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

## 当前阶段目标（更新于 2026-02-15）

### 北极星目标

在已完成 Web Package 机制 MVP（v0032-v0041）的基础上，交付首个“真实复杂度”的官方 Web Package：

- 包名：`fluttron_milkdown`
- 目标：以 `MilkdownEditor` 组件形式提供可复用的 Markdown 编辑能力（包含主题、事件、控制 API）
- 验证点：反向验证 Web Package 机制在“大依赖 + CSS + 运行时控制 + 事件桥”场景下的稳定性

### 当前能力基线（已具备）

| 能力 | 状态 | 说明 |
|---|---|---|
| CLI create/build/run | ✅ | 已可稳定创建、构建、运行 Fluttron app |
| Host ↔ UI Bridge | ✅ | 协议、错误处理、服务注册机制稳定 |
| Flutter Web 嵌入 JS 视图 | ✅ | `FluttronHtmlView` + `FluttronWebViewRegistry` 已落地 |
| JS→Flutter 事件桥 | ✅ | `FluttronEventBridge` 已落地 |
| 前端构建流水线 | ✅ | `pnpm + esbuild + 三阶段校验` |
| Web Package MVP | ✅ | 依赖发现、资源收集、HTML 注入、注册代码生成、诊断命令、验收矩阵 |

### 当前剩余差距

| # | 差距 | 说明 |
|---|---|---|
| 1 | 缺少复杂官方包样板 | 目前机制主要由测试与模板验证，缺少“高复杂业务包”的实战证明 |
| 2 | 缺少 Dart→JS 运行时控制模式 | 现有机制对“创建后控制”场景支持不足，需在 `fluttron_milkdown` 先验证 |
| 3 | playground 仍有历史集成痕迹 | 需要完全迁移到 web package 依赖形态，避免双轨维护 |

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

### 历史迭代摘要（结构化）

| 区间 | 主题 | 结果 |
|---|---|---|
| v0001-v0019 | 基础框架与 CLI 主链路 | Host/UI/Shared/CLI create-build-run 全链路建立 |
| v0020-v0031 | 前端集成能力沉淀 | `HtmlView/EventBridge` 核心能力抽象，模板与 playground 对齐 |
| v0032-v0041 | Web Package MVP | 机制完整落地并完成验收 |
| v0042 | `fluttron_milkdown` 骨架 | 包骨架、最小编辑器、构建产物完成 |

注：详细历史记录以 Git 提交与 PRD 文档为准，不再在本文件重复堆叠逐条流水账。

---

## 当前重大需求：`fluttron_milkdown`（v0042-v0050）

### 需求来源与引用关系

- 主设计文档（Source of Truth）：`docs/feature/fluttron_milkdown_design.md`
- 本文职责：把设计文档转换为“执行级迭代任务单”，并给出每一步的验收边界。
- 规则：
  - 不在本文复制整段设计说明。
  - 每个版本都标注设计文档章节引用，便于追踪。

### 目标与边界

#### 本轮目标（必须达成）

- 交付可发布的 `fluttron_milkdown` 包（Dart API + JS 资产 + README）。
- playground 完成迁移，使用包化能力，不再依赖手写大段集成代码。
- 通过机制验证清单（V1-V12）并形成结果记录。

#### 本轮非目标（明确不做）

- `fluttron_ui` 通用控制器抽象上游化（仅记录为机会点）。
- Web Package 自动构建依赖包（仍要求先手动构建 web package 前端资产）。
- pub.dev 分发策略与版本治理。

### 统一实现约束（给后续 LLM 的硬约束）

1. `viewFactories.type` 固定使用 `milkdown.editor`，不要中途变更命名。
2. 事件命名空间固定前缀：`fluttron.milkdown.editor.*`。
3. JS 控制入口固定全局函数：`window.fluttronMilkdownControl`。
4. 控制通道返回值统一 `{ ok: boolean, result?: any, error?: string }`。
5. 所有事件 payload 必须带 `viewId`（用于多实例过滤）。
6. CSS 必须维持隔离前缀 `fluttron-milkdown`，禁止裸全局选择器污染。
7. 每个版本结束必须运行该版本定义的最小验收命令并记录结果。

