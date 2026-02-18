# Fluttron 项目研发

## 文档定位

本文是 Fluttron 的执行总纲，目标是让后续参与迭代的 LLM/开发者可以直接按步骤推进，不需要二次猜测上下文。

- 本文负责：阶段目标、约束、迭代顺序、逐版本实现清单、验收标准。
- 详细技术设计由专题文档负责，本文只做"执行级拆解 + 引用索引"。
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

## 当前阶段目标（更新于 2026-02-18）

### 北极星目标

`host_service_evolution`（v0061-v0074）已完成并收口，当前目标为 **v0.1.0-alpha 社区首发**：

- Phase A（v0075-v0079）：质量与 CI 基础——Lint 清零、包元数据统一、GitHub Actions CI 上线、性能基线文档
- Phase B（v0080-v0088）：核心功能补全——`WindowService`（窗口控制）、`LoggingService`（结构化日志）、全局错误边界、`fluttron package` 打包命令
- Phase C（v0089-v0094）：开源基础设施——CONTRIBUTING/CODE_OF_CONDUCT/CHANGELOG/SECURITY/Issue 模板、`fluttron doctor`、`fluttron --version`、仓库清理
- Phase D（v0095-v0101）：文档与展示层——README 重写（EN+ZH）、Why Fluttron 页面、故障排查文档、包级 README、截图与 GIF
- Phase E（v0102-v0107）：发布准备——版本升 0.1.0-alpha、全量测试扫描、Smoke Test、Blog/社媒草稿、发布 checklist、Tag & Publish

**当前状态：Phase A 进行中，v0075、v0076、v0077 已完成，当前入口版本为 v0078**

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
| 框架层内建服务 Client | ✅ | `FileServiceClient/DialogServiceClient/ClipboardServiceClient/SystemServiceClient/StorageServiceClient` 上收至框架层 |
| host_service 脚手架 | ✅ | `fluttron create --type host_service` 双包生成 |
| 服务契约代码生成 | ✅ | `fluttron generate services` CLI 全链路（AST 解析→Host/Client/Model 生成） |

### 当前剩余差距（来源：`docs/feature/v1_release_roadmap.md` Gap Analysis）

#### A. 缺少桌面框架标配功能

| 差距 | 优先级 | 计划版本 |
|---|---|---|
| 窗口管理（resize/minimize/maximize/title/fullscreen） | CRITICAL | v0080-v0083 |
| 应用打包（`fluttron package` → .app/.dmg） | CRITICAL | v0086-v0087 |
| 结构化日志服务 | HIGH | v0084 |
| 全局错误边界（host + UI） | HIGH | v0085 |

#### B. 缺少开源基础设施

| 差距 | 优先级 | 计划版本 |
|---|---|---|
| CONTRIBUTING.md | CRITICAL | v0089 |
| CODE_OF_CONDUCT.md | CRITICAL | v0089 |
| CHANGELOG.md（补充历史） | CRITICAL | v0091 |
| Issue/PR 模板 | HIGH | v0090 |
| SECURITY.md | HIGH | v0091 |
| 包 pubspec 元数据清理 | HIGH | v0076 |
| CI pipeline（GitHub Actions） | HIGH | v0077-v0078 |

#### C. 文档与展示差距

| 差距 | 优先级 | 计划版本 |
|---|---|---|
| README 全面重写（GIF/徽章/对比表） | CRITICAL | v0095 |
| README-zh.md（中文 README） | HIGH | v0096 |
| Why Fluttron 对比页 | HIGH | v0097 |
| 故障排查/FAQ | HIGH | v0098 |
| 包级 README 文件 | MEDIUM | v0100 |
| Website sidebar 导航完整性 | MEDIUM | v0099 |

#### D. 代码质量差距

| 差距 | 优先级 | 计划版本 |
|---|---|---|
| ~~fluttron_cli 中 13 个 lint warnings~~ | ~~HIGH~~ | ~~v0075~~ ✅ |
| 所有包 `dart analyze` 清零 | HIGH | v0075-v0076 |
| 版本号统一 | MEDIUM | v0076 |

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

