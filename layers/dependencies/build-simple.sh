#!/bin/bash

echo "🚀 开始构建 Lambda Layer (简化版本)..."

# 清理旧的构建产物
echo "📁 清理旧的构建产物..."
rm -rf python/
mkdir -p python/

# 使用本地 Python 安装依赖包
echo "📦 安装 Python 依赖包..."
pip3 install --target python/ \
    pandas>=2.1.0 \
    akshare>=1.12.0 \
    numpy>=1.24.0 \
    requests>=2.31.0

# 清理不必要文件
echo "🧹 清理不必要文件..."
find python -name '*.pyc' -delete
find python -name '__pycache__' -type d -exec rm -rf {} + 2>/dev/null || true
find python -name '*.dist-info' -type d -exec rm -rf {} + 2>/dev/null || true
find python -name 'tests' -type d -exec rm -rf {} + 2>/dev/null || true

# 计算大小
echo "📊 计算 Layer 大小..."
du -sh python/

echo "✅ Lambda Layer 构建完成！"
echo "📋 验证构建结果..."
ls -la python/ | head -10
echo "📏 Layer 大小: $(du -sh python/ | cut -f1)"