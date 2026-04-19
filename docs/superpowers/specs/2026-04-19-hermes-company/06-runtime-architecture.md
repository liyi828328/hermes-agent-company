# 运行时架构

> 本文件是 [Hermes AI 软件公司设计总纲](../2026-04-19-hermes-company-design.md) 的子文档。

## 8. 运行时架构

### 8.1 PM Agent — 常驻

- 实现：独立的 Hermes profile（`hermes profile create pm-agent`）
- 启动方式：作为 systemd / launchd 服务常驻，挂在 Telegram gateway
- 唯一对话方：老板（白名单限制）
- 职责：接需求、写 PRD、汇报、简报、回答查询、读 alert 推 Telegram
- 上下文轻量：不做调度/监控，session 短，响应快

### 8.2 Dispatcher Agent — 常驻

- 实现：独立的 Hermes profile（`hermes profile create dispatcher-agent`）
- 启动方式：作为 systemd / launchd 服务常驻，后台运行
- 不对人说话，纯自动化引擎
- 职责：读 PRD → 拆任务 → spawn 子 agent → 管 merge 队列 → 跑监控循环 → 更新看板/dashboard → 异常写 alert
- 与 PM 通过档案文件通信（`company/pm-state/alerts.jsonl`、`03-tasks/tasks.md`、`STATUS.md`）
- 故障隔离：Dispatcher 挂了不影响老板与 PM 通信；PM 挂了 Dispatcher 继续调度

### 8.3 干活 Agent — 按需 spawn

- Architect / Coder / Reviewer / QA / Doc 全部按需启动，干完即退
- 启动方式：Dispatcher 通过 `delegate_task` 或 `hermes chat -q` spawn 子进程
- 多个 Coder 可并行（用 `hermes -w` worktree 模式避免 git 冲突）
- 子 agent 不直接对话老板，产出回流到 Dispatcher

### 8.4 项目并行度

- 起步上限：同时 2-3 个项目
- PM 在第 4 个项目请求时会主动建议老板做优先级排序
- 资源约束：受 VPS 算力和 API 速率限制，并非硬限制

### 8.5 模型分配

- 全员统一使用 `claude-opus-4.6-1m`
- 取舍：智商优先、上下文充裕、运维简单；代价是 token 成本高
- 缓解措施：每次调用记录 token 用量到 STATUS.md 和 dashboard，便于老板观察后续优化

---
