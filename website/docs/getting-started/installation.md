# Installation

This guide will help you install and set up Fluttron on your development machine.

## Prerequisites

Before installing Fluttron, ensure you have the following installed:

- **Flutter SDK**: [Download and install Flutter](https://docs.flutter.dev/get-started/install)
  - Minimum version: 3.19.0
  - Enable Flutter Desktop support
- **Dart SDK**: Included with Flutter SDK
- **Git**: For cloning the repository

## Clone the Repository

```bash
git clone https://github.com/fluttron/fluttron.git
cd fluttron
```

## Install Dependencies

Fluttron is a monorepo with three packages. Install dependencies for each package:

```bash
cd packages/fluttron_shared
flutter pub get

cd ../fluttron_host
flutter pub get

cd ../fluttron_ui
flutter pub get
```

## Verify Installation

Run the Flutter Web demo to verify everything is set up correctly:

```bash
cd packages/fluttron_ui
./run.sh
```

This will launch the Fluttron UI demo in Chrome browser.

## Next Steps

- [Quick Start Guide](./quick-start.md) - Create your first Fluttron app
- [Project Structure](./project-structure.md) - Understand the monorepo organization
