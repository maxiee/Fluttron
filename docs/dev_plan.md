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

## 当前阶段目标（更新于 2026-02-17）

### 北极星目标

`markdown_editor`（v0051-v0060）已完成并收口，当前切换到下一重大需求 `host_service_evolution`（v0061-v0074）：

- 以 `docs/feature/host_service_evolution_design.md` 为设计基准推进 L1 → L3 → L2。
- 优先完成 v0061-v0067（框架内建服务客户端上收 + `host_service` 模板落地）。
- 在 v0068-v0074 完成 `fluttron generate services`，形成 Host/UI 契约生成闭环。
- 保持“单版本可独立验收”的交付节奏。
- **当前起始版本：v0062（v0061 已完成）**。

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
| 内建 Host Services | ✅ | `file/dialog/clipboard/system/storage` 已落地并稳定可用 |
| markdown_editor 示例应用 | ✅ | `examples/markdown_editor` 已完成并通过 v0051-v0060 验收 |
| 文件编辑主流程 | ✅ | Open Folder、File Tree、Load、Save/Dirty、New File 全闭环 |
| 可用性能力 | ✅ | StatusBar、主题持久化、加载态与错误反馈已落地 |

### 当前剩余差距

| # | 差距 | 说明 |
|---|---|---|
| 1 | 内建服务 Client 仍分散在应用层 | `FileServiceClient/DialogServiceClient/ClipboardServiceClient` 已上收到 `fluttron_ui`（v0061），但 `markdown_editor` 尚未迁移到框架内建 client（v0063） |
| 2 | 缺少 `host_service` 一键脚手架 | CLI 仍不支持 `fluttron create --type host_service` 生成 Host/UI 双包 |
| 3 | 缺少服务契约代码生成 | `FluttronService.handle` 仍需手写 `switch/case`，契约演进成本高 |
| 4 | 服务文档与迁移路径未闭环 | built-in client API、迁移指南、custom service 教程尚未统一收口 |

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

### 已完成重大需求：`markdown_editor`（v0051-v0060）

- 状态：✅ 已完成并正式收口（2026-02-17）
- 主设计文档：`docs/feature/markdown_editor_design.md`
- 关键交付：
  - 在 `examples/markdown_editor` 交付可用于真实文件编辑的桌面 Markdown 应用。
  - 打通 `file.*`、`dialog.*`、`clipboard.*` Host Service 与 UI 调用链路。
  - 完成 Open Folder、File Tree、File Loading、Save/Dirty、StatusBar、主题持久化、New File 全流程闭环。
  - 完成异常反馈、加载态、README 与截图说明文档收口。

#### v0051-v0060 完成摘要

| 版本 | 主题 | 结果 |
|---|---|---|
| v0051 | `FileService` 落地 | 8 个方法 + 模型 + 单测完成 |
| v0052 | `DialogService`/`ClipboardService` | 原生对话框与剪贴板能力落地 |
| v0053 | 示例应用骨架 | `examples/markdown_editor` 创建并接入 Milkdown |
| v0054 | Open Folder + 侧栏树 | 目录选择与 `.md` 文件树可用 |
| v0055 | 文件加载流程 | 点击文件加载、当前文件高亮与状态维护 |
| v0056 | 保存与脏状态 | Save 按钮 + `Cmd+S` + UI 状态同步 |
| v0057 | 状态栏能力 | 文件名/保存状态/字符数/行数实时更新 |
| v0058 | 主题切换与持久化 | 主题偏好可保存并在重启后恢复 |
| v0059 | New File 流程 | 新建 `.md`、刷新侧栏、自动打开新文件 |
| v0060 | 收口与文档 | 错误处理、加载态、README、截图文档完成 |

### 历史迭代摘要（结构化）

| 区间 | 主题 | 结果 |
|---|---|---|
| v0001-v0019 | 基础框架与 CLI 主链路 | Host/UI/Shared/CLI create-build-run 全链路建立 |
| v0020-v0031 | 前端集成能力沉淀 | `HtmlView/EventBridge` 核心能力抽象，模板与 playground 对齐 |
| v0032-v0041 | Web Package MVP | 机制完整落地并完成验收 |
| v0042-v0050 | `fluttron_milkdown` | 首个复杂官方包完成交付并通过机制验证清单 |
| v0051-v0060 | `markdown_editor` | 生产级 Markdown 编辑器完成交付并形成示例级实践 |

注：详细历史记录以 Git 提交与专题文档为准，不在本文件重复维护逐条流水账。

---

## 当前重大需求：`host_service_evolution`（v0061-v0074）

### 需求来源与引用关系

