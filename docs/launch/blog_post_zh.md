# 介绍 Fluttron：为 Flutter 开发者打造的 Electron 替代方案

_2026 年 2 月 — v0.1.0-alpha_

---

## 问题所在

Flutter Desktop 非常擅长用 Dart 构建原生 UI。但有一类桌面应用，它处理起来并不理想：**需要嵌入丰富 Web 生态组件的应用**。

想想开发者实际在构建的工具：

- 基于 ProseMirror 或 Milkdown 的富文本编辑器
- 嵌入 Chart.js 或 D3 的数据看板
- 使用 CodeMirror 或 Monaco 的代码编辑器
- 基于 Reveal.js 的演示工具

这些组件经过多年打磨，拥有活跃的社区和深厚的 JS 生态。要在 Flutter Widget 中重写它们，意味着从头再造数年的工作成果——或者接受一个功能明显逊色的替代品。

**在 Fluttron 出现之前，你的选择：**

- **Electron**：功能强大，但迫使你离开 Dart 转向 Node.js。体积庞大：打包后 120–200 MB。需要维护两套运行时。
- **Tauri**：轻量、基于 Rust，但宿主层要用 Rust 编写。生态系统整合较弱。
- **Flutter Desktop（纯原生）**：纯 Dart，但完全无法访问 JS 生态。要么一切自建，要么放弃。
- **原生 flutter_inappwebview**：可以嵌入 WebView，但没有任何结构——没有类型安全的 IPC、没有服务注册、没有代码生成、没有 CLI 工具链。只有你和 `evaluateJavascript`。

以上选项都不适合"想留在 Dart 的同时又能调用 Web 生态丰富能力"的 Flutter 开发者。这正是 Fluttron 要填补的空白。

---

## Fluttron 是什么？

Fluttron 是面向 Dart 和 Flutter 开发者的、受 Electron 启发的桌面应用框架。它将 **Flutter Desktop 宿主**与运行在 WebView 内的 **Flutter Web 渲染层**结合在一起，通过类型安全的双向 IPC Bridge 相连。

```
┌─────────────────────────────────────────────────────────┐
│            Fluttron Host（Flutter Desktop）               │
│                                                           │
│  main.dart ──► ServiceRegistry ──► WindowService         │
│                                ──► FileService            │
│                                ──► StorageService         │
│                                ──► 自定义服务              │
│                                                           │
│  WebView 容器 ◄────────────────────────────────────────── │
└──────────────┬──────────────────────────────────────────┘
               │  IPC Bridge（WebView JS Handler）
               │  FluttronRequest / FluttronResponse
┌──────────────┴──────────────────────────────────────────┐
│            Fluttron UI（WebView 内的 Flutter Web）         │
│                                                           │
│  FluttronApp ──► WindowServiceClient                      │
│              ──► FileServiceClient                        │
│              ──► 你的应用 Widget                           │
│              ──► Web Packages（Flutter + JS/CSS）          │
└─────────────────────────────────────────────────────────┘
```

**三层架构：**

1. **Host（Flutter Desktop）**：原生平台访问——窗口管理、文件系统、对话框、剪贴板、持久化存储、结构化日志。全部用 Dart 编写。
2. **Bridge（WebView JS Handler）**：类型安全的 `FluttronRequest` / `FluttronResponse` 消息，按 `namespace.method` 路由。双向通信——UI 调用 Host 服务，Host 也可以向 UI 推送事件。
3. **UI（WebView 内的 Flutter Web）**：应用 UI 是一个 Flutter Web 应用——完整的 Flutter Widget 树，通过 Web Packages 访问完整的 JS 生态。

核心洞察：**两层都是 Dart**。同一种语言，同一套类型系统，同一套工具链。Bridge 只是在两个恰好运行在不同上下文中的 Dart 程序之间传递消息。

---

## 核心功能

### 1. CLI 工具链

```bash
# 新建应用
fluttron create ./my_app --name MyApp

# 构建 UI、同步资源、生成注册代码
fluttron build -p ./my_app

# 运行
fluttron run -p ./my_app

# 打包为可分发的 .app / .dmg
fluttron package -p ./my_app
fluttron package -p ./my_app --dmg
```

CLI 处理了双层构建的所有复杂性：编译 Flutter Web、运行 JavaScript 构建流水线、收集 Web Package 资源、将它们注入 HTML、生成注册代码，并将所有内容串联在一起。你只需运行 `fluttron build`。

### 2. 内建宿主服务

每个 Fluttron 应用自带七个开箱即用的宿主服务：

