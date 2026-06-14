/**
 * Termux/Android Platform Monkey Patch
 * 
 * 伪装 process.platform 为 'linux'，绕过 puppeteer-core/playwright-core 的平台检测
 * 
 * 使用方法：
 * 在脚本最开头引入：
 *   require('./monkey-patch');
 *   const puppeteer = require('puppeteer-core');
 */

// 保存原始 platform
const originalPlatform = process.platform;

// 伪装 platform 为 linux
Object.defineProperty(process, 'platform', {
  get: () => 'linux',
  configurable: true
});

// 保存原始 arch
const originalArch = process.arch;

// 添加一些可能有用的伪装
if (!process.env.CHROME_BIN) {
  // 默认 Chromium 路径
  process.env.CHROME_BIN = process.env.CHROME_BIN || '/root/crawler/chromium/chrome';
}

console.log(`[Monkey Patch] Platform: ${originalPlatform} -> linux`);
console.log(`[Monkey Patch] Arch: ${originalArch}`);

// 导出恢复函数（如果需要）
module.exports = {
  restore: () => {
    Object.defineProperty(process, 'platform', {
      get: () => originalPlatform,
      configurable: true
    });
    console.log('[Monkey Patch] Restored original platform');
  },
  originalPlatform,
  originalArch
};