当收到"营销文案"请求时：

- 输出两份：微博（中文，>140 可）+ 推特（英文，<140）
- 语言口语化、真实，不做夸大叙事

### 开源运营（触发式）

当收到"开源运营"请求时：

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

### 已完成重大需求：`host_service_evolution`（v0061-v0074）

- 状态：✅ 已完成并正式收口（2026-02-18）
- 主技术方案文档：`docs/feature/host_service_evolution_design.md`
- 关键交付：
  - 在框架层提供 5 个内建服务 typed client（File/Dialog/Clipboard/System/Storage）并完成 `markdown_editor` 迁移（L1）
  - 在 CLI 提供 `fluttron create --type host_service`，交付 Host/UI 双包脚手架（L3）
  - 在 CLI 提供 `fluttron generate services`，实现契约驱动的 Host/UI/Model 代码生成（L2）
  - 保持向后兼容，`FluttronClient.invoke()` 与现有服务注册链路不破坏

#### v0061-v0074 完成摘要

| 版本 | 主题 | 结果 |
|---|---|---|
| v0061 | 内建 Client 上收（第一批） | `FileServiceClient/DialogServiceClient/ClipboardServiceClient` + `FileStat` 已上收到框架层，测试通过 |
| v0062 | 内建 Client 上收（第二批） | `SystemServiceClient/StorageServiceClient` 已上收；`FluttronClient.getPlatform/kvSet/kvGet` 已标记 `@Deprecated` |
| v0063 | markdown_editor 迁移 | 已迁移到框架内建 client；删除 app 层重复实现（`FileServiceClient`、`DialogServiceClient`、`FileStat`）；`kvGet/kvSet` 替换为 `StorageServiceClient`；构建与测试通过 |
| v0064 | host_service 模板骨架 | `templates/host_service/` 创建完成；manifest (`fluttron_host_service.json`)、host/client 双包模板、README 全部落地 |
| v0065 | HostServiceCopier 实现 | 变量替换（snake/Pascal/camel case）、双包目录重命名、manifest 特殊处理、14 个测试全部通过 |
| v0066 | CLI `--type host_service` | `CreateCommand` 接入 `host_service` 类型；`ProjectType.hostService` 枚举、成功提示、pubspec path 重写、验收通过 |
| v0067 | E2E 验证与教程 | `examples/host_service_demo` 示例应用创建；`website/docs/getting-started/custom-services.md` 教程文档；services.md 更新；E2E custom service 调用验证完成 |
| v0068 | 服务契约注解 | `FluttronServiceContract` / `FluttronModel` 注解已落地；示例 contract (`WeatherService`) 已创建并通过编译验证 |
| v0069 | AST 解析器 | `ServiceContractParser` 实现；支持解析 contract/methods/params/models；28 个单元测试全部通过（含可选参数、nullable、List/Map） |
| v0070 | Host 侧生成器 | `HostServiceGenerator` 实现；生成 `switch/case` 路由、参数提取与校验、抽象 Base 类、helper 方法；32 个测试通过 |
| v0071 | Client 侧生成器 | `ClientServiceGenerator` 实现；生成 typed method wrapper、参数构建、结果反序列化；27 个单元测试 + 4 个集成测试全部通过 |
| v0072 | Model 生成器 | `ModelGenerator` 实现；生成 `fromMap()` factory 和 `toMap()` 方法；支持所有类型映射（String/int/double/bool/DateTime/List/Map/nullable/custom model）；50 个单元测试全部通过 |
| v0073 | CLI `generate services` 命令 | `GenerateCommand` / `GenerateServicesCommand` 实现；支持 `--contract`、`--host-output`、`--client-output`、`--shared-output`、`--dry-run`；8 个单元测试全部通过 |
| v0074 | 文档收口与最终验收 | `website/docs/api/codegen.md` + `website/docs/api/annotations.md` 文档完成；真实契约样例（TodoService）E2E 测试通过；155 个生成器测试全部通过 |

