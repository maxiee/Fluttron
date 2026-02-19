# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Fluttron, please report it responsibly.

**Do NOT create a public GitHub issue for security vulnerabilities.**

Instead, use one of the following channels:

- **GitHub Private Vulnerability Reporting**: Navigate to the repository's
  **Security → Advisories** tab and click **"Report a vulnerability"**.
- **Email**: If private reporting is unavailable, email the maintainers directly
  (see the `CONTRIBUTING.md` for contact details).

Please include as much of the following information as possible to help us triage quickly:

- A description of the vulnerability and its potential impact
- Steps to reproduce or proof-of-concept code
- Affected versions and components
- Any suggested mitigations

## Response Timeline

| Step | Target time |
|------|-------------|
| Acknowledge receipt | Within 48 hours |
| Initial assessment | Within 1 week |
| Fix & coordinated disclosure | Agreed with reporter |

We follow [Responsible Disclosure](https://en.wikipedia.org/wiki/Coordinated_vulnerability_disclosure).
We will credit reporters in the release notes unless they prefer to remain anonymous.

## Scope

This policy covers the core Fluttron framework packages:

| Package | Description |
|---------|-------------|
| `fluttron_cli` | Command-line tooling (create / build / run / package) |
| `fluttron_host` | Flutter host runtime and built-in services |
| `fluttron_shared` | Shared protocol types and bridge definitions |
| `fluttron_ui` | Flutter Web UI library and service clients |

Out-of-scope items include third-party dependencies (report those to the relevant upstream
project), example applications under `examples/`, and playground applications.

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.1.x (upcoming) | ✅ Yes |
| < 0.1.0-dev | ❌ No — pre-release; upgrade to latest |

Pre-release (`0.1.0-dev`) builds are actively developed. We will apply security fixes to
the latest development branch; older pre-release snapshots are not patched separately.

## Security Best Practices for Fluttron Applications

When building applications with Fluttron, consider the following:

- **WebView content**: Only load trusted content in the embedded WebView. Treat the
  WebView's JS environment as untrusted input when designing bridge handlers.
- **Bridge handlers**: Validate and sanitise all parameters received via
  `ServiceRegistry` handlers before passing them to native APIs.
- **File system access**: Use `FileService` with the minimum required permissions;
  avoid exposing raw path traversal to the UI layer.
- **Storage service**: Do not store sensitive credentials in `StorageService`
  (backed by `SharedPreferences`); use the platform keychain instead.
