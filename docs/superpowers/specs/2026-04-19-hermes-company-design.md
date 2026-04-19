# Hermes AI 软件公司 — 系统设计文档

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

老板已具备：
1. 服务器 / VPS（部署 demo、跑监控/看板）
2. 域名
3. 代码托管（GitHub 私仓）
4. Hermes 配置（CLI + Telegram gateway 已就绪）

按需补办（PM 会在异常上报点提醒）：
- 微信小程序 / 公众号 / 商户号
- 苹果 / Google Play 开发者账号
- 云服务账号、对象存储、数据库
- 设计资源订阅
- 支付通道

DevOps 由老板亲自承担（不设 DevOps Agent）。

---

## 3. 工作流模式

采用 C 模式：多 Agent 公司式协作。

- PM agent 接需求 → Architect agent 出技术方案 → 多个 Coder agent 并行实现 → Reviewer agent 审 → QA agent 验收 → Doc agent 出文档 → 老板签字。
- 取舍已知：token 消耗是 A 模式的 5-10 倍，需强制契约文件防 agent 失同步，需要专门设计防 Reviewer 橡皮图章，介入点设计是关键。

---

## 4. 组织编制

六角色 + Designer 能力 skill 化 + DevOps 老板自做。

| 角色 | 职责 | 模型 |
|------|------|------|
| PM Agent | 接老板需求、写 PRD、维护任务看板、对外唯一汇报口、监控调度 | claude-opus-4.6-1m |
| Architect Agent | 技术方案、DB schema、API 契约、目录结构、ADR | claude-opus-4.6-1m |
| Coder Agent（可多实例并行）| 按模块实现代码，严格遵守契约 | claude-opus-4.6-1m |
| Reviewer Agent | 代码审查、跑测试、提 issue（不是橡皮图章） | claude-opus-4.6-1m |
| QA Agent | 端到端验收、模拟用户操作、缺陷报告 | claude-opus-4.6-1m |
| Doc Agent | README、API 文档、用户手册 | claude-opus-4.6-1m |

**Designer 不设 agent**，能力拆为两层：
- 决策层：PM Agent 在 PRD 阶段调用 `popular-web-designs` skill，从 54 套真实产品设计系统挑一套作为基调，把配色 token、字体、圆角、间距规范写进 PRD 的"设计规范"章节。
- 执行层：Coder Agent 收到 PRD 后，直接套对应组件库（小程序：Vant Weapp / TDesign / NutUI；Web：参考 popular-web-designs 提供的实现），按规范配 theme，禁止自由发挥。

---

## 5. 汇报关系

```
                老板（liyi）
                     ↑
                     │ 唯一对接人 · Telegram
                     │
                PM Agent ←─────────────┐
                （常驻）                │
                ／  │  ＼              │ 异常上报
               ↓    ↓    ↓             │（卡住/冲突/超范围/外部资源）
          Architect Coder Reviewer ────┤
                          ↓            │
                          QA ──────────┤
                          ↓            │
                          Doc ─────────┘
```

**核心规则**：只有 PM Agent 跟老板对话，其他 5 个 agent 的产出全部回流到 PM。


### 5.1 主动汇报（PM 找老板的 4 个介入点）

| # | 介入点 | 触发时机 | PM 推送内容 | 老板动作 |
|---|--------|---------|-------------|---------|
| 1 | 需求确认 | 老板提出新需求后 | PRD 草稿 + 验收标准 + 范围边界 | 批准 / 驳回 / 修改 |
| 2 | 架构评审 | Architect 出方案后 | 技术栈、关键决策、取舍说明（人话版） | 拍板 |
| 3 | 里程碑交付 | 模块完成 + QA 通过 | "X 功能可演示，链接 xxx，已知问题 yyy" | 签字 / 打回 |
| 4 | 异常上报 | 见 5.2 硬规则 | 问题描述 + 候选方案 | 决策 |

### 5.2 异常上报硬规则（PM 必须立刻找老板，不许"先试试"）

- 需要花钱（开通付费服务、买域名、API 充值）
- 需要老板的账号密码 / 密钥
- 改动超出原 PRD 范围
- 任何 agent 连续失败 3 次
- 触发监控机制告警（见第 9 节）

### 5.3 老板不会收到的噪音

