#!/bin/bash
#
# OpenSquilla Termux 预编译构建脚本
# 在 ARM64 Docker 环境中编译，输出可直接在 Termux 使用的包

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/output"

echo "=========================================="
echo "  OpenSquilla Termux 预编译构建"
echo "=========================================="
echo ""

# 检查 Docker
if ! command -v docker &>/dev/null; then
    echo "错误: 未安装 Docker"
    echo "请先安装 Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# 检查 Docker 权限
if ! docker info &>/dev/null; then
    echo "错误: Docker 权限不足"
    echo "请运行: sudo usermod -aG docker \$USER"
    echo "然后重新登录"
    exit 1
fi

# 检查 Docker Buildx（用于跨架构构建）
if ! docker buildx version &>/dev/null; then
    echo "警告: Docker Buildx 未安装，尝试安装..."
    docker buildx install 2>/dev/null || {
        echo "无法安装 Buildx，请确保 Docker 版本 >= 19.03"
        exit 1
    }
fi

# 创建 QEMU 支持（用于跨架构）
echo "设置 QEMU 支持..."
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes 2>/dev/null || {
    echo "警告: QEMU 设置可能失败，如果在 ARM64 机器上可忽略"
}

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 构建镜像
echo ""
echo "构建 Docker 镜像（ARM64）..."
echo "这可能需要 10-20 分钟..."
echo ""

docker buildx build \
    --platform linux/arm64 \
    --tag opensquilla-termux-builder:latest \
    --load \
    "$SCRIPT_DIR"

if [ $? -ne 0 ]; then
    echo "错误: Docker 构建失败"
    exit 1
fi

echo ""
echo "提取编译结果..."

# 运行容器并提取输出
CONTAINER_ID=$(docker create opensquilla-termux-builder:latest)
docker cp "$CONTAINER_ID:/output/." "$OUTPUT_DIR/"
docker rm "$CONTAINER_ID" >/dev/null

echo ""
echo "=========================================="
echo "  构建完成！"
echo "=========================================="
echo ""
echo "输出目录: $OUTPUT_DIR"
echo ""
ls -lh "$OUTPUT_DIR"
echo ""
echo "使用方法:"
echo "  1. 将 output/opensquilla-termux-arm64.tar.gz 复制到 Termux"
echo "  2. 在 Termux 中运行: tar -xzf opensquilla-termux-arm64.tar.gz"
echo "  3. 启动: ~/opensquilla/run.sh --help"
echo ""
