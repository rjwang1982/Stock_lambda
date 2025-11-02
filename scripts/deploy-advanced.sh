#!/bin/bash
# 高级部署脚本 - 处理复杂部署场景
# 
# 作者: RJ.Wang
# 邮箱: wangrenjun@gmail.com
# 创建时间: 2025-11-02
# 版本: 2.0 - 简化版本，专注于高级功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 默认配置
STACK_NAME="stock-analysis-api"
AWS_REGION="cn-northwest-1"
AWS_PROFILE="susermt"
ENVIRONMENT="prod"

# 解析命令行参数
FORCE_CLEANUP=false
DRY_RUN=false
SKIP_TESTS=false

show_help() {
    echo "高级部署脚本 - 处理复杂部署场景"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --stack-name NAME     CloudFormation 堆栈名称 (默认: stock-analysis-api)"
    echo "  --region REGION       AWS 区域 (默认: cn-northwest-1)"
    echo "  --profile PROFILE     AWS 配置文件 (默认: susermt)"
    echo "  --environment ENV     部署环境 (默认: prod)"
    echo "  --force-cleanup       强制清理现有资源后重新部署"
    echo "  --dry-run            仅验证，不执行实际部署"
    echo "  --skip-tests         跳过部署后测试"
    echo "  --help               显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                           # 标准部署"
    echo "  $0 --force-cleanup           # 强制清理后部署"
    echo "  $0 --dry-run                 # 验证部署配置"
    echo "  $0 --environment dev         # 部署到开发环境"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --stack-name) STACK_NAME="$2"; shift 2 ;;
        --region) AWS_REGION="$2"; shift 2 ;;
        --profile) AWS_PROFILE="$2"; shift 2 ;;
        --environment) ENVIRONMENT="$2"; shift 2 ;;
        --force-cleanup) FORCE_CLEANUP=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --skip-tests) SKIP_TESTS=true; shift ;;
        --help) show_help; exit 0 ;;
        *) log_error "未知参数: $1"; show_help; exit 1 ;;
    esac
done

# 验证环境
validate_environment() {
    log_info "验证部署环境..."
    
    # 检查必要工具
    for tool in aws sam docker; do
        if ! command -v $tool &> /dev/null; then
            log_error "$tool 未安装"
            exit 1
        fi
    done
    
    # 验证 AWS 配置
    if ! aws sts get-caller-identity --profile "$AWS_PROFILE" &> /dev/null; then
        log_error "AWS 配置验证失败: $AWS_PROFILE"
        exit 1
    fi
    
    log_success "环境验证通过"
}

# 检查堆栈状态
check_stack_status() {
    log_info "检查堆栈状态..."
    
    if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" &> /dev/null; then
        local status=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" --query 'Stacks[0].StackStatus' --output text)
        log_info "发现现有堆栈: $STACK_NAME (状态: $status)"
        
        case "$status" in
            "ROLLBACK_COMPLETE"|"CREATE_FAILED"|"DELETE_FAILED"|"UPDATE_ROLLBACK_COMPLETE")
                log_warning "堆栈状态异常，建议使用 --force-cleanup"
                if [ "$FORCE_CLEANUP" = false ]; then
                    log_error "请使用 --force-cleanup 参数清理异常堆栈"
                    exit 1
                fi
                ;;
            "CREATE_IN_PROGRESS"|"UPDATE_IN_PROGRESS"|"DELETE_IN_PROGRESS")
                log_error "堆栈正在操作中，请等待完成后再试"
                exit 1
                ;;
        esac
    else
        log_info "未发现现有堆栈，将进行全新部署"
    fi
}

# 强制清理堆栈
force_cleanup_stack() {
    if [ "$FORCE_CLEANUP" = true ]; then
        log_warning "强制清理现有堆栈..."
        
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] 将删除堆栈: $STACK_NAME"
            return 0
        fi
        
        aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE"
        
        log_info "等待堆栈删除完成..."
        aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" 2>/dev/null || {
            log_warning "等待删除超时，继续部署..."
        }
        
        log_success "堆栈清理完成"
    fi
}

# 执行部署
deploy_stack() {
    log_info "开始部署堆栈..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] 将部署堆栈: $STACK_NAME"
        log_info "[DRY RUN] 参数: Environment=$ENVIRONMENT, LogLevel=INFO"
        return 0
    fi
    
    # 构建应用
    log_info "构建应用..."
    sam build --profile "$AWS_PROFILE"
    
    # 部署应用
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
    
    log_success "部署完成"
}

# 运行部署后测试
run_post_deploy_tests() {
    if [ "$SKIP_TESTS" = true ] || [ "$DRY_RUN" = true ]; then
        log_info "跳过部署后测试"
        return 0
    fi
    
    log_info "运行部署后测试..."
    
    # 获取 API URL
    local api_url=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" \
        --query 'Stacks[0].Outputs[?OutputKey==`StockAnalysisApiUrl`].OutputValue' \
        --output text 2>/dev/null)
    
    if [ -z "$api_url" ] || [ "$api_url" = "None" ]; then
        log_warning "无法获取 API URL，跳过测试"
        return 0
    fi
    
    log_info "API URL: $api_url"
    
    # 等待 API 就绪
    sleep 10
    
    # 简单的健康检查
    if curl -s -f "${api_url}health" > /dev/null; then
        log_success "✅ 健康检查通过"
    else
        log_error "❌ 健康检查失败"
        return 1
    fi
    
    # 股票测试
    if curl -s -f "${api_url}test-stock/600519?token=xue123" > /dev/null; then
        log_success "✅ 股票查询测试通过"
    else
        log_error "❌ 股票查询测试失败"
        return 1
    fi
    
    log_success "所有测试通过"
}

# 显示部署摘要
show_deployment_summary() {
    log_info "部署摘要:"
    echo "  堆栈名称: $STACK_NAME"
    echo "  AWS 区域: $AWS_REGION"
    echo "  环境: $ENVIRONMENT"
    echo "  配置文件: $AWS_PROFILE"
    
    if [ "$DRY_RUN" = false ]; then
        echo ""
        echo "🔗 有用的命令:"
        echo "  查看状态: make status"
        echo "  查看日志: make logs"
        echo "  测试 API: make test"
    fi
}

# 主函数
main() {
    log_info "🚀 高级部署脚本启动..."
    
    if [ "$DRY_RUN" = true ]; then
        log_warning "DRY RUN 模式 - 仅验证，不执行实际操作"
    fi
    
    validate_environment
    check_stack_status
    force_cleanup_stack
    deploy_stack
    run_post_deploy_tests
    show_deployment_summary
    
    if [ "$DRY_RUN" = true ]; then
        log_success "🎉 验证完成！"
    else
        log_success "🎉 部署完成！"
    fi
}

# 运行主函数
main "$@"