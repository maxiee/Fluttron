# Fluttron v0.1.0 Release Roadmap

## Document Purpose

This is the execution-level technical plan for bringing Fluttron from its current state (post-`host_service_evolution`, v0074) to a community-ready first release (v0.1.0-alpha). Every iteration is designed to be small, self-contained, and verifiable, so that any LLM or developer can execute it without guessing.

## Current State Assessment

### What We Have (Strengths)

| Capability | Quality |
|---|---|
| CLI create/build/run | Solid, 400+ tests pass |
| Host <-> UI Bridge | Stable, typed protocol |
| 5 Built-in Services | File, Dialog, Clipboard, System, Storage |
| Service Contract Codegen | Full pipeline: parse -> generate Host/Client/Model |
| Web Package System | Discovery, collection, injection, registration |
| fluttron_milkdown | Complex web package, validated |
| markdown_editor example | Production-grade, real file editing |
| host_service_demo example | Clear custom service pattern |
| Documentation website | Docusaurus with architecture/API/getting-started |

### What's Missing (Gap Analysis)

#### A. Missing Table-Stakes Features (every desktop framework has these)

| Gap | Priority | Effort |
|---|---|---|
| **Window management** (resize, minimize, maximize, title, fullscreen) | CRITICAL | Medium |
| **App packaging** (`fluttron package` -> distributable .app/.dmg) | CRITICAL | Medium |
| **Logging service** (structured, levels, persistence) | HIGH | Low |
| **Error/crash boundary** (global error handling in host+UI) | HIGH | Low |

#### B. Missing Open Source Infrastructure

| Gap | Priority | Effort |
|---|---|---|
| CONTRIBUTING.md | CRITICAL | Low |
| CODE_OF_CONDUCT.md | CRITICAL | Trivial |
| CHANGELOG.md (retroactive) | CRITICAL | Low |
| Issue/PR templates | HIGH | Low |
| SECURITY.md | HIGH | Trivial |
| Package pubspec metadata cleanup | HIGH | Low |
| CI pipeline (GitHub Actions for tests) | HIGH | Medium |

#### C. Documentation & Presentation Gaps

| Gap | Priority | Effort |
|---|---|---|
| README overhaul (GIF, badges, comparison) | CRITICAL | Medium |
| README-zh.md (Chinese README) | HIGH | Medium |
| "Why Fluttron" comparison page | HIGH | Low |
| Troubleshooting/FAQ | HIGH | Low |
| Package-level README files | MEDIUM | Low |
| Complete website sidebar navigation | MEDIUM | Trivial |

#### D. Code Quality

| Gap | Priority | Effort |
|---|---|---|
| 13 lint warnings in fluttron_cli | HIGH | Trivial |
| All packages `dart analyze` clean | HIGH | Low |
| Version numbers standardized | MEDIUM | Trivial |

---

## Milestone Overview

```
Phase A: Quality & CI Foundation        v0075-v0079  (5 versions)
Phase B: Table-Stakes Feature Gaps      v0080-v0088  (9 versions)
Phase C: Open Source Infrastructure     v0089-v0094  (6 versions)
Phase D: Documentation & Presentation   v0095-v0101  (7 versions)
Phase E: Release Preparation            v0102-v0107  (6 versions)
```

Total: 33 versions (v0075-v0107)

---

## Phase A: Quality & CI Foundation (v0075-v0079)

### Goal

Ensure the existing codebase is clean, all tests pass reliably, and CI catches regressions automatically. This phase builds the confidence foundation.

---

### v0075 — Fix all lint warnings and standardize analysis options

**Objective**: Get `dart analyze` to report zero issues across all packages.

**Why first**: Every subsequent iteration will run `dart analyze` as part of verification. Starting from a clean baseline makes all future work verifiable.

**Files to modify**:

1. `packages/fluttron_cli/test/src/utils/ui_build_pipeline_test.dart`
   - Lines 828, 923, 1045: Replace single cascade `..method()` with `.method()`
   - There are 13 `avoid_single_cascade_in_expression_statements` warnings total — fix all of them

2. `packages/fluttron_cli/analysis_options.yaml` (create if missing)
   - Ensure it includes `package:lints/recommended.yaml`

**Steps**:

1. Read `packages/fluttron_cli/test/src/utils/ui_build_pipeline_test.dart`
2. Search for all `..` cascade expressions that are the only cascade on their receiver
3. Replace each `receiver..method()` with `receiver.method()`
4. Run `cd packages/fluttron_cli && dart analyze` — expect 0 issues
5. Run `cd packages/fluttron_shared && dart analyze` — expect 0 issues
6. Run `cd packages/fluttron_cli && dart test` — expect all tests pass (400+)

**Acceptance criteria**:
- `dart analyze packages/fluttron_cli` reports 0 issues
- `dart analyze packages/fluttron_shared` reports 0 issues
- All existing tests still pass

---

### v0076 — Standardize package versions and metadata

**Objective**: Update all package `pubspec.yaml` files to have consistent, correct metadata.

**Files to modify**:

1. `packages/fluttron_cli/pubspec.yaml`:
   - Change `version` to `0.1.0-dev`
   - Uncomment and set `repository: https://github.com/user/Fluttron` (use actual GitHub URL)
   - Improve `description`: "Command-line tool for creating, building, and running Fluttron applications."

2. `packages/fluttron_shared/pubspec.yaml`:
   - Change `version` to `0.1.0-dev`
   - Set `repository`
   - Improve `description`: "Shared protocols, models, and annotations for Fluttron Host and Renderer."

3. `packages/fluttron_host/pubspec.yaml`:
   - Change `description` from "A new Flutter project." to "Fluttron Host runtime — WebView container, service registry, and built-in services."
   - Change `version` to `0.1.0-dev`
   - Keep `publish_to: 'none'` for now (this is a Flutter app package, not a library)

4. `packages/fluttron_ui/pubspec.yaml`:
   - Change `description` from "A new Flutter project." to "Fluttron UI framework — Flutter Web widgets, service clients, and bridge utilities."
   - Change `version` to `0.1.0-dev`
   - Keep `publish_to: 'none'` for now

5. `web_packages/fluttron_milkdown/pubspec.yaml`:
   - Verify description is meaningful
   - Set `version` to `0.1.0-dev`

**Steps**:

1. Read each pubspec.yaml listed above
2. Edit the `version`, `description`, and `repository` fields as specified
3. Run `dart pub get` in each package directory to ensure no dependency resolution issues
4. Run `dart analyze` in `packages/fluttron_cli` and `packages/fluttron_shared`

**Acceptance criteria**:
- All 5 pubspec.yaml files have meaningful descriptions (not "A new Flutter project")
- All versions are `0.1.0-dev`
- `dart pub get` succeeds in all packages
- No new analysis issues introduced

