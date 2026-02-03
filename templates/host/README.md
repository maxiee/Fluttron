# Host Template

This folder represents the Flutter desktop host template.

Minimum expectations:

- `lib/main.dart` calls `runFluttronHost(...)` from `fluttron_host`.
- `pubspec.yaml` depends on `fluttron_host` and `fluttron_shared`.
- `assets/www/` is the Web asset directory loaded by the host.
