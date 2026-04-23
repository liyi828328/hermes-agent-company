# 变更日志

## [1.0.0] - 2026-04-23

### 新增

- 城市搜索接口 `GET /api/cities?q={城市名}`，支持中文和拼音模糊搜索
- 实时天气查询接口 `GET /api/weather?location={城市ID}`，返回温度、天气描述、风向、风力、湿度
- QWeather API 代理层，隐藏 API Key，带 10 秒超时和 1 次重试
- 统一错误响应格式和错误码规范（INVALID_PARAM、UPSTREAM_ERROR、UPSTREAM_TIMEOUT、INTERNAL_ERROR）
- 请求参数校验和全局异常处理
- CORS 中间件配置
- 环境变量配置管理（pydantic-settings）
- 单元测试覆盖城市搜索和天气查询
- 项目文档（README、API 文档、部署文档）
