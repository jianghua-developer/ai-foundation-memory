# AI Foundation 系列元信息

> 各仓（底座/桥/能力层/review）根目录的 `CLAUDE.md` 是**符号链接** → `ai-foundation-memory/claude/<仓名>.md`（收编单源，见 ai-foundation-memory 仓 CLAUDE.md「收编机制」节；重装后跑其 `bootstrap.sh` 重建）。本文件经 `@../ai-foundation-memory/series-overview.md` 由各仓 `CLAUDE.md` 导入。
> 内容变化只改这一份，所有项目会话自动生效。**改某仓 CLAUDE.md = 改 `ai-foundation-memory/claude/<仓名>.md`，再提交该私有仓。**

## 系列目的

让 AI 生成完整业务系统。底座不仅是脚手架，更是「AI 生成业务时的约束层/工程地基」——AI 产出的质量下限由底座抬高；前后端接口契约靠 fullstack-bridge 自动对齐。

## 心智模型：规范驱动开发（SDD）

全系列统一心智：**规范（spec）是开发的唯一真源与接缝**——需求由浅到深沉淀为规范（方向 → 功能 → 架构 → 工程 → 各层间契约），**AI 从规范产出一切实现**（代码 / 真协议 / 页面 / 中间件接入）；底座、模板与确定性校验抬高规范的产出下限；判断与取舍留在壳与人。系列目的据此定义为「规范逐步细化 + AI 从规范产出 + 校验兜底」的 **SDD 工程范式**（统一覆盖此前"契约先行 / 先文档后代码"等表述）。

SDD 在 authoring 层的落地（上游 = 规范的生产段 fact→spec）见本仓规划文档 `direction-spec-chain.md`；各仓以 SDD 心智校准自身角色即可（产规范 / 从规范产出 / 抬规范下限三者之一）。

## 总体设计思路

- **目的驱动**：整个系列为「AI 生成完整业务系统」服务。底座是给 AI 套的约束层：AI 产出上限由 prompt 决定、**下限由底座抬高**。
- **分层约束**：单端底座（机制 + 契约 + 文档示例）约束单端质量；fullstack-bridge 的组合契约模板约束两端对齐；整合脚本把「前端 + 后端 + 裁剪契约」拼进一个大目录，AI 在此目录内对照同一份契约开发。
- **哲学**：契约先行、实现收敛（copier 未实现选项用 choice-validator 禁用）；只给机制不留视觉成品/便捷方法；文档一律**消费方视角**（是给 AI agent 读的）。
- **双前端直接对齐**：react / vue 同栈维护，目录 / 类型 / 文档体系一致（共享约定见各前端模板记忆），降低跨项目维护成本。
- **可插拔适配**：前端 / 后端底座**均用 copier**（前端 `template/` 子目录 + `_envops [[ ]]` 占位符避开 JSX/Vue 的 `{{ }}`；后端多参数可插拔：auth_mode / with_db / with_redis / with_child_app）；契约模板用**后端 copier 参数**做条件块、按参数渲染裁剪，保证后端代码形态与契约章节严格一致。**auth_mode 已贯通前后端**：前端 copier choice + `_tasks` 删除 + `[% if %]` 文件内条件，无感刷新模块/登录页按参数生成或裁剪；integrate.py 一个 `--auth-mode` 驱动前端/后端/契约三处（契约已是 copier 模板，全必填零默认 + StrictUndefined，渲染数据 = 生成后 answers 剔除合并，**优先级：用户参数 > 后端 > 前端**，后端为主）。
- **copier 参数默认值原则**：「由其他参数算出来的值」一律做 **`when:false` 派生参数**（如后端 `child_apps`），**原生参数默认值一律字面值、不写 jinja 表达式**。原因：桥的自发现（解析 copier.yml schema / params.json）只依赖原生参数的字面默认，派生值由 copier 计算（`when:false`）。**契约模板（已是 copier）可直接引用派生参数**——如 `{% for child in child_apps %}` 枚举子应用（`{% yield %}` 仅限文件名、正文禁用）。若原生参数出现表达式默认，桥无法静态读取且会显式告警——此约定把该边界变成自检不变量。

