# 经过验证的部署指南

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**创建时间：** 2025-11-01  
**验证日期：** 2025-11-01

本文档记录了经过实际验证的完整部署流程，确保一次性部署成功。

## 🎯 部署目标
- **目标区域**: AWS 中国区宁夏 (cn-northwest-1)
- **架构**: arm64 (AWS Graviton2)
- **运行时**: Python 3.13
- **部署方式**: AWS SAM

## ✅ 前置条件检查

### 必需工具版本
```bash
# 检查工具版本
aws --version        # 需要 >= 2.28.17
sam --version        # 需要 >= 1.135.0
docker --version     # 需要 >= 28.5.1
python --version     # 需要 >= 3.13
```

### AWS 配置验证
```bash
# 验证 AWS 配置
aws sts get-caller-identity --profile susermt
# 确保返回正确的账户信息和区域
```

## 🔧 正确的构建流程

### 步骤 1: 构建 Lambda Layer (关键步骤)

**⚠️ 重要**: 必须使用 Docker 构建以确保 arm64 兼容性

```bash
# 1. 清理旧的构建产物
rm -rf layers/dependencies/python/

# 2. 使用 Docker 构建 Layer
docker build -t lambda-layer-builder layers/dependencies/

# 3. 提取构建好的依赖包
docker create --name temp-container lambda-layer-builder
docker cp temp-container:/opt/python layers/dependencies/
docker rm temp-container

# 4. 验证构建结果
du -sh layers/dependencies/python/
# 预期大小: ~158MB
```

**常见错误及解决方案**:
- ❌ 使用本地 pip 安装会导致 numpy 导入错误
- ✅ 必须使用 Docker 确保 Linux arm64 兼容性

### 步骤 2: SAM 构建

```bash
# 构建 SAM 应用
sam build --template template.yaml --profile susermt

# 验证模板
sam validate --template template.yaml --profile susermt
```

### 步骤 3: 部署到 AWS

```bash
# 一次性部署命令 (包含所有必需参数)
sam deploy \
  --template template.yaml \
  --profile susermt \
  --region cn-northwest-1 \
  --stack-name stock-analysis-api \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --no-confirm-changeset \
  --no-fail-on-empty-changeset
```

**关键参数说明**:
- `--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM`: 必需，否则会失败
- `--no-confirm-changeset`: 避免交互式确认
- `--region cn-northwest-1`: 明确指定中国区宁夏

## 🧪 部署验证

### 检查部署状态
```bash
# 检查 CloudFormation 堆栈状态
aws cloudformation describe-stacks \
  --stack-name stock-analysis-api \
  --region cn-northwest-1 \
  --profile susermt \
  --query 'Stacks[0].StackStatus'
# 预期结果: "CREATE_COMPLETE" 或 "UPDATE_COMPLETE"
```

### 获取 API 端点
```bash
# 获取所有输出信息
aws cloudformation describe-stacks \
  --stack-name stock-analysis-api \
  --region cn-northwest-1 \
  --profile susermt \
  --query 'Stacks[0].Outputs'
```

### API 功能测试
```bash
# 1. 健康检查
curl -s "https://YOUR_API_ID.execute-api.cn-northwest-1.amazonaws.com.cn/prod/health"

# 2. 股票测试 (GET)
curl -s "https://YOUR_API_ID.execute-api.cn-northwest-1.amazonaws.com.cn/prod/test-stock/600519?token=xue123"

# 3. 股票分析 (POST)
curl -X POST "https://YOUR_API_ID.execute-api.cn-northwest-1.amazonaws.com.cn/prod/analyze-stock" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer xue123" \
  -d '{"stock_code": "000001", "market_type": "A"}'
```

## 🚨 常见问题及解决方案

### 问题 1: numpy 导入错误
```
Error: Unable to import numpy: you should not try to import numpy from its source directory
```
**解决方案**: 删除本地构建的 python 目录，使用 Docker 重新构建

### 问题 2: 权限不足错误
```
Error: Requires capabilities : [CAPABILITY_NAMED_IAM]
```
**解决方案**: 在部署命令中添加 `--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM`

### 问题 3: 模板文件路径错误
```
Error: Template file not found
```
**解决方案**: 使用 `--template template.yaml` 明确指定模板路径

## 📋 完整的一键部署脚本

创建 `scripts/deploy-verified.sh`:

```bash
#!/bin/bash
# 经过验证的一键部署脚本
set -e

echo "🚀 开始经过验证的部署流程..."

# 1. 检查前置条件
echo "📋 检查前置条件..."
aws sts get-caller-identity --profile susermt > /dev/null || {
    echo "❌ AWS 配置验证失败"
    exit 1
}

# 2. 清理并构建 Layer
echo "🔧 构建 Lambda Layer..."
rm -rf layers/dependencies/python/
docker build -t lambda-layer-builder layers/dependencies/
docker create --name temp-container lambda-layer-builder
docker cp temp-container:/opt/python layers/dependencies/
docker rm temp-container

echo "📊 Layer 大小: $(du -sh layers/dependencies/python/ | cut -f1)"

# 3. SAM 构建
echo "🏗️ SAM 构建..."
sam build --template template.yaml --profile susermt

# 4. 部署
echo "🚀 部署到 AWS..."
sam deploy \
  --template template.yaml \
  --profile susermt \
  --region cn-northwest-1 \
  --stack-name stock-analysis-api \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --no-confirm-changeset \
  --no-fail-on-empty-changeset

# 5. 验证部署
echo "🧪 验证部署..."
API_URL=$(aws cloudformation describe-stacks \
  --stack-name stock-analysis-api \
  --region cn-northwest-1 \
  --profile susermt \
  --query 'Stacks[0].Outputs[?OutputKey==`StockAnalysisApiUrl`].OutputValue' \
  --output text)

echo "✅ 部署完成！"
echo "🔗 API URL: ${API_URL}"
echo "🏥 健康检查: ${API_URL}health"

# 测试健康检查
if curl -s "${API_URL}health" | grep -q "healthy"; then
    echo "✅ API 健康检查通过"
else
    echo "❌ API 健康检查失败"
fi
```

## 📝 部署检查清单

部署前检查:
- [ ] AWS CLI 已配置 susermt profile
- [ ] Docker 服务正在运行
- [ ] 项目根目录包含 template.yaml
- [ ] layers/dependencies/ 目录存在且包含 Dockerfile

部署后验证:
- [ ] CloudFormation 堆栈状态为 COMPLETE
- [ ] Lambda 函数可以正常调用
- [ ] API Gateway 端点返回正确响应
- [ ] 健康检查接口正常
- [ ] 股票分析功能正常

## 🔄 更新部署

对于后续更新部署，只需重复步骤 2-3:
```bash
# 如果代码有变更，重新构建
sam build --template template.yaml --profile susermt

# 部署更新
sam deploy \
  --template template.yaml \
  --profile susermt \
  --region cn-northwest-1 \
  --stack-name stock-analysis-api \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --no-confirm-changeset \
  --no-fail-on-empty-changeset
```

**注意**: 如果依赖包有变更，需要重新构建 Layer (步骤 1)

---

**验证信息**:
- 部署日期: 2025-11-01
- 验证环境: macOS arm64, Docker Desktop
- AWS 区域: cn-northwest-1
- 部署结果: ✅ 成功

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**文档版本：** v1.0  
**最后更新：** 2025-11-01  
**适用于：** AWS SAM, Lambda 部署, 中国区部署