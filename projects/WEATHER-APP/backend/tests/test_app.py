"""Flask 路由单元测试。"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from unittest.mock import patch
import pytest
from app import app
from weather_service import CityNotFoundError, UpstreamError


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def test_weather_success(client):
    with patch("app.fetch_weather") as mock:
        mock.return_value = {"city": "北京", "temp": "25", "text": "晴", "windDir": "东北风"}
        resp = client.get("/api/weather?city=北京")
        assert resp.status_code == 200
        data = resp.get_json()
        assert data["code"] == 0
        assert data["data"]["city"] == "北京"
        assert data["data"]["temp"] == "25"
        assert data["data"]["text"] == "晴"
        assert data["data"]["windDir"] == "东北风"


def test_weather_missing_city(client):
    resp = client.get("/api/weather")
    assert resp.status_code == 400
    data = resp.get_json()
    assert data["code"] == 1001
    assert data["error"] == "MISSING_CITY"


def test_weather_empty_city(client):
    resp = client.get("/api/weather?city=")
    assert resp.status_code == 400
    data = resp.get_json()
    assert data["code"] == 1001


def test_weather_whitespace_city(client):
    resp = client.get("/api/weather?city=   ")
    assert resp.status_code == 400
    data = resp.get_json()
    assert data["code"] == 1001


def test_weather_city_not_found(client):
    with patch("app.fetch_weather") as mock:
        mock.side_effect = CityNotFoundError("not found")
        resp = client.get("/api/weather?city=不存在的城市")
        assert resp.status_code == 404
        data = resp.get_json()
        assert data["code"] == 1002
        assert data["error"] == "CITY_NOT_FOUND"


def test_weather_upstream_error(client):
    with patch("app.fetch_weather") as mock:
        mock.side_effect = UpstreamError("fail")
        resp = client.get("/api/weather?city=北京")
        assert resp.status_code == 502
        data = resp.get_json()
        assert data["code"] == 1003
        assert data["error"] == "UPSTREAM_ERROR"


def test_weather_internal_error(client):
    with patch("app.fetch_weather") as mock:
        mock.side_effect = RuntimeError("unexpected")
        resp = client.get("/api/weather?city=北京")
        assert resp.status_code == 500
        data = resp.get_json()
        assert data["code"] == 1099
        assert data["error"] == "INTERNAL_ERROR"


def test_response_content_type(client):
    with patch("app.fetch_weather") as mock:
        mock.return_value = {"city": "北京", "temp": "25", "text": "晴", "windDir": "东北风"}
        resp = client.get("/api/weather?city=北京")
        assert resp.content_type == "application/json"
