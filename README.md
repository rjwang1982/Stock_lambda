# 股票技术分析 Lambda API

![项目预览](preview.png)

基于 AWS Lambda 的无服务器股票技术分析 API，提供多市场股票数据分析和技术指标计算功能。

## ✨ 核心功能

### 📊 技术分析功能
- **多市场支持**: A股、港股、美股、ETF、LOF 等多个市场
- **技术指标计算**: 
  - 移动平均线（MA5、MA20、MA60）
  - 相对强弱指数（RSI）
  - MACD 指标
  - 布林带（Bollinger Bands）
  - 平均真实波幅（ATR）
  - 成交量分析
- **智能评分系统**: 基于多维度技术指标的综合评分（0-100分）
- **投资建议**: 根据技术分析结果提供买入/卖出/持有建议

### 🔐 安全认证
- Bearer Token 认证机制
- 支持多个有效 Token 配置
- 查询参数和请求头双重认证支持

### 📈 数据源
- 实时股票数据获取（基于 akshare 库）
- 支持历史数据分析
- 自动数据格式标准化处理

## 🏗️ AWS 架构设计

### 核心 AWS 服务

#### 1. **AWS Lambda**
- **运行时**: Python 3.13
- **架构**: arm64 (AWS Graviton2 处理器)
- **内存**: 512MB
- **超时**: 300秒
- **并发**: 支持自动扩缩容

#### 2. **Amazon API Gateway**
- **类型**: REST API
- **集成**: Lambda 代理集成
- **CORS**: 完整跨域支持
- **限流**: 生产环境 100 req/s，突发 200 req/s

#### 3. **AWS Lambda Layers**
- **依赖管理**: pandas, akshare, numpy 等数据分析库
- **架构优化**: arm64 原生构建，使用 Docker 确保兼容性

## 🚀 快速开始

### 前置要求

- **Docker**: 用于构建 Lambda Layer
- **AWS CLI**: 配置 AWS 凭证
- **SAM CLI**: AWS Serverless Application Model
- **Python 3.11+**: 本地开发环境

### 一键部署

```bash
# 克隆项目
git clone <repository-url>
cd Stock_lambda

# 使用 Makefile 部署（推荐）
make deploy
```

### 使用 Makefile（推荐）

```bash
# 查看所有可用命令
make help

# 构建 Lambda Layer
make build-layer

# 部署应用
make deploy

# 清理后重新部署
make deploy-clean

# 测试 API
make test

# 查看日志
make logs

# 查看状态
make status
```

### 手动部署步骤

#### 1. 构建 Lambda Layer

```bash
cd layers/dependencies
chmod +x build-simple.sh
./build-simple.sh
```

#### 2. 部署应用

```bash
# 基本部署（默认生产环境）
./scripts/deploy.sh

# 强制清理后部署
./scripts/deploy.sh --force-cleanup
```

### 构建说明

本项目使用 **Docker 构建** 来确保 Lambda Layer 的架构兼容性：

- **本地环境**: macOS/Linux/Windows
- **目标环境**: AWS Lambda (Linux arm64)
- **构建方式**: Docker 容器内构建，确保二进制兼容性

#### Docker 构建流程

1. 使用 AWS Lambda 官方基础镜像 (`public.ecr.aws/lambda/python:3.13-arm64`)
2. 在容器内安装 Python 依赖包
3. 提取构建好的依赖包到本地
4. 打包为 Lambda Layer
- **版本管理**: 支持 Layer 版本控制

#### 4. **Amazon CloudWatch**
- **日志记录**: 结构化日志，支持查询和分析
- **监控指标**: 函数执行时间、错误率、调用次数
- **告警配置**: 
  - Lambda 错误率告警
  - Lambda 执行时间告警
  - API Gateway 4xx/5xx 错误告警

#### 5. **Amazon SQS**
- **死信队列**: 处理失败请求的容错机制
- **消息保留**: 14天消息保留期

#### 6. **AWS IAM**
- **执行角色**: Lambda 函数执行权限
- **最小权限原则**: 仅授予必要的服务权限
- **资源访问控制**: CloudWatch Logs、SQS 访问权限

### 架构图

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Client/Browser│───▶│  API Gateway     │───▶│  Lambda Function│
│                 │    │  (REST API)      │    │  (Python 3.13)  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                │                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  CloudWatch      │    │  Lambda Layer   │
                       │  (Logs/Metrics)  │    │  (Dependencies) │
                       └──────────────────┘    └─────────────────┘
                                │                        │
                                │                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  CloudWatch      │    │  External APIs  │
                       │  (Alarms)        │    │  (Stock Data)   │
                       └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │  SQS Dead Letter │
                       │  Queue           │
                       └──────────────────┘
```

## 🛠️ 技术栈

- **后端**: Python 3.13
- **框架**: AWS SAM (Serverless Application Model)
- **数据分析**: pandas, numpy
- **股票数据**: akshare
- **基础设施**: Infrastructure as Code (CloudFormation)
- **CI/CD**: AWS SAM CLI

## 📋 API 接口

### 1. 健康检查
```http
GET /health
```

### 2. 根路径状态
```http
GET /
```

### 3. 股票测试接口（浏览器友好）
```http
GET /test-stock/{stock_code}?token={your_token}&market={market_type}
```

**参数说明**:
- `stock_code`: 股票代码（如：600519、00700、AAPL）
- `token`: 认证令牌
- `market`: 市场类型（A/HK/US/ETF/LOF）

### 4. 股票分析主接口
```http
POST /analyze-stock
Authorization: Bearer {your_token}
Content-Type: application/json

