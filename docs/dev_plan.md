# Fluttron 项目研发

## 文档定位

本文是 Fluttron 的执行总纲，目标是让后续参与迭代的 LLM/开发者可以直接按步骤推进，不需要二次猜测上下文。

- 本文负责：阶段目标、约束、迭代顺序、逐版本实现清单、验收标准。
- 详细技术设计由专题文档负责，本文只做“执行级拆解 + 引用索引”。
- 任何新增需求先进入本文评审，再进入代码迭代。

---

## 你是谁 + 你要扮演的角色

你是一名「Flutter 跨端容器 OS」的首席架构师、技术产品经理、交付工程负责人三合一助手。

你要与我共创一个项目：**Fluttron**。

---

## Fluttron 定义（不可偏离）

- Fluttron 是一个基于 Flutter 的 Dart + Flutter Web 融合的跨端方案，从 Electron 获得灵感。
- Fluttron 分为宿主部分与渲染部分。
- 宿主部分：
  - 仅通过原生 Flutter 提供入口，并展示一个空白 WebView。
  - 重点是服务层，基于 Dart 提供丰富服务，并支持业务扩展。
- 渲染部分：
  - UI 使用 Flutter Web 开发，100% 在 WebView 内。
  - 充分利用 Flutter Web 集成 Web 生态能力，打通 Web 技术栈。
- 宿主部分和渲染部分通过 Bridge 通信，初期通过 webview 底层机制通信，后续可升级为类型安全代码生成方案。
- 泛跨端：支持桌面端（macOS）与移动端（Android、iOS），当前主战场是桌面端。

---

## 当前阶段目标（更新于 2026-02-16）

### 北极星目标

`fluttron_milkdown`（v0042-v0050）已完成并收口，当前目标切换为 `v0051+` 新一轮重大需求立项与执行准备：

- 选定下一项重大需求并完成设计文档（范围、非目标、验收矩阵）。
- 以已验证能力为基线推进迭代，避免重复建设与双轨方案。
- 保持“单版本可独立验收”的交付节奏。

### 当前能力基线（已具备）

| 能力 | 状态 | 说明 |
|---|---|---|
| CLI create/build/run | ✅ | 已可稳定创建、构建、运行 Fluttron app |
| Host ↔ UI Bridge | ✅ | 协议、错误处理、服务注册机制稳定 |
| Flutter Web 嵌入 JS 视图 | ✅ | `FluttronHtmlView` + `FluttronWebViewRegistry` 已落地 |
| JS→Flutter 事件桥 | ✅ | `FluttronEventBridge` 已落地 |
| 前端构建流水线 | ✅ | `pnpm + esbuild + 三阶段校验` |
| Web Package MVP | ✅ | 依赖发现、资源收集、HTML 注入、注册代码生成、诊断命令、验收矩阵 |
| 复杂官方包样板 | ✅ | `fluttron_milkdown` 已完成（事件、控制器、主题、文档、测试） |
| playground 包化迁移 | ✅ | 已移除历史手写集成路径，统一走 web package 机制 |
| 机制验证闭环 | ✅ | `fluttron_milkdown` V1-V12 验证清单全部通过 |

### 当前剩余差距

| # | 差距 | 说明 |
|---|---|---|
| 1 | `v0051+` 重大需求尚未立项 | 需要明确新需求名称、范围、非目标与验收边界 |
| 2 | 控制通道能力未上游通用抽象 | `fluttron_ui` 仍缺统一 controller primitive |
| 3 | 多实例与性能专项未系统化 | 需补强多实例压力验证与包体积优化策略 |
| 4 | 依赖包前端资产仍需手动预构建 | CLI 尚未自动构建 web package 前端资产 |

---

## 工作方式（必须遵守）

### 输出优先级

每次答复按以下顺序组织：

1. 下一步最小可执行任务
2. 需要创建/修改的文件清单（路径 + 内容要点）
3. 关键决策与权衡
4. 验收方法
5. 风险与后续 TODO

### 防止范围膨胀

- 任何新增内容必须先判断是否进入当前迭代。
- 不进入当前迭代的内容统一进入 Backlog，并写清进入条件。

### 重要限制

- 不给泛泛架构图，必须给可直接落地的文件与命令清单。
- 一次只交付一个可独立验收的功能点（commit 粒度）。
- 优先桌面端验证，不并行扩散到移动端。
- 不引入重型 DevOps 依赖。
- 不确定点先澄清再实现。

### build in public（触发式）

当收到“营销文案”请求时：

- 输出两份：微博（中文，>140 可）+ 推特（英文，<140）
- 语言口语化、真实，不做夸大叙事

### 开源运营（触发式）

当收到“开源运营”请求时：

- 先判断是否具备传播基础，不具备则先补基础建设
- README 双语（`README.md` + `README-zh.md`）

---

## 关键架构共识（不可轻易变更）

### 分层共识

- Host（Flutter）：窗口、生命周期、权限、服务、运行时容器。
- Runtime（WebView Runtime）：JS API 注入、消息路由、模块装载。
- Apps / Web Packages（Flutter Web + JS）：业务 UI 与前端生态集成。

### Host 与 UI 通信

- 基于 WebView JavaScript Handler。
- 协议在 `fluttron_shared`：`FluttronRequest` / `FluttronResponse` / `FluttronError`。
- `ServiceRegistry` 按 `namespace.method` 路由。

### Web 视图渲染共识

- 使用 `FluttronWebViewRegistry` 先注册再渲染。
- `FluttronHtmlView` 通过 `type + args` 驱动，避免硬编码 viewType。
- JS 工厂命名统一：`window.fluttronCreate<Package><Feature>View`。

### 构建共识

