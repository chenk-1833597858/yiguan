# Termux Chromium 爬虫

在 Termux proot 环境中运行无头 Chromium 浏览器，用于网页爬取。

## 特性

- ✅ 支持 ARM64 Android 设备
- ✅ 绕过 puppeteer-core 的 Android 平台限制
- ✅ 内置反检测脚本（隐藏 webdriver 标志）
- ✅ 支持登录网站爬取（保存/加载 cookies）
- ✅ 支持截图和数据提取

## 快速开始

### 1. 在 Termux 中安装基础环境

```bash
# 安装依赖
pkg install proot proot-distro nodejs

# 安装 Ubuntu
proot-distro install ubuntu
```

### 2. 从 GitHub Releases 下载编译产物

从 [Releases](https://github.com/chenk-1833597858/yiguan/releases) 页面下载 `termux-crawler-dist.tar.gz`。

### 3. 解压并安装

```bash
# 解压
mkdir -p ~/crawler
tar -xzf termux-crawler-dist.tar.gz -C ~/crawler --strip-components=1

# 进入 proot 环境
proot-distro login ubuntu

# 在 proot 中安装 Node.js 依赖
cd ~/crawler
npm install puppeteer-core
```

### 4. 运行爬虫

```bash
# 在 proot Ubuntu 中
export CHROMIUM_PATH=/root/crawler/chromium/chrome
node crawler.js https://example.com
```

## 文件说明

```
yiguan/
├── .github/workflows/
│   └── build.yaml           # GitHub Actions 构建脚本
├── src/
│   ├── crawler.js           # 主爬虫脚本
│   ├── login-crawler.js     # 需要登录的网站爬虫
│   └── monkey-patch.js      # 平台伪装脚本
├── scripts/
│   ├── install-termux.sh    # Termux 安装脚本
│   └── run-crawler.sh       # 运行脚本
└── README.md
```

## 使用示例

### 基础爬取

```bash
node crawler.js https://example.com
```

### 截图

```bash
node crawler.js https://example.com --screenshot=screenshot.png
```

### 指定输出文件

```bash
node crawler.js https://example.com --output=my-data.json
```

### 需要登录的网站

```bash
# 首次登录（手动完成登录）
node login-crawler.js --login --site=github.com

# 之后自动使用 cookies
node login-crawler.js https://github.com/dashboard
```

## 爬虫 API

```javascript
const crawler = require('./crawler');

// 自定义爬取
const result = await crawler.crawl('https://example.com', {
  screenshot: 'output.png',
  output: 'data.json',
  timeout: 30000
});
```

## 配置选项

在 `crawler.js` 中可以修改以下配置：

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `chromiumPath` | Chromium 可执行文件路径 | `/root/crawler/chromium/chrome` |
| `timeout` | 超时时间（毫秒） | 30000 |
| `userAgent` | User-Agent | Android Chrome UA |
| `viewport` | 视口大小 | 393x851 |

## 常见问题

### 1. Chromium 启动失败

确保添加了 `--no-sandbox` 参数（已在脚本中默认添加）。

### 2. 共享内存错误

```bash
# 手动挂载 /dev/shm
mount -t tmpfs tmpfs /dev/shm
```

### 3. 缺少依赖库

在 proot Ubuntu 中安装：

```bash
apt install -y libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 \
    libxfixes3 libxrandr2 libgbm1 libasound2 libpango-1.0-0 \
    libcairo2 libatspi2.0-0
```

## 自行编译

### 触发 GitHub Actions

1. 进入仓库的 Actions 页面
2. 选择 "Build Termux Chromium Crawler"
3. 点击 "Run workflow"

### 手动编译

```bash
# 克隆仓库
git clone https://github.com/chenk-1833597858/yiguan.git
cd yiguan

# 下载 Chromium
wget https://commondatastorage.googleapis.com/chromium-browser-snapshots/Linux_ARM64/LAST_CHANGE
VERSION=$(cat LAST_CHANGE)
wget "https://commondatastorage.googleapis.com/chromium-browser-snapshots/Linux_ARM64/${VERSION}/chrome-linux.zip"
unzip chrome-linux.zip

# 修改 puppeteer-core
git clone https://github.com/puppeteer/puppeteer.git
# ... 应用补丁
```

## 许可证

MIT License

## 致谢

- [Puppeteer](https://github.com/puppeteer/puppeteer)
- [Chromium](https://www.chromium.org/)
