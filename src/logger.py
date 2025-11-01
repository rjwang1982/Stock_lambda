#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
结构化日志记录模块

提供结构化的日志记录功能，支持 JSON 格式输出，便于 CloudWatch 日志分析。
包含请求跟踪、性能监控和错误记录功能。

作者: RJ.Wang
邮箱: wangrenjun@gmail.com
创建时间: 2025-10-31
版本: 1.0
许可证: MIT
"""

import json
import logging
import os
import time
from datetime import datetime
from typing import Dict, Any, Optional, Union
from functools import wraps

from utils import get_environment_info, is_development_environment


class StructuredFormatter(logging.Formatter):
    """结构化日志格式化器"""
    
    def format(self, record: logging.LogRecord) -> str:
        """格式化日志记录为 JSON"""
        
        # 基础日志信息
        log_entry = {
            'timestamp': datetime.fromtimestamp(record.created).isoformat(),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno
        }
        
        # 添加环境信息
        if hasattr(record, 'request_id'):
            log_entry['request_id'] = record.request_id
        
        if hasattr(record, 'execution_time'):
            log_entry['execution_time_ms'] = record.execution_time
        
        if hasattr(record, 'stock_code'):
            log_entry['stock_code'] = record.stock_code
        
        if hasattr(record, 'user_ip'):
            log_entry['user_ip'] = record.user_ip
        
        if hasattr(record, 'user_agent'):
            log_entry['user_agent'] = record.user_agent
        
        # 添加额外的上下文数据
        if hasattr(record, 'extra_data'):
            log_entry['extra'] = record.extra_data
        
        # 异常信息
        if record.exc_info:
            log_entry['exception'] = self.formatException(record.exc_info)
        
        # 在开发环境添加更多调试信息
        if is_development_environment():
            log_entry['thread'] = record.thread
            log_entry['process'] = record.process
        
        return json.dumps(log_entry, ensure_ascii=False, default=str)


class StructuredLogger:
    """结构化日志记录器"""
    
    def __init__(self, name: str = __name__):
        self.logger = logging.getLogger(name)
        self.request_context = {}
        self._setup_logger()
    
    def _setup_logger(self):
        """设置日志记录器"""
        # 避免重复设置
        if self.logger.handlers:
            return
        
        # 设置日志级别
        log_level = os.environ.get('LOG_LEVEL', 'INFO').upper()
        self.logger.setLevel(getattr(logging, log_level))
        
        # 创建处理器
        handler = logging.StreamHandler()
        handler.setFormatter(StructuredFormatter())
        
        self.logger.addHandler(handler)
        self.logger.propagate = False
    
    def set_request_context(self, event: Dict[str, Any], context: Any = None):
        """设置请求上下文"""
        request_context = event.get('requestContext', {})
        identity = request_context.get('identity', {})
        
        self.request_context = {
            'request_id': request_context.get('requestId'),
            'method': event.get('httpMethod'),
            'path': event.get('path'),
            'stage': request_context.get('stage'),
            'user_ip': identity.get('sourceIp'),
            'user_agent': event.get('headers', {}).get('User-Agent', ''),
            'api_id': request_context.get('apiId')
        }
        
        if context:
            self.request_context.update({
                'function_name': context.function_name,
                'function_version': context.function_version,
                'memory_limit': context.memory_limit_in_mb,
                'remaining_time': context.get_remaining_time_in_millis()
            })
    
    def _add_context(self, extra: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """添加上下文信息到日志"""
        context = self.request_context.copy()
        if extra:
            context.update(extra)
        return context
    
    def info(self, message: str, **kwargs):
        """记录信息日志"""
        extra = self._add_context(kwargs)
        self.logger.info(message, extra=extra)
    
    def debug(self, message: str, **kwargs):
        """记录调试日志"""
        extra = self._add_context(kwargs)
        self.logger.debug(message, extra=extra)
    
    def warning(self, message: str, **kwargs):
        """记录警告日志"""
        extra = self._add_context(kwargs)
        self.logger.warning(message, extra=extra)
    
    def error(self, message: str, exc_info: bool = False, **kwargs):
        """记录错误日志"""
        extra = self._add_context(kwargs)
        self.logger.error(message, exc_info=exc_info, extra=extra)
    
    def critical(self, message: str, exc_info: bool = False, **kwargs):
        """记录严重错误日志"""
        extra = self._add_context(kwargs)
        self.logger.critical(message, exc_info=exc_info, extra=extra)
    
    def log_request_start(self, event: Dict[str, Any]):
        """记录请求开始"""
        method = event.get('httpMethod', 'UNKNOWN')
        path = event.get('path', '/')
        
        self.info(
            f"请求开始: {method} {path}",
            event_type="request_start",
            method=method,
            path=path
        )
    
    def log_request_end(self, status_code: int, execution_time: float):
        """记录请求结束"""
        self.info(
            f"请求完成: {status_code}",
            event_type="request_end",
            status_code=status_code,
            execution_time_ms=round(execution_time * 1000, 2)
        )
    
    def log_stock_analysis_start(self, stock_code: str, market_type: str):
        """记录股票分析开始"""
        self.info(
            f"开始股票分析: {stock_code} ({market_type})",
            event_type="stock_analysis_start",
            stock_code=stock_code,
            market_type=market_type
        )
    
    def log_stock_analysis_end(self, stock_code: str, score: int, 
                              data_points: int, execution_time: float):
        """记录股票分析结束"""
        self.info(
            f"股票分析完成: {stock_code}, 评分: {score}",
            event_type="stock_analysis_end",
            stock_code=stock_code,
            score=score,
            data_points=data_points,
            execution_time_ms=round(execution_time * 1000, 2)
        )
    
    def log_authentication_attempt(self, success: bool, token_preview: str = ""):
        """记录认证尝试"""
        self.info(
            f"认证尝试: {'成功' if success else '失败'}",
            event_type="authentication_attempt",
            success=success,
            token_preview=token_preview
        )
    
    def log_external_api_call(self, service: str, endpoint: str, 
                             status_code: int, response_time: float):
        """记录外部 API 调用"""
        self.info(
            f"外部API调用: {service} - {status_code}",
            event_type="external_api_call",
            service=service,
            endpoint=endpoint,
            status_code=status_code,
            response_time_ms=round(response_time * 1000, 2)
        )
    
    def log_performance_metric(self, metric_name: str, value: Union[int, float], 
                              unit: str = "ms"):
        """记录性能指标"""
        self.info(
            f"性能指标: {metric_name} = {value}{unit}",
            event_type="performance_metric",
            metric_name=metric_name,
            value=value,
            unit=unit
        )
    
    def log_business_event(self, event_name: str, **kwargs):
        """记录业务事件"""
        self.info(
            f"业务事件: {event_name}",
            event_type="business_event",
            event_name=event_name,
            **kwargs
        )


# 全局日志记录器实例
_structured_logger = None


def get_logger(name: str = __name__) -> StructuredLogger:
    """获取结构化日志记录器实例"""
    global _structured_logger
    if _structured_logger is None:
        _structured_logger = StructuredLogger(name)
    return _structured_logger


def log_execution_time(func):
    """记录函数执行时间的装饰器"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        logger = get_logger()
        start_time = time.time()
        
        try:
            result = func(*args, **kwargs)
            execution_time = time.time() - start_time
            
            logger.log_performance_metric(
                metric_name=f"{func.__name__}_execution_time",
                value=round(execution_time * 1000, 2),
                unit="ms"
            )
            
            return result
            
        except Exception as e:
            execution_time = time.time() - start_time
            logger.error(
                f"函数 {func.__name__} 执行失败",
                exc_info=True,
                execution_time_ms=round(execution_time * 1000, 2)
            )
            raise
    
    return wrapper


