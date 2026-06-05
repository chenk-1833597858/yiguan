#!/bin/bash
#
# OpenSquilla 离线安装包生成脚本
# 用于在有网络的设备上生成离线安装包
#
# 使用方法:
#   ./build-offline-package.sh
#
# 输出:
#   opensquilla-termux-offline.tar.gz
#

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 创建临时目录
TMP_DIR=$(mktemp -d)
PACKAGE_DIR="$TMP_DIR/opensquilla-offline"

mkdir -p "$PACKAGE_DIR/wheels"
mkdir -p "$PACKAGE_DIR/scripts"

log_info "下载 OpenSquilla wheel..."
WHEEL_URL="https://github.com/opensquilla/opensquilla/releases/download/v0.3.1/opensquilla-0.3.1-py3-none-any.whl"
wget -q "$WHEEL_URL" -O "$PACKAGE_DIR/wheels/opensquilla-0.3.1-py3-none-any.whl"

log_info "下载依赖 wheels（这可能需要几分钟）..."
# 使用 pip download 下载所有依赖
pip download -d "$PACKAGE_DIR/wheels" \
    "opensquilla==0.3.1" \
    --python-version 3.12 \
    --only-binary=:all: \
    || log_info "部分依赖需要源码编译"

# 复制安装脚本
cp install-opensquilla-termux.sh "$PACKAGE_DIR/scripts/"
cp README.md "$PACKAGE_DIR/"
cp QUICKSTART.md "$PACKAGE_DIR/"

# 创建离线安装脚本
cat > "$PACKAGE_DIR/install-offline.sh" << 'OFFLINE_INSTALL'
#!/bin/bash
# 离线安装脚本

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info "开始离线安装..."

# 1. 安装 Termux 依赖
pkg update -y
pkg install -y proot proot-distro

# 2. 安装 Ubuntu
if ! proot-distro list | grep -q "ubuntu.*installed"; then
    log_info "安装 Ubuntu 环境..."
    proot-distro install ubuntu
fi

# 3. 在 Ubuntu 中安装
proot-distro login ubuntu --shared-tmp << 'UBUNTU_OFFLINE'
#!/bin/bash
set -e

# 更新系统
apt update -qq
apt install -y -qq python3.12 python3.12-venv python3-pip

# 创建虚拟环境
python3.12 -m venv ~/opensquilla-venv
source ~/opensquilla-venv/bin/activate

# 从本地 wheels 安装
pip install --no-index --find-links=/tmp/wheels opensquilla

echo "OpenSquilla 离线安装完成!"
UBUNTU_OFFLINE

log_success "离线安装完成!"
log_info "使用: ~/opensquilla --help"
OFFLINE_INSTALL

chmod +x "$PACKAGE_DIR/install-offline.sh"

# 打包
log_info "创建压缩包..."
cd "$TMP_DIR"
tar -czf opensquilla-termux-offline.tar.gz opensquilla-offline
mv opensquilla-termux-offline.tar.gz "$OLDPWD/"

# 清理
rm -rf "$TMP_DIR"

log_success "离线安装包已创建: opensquilla-termux-offline.tar.gz"
log_info "大小: $(du -h opensquilla-termux-offline.tar.gz | cut -f1)"
