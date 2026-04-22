# 项目档案制度

> 本文件是 [Hermes AI 软件公司设计总纲](../hermes-company-design.md) 的子文档。
>
> **用途**：定义项目仓库的档案结构、严格契约规则、GitHub 集成方式、PR 审核流水线（创建/调度/merge/契约变更分级/监控联动）。


每个项目一个 GitHub 私仓，`projects/<项目代号>/` 即为该仓库的本地 clone。

> **注意**：`projects/` 下的每个项目是独立 git repo，不属于 workspace repo。workspace repo 只管 `docs/` 和 `company/` 等公司级文件。

## 档案结构

每个项目仓库内部结构：

```
<项目代号>/                    # = GitHub 私仓根目录
├── docs/                      # 项目档案
│   ├── prd.md                 # PM 维护：需求、验收标准、范围边界、设计规范
│   ├── architecture.md        # Architect 维护：技术栈、模块划分、部署方案、目录结构
│   ├── contracts/             # Architect 维护：API spec、DB schema、消息格式
│   │   ├── api.yaml           # OpenAPI 契约
│   │   ├── schema.sql         # 数据库 schema（含索引）
│   │   ├── error-codes.md     # 统一错误码规范
│   │   └── events.md          # 异步事件定义
│   ├── tasks/                 # 任务看板 + 信号文件
│   │   ├── tasks.md           # 看板：todo / doing / review / done
│   │   ├── <task-id>.done     # 子 agent 完成信号
│   │   └── <task-id>.failed   # 子 agent 失败信号
│   ├── decisions/             # 所有人追加：架构决策记录（ADR）
│   │   └── ADR-001-xxx.md
│   ├── reviews/               # Reviewer 输出：审查报告（按轮次）
│   │   └── review-<task-id>-r1.md
│   ├── reports/               # 覆盖率报告
│   │   └── coverage-<task-id>.md
│   ├── qa/                    # QA 输出：测试用例 + 缺陷报告 + 验收报告
│   │   ├── test-cases-<task-id>.md
│   │   ├── defects-<task-id>.md
│   │   └── acceptance-report-<task-id>.md
│   ├── API.md                 # Doc Agent 维护
│   ├── DEPLOY.md              # Doc Agent 维护
│   ├── DATABASE.md            # Doc Agent 维护（如有数据库）
│   └── USER-GUIDE.md          # Doc Agent 维护（如有用户界面）
├── src/                       # 业务代码
├── tests/                     # 测试代码
│   ├── unit/                  # 单元测试（Coder 写）
│   ├── integration/           # 集成测试（Coder 写）
│   └── e2e/                   # E2E 测试（QA 写）
├── README.md                  # Doc Agent 维护
├── CHANGELOG.md               # Doc Agent 维护
├── STATUS.md                  # PM 每工作周期更新：当前进度、阻塞、下一步
└── .gitignore
```

## 严格契约规则

- 任何 agent 开工第一件事：读 `docs/prd.md` + `docs/architecture.md` + `docs/contracts/`
- Coder 改代码必须先看 `docs/contracts/`，发现契约不够用 → **不许擅自扩展**，必须通过 PM 找 Architect 改契约 → Architect 修改 → PM 通知所有相关 Coder
- Coder 越界（修改了未声明的契约）→ Reviewer 直接 reject，不进 review
- 所有跨 agent 决策走 ADR：一页纸，记录背景 / 候选方案 / 决定 / 影响，**追加不删除**
- `STATUS.md` 是 PM 给老板看的窗口，每工作周期（或每个介入点前）更新

## GitHub 集成

- 每个项目对应一个私仓
- 任务 = GitHub Issue
- Coder 提交 = Pull Request
- Reviewer 通过 PR review 留 comment
- PM 通过 `gh` CLI 操作 issue / PR / project board
- **git commit message 一律使用中文描述**

## PR 审核流水线

为支持运行期 bug 修复阶段多 Coder Agent 并行产生的 PR 洪流，补充本节规则。