- UI 构建流水线：`pnpm(js:build/js:clean)` → `flutter build web` → 三阶段资源校验。
- Web Package 流水线：`package_config` 发现依赖 → 资产收集 → HTML 注入 → 注册代码生成。

详细规则引用：`docs/templating.md`、`docs/feature/fluttron_web_package_prd.md`。

---

## 已完成需求归档

### 已完成重大需求：Web Package MVP（v0032-v0041）

- 状态：✅ 已完成并通过验收矩阵
- 需求文档：`docs/feature/fluttron_web_package_prd.md`
- 交付物：
  - `web_package` 模板与 `create --type web_package`
  - Manifest 解析校验
  - 依赖发现 / 资产收集 / HTML 注入 / 注册生成
  - `UiBuildPipeline` 主流程接入
  - `fluttron packages list` 诊断命令
  - 集成验收与回归测试矩阵（v0041）

### 已完成重大需求：`fluttron_milkdown`（v0042-v0050）

- 状态：✅ 已完成并正式收口（2026-02-16）
- 主设计文档：`docs/feature/fluttron_milkdown_design.md`
- 验证报告：`docs/feature/fluttron_milkdown_validation.md`
- 关键交付：
  - 交付可复用 `MilkdownEditor`（事件、控制器、主题）
  - 打通 Dart→JS 运行时控制通道与 typed event 模型
  - playground 完成包化迁移，移除历史手写集成链路
  - 完成测试与验证收口（`flutter test` 67 passed，V1-V12 全通过）
  - 文档闭环完成（README + Website 示例 + 设计/验证文档）

#### v0042-v0050 完成摘要

| 版本 | 主题 | 结果 |
|---|---|---|
| v0042 | 包骨架与最小编辑器 | 包结构、工厂函数、构建产物可用 |
| v0043 | playground 全链路接入 | Discovery/Collection/Injection/Registration 全部打通 |
| v0044 | 编辑能力扩展 | GFM + 高亮 + feature toggle + 体积指标落档 |
| v0045 | 事件系统完善 | `change/ready/focus/blur` + typed event 落地 |
| v0046 | JS 控制通道 | `fluttronMilkdownControl` + 统一错误返回结构 |
| v0047 | Dart 控制器 API | `MilkdownController` + interop + 生命周期绑定 |
| v0048 | 多主题支持 | 4 主题初始化与运行时切换稳定 |
| v0049 | 测试与验证清单 | 测试补齐，V1-V12 全通过，缺口入 Backlog |
| v0050 | 文档与迁移收口 | 文档完善 + playground 最终清理完成 |

### 历史迭代摘要（结构化）

| 区间 | 主题 | 结果 |
|---|---|---|
| v0001-v0019 | 基础框架与 CLI 主链路 | Host/UI/Shared/CLI create-build-run 全链路建立 |
| v0020-v0031 | 前端集成能力沉淀 | `HtmlView/EventBridge` 核心能力抽象，模板与 playground 对齐 |
| v0032-v0041 | Web Package MVP | 机制完整落地并完成验收 |
| v0042-v0050 | `fluttron_milkdown` | 首个复杂官方包完成交付并通过机制验证清单 |

注：详细历史记录以 Git 提交与专题文档为准，不在本文件重复维护逐条流水账。

---

## 当前重大需求（待定义）：`v0051+`

### 立项输入（必须补齐）

1. 需求名称与目标用户价值（一句话可验证）。
2. 主设计文档路径（建议：`docs/feature/<next_requirement>_design.md`）。
3. 本轮目标与非目标（防止范围膨胀）。
4. 版本切分与每版本最小验收命令（可执行、可复现）。

### 候选方向（来自 Backlog）

| 候选项 | 进入条件 | 优先级 |
|---|---|---|
| `fluttron_ui` 统一控制器抽象 | 至少 2 个 web package 复用同类控制通道时启动 | P1 |
| CLI 自动构建 web package 依赖资产 | 依赖包数量增长导致人工预构建成本明显上升时启动 | P1 |
| 多实例稳定性专项 | 启动多实例业务前必须完成专项压测与故障注入 | P1 |
| 资产懒加载/按需加载 | 启动体积与冷启动时间成为用户痛点时启动 | P2 |
| pub.dev 分发规范与兼容矩阵 | 对外发布前必须完成版本策略与兼容基线定义 | P2 |

### 执行模板（新需求启动后填写）

```markdown
## 当前重大需求：`<name>`（v0051-v00xx）

### 需求来源与引用关系
### 目标与边界
### 统一实现约束
### 执行顺序
### 版本任务单（仅保留当前进行中与未完成项）
```

---

## Backlog（未来）

| 条目 | 进入条件 | 备注 |
|---|---|---|
| `fluttron_ui` 抽象统一 `FluttronWebViewController` | 出现跨包重复控制模式 | 已有 `fluttron_milkdown` 参考实现 |
| CLI 自动构建 web package 依赖资产 | 人工预构建成为稳定交付瓶颈 | 当前仍要求包侧先构建前端 |
| 多实例编辑器系统级稳定性测试 | 新需求包含多实例编辑场景 | 需覆盖内存、事件隔离、恢复能力 |
| web package 资产按需加载 | 启动体积与性能指标触发阈值 | 与构建链路改造联动 |
| pub.dev 分发规范与兼容矩阵 | 对外发布前 | 与版本治理策略联动 |

---

## 立即下一步（执行入口）

- 当前起始版本：`v0051`
- `fluttron_milkdown` 迭代已完成并归档，当前文档已为新重大需求预留空间。
- 下一步最小动作：
  1. 从 Backlog 中选择一个候选项进入 `v0051`。
  2. 新建对应设计文档并回填“当前重大需求（待定义）”模板。
  3. 先落一个可独立验收的首版本任务（`v0051`）再扩展后续版本。
