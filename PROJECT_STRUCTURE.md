# 项目结构说明

## 📁 目录结构

```
Stock_lambda/
├── src/                          # Lambda 函数源代码
│   ├── lambda_function.py        # 主处理器
│   ├── stock_analyzer.py         # 股票分析核心逻辑
│   ├── auth_handler.py           # 认证处理
│   ├── response_builder.py       # 响应构建
│   ├── error_handler.py          # 错误处理
│   ├── logger.py                 # 日志记录
│   └── utils.py                  # 工具函数
├── layers/                       # Lambda Layer 依赖
│   └── dependencies/             # Python 依赖包
│       ├── requirements-layer.txt # Layer 依赖清单
│       ├── Dockerfile            # 构建容器配置
│       ├── Makefile              # 构建脚本
│       └── build-simple.sh       # 简化构建脚本
├── events/                       # 测试事件文件
│   ├── analyze-stock-post.json   # 股票分析请求
│   ├── health-check.json         # 健康检查
│   └── test-stock-get.json       # 股票测试请求
├── scripts/                      # 部署和构建脚本
│   ├── deploy.sh                 # 自动化部署脚本
│   ├── build-layer.sh            # Layer 构建脚本
│   └── pre-deploy-check.sh       # 部署前检查
├── tests/                        # 测试文件
│   └── test_simple.py            # 简单功能测试
├── docs/                         # 项目文档
│   ├── API_USAGE.md              # API 使用指南
│   ├── DEPLOYMENT.md             # 部署指南
│   └── ENVIRONMENT_VARIABLES.md  # 环境变量配置
├── template.yaml                 # SAM 模板文件
├── samconfig.toml                # SAM 配置文件
├── requirements.txt              # Python 依赖
├── README.md                     # 项目说明
└── LICENSE                       # 许可证文件
```

## 🔧 核心组件

### Lambda 函数 (`src/`)
- **lambda_function.py**: 主入口点，处理 API Gateway 事件
- **stock_analyzer.py**: 股票技术分析核心逻辑
- **auth_handler.py**: Bearer Token 认证
- **response_builder.py**: 标准化 API 响应
- **error_handler.py**: 统一错误处理
- **logger.py**: 结构化日志记录
- **utils.py**: 通用工具函数

### Lambda Layer (`layers/dependencies/`)
- 包含 pandas, akshare, numpy 等数据分析库
- 使用 Docker 构建确保 arm64 兼容性
- 优化包大小以符合 AWS 限制

### 部署配置
- **template.yaml**: AWS SAM 基础设施即代码
- **samconfig.toml**: 部署配置参数
- **scripts/**: 自动化部署和构建脚本

### 测试和事件
- **events/**: API Gateway 测试事件模板
- **tests/**: 本地功能测试

## 🚀 快速开始

1. **构建依赖包**:
   ```bash
   cd layers/dependencies
   ./build-simple.sh
   ```

2. **本地测试**:
   ```bash
   sam local start-api --profile susermt
   ```

3. **部署到 AWS**:
   ```bash
   ./scripts/deploy.sh
   ```

## 📝 文档说明

- **README.md**: 完整的项目介绍和使用说明
- **docs/API_USAGE.md**: 详细的 API 使用指南
- **docs/DEPLOYMENT.md**: 部署步骤和故障排除
- **docs/ENVIRONMENT_VARIABLES.md**: 环境变量配置说明

## 🔄 开发工作流

1. 修改源代码 (`src/`)
2. 本地测试 (`sam local start-api`)
3. 运行测试 (`python tests/test_simple.py`)
4. 构建和部署 (`./scripts/deploy.sh`)
5. 验证部署 (测试 API 端点)

## 📦 依赖管理

- **requirements.txt**: Lambda 函数直接依赖
- **layers/dependencies/requirements-layer.txt**: Layer 中的重型依赖
- 使用 Layer 减少函数包大小和冷启动时间