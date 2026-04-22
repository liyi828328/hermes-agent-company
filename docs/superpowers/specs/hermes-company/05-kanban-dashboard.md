# 看板与 Dashboard

> 本文件是 [Hermes AI 软件公司设计总纲](../hermes-company-design.md) 的子文档。
>
> **用途**：定义两层看板系统——GitHub Projects v2（单项目细节）和 VPS 聚合页（跨项目总览），让老板随时掌握全公司状态。


GitHub Projects（单项目细节） + VPS 聚合页（跨项目总览）。

## 单项目层 — GitHub Projects v2

- 每个项目一个 Project board
- Issue = 任务，按 Status 字段自动分列：Backlog / Todo / In Progress / Review / Done / Blocked
- PM 通过 `gh` CLI 创建 issue、移动状态、加标签（agent:coder、priority:high、blocker 等）
- 老板可在浏览器或 GitHub 移动 App 上查看细节，留 comment 即与 PM 沟通

## 公司层 — VPS 聚合页（规划中，当前未实现）

- 部署在老板的 VPS，通过域名访问（建议子域名如 `dashboard.<your-domain>`）
- 后端：定时脚本（cron，每 10 分钟跑一次），读取所有 `projects/*/STATUS.md` + GitHub API，渲染为静态 HTML
- 字段：项目代号 / 当前阶段 / 阻塞点 / 最后更新时间 / 累计 token 消耗 / 跳转 GitHub 链接
- 移动端友好（响应式），便于老板手机随时扫一眼
- 实现栈建议：Python 脚本 + Jinja2 模板 + Nginx 静态服务（最小依赖）

---
