#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
股票技术分析核心模块

从原始 FastAPI 应用提取的股票分析逻辑，适配 Lambda 环境。
保持所有计算逻辑不变，移除 FastAPI 相关依赖。

Author: RJ.Wang (Lambda 适配)
License: MIT
"""

import os
import pandas as pd
import akshare as ak
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, Tuple


class StockAnalyzer:
    """股票技术分析器"""
    
    def __init__(self):
        """初始化分析器，配置技术指标参数"""
        # 从环境变量获取参数，提供默认值
        self.params = {
            'ma_periods': {
                'short': int(os.environ.get('MA_SHORT_PERIOD', 5)),
                'medium': int(os.environ.get('MA_MEDIUM_PERIOD', 20)),
                'long': int(os.environ.get('MA_LONG_PERIOD', 60))
            },
            'rsi_period': int(os.environ.get('RSI_PERIOD', 14)),
            'bollinger_period': 20,
            'bollinger_std': 2,
            'volume_ma_period': 20,
            'atr_period': 14
        }
        
        # 禁用代理（Lambda 环境优化）
        self._disable_proxy()
    
    def _disable_proxy(self):
        """禁用 HTTP 代理，优化 Lambda 网络访问"""
        proxy_vars = ['NO_PROXY', 'no_proxy', 'HTTP_PROXY', 'HTTPS_PROXY', 
                     'http_proxy', 'https_proxy']
        
        os.environ['NO_PROXY'] = '*'
        os.environ['no_proxy'] = '*'
        
        for var in ['HTTP_PROXY', 'HTTPS_PROXY', 'http_proxy', 'https_proxy']:
            if var in os.environ:
                del os.environ[var]
    
    def get_stock_data(self, stock_code: str, market_type: str = 'A', 
                      start_date: Optional[str] = None, 
                      end_date: Optional[str] = None) -> pd.DataFrame:
        """
        获取股票或基金数据
        
        Args:
            stock_code: 股票代码
            market_type: 市场类型 ('A', 'HK', 'US', 'ETF', 'LOF')
            start_date: 开始日期 (YYYYMMDD)
            end_date: 结束日期 (YYYYMMDD)
            
        Returns:
            包含股票数据的 DataFrame
            
        Raises:
            ValueError: 股票代码格式错误或市场类型不支持
            Exception: 数据获取失败
        """
        # 设置默认日期范围（近一年）
        if start_date is None:
            start_date = (datetime.now() - timedelta(days=365)).strftime('%Y%m%d')
        if end_date is None:
            end_date = datetime.now().strftime('%Y%m%d')
        
        try:
            # 根据市场类型获取数据
            if market_type == 'A':
                df = self._get_a_stock_data(stock_code, start_date, end_date)
            elif market_type == 'HK':
                df = ak.stock_hk_daily(symbol=stock_code, adjust="qfq")
            elif market_type == 'US':
                df = ak.stock_us_hist(
                    symbol=stock_code,
                    start_date=start_date,
                    end_date=end_date,
                    adjust="qfq"
                )
            elif market_type == 'ETF':
                df = ak.fund_etf_hist_em(
                    symbol=stock_code,
                    period="daily",
                    start_date=start_date,
                    end_date=end_date,
                    adjust="qfq"
                )
            elif market_type == 'LOF':
                df = ak.fund_lof_hist_em(
                    symbol=stock_code,
                    period="daily",
                    start_date=start_date,
                    end_date=end_date,
                    adjust="qfq"
                )
            else:
                raise ValueError(f"不支持的市场类型: {market_type}")
            
            # 标准化数据格式
            df = self._standardize_dataframe(df)
            
            return df.sort_values('date')
            
        except Exception as e:
            raise Exception(f"获取数据失败: {str(e)}")
    
    def _get_a_stock_data(self, stock_code: str, start_date: str, end_date: str) -> pd.DataFrame:
        """获取 A 股数据并验证代码格式"""
        # 验证 A 股代码格式
        valid_prefixes = ['0', '3', '6', '688', '8']
        valid_format = any(stock_code.startswith(prefix) for prefix in valid_prefixes)
        
        if not valid_format:
            error_msg = (
                f"无效的A股股票代码格式: {stock_code}。\n"
                "A股代码应以0、3、6、688或8开头"
            )
            raise ValueError(error_msg)
        
        return ak.stock_zh_a_hist(
            symbol=stock_code,
            start_date=start_date,
            end_date=end_date,
            adjust="qfq"
        )
    
    def _standardize_dataframe(self, df: pd.DataFrame) -> pd.DataFrame:
        """标准化 DataFrame 格式"""
        # 重命名列名以匹配分析需求（支持多种格式）
        column_mapping = {
            # 中文列名（A股）
            "日期": "date",
            "开盘": "open", 
            "收盘": "close",
            "最高": "high",
            "最低": "low",
            "成交量": "volume",
            # 英文列名（港股、美股等）
            "Date": "date",
            "Open": "open",
            "Close": "close", 
            "High": "high",
            "Low": "low",
            "Volume": "volume",
            # 其他可能的列名
            "open": "open",
            "close": "close",
            "high": "high", 
            "low": "low",
            "volume": "volume"
        }
        
        df = df.rename(columns=column_mapping)
        
        # 如果没有 date 列，尝试使用索引作为日期
        if 'date' not in df.columns:
            if df.index.name in ['Date', '日期', 'date'] or pd.api.types.is_datetime64_any_dtype(df.index):
                df = df.reset_index()
                df = df.rename(columns={df.columns[0]: 'date'})
            else:
                # 如果还是没有日期列，创建一个简单的日期序列
                df['date'] = pd.date_range(start='2023-01-01', periods=len(df), freq='D')
        
        # 确保日期格式正确
        df['date'] = pd.to_datetime(df['date'])
        
        # 数据类型转换
        numeric_columns = ['open', 'close', 'high', 'low', 'volume']
        for col in numeric_columns:
            if col in df.columns:
                df[col] = pd.to_numeric(df[col], errors='coerce')
        
        # 删除空值
        df = df.dropna()
        
        return df
    
    def calculate_indicators(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        计算所有技术指标
        
        Args:
            df: 包含股票数据的 DataFrame
            
        Returns:
            添加了技术指标的 DataFrame
        """
        try:
            # 计算移动平均线
            df['MA5'] = self._calculate_ema(df['close'], self.params['ma_periods']['short'])
            df['MA20'] = self._calculate_ema(df['close'], self.params['ma_periods']['medium'])
            df['MA60'] = self._calculate_ema(df['close'], self.params['ma_periods']['long'])
            
            # 计算 RSI
            df['RSI'] = self._calculate_rsi(df['close'], self.params['rsi_period'])
            
            # 计算 MACD
            df['MACD'], df['Signal'], df['MACD_hist'] = self._calculate_macd(df['close'])
            
            # 计算布林带
            df['BB_upper'], df['BB_middle'], df['BB_lower'] = self._calculate_bollinger_bands(
                df['close'],
                self.params['bollinger_period'],
                self.params['bollinger_std']
            )
            
            # 成交量分析
            df['Volume_MA'] = df['volume'].rolling(window=self.params['volume_ma_period']).mean()
            df['Volume_Ratio'] = df['volume'] / df['Volume_MA']
            
            # 计算 ATR 和波动率
            df['ATR'] = self._calculate_atr(df, self.params['atr_period'])
            df['Volatility'] = df['ATR'] / df['close'] * 100
            
            # 动量指标
            df['ROC'] = df['close'].pct_change(periods=10) * 100
            
            return df
            
        except Exception as e:
            raise Exception(f"计算技术指标时出错: {str(e)}")
    
    def calculate_score(self, df: pd.DataFrame) -> int:
        """
        计算综合评分（满分100分）
        
        Args:
            df: 包含技术指标的 DataFrame
            
        Returns:
            综合评分 (0-100)
        """
        try:
            score = 0
            latest = df.iloc[-1]
            
            # 趋势得分（30分）
            if latest['MA5'] > latest['MA20']:
                score += 15
            if latest['MA20'] > latest['MA60']:
                score += 15
            
            # RSI 得分（20分）
            if 30 <= latest['RSI'] <= 70:
                score += 20
            elif latest['RSI'] < 30:  # 超卖
                score += 15
            
            # MACD 得分（20分）
            if latest['MACD'] > latest['Signal']:
                score += 20
            
            # 成交量得分（30分）
            if latest['Volume_Ratio'] > 1.5:
                score += 30
            elif latest['Volume_Ratio'] > 1:
                score += 15
            
            return int(score)
            
        except Exception as e:
            raise Exception(f"计算评分时出错: {str(e)}")
    
    def get_recommendation(self, score: int) -> str:
        """
        根据得分给出投资建议
        
        Args:
            score: 综合评分
            
        Returns:
            投资建议字符串
        """
        if score >= 80:
            return '强烈推荐买入'
        elif score >= 60:
            return '建议买入'
        elif score >= 40:
            return '观望'
        elif score >= 20:
            return '建议卖出'
        else:
            return '强烈建议卖出'
    
    def generate_analysis_report(self, stock_code: str, market_type: str,
                               start_date: Optional[str] = None,
                               end_date: Optional[str] = None) -> Dict[str, Any]:
        """
        生成完整的股票分析报告
        
        Args:
            stock_code: 股票代码
            market_type: 市场类型
            start_date: 开始日期
            end_date: 结束日期
            
        Returns:
            包含分析结果的字典
        """
        # 获取股票数据
        stock_data = self.get_stock_data(stock_code, market_type, start_date, end_date)
        
        # 计算技术指标
        stock_data = self.calculate_indicators(stock_data)
        
        # 检查数据完整性
        if len(stock_data) < 2:
            raise ValueError("数据不足，至少需要2条记录")
        
        # 计算评分
        score = self.calculate_score(stock_data)
        
        # 获取最新数据
        latest = stock_data.iloc[-1]
        prev = stock_data.iloc[-2]
        
        # 生成技术指标概要
        technical_summary = {
            'trend': 'upward' if latest['MA5'] > latest['MA20'] else 'downward',
            'volatility': f"{latest['Volatility']:.2f}%",
            'volume_trend': 'increasing' if latest['Volume_Ratio'] > 1 else 'decreasing',
            'rsi_level': float(latest['RSI']) if not pd.isna(latest['RSI']) else 0
        }
        
        # 获取近14日交易数据
        recent_data = stock_data.tail(14).to_dict('records')
        
        # 生成主报告
        report = {
            'stock_code': stock_code,
            'market_type': market_type,
            'analysis_date': datetime.now().strftime('%Y-%m-%d'),
            'score': score,
            'price': float(latest['close']),
            'price_change': float((latest['close'] - prev['close']) / prev['close'] * 100),
            'ma_trend': 'UP' if latest['MA5'] > latest['MA20'] else 'DOWN',
            'rsi': float(latest['RSI']) if not pd.isna(latest['RSI']) else None,
            'macd_signal': 'BUY' if latest['MACD'] > latest['Signal'] else 'SELL',
            'volume_status': 'HIGH' if latest['Volume_Ratio'] > 1.5 else 'NORMAL',
            'recommendation': self.get_recommendation(score),
            'technical_indicators': {
                'MA5': float(latest['MA5']),
                'MA20': float(latest['MA20']),
                'MA60': float(latest['MA60']),
                'RSI': float(latest['RSI']) if not pd.isna(latest['RSI']) else None,
                'MACD': float(latest['MACD']),
                'volatility': f"{latest['Volatility']:.2f}%",
                'volume_ratio': float(latest['Volume_Ratio'])
            }
        }
        
        return {
            "technical_summary": technical_summary,
            "recent_data": recent_data,
            "report": report
        }
    
    # 私有方法：技术指标计算函数
    
    def _calculate_ema(self, series: pd.Series, period: int) -> pd.Series:
        """计算指数移动平均线"""
        return series.ewm(span=period, adjust=False).mean()
    
    def _calculate_rsi(self, series: pd.Series, period: int) -> pd.Series:
        """计算 RSI 指标"""
        delta = series.diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=period).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=period).mean()
        rs = gain / loss
        return 100 - (100 / (1 + rs))
    
    def _calculate_macd(self, series: pd.Series) -> Tuple[pd.Series, pd.Series, pd.Series]:
        """计算 MACD 指标"""
        exp1 = series.ewm(span=12, adjust=False).mean()
        exp2 = series.ewm(span=26, adjust=False).mean()
        macd = exp1 - exp2
        signal = macd.ewm(span=9, adjust=False).mean()
        hist = macd - signal
        return macd, signal, hist
    
    def _calculate_bollinger_bands(self, series: pd.Series, period: int, 
                                 std_dev: float) -> Tuple[pd.Series, pd.Series, pd.Series]:
        """计算布林带"""
        middle = series.rolling(window=period).mean()
        std = series.rolling(window=period).std()
        upper = middle + (std * std_dev)
        lower = middle - (std * std_dev)
        return upper, middle, lower
    
    def _calculate_atr(self, df: pd.DataFrame, period: int) -> pd.Series:
        """计算 ATR 指标"""
        high = df['high']
        low = df['low']
        close = df['close'].shift(1)
        
        tr1 = high - low
        tr2 = abs(high - close)
        tr3 = abs(low - close)
        
        tr = pd.concat([tr1, tr2, tr3], axis=1).max(axis=1)
        return tr.rolling(window=period).mean()


# 便捷函数，保持向后兼容
def create_analyzer() -> StockAnalyzer:
    """创建股票分析器实例"""
    return StockAnalyzer()