#!/bin/bash
# 部署测试脚本
#
# 作者: RJ.Wang
# 邮箱: wangrenjun@gmail.com
# 创建时间: 2025-11-01

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🧪 测试部署信息获取功能${NC}"

# 获取 API URL
API_URL=$(aws cloudformation describe-stacks \
    --stack-name stock-analysis-api \
    --region cn-northwest-1 \
    --profile susermt \
    --query 'Stacks[0].Outputs[?OutputKey==`StockAnalysisApiUrl`].OutputValue' \
    --output text 2>/dev/null)

if [ -n "$API_URL" ] && [ "$API_URL" != "None" ]; then
    echo -e "${GREEN}✅ API Gateway URL: $API_URL${NC}"
else
    echo -e "${RED}❌ 未找到 API Gateway URL${NC}"
    exit 1
fi

# 获取 Lambda 函数 ARN
FUNCTION_ARN=$(aws cloudformation describe-stacks \
    --stack-name stock-analysis-api \
    --region cn-northwest-1 \
    --profile susermt \
    --query 'Stacks[0].Outputs[?OutputKey==`StockAnalysisFunctionArn`].OutputValue' \
    --output text 2>/dev/null)

if [ -n "$FUNCTION_ARN" ] && [ "$FUNCTION_ARN" != "None" ]; then
    FUNCTION_NAME=$(echo "$FUNCTION_ARN" | awk -F: '{print $NF}')
    echo -e "${GREEN}✅ Lambda 函数名: $FUNCTION_NAME${NC}"
else
    echo -e "${RED}❌ 未找到 Lambda 函数 ARN${NC}"
    exit 1
fi

# 测试健康检查
echo -e "${BLUE}🔍 测试健康检查端点...${NC}"
if curl -s -f "${API_URL}health" > /dev/null; then
    echo -e "${GREEN}✅ 健康检查端点正常${NC}"
else
    echo -e "${RED}❌ 健康检查端点异常${NC}"
    exit 1
fi

# 测试股票查询
echo -e "${BLUE}📈 测试股票查询端点...${NC}"
if curl -s -f "${API_URL}test-stock/600519?token=xue123" > /dev/null; then
    echo -e "${GREEN}✅ 股票查询端点正常${NC}"
else
    echo -e "${RED}❌ 股票查询端点异常${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 所有测试通过！${NC}"
echo ""
echo "📋 部署摘要:"
echo "  API URL: $API_URL"
echo "  Lambda 函数: $FUNCTION_NAME"
echo "  环境: prod"
echo "  状态: 正常运行"