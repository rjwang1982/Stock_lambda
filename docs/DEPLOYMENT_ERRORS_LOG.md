# 部署错误记录与解决方案

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**创建时间：** 2025-11-01

本文档记录在部署过程中遇到的所有错误和解决方案，用于避免重复踩坑。

## 📋 错误分类

### 🏗️ 构建阶段错误

#### 错误 1: numpy 导入失败
**时间**: 2025-11-01 首次部署  
**错误信息**:
```
[ERROR] Runtime.ImportModuleError: Unable to import module 'lambda_function': 
Unable to import required dependencies:
numpy: Error importing numpy: you should not try to import numpy from
        its source directory; please exit the numpy source tree, and relaunch
        your python interpreter from there.
```

**原因分析**: 
- 使用本地 pip 安装依赖包到 Lambda Layer
- macOS arm64 架构与 AWS Lambda Linux arm64 环境不兼容
- numpy 等科学计算库需要特定的编译环境

**解决方案**:
```bash
# 删除本地构建的包
rm -rf layers/dependencies/python/

# 使用 Docker 构建 arm64 兼容的包
docker build -t lambda-layer-builder layers/dependencies/
docker create --name temp-container lambda-layer-builder
docker cp temp-container:/opt/python layers/dependencies/
docker rm temp-container
```

**预防措施**: 
- 始终使用 Docker 构建 Lambda Layer
- 不要使用本地 pip 直接安装到 Layer 目录

---

### 🔐 权限配置错误

#### 错误 2: CloudFormation 权限不足
**时间**: 2025-11-01 首次部署  
**错误信息**:
```
Error: Failed to create changeset for the stack: stock-analysis-api, 
ex: Waiter ChangeSetCreateComplete failed: Waiter encountered a terminal failure state: 
For expression "Status" we matched expected path: "FAILED" Status: FAILED. 
Reason: Requires capabilities : [CAPABILITY_NAMED_IAM]
```

**原因分析**: 
- SAM 模板中创建了命名的 IAM 角色
- 需要明确授权 CloudFormation 创建 IAM 资源

**解决方案**:
```bash
# 在部署命令中添加必需的权限
sam deploy \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  # ... 其他参数
```

**预防措施**: 
- 部署脚本中默认包含所有必需权限
- 在部署文档中明确说明权限要求

---

### 📁 路径和目录错误

#### 错误 3: 部署脚本执行目录错误
**时间**: 2025-11-01 重新部署测试  
**错误信息**:
```
[ERROR] template.yaml 文件不存在
zsh: no such file or directory: ./scripts/deploy-verified.sh
```

**原因分析**: 
- 在错误的目录执行部署脚本
- 脚本使用相对路径查找项目文件
- 当前工作目录不是项目根目录

**解决方案**:
```bash
# 确保在项目根目录执行
cd /Users/rj/SyncSpace/WorkSpace/GitHub/Stock_lambda
./scripts/deploy-verified.sh
```

**预防措施**: 
- 在脚本开头添加目录检查
- 提供清晰的错误提示和正确用法
- 在文档中明确说明执行要求

**脚本改进**:
```bash
# 添加目录检查
if [ ! -f "template.yaml" ]; then
    log_error "❌ 未在项目根目录执行脚本"
    log_error "当前目录: $(pwd)"
    log_error "请切换到项目根目录后重新执行"
    exit 1
fi
```

---

### 🌐 网络和连接错误

#### 错误 4: Docker 镜像拉取失败 (潜在)
**预防措施**: 
- 确保 Docker 服务正在运行
- 检查网络连接
- 使用国内镜像源加速

#### 错误 5: AWS API 调用超时 (潜在)
**预防措施**: 
- 检查 AWS 凭证配置
- 确认网络连接稳定
- 使用正确的区域配置

---

## 🔧 通用解决策略

### 1. 环境检查清单
```bash
# 工具版本检查
aws --version        # >= 2.28.17
sam --version        # >= 1.135.0  
docker --version     # >= 28.5.1
python --version     # >= 3.13

# AWS 配置检查
aws sts get-caller-identity --profile susermt

# Docker 服务检查
docker ps
```

### 2. 清理和重置
```bash
# 清理本地构建产物
rm -rf .aws-sam/
rm -rf layers/dependencies/python/

# 删除 AWS 资源
aws cloudformation delete-stack \
  --stack-name stock-analysis-api \
  --region cn-northwest-1 \
  --profile susermt
```

### 3. 逐步调试
```bash
# 1. 单独测试 Layer 构建
docker build -t lambda-layer-builder layers/dependencies/

# 2. 单独测试 SAM 构建
sam build --template template.yaml --profile susermt

# 3. 验证模板
sam validate --template template.yaml --profile susermt
```

## 📊 错误统计

| 错误类型 | 发生次数 | 解决状态 | 预防措施完成度 |
|---------|---------|---------|---------------|
| numpy 导入错误 | 1 | ✅ 已解决 | ✅ 已完成 |
| 权限配置错误 | 1 | ✅ 已解决 | ✅ 已完成 |
| 目录路径错误 | 1 | ✅ 已解决 | ✅ 已完成 |

## 🎯 改进建议

1. **自动化检查**: 在脚本中添加更多前置条件检查
2. **错误恢复**: 提供自动清理和重试机制
3. **用户指导**: 提供更清晰的错误信息和解决步骤
4. **文档完善**: 持续更新部署文档和错误记录

---

**更新记录**:
- 2025-11-01: 初始创建，记录首次部署的3个主要错误
- 后续将持续更新新发现的问题和解决方案

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**文档版本：** v1.0  
**最后更新：** 2025-11-01  
**适用于：** AWS Lambda 部署, 错误排查, 问题预防