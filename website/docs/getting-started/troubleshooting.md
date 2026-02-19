---
sidebar_position: 99
---

# Troubleshooting

Common issues and solutions when working with Fluttron.

## Build Issues

### `fluttron build` fails with "pnpm not found"

**Symptom**: Running `fluttron build -p <path>` exits with an error like `pnpm: command not found`.

**Cause**: The Fluttron build pipeline uses `pnpm` to bundle the JS frontend. If `pnpm` is not on your `PATH`, the build step fails.

**Solution**:

```bash
# Enable Corepack (ships with Node.js ≥16.9)
corepack enable

# Verify pnpm is available
pnpm --version
```

If you installed Node.js via Homebrew or nvm, make sure the active Node version has Corepack enabled:

```bash
nvm use --lts
corepack enable
pnpm --version
```

Then re-run `fluttron build`.

---

### `flutter build web` fails inside `fluttron build`

**Symptom**: Build output shows `flutter build web` failing with errors about web support not being enabled.

**Cause**: Flutter web support may not be activated for your current Flutter channel, or you are on an unsupported channel.

**Solution**:

```bash
# Switch to stable channel
flutter channel stable
flutter upgrade

# Enable web support
flutter config --enable-web
flutter devices  # should list "Chrome" and "Web server"
```

Then retry the build.

---

### Assets not loading in the WebView (blank screen or 404)

**Symptom**: The app launches but the WebView shows a blank screen. The Flutter console logs errors like `ERR_FILE_NOT_FOUND` for `index.html`.

**Cause**: `fluttron build` copies UI output into `host/assets/www/`. If the copy step did not run (e.g. you ran `flutter run` directly instead of `fluttron run`), this directory will be empty or stale.

**Solution**:

1. Run a full build first:
   ```bash
   fluttron build -p <path>
   ```
2. Confirm the output exists:
   ```bash
   ls <path>/host/assets/www/
   # should contain: index.html, main.dart.js, flutter.js, ...
   ```
3. Then run the host:
   ```bash
   fluttron run -p <path>
   ```

---

### `fluttron build` passes but web package assets are missing

**Symptom**: The app builds, but a web package widget shows a blank area or a JavaScript error referencing a missing factory function.

**Cause**: Web package JS assets must be built separately before `fluttron build` copies them.

**Solution**:

```bash
# Build the web package frontend first
cd <web_package_path>/frontend
pnpm install
pnpm run js:build

# Then build the app
cd <app_path>
fluttron build -p .
```

Verify discovery with `fluttron packages list -p <app_path>`.

---

## Runtime Issues

### Bridge communication fails — service method returns error

**Symptom**: Calling a Host Service from the UI returns an error like `SERVICE_NOT_FOUND` or `METHOD_NOT_FOUND`.

**Cause**: The service is either not registered on the host side, or the namespace/method name in the call does not match the registered handler.

**Solution**:

1. Check your host `main.dart` to confirm the service is registered:
   ```dart
   final fluttron = FluttronHost(
     services: [
       FileService(),
       MyCustomService(),  // ← must be here
     ],
   );
   ```
2. Verify the namespace and method name. For example, if `MyCustomService` handles `my_service.doWork`, the client must call exactly `my_service.doWork`.
3. Run `fluttron doctor` to rule out environment issues.

---

### WebView shows a white or blank screen after the app launches

**Symptom**: The Flutter host window opens, but the embedded WebView is entirely white with no content.

**Common causes and fixes**:

| Cause | Fix |
|-------|-----|
| `host/assets/www/` is empty | Run `fluttron build -p <path>` first |
| macOS sandbox blocking local file access | Run via `fluttron run` (not bare `flutter run`) |
| Web package JS assets missing | Build web package frontend with `pnpm run js:build` |
| Dart compilation error in UI | Run `fluttron build -p <path>` and check for errors |

For detailed diagnostics, check the Flutter console output when running the host in debug mode.

---

### `LoggingService` messages are not visible in console

**Symptom**: The UI calls `LoggingServiceClient.info(...)`, but nothing appears in the host stdout.

**Cause**: By default, logging output goes to the host process stdout. If you launched the app from Finder or as a packaged `.app`, stdout is not connected to a terminal.

**Solution**: Run the app via the CLI to see log output:

```bash
fluttron run -p <path>
```

You can also read stored log entries via the `logging.getLogs` service call from the UI.

---

### Window control methods (`minimize`, `setFullScreen`, etc.) have no effect

**Symptom**: Calling `WindowServiceClient.minimize()` or similar from the UI does nothing and no error is returned.