### 历史迭代摘要（结构化）

| 区间 | 主题 | 结果 |
|---|---|---|
| v0001-v0019 | 基础框架与 CLI 主链路 | Host/UI/Shared/CLI create-build-run 全链路建立 |
| v0020-v0031 | 前端集成能力沉淀 | `HtmlView/EventBridge` 核心能力抽象，模板与 playground 对齐 |
| v0032-v0041 | Web Package MVP | 机制完整落地并完成验收 |
| v0042-v0050 | `fluttron_milkdown` | 首个复杂官方包完成交付并通过机制验证清单 |
| v0051-v0060 | `markdown_editor` | 生产级 Markdown 编辑器完成交付并形成示例级实践 |
| v0061-v0074 | `host_service_evolution` | 内建服务 Client 框架层上收、host_service 脚手架、服务契约代码生成 CLI 全链路落地 |

注：详细历史记录以 Git 提交与专题文档为准，不在本文件重复维护逐条流水账。

---

## 当前重大需求：v0.1.0 Release Preparation（v0075-v0107）

### 需求来源与引用关系

- 主技术方案文档：`docs/feature/v1_release_roadmap.md`
- 当前文档职责：执行级版本拆解、依赖顺序、最小验收与阶段门控。
- 技术方案文档职责：每个版本的详细实施步骤、文件清单、代码片段与逐步验收标准。
- **任意版本开始实现前，必须先阅读 `docs/feature/v1_release_roadmap.md` 中对应版本的章节（`### vXXXX —` 标题）。**

### LLM 实施提示（必须遵守）

- 实现 Phase A（v0075-v0079）前，先阅读技术方案文档 `## Phase A: Quality & CI Foundation` 整节，熟悉各版本的 Files to modify / Steps / Acceptance criteria。
- 实现 Phase B（v0080-v0088）前，先阅读 `## Phase B: Table-Stakes Feature Gaps` 整节；实现 v0080（WindowService）前，注意技术方案文档 `### v0080` 中关于是否使用 `window_manager` 包的决策说明。
- 实现 Phase C（v0089-v0094）前，先阅读 `## Phase C: Open Source Infrastructure` 整节；各文件的完整内容模板在技术方案文档中已给出，直接参照输出。
- 实现 Phase D（v0095-v0101）前，先阅读 `## Phase D: Documentation & Presentation` 整节；README 结构、website 页面结构均在技术方案文档中已给出完整骨架。
- 实现 Phase E（v0102-v0107）前，先阅读 `## Phase E: Release Preparation` 整节以及文档末尾 `## LLM Execution Instructions` 与 `## Parallel Execution Opportunities`。
- 若本文件与技术方案文档冲突：文件清单、代码内容、验收标准以技术方案文档为准，本文件只维护执行顺序与里程碑。

### 目标与边界（本轮）

- 目标：
  1. 代码质量与 CI 基础：lint 清零、版本统一、GitHub Actions 流水线上线（Phase A）。
  2. 核心功能补全：`WindowService`、`LoggingService`、全局错误边界、`fluttron package` 打包命令（Phase B）。
  3. 开源基础设施：社区贡献文档、issue/PR 模板、`fluttron doctor`、`fluttron --version`、仓库清理（Phase C）。
  4. 文档与展示：README 重写（EN+ZH）、Why Fluttron 对比页、故障排查、包级 README、截图 GIF（Phase D）。
  5. 发布准备：版本升 0.1.0-alpha、全量测试、Smoke Test、Blog/社媒草稿、Checklist、Tag & Publish（Phase E）。
- 非目标：
  1. Windows/Linux 支持（post-v0.1.0-alpha）。
  2. pub.dev 发布（需稳定 API surface 后）。
  3. 插件系统、自动更新、系统托盘、原生菜单、多窗口（post-v0.1.0）。
  4. iOS/Android 专项验证（架构支持，但不纳入 v0.1.0-alpha 范围）。
  5. 性能专项优化（当前性能对 alpha 可接受）。

