# WEATHER-APP — 天气查询小工具

一个简洁的天气查询 Web 应用。输入城市名称，即可查看当前温度、天气描述和风向信息。前后端分离架构，后端代理调用和风天气（QWeather）API。

## 功能

- 输入城市名称查询当前天气
- 展示温度（℃）、天气描述（如"晴"）、风向（如"东北风"）
- 响应式布局，手机和电脑均可正常使用
- 城市不存在时给出友好提示

## 技术栈

| 层 | 技术 |
|----|------|
| 后端 | Python 3 + Flask |
| 前端 | 原生 HTML + CSS + JavaScript |
| HTTP 客户端 | requests |
| 跨域 | flask-cors |
| 天气数据源 | 和风天气 API（QWeather） |

## 目录结构

```
WEATHER-APP/
├── backend/
│   ├── app.py                  # Flask 主应用
│   ├── config.py               # 配置管理
│   ├── weather_service.py      # 和风天气 API 封装
│   ├── requirements.txt        # Python 依赖
│   └── tests/                  # 单元测试
├── frontend/
│   ├── index.html              # 主页面
│   ├── style.css               # 样式
│   └── app.js                  # 前端逻辑
├── docs/                       # 项目文档
│   ├── API.md                  # API 文档
│   ├── DEPLOY.md               # 部署文档
│   └── USER-GUIDE.md           # 用户指南
├── README.md
└── CHANGELOG.md
```

## 快速启动

### 前置条件

- Python 3.8+
- pip

### 1. 启动后端

```bash
cd backend
pip install -r requirements.txt
export QWEATHER_API_KEY="a5d3a7d4e32c4c7d880025b161cc9f15"
python app.py
```

后端将在 `http://localhost:5000` 启动。

### 2. 打开前端

用浏览器直接打开 `frontend/index.html` 文件即可。

### 3. 使用

在搜索框输入城市名称（如"北京"），点击搜索按钮或按回车键，即可看到天气信息。

## 环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| QWEATHER_API_KEY | 和风天气 API Key | 空（必填） |
| QWEATHER_GEO_BASE_URL | GeoAPI 地址 | https://geoapi.qweather.com/v2/city/lookup |
| QWEATHER_WEATHER_BASE_URL | 天气 API 地址 | https://devapi.qweather.com/v7/weather/now |
| QWEATHER_TIMEOUT | API 调用超时（秒） | 5 |
| FLASK_DEBUG | 开启 Flask 调试模式 | false |

## 运行测试

```bash
cd backend
pip install -r requirements.txt
pytest --cov=. --cov-report=term-missing
```

## 相关文档

- [API 文档](docs/API.md)
- [部署文档](docs/DEPLOY.md)
- [用户指南](docs/USER-GUIDE.md)
- [产品需求文档](docs/prd.md)
- [技术架构文档](docs/architecture.md)
