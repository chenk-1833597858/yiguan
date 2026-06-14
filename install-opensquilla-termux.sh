#!/bin/bash
#
# OpenSquilla 原生安装脚本 for Termux
# 版本: 2.0.0 (原生 Termux 版)
# 适用于: Termux (Android) - 无需 proot-distro
# OpenSquilla 版本: v0.3.1
#
# 使用方法:
#   1. 将此脚本复制到 Termux
#   2. chmod +x install-opensquilla-termux-native.sh
#   3. ./install-opensquilla-termux-native.sh
#
# 注意: 此脚本直接在 Termux 中运行，不使用 Ubuntu 环境
#       Python 3.12+ 通过 tur-repo (Termux User Repository) 安装
#

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# 检查是否在 Termux 中运行
check_termux() {
    if [ -z "$TERMUX_VERSION" ] && [ ! -d "$PREFIX" ]; then
        log_error "此脚本必须在 Termux 中运行"
        log_info "请先安装 Termux: https://termux.dev"
        exit 1
    fi
    
    if [ -n "$TERMUX_VERSION" ]; then
        log_success "检测到 Termux 版本: $TERMUX_VERSION"
    else
        log_success "检测到 Termux 环境"
    fi
    
    log_info "Prefix: $PREFIX"
}

# 检查系统架构
check_arch() {
    ARCH=$(uname -m)
    log_info "系统架构: $ARCH"
    
    case $ARCH in
        aarch64|arm64)
            ARCH_TYPE="aarch64"
            ;;
        armv7|armv7l|arm)
            ARCH_TYPE="arm"
            ;;
        x86_64)
            ARCH_TYPE="x86_64"
            ;;
        i686|i386)
            ARCH_TYPE="x86"
            ;;
        *)
            log_error "不支持的架构: $ARCH"
            exit 1
            ;;
    esac
    log_success "架构类型: $ARCH_TYPE"
}

# 检查 Python 版本
check_python_version() {
    if command -v python &>/dev/null; then
        PYTHON_VERSION=$(python --version 2>&1 | cut -d' ' -f2)
        PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d'.' -f1)
        PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d'.' -f2)
        
        log_info "当前 Python 版本: $PYTHON_VERSION"
        
        if [ "$PYTHON_MAJOR" -ge 3 ] && [ "$PYTHON_MINOR" -ge 12 ]; then
            log_success "Python 版本满足要求 (>= 3.12)"
            return 0
        else
            log_warn "Python 版本不满足要求 (需要 >= 3.12)"
            return 1
        fi
    else
        log_warn "未检测到 Python"
        return 1
    fi
}

# 添加 tur-repo (Termux User Repository) 源
# 这是获取 Python 3.12+ 的关键步骤
add_tur_repo() {
    log_step "添加 tur-repo 源..."
    
    # tur-repo 是 Termux 官方认可的第三方源
    # 包含 Python 3.12 等新版本软件包
    
    # 检查是否已添加
    if grep -q "tur-repo" "$PREFIX/etc/apt/sources.list" 2>/dev/null || \
       [ -f "$PREFIX/etc/apt/sources.list.d/tur.list" ]; then
        log_success "tur-repo 源已存在"
        return 0
    fi
    
    # 添加 tur-repo
    log_info "正在添加 tur-repo..."
    
    # 方法1: 使用 tur-repo 安装脚本（推荐）
    if curl -sL "https://github.com/termux-user-repository/tur/raw/master/setup-repo.sh" | bash; then
        log_success "tur-repo 添加成功（通过脚本）"
        return 0
    fi
    
    # 方法2: 手动添加源
    log_warn "脚本添加失败，尝试手动添加..."
    
    cat > "$PREFIX/etc/apt/sources.list.d/tur.list" << 'EOF'
# Termux User Repository (tur-repo)
# https://github.com/termux-user-repository/tur
deb [trusted=yes] https://tur.kcubed.com/ tur tur-on-device
EOF
    
    if [ -f "$PREFIX/etc/apt/sources.list.d/tur.list" ]; then
        log_success "tur-repo 源已手动添加"
        return 0
    else
        log_error "无法添加 tur-repo 源"
        exit 1
    fi
}

