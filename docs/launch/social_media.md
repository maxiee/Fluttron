# Launch Day Social Media

GitHub: https://github.com/maxiee/Fluttron
Docs: https://maxiee.github.io/Fluttron/

---

## Twitter/X (English)

### Tweet 1 — Main announcement (≤ 280 chars)

```
Introducing Fluttron 🎉

Build desktop apps with Flutter + Web ecosystem.

Dart-native host. Flutter Web renderer. Type-safe IPC bridge with codegen.

Think Electron, but for Flutter devs.

GitHub: https://github.com/maxiee/Fluttron

#Flutter #Dart #OpenSource #CrossPlatform
```

> Character count: ~220 ✓

### Tweet 2 — Follow-up thread (≤ 280 chars each)

```
Why? Flutter Desktop is great but has zero access to the JS ecosystem.

Rich-text editors, code editors, charts — these live in JS land.

Fluttron bridges both worlds: write your host in Dart, render your UI with Flutter Web, and drop in any JS library.

#Flutter #Dart
```

> Character count: ~255 ✓

```
What's in Fluttron v0.1.0-alpha:

✅ CLI: create / build / run / package / doctor
✅ Built-in services: file, dialog, window, logging
✅ Codegen for custom services
✅ Web Package system for JS integration
✅ Markdown editor example (Milkdown)

https://github.com/maxiee/Fluttron
```

> Character count: 274 ✓

---

## Weibo（中文）

```
发布 Fluttron v0.1.0-alpha —— 面向 Flutter 开发者的跨端桌面应用框架 🎉

灵感来自 Electron，但完全基于 Dart 生态：

🔷 宿主层：Flutter Desktop（Dart 原生服务体系）
🔷 渲染层：Flutter Web + WebView（可无缝集成 JS 生态）
🔷 类型安全的双向 IPC Bridge，支持代码生成

亮点能力：
• 一条命令创建/构建/运行/打包应用：`fluttron create / build / run / package`
• 内建五大 Host Service：文件、对话框、剪贴板、窗口控制、结构化日志
• 自定义服务 + 代码生成（写一个 Dart 契约文件，CLI 自动生成 Host 实现与 UI Client）
• Web Package 机制：把 Milkdown、CodeMirror、Chart.js 这类 JS 库打包进 Fluttron 应用
• 官方示例：`markdown_editor`——用 Milkdown 做渲染引擎的桌面 Markdown 编辑器

如果你曾经纠结「Flutter 桌面里怎么集成 JS 生态」，这个项目可能是你需要的答案。

GitHub: https://github.com/maxiee/Fluttron
文档: https://maxiee.github.io/Fluttron/

#Flutter #Dart #开源 #桌面开发 #跨端
```

---

## Reddit r/FlutterDev

### Post title (choose one)

- "I built an Electron-inspired desktop framework for Flutter — Fluttron (v0.1.0-alpha)"
- "Fluttron: Flutter Desktop host + Flutter Web renderer + JS ecosystem integration + typed IPC codegen"
- "Show r/FlutterDev: Fluttron — build Electron-style apps while staying in Dart"

### Post body

```
Hey r/FlutterDev 👋

I've been building Fluttron for the past several months and just hit v0.1.0-alpha.
Sharing here because I think this scratches an itch a lot of Flutter desktop devs have.

**The problem**: Flutter Desktop is great for native UI, but the moment you want to
embed something like a rich-text editor (ProseMirror/Milkdown), a code editor
(CodeMirror/Monaco), or charts (Chart.js/D3) — you're stuck. Rewriting those in
Flutter widgets is months of work and usually worse.

**What Fluttron does**:
- Flutter Desktop host with a service layer (file, dialog, window, logging, etc.)
- Flutter Web UI running inside a WebView (full JS ecosystem access)
- Typed bidirectional IPC bridge with codegen support
- CLI toolchain: `fluttron create / build / run / package / doctor`
- Web Package system for integrating JS libraries cleanly

**The architecture in one picture**:
```
┌──────────────────────────────────────────────┐
│          Flutter Desktop Host                 │
│  ServiceRegistry → FileService, WindowService │
│  WebView Container ←──────────────────────── │
└──────────────┬───────────────────────────────┘
               │  IPC Bridge
┌──────────────┴───────────────────────────────┐
│       Flutter Web in WebView                  │
│  FluttronClient.invoke("file.readFile", ...)  │
│  JS libraries embedded via Web Packages       │
└──────────────────────────────────────────────┘
```

**What's included in v0.1.0-alpha**:
- Full CLI (`create` / `build` / `run` / `package` / `doctor` / `generate services`)
- 5 built-in host services (file, dialog, clipboard, window, logging)
- Custom service codegen from a Dart contract annotation
- Web Package mechanism for JS library integration
- `examples/markdown_editor`: a real markdown editor using Milkdown

GitHub: https://github.com/maxiee/Fluttron
Docs: https://maxiee.github.io/Fluttron/

Happy to answer questions about the design — especially the bridge protocol,
the Web Package system, or the codegen approach. Still early but the core
architecture is stable.
```

---

## Hacker News

### Title (choose one)

- "Show HN: Fluttron – Electron-inspired desktop framework for Dart/Flutter"
- "Show HN: Fluttron – Flutter Desktop host + Flutter Web renderer, with typed IPC codegen"

### Comment body (for Show HN submission)

```
Fluttron is an Electron-inspired desktop application framework built on Dart and Flutter.

The core idea: Flutter Desktop as the host (native services, lifecycle, permissions)
+ Flutter Web running inside a WebView (UI and JS ecosystem access)
+ a typed bidirectional IPC bridge connecting the two.

The problem it solves: Flutter Desktop gives you excellent native UI in Dart, but
no path to the JS ecosystem. Components like Milkdown (rich text), CodeMirror
(code editor), or Chart.js have years of community investment. Rewriting them as
Flutter widgets is impractical. Fluttron lets you use them directly.

v0.1.0-alpha ships with:
- CLI toolchain: create / build / run / package (→ .app / .dmg) / doctor
- 5 built-in host services: file I/O, native dialogs, clipboard, window control, logging
- Typed IPC codegen: write a Dart @FluttronServiceContract, CLI generates host impl + UI client
- Web Package system: package a JS library (Milkdown, CodeMirror, etc.) as a reusable Fluttron package
- Example app: a Markdown editor using Milkdown as the renderer

Current target: macOS desktop. Architecture supports Android/iOS but not the focus yet.

GitHub: https://github.com/maxiee/Fluttron
Docs: https://maxiee.github.io/Fluttron/

I'm the author. Happy to discuss the bridge design, codegen approach, or why I chose
Flutter Web inside a WebView rather than a raw WebView + plain HTML/JS.
```
