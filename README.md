# Fluttron ⚡️

**Dart 原生的跨端容器 OS。**

> 也就是 Dart/Flutter 版本的 Electron。

## 💡 为什么开发 Fluttron?

Fluttron 重新定义了跨端开发架构，通过融合 **原生宿主的稳定性** 与 **Web 渲染的灵活性**，让 Dart 开发者拥有了自己的 "Electron"。

Electron 利用 Node.js 和 Chromium 统治了桌面端开发，但它要求 Dart 开发者必须切换技术栈。**Fluttron** 让你在系统层（System Layer）和 UI 层（UI Layer）都能使用 Dart 语言。

## 🏗 架构设计

Fluttron 采用了类似 Electron 或小程序容器的双层架构（Host & Renderer）：

- **宿主 (Host):** 基于 **Flutter Desktop** 开发。它负责管理窗口、生命周期，并通过服务注册表（Service Registry）对外暴露原生能力（如文件系统、数据库、系统 API）。
- **渲染层 (Renderer):** 基于 **Flutter Web** 开发。它运行在受控的 WebView 容器内，负责 UI 绘制和业务逻辑，通过高性能 Bridge 与宿主通信。

```mermaid
graph TD
    subgraph Host [Fluttron Host (Native Dart)]
        HostMain[主入口]
        ServiceRegistry[服务注册中心]
        Sys[系统服务]
        Store[存储服务]
        BridgeHost[宿主 Bridge]
    end

    subgraph Renderer [Fluttron UI (Flutter Web)]
        WebMain[Web 入口]
        Client[Fluttron 客户端 SDK]
        UI[业务 UI]
        BridgeWeb[渲染层 Bridge]
    end

    UI --> Client
    Client --> BridgeWeb
    BridgeWeb <-->|IPC / JS Channel| BridgeHost
    BridgeHost --> ServiceRegistry
    ServiceRegistry --> Sys
    ServiceRegistry --> Store
```

## ✨ 核心特性

- 全栈 Dart: 宿主服务用 Dart 写，界面 UI 用 Dart (Flutter Web) 写。
- 服务化架构: 宿主通过 ServiceRegistry 模式管理能力，易于扩展。
- Web 生态: 渲染层本质是 Web，既享受 Flutter 的绘制，也能无缝接入 Web 生态。
- 沙箱隔离: 严格区分系统权限（Host）与 UI 逻辑（Renderer），架构更清晰安全。

## 🚀 当前状态

项目目前处于 MVP (最小可行性平台) 阶段。

- [x] 完成 Host 与 Renderer 分层架构
- [x] 跑通 Bridge 通信协议 (Host <-> WebView)
- [x] 实现基础服务注册中心 (System & KV Storage)
- [ ] CLI 脚手架工具 (开发中)
- [ ] 插件系统

## 🤝 参与共建

Fluttron 遵循 "Build in public" 原则。欢迎提交 Issue 或 PR。

详细文档与安装指南正在编写中...