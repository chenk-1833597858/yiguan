/**
 * 需要登录的网站爬虫模板
 * 
 * 支持保存和加载 cookies，避免重复登录
 * 
 * 使用方法：
 *   # 首次登录（手动）
 *   node login-crawler.js --login --site=example.com
 *   
 *   # 之后自动使用 cookies
 *   node login-crawler.js https://example.com/dashboard
 */

require('./monkey-patch');

const puppeteer = require('puppeteer-core');
const fs = require('fs');
const path = require('path');

const CONFIG = {
  chromiumPath: process.env.CHROMIUM_PATH || '/root/crawler/chromium/chrome',
  cookiesDir: './cookies',
  timeout: 60000,
  userAgent: 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36'
};

const BROWSER_ARGS = [
  '--no-sandbox',
  '--disable-setuid-sandbox',
  '--disable-gpu',
  '--disable-dev-shm-usage'
];

const STEALTH_SCRIPT = `
Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
window.chrome = { runtime: {} };
`;

// 获取 cookies 文件路径
function getCookiesPath(site) {
  return path.join(CONFIG.cookiesDir, `${site}.json`);
}

// 保存 cookies
async function saveCookies(page, site) {
  const cookies = await page.cookies();
  const filePath = getCookiesPath(site);
  
  if (!fs.existsSync(CONFIG.cookiesDir)) {
    fs.mkdirSync(CONFIG.cookiesDir, { recursive: true });
  }
  
  fs.writeFileSync(filePath, JSON.stringify(cookies, null, 2));
  console.log(`[Cookies] 已保存到: ${filePath}`);
}

// 加载 cookies
async function loadCookies(page, site) {
  const filePath = getCookiesPath(site);
  
  if (!fs.existsSync(filePath)) {
    console.log(`[Cookies] 未找到 cookies 文件: ${filePath}`);
    return false;
  }
  
  const cookies = JSON.parse(fs.readFileSync(filePath));
  await page.setCookie(...cookies);
  console.log(`[Cookies] 已加载: ${filePath}`);
  return true;
}

// 主函数
async function main() {
  const args = process.argv.slice(2);
  
  // 解析参数
  const needLogin = args.includes('--login');
  const siteArg = args.find(a => a.startsWith('--site='));
  const site = siteArg ? siteArg.split('=')[1] : 'default';
  const url = args.find(a => !a.startsWith('--')) || `https://${site}.com`;
  
  console.log('='.repeat(50));
  console.log('登录爬虫');
  console.log('='.repeat(50));
  console.log(`站点: ${site}`);
  console.log(`URL: ${url}`);
  console.log(`登录模式: ${needLogin}`);
  console.log('='.repeat(50));
  
  const browser = await puppeteer.launch({
    executablePath: CONFIG.chromiumPath,
    headless: false,  // 登录时需要看到界面（可选）
    args: BROWSER_ARGS
  });
  
  try {
    const page = await browser.newPage();
    await page.evaluateOnNewDocument(STEALTH_SCRIPT);
    await page.setUserAgent(CONFIG.userAgent);
    
    // 加载已有的 cookies
    const hasCookies = await loadCookies(page, site);
    
    // 访问页面
    await page.goto(url, { waitUntil: 'networkidle2', timeout: CONFIG.timeout });
    
    // 检查是否已登录
    const isLoggedIn = await checkLoginStatus(page, site);
    
    if (!isLoggedIn && !needLogin) {
      console.log('[登录] 未登录，请先运行登录模式');
      console.log('[登录] 命令: node login-crawler.js --login --site=' + site);
      return;
    }
    
    if (needLogin && !isLoggedIn) {
      console.log('[登录] 请在浏览器中手动登录...');
      console.log('[登录] 登录完成后按 Enter 继续');
      
      // 等待用户确认
      await waitForUserInput();
      
      // 保存 cookies
      await saveCookies(page, site);
      console.log('[登录] 登录完成，cookies 已保存');
    }
    
    // 如果是正常爬取模式
    if (!needLogin) {
      console.log('[爬取] 开始提取数据...');
      
      // 等待页面稳定
      await page.waitForTimeout(2000);
      
      // 提取数据
      const data = await page.evaluate(() => {
        return {
          title: document.title,
          url: window.location.href,
          content: document.body.innerText.slice(0, 10000)
        };
      });
      
      console.log('[爬取] 数据提取完成');
      console.log(JSON.stringify(data, null, 2));
      
      // 保存结果
      fs.writeFileSync('./output.json', JSON.stringify(data, null, 2));
    }
    
  } finally {
    await browser.close();
  }
}

// 检查登录状态（需要根据具体网站调整）
async function checkLoginStatus(page, site) {
  // 这里需要根据不同网站定制
  // 示例：检查是否存在登录用户名元素
  
  try {
    // 常见的登录状态指示器
    const indicators = [
      '.user-name',
      '.username',
      '.logged-in',
      '[data-testid="user-avatar"]',
      'nav .user'
    ];
    
    for (const selector of indicators) {
      const element = await page.$(selector);
      if (element) {
        return true;
      }
    }
    
    return false;
  } catch {
    return false;
  }
}

// 等待用户输入
function waitForUserInput() {
  return new Promise(resolve => {
    process.stdin.once('data', () => {
      resolve();
    });
  });
}

main().catch(console.error);