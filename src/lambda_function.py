#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
股票技术分析 Lambda 主处理器

处理 API Gateway 事件，路由到对应的处理函数，返回标准响应。
整合股票分析、认证和响应构建模块。

作者: RJ.Wang
邮箱: wangrenjun@gmail.com
创建时间: 2025-10-31
版本: 1.0
许可证: MIT
"""

import json
import time
from typing import Dict, Any, Optional

# 导入自定义模块
from stock_analyzer import StockAnalyzer, create_analyzer
from auth_handler import authenticate_event, AuthenticationError
from response_builder import get_response_builder
from error_handler import handle_error, BaseAPIError, ValidationError, StockDataError
from logger import get_logger, log_lambda_handler, log_execution_time
from utils import (
    parse_json_body, validate_stock_code, validate_date_format,
    get_default_date_range, extract_path_parameters, extract_query_parameters,
    get_request_info
)

# 获取结构化日志记录器
logger = get_logger(__name__)

# 全局实例（Lambda 容器复用优化）
stock_analyzer = None
response_builder = None


def get_stock_analyzer() -> StockAnalyzer:
    """获取股票分析器实例（单例模式）"""
    global stock_analyzer
    if stock_analyzer is None:
        stock_analyzer = create_analyzer()
        logger.info("股票分析器初始化完成")
    return stock_analyzer


@log_lambda_handler
def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda 主处理器函数
    
    Args:
        event: API Gateway 事件
        context: Lambda 上下文
        
    Returns:
        API Gateway 响应格式的字典
    """
    global response_builder
    if response_builder is None:
        response_builder = get_response_builder()
    
    try:
        # 路由分发
        return route_request(event, context)
        
    except Exception as e:
        # 使用统一错误处理器
        request_context = get_request_info(event)
        return handle_error(e, request_context)