### 执行顺序（冻结）

1. Phase A（v0075-v0079）：质量地基，CI 防护网——所有后续 Phase 的前置条件。
2. Phase B（v0080-v0088）：功能完整性——桌面框架标配能力补全。
3. Phase C（v0089-v0094）：开源就绪——社区基础设施落地。
4. Phase D（v0095-v0101）：展示层——让第一印象足够好。
5. Phase E（v0102-v0107）：收口与发布——最终检查与社区公告。

### 版本任务单

#### Phase A: Quality & CI Foundation（v0075-v0079）

| 版本 | 最小可执行任务 | 技术方案必读章节 | 依赖 | 最小验收 | 状态 |
|---|---|---|---|---|---|
| v0075 | 修复 `fluttron_cli` 全部 13 个 `avoid_single_cascade_in_expression_statements` lint warnings（位于 `ui_build_pipeline_test.dart`）；确认 `analysis_options.yaml` 配置正确 | `docs/feature/v1_release_roadmap.md §v0075` | 无 | `dart analyze packages/fluttron_cli` 与 `dart analyze packages/fluttron_shared` 均报告 0 issues；现有 400+ 测试全部通过 | ✅ 已完成 |
| v0076 | 统一所有包 `pubspec.yaml` 版本为 `0.1.0-dev`；为所有包补全有意义的 `description` 字段（无 "A new Flutter project"）；为 `fluttron_cli`/`fluttron_shared` 设置 `repository` 字段 | `docs/feature/v1_release_roadmap.md §v0076` | v0075 | 5 个 pubspec 描述有意义；版本均为 `0.1.0-dev`；`dart pub get` 全部成功；无新 analyze 问题 | ✅ 已完成 |
| v0077 | 创建 `.github/workflows/ci.yml`，包含 `test-cli`（`dart test --exclude-tags acceptance`）和 `test-shared`（`dart test`）两个 job | `docs/feature/v1_release_roadmap.md §v0077` | v0076 | `.github/workflows/ci.yml` 存在；本地 `dart test --exclude-tags acceptance`（CLI）通过；本地 `dart test`（shared）通过 | ✅ 已完成 |
| v0078 | 扩展 CI YAML，增加 `test-host` 和 `test-ui` 两个 Flutter job（使用 `subosito/flutter-action@v2`，含 analyze + flutter test） | `docs/feature/v1_release_roadmap.md §v0078` | v0077 | CI YAML 包含 4 个 job；`flutter test` (host) 和 `flutter test` (ui) 本地全通过 | ⬜ 待开始 |
| v0079 | macOS Release 模式构建 playground 与 markdown_editor；测量 .app bundle 大小；记录至 `docs/performance_baseline.md`（含 Flutter/Dart 版本、与 Electron/Tauri/Flutter Desktop 对比上下文） | `docs/feature/v1_release_roadmap.md §v0079` | v0078 | `docs/performance_baseline.md` 存在并包含至少 2 个 app 的实测值 | ⬜ 待开始 |

#### Phase B: Table-Stakes Feature Gaps（v0080-v0088）

