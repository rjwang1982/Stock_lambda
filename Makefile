# Stock Analysis Lambda API Makefile
# 股票分析 Lambda API 构建和部署工具
#
# 作者: RJ.Wang
# 邮箱: wangrenjun@gmail.com
# 创建时间: 2025-11-01
# 版本: 2.0 - 优化版本，减少与部署脚本的重叠

# 配置变量
STACK_NAME := stock-analysis-api
AWS_REGION := cn-northwest-1
AWS_PROFILE := susermt
ENVIRONMENT := prod

.PHONY: help build-layer build deploy deploy-clean test logs status clean delete check dev

# 默认目标
help:
	@echo "Stock Analysis Lambda API - 构建和部署工具"
	@echo ""
	@echo "🚀 主要命令:"
	@echo "  deploy         部署到 AWS (推荐)"
	@echo "  deploy-clean   强制清理后重新部署"
	@echo "  test           测试 API 端点"
	@echo "  status         查看部署状态"
	@echo ""
	@echo "🔧 开发命令:"
	@echo "  build-layer    仅构建 Lambda Layer"
	@echo "  build          仅构建应用（不部署）"
	@echo "  clean          清理本地构建产物"
	@echo "  logs           查看 Lambda 日志"
	@echo "  check          检查构建环境"
	@echo ""
	@echo "⚠️  危险命令:"
	@echo "  delete         删除 AWS 资源"
	@echo ""
	@echo "📋 快捷组合:"
	@echo "  dev            开发模式（清理+构建+部署+测试）"
	@echo ""
	@echo "示例:"
	@echo "  make deploy       # 标准部署"
	@echo "  make dev          # 开发模式"
	@echo "  make test         # 测试 API"

# 检查构建环境
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
	@echo "AWS 配置:"
	@aws sts get-caller-identity --profile $(AWS_PROFILE) --query 'Account' --output text 2>/dev/null || echo "❌ AWS 配置错误"

# 构建 Lambda Layer
build-layer:
	@echo "🚀 构建 Lambda Layer..."
	@cd layers/dependencies && chmod +x build-simple.sh && ./build-simple.sh

# 构建应用（不部署）
build: build-layer
	@echo "🔨 构建 SAM 应用..."
	@sam build --profile $(AWS_PROFILE)
	@echo "✅ 构建完成，使用 'make deploy' 进行部署"

# 标准部署
deploy:
	@echo "� 开始部署...."
	@sam build --profile $(AWS_PROFILE) || (echo "❌ 构建失败，正在尝试重新构建 Layer..." && $(MAKE) build-layer && sam build --profile $(AWS_PROFILE))
	@sam deploy \
		--stack-name $(STACK_NAME) \
		--region $(AWS_REGION) \
		--profile $(AWS_PROFILE) \
		--parameter-overrides Environment=$(ENVIRONMENT) LogLevel=INFO \
		--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
		--no-confirm-changeset \
		--no-fail-on-empty-changeset
	@echo "✅ 部署完成！"
	@$(MAKE) status

# 强制清理后重新部署
deploy-clean: clean
	@echo "🧹 强制清理后重新部署..."
	@echo "⚠️  正在删除现有堆栈..."
	@aws cloudformation delete-stack --stack-name $(STACK_NAME) --region $(AWS_REGION) --profile $(AWS_PROFILE) 2>/dev/null || true
	@echo "等待堆栈删除完成..."
	@aws cloudformation wait stack-delete-complete --stack-name $(STACK_NAME) --region $(AWS_REGION) --profile $(AWS_PROFILE) 2>/dev/null || true
	@echo "开始重新部署..."
	@$(MAKE) deploy

# 测试 API 端点
test:
	@echo "🧪 测试 API 端点..."
	@API_URL=$$(aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(AWS_REGION) \
		--profile $(AWS_PROFILE) \
		--query 'Stacks[0].Outputs[?OutputKey==`StockAnalysisApiUrl`].OutputValue' \
		--output text 2>/dev/null); \
	if [ -n "$$API_URL" ] && [ "$$API_URL" != "None" ]; then \
		echo "📍 API URL: $$API_URL"; \
		echo ""; \
		echo "🔍 健康检查:"; \
		curl -s "$${API_URL}health" | python3 -m json.tool 2>/dev/null || echo "❌ 健康检查失败"; \
		echo ""; \
		echo "🏠 根路径:"; \
		curl -s "$$API_URL" | python3 -m json.tool 2>/dev/null || echo "❌ 根路径测试失败"; \
		echo ""; \
		echo "📈 股票测试 (贵州茅台):"; \
		curl -s "$${API_URL}test-stock/600519?token=xue123" | python3 -c "import sys,json; data=json.load(sys.stdin); print(f\"股票代码: {data.get('data',{}).get('stock_code','N/A')}\"); print(f\"当前价格: {data.get('data',{}).get('price','N/A')}\"); print(f\"技术评分: {data.get('data',{}).get('score','N/A')}\"); print(f\"投资建议: {data.get('data',{}).get('recommendation','N/A')}\")" 2>/dev/null || echo "❌ 股票测试失败"; \
	else \
		echo "❌ 无法获取 API URL，请检查部署状态"; \
	fi

# 查看部署状态
status:
	@echo "📊 查看部署状态..."
	@aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(AWS_REGION) \
		--profile $(AWS_PROFILE) \
		--query 'Stacks[0].{StackName:StackName,Status:StackStatus,Created:CreationTime}' \
		--output table 2>/dev/null || echo "❌ 堆栈不存在"
	@echo ""
	@echo "🔗 API 端点:"
	@aws cloudformation describe-stacks \
		--stack-name $(STACK_NAME) \
		--region $(AWS_REGION) \
		--profile $(AWS_PROFILE) \
		--query 'Stacks[0].Outputs[?OutputKey==`StockAnalysisApiUrl`].OutputValue' \
		--output text 2>/dev/null || echo "❌ 未找到 API URL"

# 查看日志
logs:
	@echo "📋 查看 Lambda 日志..."
	@sam logs --stack-name $(STACK_NAME) --region $(AWS_REGION) --profile $(AWS_PROFILE) --tail

# 清理本地构建产物
clean:
	@echo "🧹 清理本地构建产物..."
	@rm -rf .aws-sam/
	@rm -rf layers/dependencies/python/
	@echo "✅ 清理完成"

# 删除 AWS 资源
delete:
	@echo "⚠️  删除 AWS 资源..."
	@read -p "确定要删除堆栈 $(STACK_NAME) 吗？(y/N): " confirm && \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		aws cloudformation delete-stack --stack-name $(STACK_NAME) --region $(AWS_REGION) --profile $(AWS_PROFILE) && \
		echo "✅ 删除命令已发送，请等待完成"; \
	else \
		echo "❌ 取消删除"; \
	fi

# 开发模式 - 完整流程
dev: clean build deploy test
	@echo "🎉 开发模式部署完成！"

# 生产部署（别名）
prod: deploy

# 快速重新部署（跳过 Layer 构建）
redeploy:
	@echo "⚡ 快速重新部署（跳过 Layer 构建）..."
	@sam build --profile $(AWS_PROFILE)
	@sam deploy \
		--stack-name $(STACK_NAME) \
		--region $(AWS_REGION) \
		--profile $(AWS_PROFILE) \
		--parameter-overrides Environment=$(ENVIRONMENT) LogLevel=INFO \
		--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
		--no-confirm-changeset \
		--no-fail-on-empty-changeset
	@echo "✅ 快速部署完成！"