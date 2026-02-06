# UI Template

This folder represents the Flutter Web UI template.

Minimum expectations:

- `lib/main.dart` demonstrates Fluttron bridge calls and external HTML/JS embed.
- `pubspec.yaml` depends on `fluttron_ui` and `fluttron_shared`.
- Build output goes to `build/web/` and will be copied to the host `assets/www/`.

## Frontend assets convention (v0021)

- JavaScript source input: `frontend/src/main.js`
- JavaScript runtime output: `web/ext/main.js`
- Runtime global factory: `window.fluttronCreateTemplateHtmlView(viewId)`

`web/ext/main.js` is committed in template to keep `fluttron create` -> `fluttron build` zero-extra-command.

## pnpm tooling

This template uses `pnpm` with `packageManager: pnpm@10.0.0`.

```bash
corepack enable
pnpm install
pnpm run js:build
```

Useful scripts:

- `pnpm run js:build`: copy `frontend/src/main.js` to `web/ext/main.js`
- `pnpm run js:watch`: watch source file and rebuild output
- `pnpm run js:clean`: remove `web/ext/main.js`

## Current CLI boundary

In v0021, `fluttron build` does not run frontend scripts automatically.
Run `pnpm run js:build` manually after changing `frontend/src/main.js`.
