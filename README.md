# OpenSquilla ARM64 Build

自动编译 OpenSquilla 的 ARM64 版本，适用于 Android Termux。

## 使用方法

### 1. 触发编译
1. 进入 Actions 页面
2. 选择 "Build OpenSquilla for ARM64/Android"
3. 点击 "Run workflow"
4. 等待编译完成（约 30-60 分钟）

### 2. 下载安装包
编译完成后，在 Releases 页面下载 `opensquilla-arm64.tar.gz`

### 3. 在 Termux 中安装
```bash
# 解压
tar -xzvf opensquilla-arm64.tar.gz

# 安装依赖
pip install -r requirements.txt

# 运行
opensquilla
```

## 注意事项

- 首次编译需要下载依赖，可能较慢
- 编译产物保留 30 天
- 建议使用 Python 3.12+
