# 组织编制

> 本文件是 [Hermes AI 软件公司设计总纲](../2026-04-19-hermes-company-design.md) 的子文档。


七角色 + Designer 能力 skill 化 + DevOps 老板自做。

| 角色 | 职责 | 模型 |
|------|------|------|
| PM Agent | 对老板唯一窗口：接需求、写 PRD、汇报、简报、回答查询、维护 STATUS.md 摘要 | claude-opus-4.6-1m |
| Dispatcher Agent | 内部调度引擎：拆任务、spawn 子 agent、管 merge 队列、跑监控循环、更新看板/dashboard、异常写 alert | claude-opus-4.6-1m |
| Architect Agent | 技术方案、DB schema、API 契约、目录结构、ADR | claude-opus-4.6-1m |
| Coder Agent（可多实例并行）| 按模块实现代码，严格遵守契约 | claude-opus-4.6-1m |
| Reviewer Agent | 代码审查、跑测试、提 issue（不是橡皮图章） | claude-opus-4.6-1m |
| QA Agent | 端到端验收、模拟用户操作、缺陷报告 | claude-opus-4.6-1m |
| Doc Agent | README、API 文档、用户手册 | claude-opus-4.6-1m |

**PM 与 Dispatcher 的分工边界**：

| 事项 | PM | Dispatcher |
|------|-----|-----------|
| 接老板需求 | ✅ | |
| 写 PRD | ✅ | |
| 汇报/简报/异常通知推 Telegram | ✅ | |
| 回答老板查询 | ✅ | |
| 拆任务为 GitHub Issues | | ✅ |
| spawn 子 agent（Architect/Coder/Reviewer/QA/Doc） | | ✅ |
| 管 PR merge 队列（锁/rebase/merge/通知） | | ✅ |
| 跑监控循环（5 分钟扫描） | | ✅ |
| 更新看板/dashboard 数据 | | ✅ |
| 发现异常写 alert 文件 | | ✅ |
| 读 alert 推老板 | ✅ | |
| 维护 STATUS.md | ✅（摘要） | ✅（原始数据） |

**PM ↔ Dispatcher 通信机制**（纯文件，不直接对话）：
- PM 写 `00-prd.md` 标记 `status: approved` → Dispatcher 检测到后开始调度
- Dispatcher 写 `company/pm-state/alerts.jsonl` → PM 轮询读到后推 Telegram
- Dispatcher 更新 `03-tasks/tasks.md` → PM 从中生成 STATUS.md 摘要

**Designer 不设 agent**，能力拆为两层：
- 决策层：PM Agent 在 PRD 阶段调用 `popular-web-designs` skill，从 54 套真实产品设计系统挑一套作为基调，把配色 token、字体、圆角、间距规范写进 PRD 的"设计规范"章节。
- 执行层：Coder Agent 收到 PRD 后，直接套对应组件库（小程序：Vant Weapp / TDesign / NutUI；Web：参考 popular-web-designs 提供的实现），按规范配 theme，禁止自由发挥。

---
