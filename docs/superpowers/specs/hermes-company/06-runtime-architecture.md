# 运行时架构

> 本文件是 [Hermes AI 软件公司设计总纲](../hermes-company-design.md) 的子文档。
>
> **用途**：定义运行时架构——PM 和 Dispatcher 常驻服务、子 agent 按需 spawn、并行度、模型分配、spawn 方式选择标准、agent 间协调与信号文件机制。


## PM Agent — 常驻

- 实现：独立的 Hermes profile（`hermes profile create pm-agent`）
- 启动方式：作为 systemd / launchd 服务常驻，挂在 Telegram gateway
- 唯一对话方：老板（白名单限制）
- 职责：接需求、写 PRD、汇报、简报、回答查询、读 alert 推 Telegram
- 上下文轻量：不做调度/监控，session 短，响应快

## Dispatcher Agent — 常驻

- 实现：独立的 Hermes profile（`hermes profile create dispatcher-agent`）
- 启动方式：作为 systemd / launchd 服务常驻，后台运行
- 不对人说话，纯自动化引擎
- 职责：读 PRD → 拆任务 → spawn 子 agent → 管 merge 队列 → 跑监控循环 → 更新看板/dashboard → 异常写 alert
- 与 PM 通过档案文件通信（`company/pm-state/alerts.jsonl`、`docs/tasks/tasks.md`、`STATUS.md`）
- 故障隔离：Dispatcher 挂了不影响老板与 PM 通信；PM 挂了 Dispatcher 继续调度

## 干活 Agent — 按需 spawn

- Architect / Coder / Reviewer / QA / Doc 全部按需启动，干完即退
- 启动方式：Dispatcher 通过 `delegate_task` 或 `hermes chat -q` spawn 子进程
- 多个 Coder 可并行（用 `hermes -w` worktree 模式避免 git 冲突）
- 子 agent 不直接对话老板，产出回流到 Dispatcher

## 项目并行度

- 起步上限：同时 2-3 个项目
- PM 在第 4 个项目请求时会主动建议老板做优先级排序
- 资源约束：受 VPS 算力和 API 速率限制，并非硬限制

## 模型分配

- 全员统一使用 `claude-opus-4.6-1m`
- 取舍：智商优先、上下文充裕、运维简单；代价是 token 成本高
- 缓解措施：每次调用记录 token 用量到 STATUS.md 和 dashboard，便于老板观察后续优化

---

## Spawn 方式选择标准

Dispatcher spawn 子 agent 时根据任务规模选择方式：

| 方式 | 适用场景 | 典型角色 |
|------|---------|---------|
| `delegate_task` | 短任务，预估 < 40 tool calls | Reviewer（审 PR）、Doc（写文档）、Architect（出方案） |
| `hermes chat -q` | 长任务，预估 ≥ 40 tool calls | Coder（写模块）、QA（E2E 测试） |

关键区别：
- `delegate_task`：50 tool calls 上限，不能再 delegate，结果直接回到 Dispatcher session
- `hermes chat -q`：完全独立进程，无 turn 限制，产出通过档案文件传递
- 多个 Coder 用 `hermes chat -q` 时加 `-w`（worktree 模式）避免 git 冲突
- 边界情况拿不准时，偏向用 `hermes chat -q`（宁可多开进程也不要任务跑到一半撞 50 call 上限）

## Agent 间协调机制

七个 agent 之间**不直接对话**，全部通过文件 + 进程信号协调。

### 协调链路总览

```
老板 ←→ PM：Telegram 消息
PM → Dispatcher：docs/prd.md 中 status: approved
Dispatcher → 子 agent：spawn 时 prompt 注入（项目代号、任务 ID、文件路径）
Dispatcher ← 子 agent：子 agent 写文件到项目 repo（代码/PR/测试报告/文档）
Dispatcher → PM：company/pm-state/alerts.jsonl（异常告警）
Dispatcher → PM：docs/tasks/tasks.md + STATUS.md（进度数据）
PM → 老板：读 alerts + STATUS.md → 推 Telegram
```

### 任务完成信号机制

子 agent 完成任务后，Dispatcher 需要知道"干完了"并检查产出。按 spawn 方式分两套机制：

**delegate_task 的任务（短任务）**：
- 结果自动回到 Dispatcher session，天然知道完成
- 不需要额外信号

**hermes chat -q 的任务（长任务）**：
- Dispatcher 用 `background=true` + `notify_on_complete=true` 启动子进程
- 子进程退出时 Dispatcher 自动收到通知
- Dispatcher 收到通知后检查信号文件：
  - `docs/tasks/<task-id>.done` → 任务成功，读取产出（PR 链接 / 测试报告路径 / 文档路径）
  - `docs/tasks/<task-id>.failed` → 任务失败，读取错误信息，决定重试或写 alert
- 如果子进程退出但没有信号文件 → 视为异常，写 alert

**信号文件格式**（JSON）：
```json
{
  "task_id": "coder-42-fix-login",
  "agent": "coder",
  "status": "done",
  "output": {
    "pr_url": "https://github.com/xxx/pull/42",
    "files_changed": 5,
    "test_passed": true,
    "coverage": "87%"
  },
  "token_usage": 125000,
  "duration_seconds": 340,
  "timestamp": "2026-04-20T14:30:00Z"
}
```

**子 agent 的职责**：每个子 agent 在 prompt 中被要求，任务结束前必须写信号文件到 `docs/tasks/<task-id>.done` 或 `.failed`。这是强制行为规则，写进各 agent 的 prompt 模板中。