| 版本 | 最小可执行任务 | 技术方案必读章节 | 依赖 | 最小验收 | 状态 |
|---|---|---|---|---|---|
| v0080 | 在 `fluttron_host` 新增 `WindowService`（9 个方法：setTitle/setSize/getSize/minimize/maximize/setFullScreen/isFullScreen/center/setMinSize）；引入 `window_manager` 依赖；注册至默认服务列表 | `docs/feature/v1_release_roadmap.md §v0080` | v0079 | `WindowService` 类存在并已注册；`flutter analyze packages/fluttron_host` 通过 | ⬜ 待开始 |
| v0081 | 为 `WindowService` 编写完整单元测试（覆盖 9 个方法 + 错误处理 + METHOD_NOT_FOUND） | `docs/feature/v1_release_roadmap.md §v0081` | v0080 | `window_service_test.dart` 存在；`flutter test packages/fluttron_host` 全通过；错误场景已覆盖 | ⬜ 待开始 |
| v0082 | 在 `fluttron_ui` 新增 `WindowServiceClient`（9 个 typed 方法）；从 `fluttron_ui.dart` 导出；补测试 | `docs/feature/v1_release_roadmap.md §v0082` | v0080 | `WindowServiceClient` 可从 `fluttron_ui.dart` 导入；测试全通过；`flutter analyze packages/fluttron_ui` 通过 | ⬜ 待开始 |
| v0083 | 更新 host 模板 `main.dart` 与 playground 注册 `WindowService`；更新 `website/docs/api/services.md` 补 `window.*` 文档 | `docs/feature/v1_release_roadmap.md §v0083` | v0082 | 新建 app 模板默认包含 WindowService；services.md 有 window 章节；playground 演示窗口控制可用 | ⬜ 待开始 |
| v0084 | 在 `fluttron_host` 新增 `LoggingService`（ring buffer，默认 1000 条，3 个方法：log/getLogs/clear）；在 `fluttron_ui` 新增 `LoggingServiceClient`（debug/info/warn/error）；双侧均导出并注册；补测试 | `docs/feature/v1_release_roadmap.md §v0084` | v0083 | `LoggingService` 与 `LoggingServiceClient` 存在并已测试；UI 侧日志调用在 host stdout 可见 | ⬜ 待开始 |
| v0085 | 在 host 入口增加 `runZonedGuarded` + `FlutterError.onError` 全局错误边界；在 UI 入口增加同等边界；更新 host 与 UI 模板同步 | `docs/feature/v1_release_roadmap.md §v0085` | v0084 | 未捕获错误有 stack trace 日志输出；Bridge 错误有有意义提示；模板包含错误边界 | ⬜ 待开始 |
| v0086 | 实现 `fluttron package -p <path>` CLI 命令（链式：build → `flutter build macos --release` → 拷贝 .app 至 `<path>/dist/`，打印路径与大小）；注册至 CLI | `docs/feature/v1_release_roadmap.md §v0086` | v0085 | `fluttron package -p playground` 在 `dist/` 生成 .app；.app 可正常启动；bundle 大小打印至 stdout | ⬜ 待开始 |
| v0087 | 为 `PackageCommand` 增加 `--dmg` flag，调用 `hdiutil create` 生成 .dmg 文件 | `docs/feature/v1_release_roadmap.md §v0087` | v0086 | `fluttron package -p playground --dmg` 生成 .dmg；DMG 可挂载并包含 app；大小打印至 stdout | ⬜ 待开始 |
| v0088 | 更新 `examples/markdown_editor`：使用 `WindowServiceClient` 在打开文件时动态设置窗口标题（`Fluttron Editor - filename.md`）；使用 `LoggingServiceClient` 记录关键操作日志 | `docs/feature/v1_release_roadmap.md §v0088` | v0083, v0084 | 打开文件时窗口标题动态变化；host 控制台可见操作日志；原有 markdown_editor 功能无回归 | ⬜ 待开始 |

#### Phase C: Open Source Infrastructure（v0089-v0094）

