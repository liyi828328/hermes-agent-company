# QA 能力边界

> 本文件是 [Hermes AI 软件公司设计总纲](../hermes-company-design.md) 的子文档。
>
> **用途**：明确 QA Agent 的能力边界——能测什么（API/Web/DB）、不能测什么（小程序/App/性能/安全）、做不了的由谁兜底。

---

## QA Agent 能做的

| 测试类型 | 方式 | 工具 |
|---------|------|------|
| API 接口测试 | 调用 endpoint 验证 request/response | curl / httpie / 脚本 |
| Web 页面 E2E | 模拟用户操作浏览器 | Hermes `browser` 工具 |
| 数据库状态验证 | 跑 SQL 检查数据一致性 | `terminal`（mysql/psql/sqlite3） |
| 业务逻辑审查 | 读代码检查逻辑是否符合 PRD | `file` / `search_files` |
| 测试报告生成 | 测试用例表 + 缺陷报告 + 验收报告 | 写到 `docs/qa/` |

---

## QA Agent 做不了的

| 测试类型 | 原因 | 兜底方案 |
|---------|------|---------|
| 微信小程序 UI/交互测试 | Hermes 无法控制小程序开发者工具 | 老板在介入点 3 手动验收 |
| iOS/Android 原生 App 操作 | Hermes 无法控制移动端模拟器 | 老板手动验收 |
| 性能压测 | 需要专门工具（k6/locust/wrk），配置复杂 | 第二阶段考虑，或老板自己用工具跑 |
| 安全渗透测试 | 需要专业安全工具和知识 | 第二阶段考虑 |
| 多端兼容性测试 | 需要多浏览器/多设备环境 | 老板手动抽检 |

---

## 与其他子文档的关联

- **04-agent-prompts.md**：QA Agent 的行为规则和禁止行为中已注明"小程序端 UI/交互测试不在 QA 职责范围"
- **09-testing-strategy.md**：QA 只做 E2E 层，不管单元和集成测试
- **02-reporting.md**：介入点 3（里程碑交付）是老板手动验收小程序/App 的唯一环节
