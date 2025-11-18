# 📊 股票分析工作流文档

**作者**: RJ.Wang  
**邮箱**: wangrenjun@gmail.com  
**创建时间**: 2025-11-18  
**版本**: 1.0

---

## 🎯 概述

这是一个基于 **Dify 平台**的股票技术分析自动化工作流，结合了股票分析 API 和 AI 大模型，为用户提供专业且易懂的投资分析报告。

**工作流名称**：股票分析工作流-小白版  
**图标**：💡  
**模式**：Workflow（工作流模式）

---

## 🚀 核心功能

- ✅ 支持多市场股票分析（A股、港股、美股、ETF、LOF）
- ✅ 自动获取技术指标数据
- ✅ AI 生成专业投资分析报告
- ✅ 智能错误处理和重试机制
- ✅ 结构化数据输出
- ✅ 通俗易懂的小白版解读

---

## 📋 工作流程图

```
┌─────────┐
│  开始   │ 输入股票代码和市场类型
└────┬────┘
     │
     ▼
┌─────────┐
│ 验证输入 │ 检查股票代码是否为空
└────┬────┘
     │
     ├─── 验证失败 ──→ 结束
     │
     ▼ 验证成功
┌──────────────┐
│ 获取股票数据  │ 调用 API 获取技术指标
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ 解析响应数据  │ 提取关键指标和数据
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ AI投资分析   │ 使用通义千问生成报告
└──────┬───────┘
       │
       ▼
┌─────────┐
│  结束   │ 输出完整分析结果
└─────────┘
```

---

## 🔧 节点详解

### 1️⃣ 开始节点 (start)

**功能**：接收用户输入

**输入参数**：

| 参数名 | 类型 | 默认值 | 必填 | 说明 |
|--------|------|--------|------|------|
| `stock_code` | 文本输入 | 002352 | ✅ | 股票代码（最长10字符） |
| `market_type` | 下拉选择 | A | ✅ | 市场类型（A/HK/US/ETF/LOF） |

**市场类型说明**：
- `A`：A股市场
- `HK`：港股市场
- `US`：美股市场
- `ETF`：ETF基金
- `LOF`：LOF基金

---

### 2️⃣ 验证输入节点 (validate)

**功能**：验证股票代码是否为空

**验证条件**：
- 条件：`stock_code` 不为空
- 逻辑运算符：AND

**流程分支**：
- ✅ **验证通过**：继续执行获取股票数据
- ❌ **验证失败**：直接跳转到结束节点

---

### 3️⃣ 获取股票数据节点 (http_request)

**功能**：调用股票分析 API 获取技术指标数据

**请求配置**：

| 配置项 | 值 |
|--------|-----|
| **请求方法** | POST |
| **API地址** | `https://z4jpb59h5g.execute-api.cn-northwest-1.amazonaws.com.cn/prod/analyze-stock` |
| **认证方式** | Bearer Token |
| **Content-Type** | application/json |

**请求头**：
```
Content-Type: application/json
Authorization: Bearer {{env.apikey}}
```

**请求体**：
```json
{
  "stock_code": "{{start.stock_code}}",
  "market_type": "{{start.market_type}}"
}
```

**重试配置**：
- ✅ 启用重试
- 最大重试次数：3次
- 重试间隔：1000ms

**超时设置**：
- 连接超时：3秒
- 读取超时：3秒
- 写入超时：3秒
- 最大连接超时：30秒
- 最大读取超时：60秒
- 最大写入超时：30秒

**SSL验证**：✅ 启用

---

### 4️⃣ 解析响应数据节点 (parse_response)

**功能**：解析 API 返回的 JSON 数据，提取关键指标

**代码语言**：Python 3

**输入变量**：
- `response_body`：HTTP 请求返回的响应体

**输出变量**：

| 变量名 | 类型 | 说明 |
|--------|------|------|
| `technical_summary` | string | 技术指标概要（JSON格式） |
| `report` | string | 完整分析报告（JSON格式） |
| `recent_data` | string | 近期交易数据（最近5条，JSON格式） |
| `stock_code` | string | 股票代码 |
| `price` | string | 当前价格 |
| `score` | string | 综合评分（0-100） |
| `recommendation` | string | 投资建议 |