| 版本 | 最小可执行任务 | 技术方案必读章节 | 依赖 | 最小验收 | 状态 |
|---|---|---|---|---|---|
| v0089 | 创建 `CONTRIBUTING.md`（含 Prerequisites/Setup/Project Structure/Development Workflow/Standards/Commit Messages/PR Process）与 `CODE_OF_CONDUCT.md`（Contributor Covenant v2.1 完整英文版） | `docs/feature/v1_release_roadmap.md §v0089` | v0088 | 两文件位于仓库根目录；CONTRIBUTING 覆盖 setup/workflow/standards；CoC 是完整 Contributor Covenant | ⬜ 待开始 |
| v0090 | 创建 `.github/ISSUE_TEMPLATE/bug_report.md`、`.github/ISSUE_TEMPLATE/feature_request.md`、`.github/pull_request_template.md`（技术方案文档有完整模板内容） | `docs/feature/v1_release_roadmap.md §v0090` | v0089 | 3 个模板文件存在；YAML frontmatter 正确；PR 模板含 analyze/test/docs checklist | ⬜ 待开始 |
| v0091 | 创建 `CHANGELOG.md`（含各 milestone 补录历史，从 v0001 到当前）与 `SECURITY.md`（含漏洞报告流程、响应时间线、覆盖范围） | `docs/feature/v1_release_roadmap.md §v0091` | v0090 | CHANGELOG 覆盖所有主要里程碑（v0001-v0074 + unreleased）；SECURITY 有明确报告指引；两文件位于仓库根目录 | ⬜ 待开始 |
| v0092 | 创建 `packages/fluttron_cli/lib/src/version.dart`（`const fluttronVersion = '0.1.0-dev'`）；在 CLI `CommandRunner` 中配置 version；验证 `fluttron --version` 输出正确 | `docs/feature/v1_release_roadmap.md §v0092` | v0091 | `fluttron --version` 输出 `0.1.0-dev`；所有 pubspec 版本与 version.dart 一致 | ⬜ 待开始 |
| v0093 | 实现 `fluttron doctor` 命令，检查 Flutter SDK / Dart SDK / Node.js / pnpm / macOS 桌面支持已启用；格式化输出 ✓/✗；exit code 0（全通过）或 1（有失败）；注册至 CLI；补测试 | `docs/feature/v1_release_roadmap.md §v0093` | v0092 | `fluttron doctor` 可运行并打印环境状态；缺失依赖明确标注；exit code 符合预期 | ⬜ 待开始 |
| v0094 | 更新 `.gitignore` 覆盖 `.opencode/`、`.test_integration/`、`.pnpm-store/`、`.mcp_servers/` 等开发工具目录；整理仓库根目录，确保无内部专用文件暴露给外部访客 | `docs/feature/v1_release_roadmap.md §v0094` | v0093 | `.gitignore` 覆盖所有开发工具目录；仓库根目录对外部访客整洁 | ⬜ 待开始 |

#### Phase D: Documentation & Presentation（v0095-v0101）

| 版本 | 最小可执行任务 | 技术方案必读章节 | 依赖 | 最小验收 | 状态 |
|---|---|---|---|---|---|
| v0095 | 重写 `README.md`（英文）：tagline、badges（CI/version/license）、截图/GIF 占位、What is Fluttron / Why Fluttron 对比表 / Quick Start / Features / Architecture Mermaid 图 / Examples / Contributing / License | `docs/feature/v1_release_roadmap.md §v0095` | v0094 | README 有对比表（vs Electron/Tauri/Flutter Desktop）、CI badge、Quick Start；结构完整无占位符 | ⬜ 待开始 |
| v0096 | 创建 `README-zh.md`（中文完整翻译）；两个 README 顶部互相添加语言切换链接 | `docs/feature/v1_release_roadmap.md §v0096` | v0095 | README-zh.md 存在；两文件顶部有互链（`[中文](README-zh.md)` / `[English](README.md)`） | ⬜ 待开始 |
| v0097 | 创建 `website/docs/getting-started/why-fluttron.md`（问题陈述/解决方案/详细对比表/适合场景/不适合场景）；更新 `website/sidebars.js` 将其置于 getting-started 第一位 | `docs/feature/v1_release_roadmap.md §v0097` | v0096 | Why Fluttron 页面存在并在 sidebar；对比表完整；`npm run build`（website）成功 | ⬜ 待开始 |
| v0098 | 创建 `website/docs/getting-started/troubleshooting.md`（≥8 个 Q&A，覆盖 Build Issues / Runtime Issues / CLI Issues / FAQ）；更新 sidebar | `docs/feature/v1_release_roadmap.md §v0098` | v0097 | 故障排查页面存在并在 sidebar；≥8 条 Q&A；website 构建成功 | ⬜ 待开始 |
| v0099 | 审计 `website/docs/` 所有 .md 文件，补全 `website/sidebars.js` 中缺失页面（含 `custom-services.md`、`codegen.md`、`annotations.md`）；为缺失 frontmatter 的页面补 `sidebar_position` | `docs/feature/v1_release_roadmap.md §v0099` | v0098 | 所有 .md 文件在 sidebar 中有对应项；无 broken 导航链接；website 构建成功 | ⬜ 待开始 |
| v0100 | 为 `fluttron_cli`、`fluttron_shared`、`fluttron_host`、`fluttron_ui` 分别创建/重写 `README.md`（含 description/installation/usage/API 概览/文档链接）；确认 `fluttron_milkdown` README 已完善 | `docs/feature/v1_release_roadmap.md §v0100` | v0099 | 5 个包均有有意义 README（无 "A new Flutter project" / TODO 占位符）；每个 README 链向 website | ⬜ 待开始 |
| v0101 | 构建运行 `examples/markdown_editor`，截图保存至 `docs/screenshots/`；录制 CLI create-build-run 流程 GIF（使用 `vhs` 或 `asciinema`）；更新 README.md 引用截图/GIF | `docs/feature/v1_release_roadmap.md §v0101` | v0100 | ≥1 张截图 + ≥1 个 GIF 存在于 `docs/screenshots/`；README.md 展示视觉资产；单文件 <2MB | ⬜ 待开始 |