| 服务 | 功能 |
|---|---|
| `WindowService` | 设置标题、调整大小、最小化、最大化、全屏 |
| `FileService` | 读写文件、列目录、stat、重命名、删除 |
| `DialogService` | 原生文件打开/保存对话框和目录选择器 |
| `ClipboardService` | 读写系统剪贴板 |
| `SystemService` | 获取平台信息、语言区域、用默认浏览器打开 URL |
| `StorageService` | 持久化键值存储（应用重启后数据保留） |
| `LoggingService` | 结构化环形缓冲日志（1000 条，支持 debug/info/warn/error） |

每个服务在 Host 侧有实现，在 `fluttron_ui` 中有类型安全的 Dart Client。在 Flutter Web UI 中调用服务：

```dart
final window = WindowServiceClient(client: FluttronClient.instance);
await window.setTitle('我的文档 — Fluttron 编辑器');
await window.maximize();

final storage = StorageServiceClient(client: FluttronClient.instance);
await storage.kvSet('theme', 'dark');
final theme = await storage.kvGet('theme'); // 'dark'
```

没有字符串拼接式调用，没有手动 JSON 序列化，纯粹的 Dart。

### 3. 类型安全的服务代码生成

需要添加自定义平台能力？先定义一个契约：

```dart
// todo_contract.dart
@FluttronServiceContract(namespace: 'todo')
abstract class TodoServiceContract {
  Future<List<TodoItem>> getTodos();
  Future<void> addTodo({required String title, String? note});
  Future<void> deleteTodo({required String id});
  Future<void> toggleTodo({required String id});
}

@FluttronModel()
class TodoItem {
  final String id;
  final String title;
  final bool completed;
  final String? note;
}
```

执行一条命令：

```bash
fluttron generate services --contract todo_contract.dart
```

CLI 自动生成：
- `TodoServiceBase` — 抽象宿主侧基类，包含路由 `switch/case` 和参数提取
- `TodoServiceClient` — 带序列化/反序列化的类型安全 Dart Client
- `TodoItem.fromMap()` / `toMap()` — 模型类

你只需实现业务逻辑，框架处理所有 IPC 管道工程。

### 4. Web Package 系统

Web Package 是 Fluttron 的插件格式。一个 Web Package 打包了：
- Flutter Widget（Dart 侧）
- JavaScript 模块（Web 侧）
- CSS 资源（可选）

真正强大之处：**应用在构建时自动发现、收集并注册所有 Web Package**，无需任何手动集成步骤。

举例：`fluttron_milkdown` 是一个生产可用的 Milkdown 富文本编辑器 Web Package。在应用中使用它：

```bash
# 添加到 pubspec.yaml
flutter pub add fluttron_milkdown

# 就这样——fluttron build 会处理剩余一切
fluttron build -p ./my_app
```

在 Flutter Web UI 中：

```dart
MilkdownEditor(
  initialContent: markdownContent,
  theme: MilkdownTheme.nord,
  onContentChange: (content) => setState(() => _content = content),
  controller: _milkdownController,
)
```

底层工作：CLI 读取 `package_config.json`，发现 `fluttron_milkdown`，将其 JS/CSS 资源复制到 `assets/www/`，向 HTML 注入 `<script>` 和 `<link>` 标签，并生成视图注册代码。全程自动。

---

## 实际效果

**CLI 创建 → 构建 → 运行演示：**

![Fluttron CLI Demo](../screenshots/demo.gif)

**Fluttron Markdown Editor** — 用 Fluttron 构建的生产级演示应用：

![Fluttron Markdown Editor](../screenshots/markdown_editor.png)

演示的功能：
- 通过 `FileService` + `DialogService` 打开文件夹，展示文件树
- 加载和保存 `.md` 文件，带脏状态指示
- 通过 `fluttron_milkdown` 实现富文本编辑（Milkdown + GFM + 语法高亮）
- 通过 `WindowServiceClient` 动态设置窗口标题
- 通过 `StorageServiceClient` 切换并持久化主题
- 通过 `LoggingServiceClient` 记录操作日志

---

## 工作原理：快速代码追踪

以一次完整的服务调用为例，从头到尾走一遍。

### 第一步：UI 调用 Service Client

```dart
// 在你的 Flutter Web Widget 中
final file = FileServiceClient(client: FluttronClient.instance);
final content = await file.readFile('/path/to/document.md');
```

### 第二步：UI Bridge 序列化请求

`FluttronClient.invoke()` 将调用包装为 `FluttronRequest`：

