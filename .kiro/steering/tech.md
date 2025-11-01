# Technology Stack & Build System

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**创建时间：** 2025-10-31

## Core Technologies
- **Runtime**: Python 3.13 on AWS Lambda (arm64 architecture)
- **Framework**: AWS SAM (Serverless Application Model)
- **Infrastructure**: CloudFormation (Infrastructure as Code)
- **Data Analysis**: pandas, numpy, akshare for stock data
- **API Gateway**: REST API with CORS support

## AWS Services Used
- **AWS Lambda**: Function execution with 512MB memory, 300s timeout
- **API Gateway**: REST API with regional endpoints
- **CloudWatch**: Logging, monitoring, and alarms
- **SQS**: Dead letter queue for error handling
- **Lambda Layers**: Dependency management for heavy libraries
- **IAM**: Role-based access control

## Build System

### Dependencies
- **Layer Dependencies** (`layers/dependencies/requirements-layer.txt`): Heavy libraries (pandas, akshare, numpy)
- **Function Dependencies** (`requirements.txt`): Lightweight libraries (requests)

### Build Commands
```bash
# Build Lambda Layer (requires Docker)
cd layers/dependencies && ./build-simple.sh

# Build entire application
sam build --profile susermt

# Deploy to AWS
sam deploy --profile susermt

# Automated deployment
./scripts/deploy.sh
```

### Local Development
```bash
# Start local API server
sam local start-api --profile susermt

# Test individual function
sam local invoke StockAnalysisFunction --event events/health-check.json

# View logs
sam logs --stack-name stock-analysis-api --profile susermt --tail
```

### Terminal Operations & Troubleshooting
- **Pager Issues**: If terminal gets stuck in `less` or similar pagers (showing help text or long output), press `q` to quit and return to normal command prompt
- **Git Commands**: Some Git commands may open pagers automatically. Use `q` to exit if the terminal appears frozen
- **Log Viewing**: Commands like `git log` may use pagers. Press `q` to exit the pager view
- **Command Recovery**: If a command seems stuck, try pressing `q` first, then `Ctrl+C` if needed

## Configuration Management
- **Environment Variables**: Configured via SAM template parameters
- **Deployment Profiles**: Uses AWS profile `susermt` for China region
- **Multi-environment**: Supports dev/test/prod environments via parameters

## Code Architecture Patterns
- **Modular Design**: Separate modules for analysis, auth, response building, error handling
- **Singleton Pattern**: Global instances for Lambda container reuse optimization
- **Structured Logging**: JSON-formatted logs with correlation IDs
- **Error Handling**: Centralized error handling with custom exception classes

## Performance Optimizations
- **arm64 Architecture**: Cost-effective Graviton2 processors
- **Lambda Layers**: Reduce cold start time and package size
- **Container Reuse**: Global instances for warm starts
- **Proxy Disabling**: Optimized network access for Lambda environment

---

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**文档版本：** v1.0  
**最后更新：** 2025-10-31  
**适用于：** AWS SAM, Lambda, Python, 技术架构