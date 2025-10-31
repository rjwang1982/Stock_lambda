#!/bin/bash

# 股票分析 Lambda API 部署脚本
# 支持中国区宁夏部署

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

# 配置变量
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STACK_NAME="stock-analysis-api"
AWS_REGION="cn-northwest-1"
AWS_PROFILE="susermt"
ENVIRONMENT="dev"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --stack-name)
            STACK_NAME="$2"
            shift 2
            ;;
        --region)
            AWS_REGION="$2"
            shift 2
            ;;
        --profile)
            AWS_PROFILE="$2"
            shift 2
            ;;
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --help)
            echo "用法: $0 [选项]"
            echo "选项:"
            echo "  --stack-name NAME    CloudFormation 堆栈名称 (默认: stock-analysis-api)"
            echo "  --region REGION      AWS 区域 (默认: cn-northwest-1)"
            echo "  --profile PROFILE    AWS 配置文件 (默认: susermt)"
            echo "  --environment ENV    环境名称 (默认: dev)"
            echo "  --help              显示此帮助信息"
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            exit 1
            ;;
    esac
done

# 显示配置信息
log_info "部署配置:"
log_info "  项目根目录: $PROJECT_ROOT"
log_info "  堆栈名称: $STACK_NAME"
log_info "  AWS 区域: $AWS_REGION"
log_info "  AWS 配置文件: $AWS_PROFILE"
log_info "  环境: $ENVIRONMENT"

# 检查必要工具
check_dependencies() {
    log_info "检查依赖工具..."
    
    if ! command -v sam &> /dev/null; then
        log_error "SAM CLI 未安装，请先安装 SAM CLI"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI 未安装，请先安装 AWS CLI"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    log_success "所有依赖工具检查通过"
}

# 验证 AWS 配置
validate_aws_config() {
    log_info "验证 AWS 配置..."
    
    if ! aws sts get-caller-identity --profile "$AWS_PROFILE" &> /dev/null; then
        log_error "AWS 配置验证失败，请检查配置文件: $AWS_PROFILE"
        exit 1
    fi
    
    local account_id=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query Account --output text)
    local user_arn=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query Arn --output text)
    
    log_success "AWS 配置验证通过"
    log_info "  账户 ID: $account_id"
    log_info "  用户 ARN: $user_arn"
}

# 构建项目
build_project() {
    log_info "构建项目..."
    
    cd "$PROJECT_ROOT"
    
    # 构建 Lambda Layer
    log_info "构建 Lambda Layer..."
    cd layers/dependencies
    if [ -f "build-simple.sh" ]; then
        ./build-simple.sh
    else
        log_warning "未找到 build-simple.sh，跳过 Layer 构建"
    fi
    cd "$PROJECT_ROOT"
    
    # 使用 SAM 构建
    log_info "使用 SAM 构建应用..."
    sam build --profile "$AWS_PROFILE"
    
    # 手动复制 Layer（如果需要）
    if [ -d "layers/dependencies/python" ] && [ ! -d ".aws-sam/build/StockAnalysisLayer/python" ]; then
        log_info "复制 Lambda Layer 到构建目录..."
        mkdir -p .aws-sam/build/StockAnalysisLayer
        cp -r layers/dependencies/python .aws-sam/build/StockAnalysisLayer/
    fi
    
    log_success "项目构建完成"
}

# 验证模板
validate_template() {
    log_info "验证 SAM 模板..."
    
    if sam validate --profile "$AWS_PROFILE"; then
        log_success "SAM 模板验证通过"
    else
        log_error "SAM 模板验证失败"
        exit 1
    fi
}

# 部署应用
deploy_application() {
    log_info "部署应用到 AWS..."
    
    # 检查是否是首次部署
    if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" &> /dev/null; then
        log_info "更新现有堆栈: $STACK_NAME"
        DEPLOY_MODE="update"
    else
        log_info "创建新堆栈: $STACK_NAME"
        DEPLOY_MODE="create"
    fi
    
    # 执行部署
    sam deploy \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" \
        --parameter-overrides \
            Environment="$ENVIRONMENT" \
            LogLevel="INFO" \
        --capabilities CAPABILITY_IAM \
        --no-confirm-changeset \
        --no-fail-on-empty-changeset
    
    if [ $? -eq 0 ]; then
        log_success "应用部署成功"
    else
        log_error "应用部署失败"
        exit 1
    fi
}

# 获取部署信息
get_deployment_info() {
    log_info "获取部署信息..."
    
    # 获取 API Gateway URL
    local api_url=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" \
        --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
        --output text 2>/dev/null)
    
    if [ -n "$api_url" ] && [ "$api_url" != "None" ]; then
        log_success "API Gateway URL: $api_url"
    else
        log_warning "未找到 API Gateway URL"
    fi
    
    # 获取 Lambda 函数名
    local function_name=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" \
        --query 'Stacks[0].Outputs[?OutputKey==`FunctionName`].OutputValue' \
        --output text 2>/dev/null)
    
    if [ -n "$function_name" ] && [ "$function_name" != "None" ]; then
        log_success "Lambda 函数名: $function_name"
    else
        log_warning "未找到 Lambda 函数名"
    fi
}

# 运行部署后测试
run_post_deploy_tests() {
    log_info "运行部署后测试..."
    
    # 获取 API Gateway URL
    local api_url=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" \
        --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayUrl`].OutputValue' \
        --output text 2>/dev/null)
    
    if [ -n "$api_url" ] && [ "$api_url" != "None" ]; then
        log_info "测试健康检查端点..."
        if curl -s -f "$api_url/health" > /dev/null; then
            log_success "健康检查端点测试通过"
        else
            log_warning "健康检查端点测试失败"
        fi
        
        log_info "测试根路径端点..."
        if curl -s -f "$api_url/" > /dev/null; then
            log_success "根路径端点测试通过"
        else
            log_warning "根路径端点测试失败"
        fi
    else
        log_warning "跳过端点测试（未找到 API URL）"
    fi
}

# 清理函数
cleanup() {
    log_info "清理临时文件..."
    # 这里可以添加清理逻辑
}

# 主函数
main() {
    log_info "🚀 开始部署股票分析 Lambda API..."
    
    # 设置清理陷阱
    trap cleanup EXIT
    
    # 执行部署步骤
    check_dependencies
    validate_aws_config
    build_project
    validate_template
    deploy_application
    get_deployment_info
    run_post_deploy_tests
    
    log_success "🎉 部署完成！"
    
    echo ""
    echo "📋 部署摘要:"
    echo "  堆栈名称: $STACK_NAME"
    echo "  AWS 区域: $AWS_REGION"
    echo "  环境: $ENVIRONMENT"
    echo ""
    echo "🔗 有用的命令:"
    echo "  查看堆栈状态: aws cloudformation describe-stacks --stack-name $STACK_NAME --region $AWS_REGION --profile $AWS_PROFILE"
    echo "  查看 Lambda 日志: sam logs --stack-name $STACK_NAME --region $AWS_REGION --profile $AWS_PROFILE"
    echo "  删除堆栈: aws cloudformation delete-stack --stack-name $STACK_NAME --region $AWS_REGION --profile $AWS_PROFILE"
}

# 运行主函数
main "$@"