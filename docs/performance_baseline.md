# Fluttron Performance Baseline

## Bundle Size (macOS, Release)

Measured on: 2026-02-19
Flutter version: 3.38.5 (stable channel)
Dart version: 3.10.4

| App | .app size | Notes |
|---|---|---|
| playground (minimal) | 94 MB | Base Fluttron app with WebView container, 5 built-in services, no web packages pre-loaded |
| markdown_editor | 94 MB | Full production app with fluttron_milkdown (Milkdown rich-text editor via web package) |

> Measurement method: `du -sh <app>.app` on macOS (arm64, Apple Silicon)
> Flutter build output reports 98.3 MB (SI units, 1000-based); `du` reports 94 MB (binary units, 1024-based).

## Key Observations

- **Baseline size of a Fluttron app is ~94 MB** on macOS Apple Silicon.
- Adding a complex web package (`fluttron_milkdown`, which includes the Milkdown editor, GFM, highlight.js, and 4 themes) does **not significantly increase** bundle size. Both apps are 94 MB.
- The web package assets (JS bundles, HTML) are embedded inside the `.app` bundle under `Contents/Frameworks/App.framework/Resources/flutter_assets/assets/www/`.

## Comparison Context

| Framework | Typical bundle size | Language | Notes |
|---|---|---|---|
| Electron | 120–200 MB | JS / Node.js | Chromium + Node.js bundled |
| Tauri | 2–10 MB | Rust | Uses system WebView; very lightweight |
| Flutter Desktop (pure) | 15–30 MB | Dart | No WebView, pure Flutter rendering |
| **Fluttron** | **~94 MB** | **Dart** | Flutter Desktop host + WebKit WebView (system) + web assets |

## Notes on Fluttron's Bundle Size

- Fluttron uses the **system WebKit** (WKWebView on macOS) rather than bundling Chromium — this is why it is significantly smaller than Electron.
- The ~94 MB footprint is dominated by the Flutter framework itself (~60–70 MB), Dart AOT snapshot, and the `flutter_inappwebview` plugin.
- Future optimization opportunities:
  - Use `--split-debug-info` to reduce binary size slightly
  - Investigate tree-shaking for embedded web assets
- **vs Tauri**: Fluttron is larger because it ships its own Flutter rendering engine rather than relying on a thin Rust wrapper around the system WebView. The tradeoff is a rich Dart ecosystem and type-safe service bridge.
- **vs Flutter Desktop**: Fluttron is larger (~3×) due to the WebView plugin and bundled web assets. The tradeoff is full access to the JS/Web ecosystem within the app.

## Regression Baseline

This document serves as the baseline for future bundle size tracking. Any future change that increases the base bundle size by more than 10 MB should be investigated before merging.

| Metric | Baseline Value |
|---|---|
| Base app size (macOS, arm64) | 94 MB |
| With complex web package | 94 MB |
| Build date | 2026-02-19 |
| Flutter SDK | 3.38.5 (stable) |
| Dart SDK | 3.10.4 |
| Xcode toolchain | Apple Silicon / macOS |
