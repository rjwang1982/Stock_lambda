# Dockerfile for building Lambda Layer dependencies
# 用于构建 Lambda Layer 依赖包的 Docker 文件

FROM public.ecr.aws/lambda/python:3.13-arm64

# 设置工作目录
WORKDIR /opt

# 安装系统依赖
RUN dnf update -y && \
    dnf install -y \
        gcc \
        gcc-c++ \
        make \
        cmake \
        git \
        wget \
        tar \
        gzip \
        which && \
    dnf clean all

# 升级 pip 和安装构建工具
RUN pip install --upgrade pip setuptools wheel

# 创建 python 目录
RUN mkdir -p /opt/python

# 复制 requirements 文件
COPY requirements-layer.txt /tmp/requirements-layer.txt

# 安装 Python 依赖包到 /opt/python
RUN pip install \
    --target /opt/python \
    --no-cache-dir \
    --no-deps \
    --platform linux_aarch64 \
    --implementation cp \
    --python-version 3.13 \
    --only-binary=:all: \
    -r /tmp/requirements-layer.txt || \
    pip install \
    --target /opt/python \
    --no-cache-dir \
    -r /tmp/requirements-layer.txt

# 清理不必要的文件
RUN find /opt/python -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/python -type f -name "*.pyc" -delete && \
    find /opt/python -type f -name "*.pyo" -delete && \
    find /opt/python -type d -name "*.dist-info" -exec rm -rf {} + 2>/dev/null || true && \
    find /opt/python -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true

# 设置权限
RUN chmod -R 755 /opt/python

# 显示安装的包和大小
RUN echo "=== 已安装的包 ===" && \
    ls -la /opt/python/ && \
    echo "=== Layer 大小 ===" && \
    du -sh /opt/python/

# 默认命令
CMD ["echo", "Lambda Layer dependencies built successfully"]