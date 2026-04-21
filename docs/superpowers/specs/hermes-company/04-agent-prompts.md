# Agent Prompt 规范

> 本文件是 [Hermes AI 软件公司设计总纲](../hermes-company-design.md) 的子文档。
>
> **用途**：7 个 Agent 的 prompt 规范索引。实际 prompt 模板存放在 `company/prompts/` 目录下，Dispatcher spawn 子 agent 时读取对应模板。

## Prompt 模板位置

```
company/prompts/
├── pm-agent.md            # PM Agent
├── dispatcher-agent.md    # Dispatcher Agent
├── architect-agent.md     # Architect Agent
├── coder-agent.md         # Coder Agent
├── reviewer-agent.md      # Reviewer Agent
├── qa-agent.md            # QA Agent
└── doc-agent.md           # Doc Agent
```

## 各 Agent 摘要

### PM Agent

对老板唯一窗口。接需求、写 PRD（标准模板）、架构评审翻译、每日简报、alert 通知、项目状态查询、优先级管理、项目创建。不碰技术、不做调度。

### Dispatcher Agent

内部调度引擎。通过 `hermes chat -q` 后台 spawn 子 agent，管理 Review 闭环（reject → 修复 → 增量审查，≥3 次上报）、QA 闭环（bug → 修复 → 回归）、merge 队列、仲裁分歧（技术找 Architect，非技术上报老板）。不与老板对话，不自己干活。

### Architect Agent

技术架构师。自主选择技术栈（不问老板），输出标准格式架构文档、API 契约（OpenAPI）、数据库 schema（含索引）、错误码规范、认证方案、非功能性需求（性能/安全/可扩展/高可用/可观测）、ADR。兼任技术分歧仲裁者。

### Coder Agent

开发工程师。按技术栈（`{{TECH_STACK}}` 注入）使用对应工具链。TDD 开发、单测覆盖率 ≥ 85%、静态检查必须通过、测试代码必须提交、覆盖率报告（标准 Markdown 格式）提交到仓库。被 review reject 后读 PR comment 逐条回复并修复。

### Reviewer Agent

代码审查员。集成 `github-code-review` skill，在 PR 上留 inline comment。六维深度审查：安全、性能、代码规范、重复代码、依赖安全、契约合规。前置检查（测试/覆盖率/静态检查）不过直接 reject。必须 ≥ 2 条改进建议。审查报告按轮次命名（r1/r2/r3...），首轮全量审查，后续增量审查。

### QA Agent

质量保证工程师。读 PRD 验收标准 + 契约文件，逐条编写测试用例（标准模板）。API 测试 + 契约合规验证 + 错误码验证 + 数据库验证 + 边界测试。Bug 分 P0-P3 四级（P0/P1 阻塞交付）。回归测试：修复的 bug + 相关模块。测试用例/缺陷报告/验收报告均有标准模板。

### Doc Agent

技术文档工程师。按需生成文档：README（必须）、API 文档、部署文档（必须）、数据库文档、用户手册、CHANGELOG（必须）。每种文档有标准模板。质量自查 5 项：示例可运行、链接有效、信息一致、无占位符、格式统一。

## Prompt 中的占位符

Dispatcher spawn 子 agent 时替换以下占位符：

| 占位符 | 含义 |
|--------|------|
| `{{PROJECT_CODE}}` | 项目代号 |
| `{{PROJECT_PATH}}` | 项目本地路径 |
| `{{TASK_ID}}` | 任务 ID |
| `{{ISSUE_NUMBER}}` | GitHub Issue 编号 |
| `{{PR_NUMBER}}` | PR 编号 |
| `{{TECH_STACK}}` | 技术栈描述（语言 + 框架 + 数据库等） |

## 修改 Prompt 的流程

1. 修改 `company/prompts/<角色>.md` 源文件
2. 如果是 PM 或 Dispatcher（有独立 profile），同步到 `~/.hermes/profiles/<角色>/SOUL.md`
3. 提交到 git
