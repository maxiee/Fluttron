# fluttron_ui

Fluttron 渲染层（Renderer）核心库，基于 Flutter Web 运行于 WebView 容器内。

## 概述

`fluttron_ui` 是 Fluttron 双层架构中的**渲染层**组件。它以 Flutter Web 形式运行，被嵌入到宿主应用（Host）的 WebView 中，负责 UI 渲染与业务逻辑。

```
┌─────────────────────────────────────────────────────────────┐
│                    Fluttron Host (原生)                      │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   WebView 容器                         │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │           fluttron_ui (Flutter Web)              │  │  │
│  │  │  ┌─────────────┐  ┌──────────────────────────┐  │  │  │
│  │  │  │FluttronClient│◄─┤ flutter_inappwebview    │  │  │  │
│  │  │  └──────┬──────┘  │   callHandler('fluttron')│  │  │  │
│  │  │         │         └──────────────────────────┘  │  │  │
│  │  │         ▼                                        │  │  │
│  │  │  ┌─────────────┐  ┌──────────────────────────┐  │  │  │
│  │  │  │FluttronHtmlView│─►│ HtmlElementView        │  │  │  │
│  │  │  └─────────────┘  │   (JS Factory)           │  │  │  │
│  │  │                   └──────────────────────────┘  │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
│                           ▲                                  │
│                           │ ServiceRegistry                 │
│                    ┌──────┴──────┐                          │
│                    │ Host Bridge │                          │
│                    └─────────────┘                          │
└─────────────────────────────────────────────────────────────┘
```

## 核心架构

### 1. 应用入口（UI App）

```dart
// lib/src/ui_app.dart
void runFluttronUi({
  String title = 'Fluttron App',
  required Widget home,
  bool debugBanner = false,
})
```

封装 Flutter Web 应用启动逻辑，提供统一的入口点。

### 2. 宿主通信客户端（FluttronClient）

```dart
// lib/fluttron/fluttron_client.dart
class FluttronClient {
  // 通用 RPC 调用
  Future<dynamic> invoke(String method, Map<String, dynamic> params);
  
  // 内置服务方法
  Future<String> getPlatform();
  Future<void> kvSet(String key, String value);
  Future<String?> kvGet(String key);
}
```

**通信协议**：
- 基于 `flutter_inappwebview` 的 JavaScript Handler 机制
- 请求格式：`FluttronRequest { id, method, params }`
- 响应格式：`FluttronResponse { ok, result?, error? }`
- 调用路径：`window.flutter_inappwebview.callHandler('fluttron', payload)`

**使用示例**：
```dart
final client = FluttronClient();

// 调用系统服务
final platform = await client.getPlatform();

// 调用存储服务
await client.kvSet('theme', 'dark');
final theme = await client.kvGet('theme');

// 通用调用
final result = await client.invoke('custom.method', {'arg': 'value'});
```

### 3. 事件桥（Event Bridge）

```dart
// lib/src/event_bridge.dart
class FluttronEventBridge {
  Stream<Map<String, dynamic>> on(String eventName);
  void dispose();
}
```

**功能**：监听来自宿主（或外部 JavaScript）的浏览器 `CustomEvent` 事件。

**工作原理**：
1. 宿主通过 WebView 注入 JavaScript 触发 `CustomEvent`
2. `FluttronEventBridge` 通过 `window.addEventListener` 监听
3. 将 `event.detail` 解析为 `Map<String, dynamic>` 并通过 Dart Stream 发送

**使用示例**：
```dart
final bridge = FluttronEventBridge();

bridge.on('host-event').listen((data) {
  print('Received: ${data['message']}');
});

// 记得释放资源
bridge.dispose();
```

### 4. HTML 视图组件（Html View）

```dart
// lib/src/html_view.dart
class FluttronHtmlView extends StatefulWidget {
  const FluttronHtmlView({
    required this.type,           // 视图类型标识
    this.args,                    // 传递给 JS 工厂的参数
    this.loadingBuilder,          // 加载中占位组件
    this.errorBuilder,            // 错误占位组件
  });
}
```

**功能**：在 Flutter Web 中嵌入原生 HTML 元素，基于 `HtmlElementView` 实现。

**工作流程**：
1. 从 `FluttronWebViewRegistry` 查找注册的 JS 工厂函数
2. 根据参数生成唯一的 `resolvedViewType`（使用 FNV-1a 哈希）
3. 调用 `ui_web.platformViewRegistry.registerViewFactory` 注册视图工厂
4. 渲染 `HtmlElementView` 组件

