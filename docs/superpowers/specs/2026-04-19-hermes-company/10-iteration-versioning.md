# 迭代与版本管理

> 本文件是 [Hermes AI 软件公司设计总纲](../2026-04-19-hermes-company-design.md) 的子文档。

---

## 变更分级

首个里程碑交付后，后续需求变更和 bug 修复按以下分级处理：

| 级别 | 判定条件 | 流程 | 老板参与 |
|------|---------|------|---------|
| 小改 | ≤ 1 个模块 + 不改契约 | Dispatcher 直接派 Coder，不走 PRD | 不通知，纳入每日简报 |
| 中改 | 跨模块 或 改契约 🟢/🟡 级 | Dispatcher 协调 Architect 改契约 + 派 Coder | PM 纳入每日简报，🟡 级当天单独通知 |
| 大改 | 改契约 🔴 级 或 新增整个功能模块 | 走完整 PRD 流程（PM 写 PRD → 老板确认 → Architect → Coder...） | 老板介入点 1 确认 |

**边界判断由 Dispatcher 做**：读变更描述 + 对比现有契约，自动分级。拿不准时按高一级处理（宁可多走流程也不要漏审）。

---

## 版本号规范

采用语义化版本（Semantic Versioning）：`vX.Y.Z`

| 位 | 含义 | 谁触发 | 举例 |
|----|------|--------|------|
| X（Major） | 大版本：重大功能 / 不兼容变更 | 大改 | v1.0.0 → v2.0.0 |
| Y（Minor） | 功能迭代：新模块 / 新 endpoint | 中改 | v1.0.0 → v1.1.0 |
| Z（Patch） | Bug fix / 小优化 | 小改 | v1.0.0 → v1.0.1 |

---

## Tag 流程

- 每个里程碑 merge 完 + QA 通过后，Dispatcher 在 main 分支打 git tag
- Tag 格式：`v<X.Y.Z>`（例：`v0.1.0`）
- Tag message 包含：本次里程碑完成的功能列表（从 STATUS.md 提取）
- Dispatcher 打 tag 后更新 STATUS.md 记录版本号
- 第一个项目从 `v0.1.0` 开始（0.x 表示未正式发布）

---

## 与其他子文档的关联

- **03-project-archive.md**：契约变更三级（🟢🟡🔴）定义在该文档 6.4.4 节，本文档的变更分级直接引用
- **02-reporting.md**：大改走介入点 1（需求确认），中改 🟡 级走当天通知
- **04-agent-prompts.md**：Dispatcher 的行为规则需补充变更分级判断逻辑
