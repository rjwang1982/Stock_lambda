# Stock Analysis Lambda API Makefile
# 股票分析 Lambda API 构建和部署工具
#
# 作者: RJ.Wang
# 邮箱: wangrenjun@gmail.com
# 创建时间: 2025-11-01
# 版本: 1.0

.PHONY: help build-layer build deploy clean test logs status delete

# 默认目标
help:
	@echo "Stock Analysis Lambda API - 构建和部署工具"
	@echo ""
	@echo "可用命令:"
	@echo "  build-layer    构建 Lambda Layer (使用 Docker)"
	@echo "  build          构建整个应用"
	@echo "  deploy         部署到 AWS"
	@echo "  deploy-clean   清理现有资源后重新部署"
	@echo "  test           测试 API 端点"
	@echo "  logs           查看 Lambda 日志"
	@echo "  status         查看部署状态"
	@echo "  clean          清理本地构建产物"
	@echo "  delete         删除 AWS 资源"
	@echo ""
	@echo "示例:"
	@echo "  make build-layer  # 构建依赖包"
	@echo "  make deploy       # 部署应用"
	@echo "  make test         # 测试 API"

# 构建 Lambda Layer
build-layer:
	@echo "🚀 构建 Lambda Layer..."
	cd layers/dependencies && chmod +x build-simple.sh && ./build-simple.sh

# 构建应用
build: build-layer
	@echo "🔨 构建 SAM 应用..."
	sam build --profile susermt

# 部署应用
deploy:
	@echo "🚀 部署应用..."
	./scripts/deploy.sh

# 清理后重新部署
deploy-clean:
	@echo "🧹 清理现有资源后重新部署..."
	./scripts/deploy.sh --force-cleanup

# 测试 API
test:
	@echo "🧪 测试 API 端点..."
	@API_URL=$$(aws cloudformation describe-stacks --stack-name stock-analysis-api --region cn-northwest-1 --profile susermt --query 'Stacks[0].Outputs[?OutputKey==`StockAnalysisApiUrl`].OutputValue' --output text 2>/dev/null); \
	if [ -n "$$API_URL" ] && [ "$$API_URL" != "None" ]; then \
		echo "健康检查:"; \
		curl -s "$${API_URL}health" | python3 -m json.tool; \
		echo ""; \
		echo "根路径:"; \
		curl -s "$$API_URL" | python3 -m json.tool; \
	else \
		echo "❌ 无法获取 API URL，请检查部署状态"; \
	fi

# 查看日志
logs:
	@echo "📋 查看 Lambda 日志..."
	sam logs --stack-name stock-analysis-api --region cn-northwest-1 --profile susermt --tail

# 查看部署状态
status:
	@echo "📊 查看部署状态..."
	@aws cloudformation describe-stacks --stack-name stock-analysis-api --region cn-northwest-1 --profile susermt --query 'Stacks[0].{StackName:StackName,Status:StackStatus,Created:CreationTime}' --output table 2>/dev/null || echo "堆栈不存在"
	@echo ""
	@echo "API 端点:"
	@aws cloudformation describe-stacks --stack-name stock-analysis-api --region cn-northwest-1 --profile susermt --query 'Stacks[0].Outputs[?OutputKey==`StockAnalysisApiUrl`].OutputValue' --output text 2>/dev/null || echo "未找到 API URL"

# 清理本地构建产物
clean:
	@echo "🧹 清理本地构建产物..."
	rm -rf .aws-sam/
	rm -rf layers/dependencies/python/
	@echo "清理完成"

# 删除 AWS 资源
delete:
	@echo "⚠️  删除 AWS 资源..."
	@read -p "确定要删除堆栈 stock-analysis-api 吗？(y/N): " confirm && \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		aws cloudformation delete-stack --stack-name stock-analysis-api --region cn-northwest-1 --profile susermt && \
		echo "删除命令已发送，请等待完成"; \
	else \
		echo "取消删除"; \
	fi

# 开发模式 - 快速构建和部署
dev: clean build deploy test

# 生产部署（默认）
prod: deploy

# 验证构建环境
check:
	@echo "🔍 检查构建环境..."
	@echo "Docker:"
	@docker --version || echo "❌ Docker 未安装"
	@echo "SAM CLI:"
	@sam --version || echo "❌ SAM CLI 未安装"
	@echo "AWS CLI:"
	@aws --version || echo "❌ AWS CLI 未安装"
	@echo "Python:"
	@python3 --version || echo "❌ Python 3 未安装"