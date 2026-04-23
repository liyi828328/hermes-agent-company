/**
 * @jest-environment jsdom
 */

// Set up DOM before requiring app.js
beforeEach(() => {
  document.body.innerHTML = `
    <input type="text" id="city-input" />
    <button id="search-btn">搜索</button>
    <div id="error-msg" style="display:none;"></div>
    <div id="weather-card" style="display:none;">
      <h2 id="card-city"></h2>
      <span id="card-temp"></span>
      <span id="card-text"></span>
      <span id="card-wind"></span>
    </div>
  `;
});

// We need to re-require app.js each time since IIFE runs on require
function loadApp() {
  // Clear module cache
  delete require.cache[require.resolve('../app')];
  return require('../app');
}

describe('showWeather', () => {
  test('应正确渲染天气数据', () => {
    const app = loadApp();
    app.showWeather({ city: '北京', temp: '25', text: '晴', windDir: '东北风' });

    expect(document.getElementById('card-city').textContent).toBe('北京');
    expect(document.getElementById('card-temp').textContent).toBe('25℃');
    expect(document.getElementById('card-text').textContent).toBe('晴');
    expect(document.getElementById('card-wind').textContent).toBe('东北风');
    expect(document.getElementById('weather-card').style.display).toBe('block');
    expect(document.getElementById('error-msg').style.display).toBe('none');
  });
});

describe('showError', () => {
  test('应显示错误信息并隐藏天气卡片', () => {
    const app = loadApp();
    app.showError('未找到该城市');

    expect(document.getElementById('error-msg').textContent).toBe('未找到该城市');
    expect(document.getElementById('error-msg').style.display).toBe('block');
    expect(document.getElementById('weather-card').style.display).toBe('none');
  });
});

describe('fetchWeather', () => {
  test('应发送正确的 API 请求并返回结果', async () => {
    const app = loadApp();
    const mockData = { code: 0, data: { city: '北京', temp: '25', text: '晴', windDir: '东北风' } };

    global.fetch = jest.fn().mockResolvedValue({
      status: 200,
      json: () => Promise.resolve(mockData),
    });

    const result = await app.fetchWeather('北京');
    expect(global.fetch).toHaveBeenCalledWith(
      expect.stringContaining('/api/weather?city=%E5%8C%97%E4%BA%AC')
    );
    expect(result.status).toBe(200);
    expect(result.body).toEqual(mockData);
  });

  test('应正确编码城市名称', async () => {
    const app = loadApp();
    global.fetch = jest.fn().mockResolvedValue({
      status: 200,
      json: () => Promise.resolve({}),
    });

    await app.fetchWeather('上海');
    expect(global.fetch).toHaveBeenCalledWith(
      expect.stringContaining('city=%E4%B8%8A%E6%B5%B7')
    );
  });
});

describe('handleSearch', () => {
  test('输入为空时应显示错误', () => {
    const app = loadApp();
    document.getElementById('city-input').value = '';
    app.handleSearch();

    expect(document.getElementById('error-msg').textContent).toBe('请输入城市名称');
    expect(document.getElementById('error-msg').style.display).toBe('block');
  });

  test('输入仅空格时应显示错误', () => {
    const app = loadApp();
    document.getElementById('city-input').value = '   ';
    app.handleSearch();

    expect(document.getElementById('error-msg').textContent).toBe('请输入城市名称');
  });

  test('API 返回 200 时应显示天气', async () => {
    const app = loadApp();
    const mockData = { code: 0, data: { city: '北京', temp: '25', text: '晴', windDir: '东北风' } };

    global.fetch = jest.fn().mockResolvedValue({
      status: 200,
      json: () => Promise.resolve(mockData),
    });

    document.getElementById('city-input').value = '北京';
    app.handleSearch();

    // Wait for async
    await new Promise(r => setTimeout(r, 50));

    expect(document.getElementById('card-city').textContent).toBe('北京');
    expect(document.getElementById('card-temp').textContent).toBe('25℃');
    expect(document.getElementById('search-btn').disabled).toBe(false);
    expect(document.getElementById('search-btn').textContent).toBe('搜索');
  });

  test('API 返回错误时应显示错误信息', async () => {
    const app = loadApp();
    global.fetch = jest.fn().mockResolvedValue({
      status: 404,
      json: () => Promise.resolve({ code: 1002, error: 'CITY_NOT_FOUND', message: '未找到该城市' }),
    });

    document.getElementById('city-input').value = '不存在的城市';
    app.handleSearch();

    await new Promise(r => setTimeout(r, 50));

    expect(document.getElementById('error-msg').textContent).toBe('未找到该城市');
    expect(document.getElementById('error-msg').style.display).toBe('block');
  });

  test('网络错误时应显示网络错误提示', async () => {
    const app = loadApp();
    global.fetch = jest.fn().mockRejectedValue(new Error('Network Error'));

    document.getElementById('city-input').value = '北京';
    app.handleSearch();

    await new Promise(r => setTimeout(r, 50));

    expect(document.getElementById('error-msg').textContent).toBe('网络错误，请检查网络连接');
  });

  test('搜索时按钮应禁用并显示加载状态', () => {
    const app = loadApp();
    global.fetch = jest.fn().mockReturnValue(new Promise(() => {})); // never resolves

    document.getElementById('city-input').value = '北京';
    app.handleSearch();

    expect(document.getElementById('search-btn').disabled).toBe(true);
    expect(document.getElementById('search-btn').textContent).toBe('查询中...');
  });
});

describe('init', () => {
  test('应绑定按钮点击事件', () => {
    const app = loadApp();
    app.init();

    document.getElementById('city-input').value = '';
    document.getElementById('search-btn').click();

    expect(document.getElementById('error-msg').textContent).toBe('请输入城市名称');
  });

  test('应绑定 Enter 键事件', () => {
    const app = loadApp();
    app.init();

    document.getElementById('city-input').value = '';
    const event = new KeyboardEvent('keydown', { key: 'Enter' });
    document.getElementById('city-input').dispatchEvent(event);

    expect(document.getElementById('error-msg').textContent).toBe('请输入城市名称');
  });

  test('非 Enter 键不应触发搜索', () => {
    const app = loadApp();
    app.init();

    const event = new KeyboardEvent('keydown', { key: 'a' });
    document.getElementById('city-input').dispatchEvent(event);

    expect(document.getElementById('error-msg').style.display).toBe('none');
  });
});

describe('API_BASE 配置', () => {
  test('应支持通过 _setApiBase 修改 API base URL', async () => {
    const app = loadApp();
    app._setApiBase('http://custom:8080');

    global.fetch = jest.fn().mockResolvedValue({
      status: 200,
      json: () => Promise.resolve({ code: 0, data: {} }),
    });

    await app.fetchWeather('test');
    expect(global.fetch).toHaveBeenCalledWith(
      expect.stringContaining('http://custom:8080/api/weather')
    );
  });

  test('默认使用 localhost:5000', async () => {
    const app = loadApp();
    app._setApiBase('http://localhost:5000');

    global.fetch = jest.fn().mockResolvedValue({
      status: 200,
      json: () => Promise.resolve({ code: 0, data: {} }),
    });

    await app.fetchWeather('test');
    expect(global.fetch).toHaveBeenCalledWith(
      expect.stringContaining('http://localhost:5000/api/weather')
    );
  });
});
