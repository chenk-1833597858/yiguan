#!/bin/bash

# ============================================
# Termux 爬虫运行脚本
# ============================================

CRAWLER_DIR="${HOME}/crawler"

# 检查参数
if [ -z "$1" ]; then
    echo "用法: $0 <URL> [options]"
    echo ""
    echo "示例:"
    echo "  $0 https://example.com"
    echo "  $0 https://example.com --screenshot=screenshot.png"
    echo "  $0 https://example.com --output=data.json"
    exit 1
fi

URL="$1"
shift

# 进入 proot Ubuntu 运行
proot-distro login ubuntu -- bash -c "
    cd /root/crawler
    export CHROMIUM_PATH=/root/crawler/chromium/chrome
    node crawler.js '${URL}' $@
"
