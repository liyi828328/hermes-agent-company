"""配置管理模块 — 从环境变量读取，提供默认值。"""

import os


class Config:
    QWEATHER_API_KEY: str = os.environ.get("QWEATHER_API_KEY", "")
    QWEATHER_GEO_BASE_URL: str = os.environ.get(
        "QWEATHER_GEO_BASE_URL", "https://geoapi.qweather.com/v2/city/lookup"
    )
    QWEATHER_WEATHER_BASE_URL: str = os.environ.get(
        "QWEATHER_WEATHER_BASE_URL", "https://devapi.qweather.com/v7/weather/now"
    )
    QWEATHER_TIMEOUT: int = int(os.environ.get("QWEATHER_TIMEOUT", "5"))
