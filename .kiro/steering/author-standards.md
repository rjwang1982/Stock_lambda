---
inclusion: always
---

# Author Information Standards

## 作者信息规范

所有由 AI 助手生成的文件都必须包含标准化的作者信息。

### 标准作者信息
- **姓名**: RJ.Wang
- **邮箱**: wangrenjun@gmail.com
- **创建时间**: 2025-10-31
- **版本**: 1.0

## 文件头部格式规范

### Python 文件头部格式
```python
#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
[文件功能描述]

作者: RJ.Wang
邮箱: wangrenjun@gmail.com
创建时间: 2025-10-31
版本: 1.0
许可证: MIT
"""
```

### Shell 脚本头部格式
```bash
#!/bin/bash
# [脚本功能描述]
#
# 作者: RJ.Wang
# 邮箱: wangrenjun@gmail.com
# 创建时间: 2025-10-31
# 版本: 1.0
```

### YAML/配置文件头部格式
```yaml
# [配置文件描述]
#
# 作者: RJ.Wang
# 邮箱: wangrenjun@gmail.com
# 创建时间: 2025-10-31
# 版本: 1.0
```

### Dockerfile 头部格式
```dockerfile
# [Dockerfile 描述]
#
# 作者: RJ.Wang
# 邮箱: wangrenjun@gmail.com
# 创建时间: 2025-10-31
# 版本: 1.0
```

### Makefile 头部格式
```makefile
# [Makefile 描述]
#
# 作者: RJ.Wang
# 邮箱: wangrenjun@gmail.com
# 创建时间: 2025-10-31
# 版本: 1.0
```

## 文档格式规范

### Markdown 文档开头格式
```markdown
# [文档标题]

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**创建时间：** 2025-10-31

[文档内容开始...]
```

### Markdown 文档结尾格式
```markdown
---

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**文档版本：** v1.0  
**最后更新：** 2025-10-31  
**适用于：** [相关技术栈，如：AWS Lambda, Python, 股票分析]
```

## 应用规则

### 必须添加作者信息的文件类型
- 所有 Python 源代码文件 (`.py`)
- 所有 Shell 脚本文件 (`.sh`)
- 所有 Markdown 文档文件 (`.md`)
- 所有配置文件 (`Dockerfile`, `Makefile`, `.yaml`, `.yml`)
- 所有 JSON 配置文件（在注释中添加）
- 所有测试文件

### 不需要添加作者信息的文件
- 自动生成的文件（如构建产物）
- 第三方库文件
- 系统配置文件（如 `.gitignore`）
- 数据文件（如 JSON 测试数据）

### 版本控制规范
- **创建时间**: 新文件使用当前日期 (YYYY-MM-DD 格式)
- **版本号**: 新文件从 1.0 开始
- **更新时间**: 修改现有文件时更新"最后更新"字段

### 技术栈标识
在文档结尾的"适用于"字段中，根据文件类型添加相关技术栈：

- **Lambda 函数**: AWS Lambda, Python, Serverless
- **部署脚本**: AWS SAM, CloudFormation, 部署自动化
- **API 文档**: REST API, AWS API Gateway, 股票分析
- **配置文件**: Docker, AWS, 基础设施即代码
- **测试文件**: 单元测试, 集成测试, Python

## 示例应用

### 创建新的 Python 模块
```python
#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
新功能模块

实现特定业务逻辑的核心模块。

作者: RJ.Wang
邮箱: wangrenjun@gmail.com
创建时间: 2025-10-31
版本: 1.0
许可证: MIT
"""

# 模块代码...
```

### 创建新的文档
```markdown
# 新功能说明

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**创建时间：** 2025-10-31

## 概述
[文档内容...]

---

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**文档版本：** v1.0  
**最后更新：** 2025-10-31  
**适用于：** [相关技术栈]
```

## 质量保证

### 检查清单
- [ ] 文件头部包含完整的作者信息
- [ ] 创建时间格式正确 (YYYY-MM-DD)
- [ ] 邮箱地址正确 (wangrenjun@gmail.com)
- [ ] 版本号符合规范
- [ ] 文档包含开头和结尾的作者信息
- [ ] 技术栈标识准确

### 自动化验证
建议在 CI/CD 流程中添加作者信息检查，确保所有新文件都包含标准化的作者信息。

---

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**文档版本：** v1.0  
**最后更新：** 2025-10-31  
**适用于：** 代码规范, 文档标准, 项目管理