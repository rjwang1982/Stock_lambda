#!/bin/bash
# Lambda Layer Docker 构建脚本
#
# 作者: RJ.Wang
# 邮箱: wangrenjun@gmail.com
# 创建时间: 2025-10-31
# 版本: 2.0
# 更新: 2025-11-01 - 改用 Docker 构建以确保架构兼容性

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🚀 开始构建 Lambda Layer (Docker 版本)..."

# 检查 Docker 是否可用
if ! command -v docker &> /dev/null; then
    log_error "Docker 未安装或未启动，请先安装并启动 Docker"
    exit 1
fi

# 检查 Docker 是否运行
if ! docker info &> /dev/null; then
    log_error "Docker 未运行，请启动 Docker"
    exit 1
fi

log_success "Docker 检查通过"

# 清理旧的构建产物
log_info "清理旧的构建产物..."
rm -rf python/

# 构建 Docker 镜像
log_info "构建 Docker 镜像..."
docker build -t lambda-layer-builder . --quiet

if [ $? -ne 0 ]; then
    log_error "Docker 镜像构建失败"
    exit 1
fi

log_success "Docker 镜像构建完成"

# 从容器中复制构建好的依赖包
log_info "从容器中提取依赖包..."

# 创建临时容器
CONTAINER_ID=$(docker create lambda-layer-builder)

if [ $? -ne 0 ]; then
    log_error "创建临时容器失败"
    exit 1
fi

# 复制文件
docker cp "$CONTAINER_ID:/opt/python" ./

if [ $? -ne 0 ]; then
    log_error "复制依赖包失败"
    docker rm "$CONTAINER_ID" &> /dev/null
    exit 1
fi

# 清理临时容器
docker rm "$CONTAINER_ID" &> /dev/null

log_success "依赖包提取完成"

# 验证构建结果
if [ ! -d "python" ]; then
    log_error "构建失败：python 目录不存在"
    exit 1
fi

# 计算大小
LAYER_SIZE=$(du -sh python/ | cut -f1)
log_info "Layer 大小: $LAYER_SIZE"

# 验证关键包是否存在
log_info "验证关键依赖包..."
MISSING_PACKAGES=()

if [ ! -d "python/numpy" ]; then
    MISSING_PACKAGES+=("numpy")
fi

if [ ! -d "python/pandas" ]; then
    MISSING_PACKAGES+=("pandas")
fi

if [ ! -d "python/akshare" ]; then
    MISSING_PACKAGES+=("akshare")
fi

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    log_error "缺少关键依赖包: ${MISSING_PACKAGES[*]}"
    exit 1
fi

log_success "所有关键依赖包验证通过"

# 显示构建结果
echo ""
echo "✅ Lambda Layer 构建完成！"
echo "📋 构建摘要:"
echo "  Layer 大小: $LAYER_SIZE"
echo "  包含的主要依赖:"
ls -1 python/ | grep -E '^(numpy|pandas|akshare|requests)$' | sed 's/^/    - /'

echo ""
echo "🔧 下一步:"
echo "  运行部署脚本: ./scripts/deploy.sh"

# 清理 Docker 镜像（可选）
read -p "是否清理构建用的 Docker 镜像？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker rmi lambda-layer-builder &> /dev/null
    log_info "Docker 镜像已清理"
fi