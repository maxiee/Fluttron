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

`fluttron_milkdown`（v0042-v0050）已完成并收口，`v0051+` 已正式进入 `markdown_editor` 重大需求执行：

- 以 `docs/feature/markdown_editor_design.md` 为设计基准推进 v0051-v0060。
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
| 1 | `markdown_editor` 首版本尚未落地 | 已完成计划拆解，需先实现并验收 v0051（FileService） |
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

## 当前重大需求：`markdown_editor`（v0051-v0060）

### 需求来源与引用关系

- 主设计文档：`docs/feature/markdown_editor_design.md`
- 当前文档职责：执行级任务拆解、版本顺序、验收命令与风险前置提醒。
- 设计文档职责：架构细节、接口签名、数据模型、测试矩阵、风险清单。

### LLM 实施提示（必须遵守）

- 任一版本开始实现前，先阅读：`docs/feature/markdown_editor_design.md`。
- 实现 Host Service 时，重点对照 §4（Framework Evolution）与 §9（Framework Tasks）。
- 实现 UI 与交互时，重点对照 §5（UI Design）、§6（State Management）、§7（UI ↔ Host Communication）。
- 安排版本与依赖关系时，重点对照 §10（Iterative Execution Plan）与 §11（Dependency Graph）。
- 编写/补齐测试时，重点对照 §13（Testing Strategy）；验收目标对照 §2 与 §14。
- 若本文件与设计文档存在冲突：接口与行为细节以设计文档为准，本文件只维护执行顺序与里程碑。

### 目标与边界（本轮）

- 目标：
  1. 交付可用于真实文件编辑的桌面 Markdown 应用（`examples/markdown_editor/`）。
  2. 反向推动框架演进，补齐 `file.*`、`dialog.*`、`clipboard.*` 内建服务。
  3. 形成“官方示例级”最佳实践（脚手架、构建、状态管理、文档与验收）。
- 非目标：
  1. 协同编辑（yjs）、多标签页、导出 PDF/HTML、移动端适配。
  2. 自定义 Milkdown 插件生态扩展与复杂媒体能力。

### 执行顺序（冻结）

1. Phase 1（v0051-v0053）：先补框架服务，再建立可运行 app 骨架。
2. Phase 2（v0054-v0056）：围绕“打开目录 → 打开文件 → 保存与脏状态”形成主流程闭环。
3. Phase 3（v0057-v0058）：补状态栏与主题持久化，完善核心可用性。
4. Phase 4（v0059-v0060）：补新建文件、剪贴板与错误处理/文档收口。

### 版本任务单（当前进行中与未完成）

| 版本 | 阶段 | 最小可执行任务 | 依赖 | 最小验收 |
|---|---|---|---|---|
| v0051 | Phase 1 | 在 `fluttron_host` 新增 `FileService`（`read/write/list/stat/create/delete/rename/exists`），完成注册与单测 | 无 | playground 通过 `FluttronClient.invoke('file.readFile', ...)` 读文件成功 |
| v0052 | Phase 1 | 在 `fluttron_host` 新增 `DialogService` + `ClipboardService`，完成注册、参数校验与 macOS 手测 | v0051 可并行 | 可拉起原生 open/save 对话框，剪贴板读写可用 |
| v0053 | Phase 1 | 用 `fluttron create` 建立 `examples/markdown_editor`，接入 `fluttron_milkdown`，打通 build/run | v0051,v0052 | `fluttron build -p examples/markdown_editor` 成功，macOS 可运行并显示编辑器 |
| v0054 | Phase 2 | 实现 Open Folder + Sidebar File Tree（仅 `.md`） | v0053,v0052 | 可选择目录并在侧栏看到 `.md` 文件 |
| v0055 | Phase 2 | 实现“点击文件加载到编辑器”，维护 `currentFilePath/savedContent`，高亮当前文件 | v0054,v0051 | 点击侧栏文件可在编辑区正确切换内容 |
| v0056 | Phase 2 | 实现保存与脏状态（按钮 + Cmd+S + 状态同步） | v0055,v0051 | 编辑后显示 Unsaved，保存后显示 Saved，磁盘内容一致 |
| v0057 | Phase 3 | 实现底部 StatusBar（文件名/保存状态/字符数/行数）并接入变更事件 | v0056 | 状态栏实时更新统计数据 |
| v0058 | Phase 3 | 实现主题切换与持久化（`MilkdownController.setTheme` + `kv`） | v0057,v0052 | 重启应用后主题偏好可恢复 |
| v0059 | Phase 4 | 实现 New File 流程并补齐显式剪贴板操作（如需要） | v0058,v0051,v0052 | 可新建 `.md` 文件并自动出现在侧栏且可编辑 |
| v0060 | Phase 4 | 完成错误处理、加载态、README、截图与文档收口 | v0059 | 关键异常有可见反馈，README 可按步骤复现 |

### 并行与节奏约束

- 可并行：`v0051` 与 `v0052`（框架服务互不阻塞）。
- 半并行：`v0057` UI 布局可在 `v0055-v0056` 期间提前搭建，但事件绑定在 `v0056` 后收口。
- 节奏要求：每个版本保持“单版本可独立验收”，未达到验收标准不得进入下版本。

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
- 当前主需求：`markdown_editor`（执行范围：`v0051-v0060`）。
- 下一步最小动作：
  1. 开始 `v0051` 前先对照阅读 `docs/feature/markdown_editor_design.md` 的 §4、§9、§10、§13。
  2. 落地 `v0051`（`FileService` + 注册 + 单测）并完成最小验收命令。
  3. 按依赖顺序推进 `v0052` 与 `v0053`，确保每版独立验收后再进入下一版。