**使用示例**：
```dart
// 1. 注册视图类型
FluttronWebViewRegistry.register(
  FluttronWebViewRegistration(
    type: 'my-chart',
    jsFactoryName: 'createMyChart',
  ),
);

// 2. 在 UI 中使用
FluttronHtmlView(
  type: 'my-chart',
  args: [{'data': [1, 2, 3]}],
  loadingBuilder: (_) => CircularProgressIndicator(),
)
```

### 5. 视图注册中心（Web View Registry）

```dart
// lib/src/web_view_registry.dart
abstract final class FluttronWebViewRegistry {
  static void register(FluttronWebViewRegistration registration);
  static void registerAll(Iterable<FluttronWebViewRegistration> registrations);
  static bool isRegistered(String type);
  static FluttronWebViewRegistration lookup(String type);
}
```

**功能**：管理 `type` 到 `jsFactoryName` 的映射关系。

**注册冲突检测**：
- 同一 `type` 注册相同 `jsFactoryName`：静默忽略
- 同一 `type` 注册不同 `jsFactoryName`：抛出 `StateError`

## 平台适配模式

采用 Dart 条件导入实现跨平台编译：

```
lib/
├── src/
│   ├── html_view_platform_stub.dart      # 非 Web 平台（抛出 UnsupportedError）
│   ├── html_view_platform_web.dart       # Web 平台实现
│   ├── event_bridge_platform_stub.dart   # 非 Web 平台
│   └── event_bridge_platform_web.dart    # Web 平台实现
└── fluttron/
    ├── fluttron_client_stub.dart         # 非 Web 平台
    └── fluttron_client.dart              # Web 平台
```

**条件导入语法**：
```dart
// 使用 dart.library.html 检测 Web 平台
import 'html_view_platform_stub.dart'
    if (dart.library.html) 'html_view_platform_web.dart'
    as html_view_platform;

// 使用 dart.library.js_interop 检测新版 JS 互操作
export 'fluttron/fluttron_client_stub.dart'
    if (dart.library.js_interop) 'fluttron/fluttron_client.dart';
```

## 文件结构

```
packages/fluttron_ui/
├── lib/
│   ├── fluttron_ui.dart           # 公开 API 导出
│   ├── main.dart                  # 示例入口
│   ├── src/
│   │   ├── ui_app.dart            # 应用入口封装
│   │   ├── html_view.dart         # HTML 视图组件
│   │   ├── html_view_runtime.dart # 视图描述符解析与哈希
│   │   ├── html_view_platform_stub.dart
│   │   ├── html_view_platform_web.dart
│   │   ├── event_bridge.dart      # 事件桥
│   │   ├── event_bridge_platform_stub.dart
│   │   ├── event_bridge_platform_web.dart
│   │   └── web_view_registry.dart # 视图注册中心
│   └── fluttron/
│       ├── fluttron_client.dart       # Web 平台客户端
│       └── fluttron_client_stub.dart  # 非 Web 平台客户端
└── test/
    ├── ui_app_test.dart
    ├── html_view_test.dart
    ├── html_view_runtime_test.dart
    ├── event_bridge_test.dart
    └── web_view_registry_test.dart
```

## 依赖关系

```
fluttron_ui
├── flutter (SDK)
├── fluttron_shared          # 共享数据模型
│   ├── FluttronRequest
│   ├── FluttronResponse
│   └── FluttronError
└── cupertino_icons
```

## 设计决策

### 1. 为什么使用条件导入而非 Platform 检测？

Flutter Web 编译时会进行 Tree Shaking，条件导入确保非 Web 平台不会包含任何 `dart:js_interop` 相关代码，避免编译错误。

### 2. 为什么 FluttronHtmlView 需要注册机制？

`HtmlElementView` 要求在应用启动前注册视图工厂。通过注册中心统一管理，支持：
- 延迟注册
- 类型冲突检测
- 参数化视图复用（相同参数复用已注册的视图类型）

### 3. 参数签名（Args Signature）的作用

当同一 `type` 使用不同参数时，通过 FNV-1a 哈希生成唯一的 `resolvedViewType`：
```
type = "my-chart"
args = [{data: [1,2,3]}]
→ resolvedViewType = "my-chart.__a1b2c3d4e5f6g7h8"
```

这确保不同参数的视图实例互不干扰。

## 与宿主层的协作

| 方向 | 机制 | 用途 |
|------|------|------|
| Renderer → Host | `FluttronClient.invoke()` | 调用宿主服务（系统、存储等） |
| Host → Renderer | `CustomEvent` + `FluttronEventBridge` | 宿主主动推送消息 |
| Web Integration | `FluttronHtmlView` + JS Factory | 嵌入第三方 Web 组件 |

## 后续规划

- [ ] 类型安全的 Bridge 代码生成
- [ ] 更多内置服务封装
- [ ] 调试工具集成