**核心逻辑**：
```python
import json

def main(response_body: str) -> dict:
    """
    解析API响应数据
    """
    try:
        data = json.loads(response_body)
        
        # 数据在 data 字段下
        stock_data = data.get("data", {})
        technical_summary = stock_data.get("technical_summary", {})
        report = stock_data.get("report", {})
        recent_data = stock_data.get("recent_data", [])
        
        return {
            "technical_summary": json.dumps(technical_summary, ensure_ascii=False, indent=2),
            "report": json.dumps(report, ensure_ascii=False, indent=2),
            "recent_data": json.dumps(recent_data[-5:], ensure_ascii=False, indent=2),
            "stock_code": report.get("stock_code", ""),
            "price": str(report.get("price", 0)),
            "score": str(report.get("score", 0)),
            "recommendation": report.get("recommendation", "")
        }
    except Exception as e:
        return {
            "technical_summary": "{}",
            "report": "{}",
            "recent_data": "[]",
            "stock_code": "",
            "price": "0",
            "score": "0",
            "recommendation": f"解析错误: {str(e)}"
        }
```

---

### 5️⃣ AI投资分析节点 (analyze_llm)

**功能**：使用 AI 大模型生成专业的投资分析报告

**模型配置**：

| 配置项 | 值 |
|--------|-----|
| **模型提供商** | 通义千问 (Tongyi) |
| **模型名称** | qwen3-max-2025-09-23 |
| **模式** | Chat |
| **最大Token数** | 2000 |
| **Temperature** | 0.7 |

**提示词模板**：

```
你是一位专业的股票投资分析师，擅长技术分析和风险评估。

首先输出该股票的名称，再去互联网上搜取最新的与其相关新闻，然后：

请基于以下数据为股票 {{parse_response.stock_code}} 提供专业的投资分析：

## 技术指标概要
{{parse_response.technical_summary}}

## 分析报告
{{parse_response.report}}

## 近期交易数据
{{parse_response.recent_data}}

请提供以下分析：

1. **趋势分析**
   - 当前趋势方向
   - 关键支撑位和压力位
   - 均线系统分析

2. **技术指标解读**
   - RSI指标含义
   - MACD信号分析
   - 成交量变化解读

3. **风险评估**
   - 波动率分析
   - 潜在风险点
   - 风险等级评定

4. **投资建议**
   - 短期操作策略（1-5天）
   - 中期目标价位（1-3个月）
   - 建议止损位
   - 仓位管理建议

5. **综合评分解读**
   - 当前评分：{{parse_response.score}}分
   - 系统建议：{{parse_response.recommendation}}
   - 评分依据说明

请用专业但易懂的语言，给出具体可操作的建议。
```

**分析维度**：
- 📈 **趋势分析**：趋势方向、支撑位/压力位、均线系统
- 📊 **技术指标解读**：RSI、MACD、成交量
- ⚠️ **风险评估**：波动率、风险点、风险等级
- 💡 **投资建议**：短期策略、中期目标、止损位、仓位管理
- 🎯 **综合评分解读**：评分依据和系统建议

---

### 6️⃣ 结束节点 (end)

**功能**：输出完整的分析结果

**输出变量**：

| 变量名 | 来源 | 说明 |
|--------|------|------|
| `stock_code` | parse_response.stock_code | 股票代码 |
| `current_price` | parse_response.price | 当前价格 |
| `score` | parse_response.score | 综合评分 |
| `recommendation` | parse_response.recommendation | 系统建议 |
| `professional_report` | analyze_llm.text | AI生成的专业分析报告 |

---

## 🔐 环境变量配置

### apikey

**描述**：API认证密钥  
**类型**：字符串  
**值**：`8uB32ZB6ZqZVpwZV`  
**用途**：调用股票分析 API 的 Bearer Token 认证

**配置路径**：
```
环境变量 → apikey
```

**使用方式**：
```
Authorization: Bearer {{env.apikey}}
```

---

## 🎨 功能特性

### 已禁用的功能

| 功能 | 状态 | 说明 |
|------|------|------|
| 文件上传 | ❌ 禁用 | 不支持文件上传 |
| 图片上传 | ❌ 禁用 | 不支持图片上传 |
| 语音转文字 | ❌ 禁用 | 不支持语音输入 |
| 文字转语音 | ❌ 禁用 | 不支持语音输出 |
| 敏感词过滤 | ❌ 禁用 | 无敏感词过滤 |
| 建议问题 | ❌ 禁用 | 无自动建议问题 |
| 检索资源 | ❌ 禁用 | 无知识库检索 |

