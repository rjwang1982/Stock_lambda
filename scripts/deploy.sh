#!/bin/bash
# 股票分析 Lambda API 部署脚本
# 支持中国区宁夏部署
#
# 作者: RJ.Wang
# 邮箱: wangrenjun@gmail.com
# 创建时间: 2025-10-31
# 版本: 1.0

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
ENVIRONMENT="prod"

# 解析命令行参数
FORCE_CLEANUP=false

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
        --force-cleanup)
            FORCE_CLEANUP=true
            shift
            ;;
        --help)
            echo "用法: $0 [选项]"
            echo "选项:"
            echo "  --stack-name NAME    CloudFormation 堆栈名称 (默认: stock-analysis-api)"
            echo "  --region REGION      AWS 区域 (默认: cn-northwest-1)"
            echo "  --profile PROFILE    AWS 配置文件 (默认: susermt)"
            echo "  --force-cleanup     强制清理现有资源后重新部署"
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
        chmod +x build-simple.sh
        ./build-simple.sh
        if [ $? -ne 0 ]; then
            log_error "Lambda Layer 构建失败"
            exit 1
        fi
    else
        log_warning "未找到 build-simple.sh，跳过 Layer 构建"
    fi
    cd "$PROJECT_ROOT"
    
    # 使用 SAM 构建
    log_info "使用 SAM 构建应用..."
    sam build --profile "$AWS_PROFILE"
    
    # 确保 Layer 正确复制到构建目录
    if [ -d "layers/dependencies/python" ]; then
        log_info "复制 Lambda Layer 到构建目录..."
        mkdir -p .aws-sam/build/StockAnalysisLayer
        rm -rf .aws-sam/build/StockAnalysisLayer/python
        cp -r layers/dependencies/python .aws-sam/build/StockAnalysisLayer/
        log_success "Layer 复制完成"
    else
        log_error "Lambda Layer 不存在，请先构建 Layer"
        exit 1
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

# 检查并清理现有资源
check_and_cleanup_existing_resources() {
    log_info "检查现有资源..."
    
    # 检查是否存在同名堆栈
    if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" &> /dev/null; then
        local stack_status=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" --query 'Stacks[0].StackStatus' --output text)
        log_warning "发现现有堆栈: $STACK_NAME (状态: $stack_status)"
        
        # 如果指定了强制清理，直接清理
        if [ "$FORCE_CLEANUP" = true ]; then
            log_warning "强制清理模式，删除现有堆栈"
            cleanup_existing_stack
            return
        fi
        
        # 如果堆栈状态异常，先清理
        case "$stack_status" in
            "ROLLBACK_COMPLETE"|"CREATE_FAILED"|"DELETE_FAILED"|"UPDATE_ROLLBACK_COMPLETE")
                log_warning "堆栈状态异常，需要清理后重新部署"
                cleanup_existing_stack
                ;;
            "DELETE_IN_PROGRESS")
                log_info "堆栈正在删除中，等待删除完成..."
                wait_for_stack_deletion
                ;;
            "CREATE_IN_PROGRESS"|"UPDATE_IN_PROGRESS")
                log_error "堆栈正在操作中，请等待完成后再试"
                exit 1
                ;;
            *)
                log_info "堆栈状态正常，将进行更新部署"
                ;;
        esac
    else
        log_info "未发现现有堆栈，将进行全新部署"
    fi
}

# 清理现有堆栈
cleanup_existing_stack() {
    log_info "开始清理现有堆栈: $STACK_NAME"
    
    # 删除堆栈
    aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE"
    
    if [ $? -eq 0 ]; then
        log_success "堆栈删除命令已发送"
        wait_for_stack_deletion
    else
        log_error "堆栈删除失败"
        exit 1
    fi
}

