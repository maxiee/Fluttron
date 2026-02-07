# UI Template

This folder represents the Flutter Web UI template.

Minimum expectations:

- `lib/main.dart` demonstrates Fluttron bridge calls and external HTML/JS embed.
- `pubspec.yaml` depends on `fluttron_ui` and `fluttron_shared`.
- Build output goes to `build/web/` and will be copied to the host `assets/www/`.

## Frontend assets convention (v0023)

- JavaScript source input: `frontend/src/main.js`
- JavaScript runtime output: `web/ext/main.js`
- Runtime global factory: `window.fluttronCreateTemplateHtmlView(viewId, initialText)`
- Runtime event channel: `fluttron.template.editor.change`

`web/ext/main.js` is committed as the default runtime artifact for quick inspection.
When `scripts["js:build"]` exists, `fluttron build` and `fluttron run` automatically run frontend build before `flutter build web`.
When `scripts["js:clean"]` exists, CLI runs `js:clean` before `js:build` to reduce stale artifacts.

## pnpm tooling

This template uses `pnpm` with `packageManager: pnpm@10.0.0`.

```bash
corepack enable
pnpm install
pnpm run js:build
```

Useful scripts:

- `pnpm run js:build`: bundle `frontend/src/main.js` to `web/ext/main.js` with esbuild
- `pnpm run js:watch`: watch source file and rebuild output continuously
- `pnpm run js:clean`: remove `web/ext/main.js` and `web/ext/main.js.map`

## Current CLI boundary

In v0023, frontend build and JS validation are integrated into CLI build pipeline:

- If `package.json` or `scripts["js:build"]` is missing, frontend build is skipped.
- If `scripts["js:clean"]` is present, `pnpm run js:clean` runs before `pnpm run js:build`.
- If `js:build` exists, Node.js and pnpm are required; failures stop the CLI build with readable errors.
- CLI validates local script assets from `web/index.html` in `ui/web`, `ui/build/web`, and `host/assets/www`.
- Any JS asset validation failure stops the build pipeline.