### PR 创建规约

每个 Coder Agent 任务对应一个 PR：

- 分支命名：`<agent-id>/<issue-number>-<短描述>`（例：`coder-3/42-fix-login-timeout`）
- PR 标题：`[<issue-number>] <动词> <对象>`
- PR body 必须包含：
  - 关联 issue（`Closes #42`）
  - 修改的契约文件清单（如无则注明"无契约变更"）
  - 自测结果（跑了哪些测试、结果）
- **强制小 PR**：单 PR 修改 > 3000 行 → Reviewer 直接 reject 要求拆分

### Reviewer 调度策略

避免单 Reviewer 串行成为瓶颈：

- **PR 队列**：Dispatcher 维护一个待审队列，按"提交时间 + 优先级标签"排序
- **并行上限**：Dispatcher 同时最多 spawn **3 个 Reviewer Agent** 并行审不同 PR
- **冲突前置检测**：Reviewer 接到 PR 第一步 `git fetch + check`，与 main 冲突 → 直接打回让 Coder rebase，不浪费 review 算力
- Reviewer 与 Coder 是不同 agent 实例，天然独立，无需"回避自己 PR"机制

### 合并顺序与冲突处理

**合并锁粒度**：按"项目"加锁，同一项目同一时刻只有 1 个 PR 能 merge（Dispatcher 持有 merge lock）。

**合并流程**：
```
PR 通过 review → 进 merge 队列
Dispatcher 按 FIFO 顺序处理 merge 队列：
  1. 拿 lock
  2. rebase onto main
  3. 跑 CI（如有）
  4. merge
  5. 释放 lock
  6. 通知所有正在跑的 Coder："main 已更新，请 rebase 你的分支"
```

**冲突处理**：
- 自动 rebase 失败 → Dispatcher 让原 Coder Agent 重新 spawn 一个 "rebase 任务" 解决冲突
- 冲突解决 ≥ 2 次仍失败 → 触发异常上报，问老板
- 涉及契约文件冲突 → 自动升级到 Architect Agent 仲裁，禁止 Coder 自己改契约

### 契约变更分级与老板可见性

PR 默认在 PM 内部消化，老板**不会**收到 PR 级别通知。例外见下表。

**契约变更（`docs/contracts/` 下文件）按破坏性分三级**：

| 级别 | 类型 | 示例 | 处理 |
|------|------|------|------|
| 🟢 加法（向后兼容） | 新增 API 字段、新增表、新增 endpoint、新增可选参数 | PM 决定，不通知老板，merge 后纳入每日简报 |
| 🟡 改法（行为变更） | API 字段改默认值、新增必填校验、加索引、改返回结构（兼容范围内） | PM 决定，当天**单独**推一条非紧急通知 |
| 🔴 减法 / 破坏性（不兼容） | 删字段、改类型、删 endpoint、删表、改主键、改鉴权方式 | **必须**老板批准才能 merge，走 [02-reporting.md](02-reporting.md) 介入点 4（异常上报）流程 |

**其它强制推送给老板的 PR 触发条件**：
- PR 修改了部署 / 密钥相关文件（CI 配置、Dockerfile、`.env` 模板等）
- 同一 PR 被 Reviewer reject ≥ 3 次（说明 Coder 写不出来或方向错）

**老板主动查询**：在飞书问 PM "X 项目当前 PR 队列" → PM 返回列表（编号 / 标题 / 状态 / 等待时长）。

### 与监控机制联动

把以下 PR 流水线异常追加到07-monitoring.md 中第二层告警与第三层熔断条件：

| 条件 | 层级 |
|------|------|
| PR 队列堆积 > 10 个未 review | 第二层告警 |
| 单 PR 在 review 中 > 2 小时 | 第二层告警 |
| Merge 冲突连续失败 ≥ 5 次 | 第三层熔断 |
| 同一 PR 被 reject ≥ 3 次 | 第二层告警（同时按 6.4.4 推老板） |

---