## 底座 ↔ 桥 接入连通机制（params.json 对齐协议）

各底座通过三件套与 fullstack-bridge 对齐；**底座必须是 git 仓**（`combos.yaml` version 基线依赖 git，非 git 本地目录桥直接拒绝）。

**① params.json（底座根目录，底座自维护）**
- 由 `bin/gen-params.py`（vendored 自协议仓 `fullstack-param-protocol`）经 **copier 内省** 从 copier.yml 生成，与 copier.yml 原子提交
- Schema：`schema_version` / `source_copier_yml_hash` / `generated_by` / `params`（**全量**参数含 `derived` 标注；`choices` 结构化——`{value}` 启用、`{value, disabled, reason}` 禁用；字面 `default`）
- 派生参数（`when:false`）标 `derived:true`；**原生参数默认必须字面值**（不写 jinja 表达式）

**② pre-commit 钩子（`.githooks/pre-commit`，best-effort）**
- 每次提交重新生成 params.json；**不拦截**提交——硬门槛在 CI
- 接入：`git config core.hooksPath .githooks`

**③ CI（`.github/workflows/params-check.yml`）双职责**
1. **自检**：`gen-params.py --verify`（params.json==copier.yml）失败 → **阻止合并**
2. **变更信号**：探测 params.json 变化 → `workflow_dispatch` 触发桥仓 `check-drift` workflow（载荷 `base_repo` + `base_version`）→ 桥跑 check.py → 开/更新 issue
   - 激活前置：仓库 Variable `DRIFT_DISPATCH_ENABLED=true` + Secret `BRIDGE_DISPATCH_TOKEN`（PAT，`workflow` scope，作用于 fullstack-bridge 仓）

**连通闭环**：底座参数变化 → CI 自检 + 信号 → 桥 check.py 对比 `combos.yaml` 基线 → 未对齐开 issue → 人/AI 改桥 `combos/<组合>/` 契约模板 + **手动 bump combos.yaml version** → 桥 CI 门槛校验 → 对齐。

**桥侧消费**：`combos.yaml`（source + version 基线，version 手动维护）、`combos/<组合>/` 契约 copier 模板（全必填零默认 + StrictUndefined）、`check.py`、`check-drift` / `bridge-gate` workflow。

**契约约定**：契约模板（已是 copier）**可直接引用派生参数**（如 `{% for child in child_apps %}` 枚举）；`{% yield %}` 仅限文件名、正文禁用。

## 目前状态（2026-09-05）

> 每行只记「当前态」；演进历史见各仓 git 提交与 ai-foundation-review 报告。

| 项目 | 状态 |
| --- | --- |
| fullstack-bridge（连通层） | 多单元组合（N≥2）治理/执行：Click CLI（generate / check / 内省 `list-combos`·`show-combo`）+ 底座 clone/baked + **R1/A2** + **U1 `shared:true`** 已落 main（2026-09-05，53 测试）。剩余 R4/A1 待第二组合（「待办·仅剩」） |
| python-fastapi-template（后端） | 已接入 params.json 对齐协议并升 v2（`selection` 区 + 双区 CI/钩子 + copier 9.17.1），main 已推送（2026-09-05） |
| vite-react-spa-template（前端 React） | 已接入 params.json 对齐协议并升 v2（selection 策展 + 双区 CI/钩子 + copier 9.17.1），main 已推送（2026-09-05） |
| vite-vue-spa-template（前端 Vue） | 已接入 params.json 对齐协议并升 v2（selection 策展 + 双区 CI/钩子 + copier 9.17.1），main 已推送（2026-09-05） |
| frontend-template-copier（前端生成器） | 已发布 npm 0.0.1（前端模板已迁 copier，工具退役） |
| fullstack-param-protocol（协议仓） | `gen-params.py`（copier 内省 → params.json）+ `SCHEMA.md`；uv 管理依赖（copier 钉版本）。**v2 两区已落 main（2026-09-05）**：`params`（派生+hash）/ `selection`（策展+schema、gen-params 轮转保留）+ 双区校验 + **全链 copier 9.17.1** + selection 字段集契约（db2e9a8/10dcbed/5f94b8d/2dda1ba）；已推送 |
| bridge-mcp-server（能力层 MCP 封装） | **P3 生成面 server 已落地并推 origin main（2026-09-05）**：uv + FastMCP，六生成工具（单端 3+多端 3）+ 资源/玩法/壳侧 skill；**一面一 server**（治理面占位，check/契约维护不入）；桥入口纯 env（BRIDGE_EXE>BRIDGE，不暴露源码 cli.py）；严格 spec + 28 测试（含 MCP stdio/生成 e2e）；DESIGN/implementation-plan/README/入册 SOP 齐。P4 剩「未来组合就绪后验证 combo 段纪律」（待 python-vue / ui-bff-api）；治理面 MCP / 契约维护 Agent 见「后期待办」 |

