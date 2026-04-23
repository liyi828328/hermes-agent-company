"""weather_service 单元测试。"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from unittest.mock import MagicMock, patch
import pytest
from weather_service import (
    CityNotFoundError,
    UpstreamError,
    fetch_weather,
    get_current_weather,
    lookup_city,
)


# --- lookup_city ---

@patch("weather_service.requests.get")
def test_lookup_city_success(mock_get):
    mock_get.return_value = MagicMock(
        status_code=200,
        json=lambda: {"code": "200", "location": [{"id": "101010100"}]},
    )
    assert lookup_city("北京") == "101010100"


@patch("weather_service.requests.get")
def test_lookup_city_not_found(mock_get):
    mock_get.return_value = MagicMock(
        status_code=200,
        json=lambda: {"code": "404", "location": []},
    )
    with pytest.raises(CityNotFoundError):
        lookup_city("不存在的城市")


@patch("weather_service.requests.get")
def test_lookup_city_empty_location(mock_get):
    mock_get.return_value = MagicMock(
        status_code=200,
        json=lambda: {"code": "200", "location": []},
    )
    with pytest.raises(CityNotFoundError):
        lookup_city("xyz")


@patch("weather_service.requests.get")
def test_lookup_city_network_error(mock_get):
    import requests as req
    mock_get.side_effect = req.ConnectionError("fail")
    with pytest.raises(UpstreamError):
        lookup_city("北京")


@patch("weather_service.requests.get")
def test_lookup_city_timeout(mock_get):
    import requests as req
    mock_get.side_effect = req.Timeout("timeout")
    with pytest.raises(UpstreamError):
        lookup_city("北京")


@patch("weather_service.requests.get")
def test_lookup_city_http_error(mock_get):
    import requests as req
    mock_resp = MagicMock()
    mock_resp.raise_for_status.side_effect = req.HTTPError("500")
    mock_get.return_value = mock_resp
    with pytest.raises(UpstreamError):
        lookup_city("北京")


# --- get_current_weather ---

@patch("weather_service.requests.get")
def test_get_current_weather_success(mock_get):
    mock_get.return_value = MagicMock(
        status_code=200,
        json=lambda: {
            "code": "200",
            "now": {"temp": "25", "text": "晴", "windDir": "东北风"},
        },
    )
    result = get_current_weather("101010100")
    assert result == {"temp": "25", "text": "晴", "windDir": "东北风"}


@patch("weather_service.requests.get")
def test_get_current_weather_bad_code(mock_get):
    mock_get.return_value = MagicMock(
        status_code=200,
        json=lambda: {"code": "401", "now": None},
    )
    with pytest.raises(UpstreamError):
        get_current_weather("101010100")


@patch("weather_service.requests.get")
def test_get_current_weather_network_error(mock_get):
    import requests as req
    mock_get.side_effect = req.ConnectionError("fail")
    with pytest.raises(UpstreamError):
        get_current_weather("101010100")


@patch("weather_service.requests.get")
def test_get_current_weather_no_now(mock_get):
    mock_get.return_value = MagicMock(
        status_code=200,
        json=lambda: {"code": "200"},
    )
    with pytest.raises(UpstreamError):
        get_current_weather("101010100")


# --- fetch_weather ---

@patch("weather_service.get_current_weather")
@patch("weather_service.lookup_city")
def test_fetch_weather_success(mock_lookup, mock_weather):
    mock_lookup.return_value = "101010100"
    mock_weather.return_value = {"temp": "25", "text": "晴", "windDir": "东北风"}
    result = fetch_weather("北京")
    assert result == {"city": "北京", "temp": "25", "text": "晴", "windDir": "东北风"}


@patch("weather_service.lookup_city")
def test_fetch_weather_city_not_found(mock_lookup):
    mock_lookup.side_effect = CityNotFoundError("not found")
    with pytest.raises(CityNotFoundError):
        fetch_weather("不存在")


@patch("weather_service.lookup_city")
def test_fetch_weather_upstream_error(mock_lookup):
    mock_lookup.side_effect = UpstreamError("fail")
    with pytest.raises(UpstreamError):
        fetch_weather("北京")
