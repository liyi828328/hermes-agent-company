/**
 * 天气查询前端逻辑
 * 调用后端 API 获取天气数据并渲染到页面
 */

(function () {
  'use strict';

  // 后端 API 基础地址，可通过全局变量 WEATHER_API_BASE 配置
  var API_BASE = (typeof window !== 'undefined' && window.WEATHER_API_BASE) || 'http://localhost:5000';

  /**
   * 获取天气数据
   * @param {string} city - 城市名称
   * @returns {Promise<Object>} API 响应数据
   */
  function fetchWeather(city) {
    var url = API_BASE + '/api/weather?city=' + encodeURIComponent(city);
    return fetch(url)
      .then(function (response) {
        return response.json().then(function (data) {
          return { status: response.status, body: data };
        });
      });
  }

  /**
   * 显示天气卡片
   * @param {Object} data - 天气数据 { city, temp, text, windDir }
   */
  function showWeather(data) {
    var card = document.getElementById('weather-card');
    var errorMsg = document.getElementById('error-msg');

    errorMsg.style.display = 'none';

    document.getElementById('card-city').textContent = data.city;
    document.getElementById('card-temp').textContent = data.temp + '℃';
    document.getElementById('card-text').textContent = data.text;
    document.getElementById('card-wind').textContent = data.windDir;

    card.style.display = 'block';
  }

  /**
   * 显示错误信息
   * @param {string} message - 错误信息
   */
  function showError(message) {
    var card = document.getElementById('weather-card');
    var errorMsg = document.getElementById('error-msg');

    card.style.display = 'none';
    errorMsg.textContent = message;
    errorMsg.style.display = 'block';
  }

  /**
   * 处理搜索事件
   */
  function handleSearch() {
    var input = document.getElementById('city-input');
    var city = input.value.trim();

    if (!city) {
      showError('请输入城市名称');
      return;
    }

    // 显示加载状态
    var btn = document.getElementById('search-btn');
    btn.disabled = true;
    btn.textContent = '查询中...';

    fetchWeather(city)
      .then(function (result) {
        if (result.status === 200 && result.body.code === 0) {
          showWeather(result.body.data);
        } else {
          var msg = (result.body && result.body.message) || '查询失败，请稍后重试';
          showError(msg);
        }
      })
      .catch(function () {
        showError('网络错误，请检查网络连接');
      })
      .finally(function () {
        btn.disabled = false;
        btn.textContent = '搜索';
      });
  }

  // 初始化事件绑定
  function init() {
    var btn = document.getElementById('search-btn');
    var input = document.getElementById('city-input');

    btn.addEventListener('click', handleSearch);
    input.addEventListener('keydown', function (e) {
      if (e.key === 'Enter') {
        handleSearch();
      }
    });
  }

  // 导出供测试使用
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = { fetchWeather: fetchWeather, showWeather: showWeather, showError: showError, handleSearch: handleSearch, init: init, _setApiBase: function (base) { API_BASE = base; } };
  }

  // 浏览器环境下自动初始化
  if (typeof document !== 'undefined' && document.addEventListener) {
    document.addEventListener('DOMContentLoaded', init);
  }
})();
