#!/bin/bash

# 部署前验证脚本
# 检查所有必要的条件和配置

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
AWS_PROFILE="susermt"
AWS_REGION="cn-northwest-1"
STACK_NAME="stock-analysis-api"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --profile)
            AWS_PROFILE="$2"
            shift 2
            ;;
        --region)
            AWS_REGION="$2"
            shift 2
            ;;
        --stack-name)
            STACK_NAME="$2"
            shift 2
            ;;
        --help)
            echo "用法: $0 [选项]"
            echo "选项:"
            echo "  --profile PROFILE    AWS 配置文件 (默认: susermt)"
            echo "  --region REGION      AWS 区域 (默认: cn-northwest-1)"
            echo "  --stack-name NAME    CloudFormation 堆栈名称 (默认: stock-analysis-api)"
            echo "  --help              显示此帮助信息"
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            exit 1
            ;;
    esac
done

# 检查计数器
CHECKS_PASSED=0
CHECKS_TOTAL=0

# 增加检查计数
check_count() {
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    if [ $? -eq 0 ]; then
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    fi
}

# 检查必要工具
check_required_tools() {
    log_info "检查必要工具..."
    
    local tools=("sam" "aws" "docker" "curl" "jq")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_success "✓ $tool 已安装"
        else
            log_error "✗ $tool 未安装"
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -eq 0 ]; then
        log_success "所有必要工具已安装"
        return 0
    else
        log_error "缺少工具: ${missing_tools[*]}"
        return 1
    fi
}

# 检查 Docker 状态
check_docker_status() {
    log_info "检查 Docker 状态..."
    
    if docker info &> /dev/null; then
        log_success "✓ Docker 运行正常"
        return 0
    else
        log_error "✗ Docker 未运行或无法访问"
        return 1
    fi
}

# 检查 AWS 配置
check_aws_configuration() {
    log_info "检查 AWS 配置..."
    
    # 检查配置文件是否存在
    if aws configure list --profile "$AWS_PROFILE" &> /dev/null; then
        log_success "✓ AWS 配置文件 '$AWS_PROFILE' 存在"
    else
        log_error "✗ AWS 配置文件 '$AWS_PROFILE' 不存在"
        return 1
    fi
    
    # 检查凭证是否有效
    if aws sts get-caller-identity --profile "$AWS_PROFILE" &> /dev/null; then
        local account_id=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query Account --output text)
        local user_arn=$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query Arn --output text)
        log_success "✓ AWS 凭证有效"
        log_info "  账户 ID: $account_id"
        log_info "  用户 ARN: $user_arn"
    else
        log_error "✗ AWS 凭证无效或已过期"
        return 1
    fi
    
    # 检查区域配置
    local configured_region=$(aws configure get region --profile "$AWS_PROFILE")
    if [ "$configured_region" = "$AWS_REGION" ]; then
        log_success "✓ AWS 区域配置正确: $AWS_REGION"
    else
        log_warning "⚠ AWS 区域配置不匹配: 配置=$configured_region, 期望=$AWS_REGION"
    fi
    
    return 0
}

# 检查 AWS 权限
check_aws_permissions() {
    log_info "检查 AWS 权限..."
    
    local required_permissions=(
        "cloudformation:CreateStack"
        "cloudformation:UpdateStack"
        "cloudformation:DescribeStacks"
        "lambda:CreateFunction"
        "lambda:UpdateFunctionCode"
        "apigateway:GET"
        "apigateway:POST"
        "iam:CreateRole"
        "iam:AttachRolePolicy"
        "s3:CreateBucket"
        "s3:PutObject"
    )
    
    # 简单的权限检查 - 尝试列出 CloudFormation 堆栈
    if aws cloudformation list-stacks --region "$AWS_REGION" --profile "$AWS_PROFILE" &> /dev/null; then
        log_success "✓ 基本 CloudFormation 权限可用"
    else
        log_error "✗ 缺少 CloudFormation 权限"
        return 1
    fi
    
    # 检查 Lambda 权限
    if aws lambda list-functions --region "$AWS_REGION" --profile "$AWS_PROFILE" &> /dev/null; then
        log_success "✓ Lambda 权限可用"
    else
        log_error "✗ 缺少 Lambda 权限"
        return 1
    fi
    
    return 0
}

# 检查项目结构
check_project_structure() {
    log_info "检查项目结构..."
    
    cd "$PROJECT_ROOT"
    
    local required_files=(
        "template.yaml"
        "src/lambda_function.py"
        "src/stock_analyzer.py"
        "src/auth_handler.py"
        "src/response_builder.py"
        "src/error_handler.py"
        "src/logger.py"
        "src/utils.py"
        "layers/dependencies/python"
        "events/health-check.json"
        "events/root-path.json"
        "scripts/deploy.sh"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ -e "$file" ]; then
            log_success "✓ $file 存在"
        else
            log_error "✗ $file 缺失"
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        log_success "项目结构完整"
        return 0
    else
        log_error "缺少文件: ${missing_files[*]}"
        return 1
    fi
}

