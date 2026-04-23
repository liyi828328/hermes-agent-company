# WEATHER-APP — 部署文档

## 运行环境要求

| 项 | 要求 |
|----|------|
| 操作系统 | macOS / Linux / Windows |
| Python | 3.8+ |
| pip | 已安装 |
| 网络 | 需能访问和风天气 API（geoapi.qweather.com、devapi.qweather.com） |

## 本地部署步骤

### 1. 获取代码

```bash
git clone <仓库地址>
cd WEATHER-APP
```

### 2. 安装后端依赖

```bash
cd backend
pip install -r requirements.txt
```

依赖列表：
- flask==3.1.3
- flask-cors==4.0.2
- requests==2.32.5

### 3. 配置环境变量

```bash
export QWEATHER_API_KEY="a5d3a7d4e32c4c7d880025b161cc9f15"
```

可选环境变量：

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| QWEATHER_API_KEY | 和风天气 API Key | 空（必填） |
| QWEATHER_GEO_BASE_URL | GeoAPI 地址 | https://geoapi.qweather.com/v2/city/lookup |
| QWEATHER_WEATHER_BASE_URL | 天气 API 地址 | https://devapi.qweather.com/v7/weather/now |
| QWEATHER_TIMEOUT | API 调用超时（秒） | 5 |
| FLASK_DEBUG | 开启调试模式 | false |

### 4. 启动后端服务

```bash
cd backend
python app.py
```

服务启动后监听 `http://localhost:5000`。

### 5. 访问前端

用浏览器打开 `frontend/index.html` 文件。

前端默认连接 `http://localhost:5000` 作为后端地址。如需修改，可在 `frontend/app.js` 加载前设置全局变量：

```html
<script>window.WEATHER_API_BASE = "http://your-host:5000";</script>
<script src="app.js"></script>
```

## 验证部署

1. 启动后端后，用 curl 测试接口：

```bash
curl "http://localhost:5000/api/weather?city=北京"
```

预期返回：

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

2. 打开 `frontend/index.html`，输入"北京"搜索，应显示天气卡片。

## 常见问题

### 后端启动报错 ModuleNotFoundError

确认已在 backend 目录下执行 `pip install -r requirements.txt`。

### 前端搜索无响应

- 确认后端已启动并监听 5000 端口
- 打开浏览器开发者工具（F12）查看 Console 是否有网络错误
- 确认前端文件中 API_BASE 指向正确的后端地址

### 查询返回"天气服务暂时不可用"

- 检查网络是否能访问和风天气 API
- 确认 QWEATHER_API_KEY 环境变量已正确设置
- 检查 API Key 是否有效（未过期、未被禁用）

### 查询返回"未找到该城市"

输入的城市名称在和风天气数据库中无匹配。尝试使用标准城市名称，如"北京"而非"北京市"。
