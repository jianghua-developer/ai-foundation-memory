# fullstack-param-protocol · 底座对齐协议

本项目是 AI Foundation 系列的**协议仓**：定义各底座 copier.yml ↔ params.json 的对齐协议（`gen-params.py` 经 copier 内省生成/校验）+ `SCHEMA.md`（schema 单一真源），并提供底座接入模板（`hooks/pre-commit` + `workflows/params-check.yml`）。

**本仓通常无独立本地会话**——代码纯由 AI 在其它仓库的会话中维护（改本仓 = 在任一系列仓会话里跨目录改 `~/project/fullstack-param-protocol/`）。因此本 CLAUDE.md 面向「跨仓顺手维护本仓」的会话，浓缩本仓独有不变量。

系列元信息（系列目的 / 总体设计思路 / 当前状态 / 姊妹底座位置 / copier 位置）由下方共享文件导入，只需维护一份：

@../ai-foundation-memory/series-overview.md

## 角色与分发（本仓是"源头"，不是"运行时"）

- **本仓产三件分发物**，底座接入时复制过去、与协议仓保持同源：
  - `gen-params.py` → 底座 `bin/gen-params.py`（vendor，CI 用 `GEN_PARAMS_VERSION` sha256 指纹自检与协议仓同源）；
  - `hooks/pre-commit` → 底座 `.githooks/pre-commit`（best-effort regen，不拦截提交）；
  - `workflows/params-check.yml` → 底座 `.github/workflows/params-check.yml`（verify 硬门槛 + notify-drift 信号）。
- **改动协议/模板 = 同步所有已接入底座**：改完 `gen-params.py`/`hooks/`/`workflows/` 后，各底座需重新复制（并更新 `GEN_PARAMS_VERSION`）。接入操作见 fullstack-bridge `docs/base-onboarding.md`、纯单端底座见 bridge-mcp-server `docs/onboarding-single-template.md`。**别只改协议仓忘同步底座**——那是 drift 的源头。

## 关键不变量（开发时不得违背，来自 SCHEMA.md / 历轮评审）

- **params.json 分两区（schema_version=2）**：
  - `params` = copier 派生区，与 copier.yml 做 **hash 校验**（`source_copier_yml_hash`），regen 全量重算；
  - `selection` = **人工策展**选择事实区（`suited_for`/`tradeoffs`），**schema 校验、不参与 copier hash**，regen **轮转保留**原样写回，可缺省（v1 无 selection 合法，向后兼容）。
- **`selection` 字段集单一真源在本仓 SCHEMA.md**（S3 定案）——消费方各持引用并随本表同步：
  - fullstack-bridge `bridge/combos.py` `SELECTION_FIELDS`（merge 只并已知字段）；
  - bridge-mcp-server `bridge_mcp/protocol.py` `SELECTION_FIELDS`（未知字段显式告警）。
  - **新增字段 = 先改本表 + `schema_version` 升版，再同步上表两处**；底座侧 gen-params 仍容忍未知字段轮转保留。
- **copier 全链钉 `9.17.1`（精确版，不用范围）**：协议仓 venv / 底座钩子 `uv run --with copier==9.17.1` / 底座 CI `pip install copier==9.17.1` 三处一致——`generated_by` 含 copier patch 版本且参与 verify 全文本比对，任何环境漂版本都会让全文本比对误判。
- **gen-params.py 经 copier 内省**（`copier._template.Template.questions_data`），不解析 copier.yml——脆弱点隔离在底座钩子（生成时）；桥只消费已提交的稳定 JSON。
- **原生参数默认值须字面值、不写 jinja 表达式**（桥自发现依赖）；派生参数用 `when:false` 标 `derived:true`。
- **`hooks/pre-commit` 兜底逻辑**：copier 非钉版本时跳过（防静默改写 generated_by），不硬拦；硬门槛在底座 CI。

## 本仓维护姿势（开发/测试）

本仓是普通 uv 项目（`pyproject.toml`，`package=false`）：

```bash
cd ~/project/fullstack-param-protocol
uv sync --dev                # copier==9.17.1 + pytest
uv run pytest                # tests/test_gen_params.py（subprocess 驱动最小 copier 模板 fixture 内省）
```

- 改协议后自检：`uv run python gen-params.py --template-dir <最小模板目录> --output /tmp/params.json --verify`（validate 语义）。
- 触发底座接入同步：改 `gen-params.py` / `hooks/` / `workflows/` 后，逐底座走 fullstack-bridge `docs/base-onboarding.md` 复制步骤（含更新 `GEN_PARAMS_VERSION` 指纹）。

## 边界（本仓不做）

- 不持有任何底座模板体 / combos.yaml / 契约——只给协议与接入模板。
- 不做对齐执行（那是 fullstack-bridge check / 底座 CI 的活）；本仓是这些链路的**协议源**，不入生成 MCP、不入治理面 MCP。
- 单端/多端的协议消费差异：单端直读底座 params.json（零注册），多端经桥内省面——协议本体两者共用，本仓不区分。
