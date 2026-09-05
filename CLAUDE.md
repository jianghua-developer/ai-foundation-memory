# ai-foundation-memory · AI Foundation 系列记忆、收编与规划工作区

本目录承载三件事（**私有 git 仓**，远端 `git@github.com:jianghua-developer/ai-foundation-memory.git`）：
1. **系列元信息唯一事实源** —— `series-overview.md`，被各底座/桥/壳仓 `CLAUDE.md` 以 `@../ai-foundation-memory/series-overview.md` 导入；改一处、全系列会话生效。
2. **各仓本地 CLAUDE.md 的 canonical 收编仓** —— `claude/<repo>.md`；各仓 `~/project/<repo>/CLAUDE.md` 是指向它的符号链接（bootstrap.sh 重建）。CLAUDE.md 属本地 Claude 资产、不入各仓 git（系列通例），集中到本仓随私有 git 版本化防丢。
3. **未来系列方向规划工作区** —— 在本目录直接开会话 = 在做系列级事（整理/同步元信息，或规划未来方向）。规划产物用**独立文档**沉淀，不塞进 series-overview。

系列事实在下方 `@./series-overview.md` 导入（与各仓同源）；本文件只约定「在本目录怎么做」，不复制系列事实。

## 文件与职责

- `series-overview.md` — 系列事实唯一一份：系列目的 / 总体设计思路 / 目前状态表 / 待办 / 项目位置 / 评审归档约定 / copier 位置。被各仓导入 + 本文件导入，**改动需守下节铁律**。
- `CLAUDE.md`（本文件） — 本目录操作约定（定位/编辑规则/收编机制/规划规范/收敛不变量索引）；不对外导入。
- `claude/<repo>.md` — 各仓本地 CLAUDE.md 的 canonical（单源）。**改某仓的 CLAUDE.md = 改这里对应文件**（各仓根只是 symlink）；收编范围见 bootstrap.sh `REPOS` 数组。
- `bootstrap.sh` — 一键重建各仓根 CLAUDE.md 符号链接（重装/迁移后 `git clone` 本仓 + 跑它即恢复）。
- `direction-*.md`（规划时新建） — 一个未来方向一份（见「规划文档」节）。

## CLAUDE.md 收编机制（重装/迁移恢复）

1. `git clone git@github.com:jianghua-developer/ai-foundation-memory.git ~/project/ai-foundation-memory`
2. 各系列仓就位后跑 `~/project/ai-foundation-memory/bootstrap.sh`（把 `~/project/<repo>/CLAUDE.md` 建成指向 `claude/<repo>.md` 的**相对符号链接**）。
3. symlink 用相对路径 —— `~/project` 整树搬迁后链接仍存活；canonical 内 `@../ai-foundation-memory/series-overview.md` 相对导入也按 repo 根逻辑路径解析（实证 LOGICAL）。
4. 新增收编仓 → 把 canonical 放 `claude/<新仓>.md` 并加入 bootstrap.sh `REPOS`；该仓根 `CLAUDE.md` 建 symlink 且确保该仓 `.gitignore` 含 `CLAUDE.md`。

## series-overview.md 编辑铁律（导入面大 = 高爆炸半径）

- 状态表每行只记「当前态」；演进历史一律指向各仓 git 提交与 ai-foundation-review 报告，**不写回放**。
- 无通用性的本机/单仓构建约束**禁止写入本目录任何文件**（会被各仓 CLAUDE.md 拉进会话）；要记 → 记对应仓自身 CLAUDE.md。
- markdown linter 提示（compact 表、fence language 等）视为 cosmetic，不为此重写正文。
- 本仓**私有 git**：改 series-overview.md / claude/* 后提交推送（同款 commit/push 纪律）。

## 规划文档（未来系列方向）

方向明确后**新建独立 md**，不要把大段规划写进 series-overview（保持被导入文件精简、只放当前态）。命名 kebab-case：`direction-<主题>.md`；方向多了再建子目录 + 索引。

建议骨架（延续全系列「先文档后代码」节奏）：
1. **背景与动机** —— 为什么现在做：引用 series-overview 状态/待办 + 相关仓 docs/，不凭空起题。
2. **目标与非目标** —— 非目标同样写清，防止范围蔓延。
3. **方案对比** —— ≥2 候选 + 取舍；先对照「系列收敛不变量」看是否已被论证/否决，别重复论证。
4. **决议** —— 结论 + 理由 + 日期；确认落地的同步到所属仓 docs/DESIGN.md（唯一事实源）。
5. **落地拆分** —— 归属哪些仓、阶段（P0…）、每步先改哪仓 DESIGN/计划再动码。

规划若落地为跨仓改动 → 走既定节奏：所属仓 DESIGN 先行 → 分阶段执行 → ai-foundation-review 评审 → 报告归档（约定见 series-overview「评审报告归档」）→ 同步回本目录状态表/待办。

## 系列收敛不变量（新方向先对照；确要推倒 → 在规划文档写明推翻理由并同步受影响 DESIGN）

> 均为历轮评审/设计收敛定案，代价高；多数可复用、不值得再争。索引只给归属文档，细节去那读。

- **面分离（一面一 server）**：生成面与治理面（check/契约维护）不混入同一 MCP server；同仓可并存多 server，各自独立演进 → bridge-mcp-server `docs/DESIGN.md`。
- **双路径 × 双链**：单端 = 底座协议（params.json 两区）自述、零注册直读、不进桥；多端（N≥2）= 注册组合、**纯 cli** 消费桥生成面；server 不搬生成逻辑、桥不反向长单端逻辑 → bridge-mcp-server `docs/DESIGN.md`。
- **selection 单一真源 / 两区协议**：`params`（派生+hash）/`selection`（策展+schema、gen-params 轮转保留）分区；深选择事实只在底座写一份；**桥只消费 + 叠加 combo 段不可约事实**，combo 段字段限 suited_for/tradeoffs → fullstack-param-protocol `SCHEMA.md` + fullstack-bridge `docs/DESIGN.md` §8。
- **注册表是菜单不是门槛**：templates.yaml / combos.yaml 只服务引导；combo 段只放不可约事实、不抄 selection；spec 只收结构化参数、派生参数禁止传入；一管道一工具 → 协议仓 + bridge-mcp-server `docs/DESIGN.md` + fullstack-bridge `docs/DESIGN.md` §8。
- **参数面纪律**：原生参数默认字面值、派生参数 `when:false`；**共享参数 = 全链单一决策单值广播（U1 `shared:true`）**，不拆逐端命名空间 → fullstack-param-protocol `SCHEMA.md` + fullstack-bridge `docs/DESIGN.md` §6。
- **契约先行 / 实现收敛 / copier 全链钉版本**：契约模板可引用派生参数、`{% yield %}` 仅限文件名；copier 版本跨链一致 → 各底座三件套 + fullstack-bridge `docs/DESIGN.md` §5.1/§11.12。
