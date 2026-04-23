const { escapeHtml, buildWeatherCard, buildErrorMessage, handleApiResponse } = require('./app');

describe('escapeHtml', () => {
  test('转义 HTML 特殊字符', () => {
    expect(escapeHtml('<script>alert("xss")</script>')).toBe(
      '&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;'
    );
  });

  test('普通文本不变', () => {
    expect(escapeHtml('北京')).toBe('北京');
  });

  test('处理非字符串输入', () => {
    expect(escapeHtml(25)).toBe('25');
    expect(escapeHtml(null)).toBe('null');
    expect(escapeHtml(undefined)).toBe('undefined');
  });

  test('转义 & 和单引号', () => {
    expect(escapeHtml("Tom & Jerry's")).toBe('Tom &amp; Jerry&#039;s');
  });

  test('空字符串', () => {
    expect(escapeHtml('')).toBe('');
  });
});

describe('buildWeatherCard', () => {
  test('生成正确的天气卡片 HTML', () => {
    const data = { city: '北京', temp: '25', text: '晴', windDir: '东北风' };
    const html = buildWeatherCard(data);
    expect(html).toContain('class="weather-card"');
    expect(html).toContain('北京');
    expect(html).toContain('25℃');
    expect(html).toContain('天气：晴');
    expect(html).toContain('风向：东北风');
  });

  test('XSS 防护', () => {
    const data = { city: '<img onerror=alert(1)>', temp: '0', text: 'ok', windDir: 'N' };
    const html = buildWeatherCard(data);
    expect(html).not.toContain('<img');
    expect(html).toContain('&lt;img');
  });
});

describe('buildErrorMessage', () => {
  test('生成错误提示 HTML', () => {
    const html = buildErrorMessage('未找到该城市');
    expect(html).toContain('class="error-message"');
    expect(html).toContain('未找到该城市');
  });

  test('XSS 防护', () => {
    const html = buildErrorMessage('<script>alert(1)</script>');
    expect(html).not.toContain('<script>');
  });
});

describe('handleApiResponse', () => {
  test('成功响应渲染天气卡片', () => {
    const json = { code: 0, data: { city: '上海', temp: '30', text: '多云', windDir: '南风' } };
    const html = handleApiResponse(json);
    expect(html).toContain('class="weather-card"');
    expect(html).toContain('上海');
    expect(html).toContain('30℃');
  });

  test('错误响应显示 message', () => {
    const json = { code: 1002, error: 'CITY_NOT_FOUND', message: '未找到该城市' };
    const html = handleApiResponse(json);
    expect(html).toContain('class="error-message"');
    expect(html).toContain('未找到该城市');
  });

  test('错误响应无 message 时显示默认提示', () => {
    const json = { code: 1099 };
    const html = handleApiResponse(json);
    expect(html).toContain('请求失败，请稍后重试');
  });

  test('code 为 0 但无 data 时显示错误', () => {
    const json = { code: 0 };
    const html = handleApiResponse(json);
    expect(html).toContain('class="error-message"');
  });

  test('各种错误码都显示 message', () => {
    expect(handleApiResponse({ code: 1001, message: '缺少 city 参数' })).toContain('缺少 city 参数');
    expect(handleApiResponse({ code: 1003, message: '天气服务暂时不可用' })).toContain('天气服务暂时不可用');
  });
});

// 测试 fetchWeather（需要 mock fetch）
describe('fetchWeather', () => {
  beforeEach(() => {
    global.fetch = jest.fn();
  });

  afterEach(() => {
    delete global.fetch;
  });

  test('成功调用 API 返回 JSON', async () => {
    const mockData = { code: 0, data: { city: '北京', temp: '25', text: '晴', windDir: '东北风' } };
    global.fetch.mockResolvedValue({ json: () => Promise.resolve(mockData) });

    const { fetchWeather, API_BASE } = require('./app');
    const result = await fetchWeather('北京');

    expect(global.fetch).toHaveBeenCalledWith(API_BASE + '/api/weather?city=' + encodeURIComponent('北京'));
    expect(result).toEqual(mockData);
  });

  test('网络错误返回友好提示', async () => {
    global.fetch.mockRejectedValue(new Error('Network error'));

    // 需要重新加载模块以使用新的 fetch mock
    jest.resetModules();
    const { fetchWeather } = require('./app');
    const result = await fetchWeather('北京');

    expect(result).toEqual({ code: -1, message: '网络错误，请检查网络连接' });
  });
});

// 测试 init（需要 mock DOM）
describe('init', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <form id="search-form">
        <input id="city-input" value="" />
        <button id="search-btn">搜索</button>
      </form>
      <section id="result-container"></section>
    `;
    global.fetch = jest.fn();
  });

  afterEach(() => {
    delete global.fetch;
    document.body.innerHTML = '';
  });

  test('提交表单时调用 API 并渲染结果', async () => {
    const mockData = { code: 0, data: { city: '深圳', temp: '32', text: '晴', windDir: '南风' } };
    global.fetch.mockResolvedValue({ json: () => Promise.resolve(mockData) });

    jest.resetModules();
    const { init } = require('./app');
    init();

    const input = document.getElementById('city-input');
    const btn = document.getElementById('search-btn');
    const container = document.getElementById('result-container');
    const form = document.getElementById('search-form');

    input.value = '深圳';
    form.dispatchEvent(new Event('submit'));

    // 等待异步操作
    await new Promise(resolve => setTimeout(resolve, 10));

    expect(container.innerHTML).toContain('深圳');
    expect(container.innerHTML).toContain('32℃');
    expect(btn.disabled).toBe(false);
  });

  test('输入为空时不调用 API', () => {
    jest.resetModules();
    const { init } = require('./app');
    init();

    const form = document.getElementById('search-form');
    const input = document.getElementById('city-input');

    input.value = '   ';
    form.dispatchEvent(new Event('submit'));

    expect(global.fetch).not.toHaveBeenCalled();
  });

  test('提交时显示加载状态', () => {
    global.fetch.mockResolvedValue({ json: () => Promise.resolve({ code: 0, data: { city: 'X', temp: '1', text: 'Y', windDir: 'Z' } }) });

    jest.resetModules();
    const { init } = require('./app');
    init();

    const input = document.getElementById('city-input');
    const btn = document.getElementById('search-btn');
    const container = document.getElementById('result-container');
    const form = document.getElementById('search-form');

    input.value = '北京';
    form.dispatchEvent(new Event('submit'));

    expect(btn.disabled).toBe(true);
    expect(container.innerHTML).toContain('查询中');
  });
});