---

## 📦 依赖项

### 通义千问插件

**插件标识**：`langgenius/tongyi:0.1.0`  
**版本哈希**：`a2dd9bb656a2722292e8936f3287d53ba176cfbbe9b8bfafc596d4a2ddd99eb2`  
**类型**：Marketplace 插件

---

## 🚀 使用指南

### 1. 导入工作流

1. 登录 Dify 平台
2. 进入工作流管理页面
3. 点击"导入工作流"
4. 选择 `股票分析工作流-小白版.yml` 文件
5. 确认导入

### 2. 配置环境变量

1. 进入工作流设置
2. 找到"环境变量"配置
3. 设置 `apikey` 为你的 API 密钥
4. 保存配置

### 3. 运行工作流

1. 点击"运行"按钮
2. 输入股票代码（如：`002352`）
3. 选择市场类型（如：`A`）
4. 点击"开始"
5. 等待分析完成

### 4. 查看结果

工作流完成后，你将获得：
- 📊 股票代码和当前价格
- 🎯 综合评分（0-100分）
- 💡 系统投资建议
- 📝 AI生成的专业分析报告

---

## 💡 工作流优势

### 1. 自动化流程
- 从输入到输出全自动
- 无需手动操作
- 节省时间和精力

### 2. 智能错误处理
- 输入验证机制
- 自动重试功能（最多3次）
- 异常捕获和处理

### 3. AI 增强分析
- 使用通义千问大模型
- 生成专业投资分析
- 通俗易懂的解读

### 4. 结构化输出
- 清晰的数据解析
- 标准化的输出格式
- 易于集成和使用

### 5. 小白友好
- 简单的输入界面
- 易懂的分析报告
- 具体可操作的建议

---

## 📊 输出示例

### 基础信息
```
股票代码: 002352
当前价格: 45.23
综合评分: 65
系统建议: 建议买入
```

### AI 分析报告（示例）
```
## 1. 趋势分析
当前该股票处于上升趋势，MA5 > MA20 > MA60，多头排列明显。
关键支撑位：43.50元
关键压力位：47.80元

## 2. 技术指标解读
- RSI(14): 58.5，处于中性偏多区域
- MACD: 金叉信号，短期看涨
- 成交量: 放量上涨，资金流入明显

## 3. 风险评估
- 波动率: 2.3%，属于中等波动
- 风险等级: 中等
- 潜在风险: 短期可能面临获利回吐压力

## 4. 投资建议
- 短期策略: 可适量买入，关注47.80压力位
- 中期目标: 50-52元区间
- 建议止损位: 42.50元
- 仓位管理: 建议仓位不超过30%

## 5. 综合评分解读
当前评分65分，系统建议"建议买入"。
评分依据：技术指标向好，趋势明确，成交量配合良好。
```

---

## ⚠️ 注意事项

### 1. API 限制
- 确保 API 密钥有效
- 注意 API 调用频率限制
- 检查网络连接状态

### 2. 市场支持
- ✅ A股：完全支持
- ✅ 港股：完全支持
- ✅ ETF：完全支持
- ⚠️ LOF：数据源问题，暂不可用
- ⚠️ 美股：数据源问题，暂不可用

### 3. 数据时效性
- 数据更新频率取决于 API
- 建议在交易时间使用
- 收盘后数据更准确

### 4. 投资风险提示
- ⚠️ 本工作流仅供参考，不构成投资建议
- ⚠️ 股市有风险，投资需谨慎
- ⚠️ 请结合自身情况做出投资决策

---

## 🔄 版本历史

### v1.0 (2025-11-18)
- ✅ 初始版本发布
- ✅ 支持 A股、港股、ETF 分析
- ✅ 集成通义千问 AI 分析
- ✅ 完整的错误处理机制

---

## 📞 技术支持

**作者**: RJ.Wang  
**邮箱**: wangrenjun@gmail.com  
**项目地址**: https://github.com/yourusername/Stock_lambda

---

## 📄 许可证

MIT License

---

**最后更新**: 2025-11-18  
**适用平台**: Dify Workflow Platform
