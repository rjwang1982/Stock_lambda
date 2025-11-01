#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
工具函数模块

提供通用的工具函数，包括日志配置、数据验证、时间处理等。

作者: RJ.Wang
邮箱: wangrenjun@gmail.com
创建时间: 2025-10-31
版本: 1.0
许可证: MIT
"""

import os
import json
import logging
from typing import Any, Dict, Optional, Union
from datetime import datetime, timedelta


def setup_logging(level: str = None) -> logging.Logger:
    """
    配置日志记录
    
    Args:
        level: 日志级别（DEBUG, INFO, WARNING, ERROR）
        
    Returns:
        配置好的 logger
    """
    if level is None:
        level = os.environ.get('LOG_LEVEL', 'INFO')
    
    # 配置根日志记录器
    logging.basicConfig(
        level=getattr(logging, level.upper()),
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        force=True
    )
    
    logger = logging.getLogger(__name__)
    logger.info(f"日志级别设置为: {level}")
    
    return logger


def parse_json_body(body: Optional[str]) -> Dict[str, Any]:
    """
    解析 JSON 请求体
    
    Args:
        body: JSON 字符串
        
    Returns:
        解析后的字典
        
    Raises:
        ValueError: JSON 解析失败
    """
    if not body:
        return {}
    
    try:
        return json.loads(body)
    except json.JSONDecodeError as e:
        raise ValueError(f"无效的 JSON 格式: {str(e)}")


def validate_stock_code(stock_code: str, market_type: str = 'A') -> bool:
    """
    验证股票代码格式
    
    Args:
        stock_code: 股票代码
        market_type: 市场类型
        
    Returns:
        是否有效
    """
    if not stock_code or not isinstance(stock_code, str):
        return False
    
    stock_code = stock_code.strip()
    market_type = market_type.upper()  # 转换为大写
    
    if market_type == 'A':
        # A股代码验证
        valid_prefixes = ['0', '3', '6', '688', '8']
        return any(stock_code.startswith(prefix) for prefix in valid_prefixes)
    elif market_type in ['HK', 'US', 'ETF', 'LOF']:
        # 其他市场的基本验证
        return len(stock_code) >= 3
    
    return False


def validate_date_format(date_str: str) -> bool:
    """
    验证日期格式 (YYYYMMDD)
    
    Args:
        date_str: 日期字符串
        
    Returns:
        是否有效
    """
    if not date_str or len(date_str) != 8:
        return False
    
    try:
        datetime.strptime(date_str, '%Y%m%d')
        return True
    except ValueError:
        return False


def get_default_date_range(days: int = 365) -> tuple:
    """
    获取默认日期范围
    
    Args:
        days: 天数
        
    Returns:
        (start_date, end_date) 元组，格式为 YYYYMMDD
    """
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)
    
    return (
        start_date.strftime('%Y%m%d'),
        end_date.strftime('%Y%m%d')
    )


def extract_path_parameters(event: Dict[str, Any]) -> Dict[str, str]:
    """
    从 API Gateway 事件中提取路径参数
    
    Args:
        event: API Gateway 事件
        
    Returns:
        路径参数字典
    """
    # 首先尝试从 pathParameters 获取（非代理集成）
    path_params = event.get('pathParameters') or {}
    
    # 检查是否有 proxy 参数（代理集成）
    if 'proxy' in path_params:
        proxy_path = path_params['proxy']
        # 解析 test-stock/{stock_code} 格式的代理路径
        if proxy_path.startswith('test-stock/'):
            stock_code = proxy_path.replace('test-stock/', '').strip('/')
            if stock_code:
                return {'stock_code': stock_code}
    
    # 如果有其他路径参数，直接返回
    if path_params and 'proxy' not in path_params:
        return path_params
    
    # 如果没有 pathParameters，手动解析路径（备用方案）
    path = event.get('path', '/')
    
    # 解析 /test-stock/{stock_code} 格式的路径
    if path.startswith('/test-stock/'):
        stock_code = path.replace('/test-stock/', '').strip('/')
        if stock_code:
            return {'stock_code': stock_code}
    
    return {}


def extract_query_parameters(event: Dict[str, Any]) -> Dict[str, str]:
    """
    从 API Gateway 事件中提取查询参数
    
    Args:
        event: API Gateway 事件
        
    Returns:
        查询参数字典
    """
    return event.get('queryStringParameters') or {}


def get_request_info(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    获取请求信息摘要
    
    Args:
        event: API Gateway 事件
        
    Returns:
        请求信息字典
    """
    return {
        'method': event.get('httpMethod', 'UNKNOWN'),
        'path': event.get('path', '/'),
        'resource': event.get('resource', ''),
        'stage': event.get('requestContext', {}).get('stage', ''),
        'request_id': event.get('requestContext', {}).get('requestId', ''),
        'source_ip': event.get('requestContext', {}).get('identity', {}).get('sourceIp', ''),
        'user_agent': event.get('headers', {}).get('User-Agent', ''),
        'timestamp': datetime.now().isoformat()
    }


def truncate_string(text: str, max_length: int = 100, suffix: str = "...") -> str:
    """
    截断字符串
    
    Args:
        text: 原始字符串
        max_length: 最大长度
        suffix: 截断后缀
        
    Returns:
        截断后的字符串
    """
    if len(text) <= max_length:
        return text
    
    return text[:max_length - len(suffix)] + suffix


def safe_float_conversion(value: Any, default: float = 0.0) -> float:
    """
    安全的浮点数转换
    
    Args:
        value: 要转换的值
        default: 默认值
        
    Returns:
        转换后的浮点数
    """
    try:
        if value is None:
            return default
        return float(value)
    except (ValueError, TypeError):
        return default


def safe_int_conversion(value: Any, default: int = 0) -> int:
    """
    安全的整数转换
    
    Args:
        value: 要转换的值
        default: 默认值
        
    Returns:
        转换后的整数
    """
    try:
        if value is None:
            return default
        return int(value)
    except (ValueError, TypeError):
        return default


def format_error_message(error: Exception, include_traceback: bool = False) -> str:
    """
    格式化错误消息
    
    Args:
        error: 异常对象
        include_traceback: 是否包含堆栈跟踪
        
    Returns:
        格式化的错误消息
    """
    message = str(error)
    
    if include_traceback:
        import traceback
        tb = traceback.format_exc()
        message += f"\n\n堆栈跟踪:\n{tb}"
    
    return message


def is_development_environment() -> bool:
    """
    检查是否为开发环境
    
    Returns:
        是否为开发环境
    """
    env = os.environ.get('AWS_SAM_LOCAL', '').lower()
    return env in ['true', '1', 'yes']


def get_environment_info() -> Dict[str, str]:
    """
    获取环境信息
    
    Returns:
        环境信息字典
    """
    return {
        'aws_region': os.environ.get('AWS_REGION', 'unknown'),
        'function_name': os.environ.get('AWS_LAMBDA_FUNCTION_NAME', 'unknown'),
        'function_version': os.environ.get('AWS_LAMBDA_FUNCTION_VERSION', 'unknown'),
        'log_group': os.environ.get('AWS_LAMBDA_LOG_GROUP_NAME', 'unknown'),
        'log_stream': os.environ.get('AWS_LAMBDA_LOG_STREAM_NAME', 'unknown'),
        'is_sam_local': str(is_development_environment()),
        'python_version': os.environ.get('AWS_LAMBDA_RUNTIME_API', 'unknown')
    }


# 初始化日志
logger = setup_logging()