---

### v0077 — Add GitHub Actions CI for tests

**Objective**: Create a CI pipeline that runs all Dart tests on every push/PR.

**Files to create**:

1. `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test-cli:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable
      - name: Install dependencies
        working-directory: packages/fluttron_cli
        run: dart pub get
      - name: Analyze
        working-directory: packages/fluttron_cli
        run: dart analyze --fatal-infos
      - name: Run tests
        working-directory: packages/fluttron_cli
        run: dart test --exclude-tags acceptance

  test-shared:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable
      - name: Install dependencies
        working-directory: packages/fluttron_shared
        run: dart pub get
      - name: Analyze
        working-directory: packages/fluttron_shared
        run: dart analyze --fatal-infos
      - name: Run tests
        working-directory: packages/fluttron_shared
        run: dart test
```

**Notes**:
- We exclude the `acceptance` tag from CLI tests because those require Flutter SDK + macOS (not available on ubuntu-latest)
- `flutter test` for `fluttron_host` and `fluttron_ui` requires Flutter SDK — add a separate job if desired, but start simple

**Steps**:

1. Create `.github/workflows/ci.yml` with the content above
2. Ensure `packages/fluttron_cli/test/integration/acceptance_test.dart` has a `@Tags(['acceptance'])` annotation (it should already)
3. Verify locally: `cd packages/fluttron_cli && dart test --exclude-tags acceptance` succeeds

**Acceptance criteria**:
- `.github/workflows/ci.yml` exists
- Local `dart test --exclude-tags acceptance` in `packages/fluttron_cli` passes
- Local `dart test` in `packages/fluttron_shared` passes

---

### v0078 — Add Flutter test job for host and UI packages

**Objective**: Extend CI to cover `fluttron_host` and `fluttron_ui` packages.

**Files to modify**:

1. `.github/workflows/ci.yml` — add two new jobs:

```yaml
  test-host:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - name: Install dependencies
        working-directory: packages/fluttron_host
        run: flutter pub get
      - name: Analyze
        working-directory: packages/fluttron_host
        run: flutter analyze
      - name: Run tests
        working-directory: packages/fluttron_host
        run: flutter test

  test-ui:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - name: Install dependencies
        working-directory: packages/fluttron_ui
        run: flutter pub get
      - name: Analyze
        working-directory: packages/fluttron_ui
        run: flutter analyze
      - name: Run tests
        working-directory: packages/fluttron_ui
        run: flutter test
```

**Steps**:

1. Read current `.github/workflows/ci.yml`
2. Append the two new jobs
3. Verify locally:
   - `cd packages/fluttron_host && flutter test`
   - `cd packages/fluttron_ui && flutter test`

**Acceptance criteria**:
- CI YAML has 4 test jobs: test-cli, test-shared, test-host, test-ui
- All local test commands pass

---

### v0079 — Measure and document bundle size baseline

**Objective**: Measure the macOS app bundle size for the playground app and document it. This gives us a marketing data point and a regression baseline.

**Files to create**:

1. `docs/performance_baseline.md`:

```markdown
# Fluttron Performance Baseline

## Bundle Size (macOS, Release)

Measured on: YYYY-MM-DD
Flutter version: X.X.X
Dart version: X.X.X

| App | .app size | Notes |
|---|---|---|
| playground (minimal) | XX MB | Base Fluttron app with no web packages |
| markdown_editor | XX MB | Full app with fluttron_milkdown |

## Comparison Context

| Framework | Typical bundle size |
|---|---|
| Electron | ~120-200 MB |
| Tauri | ~2-10 MB |
| Flutter Desktop (pure) | ~15-30 MB |
| Fluttron | XX MB |
```

**Steps**:

1. Build playground in release mode: `cd playground && fluttron build -p . --release` (or `cd playground/host && flutter build macos --release`)
2. Measure the .app bundle: `du -sh playground/host/build/macos/Build/Products/Release/*.app`
3. Build markdown_editor: similar process
4. Record all sizes in `docs/performance_baseline.md`
5. Record Flutter and Dart SDK versions

**Acceptance criteria**:
- `docs/performance_baseline.md` exists with actual measured values
- Bundle sizes are documented for at least 2 apps

---

## Phase B: Table-Stakes Feature Gaps (v0080-v0088)

### Goal

Add the features that every desktop framework is expected to have. The most critical is window management.

---

### v0080 — WindowService: Host-side implementation

**Objective**: Add a `WindowService` to `fluttron_host` that provides window control capabilities.

**Context**: Every competitor (Electron, Tauri, Wails, Neutralinojs) provides window management. This is the #1 missing feature.

**Files to create/modify**:

1. `packages/fluttron_host/lib/src/services/window_service.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:fluttron_shared/fluttron_shared.dart';

/// Service for controlling the application window.
///
/// Namespace: `window`
///
/// Methods:
/// - `setTitle(title: String)` — Set the window title
/// - `setSize(width: int, height: int)` — Set the window size
/// - `getSize()` — Get current window size
/// - `minimize()` — Minimize the window
/// - `maximize()` — Maximize/restore the window
/// - `setFullScreen(enabled: bool)` — Toggle fullscreen
/// - `isFullScreen()` — Check fullscreen state
/// - `center()` — Center the window on screen
/// - `setMinSize(width: int, height: int)` — Set minimum window size
class WindowService extends FluttronService {
  @override
  String get namespace => 'window';

  @override
  Future<dynamic> handle(String method, Map<String, dynamic> params) async {
    switch (method) {
      case 'setTitle':
        // Implementation using WidgetsBinding or native channel
        // ...
      case 'setSize':
        // ...
      case 'getSize':
        // ...
      case 'minimize':
        // ...
      case 'maximize':
        // ...
      case 'setFullScreen':
        // ...
      case 'isFullScreen':
        // ...
      case 'center':
        // ...
      case 'setMinSize':
        // ...
      default:
        throw FluttronError('METHOD_NOT_FOUND', 'window.$method not implemented');
    }
  }
}
```

**Implementation approach**:
- Use `flutter_inappwebview`'s `InAppWebViewController` for WebView-related operations
- For window-level operations (title, size, minimize, maximize, fullscreen), use Flutter's built-in APIs or platform channels:
  - macOS: `NSWindow` via `MethodChannel` or the `window_manager` package
  - Consider adding `window_manager: ^0.4.x` as a dependency to `fluttron_host`

**Decision needed before starting**: Use `window_manager` package (reliable, cross-platform) or implement via direct platform channel (lighter dependency). Recommendation: Use `window_manager` — it's well-maintained and supports macOS+Windows+Linux.

**Steps**:

