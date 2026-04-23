# Hermes Company — 待办事项

更新时间：2026-04-23

## 🔴 关键

1. 监控机制 — 实现3层防御：被动日志、告警通知、熔断器（5M token/2hr/20次重复错误自动终止）
2. 子Agent卡死自动检测与恢复 — 超时后kill残留进程、重试机制

## 🟡 中等

3. PM SOUL.md 加文件优先规则 — 回答项目状态时必须先读STATUS.md，不依赖对话记忆
4. PM 仍不执行架构审批动作 — SOUL.md 写了但实际未照做，需要更具体的操作指令
5. Dashboard聚合页面（Python+Jinja2静态HTML）
6. 设计文档与实现不同步 — 回顾更新spec文档
7. Dispatcher重复spawn同一任务的Coder问题
8. init-profiles.sh 更新 — 飞书配置+cron创建
9. Agent输出模板合规 — Reviewer/QA/Architect/Doc报告缺少章节
10. QA闭环完成后Dispatcher没写qa-*.done信号文件
11. 架构文档在开发阶段后变更时，已完成的代码不会自动同步更新
12. QA没对照PRD逐条验收（前端缺失居然通过了）
13. Dispatcher任务拆解不完整（weather-app只拆了后端没拆前端）

## ⚪ 次要

14. dispatcher-run.sh 超时值偏短
15. README/DEPLOY模板合规
16. gh CLI 在 Dispatcher Agent 环境未登录（自动降级本地模式，PR/Issue功能受限）

## ✅ 已完成

- PM架构审批流程 — SOUL.md加了审批操作指令
- alerts cron job 文件为空时不再发"无新通知"
- cron频率 5分钟→1分钟
- dispatcher-run.sh 信号文件匹配加了 T*.done
- GitHub SSH Key + gh CLI认证配置
- PM + Dispatcher profiles恢复
- 飞书网关配置
