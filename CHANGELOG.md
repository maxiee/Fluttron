# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- WindowService for programmatic window control (resize/minimize/maximize/title/fullscreen)
- LoggingService for structured logging with ring buffer
- `fluttron package` command for macOS `.app` bundling
- `fluttron package --dmg` flag for `.dmg` generation via `hdiutil`
- Global error boundary (`runZonedGuarded` + `FlutterError.onError`) in host and UI
- CI pipeline with GitHub Actions (4 jobs: test-cli, test-shared, test-host, test-ui)
- CONTRIBUTING.md and CODE_OF_CONDUCT.md (Contributor Covenant v2.1)
- GitHub Issue templates (bug report, feature request) and PR template
- CHANGELOG.md (this file) and SECURITY.md

### Changed
- Standardized all package versions to `0.1.0-dev`
- Fixed all lint warnings (`dart analyze` reports 0 issues)

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

[Unreleased]: https://github.com/fluttron/fluttron/compare/v0.0.74...HEAD
[0.0.74]: https://github.com/fluttron/fluttron/compare/v0.0.60...v0.0.74
[0.0.60]: https://github.com/fluttron/fluttron/compare/v0.0.50...v0.0.60
[0.0.50]: https://github.com/fluttron/fluttron/compare/v0.0.41...v0.0.50
[0.0.41]: https://github.com/fluttron/fluttron/compare/v0.0.31...v0.0.41
[0.0.31]: https://github.com/fluttron/fluttron/compare/v0.0.19...v0.0.31
[0.0.19]: https://github.com/fluttron/fluttron/releases/tag/v0.0.19
