# 项目维护指南

**项目**: 股票技术分析 Lambda API  
**作者**: RJ.Wang (wangrenjun@gmail.com)  
**版本**: v1.0  
**最后更新**: 2025-11-02  

## 📋 项目概述

这是一个基于 AWS Lambda 的无服务器股票技术分析 API，提供多市场股票数据分析和技术指标计算功能。

### 核心特性
- 支持 A股、港股、美股、ETF、LOF 多个市场
- 提供移动平均线、RSI、MACD、布林带等技术指标
- 智能评分系统和投资建议
- Bearer Token 认证机制
- 完整的 AWS 无服务器架构

## 🏗️ 项目架构

### 技术栈
- **运行时**: Python 3.13 on AWS Lambda (arm64)
- **框架**: AWS SAM (Serverless Application Model)
- **数据分析**: pandas, numpy, akshare
- **基础设施**: CloudFormation (Infrastructure as Code)

### 目录结构
```
Stock_lambda/
├── src/                    # Lambda 函数源代码
├── layers/dependencies/    # Lambda Layer 依赖包
├── docs/                   # 详细文档
├── scripts/                # 部署和测试脚本
├── events/                 # API Gateway 测试事件
├── tests/                  # 单元测试
├── template.yaml           # SAM 基础设施模板
├── Makefile               # 构建工具
└── README.md              # 项目说明
```

## 🚀 快速开始

### 环境要求
- Docker (用于构建 Lambda Layer)
- AWS CLI (配置 AWS 凭证)
- SAM CLI (AWS Serverless Application Model)
- Python 3.13

### 部署命令
```bash
# 检查环境
make check

# 标准部署
make deploy

# 开发模式（完整流程）
make dev

# 测试 API
make test
```

## 🔧 维护任务

### 日常维护
- **依赖更新**: 定期更新 `requirements.txt` 和 `requirements-layer.txt` 中的包版本
- **安全检查**: 监控 AWS 安全建议和 Python 包安全更新
- **性能监控**: 通过 CloudWatch 监控 Lambda 函数性能

### 定期任务
- **成本优化**: 每月检查 AWS 使用成本和资源配置
- **文档更新**: 确保文档与代码版本同步
- **备份验证**: 验证部署脚本和配置文件的有效性

### 故障排除
- **日志查看**: `make logs` 查看 Lambda 日志
- **状态检查**: `make status` 查看部署状态
- **重新部署**: `make deploy-clean` 强制清理后重新部署

## 📚 相关文档

- [API 使用指南](docs/API_USAGE.md) - 详细的 API 使用说明
- [部署指南](docs/DEPLOYMENT.md) - 完整的部署步骤
- [环境变量配置](docs/ENVIRONMENT_VARIABLES.md) - 配置参数说明

## 🔄 版本历史

### v1.0 (2025-11-02)
- 完成核心功能开发
- 实现多市场股票分析
- 完善文档和部署流程
- 优化项目结构和工具链

## 📞 支持

如有问题或建议，请联系：
- **邮箱**: wangrenjun@gmail.com
- **项目**: AWS Lambda 股票技术分析 API

---

*本项目采用 MIT 许可证，详见 LICENSE 文件。*