# 检查 SAM 模板
check_sam_template() {
    log_info "检查 SAM 模板..."
    
    cd "$PROJECT_ROOT"
    
    # 验证模板语法
    if sam validate --profile "$AWS_PROFILE" &> /dev/null; then
        log_success "✓ SAM 模板语法正确"
    else
        log_error "✗ SAM 模板语法错误"
        sam validate --profile "$AWS_PROFILE"
        return 1
    fi
    
    # 检查模板中的关键配置
    if grep -q "python3.13" template.yaml; then
        log_success "✓ Python 运行时版本正确"
    else
        log_warning "⚠ 未找到 Python 3.13 运行时配置"
    fi
    
    if grep -q "arm64" template.yaml; then
        log_success "✓ ARM64 架构配置正确"
    else
        log_warning "⚠ 未找到 ARM64 架构配置"
    fi
    
    return 0
}

# 检查 Lambda Layer
check_lambda_layer() {
    log_info "检查 Lambda Layer..."
    
    cd "$PROJECT_ROOT"
    
    if [ -d "layers/dependencies/python" ]; then
        local layer_size=$(du -sh layers/dependencies/python | cut -f1)
        log_success "✓ Lambda Layer 存在，大小: $layer_size"
        
        # 检查关键依赖包
        local required_packages=("pandas" "akshare" "numpy" "requests")
        local missing_packages=()
        
        for package in "${required_packages[@]}"; do
            if [ -d "layers/dependencies/python/$package" ]; then
                log_success "✓ $package 包存在"
            else
                log_error "✗ $package 包缺失"
                missing_packages+=("$package")
            fi
        done
        
        if [ ${#missing_packages[@]} -eq 0 ]; then
            return 0
        else
            log_error "缺少依赖包: ${missing_packages[*]}"
            return 1
        fi
    else
        log_error "✗ Lambda Layer 不存在"
        log_info "请运行: cd layers/dependencies && ./build-simple.sh"
        return 1
    fi
}

# 检查环境变量
check_environment_variables() {
    log_info "检查环境变量配置..."
    
    # 检查 SAM 模板中的环境变量
    local env_vars=("LOG_LEVEL" "AWS_REGION" "VALID_TOKENS" "MA_SHORT_PERIOD" "MA_MEDIUM_PERIOD" "MA_LONG_PERIOD" "RSI_PERIOD")
    
    for var in "${env_vars[@]}"; do
        if grep -q "$var" template.yaml; then
            log_success "✓ $var 环境变量已配置"
        else
            log_warning "⚠ $var 环境变量未在模板中找到"
        fi
    done
    
    return 0
}

# 检查现有堆栈状态
check_existing_stack() {
    log_info "检查现有堆栈状态..."
    
    if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" &> /dev/null; then
        local stack_status=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" --query 'Stacks[0].StackStatus' --output text)
        log_info "现有堆栈状态: $stack_status"
        
        case "$stack_status" in
            "CREATE_COMPLETE"|"UPDATE_COMPLETE")
                log_success "✓ 堆栈状态正常，可以更新"
                ;;
            "CREATE_IN_PROGRESS"|"UPDATE_IN_PROGRESS")
                log_warning "⚠ 堆栈正在操作中，请等待完成"
                return 1
                ;;
            "CREATE_FAILED"|"UPDATE_FAILED"|"ROLLBACK_COMPLETE")
                log_warning "⚠ 堆栈处于失败状态，可能需要手动处理"
                ;;
            *)
                log_warning "⚠ 堆栈状态未知: $stack_status"
                ;;
        esac
    else
        log_info "堆栈不存在，将创建新堆栈"
    fi
    
    return 0
}

# 运行本地测试
run_local_tests() {
    log_info "运行本地测试..."
    
    cd "$PROJECT_ROOT"
    
    if [ -f "test_mock.py" ]; then
        if python3 test_mock.py &> /dev/null; then
            log_success "✓ 本地模拟测试通过"
            return 0
        else
            log_error "✗ 本地模拟测试失败"
            return 1
        fi
    else
        log_warning "⚠ 未找到本地测试文件"
        return 0
    fi
}

# 生成部署摘要
generate_deployment_summary() {
    log_info "生成部署摘要..."
    
    echo ""
    echo "📋 部署前检查摘要:"
    echo "  项目根目录: $PROJECT_ROOT"
    echo "  堆栈名称: $STACK_NAME"
    echo "  AWS 区域: $AWS_REGION"
    echo "  AWS 配置文件: $AWS_PROFILE"
    echo "  检查通过: $CHECKS_PASSED/$CHECKS_TOTAL"
    echo ""
    
    if [ $CHECKS_PASSED -eq $CHECKS_TOTAL ]; then
        log_success "🎉 所有检查通过，可以开始部署！"
        echo ""
        echo "🚀 运行部署命令:"
        echo "  ./scripts/deploy.sh --stack-name $STACK_NAME --region $AWS_REGION --profile $AWS_PROFILE"
        return 0
    else
        log_error "❌ 部分检查失败，请修复问题后重试"
        return 1
    fi
}

# 主函数
main() {
    log_info "🔍 开始部署前验证..."
    
    echo "配置信息:"
    echo "  项目根目录: $PROJECT_ROOT"
    echo "  AWS 配置文件: $AWS_PROFILE"
    echo "  AWS 区域: $AWS_REGION"
    echo "  堆栈名称: $STACK_NAME"
    echo ""
    
    # 执行所有检查
    check_required_tools; check_count
    check_docker_status; check_count
    check_aws_configuration; check_count
    check_aws_permissions; check_count
    check_project_structure; check_count
    check_sam_template; check_count
    check_lambda_layer; check_count
    check_environment_variables; check_count
    check_existing_stack; check_count
    run_local_tests; check_count
    
    # 生成摘要
    generate_deployment_summary
}

# 运行主函数
main "$@"