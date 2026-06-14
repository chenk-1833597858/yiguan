# OpenSquilla Termux 预编译 Docker 镜像
# 用于在 ARM64 环境中编译 Termux 兼容的 Python 包

# 使用 ARM64 Ubuntu 作为基础
FROM --platform=linux/arm64 ubuntu:24.04

LABEL maintainer="OpenSquilla Builder"
LABEL description="Pre-compile OpenSquilla for Termux ARM64"

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONIOENCODING=utf-8

# 安装编译工具和依赖
RUN apt-get update && apt-get install -y \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    python3-pip \
    build-essential \
    clang \
    lld \
    cmake \
    ninja-build \
    pkg-config \
    libffi-dev \
    libssl-dev \
    libsqlite3-dev \
    libjpeg-dev \
    libpng-dev \
    zlib1g-dev \
    libfreetype6-dev \
    libxml2-dev \
    libxslt1-dev \
    libbz2-dev \
    liblzma-dev \
    libncurses5-dev \
    libreadline-dev \
    libgdbm-dev \
    tk-dev \
    uuid-dev \
    curl \
    wget \
    git \
    tar \
    gzip \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# 设置 Python 3.12 为默认
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# 创建工作目录
WORKDIR /build

# 创建虚拟环境
RUN python -m venv /build/venv
ENV PATH="/build/venv/bin:$PATH"

# 升级 pip
RUN pip install --upgrade pip wheel setuptools

# 下载 OpenSquilla wheel
RUN wget -q https://github.com/opensquilla/opensquilla/releases/download/v0.3.1/opensquilla-0.3.1-py3-none-any.whl

# 安装 OpenSquilla（这会编译所有依赖）
RUN pip install opensquilla-0.3.1-py3-none-any.whl

# 验证安装
RUN python -c "import opensquilla; print(f'OpenSquilla installed: {opensquilla.__version__}')"

# 创建输出目录
RUN mkdir -p /output

# 打包虚拟环境
RUN cd /build && tar -czf /output/opensquilla-termux-arm64.tar.gz venv/

# 创建安装脚本
RUN echo '#!/bin/bash' > /output/install.sh && \
    echo 'set -e' >> /output/install.sh && \
    echo 'echo "解压 OpenSquilla 到 ~/opensquilla"' >> /output/install.sh && \
    echo 'mkdir -p ~/opensquilla' >> /output/install.sh && \
    echo 'tar -xzf opensquilla-termux-arm64.tar.gz -C ~/opensquilla' >> /output/install.sh && \
    echo 'echo "创建启动脚本"' >> /output/install.sh && \
    echo 'echo "#!/bin/bash" > ~/opensquilla/run.sh' >> /output/install.sh && \
    echo 'echo "source ~/opensquilla/venv/bin/activate && opensquilla \"\$@\"" >> ~/opensquilla/run.sh' >> /output/install.sh && \
    echo 'chmod +x ~/opensquilla/run.sh' >> /output/install.sh && \
    echo 'echo "安装完成！使用: ~/opensquilla/run.sh [命令]"' >> /output/install.sh && \
    chmod +x /output/install.sh

# 创建 README
RUN echo '# OpenSquilla Termux 预编译包' > /output/README.md && \
    echo '' >> /output/README.md && \
    echo '## 使用方法' >> /output/README.md && \
    echo '' >> /output/README.md && \
    echo '1. 将 opensquilla-termux-arm64.tar.gz 复制到 Termux' >> /output/README.md && \
    echo '2. 运行: ./install.sh' >> /output/README.md && \
    echo '3. 启动: ~/opensquilla/run.sh --help' >> /output/README.md

WORKDIR /output

# 默认命令：显示打包内容
CMD ["ls", "-lh", "/output"]
