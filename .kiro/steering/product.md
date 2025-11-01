# Product Overview

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**创建时间：** 2025-10-31

## Stock Technical Analysis Lambda API

A serverless stock technical analysis API built on AWS Lambda, providing multi-market stock data analysis and technical indicator calculations.

### Core Features
- **Multi-market Support**: A-shares, Hong Kong stocks, US stocks, ETFs, LOFs
- **Technical Indicators**: Moving averages (MA5/20/60), RSI, MACD, Bollinger Bands, ATR, volume analysis
- **Intelligent Scoring**: Comprehensive 0-100 scoring system based on multiple technical indicators
- **Investment Recommendations**: Buy/sell/hold recommendations based on technical analysis

### Target Markets
- **A-shares**: Chinese mainland stocks (codes starting with 0, 3, 6, 688, 8)
- **Hong Kong**: HK stocks (5-digit codes like 00700)
- **US Markets**: US stocks (alphabetic symbols like AAPL, TSLA)
- **ETFs/LOFs**: Exchange-traded and listed open-end funds

### API Endpoints
- `GET /health` - Health check
- `GET /` - Service status and info
- `GET /test-stock/{code}` - Browser-friendly stock testing
- `POST /analyze-stock` - Full technical analysis

### Authentication
Uses Bearer Token authentication with configurable valid tokens via environment variables.

### Deployment Target
AWS China region (cn-northwest-1) using serverless architecture for high availability and cost efficiency.

---

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**文档版本：** v1.0  
**最后更新：** 2025-10-31  
**适用于：** AWS Lambda, 股票分析, Serverless API