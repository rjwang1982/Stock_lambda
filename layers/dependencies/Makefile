# Makefile for building Lambda Layer dependencies
# This ensures arm64 compatibility for AWS Lambda
#
# 作者: RJ.Wang
# 邮箱: wangrenjun@gmail.com
# 创建时间: 2025-10-31
# 版本: 1.0

.PHONY: build-layer clean verify help

# Default target
build-StockAnalysisLayer: build-layer

build-layer:
	@echo "🚀 开始构建 Lambda Layer (arm64)..."
	@echo "📁 清理旧的构建产物..."
	rm -rf python/
	mkdir -p python/
	@echo "🐳 使用 Docker 构建 arm64 依赖包..."
	docker run --rm \
		--platform linux/arm64 \
		-v $(shell pwd):/workspace \
		-w /workspace \
		python:3.13-slim \
		bash -c " \
			echo '📦 更新包管理器...' && \
			apt-get update -qq && \
			apt-get install -y -qq gcc g++ && \
			echo '📦 安装 Python 依赖包...' && \
			pip install --no-cache-dir --target python \
				pandas>=2.1.0 \
				akshare>=1.12.0 \
				numpy>=1.24.0 \
				requests>=2.31.0 && \
			echo '🧹 清理不必要文件...' && \
			find python -name '*.pyc' -delete && \
			find python -name '__pycache__' -type d -exec rm -rf {} + 2>/dev/null || true && \
			find python -name '*.dist-info' -type d -exec rm -rf {} + 2>/dev/null || true && \
			find python -name 'tests' -type d -exec rm -rf {} + 2>/dev/null || true && \
			echo '📊 计算 Layer 大小...' && \
			du -sh python/ \
		"
	@echo "✅ Lambda Layer 构建完成！"
	@echo "📋 验证构建结果..."
	@ls -la python/ | head -10
	@echo "📏 Layer 大小: $$(du -sh python/ | cut -f1)"

clean:
	@echo "🧹 清理构建产物..."
	rm -rf python/
	@echo "✅ 清理完成！"

# 验证依赖包
verify:
	@echo "🔍 验证依赖包..."
	@python3 -c "import sys; sys.path.insert(0, 'python'); import pandas, akshare, numpy, requests; print('✅ 所有依赖包验证成功')"

# 显示帮助
help:
	@echo "可用命令:"
	@echo "  build-layer  - 构建 Lambda Layer 依赖包"
	@echo "  clean        - 清理构建产物"
	@echo "  verify       - 验证依赖包"
	@echo "  help         - 显示此帮助信息"