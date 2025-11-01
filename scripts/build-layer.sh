#!/bin/bash
# 构建 Lambda Layer 脚本
# 使用 Docker 确保 arm64 Linux 兼容性
#
# 作者: RJ.Wang
# 邮箱: wangrenjun@gmail.com
# 创建时间: 2025-10-31
# 版本: 1.0

set -e

echo "🚀 开始构建 Lambda Layer..."

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAYER_DIR="${PROJECT_ROOT}/layers/dependencies"

echo "📁 项目根目录: ${PROJECT_ROOT}"
echo "📦 Layer 目录: ${LAYER_DIR}"

# 清理旧的构建产物
echo "🧹 清理旧的构建产物..."
rm -rf "${LAYER_DIR}/python"
mkdir -p "${LAYER_DIR}/python"

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker 未运行，请启动 Docker 后重试"
    exit 1
fi

# 检查必需文件
if [ ! -f "${LAYER_DIR}/requirements-layer.txt" ]; then
    echo "❌ 缺少 requirements-layer.txt 文件"
    exit 1
fi

echo "🐳 使用 Docker 构建 arm64 依赖包..."

# 方法1: 使用自定义 Dockerfile（推荐）
if [ -f "${LAYER_DIR}/Dockerfile" ]; then
    echo "📋 使用自定义 Dockerfile 构建..."
    
    # 构建 Docker 镜像
    docker build \
        --platform linux/arm64 \
        -t stock-analysis-layer-builder \
        -f "${LAYER_DIR}/Dockerfile" \
        "${LAYER_DIR}"
    
    # 从容器中复制构建结果
    CONTAINER_ID=$(docker create --platform linux/arm64 stock-analysis-layer-builder)
    docker cp "${CONTAINER_ID}:/opt/python" "${LAYER_DIR}/"
    docker rm "${CONTAINER_ID}"
    
    echo "✅ 使用 Dockerfile 构建完成"
else
    # 方法2: 直接使用 Python 镜像
    echo "📋 使用 Python 镜像直接构建..."
    
    docker run --rm \
        --platform linux/arm64 \
        -v "${LAYER_DIR}:/layer" \
        -w /layer \
        public.ecr.aws/lambda/python:3.13-arm64 \
        bash -c "
            echo '📦 安装系统依赖...'
            dnf update -y && dnf install -y gcc gcc-c++ make cmake
            
            echo '📦 升级 pip...'
            pip install --upgrade pip setuptools wheel
            
            echo '📦 安装 Python 依赖包...'
            pip install --target python --no-cache-dir -r requirements-layer.txt
            
            echo '🧹 清理不必要文件...'
            find python -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true
            find python -type f -name '*.pyc' -delete
            find python -type f -name '*.pyo' -delete
            find python -type d -name '*.dist-info' -exec rm -rf {} + 2>/dev/null || true
            find python -type d -name '*.egg-info' -exec rm -rf {} + 2>/dev/null || true
            
            echo '🔍 检查安装结果...'
            ls -la python/
            
            echo '📊 计算大小...'
            du -sh python/
        "
    
    echo "✅ 使用 Python 镜像构建完成"
fi

# 验证构建结果
if [ ! -d "${LAYER_DIR}/python" ]; then
    echo "❌ Layer 构建失败：python 目录不存在"
    exit 1
fi

# 检查关键包是否存在
echo "🔍 验证关键包..."
REQUIRED_PACKAGES=("pandas" "akshare" "numpy")
for package in "${REQUIRED_PACKAGES[@]}"; do
    if [ ! -d "${LAYER_DIR}/python/${package}" ] && [ ! -d "${LAYER_DIR}/python/${package}-"* ]; then
        echo "❌ 缺少必需包: ${package}"
        # 列出实际安装的包
        echo "📋 实际安装的包:"
        ls -la "${LAYER_DIR}/python/" | head -20
        exit 1
    else
        echo "✅ 找到包: ${package}"
    fi
done

# 计算 Layer 大小
LAYER_SIZE=$(du -sh "${LAYER_DIR}/python" | cut -f1)
echo "📏 Layer 大小: ${LAYER_SIZE}"

# 检查大小限制（250MB）
LAYER_SIZE_MB=$(du -sm "${LAYER_DIR}/python" | cut -f1)
if [ "${LAYER_SIZE_MB}" -gt 250 ]; then
    echo "⚠️  警告: Layer 大小 (${LAYER_SIZE_MB}MB) 超过 AWS 限制 (250MB)"
    echo "   建议优化依赖包或分拆 Layer"
    
    # 显示最大的目录
    echo "📊 最大的目录:"
    du -sm "${LAYER_DIR}/python"/* | sort -nr | head -10
else
    echo "✅ Layer 大小符合 AWS 限制"
fi

# 创建测试脚本
echo "📝 创建测试脚本..."
cat > "${LAYER_DIR}/test_imports.py" << 'EOF'
#!/usr/bin/env python3
"""测试 Lambda Layer 中的包是否可以正常导入"""

import sys
import os

# 添加 Layer 路径
sys.path.insert(0, '/opt/python')
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'python'))

def test_imports():
    """测试关键包的导入"""
    try:
        import pandas as pd
        print(f"✅ pandas {pd.__version__} 导入成功")
    except ImportError as e:
        print(f"❌ pandas 导入失败: {e}")
        return False
    
    try:
        import numpy as np
        print(f"✅ numpy {np.__version__} 导入成功")
    except ImportError as e:
        print(f"❌ numpy 导入失败: {e}")
        return False
    
    try:
        import akshare as ak
        print(f"✅ akshare 导入成功")
    except ImportError as e:
        print(f"❌ akshare 导入失败: {e}")
        return False
    
    try:
        import requests
        print(f"✅ requests {requests.__version__} 导入成功")
    except ImportError as e:
        print(f"❌ requests 导入失败: {e}")
        return False
    
    return True

if __name__ == "__main__":
    print("🧪 测试 Lambda Layer 包导入...")
    if test_imports():
        print("🎉 所有包导入测试通过！")
        sys.exit(0)
    else:
        print("❌ 包导入测试失败！")
        sys.exit(1)
EOF

# 运行测试
echo "🧪 测试包导入..."
cd "${LAYER_DIR}"
python3 test_imports.py

echo ""
echo "🎉 Lambda Layer 构建完成！"
echo ""
echo "📋 构建摘要:"
echo "   - 位置: ${LAYER_DIR}/python"
echo "   - 大小: ${LAYER_SIZE} (${LAYER_SIZE_MB}MB)"
echo "   - 包含: pandas, akshare, numpy, requests 及其依赖"
echo "   - 架构: linux/arm64"
echo "   - Python: 3.13"
echo ""
echo "🚀 下一步: 运行 'sam build' 构建整个应用"
echo "   或运行 'sam local start-api' 进行本地测试"