### 执行顺序（不可打乱）

1. v0042-v0043：先打通“包可建 + 可被 playground 发现并运行”。
2. v0044-v0045：完善编辑器能力与事件系统。
3. v0046-v0047：补齐控制通道与 Dart 控制器。
4. v0048：主题体系。
5. v0049-v0050：测试、文档、迁移收口。

---

## v0042-v0050 详细迭代任务单

> 状态标记：`[ ]` 未开始，`[~]` 进行中，`[x]` 已完成

### [x] v0042 - `fluttron_milkdown` 包骨架与最小可运行编辑器 ✅

**完成日期**: 2026-02-15

**目标**

- 在 `web_packages/fluttron_milkdown` 建立完整包骨架。
- 完成最小编辑器渲染（可显示、可输入、可构建）。

**实现任务（已全部完成）**

1. ✅ 创建目录与基础文件：`pubspec.yaml`、`fluttron_web_package.json`、`analysis_options.yaml`、`README.md`、`CHANGELOG.md`。
2. ✅ 建立 `frontend/` 构建链路：`package.json`、`scripts/build-frontend.mjs`、`src/main.js`。
3. ✅ 在 JS 侧实现最小工厂函数 `window.fluttronCreateMilkdownEditorView(viewId, config)`，支持 config 归一化：`initialMarkdown/theme/readonly`。
4. ✅ 在 Dart 侧建立公共导出 `lib/fluttron_milkdown.dart` 与最小 `MilkdownEditor`（仅封装 `FluttronHtmlView(type: 'milkdown.editor')`）。
5. ✅ 运行并提交 `web/ext/main.js` 与 `web/ext/main.css` 产物。

**验收结果**

- `dart analyze`: 无问题 ✅
- `pnpm run js:build`: 成功 ✅
- 产物文件：
  - `web/ext/main.js`: 5.2MB（含 KaTeX 字体内联）
  - `web/ext/main.css`: 1.5MB
- `fluttron_web_package.json` 中 `type/jsFactoryName/assets` 与实现一致 ✅

**注意事项**

- Bundle 体积较大（5.2MB JS + 1.5MB CSS），主要因为 KaTeX 字体内联和完整 CodeMirror 语言支持，后续可优化。

**设计引用**

- `docs/feature/fluttron_milkdown_design.md` §3.2、§4.1、§4.2、§4.8、§5.1、§5.4、§6、§10 Phase 1。

---

### [~] v0043 - playground 接入并跑通 Web Package 全链路

**目标**

- 让 playground 通过 path 依赖接入 `fluttron_milkdown`。
- 验证 Discovery/Collection/Injection/Registration 四阶段在真实包上可用。

**实现任务（必须全部完成）**

1. 在 `playground/ui/pubspec.yaml` 添加 `fluttron_milkdown` path 依赖并执行 `flutter pub get`。
2. 执行 `fluttron build -p playground`，检查构建日志必须出现 web package 发现与注入阶段。
3. 校验以下构建产物：
   - `playground/ui/build/web/ext/packages/fluttron_milkdown/main.js`
   - `playground/ui/build/web/ext/packages/fluttron_milkdown/main.css`
   - `playground/ui/build/web/index.html` 中存在对应 `<script>` 与 `<link>`。
4. 校验注册代码：`playground/ui/lib/generated/web_package_registrations.dart` 包含 `milkdown.editor` 注册。
5. playground 页面改用 `MilkdownEditor` 最小渲染，确保 macOS 宿主可见编辑器。

**涉及文件（最小清单）**

- `playground/ui/pubspec.yaml`
- `playground/ui/lib/main.dart`
- `playground/ui/lib/generated/web_package_registrations.dart`（生成文件）

**验收命令**

- `cd playground/ui && flutter pub get`
- `fluttron build -p playground`
- `fluttron run -p playground --no-build -d macos`

