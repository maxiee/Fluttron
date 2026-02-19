# Contributing to Fluttron

Thank you for your interest in contributing to Fluttron! This document explains how to get set up and how we work.

---

## Getting Started

### Prerequisites

- **Flutter SDK** (stable channel) with macOS desktop support enabled
  - Run `flutter config --enable-macos-desktop` if not already enabled
  - Verify: `flutter doctor`
- **Dart SDK** (comes with Flutter, >= 3.0)
- **Node.js** >= 18 and **pnpm** (for Flutter Web / JS build pipeline)
  - Install pnpm: `npm install -g pnpm`
- **macOS** — primary development and testing platform

### Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-org/fluttron.git
   cd fluttron
   ```

2. **Install Dart dependencies**

   ```bash
   dart pub get -C packages/fluttron_cli
   dart pub get -C packages/fluttron_shared
   ```

3. **Install Flutter dependencies**

   ```bash
   flutter pub get -C packages/fluttron_host
   flutter pub get -C packages/fluttron_ui
   ```

4. **Install JS dependencies** (for web packages and playground)

   ```bash
   pnpm install
   ```

5. **Run the test suite**

   ```bash
   # Dart packages
   cd packages/fluttron_cli && dart test --exclude-tags acceptance
   cd packages/fluttron_shared && dart test

   # Flutter packages
   flutter test packages/fluttron_host
   flutter test packages/fluttron_ui
   ```

### Project Structure

```
fluttron/
├── packages/
│   ├── fluttron_cli/      # CLI tool (fluttron create/build/run/generate/package/doctor)
│   ├── fluttron_shared/   # Shared protocol types (FluttronRequest/Response/Error)
│   ├── fluttron_host/     # Flutter host app framework + built-in services
│   └── fluttron_ui/       # Flutter Web UI framework + service clients
├── templates/             # App and host_service scaffolding templates
├── examples/              # Example applications
│   ├── markdown_editor/   # Full-featured Markdown editor demo
│   └── host_service_demo/ # Custom service scaffolding demo
├── web_packages/          # Web packages (e.g., fluttron_milkdown)
├── playground/            # Development playground app
├── website/               # Docusaurus documentation site
└── docs/                  # Architecture and design documents
```

---

## Development Workflow

### Making Changes

1. **Create a branch** from `main`

   ```bash
   git checkout -b feat/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

2. **Make your changes** following the coding standards below.

3. **Ensure analysis passes** in all affected packages

   ```bash
   dart analyze packages/fluttron_cli
   dart analyze packages/fluttron_shared
   flutter analyze packages/fluttron_host
   flutter analyze packages/fluttron_ui
   ```

4. **Ensure all tests pass**

   ```bash
   cd packages/fluttron_cli && dart test --exclude-tags acceptance
   cd packages/fluttron_shared && dart test
   flutter test packages/fluttron_host
   flutter test packages/fluttron_ui
   ```

5. **Submit a pull request** against `main`.

### Running a Specific Example App

```bash
# Build and run the markdown_editor example
fluttron run -p examples/markdown_editor

# Or build only
fluttron build -p examples/markdown_editor
```

### Activating the CLI Locally

```bash
dart pub global activate --source path packages/fluttron_cli
```

---

## Coding Standards

### Dart / Flutter Style

- Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style).
- Run `dart format .` before committing.
- All `dart analyze` / `flutter analyze` results must be zero issues.

### Documentation

- All comments and documentation must be in **English**.
- New public APIs require **dartdoc comments** (`///`).
- New CLI commands require an update to `website/docs/`.

### Testing

- Every new feature or bug fix must include corresponding tests.
- Unit tests live alongside source files (`test/` directory in each package).
- Acceptance tests (tagged `acceptance`) may require a running environment; exclude them in CI with `--exclude-tags acceptance`.
- Aim to keep code coverage for new code at ≥ 80%.

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | When to use |
|--------|-------------|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `docs:` | Documentation only |
| `test:` | Tests only |
| `refactor:` | Code restructuring without behavior change |
| `chore:` | Build scripts, CI, dependency updates |
| `perf:` | Performance improvement |

Examples:
```
feat: add fluttron doctor command for environment checks
fix: handle null response in WindowService.getSize
docs: update services.md with window.* API reference
test: add unit tests for ModelGenerator nullable types
```

Reference issue numbers when applicable: `fix: resolve file tree refresh bug (#42)`.

---

## Reporting Issues

Please use the GitHub Issue templates:

- **Bug report** — for unexpected behavior or crashes
- **Feature request** — for new capabilities or improvements

Before opening an issue, search existing issues to avoid duplicates.

---

## Pull Request Process

Before submitting a PR, make sure:

- [ ] `dart analyze` / `flutter analyze` passes with zero issues in all affected packages
- [ ] All existing tests continue to pass
- [ ] New tests are added for new functionality
- [ ] Public API changes have dartdoc comments
- [ ] Documentation updated if behavior changes (website docs, inline comments)
- [ ] Commit messages follow the Conventional Commits convention
- [ ] PR description explains *why* the change is needed, not just what was changed

PRs are reviewed on a best-effort basis. We may ask for changes or clarification before merging.

---

## License

By contributing to Fluttron, you agree that your contributions will be licensed under the [MIT License](LICENSE).