- Coder 写代码进度
- Reviewer 提的小 issue（PM 内部消化）
- Doc 写文档过程
- Agent 之间的契约协商
- 日常 token 消耗（除非触发监控阈值）

### 5.4 每日定时简报

- 时间：每天 09:00
- 内容：昨日完成任务 / 今日计划 / 各项目当前阶段 / 累计 token 消耗 / 待处理事项清单
- 实现：cron 触发 PM Agent 生成简报，推 Telegram

### 5.5 静默时段

- 默认静默：23:00 - 08:00
- 静默期内：仅第三层硬熔断立刻推送；其他通知（异常告警、介入点请求）攒到 08:00 一起推送
- 例外开关：老板可发 `/urgent on` 临时关闭静默，`/urgent off` 恢复

### 5.6 汇报回执 / 超时默认行为

| 消息类型 | 等待时长 | 超时默认行为 |
|---------|---------|-------------|
| 介入点（PRD / 架构 / 里程碑） | 无限期 | 必须等老板回复，项目阻塞等待 |
| 异常通知（第二层告警） | 30 分钟 | 默认"停止该 agent"，等老板决定 |
| 硬熔断（第三层） | — | 已自动停，纯通知 |
| 每日简报 | — | 不需回复 |

### 5.7 老板对 PM 的指令类型

- 新需求：自然语言描述，PM 走 PRD 流程
- 回应介入点：批准 / 驳回 / 修改建议
- 回应异常：继续 / 停止 / 我接管 / 调整方案
- 主动查询："X 项目什么状态" → PM 从 STATUS.md 摘要
- 优先级调整："暂停 X 项目"、"优先做 Y"

---

## 6. 唯一真相源（项目档案制度）

每个项目一个 GitHub 私仓，本地工作副本位于 `~/work/AI/Hermes/workspace/projects/<项目代号>/`。

### 6.1 档案结构

```
projects/<项目代号>/
├── 00-prd.md              # PM 维护：需求、验收标准、范围边界、设计规范
├── 01-architecture.md     # Architect 维护：技术栈、模块划分、部署方案
├── 02-contracts/          # Architect 维护：API spec、DB schema、消息格式
│   ├── api.yaml           # OpenAPI 契约
│   ├── schema.sql         # 数据库 schema
│   └── events.md          # 异步事件定义
├── 03-tasks/              # PM 维护：任务拆分 + 状态
│   └── tasks.md           # 看板：todo / doing / review / done
├── 04-decisions/          # 所有人追加：架构决策记录（ADR）
│   └── ADR-001-xxx.md
├── 05-reviews/            # Reviewer 输出：每次 review 的发现
├── 06-qa/                 # QA 输出：测试用例 + 缺陷报告
├── 07-docs/               # Doc Agent 维护：README、用户手册、API 文档
├── code/                  # 实际代码（git 仓库子目录或单独仓库）
└── STATUS.md              # PM 每工作周期更新：当前进度、阻塞、下一步
```

### 6.2 严格契约规则

- 任何 agent 开工第一件事：读 `00-prd.md` + `01-architecture.md` + `02-contracts/`
- Coder 改代码必须先看 `02-contracts/`，发现契约不够用 → **不许擅自扩展**，必须通过 PM 找 Architect 改契约 → Architect 修改 → PM 通知所有相关 Coder
- Coder 越界（修改了未声明的契约）→ Reviewer 直接 reject，不进 review
- 所有跨 agent 决策走 ADR：一页纸，记录背景 / 候选方案 / 决定 / 影响，**追加不删除**
- `STATUS.md` 是 PM 给老板看的窗口，每工作周期（或每个介入点前）更新

### 6.3 GitHub 集成

- 每个项目对应一个私仓
- 任务 = GitHub Issue
- Coder 提交 = Pull Request
- Reviewer 通过 PR review 留 comment
- PM 通过 `gh` CLI 操作 issue / PR / project board

---

## 7. 看板系统

GitHub Projects（单项目细节） + VPS 聚合页（跨项目总览）。

### 7.1 单项目层 — GitHub Projects v2