**待办（主线）——2026-09-05 整理**（已完成项已归档，历史见各仓提交与 ai-foundation-review 报告）

**主线方向（2026-09-05 定稿，未立项未动码）**：下阶段主线 = **authoring 规格链**（一句话 → 可运行系统：每段接缝的规格生产能力，规格 schema/玩法/校验 + 现期 spec/authoring MCP 面；上游规格仓 `authoring-spec`（待命名）承载，dogfood 临时目录）。完整决议/证伪条件/落地拆分见同仓 `direction-spec-chain.md`。本表"仅剩"待办是它的下游承接，不冲突。

✅ 已收口：生成能力架构重构（桥 N≥2 + Click CLI + clone/baked）；bridge-mcp-server 评审收敛跨仓改动 ①-④（协议 v2 两区 / 三底座 selection+CI / 桥内省面 + R1/A2 + shared / 生成面 server，均已合 main 推送）。

**仅剩（均依赖未来组合 / 新底座，非当前阻塞）**：
- **R4 + A1（ui-bff-api 三单元链接入时）**：多 provider 共享参数与 merge_order 统一为「最深 provider 赢」；链形校验收紧为单一路径（出入度 + 连通，防星型漏过）。
- **契约层扩展**：python-vue 组合、更多后端栈、jwt 模式契约补章节（待后端 jwt 实现）。
- **新底座接入**：nuxt-fullstack / bff-gateway / cli 三件套（单端入册流程见 bridge-mcp-server `docs/onboarding-single-template.md`）。
- 新组合/底座就绪后：验证 combo 段「仅不可约」纪律；需要时给 combos.yaml unit 加 kind 机器字段（`list_combos` frontend/backend_kind 过滤）——届时一并评估。

**后期待办（非主线，调研已出方案）**：
- **copier 前端 wrapper（降低开发者心智负担）**：动机纯为降低前端开发者心智负担（不感知 python/copier）。复用已退役的 frontend-template-copier 仓库做 npm wrapper（`npx create-xxx` 内部调 copier，条件裁剪/answers 重放能力全保留）。调研结论：前端生态无 copier 1:1 等价物（条件裁剪最弱、更新机制全走 git 三路合并），wrapper 是成本最低路径；若未来要脱离 python 依赖再考虑 degit+自建条件裁剪 或 @template-tools/template-sync 重构（更新语义会降级为 git 合并）。
- **CLI 框架（✅ 已实施：Click 非 Typer）**：桥 CLI 全量 Click（数据驱动动态注册，契合 MCP 确定性 schema；详析见 fullstack-bridge 历史提交/「目前状态」行）。
- **治理面 check 链 MCP（未来，跨壳需要时再评估，2026-09-05 定调）**：桥 `cli.py check`（漂移/对齐）现服务 CI workflow（bridge-gate / check-drift），**不纳入生成 MCP**（bridge-mcp-server DESIGN §10：生成面与治理面分开）。若未来出现「系列维护助手 / 跨壳治理」需稳定调用 check/漂移 → 另起治理面 MCP server（数据面：check 报告 + 底座 diff + drift issue 流；玩法从真源派生）。当前 YAGNI。
- **契约维护 Agent（独立 agent 仓，AI 维护契约；立项信号 = 第二组合 / 多 edge 契约，2026-09-05 定调）**：drift issue / bridge-gate 失败触发 → AI 改 fullstack-bridge 工作副本的 `combos/<组合>/`（copier.yml 条件 + CONTRACT.md.jinja）+ `combos.yaml` version/combo 段 → 本地 `cli.py check` 绿 → PR → ai-foundation-review gate。仓内 = 使命/SOP（契约即 wiki 规则：单一真源在底座 params/selection、coverage hard vs advisory、combo 段纪律、version bump 语义）+ 确定性脚手架（extract-diff-context / coverage-gap，能算的不靠 LLM 猜）+ 质量门。与生成 MCP **不相交**（生成只读桥核心、它写桥核心）；独立演进，不入任何底座/桥仓。

