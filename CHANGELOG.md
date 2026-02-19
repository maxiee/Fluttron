# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [0.1.0-alpha] - 2026-02-19

### Added (Phase E: Release Preparation)
- Bumped all framework package versions to `0.1.0-alpha`

### Added (Phase D: Documentation & Presentation, v0095–v0101)
- Rewrote `README.md` (English): tagline, CI/version/license badges, comparison table
  (Fluttron vs Electron vs Tauri vs Flutter Desktop), Quick Start, Architecture Mermaid
  diagram, examples, contributing, and license sections
- Added `README-zh.md` — full Chinese translation with language-switcher links
- Added `website/docs/getting-started/why-fluttron.md` — problem statement, solution,
  detailed comparison table, when-to-use / when-not-to-use guidance
- Added `website/docs/getting-started/troubleshooting.md` — ≥8 Q&A covering build issues,
  runtime issues, CLI issues, and FAQ
- Completed `website/sidebars.js` navigation (all docs pages linked, no broken navigation)
- Added/rewrote package-level `README.md` for `fluttron_cli`, `fluttron_shared`,
  `fluttron_host`, `fluttron_ui`, and `fluttron_milkdown`
- Added `docs/screenshots/` with markdown editor screenshot and CLI demo GIF

### Added (Phase C: Open Source Infrastructure, v0089–v0094)
- `CONTRIBUTING.md` (prerequisites, setup, project structure, workflow, standards, commit
  messages, PR process)
- `CODE_OF_CONDUCT.md` — Contributor Covenant v2.1 (English)
- GitHub Issue templates: bug report, feature request
- GitHub PR template with analyze / test / docs checklist
- `CHANGELOG.md` (this file) with retroactive history from v0001 to current
- `SECURITY.md` with vulnerability reporting process and response timeline
- `fluttron --version` command reporting version from `version.dart`
- `fluttron doctor` diagnostic command (checks Flutter / Dart / Node.js / pnpm / macOS
  desktop support; exit code 0 = all pass, 1 = failures)
- Updated `.gitignore` to cover `.opencode/`, `.test_integration/`, `.pnpm-store/`,
  `.mcp_servers/` and other dev-tool directories

### Added (Phase B: Table-Stakes Features, v0080–v0088)
- `WindowService` (host) — 9 methods: `setTitle`, `setSize`, `getSize`, `minimize`,
  `maximize`, `setFullScreen`, `isFullScreen`, `center`, `setMinSize`; backed by
  `window_manager ^0.4.0`
- `WindowServiceClient` (UI) — typed wrapper for all 9 window methods; exported from
  `fluttron_ui`
- `LoggingService` (host) — ring-buffer logger (default 1000 entries); methods: `log`,
  `getLogs`, `clear`; writes to stdout with timestamp and level
- `LoggingServiceClient` (UI) — typed `debug()`, `info()`, `warn()`, `error()` helpers
- Global error boundary in host: `runZonedGuarded` + `FlutterError.onError`
- Global error boundary in UI: uncaught async / framework errors are caught and logged
- `fluttron package -p <path>` — chains build → `flutter build macos --release` → copies
  `.app` to `<path>/dist/`; prints bundle path and size
- `fluttron package --dmg` — generates `.dmg` via `hdiutil create`
- Updated `examples/markdown_editor` to use `WindowServiceClient` (dynamic window title)
  and `LoggingServiceClient` (key operation logging)

### Added (Phase A: Quality & CI Foundation, v0075–v0079)
- GitHub Actions CI pipeline with 4 jobs: `test-cli`, `test-shared`, `test-host`,
  `test-ui` (using `dart-lang/setup-dart@v1` and `subosito/flutter-action@v2`)
- `docs/performance_baseline.md` — macOS release bundle sizes for playground and
  markdown_editor, with comparison context vs Electron / Tauri / Flutter Desktop

### Changed
- All framework package versions unified: `fluttron_cli`, `fluttron_shared`,
  `fluttron_host`, `fluttron_ui`, `fluttron_milkdown` — from `0.1.0-dev` to `0.1.0-alpha`