**Cause**: `WindowService` depends on `window_manager`. On macOS, the app must be run with the correct entitlements. This issue can also occur if the host was built for a non-desktop target.

**Solution**:

1. Verify the host target is `macos`:
   ```bash
   flutter devices  # confirm "macOS (desktop)" is present
   fluttron run -p <path>
   ```
2. Confirm `WindowService` is registered (see service registration above).
3. On first launch, macOS may require the app to be brought to the foreground before `minimize` takes effect.

---

## CLI Issues

### `fluttron create` fails with "permission denied"

**Symptom**: Running `fluttron create ./my_app` prints `Permission denied` and exits.

**Cause**: The target directory or its parent is read-only, or the CLI was activated with insufficient permissions.

**Solution**:

```bash
# Confirm you can write to the parent directory
ls -la .

# If the target directory already exists and is locked
rm -rf ./my_app
fluttron create ./my_app --name MyApp
```

Do not run `fluttron create` with `sudo` — it can create files owned by root that Flutter tools will later fail to modify.

---

### `fluttron doctor` reports issues

**Symptom**: Running `fluttron doctor` shows one or more ✗ items.

**Solutions by item**:

| Failing check | Fix |
|---------------|-----|
| Flutter SDK not found | Install Flutter from [flutter.dev](https://flutter.dev/docs/get-started/install) and add to `PATH` |
| macOS desktop support disabled | Run `flutter config --enable-macos-desktop` |
| Dart SDK not found | Dart ships with Flutter; ensure `flutter/bin` is in `PATH` |
| Node.js not found | Install Node.js ≥18 from [nodejs.org](https://nodejs.org) |
| pnpm not found | Run `corepack enable && corepack prepare pnpm@latest --activate` |

After addressing each item, re-run `fluttron doctor` to confirm all checks pass.

---

### `fluttron` command not found after `dart pub global activate`

**Symptom**: After activating the CLI, the shell reports `fluttron: command not found`.

**Cause**: The Dart pub global bin directory is not on your `PATH`.

**Solution**:

```bash
# Find the pub global bin path
dart pub global list

# Add to your shell profile (~/.zshrc or ~/.bashrc)
export PATH="$PATH:$HOME/.pub-cache/bin"

# Reload the profile
source ~/.zshrc
```

Then verify:

```bash
fluttron --version
```

---

## FAQ

### Can I use React, Vue, or plain HTML/JS instead of Flutter Web for the UI?

Technically yes. Fluttron's `FluttronHtmlView` can render any HTML/JS content. Web packages can wrap any JavaScript library. However, you lose the Dart type-safety and Flutter widget ecosystem that the default Flutter Web UI layer provides. The recommended approach is Flutter Web for the main UI with JS libraries wrapped via web packages for ecosystem integration.

---

### Does Fluttron support iOS and Android?

The architecture is designed to support mobile, but the current focus is macOS desktop. iOS and Android have not been validated in the v0.1.0-alpha release. Community contributions for mobile targets are welcome.

---

### How does Fluttron's bundle size compare to Electron?

Based on measurements taken from Release builds on an Apple Silicon Mac:

| Framework | Typical bundle size |
|-----------|-------------------|
| Fluttron (macOS) | ~30–50 MB |
| Electron | ~130–200 MB |
| Tauri (macOS) | ~8–15 MB |
| Flutter Desktop (macOS) | ~20–30 MB |

See `docs/performance_baseline.md` in the repository for exact measured values.

---

### Can I use existing Flutter packages in a Fluttron app?

**Host layer**: Any pub.dev package that supports macOS (or your target platform) works in the host. This includes database clients, network libraries, file system utilities, and more.

**UI layer (Flutter Web)**: Packages must support Flutter Web. Check the package's pub.dev page for a web compatibility badge before adding it.

**JS/Web ecosystem**: Wrap JavaScript libraries using Fluttron's web package mechanism to integrate npm packages into your Flutter Web UI.

---

### How do I update the Fluttron framework packages?

Since Fluttron packages are referenced via local `path:` dependencies in the generated project templates, updates are done by pulling the latest Fluttron repository:

```bash
cd <fluttron-repo>
git pull
dart pub global activate --path packages/fluttron_cli  # re-activate CLI
```

Then run `flutter pub get` inside your app's `host/` and `ui/` directories.

---

### Something is not working and it's not listed here

1. Run `fluttron doctor` to check your environment.
2. Run the failing command with full output: check stderr for root cause messages.
3. Search [GitHub Issues](https://github.com/maxiee/Fluttron/issues) for similar reports.
4. Open a new issue using the **Bug Report** template and include:
   - `fluttron --version` output
   - `flutter doctor -v` output
   - The full error message and stack trace
