# OpenSquilla Termux 原生安装包 - 文件清单

```
opensquilla-build/
├── install-opensquilla-termux.sh   # 主安装脚本（原生 Termux 版）
├── build-offline-package.sh         # 离线包生成脚本
├── README.md                         # 完整安装指南
├── QUICKSTART.md                     # 快速开始指南
└── MANIFEST.md                       # 本文件
```

## 文件说明

### install-opensquilla-termux.sh
**主安装脚本** - 核心文件（原生 Termux 版）

功能：
- 自动检测 Termux 环境和架构
- 添加 tur-repo 源获取 Python 3.12+
- 安装 Termux 编译工具（clang/lld/make）
- 在 Termux 中创建 Python 虚拟环境
- 安装 OpenSquilla 及依赖
- 创建便捷启动脚本

使用：
```bash
chmod +x install-opensquilla-termux.sh
./install-opensquilla-termux.sh
```

**关键特性**:
- ✅ 无需 proot-distro Ubuntu 环境
- ✅ 通过 tur-repo 或 pyenv 安装 Python 3.12+
- ✅ 存储占用约 500MB（比 proot 方案节省 ~1GB）
- ✅ 启动速度更快（秒级启动）

### build-offline-package.sh
**离线包生成脚本**

用途：在有网络的设备上生成离线安装包，用于无网络环境安装

使用：
```bash
# 在有网络的 Linux/Mac 设备上运行
./build-offline-package.sh

# 输出: opensquilla-termux-offline.tar.gz
```

注意：需要 Python 3.12+ 和 pip

### README.md
**完整安装指南**

包含：
- 详细安装步骤
- tur-repo 和 pyenv 使用说明
- Termux 包名对照表
- 故障排查
- 与 proot 方案对比

### QUICKSTART.md
**快速开始指南**

简洁版文档，适合快速查阅

## 系统要求

### Termux 环境
- Termux 最新版本（建议从 F-Droid 安装）
- Android 7.0+ (API 24+)
- 至少 1GB 可用存储（比 proot 方案节省约1GB）
- 至少 2GB RAM（推荐 4GB+ 用于编译）

### 架构支持
- aarch64 (ARM64) ✅
- armv7/v7l (ARM) ✅
- x86_64 ✅
- i686 ✅

## 安装流程对比

### 原生 Termux 方案（本脚本）
```
┌─────────────────┐
│  Termux 环境    │
└────────┬────────┘
         │ 添加 tur-repo
         ▼
┌─────────────────┐
│  Python 3.12+   │
└────────┬────────┘
         │ 创建 venv
         ▼
┌─────────────────┐
│  OpenSquilla    │
└─────────────────┘

存储: ~500MB
启动: 秒级
```

### proot-distro 方案（旧方案）
```
┌─────────────────┐
│  Termux 环境    │
└────────┬────────┘
         │ pkg install proot-distro
         ▼
┌─────────────────┐
│  Ubuntu 环境    │
└────────┬────────┘
         │ apt install python3.12
         ▼
┌─────────────────┐
│  OpenSquilla    │
└─────────────────┘

存储: ~1.6GB
启动: 3-5秒
```

## 依赖说明

### Termux 系统包（原生方案）

**编译工具**:
- clang（替代 gcc）
- lld（LLVM linker）
- make
- cmake（可选）
- pkg-config

**开发库**:
- libffi
- openssl / openssl-tool
- libjpeg-turbo
- libpng
- zlib
- sqlite
- libxml2
- libxslt
- readline（pyenv 需要）
- bzip2 / xz-utils（pyenv 需要）

### Python 包（核心）
参见 pyproject.toml dependencies 列表

## 存储空间估算（原生方案）

| 组件 | 大小 |
|------|------|
| Termux 编译工具 | ~100MB |
| 开发库 | ~50MB |
| Python 虚拟环境 | ~300MB |
| OpenSquilla 及依赖 | ~150MB |
| **总计** | **~500MB** |

对比 proot 方案节省约 1GB！

## Python 3.12+ 安装方式

### 方式1: tur-repo（推荐）
```bash
# 添加 tur-repo
curl -sL https://github.com/termux-user-repository/tur/raw/master/setup-repo.sh | bash

# 安装 Python 3.12
pkg update
pkg install python3.12
```

### 方式2: pyenv 编译（备用）
```bash
# 安装 pyenv
curl -sL https://pyenv.run | bash

# 编译 Python 3.12（需要 10-30 分钟）
pyenv install 3.12.8
pyenv global 3.12.8
```

## 测试建议

安装完成后，建议运行以下测试：

```bash
# 1. 测试 Python 版本
source ~/opensquilla-venv/bin/activate
python --version  # 应显示 3.12.x

# 2. 测试 OpenSquilla 导入
python -c "import opensquilla; print(f'OpenSquilla: {opensquilla.__version__}')"

# 3. 测试 CLI
~/opensquilla --help
```

## 已知问题

1. **tur-repo 不稳定**: 建议添加备用源或使用 pyenv
2. **pyenv 编译时间**: 编译 Python 3.12 需要 10-30 分钟
3. **sqlite-vec 编译**: 可能需要 clang 支持
4. **cryptography 安装**: 需要 libffi 和 openssl

## 更新维护

### 更新安装脚本
```bash
# 下载最新版本
wget https://your-host/install-opensquilla-termux.sh -O install-opensquilla-termux.sh.new
mv install-opensquilla-termux.sh.new install-opensquilla-termux.sh
chmod +x install-opensquilla-termux.sh
```

### 更新 OpenSquilla
```bash
source ~/opensquilla-venv/bin/activate
pip install --upgrade opensquilla
```

## 分发建议

### 方式一：单文件分发
只需分发 `install-opensquilla-termux.sh`

### 方式二：离线包分发
运行 `build-offline-package.sh` 生成的 tar.gz

### 方式三：完整包分发
打包整个目录为 zip/tar.gz

---

_版本: 2.0.0 (原生 Termux 版)_
_更新时间: 2026-06-05_
_特性: 无需 proot，轻量级，快速启动_