```json
{
  "namespace": "file",
  "method": "readFile",
  "params": { "path": "/path/to/document.md" },
  "requestId": "req-42"
}
```

该 JSON 通过 WebView 的 JavaScript Handler 发送给 Host。

### 第三步：Host 路由请求

`ServiceRegistry` 接收消息，提取 `namespace.method`，路由到 `FileService.handleRequest()`，从磁盘读取文件并返回 `FluttronResponse`。

### 第四步：响应返回

响应通过 `webViewController.callAsyncJavaScript()` 传回，在 UI Bridge 中被反序列化，Widget 中的 `Future<String>` 完成。

对于非 I/O 操作，整个往返通常 **< 5ms**。Dart 类型系统在编译时捕获两端的类型不匹配。

---

## 快速上手

**前置条件**：Flutter SDK（stable，已启用 macOS 桌面支持）、Node.js ≥ 18、pnpm

```bash
# 1. 克隆仓库
git clone https://github.com/maxiee/Fluttron.git
cd Fluttron

# 2. 安装 CLI
dart pub global activate --path packages/fluttron_cli

# 3. 检查环境
fluttron doctor

# 4. 创建并运行你的第一个应用
fluttron create ./hello_fluttron --name HelloFluttron
fluttron build -p ./hello_fluttron
fluttron run -p ./hello_fluttron
```

你会看到一个 macOS 窗口弹出，里面运行着 Flutter Web UI。接下来：

- 编辑 `hello_fluttron/ui/lib/main.dart` 修改 UI（这是一个 Flutter Web 应用）
- 编辑 `hello_fluttron/host/lib/main.dart` 添加 Host 服务
- 运行 `fluttron build -p ./hello_fluttron && fluttron run -p ./hello_fluttron` 重新构建

### 运行示例应用

```bash
# 运行 Markdown Editor 演示
fluttron build -p examples/markdown_editor
fluttron run -p examples/markdown_editor

# 运行 Host Service 演示
fluttron build -p examples/host_service_demo
fluttron run -p examples/host_service_demo
```

### 创建自定义服务

```bash
# 生成 Host Service 双包脚手架
fluttron create ./my_service --type host_service --name MyService

# 编写契约后，生成实现代码
fluttron generate services --contract my_service_contract.dart
```

---

## 打包体积

基于 WebView 的框架，打包体积是常见顾虑。Fluttron 的对比：

| 框架 | 典型体积 | 说明 |
|---|---|---|
| Electron | 120–200 MB | 捆绑完整 Chromium + Node.js |
| Tauri | 2–10 MB | 使用系统 WebView，极度轻量 |
| Flutter Desktop | 15–30 MB | 纯 Flutter，无 WebView |
| **Fluttron** | **~94 MB** | Flutter 宿主 + 系统 WebKit（WKWebView） |

Fluttron 使用**系统 WebKit**（macOS 上的 WKWebView），而非捆绑 Chromium，这使其体积远小于 Electron。~94 MB 的占用主要来自 Flutter 框架本身（约 60–70 MB）；添加像 `fluttron_milkdown` 这样复杂的 Web Package 不会显著增加体积。

---

## 未来规划

Fluttron v0.1.0-alpha 专注于 macOS。路线图如下：

**近期（v0.2.0）**：
- Windows 支持
- 系统托盘集成
- 原生菜单栏支持
- Web Package 插件系统

**中期（v0.3.0）**：
- pub.dev 发布（API 稳定后）
- 应用自动更新
- 多窗口支持
- iOS/Android 专项验证

**远期**：
- Linux 支持
- 性能分析工具
- Web Package 层热重载

---

## 现在就试试

**GitHub**：[https://github.com/maxiee/Fluttron](https://github.com/maxiee/Fluttron)

**文档**：[https://maxiee.github.io/Fluttron](https://maxiee.github.io/Fluttron)

**示例**：
- `examples/markdown_editor` — 完整 Markdown 编辑器（文件系统、窗口控制、主题）
- `examples/host_service_demo` — 自定义服务脚手架与代码生成演示
- `packages/fluttron_milkdown` — Web Package 参考实现

如果你是一名 Flutter 开发者，曾经希望在桌面应用中使用某个 JS 库而不必离开 Dart 生态，Fluttron 就是为你构建的。欢迎 Star 仓库、尝试快速入门，并告诉我们你的想法。

---

_Fluttron 基于 MIT 协议开源，欢迎贡献。参阅 [CONTRIBUTING.md](../../CONTRIBUTING.md) 了解如何参与。_
