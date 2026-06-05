# OpenSquilla ARM64 安装指南

## 在 Termux 中快速安装

```bash
# 1. 安装 Python
pkg install python

# 2. 直接安装 OpenSquilla
pip install opensquilla

# 3. 运行
opensquilla
```

## 如果遇到编译错误

某些依赖需要编译，如果失败，尝试：

```bash
# 安装编译工具
pkg install clang cmake rust

# 重新安装
pip install opensquilla
```

## 检查 Python 版本

OpenSquilla 需要 Python 3.12+

```bash
python --version
```

如果版本过低，需要升级 Termux 或使用 proot-distro。