- 每个项目一个 Project board
- Issue = 任务，按 Status 字段自动分列：Backlog / Todo / In Progress / Review / Done / Blocked
- PM 通过 `gh` CLI 创建 issue、移动状态、加标签（agent:coder、priority:high、blocker 等）
- 老板可在浏览器或 GitHub 移动 App 上查看细节，留 comment 即与 PM 沟通

### 7.2 公司层 — VPS 聚合页

- 部署在老板的 VPS，通过域名访问（建议子域名如 `dashboard.<your-domain>`）
- 后端：定时脚本（cron，每 10 分钟跑一次），读取所有 `projects/*/STATUS.md` + GitHub API，渲染为静态 HTML
- 字段：项目代号 / 当前阶段 / 阻塞点 / 最后更新时间 / 累计 token 消耗 / 跳转 GitHub 链接
- 移动端友好（响应式），便于老板手机随时扫一眼
- 实现栈建议：Python 脚本 + Jinja2 模板 + Nginx 静态服务（最小依赖）

---

## 8. 运行时架构

### 8.1 PM Agent — 常驻

- 实现：独立的 Hermes profile（`hermes profile create pm-agent`）
- 启动方式：作为 systemd / launchd 服务常驻，挂在 Telegram gateway
- 唯一对话方：老板（白名单限制）
- 职责：接需求、写 PRD、维护项目状态、调度子 agent、执行监控循环、向老板汇报

### 8.2 干活 Agent — 按需 spawn

- Architect / Coder / Reviewer / QA / Doc 全部按需启动，干完即退
- 启动方式：PM 通过 `delegate_task` 或 `hermes chat -q` spawn 子进程
- 多个 Coder 可并行（用 `hermes -w` worktree 模式避免 git 冲突）
- 子 agent 不直接对话老板，产出回流到 PM

### 8.3 项目并行度

- 起步上限：同时 2-3 个项目
- PM 在第 4 个项目请求时会主动建议老板做优先级排序
- 资源约束：受 VPS 算力和 API 速率限制，并非硬限制

### 8.4 模型分配

- 全员统一使用 `claude-opus-4.6-1m`
- 取舍：智商优先、上下文充裕、运维简单；代价是 token 成本高
- 缓解措施：每次调用记录 token 用量到 STATUS.md 和 dashboard，便于老板观察后续优化

---

## 9. 监控机制（三层防御）

设计目标：可以烧 token，绝不能让任何 agent 陷入死循环或失控而老板无感知。

### 9.1 第一层 — 被动监控

- 每个 agent 调用都记 log：时间戳 / 项目代号 / agent 角色 / 任务 ID / token 用量 / 耗时 / 工具调用次数 / 退出状态
- 日志位置：`workspace/company/logs/agent-YYYY-MM-DD.jsonl`
- 聚合到项目 STATUS.md 和 dashboard
- 不打扰老板

### 9.2 第二层 — 异常通知（PM 主动 Telegram）

PM 跑监控循环（cron 每 5 分钟），扫描所有在跑子 agent，触发任一条件即推送：

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

### 9.3 第三层 — 硬熔断（自动停 + 通知）

触发任一条件，PM 自动 `process kill` 失控 agent，暂存现场快照，通知老板：

- 单 agent token 超 5M
- 单任务运行 > 2 小时
- 同一错误重复 ≥ 20 次

熔断后老板可选：恢复（清理状态后重启）/ 改方案（修改 PRD 或 ADR 后重启）/ 放弃任务。

### 9.4 监控实现

- PM 内置一个 monitor 循环（独立 cron job），调用 Hermes 的 session log API 检查所有活跃子 agent
- 命中阈值 → 通过 `send_message` 推 Telegram
- 命中熔断 → 通过 `process kill` 终止 + 写入 `workspace/company/logs/circuit-breaker.jsonl`

---

## 10. 工作空间布局

```
/Users/liyi/work/AI/Hermes/workspace/
├── docs/superpowers/specs/      # 设计文档（含本文件）
├── projects/                    # 每个项目的档案 + 代码副本
│   └── <项目代号>/
├── company/                     # 公司级元数据
│   ├── logs/                    # agent 调用日志、熔断日志
│   ├── dashboard/               # 聚合页生成器（脚本 + 模板 + 输出）
│   ├── pm-state/                # PM Agent 持久化状态（项目索引、待办、白名单）
│   └── monitor/                 # 监控循环脚本和配置
└── .git/                        # 整个工作空间一个 git 仓库
```

