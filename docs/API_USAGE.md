# API 使用指南

本文档详细说明如何使用股票技术分析 Lambda API 进行股票数据分析。

## 目录

- [API 概览](#api-概览)
- [认证方式](#认证方式)
- [API 端点](#api-端点)
- [请求示例](#请求示例)
- [响应格式](#响应格式)
- [错误处理](#错误处理)
- [最佳实践](#最佳实践)

## API 概览

### 基础信息

- **Base URL**: `https://your-api-id.execute-api.cn-northwest-1.amazonaws.com.cn/prod`
- **协议**: HTTPS
- **数据格式**: JSON
- **字符编码**: UTF-8

### 支持的市场类型

| 市场类型 | 描述 | 股票代码示例 |
|---------|------|-------------|
| A | A股市场 | 600519, 000001, 300750 |
| HK | 港股市场 | 00700, 09988, 01024 |
| US | 美股市场 | AAPL, TSLA, MSFT |
| ETF | 交易型开放式指数基金 | 510300, 159919 |
| LOF | 上市型开放式基金 | 161725, 163407 |

### 技术指标

API 计算以下技术指标：
- **移动平均线 (MA)**: 5日、20日、60日
- **相对强弱指数 (RSI)**: 14日
- **MACD**: 指数平滑移动平均线
- **布林带 (BOLL)**: 20日布林带
- **成交量指标**: 量价关系分析

## 认证方式

API 使用 Bearer Token 认证方式。

### 获取 Token

请联系系统管理员获取有效的认证 Token。

### 使用 Token

在请求头中包含 Authorization 字段：

```http
Authorization: Bearer your-token-here
```

或者在查询参数中传递（仅限 GET 请求）：

```http
GET /test-stock/600519?token=your-token-here
```

## API 端点

### 1. 健康检查

检查 API 服务状态。

```http
GET /health
```

**响应示例**:
```json
{
  "status": "healthy",
  "timestamp": "2024-10-31T10:30:00Z",
  "version": "1.0.0"
}
```

### 2. 根路径状态

获取 API 基本信息。

```http
GET /
```

**响应示例**:
```json
{
  "message": "股票技术分析 API",
  "version": "1.0.0",
  "endpoints": [
    "GET /health",
    "GET /test-stock/{stock_code}",
    "POST /analyze-stock"
  ]
}
```

### 3. 股票测试接口

快速测试股票分析功能，适合浏览器直接访问。

```http
GET /test-stock/{stock_code}?token={token}&market_type={market_type}
```

**路径参数**:
- `stock_code`: 股票代码

**查询参数**:
- `token`: 认证令牌（必需）
- `market_type`: 市场类型（可选，默认为 A）

**响应示例**:
```json
{
  "stock_code": "600519",
  "market_type": "A",
  "score": 75,
  "price": 1680.50,
  "recommendation": "建议买入",
  "analysis_date": "2024-10-31",
  "technical_indicators": {
    "ma5": 1675.20,
    "ma20": 1650.80,
    "ma60": 1620.30,
    "rsi": 65.5,
    "macd": {
      "dif": 12.5,
      "dea": 8.3,
      "histogram": 4.2
    }
  }
}
```

### 4. 股票分析主接口

执行完整的股票技术分析。

```http
POST /analyze-stock
```

**请求头**:
```http
Content-Type: application/json
Authorization: Bearer your-token-here
```

**请求体**:
```json
{
  "stock_code": "600519",
  "market_type": "A",
  "start_date": "20231101",
  "end_date": "20241031"
}
```

**请求参数说明**:
- `stock_code`: 股票代码（必需）
- `market_type`: 市场类型（可选，默认为 A）
- `start_date`: 开始日期，格式 YYYYMMDD（可选）
- `end_date`: 结束日期，格式 YYYYMMDD（可选）

**响应示例**:
```json
{
  "stock_code": "600519",
  "market_type": "A",
  "score": 75,
  "price": 1680.50,
  "recommendation": "建议买入",
  "analysis_date": "2024-10-31",
  "data_period": {
    "start_date": "2023-11-01",
    "end_date": "2024-10-31",
    "total_days": 365
  },
  "technical_indicators": {
    "moving_averages": {
      "ma5": 1675.20,
      "ma20": 1650.80,
      "ma60": 1620.30,
      "trend": "上升"
    },
    "rsi": {
      "value": 65.5,
      "signal": "中性偏强"
    },
    "macd": {
      "dif": 12.5,
      "dea": 8.3,
      "histogram": 4.2,
      "signal": "金叉"
    },
    "bollinger_bands": {
      "upper": 1720.50,
      "middle": 1680.50,
      "lower": 1640.50,
      "position": "中轨附近"
    },
    "volume_analysis": {
      "avg_volume": 2500000,
      "recent_volume": 3200000,
      "volume_ratio": 1.28,
      "signal": "放量"
    }
  },
  "price_analysis": {
    "current_price": 1680.50,
    "price_change": 25.30,
    "price_change_percent": 1.53,
    "high_52w": 1850.00,
    "low_52w": 1420.00,
    "position_in_range": 0.68
  },
  "risk_assessment": {
    "volatility": 0.25,
    "risk_level": "中等",
    "support_level": 1640.00,
    "resistance_level": 1720.00
  }
}
```

## 请求示例

### cURL 示例

#### 健康检查
```bash
curl -X GET "https://your-api-id.execute-api.cn-northwest-1.amazonaws.com.cn/prod/health"
```

#### 股票测试
```bash
curl -X GET "https://your-api-id.execute-api.cn-northwest-1.amazonaws.com.cn/prod/test-stock/600519?token=xue123&market_type=A"
```

#### 股票分析
```bash
curl -X POST "https://your-api-id.execute-api.cn-northwest-1.amazonaws.com.cn/prod/analyze-stock" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer xue123" \
  -d '{
    "stock_code": "600519",
    "market_type": "A",
    "start_date": "20231101",
    "end_date": "20241031"
  }'
```

### Python 示例

```python
import requests
import json

# API 配置
BASE_URL = "https://your-api-id.execute-api.cn-northwest-1.amazonaws.com.cn/prod"
TOKEN = "your-token-here"

# 设置请求头
headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {TOKEN}"
}

# 股票分析请求
def analyze_stock(stock_code, market_type="A", start_date=None, end_date=None):
    url = f"{BASE_URL}/analyze-stock"
    
    payload = {
        "stock_code": stock_code,
        "market_type": market_type
    }
    
    if start_date:
        payload["start_date"] = start_date
    if end_date:
        payload["end_date"] = end_date
    
    response = requests.post(url, headers=headers, json=payload)
    
    if response.status_code == 200:
        return response.json()
    else:
        print(f"错误: {response.status_code} - {response.text}")
        return None

# 使用示例
result = analyze_stock("600519", "A", "20231101", "20241031")
if result:
    print(f"股票代码: {result['stock_code']}")
    print(f"评分: {result['score']}")
    print(f"建议: {result['recommendation']}")
```

### JavaScript 示例

```javascript
// API 配置
const BASE_URL = "https://your-api-id.execute-api.cn-northwest-1.amazonaws.com.cn/prod";
const TOKEN = "your-token-here";

// 股票分析函数
async function analyzeStock(stockCode, marketType = "A", startDate = null, endDate = null) {
    const url = `${BASE_URL}/analyze-stock`;
    
    const payload = {
        stock_code: stockCode,
        market_type: marketType
    };
    
    if (startDate) payload.start_date = startDate;
    if (endDate) payload.end_date = endDate;
    
    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${TOKEN}`
            },
            body: JSON.stringify(payload)
        });
        
        if (response.ok) {
            return await response.json();
        } else {
            console.error(`错误: ${response.status} - ${await response.text()}`);
            return null;
        }
    } catch (error) {
        console.error('请求失败:', error);
        return null;
    }
}

// 使用示例
analyzeStock("600519", "A", "20231101", "20241031")
    .then(result => {
        if (result) {
            console.log(`股票代码: ${result.stock_code}`);
            console.log(`评分: ${result.score}`);
            console.log(`建议: ${result.recommendation}`);
        }
    });
```

## 响应格式

### 成功响应

所有成功的 API 响应都使用 HTTP 状态码 200，并返回 JSON 格式数据。

### 评分系统

API 使用 0-100 的评分系统：
- **80-100**: 强烈建议买入
- **60-79**: 建议买入
- **40-59**: 中性观望
- **20-39**: 建议卖出
- **0-19**: 强烈建议卖出

### 技术指标说明

#### 移动平均线 (MA)
- **金叉**: 短期均线上穿长期均线，看涨信号
- **死叉**: 短期均线下穿长期均线，看跌信号

#### RSI 相对强弱指数
- **> 70**: 超买区域，可能回调
- **30-70**: 正常区域
- **< 30**: 超卖区域，可能反弹

#### MACD
- **DIF > DEA**: 多头市场
- **DIF < DEA**: 空头市场
- **柱状图 > 0**: 动能增强
- **柱状图 < 0**: 动能减弱

## 错误处理

### HTTP 状态码

| 状态码 | 说明 | 处理建议 |
|--------|------|----------|
| 200 | 成功 | 正常处理响应数据 |
| 400 | 请求参数错误 | 检查请求参数格式 |
| 401 | 认证失败 | 检查 Token 是否正确 |
| 403 | 权限不足 | 检查 Token 是否有效 |
| 404 | 端点不存在 | 检查 URL 路径 |
| 429 | 请求过于频繁 | 降低请求频率 |
| 500 | 服务器内部错误 | 稍后重试或联系支持 |

### 错误响应格式

```json
{
  "error": "错误类型",
  "detail": "详细错误信息",
  "timestamp": "2024-10-31T10:30:00Z",
  "request_id": "abc123-def456"
}
```

### 常见错误

#### 1. 认证错误
```json
{
  "error": "认证失败",
  "detail": "无效的 Bearer Token"
}
```

#### 2. 参数错误
```json
{
  "error": "参数验证失败",
  "detail": "股票代码格式不正确"
}
```

#### 3. 数据获取错误
```json
{
  "error": "数据获取失败",
  "detail": "无法获取股票数据，请检查股票代码"
}
```

#### 4. 服务超时
```json
{
  "error": "请求超时",
  "detail": "数据处理时间过长，请稍后重试"
}
```

## 最佳实践

### 1. 错误处理

```python
import requests
import time

def safe_api_call(url, headers, payload, max_retries=3):
    for attempt in range(max_retries):
        try:
            response = requests.post(url, headers=headers, json=payload, timeout=30)
            
            if response.status_code == 200:
                return response.json()
            elif response.status_code == 429:
                # 请求过于频繁，等待后重试
                time.sleep(2 ** attempt)
                continue
            else:
                print(f"API 错误: {response.status_code} - {response.text}")
                return None
                
        except requests.exceptions.Timeout:
            print(f"请求超时，重试 {attempt + 1}/{max_retries}")
            time.sleep(1)
        except requests.exceptions.RequestException as e:
            print(f"请求异常: {e}")
            return None
    
    return None
```

### 2. 批量处理

```python
import asyncio
import aiohttp

async def analyze_multiple_stocks(stock_codes, token):
    async with aiohttp.ClientSession() as session:
        tasks = []
        for code in stock_codes:
            task = analyze_stock_async(session, code, token)
            tasks.append(task)
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        return results

async def analyze_stock_async(session, stock_code, token):
    url = f"{BASE_URL}/analyze-stock"
    headers = {"Authorization": f"Bearer {token}"}
    payload = {"stock_code": stock_code}
    
    async with session.post(url, headers=headers, json=payload) as response:
        if response.status == 200:
            return await response.json()
        else:
            return {"error": f"HTTP {response.status}"}
```

### 3. 缓存策略

```python
import time
from functools import lru_cache

class StockAnalysisClient:
    def __init__(self, base_url, token):
        self.base_url = base_url
        self.token = token
        self._cache = {}
        self._cache_ttl = 300  # 5分钟缓存
    
    def analyze_stock(self, stock_code, use_cache=True):
        cache_key = f"{stock_code}_{int(time.time() // self._cache_ttl)}"
        
        if use_cache and cache_key in self._cache:
            return self._cache[cache_key]
        
        result = self._make_api_call(stock_code)
        
        if result and use_cache:
            self._cache[cache_key] = result
        
        return result
```

### 4. 请求频率控制

```python
import time
from threading import Lock

class RateLimiter:
    def __init__(self, max_calls=10, time_window=60):
        self.max_calls = max_calls
        self.time_window = time_window
        self.calls = []
        self.lock = Lock()
    
    def wait_if_needed(self):
        with self.lock:
            now = time.time()
            # 清理过期的调用记录
            self.calls = [call_time for call_time in self.calls 
                         if now - call_time < self.time_window]
            
            if len(self.calls) >= self.max_calls:
                sleep_time = self.time_window - (now - self.calls[0])
                if sleep_time > 0:
                    time.sleep(sleep_time)
            
            self.calls.append(now)

# 使用示例
rate_limiter = RateLimiter(max_calls=10, time_window=60)

def analyze_with_rate_limit(stock_code):
    rate_limiter.wait_if_needed()
    return analyze_stock(stock_code)
```

### 5. 数据验证

```python
def validate_stock_code(stock_code, market_type="A"):
    """验证股票代码格式"""
    if not stock_code or not isinstance(stock_code, str):
        return False
    
    if market_type == "A":
        # A股代码验证
        return (stock_code.isdigit() and len(stock_code) == 6 and 
                stock_code[0] in ['0', '3', '6', '8'])
    elif market_type == "HK":
        # 港股代码验证
        return (stock_code.isdigit() and len(stock_code) == 5)
    elif market_type == "US":
        # 美股代码验证
        return stock_code.isalpha() and 1 <= len(stock_code) <= 5
    
    return True  # 其他市场类型暂不验证

def validate_date_format(date_str):
    """验证日期格式 YYYYMMDD"""
    if not date_str:
        return True  # 可选参数
    
    try:
        time.strptime(date_str, '%Y%m%d')
        return True
    except ValueError:
        return False
```

## 性能优化建议

1. **使用连接池**: 复用 HTTP 连接以减少延迟
2. **实施缓存**: 对相同请求进行缓存以减少 API 调用
3. **批量处理**: 使用异步请求处理多个股票
4. **错误重试**: 实施指数退避重试策略
5. **请求压缩**: 使用 gzip 压缩减少传输时间

## 支持和反馈

如果您在使用 API 过程中遇到问题，请：

1. 检查本文档中的故障排除部分
2. 查看 [部署指南](DEPLOYMENT.md) 中的调试技巧
3. 联系技术支持团队

---

**注意**: 本 API 提供的股票分析结果仅供参考，不构成投资建议。投资有风险，决策需谨慎。