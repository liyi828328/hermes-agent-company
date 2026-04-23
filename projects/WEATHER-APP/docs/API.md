# Weather App — API 接口文档

## 概述

Weather App 后端提供 2 个 RESTful API 接口，所有接口均返回 JSON 格式数据。

- 基础地址：`http://localhost:8000`
- 自动文档：`http://localhost:8000/docs`（Swagger UI）
- OpenAPI 规范：`http://localhost:8000/openapi.json`

## 统一响应格式

### 成功响应

```json
{
  "code": "OK",
  "data": { ... }
}
```

### 错误响应

```json
{
  "code": "错误码",
  "message": "人类可读的错误描述"
}
```

## 接口列表

### 1. 城市搜索

根据城市名称模糊搜索城市列表。

**请求**

```
GET /api/cities?q={城市名称}
```

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| q | query | string | 是 | 城市名称，支持中文和拼音，最少 1 个字符 |

**成功响应** `200 OK`

```json
{
  "code": "OK",
  "data": [
    {
      "id": "101010100",
      "name": "北京",
      "adm1": "北京",
      "adm2": "北京",
      "country": "中国"
    }
  ]
}
```

**响应字段说明**

| 字段 | 类型 | 说明 |
|------|------|------|
| data[].id | string | 城市 ID，用于天气查询接口 |
| data[].name | string | 城市名称 |
| data[].adm1 | string | 一级行政区（省/直辖市） |
| data[].adm2 | string | 二级行政区（市） |
| data[].country | string | 国家名称 |

**未找到城市时**：返回 `200 OK`，`data` 为空数组 `[]`。

**请求示例**

```bash
# 中文搜索
curl "http://localhost:8000/api/cities?q=北京"

# 拼音搜索
curl "http://localhost:8000/api/cities?q=beijing"
```

---

### 2. 实时天气查询

根据城市 ID 获取实时天气信息。

**请求**

```
GET /api/weather?location={城市ID}
```

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| location | query | string | 是 | 城市 ID（从城市搜索接口获取） |

**成功响应** `200 OK`

```json
{
  "code": "OK",
  "data": {
    "temp": "23",
    "text": "晴",
    "windDir": "西北风",
    "windScale": "3",
    "humidity": "45",
    "obsTime": "2026-04-23T15:00+08:00"
  }
}
```

**响应字段说明**

| 字段 | 类型 | 说明 |
|------|------|------|
| data.temp | string | 温度，单位：摄氏度 |
| data.text | string | 天气状况文字描述（如晴、多云、阴等） |
| data.windDir | string | 风向（如西北风、东南风） |
| data.windScale | string | 风力等级 |
| data.humidity | string | 相对湿度，百分比 |
| data.obsTime | string | 数据观测时间，ISO 8601 格式 |

**请求示例**

```bash
curl "http://localhost:8000/api/weather?location=101010100"
```

## 错误码

| 错误码 | HTTP 状态码 | 含义 | 触发场景 |
|--------|-------------|------|----------|
| OK | 200 | 成功 | 正常响应 |
| INVALID_PARAM | 400 | 参数错误 | 缺少必填参数或参数格式不合法 |
| UPSTREAM_ERROR | 502 | 上游服务错误 | QWeather API 返回非正常状态 |
| UPSTREAM_TIMEOUT | 504 | 上游服务超时 | 请求 QWeather 超过 10 秒未响应 |
| INTERNAL_ERROR | 500 | 内部错误 | 未预期的服务端异常 |

**错误响应示例**

```bash
# 参数缺失
curl "http://localhost:8000/api/cities"
# 返回 400：{"code": "INVALID_PARAM", "message": "参数格式不合法"}

# 上游超时
# 返回 504：{"code": "UPSTREAM_TIMEOUT", "message": "天气服务请求超时，请稍后重试"}

# 上游错误
# 返回 502：{"code": "UPSTREAM_ERROR", "message": "天气服务暂时不可用，请稍后重试"}
```

## 调用流程

典型的使用流程：

1. 调用城市搜索接口 `GET /api/cities?q=上海`，获取城市列表
2. 从返回的城市列表中取出目标城市的 `id`（如 `101020100`）
3. 调用天气查询接口 `GET /api/weather?location=101020100`，获取实时天气

## 注意事项

- 城市搜索未找到结果时返回 `200 OK` + 空数组，不视为错误
- 所有 5xx 错误的 `message` 字段不暴露内部细节，仅返回用户友好提示
- 前端应根据 `code` 字段判断是否成功，不依赖 HTTP 状态码
- 后端请求 QWeather 的超时时间为 10 秒，失败后会重试 1 次