**完成定义（DoD）**

- 构建与运行成功。
- 编辑器在 playground 可见并可输入。
- 注入与注册文件均正确生成。

**设计引用**

- `docs/feature/fluttron_milkdown_design.md` §9.1（V4-V8, V12）、§10 Phase 1。

---

### [ ] v0044 - 编辑能力扩展（GFM + 高亮 + 编辑体验）

**目标**

- 将最小编辑器升级为可用的 Markdown 生产力编辑器。

**实现任务（必须全部完成）**

1. JS 侧启用 GFM 相关能力（表格、任务列表、删除线）。
2. 启用代码块高亮能力（Prism）。
3. 启用编辑体验能力（history、slash、tooltip 等）。
4. 对配置对象预留 feature toggle 字段（即使暂不暴露 Dart API，也要在 JS 层可演进）。
5. 记录构建后体积指标（JS/CSS 原始大小 + gzip 大小），写入 package README 的“Bundle Metrics”段落。

**涉及文件（最小清单）**

- `web_packages/fluttron_milkdown/frontend/src/main.js`
- `web_packages/fluttron_milkdown/frontend/src/editor.js`
- `web_packages/fluttron_milkdown/README.md`

**验收命令**

- `cd web_packages/fluttron_milkdown/frontend && pnpm run js:build`
- `fluttron build -p playground`

**完成定义（DoD）**

- playground 中表格、任务列表、代码块高亮、slash/tooltip 可见。
- README 有体积数据与预算对照。

**设计引用**

- `docs/feature/fluttron_milkdown_design.md` §4.1、§4.3、§13、§10 Phase 2。

---

### [ ] v0045 - 事件系统完善（change/ready/focus/blur + Typed Event）

**目标**

- 建立可稳定消费的事件层，为业务状态同步与后续控制器绑定提供基础。

**实现任务（必须全部完成）**

1. JS 侧统一事件分发模块：`change/ready/focus/blur`。
2. `change` 事件 payload 至少包含：`viewId/markdown/characterCount/lineCount/updatedAt`。
3. Dart 侧新增 `MilkdownChangeEvent` 类型和 `milkdownEditorChanges()` helper。
4. `MilkdownEditor` 增加 `onChanged` / `onReady` 回调并正确订阅/释放。
5. 事件监听必须按 `viewId` 过滤，避免多实例串流。

**涉及文件（最小清单）**

- `web_packages/fluttron_milkdown/frontend/src/events.js`
- `web_packages/fluttron_milkdown/frontend/src/main.js`
- `web_packages/fluttron_milkdown/lib/src/milkdown_events.dart`
- `web_packages/fluttron_milkdown/lib/src/milkdown_editor.dart`

**验收命令**

- `cd web_packages/fluttron_milkdown && dart analyze`
- `fluttron build -p playground`
- 手工验证：编辑内容时 Dart 侧状态实时更新

**完成定义（DoD）**

- 事件完整触发且 payload 字段稳定。
- Dart 端可消费 typed event，不再直接散落 map 解析逻辑。

**设计引用**

- `docs/feature/fluttron_milkdown_design.md` §4.5、§5.5、§9.1（V9）、§10 Phase 3。

---

### [ ] v0046 - JS 控制通道（Dart→JS Runtime Control）

**目标**

- 提供编辑器创建后的运行时控制能力。

**实现任务（必须全部完成）**

1. 在 JS 全局暴露 `window.fluttronMilkdownControl(viewId, action, params)`。
2. 支持动作：`getContent`、`setContent`、`focus`、`insertText`、`setReadonly`、`setTheme`。
3. 建立 `editorInstances: Map<viewId, instance>` 并确保实例生命周期正确（创建/销毁）。
4. 未找到实例、未知 action、参数不合法时返回 `{ok:false,error}`，不可静默失败。
5. `ready` 事件确保包含 `viewId`，为 controller 绑定做准备。

**涉及文件（最小清单）**

