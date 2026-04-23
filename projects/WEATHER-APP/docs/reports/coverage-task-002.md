# 覆盖率报告 - task-002（前端页面开发）

- 日期：2026-04-23
- 工具：Jest 29 + jsdom
- 测试文件：frontend/app.test.js

## 覆盖率

| 指标 | 百分比 |
|------|--------|
| Statements | 100% |
| Branches | 87.5% |
| Functions | 100% |
| Lines | 100% |

## 测试用例（19 个，全部通过）

- escapeHtml: 5 个（HTML 转义、非字符串、空字符串）
- buildWeatherCard: 2 个（正常渲染、XSS 防护）
- buildErrorMessage: 2 个（正常渲染、XSS 防护）
- handleApiResponse: 5 个（成功/错误/默认提示/无 data/多错误码）
- fetchWeather: 2 个（成功调用、网络错误）
- init: 3 个（正常提交渲染、空输入拦截、加载状态）