1. Add `window_manager: ^0.4.0` to `packages/fluttron_host/pubspec.yaml` dependencies
2. Run `flutter pub get` in `packages/fluttron_host`
3. Create `packages/fluttron_host/lib/src/services/window_service.dart` implementing all 9 methods
4. Register `WindowService` in the default service list alongside existing services
5. Export `WindowService` from `fluttron_host.dart`

**Acceptance criteria**:
- `WindowService` class exists with all 9 methods
- `flutter analyze packages/fluttron_host` passes
- `WindowService` is registered by default in new app templates

---

### v0081 — WindowService: Unit tests

**Objective**: Write comprehensive tests for `WindowService`.

**Files to create**:

1. `packages/fluttron_host/test/window_service_test.dart`:
   - Test each of the 9 methods
   - Test error handling for invalid parameters
   - Test METHOD_NOT_FOUND for unknown methods

**Steps**:

1. Create test file with groups for each method
2. Mock the underlying window_manager or platform channel
3. Test parameter validation (e.g., negative width/height for setSize)
4. Test return values (e.g., getSize returns correct format)
5. Run `cd packages/fluttron_host && flutter test`

**Acceptance criteria**:
- `window_service_test.dart` exists with tests for all 9 methods
- All tests pass
- Error cases covered (bad params, unknown method)

---

### v0082 — WindowServiceClient: UI-side typed client

**Objective**: Add `WindowServiceClient` to `fluttron_ui` so UI code can control the window with type safety.

**Files to create/modify**:

1. `packages/fluttron_ui/lib/src/services/window_service_client.dart`:

```dart
import 'package:fluttron_ui/src/fluttron_client.dart';

/// Type-safe client for the window host service.
class WindowServiceClient {
  WindowServiceClient(this._client);
  final FluttronClient _client;

  /// Set the window title.
  Future<void> setTitle(String title) async {
    await _client.invoke('window.setTitle', {'title': title});
  }

  /// Set the window size in logical pixels.
  Future<void> setSize(int width, int height) async {
    await _client.invoke('window.setSize', {'width': width, 'height': height});
  }

  /// Get the current window size.
  Future<Map<String, int>> getSize() async {
    final result = await _client.invoke('window.getSize', {});
    return {
      'width': result['width'] as int,
      'height': result['height'] as int,
    };
  }

  /// Minimize the window.
  Future<void> minimize() async {
    await _client.invoke('window.minimize', {});
  }

  /// Maximize or restore the window.
  Future<void> maximize() async {
    await _client.invoke('window.maximize', {});
  }

  /// Toggle fullscreen mode.
  Future<void> setFullScreen(bool enabled) async {
    await _client.invoke('window.setFullScreen', {'enabled': enabled});
  }

  /// Check if the window is in fullscreen mode.
  Future<bool> isFullScreen() async {
    final result = await _client.invoke('window.isFullScreen', {});
    return result['result'] as bool;
  }

  /// Center the window on screen.
  Future<void> center() async {
    await _client.invoke('window.center', {});
  }

  /// Set the minimum window size.
  Future<void> setMinSize(int width, int height) async {
    await _client.invoke('window.setMinSize', {'width': width, 'height': height});
  }
}
```

2. `packages/fluttron_ui/lib/fluttron_ui.dart`:
   - Add export for `WindowServiceClient`

3. `packages/fluttron_ui/test/services/window_service_client_test.dart`:
   - Test each method's parameter construction and invocation

**Steps**:

1. Create `window_service_client.dart` with all 9 methods
2. Update `fluttron_ui.dart` to export the new client
3. Create test file with mock `FluttronClient`
4. Run `cd packages/fluttron_ui && flutter test`
5. Run `flutter analyze packages/fluttron_ui`

**Acceptance criteria**:
- `WindowServiceClient` exported from `fluttron_ui.dart`
- All tests pass
- `flutter analyze` clean

---

### v0083 — WindowService: Template and example integration

**Objective**: Update the app template and playground to register `WindowService` by default. Update `fluttron.json` spec to pass window config to the service.

**Files to modify**:

1. `templates/host/lib/main.dart`:
   - Add `WindowService()` to default service registry

2. `templates/fluttron.json`:
   - Window config is already present (`width`, `height`, `resizable`, `title`)
   - Ensure `WindowService` reads from this config on startup

3. `playground/host/lib/main.dart`:
   - Add `WindowService()` to registry

4. `website/docs/api/services.md`:
   - Add `window.*` section documenting all 9 methods

**Steps**:

1. Read current template `main.dart` and add WindowService registration
2. Read playground `main.dart` and add WindowService registration
3. Update services.md with window service documentation
4. Build and run playground to verify window control works

**Acceptance criteria**:
- New apps created with `fluttron create` include WindowService by default
- `services.md` documents window.* methods
- Playground app demonstrates window control

---

### v0084 — LoggingService: Host-side implementation + client

**Objective**: Add a structured logging service that both host and UI code can use.

**Why**: Developers need debugging visibility. Currently there's no structured logging.

**Files to create**:

1. `packages/fluttron_host/lib/src/services/logging_service.dart`:
   - Namespace: `logging`
   - Methods:
     - `log(level: String, message: String, data: Map?)` — Log a message
     - `getLogs(level: String?, limit: int?)` — Retrieve recent logs
     - `clear()` — Clear log buffer
   - Internal: Maintain a ring buffer of recent logs (configurable size, default 1000)
   - Write to stdout with timestamp and level

2. `packages/fluttron_ui/lib/src/services/logging_service_client.dart`:
   - `LoggingServiceClient` with typed methods for `debug()`, `info()`, `warn()`, `error()`
   - Each delegates to `logging.log` with appropriate level

3. Tests for both host and client sides

**Steps**:

1. Create `LoggingService` in fluttron_host
2. Create `LoggingServiceClient` in fluttron_ui
3. Export from both packages
4. Add tests
5. Register in template and playground

**Acceptance criteria**:
- `LoggingService` and `LoggingServiceClient` exist and are tested
- Logging from UI side produces output on host stdout
- Ring buffer limits work correctly

---

### v0085 — Global error boundary for host and UI

**Objective**: Add error handling infrastructure so uncaught errors don't crash silently.

**Files to modify**:

1. `packages/fluttron_host/lib/src/host_app.dart` (or equivalent main entry):
   - Wrap in `runZonedGuarded` for async error catching
   - Add `FlutterError.onError` handler for framework errors
   - Log caught errors via `LoggingService`

2. `packages/fluttron_ui/lib/src/ui_app.dart` (or equivalent):
   - Similar error boundary setup for the web side
   - Bridge errors should be caught and displayed, not swallowed

3. `templates/host/lib/main.dart`:
   - Wrap main() in error boundary
   - Show error overlay or log when bridge communication fails

4. `templates/ui/lib/main.dart`:
   - Wrap main() in error boundary

**Steps**:

