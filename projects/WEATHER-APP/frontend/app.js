/**
 * WEATHER-APP 前端逻辑
 * 调用后端 GET /api/weather?city=xxx 并渲染结果
 */

const API_BASE = 'http://localhost:5000';

/**
 * 构建天气卡片 HTML
 * @param {object} data - { city, temp, text, windDir }
 * @returns {string} HTML 字符串
 */
function buildWeatherCard(data) {
  return (
    '<div class="weather-card">' +
      '<div class="city-name">' + escapeHtml(data.city) + '</div>' +
      '<div class="temp">' + escapeHtml(data.temp) + '℃</div>' +
      '<div class="detail">天气：' + escapeHtml(data.text) + '</div>' +
      '<div class="detail">风向：' + escapeHtml(data.windDir) + '</div>' +
    '</div>'
  );
}

/**
 * 构建错误提示 HTML
 * @param {string} message - 错误信息
 * @returns {string} HTML 字符串
 */
function buildErrorMessage(message) {
  return '<div class="error-message">' + escapeHtml(message) + '</div>';
}

/**
 * 转义 HTML 特殊字符，防止 XSS
 * @param {string} str
 * @returns {string}
 */
function escapeHtml(str) {
  if (typeof str !== 'string') {
    str = String(str);
  }
  var map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;'
  };
  return str.replace(/[&<>"']/g, function(c) { return map[c]; });
}

/**
 * 处理 API 响应数据，返回渲染用 HTML
 * @param {object} json - API 响应 JSON
 * @returns {string} HTML 字符串
 */
function handleApiResponse(json) {
  if (json.code === 0 && json.data) {
    return buildWeatherCard(json.data);
  }
  return buildErrorMessage(json.message || '请求失败，请稍后重试');
}

/**
 * 调用后端天气 API
 * @param {string} city - 城市名
 * @returns {Promise<object>} API 响应 JSON
 */
function fetchWeather(city) {
  var url = API_BASE + '/api/weather?city=' + encodeURIComponent(city);
  return fetch(url)
    .then(function(res) { return res.json(); })
    .catch(function() {
      return { code: -1, message: '网络错误，请检查网络连接' };
    });
}

/**
 * 初始化页面事件绑定
 */
function init() {
  var form = document.getElementById('search-form');
  var input = document.getElementById('city-input');
  var btn = document.getElementById('search-btn');
  var container = document.getElementById('result-container');

  form.addEventListener('submit', function(e) {
    e.preventDefault();
    var city = input.value.trim();
    if (!city) return;

    btn.disabled = true;
    container.innerHTML = '<div class="loading">查询中...</div>';

    fetchWeather(city).then(function(json) {
      container.innerHTML = handleApiResponse(json);
      btn.disabled = false;
    });
  });
}

// DOM 加载完成后初始化
if (typeof document !== 'undefined') {
  document.addEventListener('DOMContentLoaded', init);
}

// 导出纯函数供测试使用
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { escapeHtml, buildWeatherCard, buildErrorMessage, handleApiResponse, fetchWeather, init, API_BASE };
}
