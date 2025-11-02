# 更新日志

## [2.0.3] - 2025-11-02

### 🔧 修复
- **更新提示信息**: 修复 `build-simple.sh` 中过时的部署脚本引用
- **文档同步**: 更新文档中的部署命令，使用新的 Makefile 工具链
- **项目清理**: 完成全面的项目清理和优化

### 📝 具体修复
- ✅ 修正 Layer 构建完成后的提示信息
- ✅ 更新部署文档中的命令示例
- ✅ 统一使用 `make deploy` 作为标准部署方式

## [2.0.2] - 2025-11-01

### 🐛 修复
- **修复部署信息获取**: 更正 CloudFormation 输出键名查询
- **改进部署后测试**: 修复 API URL 和函数名获取逻辑
- **增强测试脚本**: 新增独立的部署测试脚本

### 📝 具体修复
- ✅ 修正 `ApiGatewayUrl` → `StockAnalysisApiUrl`
- ✅ 修正 `FunctionName` → `StockAnalysisFunctionArn`
- ✅ 新增 `scripts/test-deployment.sh` 测试脚本

## [2.0.1] - 2025-11-01

### 🔄 变更
- **简化部署配置**: 移除环境参数选项，默认使用生产环境
- **优化用户体验**: 减少部署时的参数配置复杂度

### 📝 具体修改

#### 部署脚本 (`scripts/deploy.sh`)
- ✅ 移除 `--environment ENV` 参数选项
- ✅ 默认环境从 `dev` 改为 `prod`
- ✅ 简化帮助信息

#### Makefile
- ✅ 更新生产部署命令，移除环境参数
- ✅ 保持其他命令不变

#### 文档更新
- ✅ 更新 `README.md` 部署说明
- ✅ 更新 `DEPLOYMENT_GUIDE.md` 示例命令
- ✅ 移除环境相关的配置说明

### 🚀 现在的部署方式

```bash
# 一键部署（生产环境）
./scripts/quick-deploy.sh

# 标准部署（生产环境）
make deploy

# 强制清理后部署
make deploy-clean

# 使用 Makefile
make deploy
make deploy-clean
```

### ⚙️ 技术细节

- **默认环境**: `prod`
- **CloudFormation 参数**: `Environment=prod`
- **向后兼容**: 现有部署不受影响
- **模板配置**: `template.yaml` 中默认值已为 `prod`

---

## [2.0.0] - 2025-11-01

### 🎉 重大更新
- **Docker 构建集成**: 解决架构兼容性问题
- **自动化部署工具**: 新增 Makefile 和一键部署脚本
- **增强的错误处理**: 改进部署脚本的可靠性

### 🔧 新功能
- Docker 构建 Lambda Layer
- 资源清理和强制重新部署
- 自动化测试和状态检查
- 完整的部署指南文档

---

**维护者**: RJ.Wang  
**邮箱**: wangrenjun@gmail.com