#!/bin/bash

# ============================================
# Termux Chromium 爬虫安装脚本
# ============================================

set -e

echo "============================================"
echo "  Termux Chromium 爬虫安装脚本"
echo "============================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
CRAWLER_DIR="${HOME}/crawler"
DIST_FILE="${HOME}/termux-crawler-dist.tar.gz"

# ===== 步骤 1: 检查环境 =====
echo -e "${YELLOW}[步骤 1/6] 检查环境...${NC}"

if [ ! -d "/data/data/com.termux" ]; then
    echo -e "${RED}错误: 此脚本必须在 Termux 中运行${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Termux 环境检测通过${NC}"

# ===== 步骤 2: 安装基础依赖 =====
echo -e "${YELLOW}[步骤 2/6] 安装基础依赖...${NC}"

pkg update -y
pkg install -y proot proot-distro nodejs wget

echo -e "${GREEN}✓ 基础依赖安装完成${NC}"

# ===== 步骤 3: 安装 Ubuntu proot 环境 =====
echo -e "${YELLOW}[步骤 3/6] 安装 Ubuntu proot 环境...${NC}"

if proot-distro list | grep -q "ubuntu.*installed"; then
    echo -e "${GREEN}✓ Ubuntu 已安装${NC}"
else
    proot-distro install ubuntu
    echo -e "${GREEN}✓ Ubuntu 安装完成${NC}"
fi

# ===== 步骤 4: 配置 proot 环境 =====
echo -e "${YELLOW}[步骤 4/6] 配置 proot 环境...${NC}"

# 创建安装目录
mkdir -p "${CRAWLER_DIR}"

# 在 proot 中安装 Node.js 依赖
proot-distro login ubuntu -- bash -c "
    apt update
    apt install -y libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2 libpango-1.0-0 libcairo2 libatspi2.0-0
"

echo -e "${GREEN}✓ proot 环境配置完成${NC}"

# ===== 步骤 5: 解压爬虫包 =====
echo -e "${YELLOW}[步骤 5/6] 解压爬虫包...${NC}"

if [ ! -f "${DIST_FILE}" ]; then
    echo -e "${RED}错误: 未找到爬虫包: ${DIST_FILE}${NC}"
    echo "请先从 GitHub Releases 下载 termux-crawler-dist.tar.gz"
    echo "并放到 ${HOME} 目录"
    exit 1
fi

tar -xzf "${DIST_FILE}" -C "${CRAWLER_DIR}" --strip-components=1

echo -e "${GREEN}✓ 爬虫包解压完成${NC}"

# ===== 步骤 6: 配置共享内存 =====
echo -e "${YELLOW}[步骤 6/6] 配置共享内存...${NC}"

# 检查 /dev/shm
if [ ! -d "/dev/shm" ]; then
    mkdir -p /dev/shm
fi

# 尝试挂载（可能需要 root）
mount -t tmpfs tmpfs /dev/shm 2>/dev/null || true

echo -e "${GREEN}✓ 共享内存配置完成${NC}"

# ===== 完成 =====
echo ""
echo "============================================"
echo -e "${GREEN}安装完成！${NC}"
echo "============================================"
echo ""
echo "使用方法："
echo "  1. 进入 Ubuntu 环境:"
echo "     proot-distro login ubuntu"
echo ""
echo "  2. 进入爬虫目录:"
echo "     cd /root/crawler"
echo ""
echo "  3. 安装 Node.js 依赖:"
echo "     npm install puppeteer-core"
echo ""
echo "  4. 运行爬虫:"
echo "     node crawler.js https://example.com"
echo ""
echo "============================================"
