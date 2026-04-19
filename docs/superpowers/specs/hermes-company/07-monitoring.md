# 监控机制（三层防御）

> 本文件是 [Hermes AI 软件公司设计总纲](../hermes-company-design.md) 的子文档。
>
> **用途**：定义三层监控防御机制——被动日志、异常通知（Telegram）、硬熔断（自动停），防止任何 agent 陷入死循环而老板无感知。


设计目标：可以烧 token，绝不能让任何 agent 陷入死循环或失控而老板无感知。

## 第一层 — 被动监控

- 每个 agent 调用都记 log：时间戳 / 项目代号 / agent 角色 / 任务 ID / token 用量 / 耗时 / 工具调用次数 / 退出状态
- 日志位置：`workspace/company/logs/agent-YYYY-MM-DD.jsonl`
- 聚合到项目 STATUS.md 和 dashboard
- 不打扰老板

## 第二层 — 异常通知（PM 主动 Telegram）

Dispatcher 跑监控循环（cron 每 5 分钟），扫描所有在跑子 agent，触发任一条件即写 alert → PM 读到后推送：

| 条件 | 信号含义 |
|------|---------|
| 单 agent 连续工具调用 > 30 次仍无产出 | 典型死循环 |
| 单 agent 重复调用同一工具 + 同一参数 ≥ 3 次 | 卡在同一错误 |
| 单任务运行 > 30 分钟 | 异常缓慢 |
| 单任务 token 消耗 > 1M | 异常巨大 |
| 任何 agent 报错后又重试 ≥ 5 次 | 修不动还在硬刚 |

通知格式示例：
```
⚠️ [proj-mall] Coder Agent 卡住
  连续 7 次调用 patch 工具修同一文件失败
  已用 1.2M tokens，运行 18 分钟
  操作：继续 / 停止 / 我接管
```

超时 30 分钟无回复 → 默认"停止该 agent"。

## 第三层 — 硬熔断（自动停 + 通知）

触发任一条件，Dispatcher 自动 `process kill` 失控 agent，暂存现场快照，写 alert → PM 推送老板：

- 单 agent token 超 5M
- 单任务运行 > 2 小时
- 同一错误重复 ≥ 20 次

熔断后老板可选：恢复（清理状态后重启）/ 改方案（修改 PRD 或 ADR 后重启）/ 放弃任务。

## 监控实现

- Dispatcher 内置 monitor 循环（独立 cron job），调用 Hermes 的 session log API 检查所有活跃子 agent
- 命中阈值 → 写入 `company/pm-state/alerts.jsonl`，PM 轮询读到后通过 `send_message` 推 Telegram
- 命中熔断 → Dispatcher 通过 `process kill` 终止 + 写入 `workspace/company/logs/circuit-breaker.jsonl` + 写 alert

---