- 主技术方案文档：`docs/feature/host_service_evolution_design.md`
- 当前文档职责：执行级版本拆解、依赖顺序、最小验收与阶段门控。
- 技术方案文档职责：接口定义、目录与文件规范、代码生成策略、风险与兼容性细节。

### LLM 实施提示（必须遵守）

- 任一版本开始实现前，先阅读：`docs/feature/host_service_evolution_design.md` 的 §7（Iterative Execution Plan）定位当前版本。
- 实现 L1（v0061-v0063）时，重点对照 §4（Phase L1）与 §10（Documentation Plan 中 L1 交付项）。
- 实现 L3（v0064-v0067）时，重点对照 §5（Phase L3）与 §10（Custom Service 文档交付项）。
- 实现 L2（v0068-v0074）时，重点对照 §6（Phase L2）与 §8（Risk Analysis）。
- 涉及兼容性与废弃策略时，必须对照 §9（Backward Compatibility）。
- 若本文件与技术方案文档冲突：接口签名、模型结构、生成规则以技术方案文档为准，本文件只维护执行顺序与里程碑。

### 目标与边界（本轮）

- 目标：
  1. 在框架层提供 5 个内建服务 typed client，并完成 `markdown_editor` 迁移（L1）。
  2. 在 CLI 提供 `fluttron create --type host_service`，交付 Host/UI 双包脚手架（L3）。
  3. 在 CLI 提供 `fluttron generate services`，实现契约驱动的 Host/UI/Model 代码生成（L2）。
  4. 保持向后兼容，`FluttronClient.invoke()` 与现有服务注册链路不破坏。
- 非目标：
  1. 运行时自动服务发现与自动注册。
  2. 跨进程/跨网络传输协议改造（仍基于 WebView JSON Bridge）。
  3. 移动端一致性专项验证与性能专项优化（桌面优先）。

### 执行顺序（冻结）

1. Phase 1（v0061-v0063）：先完成内建服务 client 上收与示例迁移（L1）。
2. Phase 2（v0064-v0067）：再交付 `host_service` 模板与 `create --type host_service`（L3）。
3. Phase 3（v0068-v0074）：最后交付服务契约代码生成 CLI（L2）。

### 版本前决策钩子（来自技术方案 §11）

- v0061 开始前：确认 Q1（built-in clients 是直接导出在 `fluttron_ui.dart` 还是子入口）。
- v0064 开始前：确认 Q4（`fluttron_host_service.json` 在 L3 是否强制必需）。
- v0066 开始前：确认 Q2（`ServiceRegistry.register` 是否对 namespace 冲突直接抛错）。
- v0068 开始前：确认 Q3（L2 的 generated `Base` 类落在 host 包还是 shared 包）。

### 版本任务单（当前进行中与未完成）

