/**
 * Termux Chromium 爬虫模板
 * 改进版：更完善的错误处理和依赖检测
 * 
 * 使用方法：
 *   node crawler.js <URL> [options]
 * 
 * 示例：
 *   node crawler.js https://example.com
 *   node crawler.js https://example.com --screenshot=output.png
 *   node crawler.js https://example.com --output=data.json
 */

// ===== 必须在最开头加载 monkey patch =====
require('./monkey-patch');

const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');

// ===== 配置 =====
const CONFIG = {
  // Chromium 路径（根据实际安装位置调整）
  chromiumPath: process.env.CHROMIUM_PATH || 
                process.env.CHROME_BIN || 
                '/root/crawler/chromium/chrome',
  
  // 备用路径
  fallbackPaths: [
    '/root/crawler/chromium/chrome',
    '/root/crawler/chromium/chromium',
    './chromium/chrome',
    './chromium/chromium'
  ],
  
  // 默认超时
  timeout: 30000,
  
  // 输出目录
  outputDir: process.env.OUTPUT_DIR || './output',
  
  // User-Agent
  userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
  
  // 视口大小
  viewport: {
    width: 393,
    height: 851
  }
};

// ===== 浏览器启动参数 =====
const BROWSER_ARGS = [
  '--no-sandbox',                    // Android/proot 必需
  '--disable-setuid-sandbox',        // Android/proot 必需
  '--disable-gpu',                   // 无 GPU 环境
  '--disable-dev-shm-usage',         // 避免 /dev/shm 问题
  '--disable-software-rasterizer',   // 避免软件渲染问题
  '--disable-background-networking',
  '--disable-default-apps',
  '--disable-extensions',
  '--disable-sync',
  '--metrics-recording-only',
  '--mute-audio',
  '--no-first-run',
  '--safebrowsing-disable-auto-update',
  '--enable-automation=false',       // 隐藏自动化标志
  '--password-store=basic',
  '--use-mock-keychain',
  '--disable-blink-features=AutomationControlled'  // 隐藏自动化特征
];

// ===== 反检测脚本 =====
const STEALTH_SCRIPT = `
// 隐藏 webdriver 标志
Object.defineProperty(navigator, 'webdriver', {
  get: () => undefined,
  configurable: true
});

// 伪装 plugins
Object.defineProperty(navigator, 'plugins', {
  get: () => [1, 2, 3, 4, 5],
  configurable: true
});

// 伪装 languages
Object.defineProperty(navigator, 'languages', {
  get: () => ['zh-CN', 'zh', 'en'],
  configurable: true
});

// 添加 chrome 对象
window.chrome = {
  runtime: {},
  loadTimes: function() {},
  csi: function() {},
  app: {}
};

// 隐藏自动化标志
const originalQuery = window.navigator.permissions.query;
window.navigator.permissions.query = (parameters) => (
  parameters.name === 'notifications' ?
    Promise.resolve({ state: Notification.permission }) :
    originalQuery(parameters)
);
`;

// ===== 辅助函数 =====

// 查找 Chromium 可执行文件
function findChromium() {
  // 先检查配置路径
  if (fs.existsSync(CONFIG.chromiumPath)) {
    return CONFIG.chromiumPath;
  }
  
  // 检查备用路径
  for (const fallbackPath of CONFIG.fallbackPaths) {
    if (fs.existsSync(fallbackPath)) {
      console.log(`[信息] 使用备用 Chromium 路径: ${fallbackPath}`);
      return fallbackPath;
    }
  }
  
  return null;
}

// 检查依赖库
async function checkDependencies() {
  const { exec } = require('child_process');
  
  return new Promise((resolve) => {
    exec('ldd --version 2>&1', (error, stdout) => {
      if (error) {
        console.log('[警告] 无法检查 glibc 版本');
      } else {
        console.log(`[信息] ${stdout.split('\n')[0]}`);
      }
      resolve();
    });
  });
}

