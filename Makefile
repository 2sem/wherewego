.PHONY: setup init install ins gen ca install-clean clean cache build test generate generate-clean generate-no-cache generate-open graph archive archive-clean s i c ic b t g gc gn o gr ar go bt rebuild ig

# First-time bootstrap: tools, decrypted secret plists, packages, workspace
setup: init
	@command -v git-secret >/dev/null 2>&1 || brew install git-secret
	git secret reveal
	$(MAKE) install generate

# Install mise (if missing) and the tuist version pinned in .mise.toml
init:
	@command -v mise >/dev/null 2>&1 || brew install mise
	mise install

# Clean Build by Tuist
clean:
	mise x -- tuist clean dependencies binaries

# Resolve Swift package dependencies
install:
	mise x -- tuist install

# Alias for install
ins: install

# Wipe fetched packages and cached binaries, then re-fetch and rebuild the cache
install-clean: clean install

# Cache Binaries
cache:
	mise x -- tuist cache

# Alias for cache
ca: cache

# Build the app
build:
	mise x -- tuist build

# Run tests
test:
	mise x -- tuist test

# Generate the Xcode workspace
generate:
	mise x -- tuist generate --no-open

# Alias for generate
gen: generate

# Wipe fetched packages and cached binaries, re-fetch, then generate
generate-clean: clean install generate

# Generate the Xcode workspace building every package from source (cache profile none)
generate-no-cache:
	mise x -- tuist generate --no-open --cache-profile none

# Generate the Xcode workspace and open it
generate-open:
	mise x -- tuist generate

# Generate the project dependency graph without external dependencies
graph:
	mise x -- tuist graph --skip-external-dependencies

# Archive the current generation into Xcode's Organizer
archive:
	xcodebuild archive \
		-workspace wherewego.xcworkspace \
		-scheme App \
		-configuration Release \
		-destination 'generic/platform=iOS' \
		-allowProvisioningUpdates

# Archive a release. Never archive off a cached generation: `tuist cache` stores
# xcframeworks with no dSYMs, so Xcode links prebuilt Firebase frameworks
# instead of compiling them, and the dSYMs Crashlytics needs are never produced.
archive-clean: clean install generate-no-cache archive

# --- Short aliases ---

s: setup
i: install
c: clean
ic: install-clean
b: build
t: test
g: generate
gc: generate-clean
gn: generate-no-cache
o: generate-open
gr: graph
ar: archive-clean

# --- Combos ---

# Resolve packages, generate the workspace, then build
go: install generate build

# Build then run tests
bt: build test

# Full reset: wipe, re-fetch, regenerate, build
rebuild: clean install generate build

# Resolve packages, then generate the workspace
ig: install generate