| 版本 | 阶段 | 最小可执行任务 | 技术方案必读章节 | 依赖 | 最小验收 | 状态 |
|---|---|---|---|---|---|---|
| v0061 | Phase 1 / L1 | 在 `fluttron_ui` 新增 `FileServiceClient`、`DialogServiceClient`、`ClipboardServiceClient`；`FileStat` 上收至 `fluttron_shared`；更新导出与测试 | §4.2.1、§4.2.2、§4.3.1-§4.3.3、§4.3.6、§4.4、§4.8 | 无 | `dart analyze packages/fluttron_ui` 与 `dart analyze packages/fluttron_shared` 通过；3 个 client 可从 `fluttron_ui.dart` 导入 | ✅ 已完成 |
| v0062 | Phase 1 / L1 | 新增 `SystemServiceClient`、`StorageServiceClient`；为 `FluttronClient.getPlatform/kvSet/kvGet` 增加 `@Deprecated` | §4.3.4、§4.3.5、§4.5、§4.7、§4.8 | v0061 | 5 个内建 client 全部可用；旧 API 保留但显示废弃提示 | 待开始 |
| v0063 | Phase 1 / L1 | 迁移 `examples/markdown_editor` 到框架内建 client；删除 app 层重复 client 文件；补回归测试与文档 | §4.6、§4.8、§7(Phase 1)、§10(L1) | v0062 | `fluttron build -p examples/markdown_editor` 成功；`markdown_editor` 运行正常；app 层 client 重复实现已移除 | 待开始 |
| v0064 | Phase 2 / L3 | 新建 `templates/host_service/`，落地 manifest、host/client 双包模板与 README | §5.2、§5.3.1-§5.3.10、§5.5 | v0063 | 模板目录完整；模板内 Dart 代码可通过分析；文件命名符合 snake/Pascal/camel 规则 | 待开始 |
| v0065 | Phase 2 / L3 | 实现 `HostServiceCopier`（变量替换、路径改名、双包处理、manifest 特殊处理） | §5.4.2、§5.5、§5.7 | v0064 | `host_service_copier_test` 通过；替换/重命名行为可覆盖主路径 | 待开始 |
| v0066 | Phase 2 / L3 | 将 `CreateCommand` 接入 `--type host_service`；补 `ProjectType`、成功提示、pubspec path 重写 | §5.4.1、§5.6、§5.7 | v0065 | `fluttron create /tmp/test_svc --type host_service --name test_svc` 可生成可构建结构 | 待开始 |
| v0067 | Phase 2 / L3 | 增加 `fluttron_host_service.json` 解析与诊断（可选）；补教程与 E2E（创建→注册→调用） | §5.3.1、§5.7、§7(Phase 2)、§10(L3) | v0066 | playground 内完成 custom service 端到端调用；文档可复现 | 待开始 |
| v0068 | Phase 3 / L2 | 在 `fluttron_shared` 新增 `@FluttronServiceContract` / `@FluttronModel` 注解 | §6.3、§6.4、§7(Phase 3) | v0067 | 注解可导入可使用；示例 contract 可通过编译 | 待开始 |
| v0069 | Phase 3 / L2 | 实现 Dart AST 解析器，提取 service contract / methods / model 字段 | §6.7、§6.8、§6.11 | v0068 | parser fixture 测试通过（含可选参数、nullable、List/Map） | 待开始 |
| v0070 | Phase 3 / L2 | 实现 Host 侧生成器（`*_generated.dart`，`switch/case` 路由 + Base 类） | §6.5(Host)、§6.8、§6.9、§6.10、§6.11 | v0069 | 生成代码可编译；路由与参数校验行为正确 | 待开始 |
| v0071 | Phase 3 / L2 | 实现 Client 侧生成器（typed method wrapper） | §6.5(Client)、§6.8、§6.9、§6.10、§6.11 | v0069 | 生成 client 可编译并正确调用 `namespace.method` | 待开始 |
| v0072 | Phase 3 / L2 | 实现 Model 生成器（`fromMap/toMap`） | §6.5(Models)、§6.8、§6.10、§6.11 | v0069 | 生成模型序列化/反序列化测试通过 | 待开始 |
| v0073 | Phase 3 / L2 | 接入 `fluttron generate services` 命令，支持 `--contract`、输出目录、`--dry-run` | §6.6、§6.10、§6.11 | v0070,v0071,v0072 | CLI 一次生成 Host/Client/Model 文件；`--dry-run` 仅预览不写盘 | 待开始 |
| v0074 | Phase 3 / L2 | 完成边缘场景、错误文案、文档收口与最终验收 | §6.9、§6.11、§8、§9、§10 | v0073 | 真实契约样例生成可用；兼容性说明与使用文档完整 | 待开始 |

### 并行与节奏约束

- 可立即开始：`v0062`（依赖 v0061 已完成）。
- 串行链路：`v0061 → v0062 → v0063 → v0064 → v0065 → v0066 → v0067`。
- 可并行：`v0070`、`v0071`、`v0072`（共同依赖 `v0069`）。
- 收口顺序：`v0073` 依赖 `v0070/v0071/v0072` 全完成，`v0074` 最终收口。
- 节奏要求：每个版本保持“单版本可独立验收”，未满足最小验收不得进入下一版本。

#### v0061-v0074 完成摘要

| 版本 | 主题 | 结果 |
|---|---|---|---|
| v0061 | 内建 Client 上收（第一批） | `FileServiceClient/DialogServiceClient/ClipboardServiceClient` + `FileStat` 已上收到框架层，测试通过 |

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

- 当前起始版本：`v0062`
- 当前主需求：`host_service_evolution`（执行范围：`v0061-v0074`）。
- 当前状态：v0061 已完成，进入 v0062。
- v0062 最小任务：
  - 在 `packages/fluttron_ui/lib/src/services/` 新增 `SystemServiceClient`、`StorageServiceClient`。
  - 为 `FluttronClient.getPlatform/kvSet/kvGet` 增加 `@Deprecated` 注解。
  - 按 §4.8 补齐对应单元测试。
- v0062 实现前必读：`docs/feature/host_service_evolution_design.md` §4.3.4、§4.3.5、§4.5、§4.7、§4.8。
- v0062 最小验收命令：
  - `dart analyze packages/fluttron_ui`
  - `(cd packages/fluttron_ui && flutter test)`
  - 验证 5 个内建 client 全部可从 `fluttron_ui.dart` 导入
  - 验证旧 API 保留但显示废弃提示