{
  "stock_code": "600519",
  "market_type": "A",
  "start_date": "20240101",
  "end_date": "20241031"
}
```

## 🚀 部署指南


### 前置要求

1. **AWS CLI 配置**
   ```bash
   aws configure --profile susermt
   # 配置 Access Key、Secret Key、Region (cn-northwest-1)
   ```

2. **安装 SAM CLI**
   ```bash
   # macOS
   brew install aws-sam-cli
   
   # Windows
   # 下载并安装 SAM CLI MSI
   
   # Linux
   pip install aws-sam-cli
   ```

3. **安装 Docker**
   ```bash
   # 用于构建 Lambda Layer 依赖包
   # 访问 https://docker.com 下载安装
   ```

4. **Python 3.13**
   ```bash
   python --version  # 确保版本为 3.13.x
   ```

### 部署步骤

#### 第一步：克隆项目
```bash
git clone <repository-url>
cd lambda-stock-api
```

#### 第二步：构建依赖包
```bash
# 构建 Lambda Layer
cd layers/dependencies
./build-simple.sh
```

#### 第三步：本地测试（可选）
```bash
# 启动本地 API
sam local start-api --profile susermt

# 在另一个终端测试
curl http://localhost:3000/health
```

#### 第四步：部署到 AWS
```bash
# 使用部署脚本
./scripts/deploy.sh

# 或者手动部署
sam build --profile susermt
sam deploy --profile susermt
```

#### 第五步：验证部署
```bash
# 获取 API Gateway URL
aws cloudformation describe-stacks \
  --stack-name stock-analysis-api \
  --region cn-northwest-1 \
  --profile susermt \
  --query 'Stacks[0].Outputs'

# 测试健康检查
curl https://{api-id}.execute-api.cn-northwest-1.amazonaws.com.cn/prod/health
```

### 环境变量配置

在 `template.yaml` 中配置以下环境变量：

```yaml
Environment:
  Variables:
    LOG_LEVEL: INFO                    # 日志级别
    VALID_TOKENS: "token1,token2"      # 有效认证令牌
    MA_SHORT_PERIOD: 5                 # 短期均线周期
    MA_MEDIUM_PERIOD: 20               # 中期均线周期  
    MA_LONG_PERIOD: 60                 # 长期均线周期
    RSI_PERIOD: 14                     # RSI 指标周期
```

## 📊 使用示例

### 浏览器测试
```
https://{api-id}.execute-api.cn-northwest-1.amazonaws.com.cn/prod/test-stock/600519?token=xue123
```

### cURL 测试
```bash
# 分析贵州茅台
curl -X POST "https://{api-id}.execute-api.cn-northwest-1.amazonaws.com.cn/prod/analyze-stock" \
  -H "Authorization: Bearer xue123" \
  -H "Content-Type: application/json" \
  -d '{
    "stock_code": "600519",
    "market_type": "A"
  }'
```

### Python 客户端
```python
import requests

url = "https://{api-id}.execute-api.cn-northwest-1.amazonaws.com.cn/prod/analyze-stock"
headers = {
    "Authorization": "Bearer xue123",
    "Content-Type": "application/json"
}
data = {
    "stock_code": "600519",
    "market_type": "A"
}

response = requests.post(url, headers=headers, json=data)
result = response.json()
print(f"股票评分: {result['data']['score']}")
print(f"投资建议: {result['data']['recommendation']}")
```

## 💰 成本估算

基于中等使用量（1000次调用/天）：

| 服务 | 月使用量 | 预估成本 (USD) |
|------|----------|----------------|
| Lambda | 30,000 次调用 | $2-3 |
| API Gateway | 30,000 次请求 | $1-2 |
| CloudWatch | 日志和指标 | $1 |
| Lambda Layer | 存储 | $0.1 |
| **总计** | | **$4-6** |

## 🔧 运维管理

### 监控和告警
- CloudWatch Dashboard 查看实时指标
- 错误率超过阈值自动告警
- 执行时间异常监控

### 日志查看
```bash
# 查看最近的日志
aws logs tail "/aws/lambda/stock-analysis-api-stock-analysis" \
  --region cn-northwest-1 \
  --profile susermt \
  --since 1h
```

### 性能优化
- 使用 arm64 架构降低成本
- Lambda Layer 减少冷启动时间
- 合理配置内存和超时时间

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## � 文档

- [API 使用指南](docs/API_USAGE.md) - 详细的 API 使用说明
- [部署指南](docs/DEPLOYMENT.md) - 完整的部署步骤
- [环境变量配置](docs/ENVIRONMENT_VARIABLES.md) - 配置参数说明
- [项目结构说明](PROJECT_STRUCTURE.md) - 详细的目录结构

## � 支目持

如有问题或建议，请发送邮件至 wangrenjun@gmail.com

---

**⚡ 基于 AWS 无服务器架构的股票技术分析 API**

*作者: RJ.Wang | 邮箱: wangrenjun@gmail.com | 版本: v1.0*