#### Phase E: Release Preparation（v0102-v0107）

| 版本 | 最小可执行任务 | 技术方案必读章节 | 依赖 | 最小验收 | 状态 |
|---|---|---|---|---|---|
| v0102 | 将所有 pubspec.yaml 与 `version.dart` 版本升至 `0.1.0-alpha`；更新 CHANGELOG.md（补充 Phase A-D 所有变更）；全量测试扫描（CLI/shared/host/ui）与 analyze 扫描；逐一构建运行 3 个示例 app | `docs/feature/v1_release_roadmap.md §v0102` | v0101 | 所有版本为 `0.1.0-alpha`；所有测试通过；所有 analyze 干净；playground/markdown_editor/host_service_demo 均可构建运行 | ⬜ 待开始 |
| v0103 | 创建 `scripts/smoke_test.sh`（链式验证：install CLI → create app → build → doctor → create web_package → create host_service → package）；执行至全部通过 | `docs/feature/v1_release_roadmap.md §v0103` | v0102 | `scripts/smoke_test.sh` 无人工干预端到端全通过 | ⬜ 待开始 |
| v0104 | 撰写发布博客草稿：`docs/launch/blog_post_en.md`（英文，含问题/方案/功能/演示/代码样例/快速入门/Roadmap）与 `docs/launch/blog_post_zh.md`（中文版，适配微信/知乎平台） | `docs/feature/v1_release_roadmap.md §v0104` | v0103 | 两份博客草稿完整；技术内容准确；含 GitHub 与文档链接 | ⬜ 待开始 |
| v0105 | 撰写社媒文案草稿：`docs/launch/social_media.md`（含 Twitter/X、微博、Reddit r/FlutterDev、Hacker News 四平台） | `docs/feature/v1_release_roadmap.md §v0105` | v0104 | 所有平台文案在字符限制内；信息一致且有说服力；含 GitHub 链接 | ⬜ 待开始 |
| v0106 | 创建 `docs/launch/launch_checklist.md`（参照技术方案文档完整清单）；逐项核查；修复所有阻塞项 | `docs/feature/v1_release_roadmap.md §v0106` | v0105 | `docs/launch/launch_checklist.md` 所有条目已勾选；无阻塞问题 | ⬜ 待开始 |
| v0107 | 创建 annotated tag `v0.1.0-alpha`；push tag；在 GitHub 创建 Release（release notes 来自 CHANGELOG）；发布文档网站；发出社媒公告 | `docs/feature/v1_release_roadmap.md §v0107` | v0106 | `v0.1.0-alpha` tag 存在于 GitHub；GitHub Release 创建；文档网站上线；≥1 条社媒公告已发出 | ⬜ 待开始 |