- `web_packages/fluttron_milkdown/frontend/src/main.js`
- `web_packages/fluttron_milkdown/frontend/src/editor.js`

**验收命令**

- `cd web_packages/fluttron_milkdown/frontend && pnpm run js:build`
- 在浏览器控制台或 playground 调试按钮验证各 action

**完成定义（DoD）**

- 所有 action 都可返回可预期结果。
- 失败路径都有明确错误信息。

**设计引用**

- `docs/feature/fluttron_milkdown_design.md` §4.4、§7.1、§7.2、§7.3、§9.1（V10）、§10 Phase 4。

---

### [ ] v0047 - Dart 控制器 API（MilkdownController + Interop）

**目标**

- 将控制通道封装成 Dart 侧稳定 API，供业务代码直接调用。

**实现任务（必须全部完成）**

1. 新增 `MilkdownController`：`getContent/setContent/focus/insertText/setReadonly/setTheme`。
2. 新增 `milkdown_interop.dart` + `*_web.dart` + `*_stub.dart` 条件导入。
3. `MilkdownEditor` 在 ready 事件中 `controller.attach(viewId)`，在 dispose 时 `detach()`。
4. controller 未 attach 时调用方法必须抛 `StateError`，错误文案清晰。
5. playground 增加操作按钮（获取内容、插入文本、切换只读），作为交互验收面板。

**涉及文件（最小清单）**

- `web_packages/fluttron_milkdown/lib/src/milkdown_controller.dart`
- `web_packages/fluttron_milkdown/lib/src/milkdown_interop.dart`
- `web_packages/fluttron_milkdown/lib/src/milkdown_interop_web.dart`
- `web_packages/fluttron_milkdown/lib/src/milkdown_interop_stub.dart`
- `web_packages/fluttron_milkdown/lib/src/milkdown_editor.dart`
- `playground/ui/lib/main.dart`

**验收命令**

- `cd web_packages/fluttron_milkdown && dart analyze`
- `fluttron build -p playground`
- `fluttron run -p playground --no-build -d macos`

**完成定义（DoD）**

- 控制器全部 API 可用。
- 未就绪调用可稳定报错。
- playground 演示按钮可证明控制链路畅通。

**设计引用**

- `docs/feature/fluttron_milkdown_design.md` §5.3、§5.6、§7.2、§7.3、§10 Phase 4。

---

### [ ] v0048 - 多主题支持（初始化主题 + 运行时切换）

**目标**

- 提供 6 种内置主题，并保证切换即时、无明显闪烁。

**实现任务（必须全部完成）**

1. Dart 侧新增 `MilkdownTheme` 枚举（frame/classic/nord + dark 变体）。
2. JS 构建期打包全部主题 CSS，运行时通过 class/data-theme 切换。
3. `MilkdownEditor(theme: ...)` 支持初始主题。
4. `MilkdownController.setTheme(...)` 支持运行时切换。
5. playground 增加主题下拉框，验证 UI 即时变化。

**涉及文件（最小清单）**

- `web_packages/fluttron_milkdown/lib/src/milkdown_theme.dart`
- `web_packages/fluttron_milkdown/lib/src/milkdown_editor.dart`
- `web_packages/fluttron_milkdown/lib/src/milkdown_controller.dart`
- `web_packages/fluttron_milkdown/frontend/src/themes.js`
- `web_packages/fluttron_milkdown/frontend/src/main.js`
- `playground/ui/lib/main.dart`

**验收命令**

- `cd web_packages/fluttron_milkdown/frontend && pnpm run js:build`
- `fluttron build -p playground`
- 手工验证主题切换（light/dark）

**完成定义（DoD）**

- 6 个主题都可切换。
- 切换后内容不丢失，编辑状态稳定。

**设计引用**

- `docs/feature/fluttron_milkdown_design.md` §4.6、§8.1、§8.2、§8.3、§10 Phase 5。

---

### [ ] v0049 - 测试收口与机制验证清单执行

**目标**

- 用测试与验证报告证明 `fluttron_milkdown` 和 Fluttron 机制都可稳定运行。