// ===== 主函数 =====
async function main() {
  // 解析命令行参数
  const args = process.argv.slice(2);
  const url = args.find(a => !a.startsWith('--')) || 'https://example.com';
  
  const screenshotArg = args.find(a => a.startsWith('--screenshot='));
  const screenshotPath = screenshotArg ? screenshotArg.split('=')[1] : null;
  
  const outputArg = args.find(a => a.startsWith('--output='));
  const outputPath = outputArg ? outputArg.split('=')[1] : 'data.json';
  
  const headless = !args.includes('--headful');
  const verbose = args.includes('--verbose') || args.includes('-v');
  
  console.log('='.repeat(50));
  console.log('Termux Chromium Crawler');
  console.log('='.repeat(50));
  console.log(`URL: ${url}`);
  console.log(`Headless: ${headless}`);
  console.log('='.repeat(50));
  
  // 检查 Chromium
  const chromiumPath = findChromium();
  if (!chromiumPath) {
    console.error('[错误] 未找到 Chromium 可执行文件');
    console.error(`请设置 CHROMIUM_PATH 环境变量或确保 Chromium 位于:`);
    CONFIG.fallbackPaths.forEach(p => console.error(`  - ${p}`));
    process.exit(1);
  }
  console.log(`[信息] Chromium: ${chromiumPath}`);
  
  // 检查依赖
  if (verbose) {
    await checkDependencies();
  }
  
  let browser = null;
  
  try {
    // 启动浏览器
    console.log('[启动] 正在启动 Chromium...');
    
    const launchOptions = {
      executablePath: chromiumPath,
      headless: headless ? 'new' : false,
      args: BROWSER_ARGS,
      ignoreDefaultArgs: ['--enable-automation'],
      defaultViewport: CONFIG.viewport,
      timeout: CONFIG.timeout
    };
    
    if (verbose) {
      console.log('[调试] 启动参数:', JSON.stringify(launchOptions, null, 2));
    }
    
    browser = await puppeteer.launch(launchOptions);
    
    console.log('[启动] Chromium 启动成功');
    
    // 创建页面
    const page = await browser.newPage();
    
    // 注入反检测脚本
    await page.evaluateOnNewDocument(STEALTH_SCRIPT);
    
    // 设置 User-Agent
    await page.setUserAgent(CONFIG.userAgent);
    
    // 设置额外 HTTP 头
    await page.setExtraHTTPHeaders({
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8'
    });
    
    // 访问页面
    console.log(`[访问] 正在访问: ${url}`);
    
    const response = await page.goto(url, {
      waitUntil: 'networkidle2',
      timeout: CONFIG.timeout
    });
    
    if (!response) {
      throw new Error('页面加载失败：无响应');
    }
    
    console.log(`[访问] 页面加载完成 (状态码: ${response.status()})`);
    
    // 检测是否被重定向
    const finalUrl = page.url();
    if (finalUrl !== url) {
      console.log(`[信息] 重定向到: ${finalUrl}`);
    }
    
    // ===== 提取数据 =====
    console.log('[提取] 正在提取数据...');
    
    const data = await page.evaluate(() => {
      // 提取页面标题
      const title = document.title;
      
      // 提取所有链接
      const links = Array.from(document.querySelectorAll('a[href]')).map(a => ({
        href: a.href,
        text: a.textContent.trim().slice(0, 100)
      })).filter(l => l.href && !l.href.startsWith('javascript:'));
      
      // 提取所有图片
      const images = Array.from(document.querySelectorAll('img[src]')).map(img => ({
        src: img.src,
        alt: img.alt || ''
      }));
      
      // 提取页面文本
      const text = document.body.innerText.slice(0, 5000);
      
      // 提取 meta 信息
      const meta = {
        description: document.querySelector('meta[name="description"]')?.content || '',
        keywords: document.querySelector('meta[name="keywords"]')?.content || '',
        author: document.querySelector('meta[name="author"]')?.content || ''
      };
      
      // 检测可能的反爬标志
      const hasCaptcha = !!document.querySelector('[class*="captcha"], [id*="captcha"]');
      const hasLogin = !!document.querySelector('form[action*="login"], [class*="login"]');
      
      return { 
        title, 
        links, 
        images, 
        text, 
        meta,
        warnings: { hasCaptcha, hasLogin }
      };
    });
    
    // 警告检测
    if (data.warnings.hasCaptcha) {
      console.log('[警告] 页面可能包含验证码');
    }
    if (data.warnings.hasLogin) {
      console.log('[信息] 页面包含登录表单');
    }
    
    console.log(`[提取] 提取完成: ${data.links.length} 个链接, ${data.images.length} 个图片`);
    
    // ===== 截图 =====
    if (screenshotPath) {
      console.log(`[截图] 正在保存截图: ${screenshotPath}`);
      
      // 确保输出目录存在
      const screenshotDir = path.dirname(screenshotPath);
      if (screenshotDir && !fs.existsSync(screenshotDir)) {
        fs.mkdirSync(screenshotDir, { recursive: true });
      }
      
      await page.screenshot({
        path: screenshotPath,
        fullPage: true
      });
      console.log('[截图] 截图保存成功');
    }
    
    // ===== 保存数据 =====
    const result = {
      url,
      finalUrl,
      timestamp: new Date().toISOString(),
      statusCode: response.status(),
      ...data
    };
    
    // 删除警告字段（不需要保存）
    delete result.warnings;
    
    // 确保输出目录存在
    if (!fs.existsSync(CONFIG.outputDir)) {
      fs.mkdirSync(CONFIG.outputDir, { recursive: true });
    }
    
    const finalOutputPath = path.join(CONFIG.outputDir, outputPath);
    fs.writeFileSync(finalOutputPath, JSON.stringify(result, null, 2));
    console.log(`[保存] 数据已保存到: ${finalOutputPath}`);
    
    // 打印摘要
    console.log('\n' + '='.repeat(50));
    console.log('摘要');
    console.log('='.repeat(50));
    console.log(`标题: ${data.title}`);
    console.log(`链接数: ${data.links.length}`);
    console.log(`图片数: ${data.images.length}`);
    console.log(`文本长度: ${data.text.length} 字符`);
    console.log('='.repeat(50));
    
    return result;
    
  } catch (error) {
    console.error('[错误]', error.message);
    
    // 提供更详细的错误信息
    if (error.message.includes('Failed to launch')) {
      console.error('\n可能的原因:');
      console.error('1. Chromium 未正确安装');
      console.error('2. 缺少系统依赖库');
      console.error('3. /dev/shm 不可用');
      console.error('\n请确保已安装依赖:');
      console.error('  apt install -y libnss3 libnspr4 libatk1.0-0 ...');
    } else if (error.message.includes('net::ERR')) {
      console.error('\n网络错误，请检查:');
      console.error('1. 网络连接是否正常');
      console.error('2. 目标网站是否可访问');
    } else if (error.message.includes('timeout')) {
      console.error('\n超时错误，请尝试:');
      console.error('1. 增加超时时间');
      console.error('2. 检查网络速度');
    }
    
    throw error;
  } finally {
    // 关闭浏览器
    if (browser) {
      console.log('[关闭] 正在关闭 Chromium...');
      try {
        await browser.close();
        console.log('[关闭] Chromium 已关闭');
      } catch (e) {
        console.log('[警告] 浏览器关闭时出错:', e.message);
      }
    }
  }
}

// 运行
main().catch(error => {
  console.error('\n执行失败:', error.message);
  process.exit(1);
});
