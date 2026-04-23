"""Flask 主应用 — /api/weather 路由。"""

import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from weather_service import CityNotFoundError, UpstreamError, fetch_weather

app = Flask(__name__)
CORS(app)


@app.route("/api/weather", methods=["GET"])
def get_weather():
    city = request.args.get("city", "").strip()
    if not city:
        return jsonify({"code": 1001, "error": "MISSING_CITY", "message": "缺少 city 参数"}), 400

    try:
        data = fetch_weather(city)
        return jsonify({"code": 0, "data": data})
    except CityNotFoundError:
        return jsonify({"code": 1002, "error": "CITY_NOT_FOUND", "message": "未找到该城市"}), 404
    except UpstreamError:
        return jsonify({"code": 1003, "error": "UPSTREAM_ERROR", "message": "天气服务暂时不可用"}), 502
    except Exception:
        return jsonify({"code": 1099, "error": "INTERNAL_ERROR", "message": "服务器内部错误"}), 500


if __name__ == "__main__":
    app.run(debug=os.environ.get("FLASK_DEBUG", "false").lower() == "true", port=5000)