1. Read existing host_app.dart and ui_app.dart
2. Add error boundary wrappers
3. Update templates to include error boundaries
4. Test by intentionally triggering errors (e.g., call non-existent service method)
5. Verify errors are logged and not swallowed

**Acceptance criteria**:
- Uncaught errors in host are logged with stack trace
- Uncaught errors in UI are logged with stack trace
- Bridge errors show meaningful messages
- Templates include error boundaries by default

---

### v0086 — `fluttron package` command: macOS app bundling

**Objective**: Add a CLI command that produces a distributable macOS `.app` bundle.

**Why**: Users who try the framework need to ship real apps. Without a packaging story, adoption dies.

**Files to create/modify**:

1. `packages/fluttron_cli/lib/src/commands/package.dart`:

```dart
/// `fluttron package -p <path> --platform macos`
///
/// Steps:
/// 1. Run `fluttron build -p <path>` (ensures UI is built and synced)
/// 2. Run `flutter build macos --release` in the host directory
/// 3. Copy the .app bundle to a `dist/` output directory
/// 4. Print the output path and bundle size
class PackageCommand extends Command<int> {
  // ...
}
```

2. `packages/fluttron_cli/lib/src/cli.dart`:
   - Register `PackageCommand`

3. `packages/fluttron_cli/test/src/commands/package_command_test.dart`:
   - Test command argument parsing
   - Test output directory creation

**Steps**:

1. Read existing `build.dart` command to understand the build pipeline
2. Create `PackageCommand` that chains: build -> flutter build macos --release -> copy .app to dist/
3. Register in CLI
4. Add basic tests
5. Test with playground: `fluttron package -p playground`
6. Verify output .app exists and launches

**Acceptance criteria**:
- `fluttron package -p <path>` produces a `.app` in `<path>/dist/`
- The .app launches correctly
- Bundle size is printed to stdout

---

### v0087 — `fluttron package` command: DMG creation (optional)

**Objective**: Optionally create a `.dmg` disk image for macOS distribution.

**Files to modify**:

1. `packages/fluttron_cli/lib/src/commands/package.dart`:
   - Add `--dmg` flag
   - Use `hdiutil` (macOS built-in) to create DMG from .app:
     ```
     hdiutil create -volname "AppName" -srcfolder dist/AppName.app -ov -format UDZO dist/AppName.dmg
     ```

2. `packages/fluttron_cli/test/src/commands/package_command_test.dart`:
   - Add test for DMG flag parsing

**Steps**:

1. Read the current PackageCommand
2. Add `--dmg` option
3. After .app is created, run hdiutil if --dmg is set
4. Print DMG path and size
5. Test with playground

**Acceptance criteria**:
- `fluttron package -p playground --dmg` produces a `.dmg` file
- DMG mounts and contains the app
- Size is printed

---

### v0088 — Update markdown_editor to showcase new services

**Objective**: Update the markdown_editor example to use `WindowService` and `LoggingService`, demonstrating the new capabilities.

**Files to modify**:

1. `examples/markdown_editor/ui/lib/main.dart` or relevant UI files:
   - Use `WindowServiceClient` to set window title to current file name
   - Example: When a file is opened, call `windowService.setTitle('Fluttron Editor - filename.md')`

2. `examples/markdown_editor/ui/lib/...`:
   - Add `LoggingServiceClient` usage for key operations (file open, save, errors)

3. `examples/markdown_editor/host/lib/main.dart`:
   - Ensure `WindowService` and `LoggingService` are registered

**Steps**:

1. Read current markdown_editor UI code
2. Add WindowServiceClient for dynamic window title
3. Add LoggingServiceClient for operation logging
4. Build and run: `fluttron build -p examples/markdown_editor && fluttron run -p examples/markdown_editor`
5. Verify window title changes when opening files
6. Verify logs appear in host console

**Acceptance criteria**:
- Window title shows current filename
- Operations are logged to host console
- No regressions in existing functionality

---

## Phase C: Open Source Infrastructure (v0089-v0094)

### Goal

Make the repository ready for external contributors and community engagement.

---

### v0089 — CONTRIBUTING.md and CODE_OF_CONDUCT.md

**Objective**: Create essential community governance documents.

**Files to create**:

1. `CONTRIBUTING.md`:

Structure:
```markdown
# Contributing to Fluttron

## Getting Started

### Prerequisites
- Flutter SDK (stable channel) with desktop support enabled
- Dart SDK (comes with Flutter)
- Node.js (>= 18) and pnpm
- macOS (primary development platform)

### Setup
1. Clone the repository
2. Run `dart pub get` in `packages/fluttron_cli` and `packages/fluttron_shared`
3. Run `flutter pub get` in `packages/fluttron_host` and `packages/fluttron_ui`
4. Run tests: `cd packages/fluttron_cli && dart test --exclude-tags acceptance`

### Project Structure
[Brief overview of packages/, templates/, examples/, web_packages/]

## Development Workflow

### Making Changes
1. Create a branch from `main`
2. Make your changes
3. Ensure `dart analyze` passes in all packages
4. Ensure all tests pass
5. Submit a pull request

### Coding Standards
- Follow Dart/Flutter official style guide
- All comments in English
- New public APIs must have dartdoc comments
- New features must include tests

### Commit Messages
- Use conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`
- Reference issue numbers when applicable

## Reporting Issues
[Link to issue templates]

## Pull Request Process
[Checklist: tests, docs, analysis]
```

2. `CODE_OF_CONDUCT.md`:
   - Use the Contributor Covenant v2.1 (standard for open source)
   - English text

**Steps**:

1. Create both files with the content structures above
2. Fill in all sections with project-specific details
3. Verify links are correct

**Acceptance criteria**:
- Both files exist at repository root
- CONTRIBUTING.md covers setup, development workflow, standards
- CODE_OF_CONDUCT.md is complete Contributor Covenant

---

### v0090 — GitHub issue and PR templates

**Objective**: Create structured templates for bug reports, feature requests, and pull requests.

**Files to create**:

1. `.github/ISSUE_TEMPLATE/bug_report.md`:

```markdown
---
name: Bug Report
about: Report a bug in Fluttron
title: '[Bug] '
labels: bug
---

## Description
[Clear description of the bug]

## Steps to Reproduce
1.
2.
3.

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Environment
- OS: [e.g., macOS 14.2]
- Flutter version: [output of `flutter --version`]
- Fluttron CLI version: [output of `fluttron --version`]

## Additional Context
[Screenshots, logs, error messages]
```

2. `.github/ISSUE_TEMPLATE/feature_request.md`:

```markdown
---
name: Feature Request
about: Suggest a new feature
title: '[Feature] '
labels: enhancement
---

## Problem
[What problem does this solve?]

## Proposed Solution
[How should it work?]

