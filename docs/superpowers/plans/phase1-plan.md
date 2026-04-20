# Phase 1 实施计划（粗 plan）

> **目标**：搭建"AI 软件公司"的基础设施，跑通从"老板发需求"到"代码交付"的完整流水线。
>
> **方式**：A 模式——按模块逐个实施，老板在线跟着看，随时纠偏。
>
> **验收标志**：用一个 hello-world 级小项目走完全流程。

---

## 模块依赖关系

```
模块 1（Prompt 模板）──→ 模块 2（PM Agent）──→ 模块 5（端到端验证）
                    ──→ 模块 3（Dispatcher Agent）──→ 模块 5
模块 4（项目模板）──→ 模块 5
模块 6（监控）可与 2/3 并行，在 5 之前完成
模块 7（Dashboard）可最后做，不阻塞验证
```

简化顺序：**1 → 2 → 3 → 4 → 6 → 5 → 7**

---

## 模块 1：Agent Prompt 模板落盘

**做什么**：把 04-agent-prompts.md 中定义的 7 个角色 prompt 写成实际的模板文件，存到 `company/prompts/`。

**交付物**：
- `company/prompts/pm-agent.md`
- `company/prompts/dispatcher-agent.md`
- `company/prompts/architect-agent.md`
- `company/prompts/coder-agent.md`
- `company/prompts/reviewer-agent.md`
- `company/prompts/qa-agent.md`
- `company/prompts/doc-agent.md`

**验收**：每个模板文件包含完整的角色定义 + 行为规则 + 禁止行为 + 动态上下文占位符。

**预估**：30 分钟

---

## 模块 2：PM Agent 常驻服务

**做什么**：
- 创建 Hermes profile `pm-agent`
- 配置 Telegram gateway + 白名单（只允许老板对话）
- 注入 PM prompt 模板为 personality
- 配置 cron 任务：每天 09:00 触发每日简报
- 配置静默时段（23:00-08:00）逻辑
- 配置 alert 轮询机制（读 `company/pm-state/alerts.jsonl`）
- 以 launchd 服务启动常驻

**交付物**：
- `pm-agent` profile 创建完毕
- PM 能通过 Telegram 与老板对话
- PM 能生成每日简报
- PM 能读 alert 文件并推送

**验收**：老板在 Telegram 发一条消息，PM 正确回复；手动写一条 alert 文件，PM 读到后推送。

**依赖**：模块 1（需要 PM prompt 模板）

**预估**：1-2 小时

---

## 模块 3：Dispatcher Agent 常驻服务

**做什么**：
- 创建 Hermes profile `dispatcher-agent`
- 注入 Dispatcher prompt 模板为 personality
- 配置监控循环（每 5 分钟扫描子 agent 状态）
- 配置 docs/prd.md 的 `status: approved` 检测逻辑
- 配置 merge 队列管理逻辑
- 配置信号文件检测逻辑
- 以 launchd 服务启动常驻

**交付物**：
- `dispatcher-agent` profile 创建完毕
- Dispatcher 能检测 PRD 状态变化并触发任务拆解
- Dispatcher 能 spawn 子 agent（delegate_task / hermes chat -q）
- Dispatcher 能写 alert 文件

**验收**：手动创建一个 `docs/prd.md`（status: approved），Dispatcher 检测到后自动拆出 GitHub Issues。

**依赖**：模块 1（需要 Dispatcher prompt 模板）

**预估**：2-3 小时

---

## 模块 4：项目仓库模板

**做什么**：创建一个项目仓库模板（GitHub template repo 或本地脚手架脚本），新建项目时一键初始化标准目录结构。

**交付物**：
- `company/templates/project-scaffold/` 目录，包含：
  - `docs/prd.md`（空模板，含 status 字段）
  - `docs/architecture.md`（空模板）
  - `docs/contracts/`（空目录 + .gitkeep）
  - `docs/tasks/tasks.md`（空看板模板）
  - `docs/decisions/`（空目录 + .gitkeep）
  - `docs/reviews/`（空目录 + .gitkeep）
  - `docs/qa/`（空目录 + .gitkeep）
  - `src/`（空目录 + .gitkeep）
  - `tests/unit/`、`tests/integration/`、`tests/e2e/`（空目录）
  - `STATUS.md`（空模板）
  - `README.md`（空模板）
  - `.gitignore`（通用模板）
