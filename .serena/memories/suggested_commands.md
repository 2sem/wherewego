# WhereWeGo — Suggested Commands

## Build & Development

```bash
# Install tool versions (tuist via mise)
mise install

# Resolve & fetch SPM dependencies
mise x -- tuist install

# Generate Xcode project (only when files are added/removed)
mise x -- tuist generate

# Build the project
mise x -- tuist build

# Run tests
mise x -- tuist test
```

## Notes
- ALL tuist commands must be prefixed with `mise x --`
- Do NOT regenerate the project (`tuist generate`) unless a file is being added or deleted
- Secrets are encrypted; CI decrypts via `git-secret` + GPG before building

## Git
Standard git commands work normally on Darwin.
