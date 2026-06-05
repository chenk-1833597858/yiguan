# OpenSquilla ARM64 一键安装包

自动编译 OpenSquilla ARM64 版本，适用于 Android Termux。

## 📦 下载安装包

1. 进入 [Actions](../../actions) 页面
2. 点击最新的成功构建
3. 在 Artifacts 中下载 `opensquilla-arm64-package`
4. 或在 [Releases](../../releases) 页面下载

## 🚀 安装方法

```bash
# 1. 解压到用户目录
tar -xzvf opensquilla-arm64.tar.gz -C $HOME

# 2. 激活虚拟环境
source $HOME/opensquilla/bin/activate

# 3. 运行 OpenSquilla
opensquilla
```

## ⚙️ 手动触发编译

1. 进入 Actions 页面
2. 选择 "Build OpenSquilla ARM64 Package"
3. 点击 "Run workflow"
4. 等待编译完成（约 30-60 分钟）

## 📋 系统要求

- Android 7.0+
- Termux (最新版)
- ARM64 架构

---
*此项目自动编译 OpenSquilla 的 ARM64 版本*