- `company/scripts/new-project.sh`：一键创建 GitHub 私仓 + clone + 初始化目录 + 首次 commit

**验收**：跑 `new-project.sh mall` → GitHub 上出现 `hermes-proj-mall` 私仓，本地 `projects/mall/` 有完整目录结构。

**依赖**：无

**预估**：30 分钟

---

## 模块 5：端到端验证（hello-world 项目）

**做什么**：用一个最小项目走完全流程，验证 PM → Dispatcher → Architect → Coder → Reviewer → QA → Doc 的完整链路。

**项目选择**：一个极简 Web API（比如"待办事项 TODO API"，3 个 endpoint：列表/新增/删除），不做前端，纯后端 + 测试。

**流程**：
1. 老板在 Telegram 发需求："做一个 TODO API"
2. PM 澄清需求 → 写 PRD → 推老板确认
3. 老板批准 → PM 创建项目仓库（用模块 4 的脚本）
4. Dispatcher 检测到 → spawn Architect → 出架构 + 契约
5. PM 推架构给老板 → 老板拍板
6. Dispatcher 拆任务 → spawn Coder → 写代码 + 测试 → 提 PR
7. Dispatcher spawn Reviewer → 审 PR → merge
8. Dispatcher 跑集成测试
9. Dispatcher spawn QA → E2E 验收
10. Dispatcher spawn Doc → 写文档
11. PM 推里程碑报告 → 老板签字

**验收**：TODO API 能跑、测试全绿、文档完整、全流程在 Telegram 有完整汇报记录。

**依赖**：模块 1/2/3/4/6 全部完成

**预估**：3-5 小时（取决于 agent 表现）

---

## 模块 6：监控循环

**做什么**：
- 实现 Dispatcher 的监控扫描逻辑（每 5 分钟 cron）
- 实现三层防御的阈值检测
- 实现 alert 写入机制
- 实现硬熔断的 process kill 逻辑
- 日志写入 `company/logs/agent-YYYY-MM-DD.jsonl`

**交付物**：
- `company/monitor/monitor.py`（或嵌入 Dispatcher prompt 的行为规则）
- `company/monitor/config.yaml`（阈值配置）
- 日志文件格式定义

**验收**：手动模拟一个"死循环 agent"（故意写一个会卡住的任务），监控检测到并写 alert，PM 推送到 Telegram。

**依赖**：模块 2 + 3（需要 PM 和 Dispatcher 都在跑）

**预估**：1-2 小时

---

## 模块 7：Dashboard 聚合页

**做什么**：
- 写一个 Python 脚本，读取所有 `projects/*/STATUS.md` + GitHub API 数据
- 用 Jinja2 渲染成静态 HTML
- cron 每 10 分钟跑一次
- 响应式布局，手机能看

**交付物**：
- `company/dashboard/generate.py`
- `company/dashboard/templates/index.html`
- `company/dashboard/output/index.html`（生成的静态页）
- cron 配置

**验收**：本地浏览器打开 `output/index.html` 能看到项目状态汇总。VPS 部署留到后续。

**依赖**：模块 5（需要至少一个项目有 STATUS.md 数据）

**预估**：1-2 小时

---

## 总览

| 模块 | 内容 | 依赖 | 预估 |
|------|------|------|------|
| 1 | Prompt 模板落盘 | 无 | 30 分钟 |
| 2 | PM Agent 常驻 | 模块 1 | 1-2 小时 |
| 3 | Dispatcher Agent 常驻 | 模块 1 | 2-3 小时 |
| 4 | 项目仓库模板 | 无 | 30 分钟 |
| 5 | 端到端验证 | 1/2/3/4/6 | 3-5 小时 |
| 6 | 监控循环 | 模块 2+3 | 1-2 小时 |
| 7 | Dashboard 聚合页 | 模块 5 | 1-2 小时 |

**总预估**：9-15 小时（可分多天完成）

**实施顺序**：1 → 4（可并行）→ 2 → 3 → 6 → 5 → 7
