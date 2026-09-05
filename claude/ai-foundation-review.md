# ai-foundation-review · 系列 code review 工作区

本目录是 AI Foundation 系列的**跨项目代码审查工作区**：对兄弟项目（fullstack-bridge / 各底座 / 协议仓 / 能力层）做架构与代码 review。**本目录不是被 review 的项目本身**，不承载业务代码、非 git 仓——它是 review 会话的挂载点，可跨目录直接读写 `~/project/` 下各项目。

系列元信息（系列目的 / 总体设计思路 / 当前状态 / **姊妹项目位置** / copier 位置）由下方共享文件导入，只需维护一份：

@../ai-foundation-memory/series-overview.md

## 工作约定

- **被 review 对象**：以 `series-overview.md` 的「系列项目位置」表为准（角色 / 本地路径 / git）。不 review 本目录本身。
- **review 对象路径**：各项目在 `~/project/<项目名>/`；本地路径是权威，不臆测。
- **改前先读**：进一个项目 review 前，先读其 `CLAUDE.md`（含该项目的架构约束与事实源文档）。fullstack-bridge 当前在 `refactor/nunit-topology` 分支有重构态代码，review 前先确认目标分支/提交。
- **发现的问题**：分「阻塞（架构/正确性）」「建议（可读性/一致性）」「nit（风格）」三档汇报；给文件+行号定位，引用实际代码，不泛泛而谈。
- **不改代码**：review 只读 + 汇报（除非被明确要求修）；避免在非目标分支上留改动。

## Review 检查基准（系列架构不变量）

Review 时对照以下系列级原则，它们是「为什么这么设计」的判据：

- **生成 ≠ 治理**：单模板（纯前端/纯后端/CLI/单仓全栈）= git 地址 + copier，零注册；注册表（combos.yaml bases/units）只服务多端治理。代码若让单模板依赖注册/params.json 即违背。
- **底座自描述**：底座 = `git 仓 + template/ + copier.yml + params.json`（协议仓 gen-params 经 copier 内省生成，CI 防过期）。桥/工具不解析 copier.yml、不手抄参数——参数结构一律读 params.json。
- **单一真源**：一份事实只存一处。契约模板 per-combo 手写、units key 驱动目录、README 数据注入——硬编码「端名」（frontend_/backend_）或重复声明参数即 drift 源。
- **派生只读**：`derived:true` 纯派生值由 copier 算、不暴露；`derived:false` 原生参数（含派生输入如 `child_apps_raw`）才暴露。
- **桥只认 N≥2**：fullstack-bridge 管多单元组合（units+edges，N 不包括 1）；单模板不经过桥的契约/对齐机器。
- **能力层薄封装**：MCP server（bridge-mcp-server）只做给菜单/校验 spec/shell-out，不搬生成逻辑；spec 边界 = 只收结构化 spec 不收自然语言。

## 系列关键文档

- `../ai-foundation-memory/series-overview.md` — 系列元信息（状态/待办/项目位置，**单一真源**）
- `../fullstack-bridge/docs/generation-architecture.md` — 生成能力架构重构方案（重构分支保留；main 合后删除）
- `../bridge-mcp-server/docs/DESIGN.md` — 能力层设计定稿
- `../fullstack-param-protocol/SCHEMA.md` — params.json 协议 schema