## 系列项目位置

| 项目 | 角色 | 本地 | git |
| --- | --- | --- | --- |
| ai-foundation-memory | 系列元信息 + 各仓本地 CLAUDE.md 收编 + 规划工作区（私有） | `~/project/ai-foundation-memory` | `git@github.com:jianghua-developer/ai-foundation-memory.git` |
| ai-foundation-review | 系列 code review 工作区（评审报告归档于 `reports/`，见「评审报告归档」节；私有） | `~/project/ai-foundation-review` | `git@github.com:jianghua-developer/ai-foundation-review.git` |
| frontend-template-copier | 前端模板生成器（已退役） | `~/project/frontend-template-copier` | `git@github.com:jianghua-developer/frontend-template-copier`（npm 已发布 0.0.1） |
| fullstack-param-protocol | 底座对齐协议仓 | `~/project/fullstack-param-protocol` | `git@github.com:jianghua-developer/fullstack-param-protocol.git` |
| fullstack-bridge | 前后端连通层 | `~/project/fullstack-bridge` | `git@github.com:jianghua-developer/fullstack-bridge.git` |
| python-fastapi-template | 后端底座（Python） | `~/project/python-fastapi-template` | `git@github.com:jianghua-developer/python-fastapi-template.git` |
| vite-react-spa-template | 前端底座（React） | `~/project/vite-react-spa-template` | `git@github.com:jianghua-developer/vite-react-spa-template.git` |
| vite-vue-spa-template | 前端底座（Vue） | `~/project/vite-vue-spa-template` | `git@github.com:jianghua-developer/vite-vue-spa-template.git` |

## 评审报告归档（如何查找）

跨项目 review 由 ai-foundation-review 工作区产出，报告**长期保留**于私有仓 `ai-foundation-review`（根 `reports/`，已 git 版本化防丢）。两类审查位置不同：

**① 代码评审（分支/提交级，三档问题）**

```
reports/{project_name}/{branch}/{commit-hash}/{datetime}/review-report.md
```

- `project_name` = 被 review 项目目录名（如 `fullstack-bridge` / `python-fastapi-template`）；
- `branch` = 被 review 分支，含 `/` 按字面嵌套（如 `refactor/nunit-topology`）；
- `commit-hash` = 被 review 提交（分支 tip / 审查基线，短 sha）——同一分支不同提交的评审各归其位；
- `datetime` = 报告生成时刻子目录（`YYYY-MM-DD_HHMMSS`），同日多次 review 不覆盖。

**查找**：`ls reports/<项目>/<分支>/<commit-hash>/` → 取最新 `datetime` 子目录即最近一份评审。

**② 总体架构评审（系列级适配度，无项目/分支维度）**

```
reports/architecture/{datetime}/architecture-review.md
```

**查找**：`ls reports/architecture/` → 取最新 `datetime` 子目录即最近一份架构评估。

> 注：2026-09-04 前按旧规则（无 commit-hash 段）归档的唯一一份代码报告已补入 commit-hash 层对齐新结构（`fullstack-bridge/refactor/nunit-topology/dc2b13f/`），当前无旧布局残留。

## copier 位置

- **前端 / 后端均用 copier CLI**——本机已装（**9.17.1，全链钉版**），`copier copy <template> <dest>`；各底座模板体在 `template/`（copier.yml 位于其内）；前端模板 `_envops` 用 `[[ ]]` 标签避开 JSX/Vue 的 `{{ }}`
- **frontend-template-copier 已退役**——前端模板迁 copier 前的复制器（npm `frontend-template-copier@0.0.1`），不再使用