def route_request(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    路由请求到对应的处理函数
    
    Args:
        event: API Gateway 事件
        context: Lambda 上下文
        
    Returns:
        API Gateway 响应
    """
    method = event.get('httpMethod', '').upper()
    path = event.get('path', '/')
    resource = event.get('resource', '')
    
    logger.debug(f"路由解析: {method} {path} (resource: {resource})")
    
    # CORS 预检请求
    if method == 'OPTIONS':
        return response_builder.cors_preflight_response()
    
    # 根据路径和方法路由
    if method == 'GET':
        if path == '/' or path == '':
            return handle_root(event, context)
        elif path == '/health':
            return handle_health_check(event, context)
        elif path.startswith('/test-stock/'):
            return handle_test_stock_get(event, context)
        else:
            return response_builder.not_found_response("API 端点")
    
    elif method == 'POST':
        if path == '/analyze-stock' or path == '/analyze-stock/':
            return handle_analyze_stock_post(event, context)
        else:
            return response_builder.not_found_response("API 端点")
    
    else:
        return response_builder.method_not_allowed_response(['GET', 'POST', 'OPTIONS'])


def handle_root(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    处理根路径请求 GET /
    
    Args:
        event: API Gateway 事件
        context: Lambda 上下文
        
    Returns:
        根路径响应
    """
    logger.info("处理根路径请求")
    
    data = {
        'status': 'ok',
        'message': '股票分析API正在运行',
        'service': '股票技术分析 Lambda API',
        'version': '1.0.0',
        'endpoints': {
            'health': 'GET /health',
            'test': 'GET /test-stock/{stock_code}?token=your_token',
            'analyze': 'POST /analyze-stock (需要 Authorization 头)'
        }
    }
    
    return response_builder.success_response(data)


def handle_health_check(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    处理健康检查请求 GET /health
    
    Args:
        event: API Gateway 事件
        context: Lambda 上下文
        
    Returns:
        健康检查响应
    """
    logger.info("处理健康检查请求")
    return response_builder.health_check_response(
        service_name="股票技术分析 Lambda API",
        version="1.0.0"
    )


@log_execution_time
def handle_test_stock_get(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    处理股票测试请求 GET /test-stock/{stock_code}
    
    Args:
        event: API Gateway 事件
        context: Lambda 上下文
        
    Returns:
        股票分析响应
    """
    logger.info("处理股票测试请求")
    
    # 提取路径参数
    path_params = extract_path_parameters(event)
    stock_code = path_params.get('stock_code')
    
    if not stock_code:
        raise ValidationError("缺少股票代码参数")
    
    # 提取查询参数
    query_params = extract_query_parameters(event)
    market_type = query_params.get('market', query_params.get('market_type', 'A')).upper()
    
    # 认证（允许查询参数 token）
    token = authenticate_event(event, allow_query_token=True)
    logger.log_authentication_attempt(True, token[:10] + "...")
    
    # 验证股票代码
    if not validate_stock_code(stock_code, market_type):
        raise StockDataError(f"无效的股票代码格式: {stock_code}", stock_code)
    
    # 记录股票分析开始
    logger.log_stock_analysis_start(stock_code, market_type)
    start_time = time.time()
    
    # 执行股票分析
    analyzer = get_stock_analyzer()
    result = analyzer.generate_analysis_report(
        stock_code=stock_code,
        market_type=market_type
    )
    
    # 记录股票分析结束
    execution_time = time.time() - start_time
    logger.log_stock_analysis_end(
        stock_code, 
        result['report']['score'], 
        len(result.get('recent_data', [])),
        execution_time
    )
    
    # 返回简化的响应格式（兼容原始 API）
    return response_builder.success_response(result['report'])


@log_execution_time
def handle_analyze_stock_post(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    处理股票分析请求 POST /analyze-stock
    
    Args:
        event: API Gateway 事件
        context: Lambda 上下文
        
    Returns:
        股票分析响应
    """
    logger.info("处理股票分析POST请求")
    
    # 认证（仅支持 Bearer Token）
    token = authenticate_event(event, allow_query_token=False)
    logger.log_authentication_attempt(True, token[:10] + "...")
    
    # 解析请求体
    body = event.get('body', '')
    request_data = parse_json_body(body)
    
    # 提取和验证参数
    stock_code = request_data.get('stock_code')
    if not stock_code:
        raise ValidationError("缺少必需参数: stock_code")
    
    market_type = request_data.get('market_type', 'A')
    start_date = request_data.get('start_date')
    end_date = request_data.get('end_date')
    
    # 验证股票代码
    if not validate_stock_code(stock_code, market_type):
        raise StockDataError(f"无效的股票代码格式: {stock_code}", stock_code)
    
    # 验证日期格式
    if start_date and not validate_date_format(start_date):
        raise ValidationError(f"无效的开始日期格式: {start_date}，应为 YYYYMMDD")
    
    if end_date and not validate_date_format(end_date):
        raise ValidationError(f"无效的结束日期格式: {end_date}，应为 YYYYMMDD")
    
    # 设置默认日期范围
    if not start_date or not end_date:
        default_start, default_end = get_default_date_range()
        start_date = start_date or default_start
        end_date = end_date or default_end
    
    # 记录股票分析开始
    logger.log_stock_analysis_start(stock_code, market_type)
    logger.log_business_event(
        "stock_analysis_request",
        stock_code=stock_code,
        market_type=market_type,
        date_range=f"{start_date}-{end_date}"
    )
    start_time = time.time()
    
    # 执行股票分析
    analyzer = get_stock_analyzer()
    result = analyzer.generate_analysis_report(
        stock_code=stock_code,
        market_type=market_type,
        start_date=start_date,
        end_date=end_date
    )
    
    # 记录股票分析结束
    execution_time = time.time() - start_time
    logger.log_stock_analysis_end(
        stock_code, 
        result['report']['score'], 
        len(result.get('recent_data', [])),
        execution_time
    )
    
    # 返回完整的分析结果
    return response_builder.success_response(result)


# Lambda 冷启动优化
def lambda_cold_start_init():
    """Lambda 冷启动初始化"""
    logger.info("Lambda 冷启动初始化开始")
    
    # 预初始化全局实例
    global stock_analyzer, response_builder
    stock_analyzer = create_analyzer()
    response_builder = get_response_builder()
    
    logger.info("Lambda 冷启动初始化完成")


# 在模块加载时执行冷启动初始化
if __name__ != "__main__":
    lambda_cold_start_init()