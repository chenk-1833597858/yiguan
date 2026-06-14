# OpenSquilla Termux 原生安装指南（简版）

## 一键安装

```bash
# 1. 下载并运行
pkg install wget
wget https://your-host/install-opensquilla-termux.sh
chmod +x install-opensquilla-termux.sh
./install-opensquilla-termux.sh

# 2. 使用
~/opensquilla --help
```

## 核心特性

- ✅ **原生运行**: 无需 proot-distro Ubuntu 环境
- ✅ **轻量级**: 存储占用约 500MB（比 proot 方案节省 ~1GB）
- ✅ **快速启动**: 秒级启动（无虚拟化开销）
- ✅ **Python 3.12+**: 通过 tur-repo 或 pyenv 安装

## 故障排查

### Python 3.12 安装问题
```bash
# 手动添加 tur-repo
curl -sL https://github.com/termux-user-repository/tur/raw/master/setup-repo.sh | bash
pkg update
pkg install python3.12
```

### 编译依赖问题
```bash
# 安装必要的编译库
pkg install clang lld make libffi openssl libjpeg-turbo libpng zlib sqlite
source ~/opensquilla-venv/bin/activate
pip install cryptography Pillow --no-cache-dir
```

### 更新后重新安装
```bash
pkg update && pkg upgrade
./install-opensquilla-termux.sh
```

### 手动启动
```bash
source ~/opensquilla-venv/bin/activate
opensquilla --help
```

### 卸载
```bash
~/uninstall-opensquilla.sh
```

## 常用命令

| 命令 | 说明 |
|------|------|
| `~/opensquilla` | 启动 OpenSquilla |
| `~/opensquilla --help` | 查看帮助 |
| `source ~/opensquilla-venv/bin/activate` | 激活虚拟环境 |
| `~/uninstall-opensquilla.sh` | 卸载 |

## 快速别名

```bash
echo 'alias osq="~/opensquilla"' >> ~/.bashrc
source ~/.bashrc
osq --help  # 使用短命令
```

---
详细文档见 [README.md](README.md)