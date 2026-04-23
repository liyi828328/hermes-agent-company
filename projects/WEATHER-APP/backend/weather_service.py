"""封装和风天气 API 调用逻辑。"""

import requests
from config import Config


class CityNotFoundError(Exception):
    """城市未找到。"""


class UpstreamError(Exception):
    """上游 API 调用失败。"""


def lookup_city(city_name: str) -> str:
    """通过 GeoAPI 查找城市，返回 location ID。"""
    try:
        resp = requests.get(
            Config.QWEATHER_GEO_BASE_URL,
            params={"location": city_name, "key": Config.QWEATHER_API_KEY},
            timeout=Config.QWEATHER_TIMEOUT,
        )
        resp.raise_for_status()
        data = resp.json()
    except (requests.RequestException, ValueError) as exc:
        raise UpstreamError(str(exc)) from exc

    if data.get("code") != "200" or not data.get("location"):
        raise CityNotFoundError(f"未找到城市: {city_name}")

    return data["location"][0]["id"]


def get_current_weather(location_id: str) -> dict:
    """获取实时天气数据。"""
    try:
        resp = requests.get(
            Config.QWEATHER_WEATHER_BASE_URL,
            params={"location": location_id, "key": Config.QWEATHER_API_KEY},
            timeout=Config.QWEATHER_TIMEOUT,
        )
        resp.raise_for_status()
        data = resp.json()
    except (requests.RequestException, ValueError) as exc:
        raise UpstreamError(str(exc)) from exc

    if data.get("code") != "200" or not data.get("now"):
        raise UpstreamError(f"天气 API 返回异常: code={data.get('code')}")

    now = data["now"]
    return {
        "temp": now["temp"],
        "text": now["text"],
        "windDir": now["windDir"],
    }


def fetch_weather(city_name: str) -> dict:
    """完整流程：城市查找 + 获取天气。返回格式化数据。"""
    location_id = lookup_city(city_name)
    weather = get_current_weather(location_id)
    weather["city"] = city_name
    return weather
