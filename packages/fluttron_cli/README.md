# fluttron_cli

Command-line tool for creating, building, and managing Fluttron applications.

## Installation

```bash
dart pub global activate --path packages/fluttron_cli
```

## Commands

### `fluttron create`

Scaffold a new project.

```bash
# Create a new Fluttron app
fluttron create my_app --name MyApp

# Create a Fluttron web package
fluttron create my_package --name my_pkg --type web_package

# Create a host service (host + client dual packages)
fluttron create my_service --name my_svc --type host_service
```

### `fluttron build`

Build the Fluttron app (UI + Host).

```bash
fluttron build -p path/to/my_app
```

### `fluttron run`

Build and launch the app in debug mode.

```bash
fluttron run -p path/to/my_app
```

### `fluttron package`

Package the app for distribution.

```bash
# Build a .app bundle
fluttron package -p path/to/my_app

# Build a .app and wrap in a .dmg
fluttron package -p path/to/my_app --dmg
```

Output is written to `<path>/dist/`.

### `fluttron generate services`

Generate typed Host/Client/Model code from a service contract.

```bash
fluttron generate services \
  --contract lib/src/my_service_contract.dart \
  --host-output ../my_service_host/lib/src/ \
  --client-output ../my_service_client/lib/src/ \
  --shared-output ../my_service_shared/lib/src/
```

Use `--dry-run` to preview output without writing files.

### `fluttron packages list`

List all web packages discovered in the current app.

```bash
fluttron packages list -p path/to/my_app
```

### `fluttron doctor`

Check the local environment for required dependencies.

```bash
fluttron doctor
```

Checks: Flutter SDK, Dart SDK, Node.js, pnpm, macOS desktop support.

### `fluttron --version`

Print the current CLI version.

```bash
fluttron --version
```

## Documentation

Full documentation: <https://maxiee.github.io/Fluttron/>

- [Getting Started](https://maxiee.github.io/Fluttron/docs/getting-started/installation)
- [CLI Reference](https://maxiee.github.io/Fluttron/docs/api/cli)
- [Custom Services](https://maxiee.github.io/Fluttron/docs/getting-started/custom-services)
- [Code Generation](https://maxiee.github.io/Fluttron/docs/api/codegen)
