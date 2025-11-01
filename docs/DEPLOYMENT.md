# 部署指南

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**创建时间：** 2025-10-31

本文档详细说明如何部署股票技术分析 Lambda API 到 AWS 中国区宁夏（cn-northwest-1）。

## 目录

- [前置要求](#前置要求)
- [环境准备](#环境准备)
- [构建和部署](#构建和部署)
- [部署验证](#部署验证)
- [环境变量配置](#环境变量配置)
- [故障排除](#故障排除)

## 前置要求

### 必需工具

1. **AWS CLI v2**
   ```bash
   # macOS
   brew install awscli
   
   # Linux
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   ```

2. **SAM CLI**
   ```bash
   # macOS
   brew install aws-sam-cli
   
   # Linux
   pip install aws-sam-cli
   ```

3. **Docker**
   ```bash
   # macOS
   brew install --cask docker
   
   # Linux (Ubuntu)
   sudo apt-get update
   sudo apt-get install docker.io
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

4. **Python 3.13**
   ```bash
   # macOS
   brew install python@3.13
   
   # Linux
   sudo apt-get install python3.13 python3.13-venv
   ```

### AWS 账户要求

- AWS 中国区账户
- 具有以下权限的 IAM 用户或角色：
  - CloudFormation 完整权限
  - Lambda 完整权限
  - API Gateway 完整权限
  - IAM 角色创建和管理权限
  - CloudWatch Logs 权限
  - SQS 权限

## 环境准备

### 1. 配置 AWS CLI

```bash
# 配置 AWS 凭证（使用 susermt 配置文件）
aws configure --profile susermt
```

输入以下信息：
- AWS Access Key ID: `你的访问密钥ID`
- AWS Secret Access Key: `你的秘密访问密钥`
- Default region name: `cn-northwest-1`
- Default output format: `json`

### 2. 验证 AWS 配置

```bash
# 验证配置
aws sts get-caller-identity --profile susermt

# 预期输出示例
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws-cn:iam::123456789012:user/username"
}
```

### 3. 启动 Docker

确保 Docker 服务正在运行：
```bash
# 检查 Docker 状态
docker --version
docker ps
```

## 构建和部署

### 方法一：使用自动化脚本（推荐）

```bash
# 进入项目目录
cd lambda-stock-api

# 执行部署脚本
./scripts/deploy.sh

# 或者指定参数
./scripts/deploy.sh \
  --stack-name my-stock-api \
  --environment prod \
  --region cn-northwest-1 \
  --profile susermt
```

### 方法二：手动步骤

#### 1. 构建 Lambda Layer

```bash
# 进入依赖包目录
cd layers/dependencies

# 构建依赖包（使用 Docker 确保 arm64 兼容性）
./build-simple.sh

# 验证构建结果
ls -la python/
```

#### 2. 构建 SAM 应用

```bash
# 返回项目根目录
cd ../../

# 使用 SAM 构建
sam build --profile susermt

# 验证构建结果
ls -la .aws-sam/build/
```

#### 3. 部署到 AWS

```bash
# 首次部署（引导部署）
sam deploy --guided --profile susermt

# 后续部署
sam deploy --profile susermt
```

#### 4. 部署参数配置

首次部署时，SAM 会询问以下参数：

```
Stack Name [sam-app]: stock-analysis-api
AWS Region [cn-northwest-1]: cn-northwest-1
Parameter Environment [prod]: prod
Parameter LogLevel [INFO]: INFO
Parameter ValidTokens [xue123,xue1234]: your-tokens-here
Parameter MAShortPeriod [5]: 5
Parameter MAMediumPeriod [20]: 20
Parameter MALongPeriod [60]: 60
Parameter RSIPeriod [14]: 14
Confirm changes before deploy [y/N]: y
Allow SAM CLI IAM role creation [Y/n]: Y
Save parameters to samconfig.toml [Y/n]: Y
```

## 部署验证

### 1. 检查堆栈状态

```bash
# 查看 CloudFormation 堆栈
aws cloudformation describe-stacks \
  --stack-name stock-analysis-api \
  --region cn-northwest-1 \
  --profile susermt
```

### 2. 获取 API 端点

```bash
# 获取 API Gateway URL
aws cloudformation describe-stacks \
  --stack-name stock-analysis-api \
  --region cn-northwest-1 \
  --profile susermt \
  --query 'Stacks[0].Outputs[?OutputKey==`StockAnalysisApiUrl`].OutputValue' \
  --output text
```

### 3. 测试 API 端点

```bash
# 设置 API URL（替换为实际 URL）
API_URL="https://your-api-id.execute-api.cn-northwest-1.amazonaws.com.cn/prod"

# 测试健康检查
curl "$API_URL/health"

# 测试根路径
curl "$API_URL/"

# 测试股票查询（需要有效 token）
curl "$API_URL/test-stock/600519?token=xue123"

# 测试股票分析（POST 请求）
curl -X POST "$API_URL/analyze-stock" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer xue123" \
  -d '{
    "stock_code": "600519",
    "market_type": "A",
    "start_date": "20231101",
    "end_date": "20241031"
  }'
```

### 4. 查看日志

```bash
# 查看 Lambda 函数日志
sam logs --stack-name stock-analysis-api --profile susermt

# 实时查看日志
sam logs --stack-name stock-analysis-api --profile susermt --tail
```

## 环境变量配置

### 在 SAM 模板中配置

编辑 `template.yaml` 文件中的 Parameters 部分：

```yaml
Parameters:
  ValidTokens:
    Type: String
    Default: "token1,token2,token3"
    Description: Valid authentication tokens (comma separated)
    NoEcho: true
  
  LogLevel:
    Type: String
    Default: INFO
    AllowedValues: [DEBUG, INFO, WARNING, ERROR]
```

### 部署时覆盖参数

```bash
sam deploy \
  --parameter-overrides \
    Environment=prod \
    LogLevel=DEBUG \
    ValidTokens="prod-token1,prod-token2" \
    MAShortPeriod=10 \
  --profile susermt
```

### 通过 AWS Console 修改

1. 登录 AWS 控制台
2. 进入 Lambda 服务
3. 找到股票分析函数
4. 在"配置"选项卡中选择"环境变量"
5. 修改相应的环境变量值

## 故障排除

### 常见问题

#### 1. Docker 构建失败

**问题**: `build-simple.sh` 执行失败
```bash
Error: Cannot connect to the Docker daemon
```

**解决方案**:
```bash
# 启动 Docker 服务
sudo systemctl start docker

# 或者在 macOS 上启动 Docker Desktop
open -a Docker
```

#### 2. SAM 构建失败

**问题**: `sam build` 失败
```bash
Error: PythonPipBuilder:ResolveDependencies - {pandas==2.1.0(wheel)}
```

**解决方案**:
```bash
# 清理构建缓存
sam build --use-container --profile susermt

# 或者手动清理
rm -rf .aws-sam/
sam build --profile susermt
```

#### 3. 部署权限错误

**问题**: 部署时权限不足
```bash
User: arn:aws-cn:iam::123456789012:user/username is not authorized to perform: cloudformation:CreateStack
```

**解决方案**:
确保 IAM 用户具有必要权限，或联系管理员添加以下策略：
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:*",
                "lambda:*",
                "apigateway:*",
                "iam:CreateRole",
                "iam:AttachRolePolicy",
                "iam:PassRole",
                "logs:*",
                "sqs:*"
            ],
            "Resource": "*"
        }
    ]
}
```

#### 4. Lambda 函数超时

**问题**: Lambda 函数执行超时
```bash
Task timed out after 300.00 seconds
```

**解决方案**:
1. 检查股票代码是否有效
2. 检查网络连接
3. 增加 Lambda 超时时间（在 template.yaml 中修改 Timeout 参数）

#### 5. API Gateway 502 错误

**问题**: API 返回 502 Bad Gateway
```bash
{"message": "Internal server error"}
```

**解决方案**:
```bash
# 查看 Lambda 函数日志
aws logs describe-log-groups --profile susermt
aws logs get-log-events \
  --log-group-name "/aws/lambda/stock-analysis-api-stock-analysis" \
  --log-stream-name "latest" \
  --profile susermt
```

### 调试技巧

#### 1. 本地测试

```bash
# 本地启动 API
sam local start-api --profile susermt --port 3000

# 在另一个终端测试
curl http://localhost:3000/health
```

#### 2. 单独调用 Lambda 函数

```bash
# 使用测试事件调用函数
sam local invoke StockAnalysisFunction \
  --event events/health-check.json \
  --profile susermt
```

#### 3. 查看详细日志

```bash
# 设置详细日志级别
export SAM_CLI_TELEMETRY=0
sam logs --stack-name stock-analysis-api --profile susermt --tail
```

## 更新和回滚

### 更新部署

```bash
# 修改代码后重新部署
sam build --profile susermt
sam deploy --profile susermt
```

### 回滚到上一版本

```bash
# 查看堆栈事件
aws cloudformation describe-stack-events \
  --stack-name stock-analysis-api \
  --profile susermt

# 如果需要回滚，删除当前堆栈并重新部署上一版本
aws cloudformation delete-stack \
  --stack-name stock-analysis-api \
  --profile susermt
```

## 清理资源

### 删除整个堆栈

```bash
# 删除 CloudFormation 堆栈（会删除所有相关资源）
aws cloudformation delete-stack \
  --stack-name stock-analysis-api \
  --region cn-northwest-1 \
  --profile susermt

# 确认删除状态
aws cloudformation describe-stacks \
  --stack-name stock-analysis-api \
  --region cn-northwest-1 \
  --profile susermt
```

### 清理本地构建文件

```bash
# 清理 SAM 构建文件
rm -rf .aws-sam/

# 清理 Layer 构建文件
rm -rf layers/dependencies/python/
```

## 下一步

部署完成后，请参考以下文档：
- [API 使用指南](API_USAGE.md) - 了解如何使用 API
- [运维监控指南](OPERATIONS.md) - 了解如何监控和维护系统

---

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**文档版本：** v1.0  
**最后更新：** 2025-10-31  
**适用于：** AWS SAM, Lambda 部署, 中国区部署