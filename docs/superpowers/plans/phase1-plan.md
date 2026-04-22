# Phase 1 实施计划

> **目标**：7 个 Agent 全部跑通，走完一个完整项目（从需求到交付）。
>
> **方式**：按步骤逐个实施，老板在线跟着看，随时纠偏。
>
> **验证项目**：TODO API（3 个接口：列表/新增/删除，纯后端）。

---

## 实施步骤

### 步骤 1：项目仓库脚手架

创建一键初始化脚本，新建项目时自动在 GitHub 创建私仓 + 初始化标准目录结构。

**交付物**：
- `company/templates/project-scaffold/`（标准目录模板）
- `company/scripts/new-project.sh`（一键创建脚本）

**验收**：跑脚本能在 GitHub 创建私仓，本地 `projects/` 下出现完整目录结构。

---

### 步骤 2：PM Agent 常驻服务

创建 Hermes profile，配置 Telegram gateway，让 PM 常驻运行。

**交付物**：
- `pm-agent` Hermes profile
- PM prompt 模板（`company/prompts/pm-agent.md`）
- Telegram 白名单配置
- 每日简报 cron
- 静默时段逻辑
- alert 轮询机制

**验收**：老板在 Telegram 发消息，PM 正确回复；手动写一条 alert，PM 读到后推送。

---

### 步骤 3：Dispatcher Agent 常驻服务

创建 Hermes profile，让 Dispatcher 常驻后台运行。

**交付物**：
- `dispatcher-agent` Hermes profile
- Dispatcher prompt 模板（`company/prompts/dispatcher-agent.md`）
- 5 个子 agent prompt 模板（architect/coder/reviewer/qa/doc）
- PRD 状态检测逻辑
- 子 agent spawn 逻辑
- 信号文件检测逻辑
- merge 队列管理逻辑

**验收**：手动创建一个 PRD（status: approved），Dispatcher 检测到后自动拆出 GitHub Issues。

---

### 步骤 4：端到端验证（TODO API 项目）

用 TODO API 走完全流程，验证 PM → Dispatcher → Architect → Coder → Reviewer → QA → Doc 的完整链路。

**流程**：
1. 老板在 Telegram 发需求："做一个 TODO API"
2. PM 澄清需求 → 写 PRD → 推老板确认
3. 老板批准 → 创建项目仓库（步骤 1 的脚本）
4. Dispatcher 检测到 → spawn Architect → 出架构 + 契约
5. PM 推架构给老板 → 老板拍板
6. Dispatcher 拆任务 → spawn Coder → 写代码 + 测试 → 提 PR
7. Dispatcher spawn Reviewer → 审 PR → merge
8. Dispatcher 跑集成测试
9. Dispatcher spawn QA → E2E 验收
10. Dispatcher spawn Doc → 写文档
11. PM 推里程碑报告 → 老板签字

**验收**：TODO API 能跑、测试全绿、文档完整、全流程在 Telegram 有完整汇报记录。

---

## Phase 1 之后再做

- [x] 用新 prompt 重新跑端到端验证（核心流程全部通过：分支/PR/测试/覆盖率/静态检查/Review闭环/QA闭环）
- [ ] 监控循环（三层防御：被动日志 → 异常通知 → 硬熔断）
- [ ] Dashboard 聚合页（Python 脚本 + Jinja2 + 静态 HTML）
- [ ] 接飞书通讯 + PM Agent 常驻（PM 挂在飞书 gateway，老板随时能发消息）
- [ ] Dispatcher 常驻 cron 轮询（每 5 分钟启动新 session，扫描项目状态，有事处理没事退出）
- [ ] 复盘 + 更新设计文档（根据 Phase 1 实施中的发现调整 spec）
