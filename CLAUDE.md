# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WePLi is a social music iOS app where users recommend songs for themed playlists, vote on tracks, share music via community posts, and create music photo cards. Built with SwiftUI and TCA (The Composable Architecture).

## Build Commands

```bash
# Initial setup (install dependencies and generate project)
tuist install
tuist generate

# Open project
open WePLi.xcworkspace

# Run tests
xcodebuild -workspace WePLi.xcworkspace -scheme WePLi -destination 'platform=iOS Simulator,name=iPhone 15' test

# Lint code
swiftlint --config .swiftlint.yml
swiftformat --lint . --config .swiftformat

# Run SwiftGen for asset code generation
swiftgen config run --config swiftgen.yml
```

### Fastlane Commands

```bash
bundle exec fastlane ios bootstrap   # Initial dev environment setup
bundle exec fastlane ios build_debug # Debug build
bundle exec fastlane ios test        # Run unit tests
bundle exec fastlane ios ci          # Full CI pipeline (bootstrap + test + archive)
```

## Architecture

### Project Structure (Tuist Modular)

- `Projects/App/` - Main app target with SwiftUI views and TCA reducers
- `Projects/Core/` - Core modules (DesignSystem, Network, Utils - currently scaffolded)
- `Tuist/` - Tuist configuration and SPM dependencies
- `Configs/` - xcconfig files for Debug/Release builds

### TCA Pattern

Use State, Action, and Reducer for all feature logic. Inject dependencies via `@Dependency`.

### Key Dependencies

- **TCA** (ComposableArchitecture) - State management
- **Moya** - Networking
- **Kingfisher** - Image loading
- **Supabase** - Backend
- **GoogleSignIn** - Authentication
- **KeychainAccess** - Secure storage

## Code Style

### SwiftLint Rules

- Line length: warning at 120, error at 140
- Use `Logger`/`OSLog` instead of `print()` (custom rule enforced)
- Force unwrapping, force cast, force try are warnings
- Excluded: `Projects/**/Generated/**`, test files

### SwiftFormat

- 2-space indentation, max width 120
- `--self insert` enabled
- Wrap arguments/collections/parameters before-first

## Configuration

Copy `Configs/Sample.xcconfig` to `Configs/Debug.xcconfig` and `Configs/Release.xcconfig`, then fill in actual API keys (Supabase, Google Sign-In, etc.).

## Git Workflow & Conventions

Refer to `docs/git/` for detailed guidelines:

| Document | Description |
| -------- | ----------- |
| [micro-strategy.md](docs/git/micro-strategy.md) | Micro branch & micro commit strategy |
| [branch.md](docs/git/branch.md) | Branch naming conventions (`type/description`) |
| [commit.md](docs/git/commit.md) | Commit message format (`[Type]: message`) |
| [pull-request-template.md](docs/git/pull-request-template.md) | PR template and guidelines |
| [issue-labels.md](docs/git/issue-labels.md) | GitHub issue label system (TCA, modules, areas) |
| [issue-template.md](docs/git/issue-template.md) | Issue template format |
| [release-workflow.md](docs/git/release-workflow.md) | Release process (develop → main → App Store) |

### Quick Reference

**Commit Prefixes:** `[Feat]`, `[Fix]`, `[Design]`, `[Refactor]`, `[Docs]`, `[Test]`, `[Chore]`, `[Add]`, `[Del]`

**Branch Format:** `{type}/{description}` (e.g., `feat/playlist-voting-ui`, `fix/login-crash`)

**Branch Strategy:** Git-flow with `main` (production), `develop` (integration). All feature branches start from `develop`.

## Issue & PR Templates

- Issue templates: `.github/ISSUE_TEMPLATE/` (bug_report, feature_request, todo)
- PR template: `.github/pull_request_template.md`
- Labels config: `.github/labels.yml`

## Tool Versions (mise)

- Tuist 4.71.0
- Ruby 3.2.4
- Xcode 16.2+ (CI uses 16.2)
- iOS deployment target: 16.0
