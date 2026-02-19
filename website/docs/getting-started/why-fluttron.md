---
sidebar_position: 0
---

# Why Fluttron?

## The Problem

Desktop app development has a fragmentation problem — and no existing framework solves it cleanly for Flutter/Dart developers.

### Flutter Desktop: Great native performance, but no Web ecosystem

Flutter Desktop runs entirely in a native Dart/C++ runtime. It is fast, has small bundle sizes (~15–30 MB), and shares code across mobile platforms. But it has no access to the JavaScript ecosystem. Need a rich text editor? A chart library? A maps SDK? You are on your own: write it from scratch in Dart, or wrap a native library with FFI.

### Electron: Full web ecosystem, but Node.js only

Electron is the gold standard for desktop apps with web ecosystem access. VS Code, Slack, Discord — all Electron. But if you are a Dart/Flutter developer, Electron forces you to write your host logic in Node.js. You lose type safety across the IPC bridge, and you lose the Dart ecosystem entirely.

### Tauri: Smaller than Electron, but Rust is required

Tauri offers smaller bundle sizes than Electron by using a native WebView and a Rust host. The Web ecosystem is available for the UI layer. But the host is Rust — a different language, a different toolchain, and a steep learning curve for Flutter developers.

### The gap

There is no framework that offers:
- **Dart as the host language** (native services, file system, window management)
- **Web ecosystem access** in the UI layer (JS libraries, web-native widgets)
- **Type-safe IPC** between host and UI with code generation
- **Shared Dart types** between layers

Fluttron fills that gap.

---

## How Fluttron Solves It

Fluttron splits your app into two layers connected by a typed IPC bridge:

```
┌────────────────────────────────────────────────┐
│              Flutter Desktop Host               │
│   Dart runtime · File system · Window mgmt     │
│   Built-in services · Custom host services     │
└────────────────┬───────────────────────────────┘
                 │  Typed IPC Bridge (Dart codegen)
┌────────────────▼───────────────────────────────┐
│             Flutter Web Renderer                │
│   Flutter Web in WebView · JS ecosystem        │
│   Web Packages · Milkdown · Chart.js · Maps    │
└────────────────────────────────────────────────┘
```

**Host layer** (Dart): Handles native platform operations — file I/O, window control, clipboard, dialogs, key-value storage, logging. You extend it with custom host services using the code generator.

**Renderer layer** (Flutter Web): Renders the UI inside a WebView. Since it's Flutter Web, you can embed any JavaScript library as a Web Package — a typed Dart wrapper around a JS bundle.

**Bridge layer** (generated Dart): A contract-driven IPC protocol. You define a service contract with Dart annotations; the CLI generates the host handler, the client stub, and the shared models. No string-based message passing. No manual serialization.

---

## Comparison

| Feature | Electron | Tauri | Wails | Flutter Desktop | **Fluttron** |
|---|---|---|---|---|---|
| Host language | Node.js | Rust | Go | Dart | **Dart** |
| UI layer | HTML/CSS/JS | HTML/CSS/JS | HTML/CSS/JS | Flutter widgets | **Flutter Web + JS** |
| Web ecosystem | Full | Full | Full | ✗ | **Full** |
| Type-safe IPC | Manual | Rust macros | Auto | N/A | **Dart codegen** |
| Shared types across layers | ✗ | ✗ | Partial | N/A | **Yes (Dart)** |
| Bundle size (typical) | 120–200 MB | 2–10 MB | 8–15 MB | 15–30 MB | **~50 MB** |
| Flutter widget support in UI | ✗ | ✗ | ✗ | Full | **Full (Flutter Web)** |
| Mobile support | ✗ | Partial (v2) | ✗ | Yes | **Planned** |
| Primary language | JavaScript | Rust | Go | Dart | **Dart** |
| Learning curve for Flutter devs | High | High | Medium | Low | **Low** |

### Bundle size context

Fluttron's ~50 MB bundle reflects the Flutter Web runtime embedded in the WebView assets plus the Flutter Desktop host binary. This is larger than Tauri (which uses the OS WebView), but significantly smaller than Electron (which ships a full Chromium). For most desktop apps, 50 MB is an acceptable trade-off for full web ecosystem access and Dart-native host services.

### Type-safe IPC — the detail that matters

In Electron, calling a host API from the renderer looks like:

```javascript
// renderer
const result = await ipcRenderer.invoke('file:read', { path: '/tmp/data.json' });
// result is `any` — no types, no autocomplete, no compile-time safety
```

In Fluttron, you define a contract:

```dart
@FluttronServiceContract(namespace: 'file')
abstract class FileServiceContract {
  Future<String> readFile(String path);
}
```

The CLI generates the host handler and the UI client:

```dart
// UI side — fully typed, IDE autocomplete included
final content = await fileClient.readFile('/tmp/data.json');
```

If the host changes its signature, the client fails at compile time — not at runtime.

---

## When to Use Fluttron

Fluttron is a strong fit when:

- **You are a Flutter/Dart developer** building a desktop app and want to stay in Dart for the host layer.
- **You need JS library access** — rich text editors (Milkdown, TipTap), chart libraries (ECharts, Chart.js), maps (Mapbox, Leaflet), PDF renderers, syntax highlighters, or any other established JS ecosystem package.
- **You need native platform services** — file system, window management, clipboard, system dialogs — and want them as typed Dart APIs, not string-based RPC.
- **You are building a productivity tool** — document editors, code editors, dashboards, data viewers — where both rich UI fidelity and native platform integration matter.
- **You want to share code between desktop and mobile** — Fluttron's host services are designed with a path to mobile (iOS/Android) via the same bridge protocol.

Concrete use cases:
- Markdown / rich text editors with WYSIWYG JS-powered editors
- Data visualization dashboards using ECharts or D3
- Internal developer tools with native file system access
- Note-taking apps with web-native plugins
- Cross-platform productivity apps replacing Electron with a smaller, Dart-native stack

---

## When NOT to Use Fluttron

Fluttron is **not** the right tool when:

- **You are building a pure mobile app.** Fluttron's primary target is desktop (macOS today, Windows/Linux planned). Use Flutter directly for iOS/Android.
- **Your app is simple and has no web ecosystem needs.** If you just need a form, a settings screen, or a data list, Flutter Desktop alone is simpler and faster.
- **Bundle size is critical and must be under 20 MB.** Fluttron ships Flutter Web assets inside the app bundle. If you are targeting minimal footprint, consider Tauri (uses OS WebView) or Flutter Desktop.
- **Your team is not already using Dart/Flutter.** If your team is Node.js or Rust native, Electron or Tauri is a better fit — Fluttron's advantage is specifically for Flutter/Dart teams.
- **You need Windows or Linux support today.** Fluttron currently supports macOS. Windows and Linux support is planned for post-v0.1.0.
- **You need a plugin ecosystem.** Fluttron is early-stage. There are no third-party plugins yet beyond the built-in services and the `fluttron_milkdown` example package.
- **You are building a game.** Games have specialized rendering requirements; use Flutter's game engines or native game frameworks.

---

## Summary

Fluttron exists for one specific audience: **Flutter developers who need the Web ecosystem on the desktop without switching to a non-Dart host language**.

If that describes you, Fluttron gives you:

1. A Dart-native host with built-in services and a code-generated extension mechanism.
2. A Flutter Web renderer with full JS library access via typed Web Packages.
3. A generated, type-safe IPC bridge with shared Dart models.
4. A CLI that wires it all together: `create`, `build`, `run`, `package`, `generate services`, `doctor`.

**Next step**: [Quick Start →](./quick-start)
