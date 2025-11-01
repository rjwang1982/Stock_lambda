# 部署指南

## 📋 更新说明

**版本**: 2.0  
**更新日期**: 2025-11-01  
**主要改进**: Docker 构建 + 自动化部署

### 🔄 主要变更

1. **Docker 构建集成**
   - 解决了本地环境与 Lambda 环境架构不匹配问题
   - 使用 AWS Lambda 官方基础镜像确保兼容性
   - 自动化依赖包构建流程

2. **增强的部署脚本**
   - 添加资源清理功能
   - 支持强制重新部署
   - 改进错误处理和日志输出

3. **Makefile 工具**
   - 简化常用操作命令
   - 统一的构建和部署接口
   - 自动化测试和状态检查

## 🚀 部署方式

### 方式一：Makefile（推荐开发者）

```bash
# 查看所有命令
make help

# 完整部署流程
make clean          # 清理本地构建产物
make build-layer    # 构建 Lambda Layer
make deploy         # 部署到 AWS
make test           # 测试 API
```

### 方式二：传统脚本

```bash
# 构建 Layer
cd layers/dependencies
./build-simple.sh

# 部署应用（默认生产环境）
./scripts/deploy.sh

# 强制清理后部署
./scripts/deploy.sh --force-cleanup
```

## 🔧 构建流程详解

### Lambda Layer 构建

1. **Docker 镜像构建**
   ```bash
   docker build -t lambda-layer-builder layers/dependencies/
   ```

2. **依赖包安装**
   - 在 Linux arm64 容器内安装 Python 包
   - 确保与 Lambda 运行时环境兼容

3. **文件提取**
   ```bash
   docker cp container:/opt/python ./layers/dependencies/
   ```

### SAM 应用构建

1. **函数代码构建**
   ```bash
   sam build --profile susermt
   ```

2. **Layer 集成**
   - 自动复制 Docker 构建的依赖包
   - 验证关键依赖包存在

## 📊 部署验证

### 自动化测试

```bash
make test
```

### 手动验证

1. **健康检查**
   ```bash
   curl https://your-api-url/dev/health
   ```

2. **股票测试**
   ```bash
   curl "https://your-api-url/dev/test-stock/600519?token=xue123"
   ```

## 🛠️ 故障排除

### 常见问题

1. **Docker 未启动**
   ```
   错误: Docker 未运行，请启动 Docker
   解决: 启动 Docker Desktop 或 Docker 服务
   ```

2. **AWS 凭证问题**
   ```
   错误: AWS 配置验证失败
   解决: 检查 ~/.aws/credentials 中的 susermt 配置
   ```

3. **Layer 构建失败**
   ```
   错误: Docker 镜像构建失败
   解决: 检查网络连接，确保能访问 public.ecr.aws
   ```

### 日志查看

```bash
# Lambda 日志
make logs

# CloudFormation 事件
aws cloudformation describe-stack-events --stack-name stock-analysis-api --region cn-northwest-1 --profile susermt
```

## 📈 性能优化

### Layer 优化

- **大小**: ~158MB（优化后）
- **冷启动**: ~200ms
- **架构**: arm64 原生支持

### 成本优化

- **Graviton2 处理器**: 比 x86 节省 20% 成本
- **按需计费**: 仅为实际使用付费
- **Layer 复用**: 多个函数共享依赖包

## 🔄 持续集成

### GitHub Actions（可选）

```yaml
name: Deploy Lambda API
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy
        run: ./scripts/quick-deploy.sh
```

## 📚 相关文档

- [API 使用文档](docs/API_USAGE.md)
- [项目结构说明](docs/PROJECT_STRUCTURE.md)
- [环境变量配置](docs/ENVIRONMENT_VARIABLES.md)

---

**作者**: RJ.Wang  
**邮箱**: wangrenjun@gmail.com  
**更新**: 2025-11-01