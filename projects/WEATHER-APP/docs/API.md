# WEATHER-APP — API 文档

## 基本信息

- 基础地址：`http://localhost:5000`
- 数据格式：JSON
- 编码：UTF-8

## 接口列表

### GET /api/weather

查询指定城市的当前天气。

#### 请求参数

| 参数 | 位置 | 类型 | 必填 | 说明 |
|------|------|------|------|------|
| city | query | string | 是 | 城市名称（中文或英文） |

#### 请求示例

```
GET /api/weather?city=北京
```

#### 成功响应（200）

```json
{
  "code": 0,
  "data": {
    "city": "北京",
    "temp": "25",
    "text": "晴",
    "windDir": "东北风"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| code | integer | 状态码，0 表示成功 |
| data.city | string | 城市名称 |
| data.temp | string | 温度（℃） |
| data.text | string | 天气描述 |
| data.windDir | string | 风向 |

#### 错误响应

所有错误响应格式统一：

```json
{
  "code": 1001,
  "error": "MISSING_CITY",
  "message": "缺少 city 参数"
}
```

#### 错误码表

| code | error | HTTP 状态码 | 说明 |
|------|-------|------------|------|
| 0 | - | 200 | 成功（成功时无 error 字段） |
| 1001 | MISSING_CITY | 400 | 缺少 city 查询参数 |
| 1002 | CITY_NOT_FOUND | 404 | 未找到该城市 |
| 1003 | UPSTREAM_ERROR | 502 | 和风天气 API 调用失败（超时、网络错误等） |
| 1099 | INTERNAL_ERROR | 500 | 未预期的服务器异常 |

#### 调用示例

**curl**

```bash
curl "http://localhost:5000/api/weather?city=北京"
```

**Python**

```python
import requests

resp = requests.get("http://localhost:5000/api/weather", params={"city": "北京"})
data = resp.json()
if data["code"] == 0:
    print(f"温度: {data['data']['temp']}℃")
    print(f"天气: {data['data']['text']}")
    print(f"风向: {data['data']['windDir']}")
else:
    print(f"错误: {data['message']}")
```

**JavaScript**

```javascript
fetch("http://localhost:5000/api/weather?city=" + encodeURIComponent("北京"))
  .then(function (res) { return res.json(); })
  .then(function (data) {
    if (data.code === 0) {
      console.log("温度:", data.data.temp + "℃");
      console.log("天气:", data.data.text);
      console.log("风向:", data.data.windDir);
    } else {
      console.log("错误:", data.message);
    }
  });
```

## 跨域支持

后端通过 flask-cors 开启了 CORS，允许任意来源的浏览器请求。

## 数据来源

天气数据来自和风天气（QWeather）API。后端作为代理转发请求，前端不直接调用第三方 API。

### 数据流

1. 前端发送 `GET /api/weather?city=北京` 到后端
2. 后端调用和风天气 GeoAPI 查找城市，获取 location ID
3. 后端用 location ID 调用和风天气实时天气 API
4. 后端组装 city、temp、text、windDir 四个字段返回前端