## Alternatives Considered
[Other approaches you've thought of]

## Additional Context
[Any other information]
```

3. `.github/pull_request_template.md`:

```markdown
## Summary
[What does this PR do?]

## Changes
- [ ] ...

## Testing
- [ ] `dart analyze` passes
- [ ] New tests added
- [ ] Existing tests pass

## Documentation
- [ ] API docs updated (if applicable)
- [ ] Website docs updated (if applicable)

## Related Issues
Closes #
```

**Steps**:

1. Create all 3 template files
2. Verify YAML frontmatter is correct

**Acceptance criteria**:
- Bug report template appears in GitHub "New Issue" page
- Feature request template appears in GitHub "New Issue" page
- PR template auto-fills when creating a new PR

---

### v0091 — CHANGELOG.md (retroactive) and SECURITY.md

**Objective**: Create a changelog documenting the project's evolution, and a security policy.

**Files to create**:

1. `CHANGELOG.md`:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- WindowService for programmatic window control
- LoggingService for structured logging
- `fluttron package` command for macOS app bundling
- CI pipeline with GitHub Actions

### Changed
- Standardized all package versions to 0.1.0-dev
- Fixed all lint warnings

## [0.0.74] - 2026-02-18

### Added (host_service_evolution, v0061-v0074)
- Framework-level built-in service clients (File, Dialog, Clipboard, System, Storage)
- `fluttron create --type host_service` for custom service scaffolding
- `fluttron generate services` for contract-driven code generation
- Service contract annotations (@FluttronServiceContract, @FluttronModel)
- AST-based service contract parser
- Host/Client/Model code generators

## [0.0.60] - 2026-02-17

### Added (markdown_editor, v0051-v0060)
- `examples/markdown_editor` — production-grade Markdown editor
- File operations: open folder, file tree, load, save, dirty state
- Theme switching with persistence via StorageService
- Status bar with real-time file info

## [0.0.50] - 2026-02-16

### Added (fluttron_milkdown, v0042-v0050)
- `fluttron_milkdown` web package — Milkdown editor integration
- Event system (change, ready, focus, blur) with typed events
- MilkdownController API for programmatic control
- 4 theme variants with runtime switching

## [0.0.41] - 2026-02-XX

### Added (Web Package MVP, v0032-v0041)
- Web Package discovery, asset collection, HTML injection
- `fluttron create --type web_package`
- `fluttron packages list` diagnostic command
- Registration code generation

## [0.0.31] - 2026-02-XX

### Added (Frontend Integration, v0020-v0031)
- FluttronHtmlView for embedding web content
- FluttronEventBridge for JS->Flutter events
- FluttronWebViewRegistry for type-driven view registration
- Frontend build pipeline (pnpm + esbuild)

## [0.0.19] - 2026-02-XX

### Added (Foundation, v0001-v0019)
- Fluttron CLI with create/build/run commands
- Host/UI/Shared package architecture
- Host <-> Renderer bridge protocol
- ServiceRegistry with system and storage services
```

2. `SECURITY.md`:

```markdown
# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Fluttron, please report it responsibly.

**Do NOT create a public GitHub issue for security vulnerabilities.**

Instead, please email: [security email or use GitHub private vulnerability reporting]

## Response Timeline

- We will acknowledge receipt within 48 hours
- We will provide an initial assessment within 1 week
- We will work with you on a fix and coordinated disclosure

## Scope

This policy covers the Fluttron framework packages:
- fluttron_cli
- fluttron_host
- fluttron_shared
- fluttron_ui

## Supported Versions

| Version | Supported |
|---|---|
| 0.1.x | Yes |
| < 0.1.0 | No |
```

**Steps**:

1. Create CHANGELOG.md with retroactive entries
2. Fill in approximate dates from git history
3. Create SECURITY.md
4. Verify all content is accurate

**Acceptance criteria**:
- CHANGELOG.md covers all major milestones
- SECURITY.md provides clear reporting instructions
- Both files are at repository root

---

### v0092 — CLI version command and version consistency

**Objective**: Add `fluttron --version` command and ensure version is consistent across all packages.

**Files to create/modify**:

1. `packages/fluttron_cli/lib/src/version.dart`:
   ```dart
   const String fluttronVersion = '0.1.0-dev';
   ```

2. `packages/fluttron_cli/lib/src/cli.dart`:
   - Set `CommandRunner`'s version to `fluttronVersion`

3. Update all package `pubspec.yaml` files to use the same version string

**Steps**:

1. Create version.dart with the version constant
2. Update CLI to use the version
3. Verify `fluttron --version` outputs the correct version
4. Ensure all pubspec.yaml files match

**Acceptance criteria**:
- `fluttron --version` prints `0.1.0-dev`
- All packages report consistent version

---

### v0093 — `fluttron doctor` diagnostic command

**Objective**: Add a `fluttron doctor` command that checks the development environment.

**Why**: Similar to `flutter doctor`, this helps users diagnose setup issues and reduces support burden.

**Files to create**:

1. `packages/fluttron_cli/lib/src/commands/doctor.dart`:

```dart
/// `fluttron doctor`
///
/// Checks:
/// - Flutter SDK installed and version
/// - Dart SDK version
/// - Node.js installed and version
/// - pnpm installed and version
/// - macOS desktop support enabled (flutter config)
/// - Current project structure (if in a Fluttron project)
class DoctorCommand extends Command<int> {
  // Run each check, print ✓ or ✗ with details
}
```

2. `packages/fluttron_cli/test/src/commands/doctor_command_test.dart`

**Steps**:

1. Create DoctorCommand that checks each prerequisite
2. Print results in a formatted table with checkmarks
3. Register command in CLI
4. Add basic tests

**Acceptance criteria**:
- `fluttron doctor` runs and prints environment status
- Missing prerequisites are clearly flagged
- Exit code is 0 if all checks pass, 1 if any fail

---

### v0094 — Clean up playground and legacy files

**Objective**: Remove outdated files and clean up the repository for public consumption.

**Files to review and potentially remove**:

1. `.opencode/` directory — if this is a development tool config, decide if it should be in `.gitignore`
2. `.test_integration/` — leftover test artifacts, should be in `.gitignore`
3. `.pnpm-store/` — should be in `.gitignore`
4. `.mcp_servers/` — development tool, should be in `.gitignore`
5. `AGENTS.md` — internal file, Chinese content. Consider:
   - Moving to `.claude/CLAUDE.md` (standard location for AI agent instructions)
   - Or adding English translation
6. `scripts/acceptance_test.sh` and `scripts/acceptance.dart` — verify they still work

**Files to modify**:

1. `.gitignore`:
   - Add `.opencode/`
   - Add `.test_integration/`
   - Add `.pnpm-store/`
   - Add `.mcp_servers/`
   - Keep existing entries

**Steps**:

1. Read `.gitignore` to see what's already excluded
2. Add missing entries
3. Review if `.test_integration/` and other directories should be removed from git history
4. Move `AGENTS.md` content to `.claude/CLAUDE.md` if appropriate
5. Run `git status` to verify changes

**Acceptance criteria**:
- `.gitignore` covers all development tool directories
- No internal-only files are visible at repository root
- Repository looks clean for external visitors

---

## Phase D: Documentation & Presentation (v0095-v0101)

### Goal

Make the first impression excellent. README, website, and documentation should convince developers to try Fluttron.

---

### v0095 — README.md overhaul (English)

**Objective**: Rewrite README.md to be compelling, informative, and visually appealing.

**Structure**:

```markdown
# Fluttron

[One-line tagline]

[Badges: CI status, version, license, Discord/discussions link]

[Screenshot or GIF of a Fluttron app running]

## What is Fluttron?

[2-3 sentences explaining the concept]

## Why Fluttron?

[Comparison table: Fluttron vs Electron vs Tauri vs Flutter Desktop]

| | Electron | Tauri | Flutter Desktop | Fluttron |
|---|---|---|---|---|
| Host Language | JS/Node.js | Rust | Dart | **Dart** |
| UI Layer | HTML/CSS/JS | HTML/CSS/JS | Flutter widgets | **Flutter Web + JS** |
| Web Ecosystem | Full | Full | None | **Full** |
| Type-safe IPC | Manual | Rust macros | N/A | **Dart codegen** |
| Mobile Ready | No | v2 | Yes | **Planned** |

## Quick Start

[Minimal steps: install -> create -> build -> run]

## Features

[Bullet list with status badges]

## Architecture

[Mermaid diagram]

## Examples

[Links to examples with screenshots]

## Documentation

[Link to website]

## Contributing

[Link to CONTRIBUTING.md]

## License

MIT
```

**Steps**:

1. Read current README.md
2. Rewrite with the structure above
3. Add badge markdown (CI, license)
4. Keep the mermaid diagram but improve it
5. Add comparison table

**Acceptance criteria**:
- README is compelling and well-structured
- Comparison table is present and accurate
- Badges are present (CI, license at minimum)
- Quick start section is clear and minimal

---

### v0096 — README-zh.md (Chinese README)

**Objective**: Create a Chinese version of the README for the Chinese Flutter developer community.

**Files to create**:

1. `README-zh.md`:
   - Full translation of the new README.md
   - Add language switcher link at the top of both READMEs:
     - English README: `[中文](README-zh.md)`
     - Chinese README: `[English](README.md)`

**Steps**:

1. Read the new README.md
2. Translate to Chinese
3. Add language switcher links to both READMEs

**Acceptance criteria**:
- README-zh.md exists with full Chinese translation
- Both READMEs link to each other

---

### v0097 — "Why Fluttron" comparison page on website

**Objective**: Create a dedicated comparison page on the Docusaurus website.

**Files to create/modify**:

1. `website/docs/getting-started/why-fluttron.md`:

```markdown
---
sidebar_position: 0
---

# Why Fluttron?

## The Problem

[Explain the gap: Flutter Desktop is great but can't use web libraries; Electron is web-only; Tauri requires Rust]

## How Fluttron Solves It

[Dart-native host + Flutter Web renderer + Web ecosystem access]

## Comparison

[Detailed comparison with Electron, Tauri, Wails, pure Flutter Desktop]

## When to Use Fluttron

[Use cases: rich text editors, chart dashboards, apps needing JS libraries]

## When NOT to Use Fluttron

[Pure mobile apps, simple desktop apps without web needs, games]
```

2. `website/sidebars.js`:
   - Add `why-fluttron` as the first item in getting-started

**Steps**:

1. Read current sidebars.js
2. Create why-fluttron.md
3. Update sidebars to include new page
4. Build website locally: `cd website && npm run build`

**Acceptance criteria**:
- "Why Fluttron" page exists and is linked from sidebar
- Comparison table is comprehensive
- Website builds successfully

---

### v0098 — Troubleshooting and FAQ page

**Objective**: Create a troubleshooting guide covering common issues.

**Files to create/modify**:

1. `website/docs/getting-started/troubleshooting.md`:

```markdown
---
sidebar_position: 99
---

# Troubleshooting

## Build Issues

### `fluttron build` fails with "pnpm not found"
[Solution: install pnpm via corepack or npm]

### `flutter build web` fails
[Solution: ensure Flutter SDK is on stable channel with web support]

### Assets not loading in WebView
[Solution: check host/assets/www/ directory structure]

## Runtime Issues

### Bridge communication fails
[Solution: check service registration, verify namespace]

### WebView shows blank screen
[Solution: check that UI build output was copied to host assets]

## CLI Issues

### `fluttron create` fails
[Solution: check permissions, path validity]

### `fluttron doctor` reports issues
[Solution: address each reported issue]

## FAQ

### Can I use React/Vue instead of Flutter Web for the UI?
[Answer: technically yes via web packages, but you lose Dart type safety]

### Does Fluttron support mobile?
[Answer: architecture supports it, not yet validated]

### How does performance compare to Electron?
[Answer: reference performance baseline]

### Can I use existing Flutter packages?
[Answer: yes in the host layer; for the UI layer, Flutter Web compatible packages work]
```

2. `website/sidebars.js`:
   - Add troubleshooting to getting-started section

**Steps**:

1. Create troubleshooting.md with common issues
2. Update sidebars
3. Build website

**Acceptance criteria**:
- Troubleshooting page exists with at least 8 Q&A entries
- Linked from sidebar
- Website builds

---

### v0099 — Complete website sidebar navigation

**Objective**: Ensure all existing website pages are properly linked in the sidebar.

**Files to modify**:

1. `website/sidebars.js`:
   - Verify ALL pages under `website/docs/` are in the sidebar
   - Add `custom-services.md` to getting-started section
   - Add `codegen.md` and `annotations.md` to API section
   - Ensure consistent ordering

2. Add `sidebar_position` frontmatter to any pages missing it

**Steps**:

1. Read `website/sidebars.js`
2. List all files in `website/docs/` recursively
3. Compare: find any pages NOT in sidebar
4. Add missing pages
5. Build website and verify navigation

**Acceptance criteria**:
- Every .md file under `website/docs/` appears in the sidebar
- No broken navigation links
- Website builds successfully

---

### v0100 — Package-level README files

**Objective**: Write meaningful README.md for each core package.

**Files to create/modify**:

1. `packages/fluttron_cli/README.md`:
   - What it does, installation, usage examples, CLI reference

2. `packages/fluttron_shared/README.md`:
   - What it contains, how to use protocols, annotation reference

3. `packages/fluttron_host/README.md`:
   - What it provides, service registry, built-in services list

4. `packages/fluttron_ui/README.md`:
   - What it provides, service clients, web view system

5. `web_packages/fluttron_milkdown/README.md`:
   - Verify it's already comprehensive (it should be from v0050)

**Steps**:

1. Read existing README files in each package
2. Write or rewrite each one with: description, installation, usage, API overview
3. Keep each under 100 lines — link to website for details

**Acceptance criteria**:
- All 5 packages have meaningful README files
- No placeholder content ("A new Flutter project", TODO markers)
- Each README links to the website for detailed documentation

---

### v0101 — Screenshot and demo GIF for README

**Objective**: Create visual assets that showcase Fluttron in action.

**Files to create**:

1. `docs/screenshots/markdown_editor.png` — Screenshot of the markdown editor running
2. `docs/screenshots/architecture.png` — Exported architecture diagram
3. `docs/screenshots/demo.gif` — Short GIF showing: `fluttron create` -> `fluttron build` -> `fluttron run` -> app running

**Steps**:

1. Build and run `examples/markdown_editor`
2. Take a clean screenshot showing the editor with a document open
3. Record a short terminal GIF (use `vhs` or `asciinema`) showing the create-build-run flow
4. Place in `docs/screenshots/`
5. Update README.md to reference the screenshot and GIF

**Acceptance criteria**:
- At least 1 screenshot and 1 GIF exist
- README.md displays the visual assets
- Images are reasonably sized (< 2MB each)

---

## Phase E: Release Preparation (v0102-v0107)

### Goal

Final polish, version bump, and launch materials.

---

### v0102 — Version bump to 0.1.0-alpha and final test sweep

**Objective**: Update all versions to `0.1.0-alpha` and run a full test sweep.

**Files to modify**:

1. All `pubspec.yaml` files: version -> `0.1.0-alpha`
2. `packages/fluttron_cli/lib/src/version.dart`: update version string
3. Update CHANGELOG.md with all changes since dev_plan v0074

**Steps**:

1. Update all version strings
2. Run all tests:
   - `cd packages/fluttron_cli && dart test`
   - `cd packages/fluttron_shared && dart test`
   - `cd packages/fluttron_host && flutter test`
   - `cd packages/fluttron_ui && flutter test`
3. Run all analyzers:
   - `dart analyze packages/fluttron_cli`
   - `dart analyze packages/fluttron_shared`
4. Build and run each example:
   - playground
   - markdown_editor
   - host_service_demo
5. Fix any issues found

**Acceptance criteria**:
- All versions are `0.1.0-alpha`
- All tests pass
- All analyzers pass
- All example apps build and run

---

### v0103 — End-to-end smoke test on a fresh machine

**Objective**: Verify the complete user journey works from scratch.

**Test script** (create `scripts/smoke_test.sh`):

```bash
#!/bin/bash
set -e

echo "=== Fluttron Smoke Test ==="

# 1. Install CLI
dart pub global activate --path packages/fluttron_cli

# 2. Create a new app
fluttron create /tmp/smoke_test_app --name SmokeTest
echo "✓ App created"

# 3. Build the app
fluttron build -p /tmp/smoke_test_app
echo "✓ App built"

# 4. Check doctor
fluttron doctor
echo "✓ Doctor passed"

# 5. Create a web package
fluttron create /tmp/smoke_test_pkg --name smoke_pkg --type web_package
echo "✓ Web package created"

# 6. Create a host service
fluttron create /tmp/smoke_test_svc --name smoke_svc --type host_service
echo "✓ Host service created"

# 7. Package the app
fluttron package -p /tmp/smoke_test_app
echo "✓ App packaged"

# Cleanup
rm -rf /tmp/smoke_test_app /tmp/smoke_test_pkg /tmp/smoke_test_svc

echo "=== All smoke tests passed ==="
```

**Steps**:

1. Create the smoke test script
2. Run it
3. Fix any issues found
4. Run it again until it passes completely

**Acceptance criteria**:
- `scripts/smoke_test.sh` passes end-to-end
- No manual intervention needed

---

### v0104 — Prepare launch blog post draft

**Objective**: Draft a blog post announcing Fluttron to the Flutter community.

**Files to create**:

1. `docs/launch/blog_post_en.md`:

Structure:
```markdown
# Introducing Fluttron: The Electron Alternative for Flutter Developers

## The Problem
[Why Flutter Desktop alone isn't enough for some use cases]

## What is Fluttron?
[Architecture explanation with diagram]

## Key Features
[Highlight: typed bridge, code generation, web package system]

## See It in Action
[Link to demo GIF, screenshots]

## How It Works
[Quick code walkthrough]

## Getting Started
[3-step quickstart]

## What's Next
[Roadmap: Windows support, plugin system, pub.dev publication]

## Try It Now
[GitHub link]
```

2. `docs/launch/blog_post_zh.md`:
   - Chinese version for Chinese community (WeChat, Zhihu, etc.)

**Steps**:

1. Write both blog posts
2. Review for accuracy
3. Include links to GitHub, website, and examples

**Acceptance criteria**:
- Both blog posts are complete and compelling
- Technical details are accurate
- Links point to correct locations

---

### v0105 — Prepare social media announcements

**Objective**: Draft social media posts for launch day.

**Files to create**:

1. `docs/launch/social_media.md`:

```markdown
# Launch Day Social Media

## Twitter/X (English, < 280 chars)

Introducing Fluttron — build cross-platform desktop apps with Flutter + Web ecosystem.

Dart-native host. Flutter Web renderer. Type-safe bridge with codegen.

Think Electron, but for Flutter devs.

GitHub: [link]
Docs: [link]

#Flutter #Dart #CrossPlatform #OpenSource

## Weibo (Chinese)

发布 Fluttron — 基于 Flutter 的跨端桌面应用框架。

灵感来自 Electron，但完全基于 Dart 生态：
- 宿主层：Flutter Desktop
- 渲染层：Flutter Web + JS 生态
- 类型安全的 Bridge 通信 + 代码生成

特色：可以在 Flutter 桌面应用中无缝集成 Web 生态的 JS 库。

GitHub: [link]
文档: [link]

#Flutter #Dart #开源 #桌面开发

## Reddit r/FlutterDev post title ideas

- "I built an Electron alternative for Flutter developers — Fluttron"
- "Fluttron: Build desktop apps with Flutter host + Flutter Web renderer + JS ecosystem"

## Hacker News title

- "Show HN: Fluttron – Electron-inspired desktop framework for Dart/Flutter"
```

**Steps**:

1. Write all social media drafts
2. Keep within character limits
3. Ensure messaging is consistent

**Acceptance criteria**:
- Social media drafts exist for Twitter, Weibo, Reddit, HN
- All within platform character limits
- Messaging is consistent and compelling

---

### v0106 — Launch checklist and final review

**Objective**: Create and execute a launch checklist.

**Files to create**:

1. `docs/launch/launch_checklist.md`:

```markdown
# Fluttron v0.1.0-alpha Launch Checklist

## Repository
- [ ] All tests pass (CLI: 400+, Shared: 16, Host: X, UI: X)
- [ ] All packages at version 0.1.0-alpha
- [ ] `dart analyze` clean across all packages
- [ ] `.gitignore` covers all dev tool directories
- [ ] No internal/sensitive files in repository

## Documentation
- [ ] README.md is compelling with screenshot/GIF
- [ ] README-zh.md exists
- [ ] CONTRIBUTING.md exists
- [ ] CODE_OF_CONDUCT.md exists
- [ ] CHANGELOG.md is up to date
- [ ] SECURITY.md exists
- [ ] All package READMEs are meaningful
- [ ] Website builds and deploys successfully
- [ ] All website pages are in sidebar

## Features
- [ ] `fluttron create` works for all 3 types
- [ ] `fluttron build` works
- [ ] `fluttron run` works
- [ ] `fluttron package` works
- [ ] `fluttron doctor` works
- [ ] `fluttron generate services` works
- [ ] `fluttron packages list` works
- [ ] `fluttron --version` shows correct version
- [ ] WindowService works
- [ ] LoggingService works

## Examples
- [ ] playground builds and runs
- [ ] markdown_editor builds and runs
- [ ] host_service_demo builds and runs

## Launch Materials
- [ ] Blog post (EN) ready
- [ ] Blog post (ZH) ready
- [ ] Social media drafts ready
- [ ] Screenshots/GIF in repository

## CI/CD
- [ ] GitHub Actions CI passing on main
- [ ] Documentation auto-deploys

## Post-Launch Plan
- [ ] Monitor GitHub issues
- [ ] Respond to issues within 48 hours
- [ ] Plan v0.1.0 (stable) with Windows support
```

**Steps**:

1. Create the checklist
2. Go through each item
3. Fix any remaining issues
4. Mark all items as complete

**Acceptance criteria**:
- Launch checklist exists
- All items are checked off
- No blocking issues remain

---

### v0107 — Tag v0.1.0-alpha and publish

**Objective**: Create the release tag and make the announcement.

**Steps**:

1. Final `git status` — ensure working tree is clean
2. Create annotated tag: `git tag -a v0.1.0-alpha -m "First community release"`
3. Push tag: `git push origin v0.1.0-alpha`
4. Create GitHub Release with release notes (from CHANGELOG.md)
5. Deploy documentation website (should auto-deploy via CI)
6. Post to social media platforms
7. Submit blog posts

**Acceptance criteria**:
- `v0.1.0-alpha` tag exists on GitHub
- GitHub Release is created with release notes
- Documentation website is live and up to date
- At least 1 social media post is published

---

## Dependency Graph

```
Phase A (v0075-v0079): Quality Foundation
  v0075 (lint fix) → v0076 (metadata) → v0077 (CI) → v0078 (CI extend) → v0079 (benchmark)

Phase B (v0080-v0088): Features
  v0080 (window host) → v0081 (window test) → v0082 (window client) → v0083 (window integration)
  v0084 (logging) — can parallel with v0080-v0083
  v0085 (error boundary) — depends on v0084
  v0086 (package cmd) → v0087 (DMG) — can parallel with v0080-v0085
  v0088 (update example) — depends on v0083, v0084

Phase C (v0089-v0094): Infrastructure
  v0089 (CONTRIBUTING) → v0090 (templates) → v0091 (CHANGELOG) — sequential
  v0092 (version cmd) — can parallel
  v0093 (doctor) — can parallel
  v0094 (cleanup) — after v0092

Phase D (v0095-v0101): Documentation
  v0095 (README EN) → v0096 (README ZH) — sequential
  v0097 (why-fluttron) — can parallel with v0095
  v0098 (troubleshooting) — can parallel
  v0099 (sidebar) — after v0097, v0098
  v0100 (package READMEs) — can parallel
  v0101 (screenshots) — after v0095, depends on examples running

Phase E (v0102-v0107): Release
  v0102 (version bump) → v0103 (smoke test) → v0104 (blog) → v0105 (social) → v0106 (checklist) → v0107 (publish)
  All of Phase E is sequential
```

---

## Parallel Execution Opportunities

To speed up delivery, these can be worked on simultaneously:

1. **Phase A** must complete first (foundation)
2. In **Phase B**: Window service (v0080-v0083) || Logging (v0084) || Package command (v0086-v0087)
3. In **Phase C**: CONTRIBUTING flow (v0089-v0091) || Version/Doctor (v0092-v0093)
4. In **Phase D**: README (v0095-v0096) || Why-Fluttron page (v0097) || Troubleshooting (v0098)
5. **Phase E** is sequential

---

## Post-v0.1.0-alpha Roadmap (Not in Scope)

These items are explicitly deferred to future releases:

| Item | Target Release | Rationale |
|---|---|---|
| Windows support | v0.1.0 | Need to validate flutter_inappwebview on Windows |
| Linux support | v0.2.0 | Lower priority than Windows |
| pub.dev publication | v0.1.0 | Needs stable API surface |
| Plugin system | v0.2.0 | Web packages serve as informal plugins for now |
| Auto-updater | v0.3.0 | Nice-to-have, not blocking adoption |
| System tray | v0.2.0 | Common but not critical for first release |
| Native menus | v0.2.0 | Requires platform-specific work |
| Multi-window | v0.3.0 | Complex, can be deferred |
| iOS/Android validation | v0.3.0 | Architecture supports it, needs testing |
| Performance optimization | v0.2.0 | Current performance is acceptable for alpha |

---

## LLM Execution Instructions

When implementing any version in this plan:

1. **Read this document first** to understand the version's objective and dependencies
2. **Read the listed files** before modifying them
3. **Follow the steps exactly** — they are ordered for a reason
4. **Run the acceptance criteria** after implementation
5. **Do not add scope** — if you find something that needs fixing but isn't in the current version, note it for a future version
6. **Commit with conventional format**: `feat:`, `fix:`, `docs:`, `test:`, `chore:`
7. **One version = one commit** (or a small set of closely related commits)

### Common Verification Commands

```bash
# Analyze all packages
dart analyze packages/fluttron_cli
dart analyze packages/fluttron_shared

# Run CLI tests (fast, no Flutter needed)
cd packages/fluttron_cli && dart test --exclude-tags acceptance

# Run shared tests
cd packages/fluttron_shared && dart test

# Run host tests (needs Flutter)
cd packages/fluttron_host && flutter test

# Run UI tests (needs Flutter)
cd packages/fluttron_ui && flutter test

# Build website
cd website && npm run build

# Full acceptance (slow, needs Flutter + macOS)
cd packages/fluttron_cli && dart test
```