---

## 11. 关键流程图

### 11.1 新项目从需求到首个里程碑

```
老板（Telegram）→ "做个 X 小程序"
     ↓
PM Agent 提问澄清 → 写 PRD 草稿 → 推老板
     ↓ （介入点 1：需求确认）
老板批准
     ↓
PM 创建 GitHub 私仓 + Project board + 本地档案目录
     ↓
PM spawn Architect Agent → 出 01-architecture.md + 02-contracts/
     ↓ （介入点 2：架构评审）
老板拍板
     ↓
PM 拆 03-tasks/ 为 GitHub Issues
     ↓
PM 并行 spawn 多个 Coder Agent（每人一个 issue）→ 提 PR
     ↓
PM spawn Reviewer Agent → review PR → 通过则 merge
     ↓
全部模块完成 → PM spawn QA Agent → 端到端验收
     ↓
QA 通过 → PM spawn Doc Agent → 写文档
     ↓ （介入点 3：里程碑交付）
PM 推送演示链接 → 老板签字
```

### 11.2 异常处理流程

```
任何 agent 异常 / 监控告警
     ↓
第一层（被动）：写 log + 更新 dashboard
     ↓ 命中第二层阈值
第二层（通知）：PM 推 Telegram → 老板决策
     ↓ 命中第三层阈值（或第二层超时）
第三层（熔断）：PM 强杀 agent + 暂存现场 + 通知老板
     ↓
老板决策：恢复 / 改方案 / 放弃
```

---

## 12. 第二阶段（接外单）扩展点

本 spec 未实现，但已为以下能力预留接口：

- 多收件人支持（PM 推送可路由到客户 + 老板）
- 客户隔离（项目档案的 ACL、独立 GitHub org）
- 计费埋点（token 用量按项目聚合，便于报价）
- 客户验收门户（dashboard 增加客户视图）

---

## 13. 已知风险与缓解

| 风险 | 缓解措施 |
|------|---------|
| Token 成本失控 | 三层监控 + dashboard 实时可见 + 老板按月评估是否做模型分级 |
| Reviewer 变橡皮图章 | Reviewer prompt 强制要求"必须列 ≥ 2 条改进建议否则视为失职"；定期老板抽查 PR |
| Agent 之间契约失同步 | 严格契约规则 + Coder 越界自动 reject + ADR 不可变追加 |
| PM 单点故障 | PM 状态全部持久化到 `company/pm-state/`，重启可恢复；常驻服务有 systemd/launchd 自动拉起 |
| 老板被 Telegram 淹没 | 静默时段 + 每日简报合并 + PM 单一汇报口 + 噪音过滤 |
| Hermes session 状态丢失 | 子 agent 全部基于档案文件工作，无内存依赖；session 丢失只损失正在跑的那一步，重启即恢复 |
| 安全（agent 拿到密钥泄露） | 所有密钥放老板的 `.env`，spec 阶段禁止 agent 读取；需要时由老板手动注入到部署脚本 |

---

## 14. 验收标准（本设计本身）

1. ✅ 11 个原始决策点全部固化进文档
2. ✅ PM 汇报机制（4 个介入点 + 异常 + 简报 + 静默 + 回执）完整
3. ✅ 监控三层防御具体阈值明确
4. ✅ 项目档案结构和契约规则可执行
5. ✅ 工作空间布局明确
6. ✅ 已知风险与缓解措施列出

---

## 15. 下一步

进入 writing-plans 阶段，产出 Phase 1 实施计划。Phase 1 推荐范围：

1. 工作空间骨架 + git 初始化（已完成）
2. PM Agent profile 创建 + Telegram 白名单 + 常驻服务配置
3. 项目档案模板（templates/）
4. 监控循环脚本骨架
5. Dashboard 聚合页 MVP（先本地能跑，再上 VPS）
6. 跑通第一个最小项目：一个 hello-world 级小程序，验证全流程

Phase 2+ 再做：Doc Agent 自动化、设计 skill 集成深化、第二阶段扩展点。

---

## 6.4 PR 审核流水线（补充于 2026-04-19 设计 review）

为支持运行期 bug 修复阶段多 Coder Agent 并行产生的 PR 洪流，补充本节规则。

