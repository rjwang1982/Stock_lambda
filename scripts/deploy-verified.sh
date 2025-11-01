#!/bin/bash
# 经过验证的一键部署脚本
#
# 作者: RJ.Wang
# 邮箱: wangrenjun@gmail.com
# 创建时间: 2025-11-01
# 版本: 1.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 配置变量
STACK_NAME="stock-analysis-api"
AWS_REGION="cn-northwest-1"
AWS_PROFILE="susermt"

log_info "🚀 开始经过验证的部署流程..."

# 1. 检查前置条件
log_info "📋 检查前置条件..."

# 检查 AWS 配置
if ! aws sts get-caller-identity --profile $AWS_PROFILE > /dev/null 2>&1; then
    log_error "AWS 配置验证失败，请检查 profile: $AWS_PROFILE"
    exit 1
fi

# 检查 Docker
if ! docker --version > /dev/null 2>&1; then
    log_error "Docker 未安装或未启动"
    exit 1
fi

# 检查必要文件
if [ ! -f "template.yaml" ]; then
    log_error "template.yaml 文件不存在"
    exit 1
fi

if [ ! -f "layers/dependencies/Dockerfile" ]; then
    log_error "layers/dependencies/Dockerfile 文件不存在"
    exit 1
fi

log_success "前置条件检查通过"

# 2. 清理并构建 Layer
log_info "🔧 构建 Lambda Layer..."

# 清理旧的构建产物
log_info "清理旧的构建产物..."
rm -rf layers/dependencies/python/

# 使用 Docker 构建
log_info "使用 Docker 构建 arm64 兼容的依赖包..."
docker build -t lambda-layer-builder layers/dependencies/

# 提取构建结果
log_info "提取构建好的依赖包..."
docker create --name temp-container lambda-layer-builder
docker cp temp-container:/opt/python layers/dependencies/
docker rm temp-container

# 显示 Layer 大小
LAYER_SIZE=$(du -sh layers/dependencies/python/ | cut -f1)
log_success "Layer 构建完成，大小: $LAYER_SIZE"

# 3. SAM 构建
log_info "🏗️ SAM 构建..."
sam build --template template.yaml --profile $AWS_PROFILE

# 验证模板
log_info "验证 SAM 模板..."
sam validate --template template.yaml --profile $AWS_PROFILE
log_success "SAM 构建和验证完成"

# 4. 部署到 AWS
log_info "🚀 部署到 AWS..."
sam deploy \
  --template template.yaml \
  --profile $AWS_PROFILE \
  --region $AWS_REGION \
  --stack-name $STACK_NAME \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --no-confirm-changeset \
  --no-fail-on-empty-changeset

# 5. 验证部署
log_info "🧪 验证部署..."

# 检查堆栈状态
STACK_STATUS=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --region $AWS_REGION \
  --profile $AWS_PROFILE \
  --query 'Stacks[0].StackStatus' \
  --output text)

if [[ "$STACK_STATUS" == "CREATE_COMPLETE" || "$STACK_STATUS" == "UPDATE_COMPLETE" ]]; then
    log_success "CloudFormation 堆栈状态: $STACK_STATUS"
else
    log_error "CloudFormation 堆栈状态异常: $STACK_STATUS"
    exit 1
fi

# 获取 API URL
API_URL=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --region $AWS_REGION \
  --profile $AWS_PROFILE \
  --query 'Stacks[0].Outputs[?OutputKey==`StockAnalysisApiUrl`].OutputValue' \
  --output text)

if [ -z "$API_URL" ]; then
    log_error "无法获取 API URL"
    exit 1
fi

log_success "部署完成！"
echo ""
echo "🔗 API 端点信息:"
echo "   基础 URL: $API_URL"
echo "   健康检查: ${API_URL}health"
echo "   股票测试: ${API_URL}test-stock/600519?token=xue123"
echo "   股票分析: ${API_URL}analyze-stock"

# 6. 测试 API 功能
log_info "🧪 测试 API 功能..."

# 测试健康检查
log_info "测试健康检查端点..."
if curl -s "${API_URL}health" | grep -q "healthy"; then
    log_success "✅ 健康检查通过"
else
    log_warning "❌ 健康检查失败，请手动验证"
fi

# 测试股票查询
log_info "测试股票查询端点..."
if curl -s "${API_URL}test-stock/600519?token=xue123" | grep -q "success"; then
    log_success "✅ 股票查询功能正常"
else
    log_warning "❌ 股票查询功能异常，请手动验证"
fi

echo ""
log_success "🎉 部署和验证完成！"
echo ""
echo "📋 部署摘要:"
echo "   堆栈名称: $STACK_NAME"
echo "   AWS 区域: $AWS_REGION"
echo "   堆栈状态: $STACK_STATUS"
echo "   Layer 大小: $LAYER_SIZE"
echo ""
echo "🔗 有用的命令:"
echo "   查看日志: sam logs --stack-name $STACK_NAME --region $AWS_REGION --profile $AWS_PROFILE"
echo "   删除堆栈: aws cloudformation delete-stack --stack-name $STACK_NAME --region $AWS_REGION --profile $AWS_PROFILE"
echo ""
echo "📖 更多信息请参考: docs/DEPLOYMENT_GUIDE_TESTED.md"