/**
 * Termux Chromium 爬虫模板
 * 
 * 使用修改后的 puppeteer-core 在 Termux proot 环境中运行无头浏览器
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
  chromiumPath: process.env.CHROMIUM_PATH || '/root/crawler/chromium/chrome',
  
  // 默认超时
  timeout: 30000,
  
  // 输出目录
  outputDir: './output',
  
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
  '--use-mock-keychain'
];

// ===== 反检测脚本 =====
const STEALTH_SCRIPT = `
// 隐藏 webdriver 标志
Object.defineProperty(navigator, 'webdriver', {
  get: () => undefined
});

// 伪装 plugins
Object.defineProperty(navigator, 'plugins', {
  get: () => [1, 2, 3, 4, 5]
});

// 伪装 languages
Object.defineProperty(navigator, 'languages', {
  get: () => ['zh-CN', 'zh', 'en']
});

// 添加 chrome 对象
window.chrome = {
  runtime: {},
  loadTimes: function() {},
  csi: function() {},
  app: {}
};

// 隐藏自动化标志
Object.defineProperty(navigator, 'permissions', {
  get: () => ({
    query: () => Promise.resolve({ state: 'granted' })
  })
});
`;

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
  
  console.log('='.repeat(50));
  console.log('Termux Chromium Crawler');
  console.log('='.repeat(50));
  console.log(`URL: ${url}`);
  console.log(`Headless: ${headless}`);
  console.log(`Chromium: ${CONFIG.chromiumPath}`);
  console.log('='.repeat(50));
  
  let browser = null;
  
  try {
    // 启动浏览器
    console.log('[启动] 正在启动 Chromium...');
    browser = await puppeteer.launch({
      executablePath: CONFIG.chromiumPath,
      headless: headless ? 'new' : false,
      args: BROWSER_ARGS,
      ignoreDefaultArgs: ['--enable-automation'],
      defaultViewport: CONFIG.viewport,
      timeout: CONFIG.timeout
    });
    
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
    await page.goto(url, {
      waitUntil: 'networkidle2',
      timeout: CONFIG.timeout
    });
    
    console.log('[访问] 页面加载完成');
    
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
      
      return { title, links, images, text, meta };
    });
    
    console.log(`[提取] 提取完成: ${data.links.length} 个链接, ${data.images.length} 个图片`);
    
    // ===== 截图 =====
    if (screenshotPath) {
      console.log(`[截图] 正在保存截图: ${screenshotPath}`);
      await page.screenshot({
        path: screenshotPath,
        fullPage: true
      });
      console.log('[截图] 截图保存成功');
    }
    
    // ===== 保存数据 =====
    const result = {
      url,
      timestamp: new Date().toISOString(),
      ...data
    };
    
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
    throw error;
  } finally {
    // 关闭浏览器
    if (browser) {
      console.log('[关闭] 正在关闭 Chromium...');
      await browser.close();
      console.log('[关闭] Chromium 已关闭');
    }
  }
}

// 运行
main().catch(error => {
  console.error('执行失败:', error);
  process.exit(1);
});