# 更新 Termux 包管理器
update_termux() {
    log_step "更新 Termux 包管理器..."
    
    pkg update -y || {
        log_error "pkg update 失败"
        log_info "请检查网络连接并重试"
        exit 1
    }
    
    pkg upgrade -y || {
        log_warn "pkg upgrade 部分失败，继续..."
    }
    
    log_success "包管理器更新完成"
}

# 安装 Python 3.12 (通过 tur-repo 或默认源)
install_python312() {
    log_step "安装 Python 3.12+..."
    
    # 先检查是否已满足版本要求
    if check_python_version; then
        return 0
    fi
    
    # 尝试从 tur-repo 安装 python3.12
    log_info "尝试安装 Python 3.12..."
    
    # tur-repo 的包名格式: python3.12 或 python-tur
    # 尝试多个可能的包名
    for pkg_name in "python3.12" "python-tur" "python3.13"; do
        log_info "尝试安装 $pkg_name..."
        if pkg install -y "$pkg_name" 2>/dev/null; then
            log_success "成功安装 $pkg_name"
            break
        fi
    done
    
    # 再次检查版本
    if check_python_version; then
        log_success "Python 3.12+ 安装成功"
        return 0
    fi
    
    # 如果 tur-repo 方式失败，尝试其他方法
    log_warn "tur-repo Python 安装失败，尝试备用方案..."
    
    # 备用方案: 安装 Termux 默认的 Python (可能是 3.11)
    # 然后尝试使用 pyenv 编译 Python 3.12
    log_info "安装 Termux 默认 Python..."
    pkg install -y python || {
        log_error "Python 安装失败"
        exit 1
    }
    
    # 检查是否满足要求
    if check_python_version; then
        return 0
    fi
    
    # 如果 Termux 默认 Python 是 3.11，尝试 pyenv
    log_warn "Termux 默认 Python 不满足要求"
    log_info "尝试使用 pyenv 编译安装 Python 3.12..."
    
    install_pyenv_python
}

# 使用 pyenv 编译安装 Python 3.12
# 这是最后的备用方案
install_pyenv_python() {
    log_info "安装 pyenv..."
    
    pkg install -y git curl clang make lld || {
        log_error "pyenv 依赖安装失败"
        exit 1
    }
    
    # 安装 pyenv
    if [ ! -d "$HOME/.pyenv" ]; then
        curl -sL https://pyenv.run | bash || {
            log_warn "pyenv 安装失败，跳过"
            return 1
        }
        
        # 配置 pyenv 环境变量
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        
        # 添加到 bashrc
        cat >> "$HOME/.bashrc" << 'PYENV_EOF'
# pyenv 配置
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
PYENV_EOF
        
        log_success "pyenv 安装成功"
    else
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        log_success "pyenv 已存在"
    fi
    
    # 初始化 pyenv
    eval "$(pyenv init -)" || true
    
    # 安装 Python 3.12 编译依赖
    log_info "安装 Python 编译依赖..."
    pkg install -y \
        libffi \
        openssl \
        openssl-tool \
        zlib \
        libjpeg-turbo \
        libpng \
        readline \
        sqlite \
        bzip2 \
        xz-utils \
        || log_warn "部分编译依赖安装失败"
    
    # 编译安装 Python 3.12
    log_info "编译安装 Python 3.12（可能需要10-30分钟）..."
    PYTHON_CONFIGURE_OPTS="--enable-shared --enable-optimizations"
    
    pyenv install 3.12.8 || {
        log_warn "Python 3.12.8 编译失败，尝试其他版本..."
        pyenv install 3.12.4 || {
            log_error "Python 3.12 编译失败"
            return 1
        }
    }
    
    # 设置全局 Python 版本
    pyenv global 3.12.8 || pyenv global 3.12.4
    pyenv rehash
    
    log_success "Python 3.12 编译安装完成"
    
    # 验证
    python --version
}

# 安装编译工具和依赖库
install_build_deps() {
    log_step "安装编译工具和依赖库..."
    
    # Termux 使用 clang 而非 gcc
    # build-essential 在 Termux 中不存在
    
    pkg install -y \
        clang \
        lld \
        make \
        cmake \
        binutils \
        pkg-config \
        || {
            log_error "编译工具安装失败"
            exit 1
        }
    
    # 安装 Python 依赖所需的系统库
    pkg install -y \
        libffi \
        openssl \
        openssl-tool \
        libjpeg-turbo \
        libpng \
        zlib \
        libxml2 \
        libxslt \
        sqlite \
        freetype \
        || {
            log_warn "部分依赖库安装失败，继续..."
        }
    
    log_success "编译依赖安装完成"
}

