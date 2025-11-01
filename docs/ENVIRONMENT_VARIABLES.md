# 环境变量配置指南

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**创建时间：** 2025-10-31

本文档详细说明股票技术分析 Lambda API 的所有环境变量配置选项。

## 目录

- [环境变量概览](#环境变量概览)
- [认证配置](#认证配置)
- [技术指标参数](#技术指标参数)
- [系统配置](#系统配置)
- [日志配置](#日志配置)
- [配置方法](#配置方法)
- [最佳实践](#最佳实践)

## 环境变量概览

### 必需变量

| 变量名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| `VALID_TOKENS` | String | `xue123,xue1234` | 有效的认证令牌列表 |

### 可选变量

| 变量名 | 类型 | 默认值 | 描述 |
|--------|------|--------|------|
| `LOG_LEVEL` | String | `INFO` | 日志级别 |
| `MA_SHORT_PERIOD` | Number | `5` | 短期移动平均线周期 |
| `MA_MEDIUM_PERIOD` | Number | `20` | 中期移动平均线周期 |
| `MA_LONG_PERIOD` | Number | `60` | 长期移动平均线周期 |
| `RSI_PERIOD` | Number | `14` | RSI 指标计算周期 |
| `ENVIRONMENT` | String | `prod` | 部署环境标识 |
| `FUNCTION_VERSION` | String | 自动设置 | 函数版本标识 |

### 系统自动设置

| 变量名 | 描述 |
|--------|------|
| `AWS_REGION` | AWS 区域（自动设置为 cn-northwest-1） |
| `AWS_LAMBDA_FUNCTION_NAME` | Lambda 函数名称 |
| `AWS_LAMBDA_FUNCTION_VERSION` | Lambda 函数版本 |
| `_HANDLER` | Lambda 处理器入口点 |

## 认证配置

### VALID_TOKENS

**描述**: 定义有效的 Bearer Token 列表，用于 API 认证。

**格式**: 逗号分隔的字符串
```bash
VALID_TOKENS="token1,token2,token3"
```

**示例**:
```bash
# 开发环境
VALID_TOKENS="dev-token-123,test-token-456"

# 生产环境
VALID_TOKENS="prod-token-abc,prod-token-xyz,backup-token-999"
```

**安全建议**:
- 使用强随机字符串作为 Token
- 定期轮换 Token
- 不同环境使用不同的 Token
- 避免在日志中记录 Token

**Token 生成示例**:
```python
import secrets
import string

def generate_token(length=32):
    alphabet = string.ascii_letters + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(length))

# 生成示例
print(generate_token())  # 输出: aB3xY9mN2kL8qR5vT1wE4uI7oP6sD0fG
```

## 技术指标参数

### 移动平均线配置

#### MA_SHORT_PERIOD
**描述**: 短期移动平均线计算周期
**类型**: 正整数
**范围**: 1-50
**默认值**: 5

```bash
MA_SHORT_PERIOD=5   # 5日均线
MA_SHORT_PERIOD=10  # 10日均线
```

#### MA_MEDIUM_PERIOD
**描述**: 中期移动平均线计算周期
**类型**: 正整数
**范围**: 1-100
**默认值**: 20

```bash
MA_MEDIUM_PERIOD=20  # 20日均线
MA_MEDIUM_PERIOD=30  # 30日均线
```

#### MA_LONG_PERIOD
**描述**: 长期移动平均线计算周期
**类型**: 正整数
**范围**: 1-200
**默认值**: 60

```bash
MA_LONG_PERIOD=60   # 60日均线
MA_LONG_PERIOD=120  # 120日均线
```

### RSI 配置

#### RSI_PERIOD
**描述**: RSI（相对强弱指数）计算周期
**类型**: 正整数
**范围**: 1-50
**默认值**: 14

```bash
RSI_PERIOD=14  # 14日RSI（标准）
RSI_PERIOD=21  # 21日RSI（较平滑）
RSI_PERIOD=9   # 9日RSI（较敏感）
```

### 技术指标组合建议

#### 短线交易配置
```bash
MA_SHORT_PERIOD=5
MA_MEDIUM_PERIOD=10
MA_LONG_PERIOD=20
RSI_PERIOD=9
```

#### 中线交易配置（默认）
```bash
MA_SHORT_PERIOD=5
MA_MEDIUM_PERIOD=20
MA_LONG_PERIOD=60
RSI_PERIOD=14
```

#### 长线投资配置
```bash
MA_SHORT_PERIOD=10
MA_MEDIUM_PERIOD=30
MA_LONG_PERIOD=120
RSI_PERIOD=21
```

## 系统配置

### LOG_LEVEL

**描述**: 控制日志输出级别
**类型**: 字符串枚举
**可选值**: `DEBUG`, `INFO`, `WARNING`, `ERROR`
**默认值**: `INFO`

```bash
LOG_LEVEL=DEBUG    # 详细调试信息
LOG_LEVEL=INFO     # 一般信息（推荐）
LOG_LEVEL=WARNING  # 仅警告和错误
LOG_LEVEL=ERROR    # 仅错误信息
```

**日志级别说明**:
- **DEBUG**: 包含详细的调试信息，用于开发和故障排除
- **INFO**: 包含一般操作信息，适合生产环境
- **WARNING**: 仅记录警告和错误，减少日志量
- **ERROR**: 仅记录错误信息，最小日志量

### ENVIRONMENT

**描述**: 标识部署环境
**类型**: 字符串
**常用值**: `dev`, `test`, `staging`, `prod`
**默认值**: `prod`

```bash
ENVIRONMENT=dev     # 开发环境
ENVIRONMENT=test    # 测试环境
ENVIRONMENT=staging # 预生产环境
ENVIRONMENT=prod    # 生产环境
```

## 日志配置

### 日志格式

系统使用结构化 JSON 日志格式：

```json
{
  "timestamp": "2024-10-31T10:30:00Z",
  "level": "INFO",
  "message": "股票分析请求",
  "stock_code": "600519",
  "market_type": "A",
  "execution_time_ms": 1250,
  "request_id": "abc123-def456",
  "environment": "prod"
}
```

### 日志内容控制

根据 `LOG_LEVEL` 设置，系统会记录不同级别的信息：

#### DEBUG 级别
```json
{
  "level": "DEBUG",
  "message": "开始获取股票数据",
  "stock_code": "600519",
  "api_url": "https://akshare.api.com/...",
  "parameters": {...}
}
```

#### INFO 级别
```json
{
  "level": "INFO",
  "message": "股票分析完成",
  "stock_code": "600519",
  "score": 75,
  "execution_time_ms": 1250
}
```

#### WARNING 级别
```json
{
  "level": "WARNING",
  "message": "数据获取缓慢",
  "stock_code": "600519",
  "response_time_ms": 8000
}
```

#### ERROR 级别
```json
{
  "level": "ERROR",
  "message": "股票数据获取失败",
  "stock_code": "INVALID",
  "error": "股票代码不存在",
  "stack_trace": "..."
}
```

## 配置方法

### 1. SAM 模板配置

在 `template.yaml` 中配置默认值：

```yaml
Parameters:
  ValidTokens:
    Type: String
    Default: "your-default-tokens"
    NoEcho: true
  
  LogLevel:
    Type: String
    Default: INFO
    AllowedValues: [DEBUG, INFO, WARNING, ERROR]
  
  MAShortPeriod:
    Type: Number
    Default: 5
    MinValue: 1
    MaxValue: 50

Globals:
  Function:
    Environment:
      Variables:
        VALID_TOKENS: !Ref ValidTokens
        LOG_LEVEL: !Ref LogLevel
        MA_SHORT_PERIOD: !Ref MAShortPeriod
```

### 2. 部署时覆盖

使用 SAM 部署时覆盖参数：

```bash
sam deploy \
  --parameter-overrides \
    ValidTokens="prod-token1,prod-token2" \
    LogLevel=INFO \
    MAShortPeriod=10 \
    MAMediumPeriod=30 \
    MALongPeriod=90 \
    RSIPeriod=21
```

### 3. AWS Console 修改

1. 登录 AWS 控制台
2. 进入 Lambda 服务
3. 选择股票分析函数
4. 点击"配置"选项卡
5. 选择"环境变量"
6. 编辑相应变量

### 4. AWS CLI 修改

```bash
# 更新单个环境变量
aws lambda update-function-configuration \
  --function-name stock-analysis-api-stock-analysis \
  --environment Variables='{
    "VALID_TOKENS":"new-token1,new-token2",
    "LOG_LEVEL":"DEBUG",
    "MA_SHORT_PERIOD":"10"
  }' \
  --profile susermt

# 获取当前环境变量
aws lambda get-function-configuration \
  --function-name stock-analysis-api-stock-analysis \
  --query 'Environment.Variables' \
  --profile susermt
```

### 5. 使用 AWS Systems Manager Parameter Store

对于敏感配置，可以使用 Parameter Store：

```yaml
# template.yaml
Resources:
  StockAnalysisFunction:
    Type: AWS::Serverless::Function
    Properties:
      Environment:
        Variables:
          VALID_TOKENS: !Sub "{{resolve:ssm:/stock-api/${Environment}/valid-tokens:1}}"
```

创建参数：
```bash
aws ssm put-parameter \
  --name "/stock-api/prod/valid-tokens" \
  --value "prod-token1,prod-token2" \
  --type "SecureString" \
  --profile susermt
```

## 最佳实践

### 1. 环境分离

为不同环境使用不同的配置：

```bash
# 开发环境
ENVIRONMENT=dev
LOG_LEVEL=DEBUG
VALID_TOKENS="dev-token-123"

# 测试环境
ENVIRONMENT=test
LOG_LEVEL=INFO
VALID_TOKENS="test-token-456"

# 生产环境
ENVIRONMENT=prod
LOG_LEVEL=INFO
VALID_TOKENS="prod-token-789"
```

### 2. 敏感信息保护

```yaml
# 使用 NoEcho 保护敏感参数
Parameters:
  ValidTokens:
    Type: String
    NoEcho: true
    Description: "Valid authentication tokens"
```

### 3. 参数验证

在代码中验证环境变量：

```python
import os
import logging

def validate_environment():
    """验证环境变量配置"""
    errors = []
    
    # 验证必需变量
    valid_tokens = os.getenv('VALID_TOKENS')
    if not valid_tokens:
        errors.append("VALID_TOKENS is required")
    
    # 验证日志级别
    log_level = os.getenv('LOG_LEVEL', 'INFO')
    if log_level not in ['DEBUG', 'INFO', 'WARNING', 'ERROR']:
        errors.append(f"Invalid LOG_LEVEL: {log_level}")
    
    # 验证数值参数
    try:
        ma_short = int(os.getenv('MA_SHORT_PERIOD', 5))
        if ma_short < 1 or ma_short > 50:
            errors.append(f"MA_SHORT_PERIOD out of range: {ma_short}")
    except ValueError:
        errors.append("MA_SHORT_PERIOD must be a number")
    
    if errors:
        raise ValueError(f"Environment validation failed: {', '.join(errors)}")
    
    return True

# 在 Lambda 函数启动时验证
validate_environment()
```

### 4. 配置文档化

创建配置文档模板：

```yaml
# config-template.yaml
# 股票分析 API 环境变量配置模板

# 认证配置
VALID_TOKENS: "token1,token2,token3"  # 必需：有效认证令牌

# 系统配置
LOG_LEVEL: "INFO"                     # 可选：日志级别 [DEBUG|INFO|WARNING|ERROR]
ENVIRONMENT: "prod"                   # 可选：环境标识

# 技术指标配置
MA_SHORT_PERIOD: 5                    # 可选：短期均线周期 [1-50]
MA_MEDIUM_PERIOD: 20                  # 可选：中期均线周期 [1-100]
MA_LONG_PERIOD: 60                    # 可选：长期均线周期 [1-200]
RSI_PERIOD: 14                        # 可选：RSI计算周期 [1-50]
```

### 5. 配置变更管理

```bash
#!/bin/bash
# update-config.sh - 配置更新脚本

STACK_NAME="stock-analysis-api"
ENVIRONMENT="prod"

# 备份当前配置
aws lambda get-function-configuration \
  --function-name "${STACK_NAME}-stock-analysis" \
  --query 'Environment.Variables' \
  --profile susermt > "config-backup-$(date +%Y%m%d-%H%M%S).json"

# 更新配置
sam deploy \
  --stack-name "$STACK_NAME" \
  --parameter-overrides \
    Environment="$ENVIRONMENT" \
    ValidTokens="$NEW_TOKENS" \
    LogLevel="$NEW_LOG_LEVEL" \
  --profile susermt

# 验证更新
echo "配置更新完成，正在验证..."
curl -s "https://your-api-id.execute-api.cn-northwest-1.amazonaws.com.cn/prod/health"
```

## 故障排除

### 常见配置问题

#### 1. Token 认证失败
```bash
# 检查当前 Token 配置
aws lambda get-function-configuration \
  --function-name stock-analysis-api-stock-analysis \
  --query 'Environment.Variables.VALID_TOKENS' \
  --profile susermt
```

#### 2. 日志级别不生效
```bash
# 确认日志级别设置
aws logs filter-log-events \
  --log-group-name "/aws/lambda/stock-analysis-api-stock-analysis" \
  --filter-pattern "{ $.level = \"DEBUG\" }" \
  --profile susermt
```

#### 3. 技术指标参数错误
检查参数范围和类型：
```python
# 在 Lambda 函数中添加调试日志
import os
logger.info(f"MA配置: short={os.getenv('MA_SHORT_PERIOD')}, "
           f"medium={os.getenv('MA_MEDIUM_PERIOD')}, "
           f"long={os.getenv('MA_LONG_PERIOD')}")
```

### 配置恢复

如果配置出现问题，可以快速恢复：

```bash
# 使用备份配置恢复
aws lambda update-function-configuration \
  --function-name stock-analysis-api-stock-analysis \
  --environment file://config-backup-20241031-143000.json \
  --profile susermt
```

---

**注意**: 修改环境变量后，Lambda 函数会自动重启。请确保在低峰时段进行配置变更，并及时验证功能正常。

---

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**文档版本：** v1.0  
**最后更新：** 2025-10-31  
**适用于：** AWS Lambda, 环境变量配置, SAM