- Fixed all lint warnings (`dart analyze` reports 0 issues across all packages)
- Updated all package `pubspec.yaml` descriptions to be meaningful (removed "A new
  Flutter project" placeholders)
- `WindowService` and `LoggingService` registered by default in host app template

## [0.0.74] - 2026-02-18

### Added (host_service_evolution, v0061–v0074)
- Framework-level built-in service clients: `FileServiceClient`, `DialogServiceClient`,
  `ClipboardServiceClient`, `SystemServiceClient`, `StorageServiceClient`
- `fluttron create --type host_service` scaffold for custom Host + Client dual-package
- `fluttron generate services` — contract-driven code generation CLI
- Service contract annotations: `@FluttronServiceContract`, `@FluttronModel`
- AST-based `ServiceContractParser` (supports nullable, List/Map, optional params)
- `HostServiceGenerator`, `ClientServiceGenerator`, `ModelGenerator`
- `--dry-run` flag on `generate services`
- `examples/host_service_demo` example application
- Website docs: `codegen.md`, `annotations.md`, `custom-services.md`
- 155 generator unit tests; TodoService E2E integration test

### Changed
- `FluttronClient.getPlatform`, `kvGet`, `kvSet` deprecated in favour of typed clients
- `markdown_editor` migrated to framework-level service clients (removed app-layer duplicates)

## [0.0.60] - 2026-02-17

### Added (markdown_editor, v0051–v0060)
- `examples/markdown_editor` — production-grade Markdown editor built on Fluttron
- File operations: Open Folder, File Tree, Load file, Save, dirty-state tracking
- New File creation with sidebar refresh and auto-open
- Theme switching (4 variants) with persistence via `StorageServiceClient`
- Status bar with real-time filename / save-state / character count / line count
- Error feedback and loading-state UI
- `FileService` (8 methods), `DialogService`, `ClipboardService` host implementations

## [0.0.50] - 2026-02-16

### Added (fluttron_milkdown, v0042–v0050)
- `fluttron_milkdown` — first official Fluttron web package (Milkdown editor)
- Event system: `change`, `ready`, `focus`, `blur` with typed Dart events
- `MilkdownController` API for programmatic control (getContent/setContent/focus/clear)
- `fluttronMilkdownControl` JS control channel with unified error return structure
- 4 built-in themes with runtime switching
- GFM + syntax highlighting support; bundle size documented
- `flutter test` 67 tests passing; V1–V12 validation checklist complete
- Website examples and design/validation documentation

### Changed
- playground migrated to web package mechanism; legacy hand-written integration removed

## [0.0.41] - 2026-02-13

### Added (Web Package MVP, v0032–v0041)
- Web Package dependency discovery via `package_config`
- Asset collection and HTML injection pipeline
- `fluttron create --type web_package` scaffold
- `fluttron packages list` diagnostic command
- Registration code generation (`FluttronWebViewRegistry` + factory stubs)
- `UiBuildPipeline` integration: three-stage asset validation
- Integration acceptance matrix (v0041)

## [0.0.31] - 2026-02-08

### Added (Frontend Integration, v0020–v0031)
- `FluttronHtmlView` — embed web content driven by `type + args`
- `FluttronEventBridge` — JS→Flutter typed event channel
- `FluttronWebViewRegistry` — type-driven view registration
- Frontend build pipeline: `pnpm + esbuild` + three-stage validation
- Template contract updated with web view registry and type-driven HTML view

## [0.0.19] - 2026-02-06

### Added (Foundation, v0001–v0019)
- Fluttron CLI with `create`, `build`, `run` commands
- Host / UI / Shared package architecture
- Host ↔ Renderer bridge protocol (`FluttronRequest` / `FluttronResponse` / `FluttronError`)
- `ServiceRegistry` with `namespace.method` routing
- Built-in `system.*` and `storage.*` services
- macOS host template with Flutter + WebView integration
- `fluttron_shared` manifest and `WindowConfig` models
- Initial website (Docusaurus) with architecture documentation

[0.1.0-alpha]: https://github.com/maxiee/Fluttron/compare/v0.0.74...v0.1.0-alpha
[0.0.74]: https://github.com/maxiee/Fluttron/compare/v0.0.60...v0.0.74
[0.0.60]: https://github.com/maxiee/Fluttron/compare/v0.0.50...v0.0.60
[0.0.50]: https://github.com/maxiee/Fluttron/compare/v0.0.41...v0.0.50
[0.0.41]: https://github.com/maxiee/Fluttron/compare/v0.0.31...v0.0.41
[0.0.31]: https://github.com/maxiee/Fluttron/compare/v0.0.19...v0.0.31
[0.0.19]: https://github.com/maxiee/Fluttron/releases/tag/v0.0.19
