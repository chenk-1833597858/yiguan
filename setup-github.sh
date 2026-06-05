#!/bin/bash
#
# 快速设置 OpenSquilla Termux 构建仓库
# 
# 使用方法:
#   1. 确保已安装 gh (GitHub CLI) 并已登录
#   2. 运行此脚本

set -e

REPO_NAME="opensquilla-termux-builder"

echo "=========================================="
echo "  OpenSquilla Termux 构建仓库设置"
echo "=========================================="
echo ""

# 检查 gh CLI
if ! command -v gh &>/dev/null; then
    echo "错误: 未安装 GitHub CLI (gh)"
    echo ""
    echo "安装方法:"
    echo "  macOS: brew install gh"
    echo "  Linux: sudo apt install gh"
    echo "  或访问: https://cli.github.com"
    exit 1
fi

# 检查登录状态
if ! gh auth status &>/dev/null; then
    echo "错误: 未登录 GitHub CLI"
    echo "请先运行: gh auth login"
    exit 1
fi

# 获取用户名
USERNAME=$(gh api user --jq '.login')
echo "GitHub 用户: $USERNAME"
echo ""

# 创建仓库
echo "创建仓库: $REPO_NAME"
gh repo create "$REPO_NAME" --public --description "OpenSquilla Termux pre-built package builder" --confirm

# 初始化 git
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

git init
git add .
git commit -m "Initial commit: OpenSquilla Termux builder"
git branch -M main
git remote add origin "https://github.com/$USERNAME/$REPO_NAME.git"
git push -u origin main

echo ""
echo "=========================================="
echo "  仓库创建成功!"
echo "=========================================="
echo ""
echo "仓库地址: https://github.com/$USERNAME/$REPO_NAME"
echo ""
echo "下一步:"
echo "  1. 进入 Actions 标签页"
echo "  2. 点击 'Build OpenSquilla for Termux'"
echo "  3. 点击 'Run workflow'"
echo "  4. 等待构建完成"
echo "  5. 下载 Artifacts"
echo ""