# 创建 Python 虚拟环境
create_venv() {
    log_step "创建 Python 虚拟环境..."
    
    VENV_PATH="$HOME/opensquilla-venv"
    
    if [ -d "$VENV_PATH" ]; then
        log_warn "虚拟环境已存在，删除并重新创建..."
        rm -rf "$VENV_PATH"
    fi
    
    # 使用当前 Python 创建 venv
    python -m venv "$VENV_PATH" || {
        log_error "虚拟环境创建失败"
        exit 1
    }
    
    # 激活虚拟环境
    source "$VENV_PATH/bin/activate" || {
        log_error "虚拟环境激活失败"
        exit 1
    }
    
    log_success "虚拟环境已创建并激活: $VENV_PATH"
}

# 安装 OpenSquilla 和依赖
install_opensquilla() {
    log_step "安装 OpenSquilla v0.3.1..."
    
    # 确保在虚拟环境中
    if [ ! -n "$VIRTUAL_ENV" ]; then
        source "$HOME/opensquilla-venv/bin/activate"
    fi
    
    # 升级 pip
    log_info "升级 pip..."
    pip install --upgrade pip wheel setuptools || log_warn "pip 升级部分失败"
    
    # 安装编译型依赖（提前安装，避免编译失败）
    log_info "安装编译型 Python 依赖..."
    
    # cryptography 需要 libffi 和 openssl
    pip install cryptography || {
        log_warn "cryptography 安装失败，尝试使用预编译版本..."
        # 尝试使用纯 Python 实现或跳过
    }
    
    # Pillow 需要图像库
    pip install Pillow || {
        log_warn "Pillow 安装失败"
    }
    
    # 安装 OpenSquilla
    log_info "下载 OpenSquilla wheel 包..."
    WHEEL_URL="https://github.com/opensquilla/opensquilla/releases/download/v0.3.1/opensquilla-0.3.1-py3-none-any.whl"
    
    # 尝试直接从 URL 安装
    pip install "$WHEEL_URL" || {
        log_warn "直接安装失败，尝试下载后安装..."
        
        # 下载 wheel 文件
        WHEEL_FILE="$HOME/opensquilla-0.3.1.whl"
        curl -L "$WHEEL_URL" -o "$WHEEL_FILE" || {
            log_error "OpenSquilla wheel 下载失败"
            exit 1
        }
        
        pip install "$WHEEL_FILE" || {
            log_error "OpenSquilla 安装失败"
            exit 1
        }
        
        rm -f "$WHEEL_FILE"
    }
    
    # 验证安装
    log_info "验证安装..."
    python -c "import opensquilla; print(f'OpenSquilla 版本: {opensquilla.__version__}')" || {
        log_warn "OpenSquilla 导入测试失败，检查依赖..."
        
        # 显示已安装的包
        pip list
        
        # 检查是否有缺失的依赖
        log_info "尝试重新安装依赖..."
        pip install --force-reinstall starlette uvicorn pydantic sqlmodel httpx websockets || true
    }
    
    log_success "OpenSquilla 安装完成"
}

# 创建启动脚本
create_launcher() {
    log_step "创建启动脚本..."
    
    LAUNCHER_PATH="$HOME/opensquilla"
    
    cat > "$LAUNCHER_PATH" << 'LAUNCHER_EOF'
#!/bin/bash
# OpenSquilla 原生 Termux 启动脚本

# 设置环境变量
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export PYTHONIOENCODING=utf-8

# 激活虚拟环境
VENV_PATH="$HOME/opensquilla-venv"

if [ ! -d "$VENV_PATH" ]; then
    echo "错误: 虚拟环境不存在"
    echo "请先运行安装脚本"
    exit 1
fi

source "$VENV_PATH/bin/activate"

# 运行 OpenSquilla
opensquilla "$@"
LAUNCHER_EOF
    
    chmod +x "$LAUNCHER_PATH"
    log_success "启动脚本已创建: $LAUNCHER_PATH"
}

