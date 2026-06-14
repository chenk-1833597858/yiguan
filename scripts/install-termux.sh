#!/bin/bash

# ============================================
# Termux Chromium 爬虫安装脚本
# 改进版：更完善的依赖处理
# ============================================

set -e

echo "============================================"
echo "  Termux Chromium 爬虫安装脚本"
echo "============================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
CRAWLER_DIR="${HOME}/crawler"
DIST_FILE="${HOME}/termux-crawler-dist.tar.gz"
UBUNTU_MIRROR="http://ports.ubuntu.com/ubuntu-ports"

# ===== 步骤 1: 检查环境 =====
echo -e "${YELLOW}[步骤 1/7] 检查环境...${NC}"

if [ ! -d "/data/data/com.termux" ]; then
    echo -e "${RED}错误: 此脚本必须在 Termux 中运行${NC}"
    exit 1
fi

# 检测架构
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    echo -e "${YELLOW}警告: 当前架构为 $ARCH，此爬虫针对 ARM64 优化${NC}"
fi

echo -e "${GREEN}✓ Termux 环境检测通过 (架构: $ARCH)${NC}"

# ===== 步骤 2: 安装基础依赖 =====
echo -e "${YELLOW}[步骤 2/7] 安装基础依赖...${NC}"

pkg update -y 2>/dev/null || {
    echo -e "${YELLOW}尝试更换镜像源...${NC}"
    termux-change-repo
    pkg update -y
}

pkg install -y proot proot-distro nodejs wget curl

echo -e "${GREEN}✓ 基础依赖安装完成${NC}"

# ===== 步骤 3: 安装 Ubuntu proot 环境 =====
echo -e "${YELLOW}[步骤 3/7] 安装 Ubuntu proot 环境...${NC}"

if proot-distro list | grep -q "ubuntu.*installed"; then
    echo -e "${GREEN}✓ Ubuntu 已安装${NC}"
else
    echo -e "${BLUE}正在安装 Ubuntu...${NC}"
    proot-distro install ubuntu
    echo -e "${GREEN}✓ Ubuntu 安装完成${NC}"
fi

# ===== 步骤 4: 配置 proot Ubuntu 环境 =====
echo -e "${YELLOW}[步骤 4/7] 配置 proot Ubuntu 环境...${NC}"

# 在 proot 中配置环境
proot-distro login ubuntu -- bash -c '
set -e

echo "更新软件源..."
apt update -y

echo "安装 Chromium 依赖库..."
# Chromium 核心依赖
apt install -y \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    libatspi2.0-0 \
    libxshmfence1 \
    libx11-xcb1 \
    libxcb-dri3-0 \
    libxcb-glx0 \
    libxcb1

# 安装字体（支持中文）
apt install -y fonts-wqy-zenhei fonts-wqy-microhei fonts-noto-cjk || {
    echo "字体安装失败，继续..."
}

# 安装额外工具
apt install -y wget curl file

echo "Ubuntu 环境配置完成"
' 2>&1 | tail -20

echo -e "${GREEN}✓ proot 环境配置完成${NC}"

# ===== 步骤 5: 创建爬虫目录 =====
echo -e "${YELLOW}[步骤 5/7] 创建爬虫目录...${NC}"

mkdir -p "${CRAWLER_DIR}"
mkdir -p "${CRAWLER_DIR}/output"
mkdir -p "${CRAWLER_DIR}/cookies"

echo -e "${GREEN}✓ 目录创建完成${NC}"

# ===== 步骤 6: 解压爬虫包 =====
echo -e "${YELLOW}[步骤 6/7] 解压爬虫包...${NC}"

if [ ! -f "${DIST_FILE}" ]; then
    echo -e "${RED}错误: 未找到爬虫包: ${DIST_FILE}${NC}"
    echo ""
    echo "请从 GitHub Releases 下载 termux-crawler-dist.tar.gz"
    echo "下载地址: https://github.com/chenk-1833597858/yiguan/releases"
    echo ""
    echo "下载后放到: ${HOME}/"
    exit 1
fi

echo -e "${BLUE}解压中...${NC}"
tar -xzf "${DIST_FILE}" -C "${CRAWLER_DIR}" --strip-components=1 2>/dev/null || {
    # 尝试不使用 strip-components
    tar -xzf "${DIST_FILE}" -C "${CRAWLER_DIR}"
}

echo -e "${GREEN}✓ 爬虫包解压完成${NC}"

# 显示版本信息
if [ -f "${CRAWLER_DIR}/VERSION" ]; then
    echo -e "${BLUE}版本信息:${NC}"
    cat "${CRAWLER_DIR}/VERSION"
fi

# ===== 步骤 7: 配置共享内存 =====
echo -e "${YELLOW}[步骤 7/7] 配置共享内存...${NC}"

# 检查 /dev/shm
if [ ! -d "/dev/shm" ]; then
    mkdir -p /dev/shm
fi

# 尝试挂载（可能需要 root 或特定权限）
mount -t tmpfs tmpfs /dev/shm 2>/dev/null || {
    echo -e "${YELLOW}提示: 无法挂载 /dev/shm，爬虫将使用 --disable-dev-shm-usage 参数${NC}"
}

if [ -d "/dev/shm" ] && [ -w "/dev/shm" ]; then
    echo -e "${GREEN}✓ 共享内存配置成功${NC}"
else
    echo -e "${YELLOW}⚠ 共享内存不可用，但不影响使用${NC}"
fi

# ===== 完成 =====
echo ""
echo "============================================"
echo -e "${GREEN}安装完成！${NC}"
echo "============================================"
echo ""
echo -e "${BLUE}文件位置:${NC}"
echo "  爬虫目录: ${CRAWLER_DIR}"
echo "  Chromium:  ${CRAWLER_DIR}/chromium/chrome"
echo ""
echo -e "${BLUE}使用方法:${NC}"
echo ""
echo "  1. 进入 Ubuntu 环境:"
echo -e "     ${GREEN}proot-distro login ubuntu${NC}"
echo ""
echo "  2. 进入爬虫目录:"
echo -e "     ${GREEN}cd /root/crawler${NC}"
echo ""
echo "  3. 安装 Node.js 依赖 (首次运行):"
echo -e "     ${GREEN}npm install puppeteer-core${NC}"
echo ""
echo "  4. 运行爬虫:"
echo -e "     ${GREEN}export CHROMIUM_PATH=/root/crawler/chromium/chrome${NC}"
echo -e "     ${GREEN}node crawler.js https://example.com${NC}"
echo ""
echo "============================================"
echo ""
echo -e "${BLUE}快速启动脚本:${NC}"
echo "  ${HOME}/crawler/scripts/run-crawler.sh https://example.com"
echo ""
echo "============================================"

# 创建快速启动脚本
cat > "${HOME}/run-crawler.sh" << 'QUICKSTART'
#!/bin/bash
# Termux 快速启动爬虫脚本

URL="${1:-https://example.com}"

proot-distro login ubuntu -- bash -c "
    cd /root/crawler
    export CHROMIUM_PATH=/root/crawler/chromium/chrome
    
    # 检查依赖
    if [ ! -d 'node_modules' ]; then
        echo '安装依赖...'
        npm install puppeteer-core
    fi
    
    # 运行爬虫
    node crawler.js '${URL}'
"
QUICKSTART

chmod +x "${HOME}/run-crawler.sh"
echo -e "${GREEN}✓ 已创建快速启动脚本: ~/run-crawler.sh${NC}"