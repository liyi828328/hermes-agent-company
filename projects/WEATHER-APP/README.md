# Weather App — 天气查询 API 服务

一个基于 FastAPI 的天气查询后端服务，调用和风天气（QWeather）API 提供城市搜索和实时天气查询功能。API Key 安全地存储在后端，不暴露给前端。

## 功能

- **城市搜索**：输入城市名称（中文或拼音），返回匹配的城市列表
- **实时天气查询**：根据城市 ID 获取当前天气（温度、天气描述、风向、风力、湿度）
- **API Key 安全代理**：QWeather API Key 仅存在于后端环境变量中

## 技术栈

| 层 | 技术 | 版本 |
|----|------|------|
| 后端框架 | FastAPI | 0.100+ |
| HTTP 客户端 | httpx | 0.27+ |
| 配置管理 | pydantic-settings | 2.0+ |
| 运行时 | Python | 3.10+ |
| 测试 | pytest + pytest-asyncio | — |
| 静态检查 | ruff | 0.4+ |

## 快速开始

### 1. 克隆项目

```bash
git clone <仓库地址>
cd weather-app
```

### 2. 创建虚拟环境并安装依赖

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 3. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env` 文件，填入你的 QWeather API Key：

```
QWEATHER_API_KEY=你的API密钥
QWEATHER_API_HOST=k73wt3h522.re.qweatherapi.com
```

### 4. 启动服务

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

服务启动后访问 http://localhost:8000/docs 可查看自动生成的 OpenAPI 文档。

### 5. 测试接口

```bash
# 城市搜索
curl "http://localhost:8000/api/cities?q=北京"

# 实时天气查询（使用城市搜索返回的 ID）
curl "http://localhost:8000/api/weather?location=101010100"
```

## 项目结构

```
weather-app/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py              # FastAPI 入口，注册路由、CORS、异常处理
│   │   ├── config.py            # 配置管理（环境变量读取）
│   │   ├── routers/
│   │   │   ├── city.py          # 城市搜索路由 GET /api/cities
│   │   │   └── weather.py       # 天气查询路由 GET /api/weather
│   │   ├── services/
│   │   │   └── qweather.py      # QWeather API 调用封装（带超时和重试）
│   │   └── schemas/
│   │       ├── city.py          # 城市相关 Pydantic 模型
│   │       └── weather.py       # 天气相关 Pydantic 模型
│   ├── tests/                   # 单元测试
│   ├── requirements.txt
│   └── .env.example             # 环境变量模板
├── docs/
│   ├── prd.md                   # 产品需求文档
│   ├── architecture.md          # 技术架构文档
│   ├── API.md                   # API 接口文档
│   ├── DEPLOY.md                # 部署文档
│   └── contracts/
│       ├── api.yaml             # OpenAPI 契约
│       └── error-codes.md       # 错误码规范
├── README.md
├── CHANGELOG.md
└── STATUS.md
```

## 文档索引

| 文档 | 路径 | 说明 |
|------|------|------|
| API 接口文档 | [docs/API.md](docs/API.md) | 接口详情、请求/响应示例、错误码 |
| 部署文档 | [docs/DEPLOY.md](docs/DEPLOY.md) | 环境要求、部署步骤、运维说明 |
| 产品需求文档 | [docs/prd.md](docs/prd.md) | 功能列表与验收标准 |
| 技术架构文档 | [docs/architecture.md](docs/architecture.md) | 系统架构与模块设计 |
| OpenAPI 契约 | [docs/contracts/api.yaml](docs/contracts/api.yaml) | 接口定义（机器可读） |
| 错误码规范 | [docs/contracts/error-codes.md](docs/contracts/error-codes.md) | 统一错误码列表 |
| 变更日志 | [CHANGELOG.md](CHANGELOG.md) | 版本变更记录 |

## 许可

内部项目，仅限公司内部使用。
