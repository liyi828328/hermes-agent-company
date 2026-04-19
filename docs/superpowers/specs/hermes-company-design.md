# Hermes AI 软件公司 — 系统设计总纲

- 日期：2026-04-19
- 老板（唯一对接人）：liyi
- 工作空间根目录：`/Users/liyi/work/AI/Hermes/workspace`
- 状态：设计已确认，待进入 writing-plans 阶段

---

## 1. 业务定位

混合模式 D：先用自有产品孵化把多 Agent 流水线跑通，再过渡到对外接单。

- 第一阶段（当前）：老板出想法，Hermes 实现自有项目（小程序、电商系统等技术开发方向），不一定商业化，目的是验证流水线。
- 第二阶段（未来）：流水线稳定后再对外承接客户项目。本 spec 仅覆盖第一阶段，但架构需为第二阶段留扩展点（多收件人、客户隔离、计费等）。

---

## 2. 基础设施现状

老板已具备：服务器/VPS、域名、GitHub 私仓、Hermes CLI + Telegram gateway。

按需补办：微信小程序账号、苹果/Google 开发者账号、云服务、对象存储、数据库、设计资源、支付通道。

DevOps 由老板亲自承担（不设 DevOps Agent）。

---

## 3. 工作流模式

采用 C 模式：多 Agent 公司式协作。

- PM agent 接需求 → Dispatcher 调度 → Architect agent 出技术方案 → 多个 Coder agent 并行实现 → Reviewer agent 审 → QA agent 验收 → Doc agent 出文档 → 老板签字。
- 取舍已知：token 消耗是 A 模式的 5-10 倍，需强制契约文件防 agent 失同步，需要专门设计防 Reviewer 橡皮图章，介入点设计是关键。

---

## 4. 组织架构总览

七角色 + Designer 能力 skill 化 + DevOps 老板自做。

```
              老板（liyi）
                   ↑
                   │ Telegram（唯一对接）
                   │
              PM Agent（常驻）
                   ↑ alerts 文件
                   │
            Dispatcher Agent（常驻）
              ／   │   ＼
             ↓     ↓     ↓        spawn + 管理
        Architect Coder Reviewer
                         ↓
                         QA
                         ↓
                        Doc
```

核心规则：
- 只有 PM Agent 跟老板对话
- 只有 Dispatcher Agent 调度子 agent
- PM ↔ Dispatcher 通过档案文件通信，不直接对话

---

## 5. 关键流程图

### 5.1 新项目从需求到首个里程碑

```
老板（Telegram）→ "做个 X 小程序"
     ↓
PM Agent 提问澄清 → 写 PRD 草稿 → 推老板
     ↓ （介入点 1：需求确认）
老板批准
     ↓
PM 创建 GitHub 私仓 + 本地档案目录 → Dispatcher 检测到后创建 Project board
     ↓
Dispatcher spawn Architect Agent → 出 01-architecture.md + 02-contracts/
     ↓ （介入点 2：架构评审）
老板拍板
     ↓
Dispatcher 拆 03-tasks/ 为 GitHub Issues
     ↓
Dispatcher 并行 spawn 多个 Coder Agent（每人一个 issue）→ 提 PR
     ↓
Dispatcher spawn Reviewer Agent → review PR → 通过则 merge
     ↓
全部模块完成 → Dispatcher spawn QA Agent → 端到端验收
     ↓
QA 通过 → Dispatcher spawn Doc Agent → 写文档
     ↓ （介入点 3：里程碑交付）
PM 推送演示链接 → 老板签字
```

### 5.2 异常处理流程

```
任何 agent 异常 / 监控告警
     ↓
第一层（被动）：写 log + 更新 dashboard
     ↓ 命中第二层阈值
第二层（通知）：PM 推 Telegram → 老板决策
     ↓ 命中第三层阈值（或第二层超时）
第三层（熔断）：Dispatcher 强杀 agent + 暂存现场 + 通知老板
     ↓
老板决策：恢复 / 改方案 / 放弃
```

---

## 6. 工作空间布局

```
/Users/liyi/work/AI/Hermes/workspace/
├── docs/superpowers/specs/                    # 设计文档
│   ├── hermes-company-design.md    # 本文件（总纲）
│   └── hermes-company/             # 子文档目录
├── projects/                                   # 每个项目 = 独立 GitHub 私仓 clone
│   └── <项目代号>/                             # 档案(docs/) + 代码(src/) 混合
├── company/                                    # 公司级元数据（workspace repo 管理）
│   ├── logs/                                   # agent 调用日志、熔断日志
│   ├── dashboard/                              # 聚合页生成器
│   ├── pm-state/                               # PM/Dispatcher 持久化状态
│   ├── monitor/                                # 监控循环脚本和配置
│   └── prompts/                                # agent prompt 模板
├── .gitignore                                  # 含 projects/（独立 repo 不归 workspace 管）
└── .git/                                       # workspace repo（管 docs/ + company/）
```

---

## 7. 子文档索引

| # | 子文档 | 内容摘要 |
|---|--------|---------|
| 1 | [组织编制](hermes-company/01-organization.md) | 七角色定义、PM/Dispatcher 分工边界与通信机制、Designer skill 化方案 |
| 2 | [汇报关系](hermes-company/02-reporting.md) | 4 个介入点、异常上报硬规则、每日简报、静默时段、回执超时、老板指令类型 |
| 3 | [项目档案制度](hermes-company/03-project-archive.md) | 档案结构、严格契约规则、GitHub 集成、PR 审核流水线（创建/调度/merge/契约变更分级/监控联动） |
| 4 | [Agent Prompt 规范](hermes-company/04-agent-prompts.md) | 7 个 agent 的 system prompt、预装 skill、工具白名单、行为规则、禁止行为 |
| 5 | [看板与 Dashboard](hermes-company/05-kanban-dashboard.md) | GitHub Projects v2 单项目看板 + VPS 聚合页跨项目总览 |
| 6 | [运行时架构](hermes-company/06-runtime-architecture.md) | PM 常驻、Dispatcher 常驻、干活 agent 按需 spawn、并行度、模型分配 |
| 7 | [监控机制](hermes-company/07-monitoring.md) | 三层防御：被动日志 → 异常通知 → 硬熔断，阈值定义与实现方式 |
| 8 | [风险、验收标准与路线图](hermes-company/08-risks-and-roadmap.md) | 第二阶段扩展点、已知风险缓解、验收标准、Phase 1 下一步 |
| 9 | [测试策略](hermes-company/09-testing-strategy.md) | 三层测试模型（单元/集成/E2E）、覆盖率 85% 门槛、merge 后集成测试自动 revert 机制 |
| 10 | [迭代与版本管理](hermes-company/10-iteration-versioning.md) | 变更分级（小改/中改/大改）、语义化版本、Tag 流程 |
| 11 | [QA 能力边界](hermes-company/11-qa-boundaries.md) | QA 能做的（API/Web/DB/逻辑）、做不了的（小程序/App/性能/安全）、兜底方案 |

---

## 变更日志

- 2026-04-19 初版（v1）：14 节，覆盖 11 个原始决策点
- 2026-04-19 v1.1 补充：增加 PR 审核流水线（5 小节）
- 2026-04-19 v1.2 修正：PR 流水线移至正确位置，统一标题层级
- 2026-04-19 v1.3 重构：新增 Dispatcher Agent 角色（七角色）
- 2026-04-19 v2.0 重构：总分结构拆分，总纲精简 + 8 个子文档