def log_lambda_handler(func):
    """Lambda 处理器日志装饰器"""
    @wraps(func)
    def wrapper(event, context):
        logger = get_logger()
        start_time = time.time()
        
        # 设置请求上下文
        logger.set_request_context(event, context)
        
        # 记录请求开始
        logger.log_request_start(event)
        
        try:
            result = func(event, context)
            execution_time = time.time() - start_time
            
            # 从结果中提取状态码
            status_code = result.get('statusCode', 200) if isinstance(result, dict) else 200
            
            # 记录请求结束
            logger.log_request_end(status_code, execution_time)
            
            return result
            
        except Exception as e:
            execution_time = time.time() - start_time
            logger.error(
                f"Lambda 处理器执行失败: {str(e)}",
                exc_info=True,
                execution_time_ms=round(execution_time * 1000, 2)
            )
            raise
    
    return wrapper


# 便捷函数
def log_info(message: str, **kwargs):
    """记录信息日志的便捷函数"""
    logger = get_logger()
    logger.info(message, **kwargs)


def log_error(message: str, exc_info: bool = False, **kwargs):
    """记录错误日志的便捷函数"""
    logger = get_logger()
    logger.error(message, exc_info=exc_info, **kwargs)


def log_warning(message: str, **kwargs):
    """记录警告日志的便捷函数"""
    logger = get_logger()
    logger.warning(message, **kwargs)


def log_debug(message: str, **kwargs):
    """记录调试日志的便捷函数"""
    logger = get_logger()
    logger.debug(message, **kwargs)