# 等待堆栈删除完成
wait_for_stack_deletion() {
    log_info "等待堆栈删除完成..."
    
    local max_wait=600  # 最大等待10分钟
    local wait_time=0
    local check_interval=15
    
    while [ $wait_time -lt $max_wait ]; do
        if ! aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" &> /dev/null; then
            log_success "堆栈删除完成"
            return 0
        fi
        
        local stack_status=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" --query 'Stacks[0].StackStatus' --output text 2>/dev/null)
        
        if [ "$stack_status" = "DELETE_FAILED" ]; then
            log_error "堆栈删除失败，请手动检查并清理资源"
            exit 1
        fi
        
        log_info "堆栈状态: $stack_status，继续等待... ($wait_time/$max_wait 秒)"
        sleep $check_interval
        wait_time=$((wait_time + check_interval))
    done
    
    log_error "等待堆栈删除超时"
    exit 1
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
        --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
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
        --query 'Stacks[0].Outputs[?OutputKey==`StockAnalysisApiUrl`].OutputValue' \
        --output text 2>/dev/null)
    
    if [ -n "$api_url" ] && [ "$api_url" != "None" ]; then
        log_success "API Gateway URL: $api_url"
    else
        log_warning "未找到 API Gateway URL"
    fi
    
    # 获取 Lambda 函数 ARN
    local function_arn=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" \
        --query 'Stacks[0].Outputs[?OutputKey==`StockAnalysisFunctionArn`].OutputValue' \
        --output text 2>/dev/null)
    
    if [ -n "$function_arn" ] && [ "$function_arn" != "None" ]; then
        local function_name=$(echo "$function_arn" | awk -F: '{print $NF}')
        log_success "Lambda 函数名: $function_name"
    else
        log_warning "未找到 Lambda 函数 ARN"
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
        --query 'Stacks[0].Outputs[?OutputKey==`StockAnalysisApiUrl`].OutputValue' \
        --output text 2>/dev/null)
    
    if [ -z "$api_url" ] || [ "$api_url" = "None" ]; then
        log_warning "跳过端点测试（未找到 API URL）"
        return 0
    fi
    
    log_info "API URL: $api_url"
    local test_passed=0
    local test_total=0
    
    # 等待 API Gateway 就绪
    log_info "等待 API Gateway 就绪..."
    sleep 10
    
    # 测试健康检查端点
    log_info "测试健康检查端点..."
    test_total=$((test_total + 1))
    local health_response=$(curl -s -w "%{http_code}" -o /tmp/health_response.json "$api_url/health" 2>/dev/null)
    local health_status_code="${health_response: -3}"
    
    if [ "$health_status_code" = "200" ]; then
        log_success "✅ 健康检查端点测试通过 (HTTP $health_status_code)"
        if command -v python3 &> /dev/null && [ -f /tmp/health_response.json ]; then
            log_info "响应内容:"
            python3 -m json.tool /tmp/health_response.json 2>/dev/null | head -10
        fi
        test_passed=$((test_passed + 1))
    else
        log_error "❌ 健康检查端点测试失败 (HTTP $health_status_code)"
        if [ -f /tmp/health_response.json ]; then
            log_info "错误响应:"
            cat /tmp/health_response.json
        fi
    fi
    
    # 测试根路径端点
    log_info "测试根路径端点..."
    test_total=$((test_total + 1))
    local root_response=$(curl -s -w "%{http_code}" -o /tmp/root_response.json "$api_url/" 2>/dev/null)
    local root_status_code="${root_response: -3}"
    
    if [ "$root_status_code" = "200" ]; then
        log_success "✅ 根路径端点测试通过 (HTTP $root_status_code)"
        if command -v python3 &> /dev/null && [ -f /tmp/root_response.json ]; then
            log_info "响应内容:"
            python3 -m json.tool /tmp/root_response.json 2>/dev/null | head -10
        fi
        test_passed=$((test_passed + 1))
    else
        log_error "❌ 根路径端点测试失败 (HTTP $root_status_code)"
        if [ -f /tmp/root_response.json ]; then
            log_info "错误响应:"
            cat /tmp/root_response.json
        fi
    fi
    
    # 测试股票查询端点（带认证）
    log_info "测试股票查询端点..."
    test_total=$((test_total + 1))
    local stock_response=$(curl -s -w "%{http_code}" -o /tmp/stock_response.json "$api_url/test-stock/600519?token=xue123" 2>/dev/null)
    local stock_status_code="${stock_response: -3}"
    
    if [ "$stock_status_code" = "200" ]; then
        log_success "✅ 股票查询端点测试通过 (HTTP $stock_status_code)"
        if command -v python3 &> /dev/null && [ -f /tmp/stock_response.json ]; then
            log_info "股票分析结果 (贵州茅台 600519):"
            python3 -c "
import json
try:
    with open('/tmp/stock_response.json', 'r') as f:
        data = json.load(f)
    if 'data' in data:
        result = data['data']
        print(f\"  股票代码: {result.get('stock_code', 'N/A')}\")
        print(f\"  当前价格: {result.get('price', 'N/A')}\")
        print(f\"  技术评分: {result.get('score', 'N/A')}\")
        print(f\"  投资建议: {result.get('recommendation', 'N/A')}\")
        print(f\"  RSI指标: {result.get('rsi', 'N/A')}\")
except Exception as e:
    print(f'解析响应失败: {e}')
" 2>/dev/null
        fi
        test_passed=$((test_passed + 1))
    else
        log_error "❌ 股票查询端点测试失败 (HTTP $stock_status_code)"
        if [ -f /tmp/stock_response.json ]; then
            log_info "错误响应:"
            cat /tmp/stock_response.json
        fi
    fi
    
    # 清理临时文件
    rm -f /tmp/health_response.json /tmp/root_response.json /tmp/stock_response.json
    
    # 测试结果摘要
    echo ""
    log_info "📊 测试结果摘要:"
    log_info "  通过测试: $test_passed/$test_total"
    
    if [ $test_passed -eq $test_total ]; then
        log_success "🎉 所有端点测试通过！"
    else
        log_warning "⚠️  部分测试失败，请检查日志"
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
    check_and_cleanup_existing_resources
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