# 项目结构说明

## 📁 目录结构

```
Stock_lambda/
├── src/                          # Lambda 函数源代码
│   ├── lambda_function.py        # 主处理器和路由
│   ├── stock_analyzer.py         # 股票分析核心逻辑
│   ├── auth_handler.py           # Bearer Token 认证
│   ├── response_builder.py       # 标准化 API 响应
│   ├── error_handler.py          # 统一错误处理
│   ├── logger.py                 # 结构化日志记录
│   └── utils.py                  # 通用工具函数
├── layers/dependencies/          # Lambda Layer 依赖包
│   ├── requirements-layer.txt    # Layer 依赖清单
│   ├── Dockerfile               # Docker 构建配置
│   ├── Makefile                 # 构建脚本
│   └── build-simple.sh          # 简化构建脚本
├── events/                      # API Gateway 测试事件
├── scripts/                     # 部署和测试脚本
│   ├── deploy.sh                # 主要部署脚本
│   └── test-deployment.sh       # 部署测试脚本
├── tests/                       # 单元测试
├── docs/                        # 详细文档
├── template.yaml                # SAM 基础设施模板
├── samconfig.toml               # SAM 部署配置
├── Makefile                     # 构建工具
└── requirements.txt             # 函数级依赖
```

## 🔧 核心模块职责

### Lambda 函数模块
- **lambda_function.py**: API Gateway 事件处理和路由分发
- **stock_analyzer.py**: 技术指标计算和股票数据分析
- **auth_handler.py**: 多 Token 认证和权限验证
- **response_builder.py**: 统一 JSON 响应格式和 CORS 处理
- **error_handler.py**: 自定义异常类和错误处理
- **logger.py**: 结构化 JSON 日志和业务事件记录
- **utils.py**: 数据验证、日期处理和参数提取

### 构建和部署
- **Docker 构建**: 确保 arm64 架构兼容性
- **Layer 管理**: 重型依赖包独立管理
- **自动化部署**: 一键部署和资源清理

## 📦 依赖分层

- **Function 层** (`requirements.txt`): 轻量级依赖 (requests 等)
- **Layer 层** (`requirements-layer.txt`): 重型依赖 (pandas, akshare, numpy)

---

*简化版项目结构文档*