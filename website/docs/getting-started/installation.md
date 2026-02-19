---
sidebar_position: 1
---

# Installation

This guide sets up Fluttron for local development on macOS (initial focus).

## Prerequisites

- **Flutter SDK (stable)** with desktop support enabled
- **Dart SDK** (bundled with Flutter)
- **Node.js** (for template frontend build pipeline)
- **pnpm** (recommended via Corepack)
- **Git**

Verify Flutter is available:

```bash
flutter --version
flutter doctor
```

Enable macOS desktop if needed:

```bash
flutter config --enable-macos-desktop
```

Enable Corepack and check pnpm:

```bash
corepack enable
pnpm --version
```

## Clone the Repository

```bash
git clone https://github.com/maxiee/Fluttron.git
cd Fluttron
```

## Install CLI (Recommended)

Activate the CLI from the repo so you can use `fluttron` globally:

```bash
dart pub global activate --path packages/fluttron_cli
```

If you prefer not to install globally, you can run it directly with:

```bash
dart run packages/fluttron_cli/bin/fluttron.dart --help
```

## Install Package Dependencies (Repo Development)

For working on the core packages:

```bash
cd packages/fluttron_shared
flutter pub get

cd ../fluttron_host
flutter pub get

cd ../fluttron_ui
flutter pub get
```

## Next Steps

- [Quick Start Guide](./quick-start.md) - Create your first Fluttron app
- [Project Structure](./project-structure.md) - Understand repo and template layout