### 并行与节奏约束

- Phase A（v0075-v0079）是所有后续 Phase 的前置条件，必须完整完成后再进入 Phase B。
- Phase B 内部并行机会：
  - Window 链（v0080→v0081→v0082→v0083）与 Logging（v0084）可并行启动；
  - Package 命令（v0086→v0087）可与 Window/Logging 链并行；
  - v0088（示例更新）依赖 v0083 + v0084，需在两者完成后执行。
- Phase C 内部并行机会：
  - CONTRIBUTING 链（v0089→v0090→v0091）串行；
  - v0092（version 命令）和 v0093（doctor 命令）可与 v0089-v0091 并行；
  - v0094（仓库清理）建议在 v0092 之后。
- Phase D 内部并行机会：
  - README 链（v0095→v0096）串行；
  - v0097（Why Fluttron）、v0098（故障排查）可与 v0095 并行；
  - v0099（sidebar 完整性）依赖 v0097 + v0098；
  - v0100（包 README）可与其他版本并行；
  - v0101（截图/GIF）依赖示例可运行，建议在 Phase B 完成后执行。
- Phase E（v0102-v0107）全部严格串行。
- 每个版本保持"单版本可独立验收"，未满足最小验收不得进入下一版本。

---

## Backlog（未来）

| 条目 | 进入条件 | 备注 |
|---|---|---|
| Windows 支持 | v0.1.0-alpha 发布后 | 需验证 `flutter_inappwebview` 在 Windows 上的可用性 |
| Linux 支持 | v0.2.0 | 优先级低于 Windows |
| pub.dev 发布 | API surface 稳定后 | 需完成版本治理策略 |
| 插件系统 | v0.2.0 | Web packages 当前充当非正式插件 |
| 系统托盘 | v0.2.0 | 常见需求，不阻塞首发 |
| 原生菜单 | v0.2.0 | 需平台专项工作 |
| 自动更新 | v0.3.0 | Nice-to-have，不阻塞采用 |
| 多窗口支持 | v0.3.0 | 复杂，可延后 |
| iOS/Android 专项验证 | v0.3.0 | 架构支持，需测试 |
| `fluttron_ui` 抽象统一 `FluttronWebViewController` | 出现跨包重复控制模式 | 已有 `fluttron_milkdown` 参考实现 |
| CLI 自动构建 web package 依赖资产 | 人工预构建成为稳定交付瓶颈 | 当前仍要求包侧先构建前端 |
| 多实例编辑器系统级稳定性测试 | 新需求包含多实例编辑场景 | 需覆盖内存、事件隔离、恢复能力 |
| web package 资产按需加载 | 启动体积与性能指标触发阈值 | 与构建链路改造联动 |

---

## 立即下一步（执行入口）

- **当前入口**：`v0078`（扩展 CI YAML，增加 `test-host` 和 `test-ui` 两个 Flutter job）
- **技术方案参阅**：`docs/feature/v1_release_roadmap.md §v0078`
- **最小验收**：CI YAML 包含 4 个 job；`flutter test` (host) 和 `flutter test` (ui) 本地全通过
- 已完成的重大能力：
  - ✅ CLI create/build/run 主链路
  - ✅ Host ↔ UI Bridge 协议
  - ✅ Flutter Web 嵌入 JS 视图 + 事件桥
  - ✅ Web Package 机制（发现、收集、注入、注册）
  - ✅ `fluttron_milkdown` 复杂包样板
  - ✅ `markdown_editor` 示例应用
  - ✅ 内建服务框架层 Client（File/Dialog/Clipboard/System/Storage）
  - ✅ `host_service` 模板与 `fluttron create --type host_service`
  - ✅ `fluttron generate services` 代码生成 CLI
