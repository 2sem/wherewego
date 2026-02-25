# AGENTS.md

Operational guide for coding agents working in this repository.

## 1) Repository Snapshot
- Product: iOS app (`WhereWeGo`) using SwiftUI + Tuist.
- Workspace root: `Workspace.swift` with projects under `Projects/`.
- Main app target lives in `Projects/App/`.
- Tooling is pinned via `mise` (`.mise.toml` -> Tuist `4.146.2`).

## 2) Tooling Rules
- Always run Tuist through `mise`: `mise x -- tuist ...`
- Do not assume globally installed `tuist` version.
- Use `Workspace.swift` and `Projects/*/Project.swift` as source of truth.
- Do not regenerate project files unless files are added/removed.

## 3) Setup Commands
Run from repository root.

```bash
# install pinned tools
mise install

# resolve project dependencies
mise x -- tuist install
```

## 4) Build Commands
```bash
# build all testable/buildable targets
mise x -- tuist build

# build a specific scheme
mise x -- tuist build App
```

## 5) Test Commands
Baseline:

```bash
# run all tests in current workspace context
mise x -- tuist test

# run tests for the App scheme
mise x -- tuist test App
```

Single test execution (important):

```bash
# single test target
mise x -- tuist test App -- --test-targets "AppTests"

# single test class
mise x -- tuist test App -- --test-targets "AppTests/AppTests"

# single test method
mise x -- tuist test App -- --test-targets "AppTests/AppTests/test_twoPlusTwo_isFour"
```

Useful options:

```bash
# pin simulator
mise x -- tuist test App --device "iPhone 16" --os "latest"

# pass raw xcodebuild destination args
mise x -- tuist test App -- -destination 'platform=iOS Simulator,name=iPhone 16'

# skip UI tests
mise x -- tuist test App --skip-ui-tests

# build-only or without-building modes
mise x -- tuist test App --build-only
mise x -- tuist test App --without-building
```

## 6) Lint / Formatting
- No dedicated SwiftLint/SwiftFormat config is currently in repo.
- Treat `mise x -- tuist build` as the required static validation gate.
- Keep formatting consistent with touched file style.
- Do not reformat unrelated files.

## 7) Architecture & File Placement
- Screens: `Projects/App/Sources/Screens/`
- View models/state: `Projects/App/Sources/ViewModels/`
- Data/persistence/API: `Projects/App/Sources/Datas/`
- UIViewRepresentable wrappers: `Projects/App/Sources/Views/`
- When adding screens, wire navigation via `TourNavDestination` and destination mapping.

## 8) Imports & Dependencies
- Keep imports minimal and explicit.
- Typical import order:
  1) Apple frameworks (`SwiftUI`, `Foundation`, `CoreLocation`, etc.)
  2) Third-party frameworks (`Firebase`, `GoogleMobileAds`, etc.)
- A blank line between Apple and third-party imports is acceptable.
- Remove unused imports in touched files.

## 9) Formatting & Structure
- Follow local style in each file (consistency over preference).
- Semicolons are common in core sources; preserve surrounding style.
- Use `// MARK:` for non-trivial sections.
- Break up large SwiftUI views into smaller computed subviews/helpers.
- In `UIViewRepresentable` wrappers, prefer split `.frame(height:)` and `.frame(maxWidth:)` modifiers.

## 10) Types, Models, and Data Parsing
- Do not migrate existing data layer to `Codable` unless explicitly requested.
- Existing models rely on:
  - `JSONSerialization`
  - dictionary-backed storage (`[String: AnyObject]`)
  - parse helpers (`parseToInt`, `parseToFloat`, `parseToDate`, etc.)
- When adding a tour field:
  1) add key under `fieldNames`
  2) add computed property getter/setter
  3) align conversions with existing parse helpers

## 11) Naming Conventions
- Types: `UpperCamelCase`
- Methods/properties/vars: `lowerCamelCase`
- Persistent key containers follow existing style (e.g. `WWGDefaults.Keys.LastShareShown`).
- Keep domain naming aligned with existing terms (`Tour`, `Range`, `DeepLink`, etc.).

## 12) State, Storage, and Singletons
- Persisted state should be managed through `WWGDefaults`.
- Follow existing singleton pattern (`static let shared` / `static var shared`).
- Use `@EnvironmentObject` for app-wide services where that pattern already exists.

## 13) Error Handling and Logging
- Prefer guard + early return for invalid state/optionals.
- Route UI state updates to main thread in async/network callbacks.
- Keep user flows resilient: fail gracefully on malformed payloads.
- Preserve existing logging pattern (`print` and helper logging) unless refactor is requested.
- Avoid silently swallowing critical errors when callbacks can propagate failures.

## 14) Localization, Theme, Ads
- Locale branching (Korean vs foreign behavior) is intentional; preserve it.
- Use localized strings via `.localized()` following existing patterns.
- Theme behavior should align with `LSThemeManager` usage.
- Ad flow should stay centralized in `SwiftUIAdManager`.

## 15) CI, Secrets, Release Safety
- Never commit decrypted secrets or credentials.
- Secrets are encrypted and handled in CI using `git-secret` + GPG.
- Build/test workflow: `.github/workflows/buliid-test.yml`
- Deploy workflow: `.github/workflows/deploy-ios.yml`

## 16) Cursor/Copilot Instructions Coverage
- No Cursor rules found at `.cursor/rules/`.
- No `.cursorrules` file found.
- No Copilot instruction file found at `.github/copilot-instructions.md`.
- If any of those files are added later, treat them as higher-priority instructions and update this file.

## 17) Recommended Agent Workflow
1. Read `CLAUDE.md` and relevant manifests before editing.
2. Make smallest viable change first.
3. Run targeted tests (single class/method), then broader tests if needed.
4. Run `mise x -- tuist build` before handoff.
5. Report changed files, validation steps, and remaining risk.

## 18) Definition of Done
- `mise x -- tuist build` passes.
- Relevant tests pass (at minimum, targeted tests for touched logic).
- No unrelated formatting churn.
- Navigation wiring updated for new screens.
- Persisted keys only introduced via `WWGDefaults`.
- Existing localization/theme/locale behaviors are preserved.
