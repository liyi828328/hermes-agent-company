# 覆盖率报告 - bugfix-002

- 任务 ID: bugfix-002
- 日期: 2026-04-23
- 测试框架: Jest + jsdom

## 覆盖率摘要

| 指标 | 覆盖率 | 状态 |
|------|--------|------|
| Statements | 100% | ✅ |
| Branches | 86.36% | ✅ |
| Functions | 100% | ✅ |
| Lines | 100% | ✅ |

## 测试用例（15 个，全部通过）

| 分组 | 测试用例 | 结果 |
|------|----------|------|
| showWeather | 应正确渲染天气数据 | ✅ |
| showError | 应显示错误信息并隐藏天气卡片 | ✅ |
| fetchWeather | 应发送正确的 API 请求并返回结果 | ✅ |
| fetchWeather | 应正确编码城市名称 | ✅ |
| handleSearch | 输入为空时应显示错误 | ✅ |
| handleSearch | 输入仅空格时应显示错误 | ✅ |
| handleSearch | API 返回 200 时应显示天气 | ✅ |
| handleSearch | API 返回错误时应显示错误信息 | ✅ |
| handleSearch | 网络错误时应显示网络错误提示 | ✅ |
| handleSearch | 搜索时按钮应禁用并显示加载状态 | ✅ |
| init | 应绑定按钮点击事件 | ✅ |
| init | 应绑定 Enter 键事件 | ✅ |
| init | 非 Enter 键不应触发搜索 | ✅ |
| API_BASE | 应支持自定义 API base URL | ✅ |
| API_BASE | 默认使用 localhost:5000 | ✅ |