### 6.4.1 PR 创建规约

每个 Coder Agent 任务对应一个 PR：

- 分支命名：`<agent-id>/<issue-number>-<短描述>`（例：`coder-3/42-fix-login-timeout`）
- PR 标题：`[<issue-number>] <动词> <对象>`
- PR body 必须包含：
  - 关联 issue（`Closes #42`）
  - 修改的契约文件清单（如无则注明"无契约变更"）
  - 自测结果（跑了哪些测试、结果）
- **强制小 PR**：单 PR 修改 > 3000 行 → Reviewer 直接 reject 要求拆分

### 6.4.2 Reviewer 调度策略

避免单 Reviewer 串行成为瓶颈：

- **PR 队列**：PM 维护一个待审队列，按"提交时间 + 优先级标签"排序
- **并行上限**：PM 同时最多 spawn **3 个 Reviewer Agent** 并行审不同 PR
- **冲突前置检测**：Reviewer 接到 PR 第一步 `git fetch + check`，与 main 冲突 → 直接打回让 Coder rebase，不浪费 review 算力
- Reviewer 与 Coder 是不同 agent 实例，天然独立，无需"回避自己 PR"机制

### 6.4.3 合并顺序与冲突处理

**合并锁粒度**：按"项目"加锁，同一项目同一时刻只有 1 个 PR 能 merge（PM 持有 merge lock）。

**合并流程**：
```
PR 通过 review → 进 merge 队列
PM 按 FIFO 顺序处理 merge 队列：
  1. 拿 lock
  2. rebase onto main
  3. 跑 CI（如有）
  4. merge
  5. 释放 lock
  6. 通知所有正在跑的 Coder："main 已更新，请 rebase 你的分支"
```

**冲突处理**：
- 自动 rebase 失败 → PM 让原 Coder Agent 重新 spawn 一个 "rebase 任务" 解决冲突
- 冲突解决 ≥ 2 次仍失败 → 触发异常上报，问老板
- 涉及契约文件冲突 → 自动升级到 Architect Agent 仲裁，禁止 Coder 自己改契约

### 6.4.4 契约变更分级与老板可见性

PR 默认在 PM 内部消化，老板**不会**收到 PR 级别通知。例外见下表。

**契约变更（`02-contracts/` 下文件）按破坏性分三级**：

| 级别 | 类型 | 示例 | 处理 |
|------|------|------|------|
| 🟢 加法（向后兼容） | 新增 API 字段、新增表、新增 endpoint、新增可选参数 | PM 决定，不通知老板，merge 后纳入每日简报 |
| 🟡 改法（行为变更） | API 字段改默认值、新增必填校验、加索引、改返回结构（兼容范围内） | PM 决定，当天**单独**推一条非紧急通知 |
| 🔴 减法 / 破坏性（不兼容） | 删字段、改类型、删 endpoint、删表、改主键、改鉴权方式 | **必须**老板批准才能 merge，走第 5.1 节介入点 4（异常上报）流程 |

**其它强制推送给老板的 PR 触发条件**：
- PR 修改了部署 / 密钥相关文件（CI 配置、Dockerfile、`.env` 模板等）
- 同一 PR 被 Reviewer reject ≥ 3 次（说明 Coder 写不出来或方向错）

**老板主动查询**：在 Telegram 问 PM "X 项目当前 PR 队列" → PM 返回列表（编号 / 标题 / 状态 / 等待时长）。

### 6.4.5 与监控机制（第 9 节）联动

把以下 PR 流水线异常追加到第 9.2 节第二层告警与第 9.3 节第三层熔断条件：

| 条件 | 层级 |
|------|------|
| PR 队列堆积 > 10 个未 review | 第二层告警 |
| 单 PR 在 review 中 > 2 小时 | 第二层告警 |
| Merge 冲突连续失败 ≥ 5 次 | 第三层熔断 |
| 同一 PR 被 reject ≥ 3 次 | 第二层告警（同时按 6.4.4 推老板） |

---

## 变更日志

- 2026-04-19 初版（v1）：14 节，覆盖 11 个原始决策点
- 2026-04-19 v1.1 补充：增加第 6.4 节"PR 审核流水线"（5 小节），明确并行 PR 处理、契约变更三级制、监控联动