**实现任务（必须全部完成）**

1. 增加 Dart 单测：controller/theme/events/editor 生命周期。
2. 增加集成验证：至少覆盖“初始化 -> 编辑 -> 事件 -> 控制 -> 主题切换”。
3. 严格执行 `fluttron_milkdown_design` 的 V1-V12 验证清单。
4. 新增验证报告文档（建议）：`docs/feature/fluttron_milkdown_validation.md`，逐项记录结果与证据。
5. 将发现的机制缺口写入 Backlog（带触发条件与优先级）。

**涉及文件（最小清单）**

- `web_packages/fluttron_milkdown/test/milkdown_editor_test.dart`
- `web_packages/fluttron_milkdown/test/milkdown_controller_test.dart`
- `web_packages/fluttron_milkdown/test/milkdown_theme_test.dart`
- `docs/feature/fluttron_milkdown_validation.md`

**验收命令**

- `cd web_packages/fluttron_milkdown && dart test`
- `cd web_packages/fluttron_milkdown && dart analyze`
- `fluttron build -p playground`

**完成定义（DoD）**

- 测试全部通过。
- 验证清单有完整记录，不允许“口头通过”。

**设计引用**

- `docs/feature/fluttron_milkdown_design.md` §9.1、§9.2、§10 Phase 6、§12。

---

### [ ] v0050 - 文档完善与 playground 最终迁移

**目标**

- 形成可对外使用的包文档，并完成 playground 的最终清理迁移。

**实现任务（必须全部完成）**

1. 完整编写 `fluttron_milkdown` README：安装、构建、最小示例、控制器、主题、事件、FAQ。
2. playground 移除历史内联集成残留（含过时 JS 依赖与手写桥接代码）。
3. 更新项目文档入口（如 website/docs）加入 `fluttron_milkdown` 使用说明。
4. 在 `docs/dev_plan.md` 的迭代记录中补充 v0042-v0050 完成状态与关键结论。
5. 做一次端到端回归：新 clone 场景下按文档可完成构建运行。

**涉及文件（最小清单）**

- `web_packages/fluttron_milkdown/README.md`
- `playground/ui/frontend/src/main.js`
- `playground/ui/package.json`
- `playground/ui/lib/main.dart`
- `docs/dev_plan.md`
- `website/` 下对应文档（如存在）

**验收命令**

- `fluttron build -p playground`
- `fluttron run -p playground --no-build -d macos`
- 文档示例代码 smoke 运行一次

**完成定义（DoD）**

- playground 仅保留包化调用路径。
- README 按“安装即用”标准可独立指导新用户。
- 本阶段正式收口。

**设计引用**

- `docs/feature/fluttron_milkdown_design.md` §11、§10 Phase 6、§14。

---

## Backlog（未来）

- 候选增强：`fluttron_ui` 抽象统一 `FluttronWebViewController`（待 `fluttron_milkdown` 模式稳定后评估）。
- 候选增强：CLI 自动构建 web package 依赖的前端资产（当前仍要求预构建）。
- 候选增强：多实例编辑器的系统级稳定性专项测试（当前可用但仍偏实验性质）。
- 候选增强：按需加载/懒加载 web package 资产以优化启动体积。
- 候选增强：pub.dev 分发规范与版本兼容矩阵。

---

## 立即下一步（执行入口）

- 当前起始版本：`v0043`
- 第一提交目标：playground 接入 `fluttron_milkdown`，验证 Discovery/Collection/Injection/Registration 四阶段
- 完成后立即进入 `v0044` 做编辑能力扩展，不要提前并行开发后续版本

### v0042 完成记录

| 项目 | 状态 |
|---|---|
| 包骨架创建 | ✅ |
| JS 工厂函数 | ✅ `fluttronCreateMilkdownEditorView` |
| Dart Widget | ✅ `MilkdownEditor` |
| 构建产物 | ✅ main.js (5.2MB) + main.css (1.5MB) |
| dart analyze | ✅ 无问题 |

