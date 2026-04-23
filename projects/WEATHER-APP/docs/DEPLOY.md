# Weather App — 部署文档

## 环境要求

| 项目 | 要求 |
|------|------|
| Python | 3.10 或更高版本 |
| pip | 最新版本 |
| 网络 | 需要访问 QWeather API（`https://k73wt3h522.re.qweatherapi.com`） |
| 操作系统 | macOS / Linux / Windows |

## 依赖清单

项目运行时依赖（`backend/requirements.txt`）：

| 包 | 版本要求 | 用途 |
|----|----------|------|
| fastapi | >=0.100.0 | Web 框架 |
| uvicorn[standard] | >=0.23.0 | ASGI 服务器 |
| httpx | >=0.27.0 | 异步 HTTP 客户端 |
| pydantic-settings | >=2.0.0 | 配置管理 |

开发/测试依赖（同一 requirements.txt）：

| 包 | 版本要求 | 用途 |
|----|----------|------|
| pytest | >=7.0.0 | 测试框架 |
| pytest-asyncio | >=0.21.0 | 异步测试支持 |
| pytest-cov | >=4.0.0 | 覆盖率报告 |
| ruff | >=0.4.0 | 静态代码检查 |

## 本地部署步骤

### 1. 获取代码

```bash
git clone <仓库地址>
cd weather-app
```

### 2. 创建虚拟环境

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate   # macOS/Linux
# Windows: .venv\Scripts\activate
```

### 3. 安装依赖

```bash
pip install -r requirements.txt
```

### 4. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env` 文件：

```
QWEATHER_API_KEY=你的和风天气API密钥
QWEATHER_API_HOST=k73wt3h522.re.qweatherapi.com
```

环境变量说明：

| 变量名 | 必填 | 默认值 | 说明 |
|--------|------|--------|------|
| QWEATHER_API_KEY | 是 | 无 | 和风天气 API 密钥 |
| QWEATHER_API_HOST | 否 | k73wt3h522.re.qweatherapi.com | 和风天气 API 地址 |

### 5. 启动服务

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

开发模式（自动重载）：

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 6. 验证服务

```bash
# 健康检查（访问 OpenAPI 文档）
curl -s http://localhost:8000/docs | head -1

# 功能验证：城市搜索
curl "http://localhost:8000/api/cities?q=北京"

# 功能验证：天气查询
curl "http://localhost:8000/api/weather?location=101010100"
```

## 运行测试

```bash
cd backend

# 运行全部测试
pytest

# 运行测试并生成覆盖率报告
pytest --cov=app --cov-report=term-missing

# 静态代码检查
ruff check app/
```

## 端口与网络

| 服务 | 默认端口 | 协议 |
|------|----------|------|
| FastAPI 后端 | 8000 | HTTP |

出站网络请求：

| 目标 | 端口 | 说明 |
|------|------|------|
| k73wt3h522.re.qweatherapi.com | 443 (HTTPS) | QWeather API 调用 |

## 日志

FastAPI 默认输出到 stdout，使用 uvicorn 的日志格式。QWeather 服务层在请求异常时通过 Python logging 模块记录警告日志。

查看日志：

```bash
# 前台运行时直接在终端查看
uvicorn app.main:app --host 0.0.0.0 --port 8000

# 重定向日志到文件
uvicorn app.main:app --host 0.0.0.0 --port 8000 2>&1 | tee app.log
```

## 常见问题

### Q: 启动时报 ModuleNotFoundError

确认已激活虚拟环境并安装依赖：

```bash
source .venv/bin/activate
pip install -r requirements.txt
```

### Q: 城市搜索返回空数组

可能原因：
1. 城市名称输入有误
2. QWeather API Key 无效或过期 — 检查 `.env` 文件中的配置

### Q: 返回 502 或 504 错误

上游 QWeather 服务不可用或超时。检查：
1. 网络连接是否正常
2. QWeather API Host 配置是否正确
3. 等待片刻后重试
