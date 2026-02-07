# UI Template

This folder represents the Flutter Web UI template.

Minimum expectations:

- `lib/main.dart` demonstrates Fluttron bridge calls and external HTML/JS embed.
- `pubspec.yaml` depends on `fluttron_ui` and `fluttron_shared`.
- Build output goes to `build/web/` and will be copied to the host `assets/www/`.

## Frontend assets convention (v0022)

- JavaScript source input: `frontend/src/main.js`
- JavaScript runtime output: `web/ext/main.js`
- Runtime global factory: `window.fluttronCreateTemplateHtmlView(viewId)`

`web/ext/main.js` is committed as the default runtime artifact for quick inspection.
When `scripts["js:build"]` exists, `fluttron build` and `fluttron run` automatically run frontend build before `flutter build web`.

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

In v0022, frontend build is integrated into CLI build pipeline:

- If `package.json` or `scripts["js:build"]` is missing, frontend build is skipped.
- If `js:build` exists, Node.js and pnpm are required; failures stop the CLI build with readable errors.