# 创建卸载脚本
create_uninstaller() {
    log_info "创建卸载脚本..."
    
    UNINSTALLER_PATH="$HOME/uninstall-opensquilla.sh"
    
    cat > "$UNINSTALLER_PATH" << 'UNINSTALL_EOF'
#!/bin/bash
# OpenSquilla 卸载脚本 (Termux 原生版)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}警告: 此操作将卸载 OpenSquilla${NC}"
read -p "确定要继续吗? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "取消卸载"
    exit 0
fi

echo -e "${GREEN}正在卸载...${NC}"

# 删除虚拟环境
rm -rf "$HOME/opensquilla-venv"

# 删除启动脚本
rm -f "$HOME/opensquilla"
rm -f "$HOME/uninstall-opensquilla.sh"

# 删除 pyenv Python（如果使用了 pyenv）
if [ -d "$HOME/.pyenv" ]; then
    echo -e "${YELLOW}是否删除 pyenv 和编译的 Python?${NC}"
    read -p "删除 pyenv? (yes/no): " del_pyenv
    if [ "$del_pyenv" = "yes" ]; then
        rm -rf "$HOME/.pyenv"
        # 从 bashrc 移除 pyenv 配置
        sed -i '/pyenv/d' "$HOME/.bashrc"
        echo -e "${GREEN}pyenv 已删除${NC}"
    fi
fi

echo -e "${GREEN}卸载完成${NC}"
echo -e "${YELLOW}提示: Termux 系统包保留，如需完全删除请运行:${NC}"
echo "  pkg uninstall python python3.12 clang ..."
UNINSTALL_EOF
    
    chmod +x "$UNINSTALLER_PATH"
    log_success "卸载脚本已创建: $UNINSTALLER_PATH"
}

# 显示安装信息
show_info() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}  OpenSquilla 安装完成!${NC}"
    echo -e "${GREEN}  (Termux 原生版)${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    
    # 显示 Python 版本
    PYTHON_VERSION=$(python --version 2>&1)
    echo -e "Python 版本: ${BLUE}$PYTHON_VERSION${NC}"
    echo -e "OpenSquilla 版本: ${BLUE}v0.3.1${NC}"
    echo -e "安装模式: ${BLUE}Termux 原生（无 proot）${NC}"
    echo -e "虚拟环境: ${BLUE}$HOME/opensquilla-venv${NC}"
    echo ""
    
    echo -e "${YELLOW}使用方法:${NC}"
    echo "  启动 OpenSquilla:"
    echo "    ~/opensquilla --help"
    echo ""
    echo "  或手动启动:"
    echo "    source ~/opensquilla-venv/bin/activate"
    echo "    opensquilla [命令]"
    echo ""
    echo "  卸载:"
    echo "    ~/uninstall-opensquilla.sh"
    echo ""
    echo -e "${YELLOW}注意事项:${NC}"
    echo "  - Python 3.12+ 通过 tur-repo 或 pyenv 安装"
    echo "  - 部分依赖可能需要编译时间"
    echo "  - 建议在 WiFi 环境下首次运行"
    echo "  - 如遇到问题，请检查 Termux 版本是否最新"
    echo ""
    echo -e "${YELLOW}tur-repo 信息:${NC}"
    echo "  - https://github.com/termux-user-repository/tur"
    echo "  - 提供 Python 3.12+ 等新版本软件包"
    echo ""
}

# 主安装流程
main() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}  OpenSquilla 原生安装脚本${NC}"
    echo -e "${GREEN}  for Termux (Android)${NC}"
    echo -e "${GREEN}  无需 proot-distro${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo -e "${CYAN}版本: 2.0.0 (原生 Termux)${NC}"
    echo -e "${CYAN}OpenSquilla: v0.3.1${NC}"
    echo ""
    
    # 检查环境
    check_termux
    check_arch
    
    # 添加 tur-repo（获取 Python 3.12+）
    add_tur_repo
    
    # 更新包管理器
    update_termux
    
    # 安装 Python 3.12+
    install_python312
    
    # 安装编译依赖
    install_build_deps
    
    # 创建虚拟环境
    create_venv
    
    # 安装 OpenSquilla
    install_opensquilla
    
    # 创建启动脚本
    create_launcher
    create_uninstaller
    
    # 显示完成信息
    show_info
}

# 运行主函数
main "$@"