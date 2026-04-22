# 运行时架构

> 本文件是 [Hermes AI 软件公司设计总纲](../hermes-company-design.md) 的子文档。
>
> **用途**：定义运行时架构——PM 和 Dispatcher 常驻服务、子 agent 按需 spawn、并行度、模型分配、spawn 方式选择标准、agent 间协调与信号文件机制。


## PM Agent — 常驻

- 实现：独立的 Hermes profile（`hermes profile create pm-agent`）
- 启动方式：作为 launchd（macOS）/ systemd（Linux）服务常驻，挂在飞书 gateway
- 安装命令：`pm-agent gateway install`（自动注册为系统服务，开机启动、挂了自动重启）
- 唯一对话方：老板（飞书用户授权）
- 职责：接需求、写 PRD、汇报、简报、回答查询、读 alert 推飞书
- 上下文轻量：不做调度/监控，session 短，响应快
- 飞书凭证：`FEISHU_APP_ID` + `FEISHU_APP_SECRET` 配置在 profile 的 `.env` 中
- 飞书订阅方式：长连接（WebSocket），无需公网回调地址

## Dispatcher Agent — 常驻

- 实现：独立的 Hermes profile（`hermes profile create dispatcher-agent`）
- 启动方式：**不常驻进程**，通过 Hermes 内置 cron 每 5 分钟触发扫描脚本
- cron job 挂在 PM Agent 的 gateway 下（PM gateway 已常驻）
- 扫描脚本：`company/scripts/dispatcher-poll.sh`
- 锁文件：`company/pm-state/dispatcher.lock`（防止重复触发）
- 不对人说话，纯自动化引擎
- 工作流程：
  1. cron 每 5 分钟触发扫描脚本
  2. 脚本检查锁文件——有锁则跳过
  3. 扫描 `projects/*/docs/prd.md` 和 `architecture.md` 的 status 变化
  4. 检查信号文件是否有未处理的状态变化
  5. 有变化 → 创建锁文件 → 启动 `dispatcher-agent --yolo chat -q "..."` 处理
  6. Dispatcher 完成后删除锁文件
  7. 没变化 → 静默退出
- 锁文件超时保护：锁文件超过 2 小时自动删除（防止残留锁）
- 与 PM 通过档案文件通信（`company/pm-state/alerts.jsonl`、`docs/tasks/tasks.md`、`STATUS.md`）
- 故障隔离：Dispatcher 挂了不影响老板与 PM 通信；PM 挂了 Dispatcher 继续调度

## 干活 Agent — 按需 spawn

- Architect / Coder / Reviewer / QA / Doc 全部按需启动，干完即退
- 启动方式：Dispatcher 通过 `hermes chat -q` spawn 子进程
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

## Spawn 方式

所有子 agent 统一通过 `hermes chat -q` 启动独立进程，不使用 `delegate_task`。

- 完全独立进程，无 turn 限制，产出通过档案文件传递
- 多个 Coder 用 `hermes chat -q` 时加 `-w`（worktree 模式）避免 git 冲突

## Agent 间协调机制

七个 agent 之间**不直接对话**，全部通过文件 + 进程信号协调。

### 协调链路总览

```
老板 ←→ PM：飞书消息
PM → Dispatcher：docs/prd.md 中 status: approved
Dispatcher → 子 agent：spawn 时 prompt 注入（项目代号、任务 ID、文件路径）
Dispatcher ← 子 agent：子 agent 写文件到项目 repo（代码/PR/测试报告/文档）
Dispatcher → PM：company/pm-state/alerts.jsonl（异常告警）
Dispatcher → PM：docs/tasks/tasks.md + STATUS.md（进度数据）
PM → 老板：读 alerts + STATUS.md → 推飞书
```

### 任务完成信号机制

子 agent 完成任务后，Dispatcher 需要知道"干完了"并检查产出：

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

## Review 闭环

Dispatcher 主导 Coder 和 Reviewer 之间的修复循环：

```
Coder 提 PR → Dispatcher spawn Reviewer（全量审查 r1）
  → approve → 进 merge 队列
  → reject → Dispatcher spawn Coder（读 PR comment + review 报告，逐条回复并修复）
      → Dispatcher spawn Reviewer（增量审查 r2，只查修复项 + 新改动）
      → 循环直到 approve
      → ≥ 3 次 reject → 异常上报
```

Review 报告按轮次命名：`docs/reviews/review-<task-id>-r1.md`、`r2.md`...

**分歧仲裁**：Coder 不同意 Reviewer 意见时，Dispatcher 判断分歧类型——技术问题 spawn Architect 仲裁（输出 ADR），非技术问题通过 PM 上报老板。

## QA 闭环

Dispatcher 主导 QA 验收不通过后的修复循环：

```
Dispatcher spawn QA → 验收
  → passed → 进 Doc 阶段
  → failed → QA 创建 bug issue（P0-P3）
      → Dispatcher 逐个 spawn Coder 修复
      → 每个修复走 Review 闭环（Coder → Reviewer → merge）
      → 全部修复后 spawn QA 回归验证（修复的 bug + 相关模块）
      → 循环直到 passed
      → 同一 bug ≥ 3 次修复失败 → 异常上报
```

验收阻塞规则：P0/P1 未修复 → 不通过。P2/P3 可带着交付但必须记录。
