#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
统一错误处理模块

提供统一的错误处理机制，包括错误分类、日志记录和响应构建。
确保敏感信息不会泄露到客户端。

Author: RJ.Wang (Lambda 适配)
License: MIT
"""

import logging
import traceback
from typing import Dict, Any, Optional, Type
from datetime import datetime

from response_builder import get_response_builder
from utils import is_development_environment

# 配置日志
logger = logging.getLogger(__name__)


class BaseAPIError(Exception):
    """API 错误基类"""
    
    def __init__(self, message: str, status_code: int = 500, 
                 error_code: Optional[str] = None, 
                 details: Optional[Dict[str, Any]] = None):
        self.message = message
        self.status_code = status_code
        self.error_code = error_code or self.__class__.__name__
        self.details = details or {}
        super().__init__(self.message)


class ValidationError(BaseAPIError):
    """参数验证错误"""
    
    def __init__(self, message: str, field_errors: Optional[Dict[str, str]] = None):
        details = {'field_errors': field_errors} if field_errors else None
        super().__init__(
            message=message,
            status_code=400,
            error_code="VALIDATION_ERROR",
            details=details
        )


class AuthenticationError(BaseAPIError):
    """认证错误"""
    
    def __init__(self, message: str = "认证失败"):
        super().__init__(
            message=message,
            status_code=401,
            error_code="AUTHENTICATION_ERROR"
        )


class AuthorizationError(BaseAPIError):
    """授权错误"""
    
    def __init__(self, message: str = "权限不足"):
        super().__init__(
            message=message,
            status_code=403,
            error_code="AUTHORIZATION_ERROR"
        )


class NotFoundError(BaseAPIError):
    """资源未找到错误"""
    
    def __init__(self, resource: str = "资源"):
        super().__init__(
            message=f"{resource}未找到",
            status_code=404,
            error_code="NOT_FOUND"
        )


class MethodNotAllowedError(BaseAPIError):
    """HTTP 方法不允许错误"""
    
    def __init__(self, method: str, allowed_methods: Optional[list] = None):
        message = f"HTTP 方法 {method} 不被允许"
        details = {'allowed_methods': allowed_methods} if allowed_methods else None
        super().__init__(
            message=message,
            status_code=405,
            error_code="METHOD_NOT_ALLOWED",
            details=details
        )


class StockDataError(BaseAPIError):
    """股票数据相关错误"""
    
    def __init__(self, message: str, stock_code: Optional[str] = None):
        details = {'stock_code': stock_code} if stock_code else None
        super().__init__(
            message=message,
            status_code=400,
            error_code="STOCK_DATA_ERROR",
            details=details
        )


class ExternalServiceError(BaseAPIError):
    """外部服务错误"""
    
    def __init__(self, message: str, service_name: Optional[str] = None):
        details = {'service_name': service_name} if service_name else None
        super().__init__(
            message=message,
            status_code=502,
            error_code="EXTERNAL_SERVICE_ERROR",
            details=details
        )


class RateLimitError(BaseAPIError):
    """请求频率限制错误"""
    
    def __init__(self, message: str = "请求过于频繁，请稍后重试"):
        super().__init__(
            message=message,
            status_code=429,
            error_code="RATE_LIMIT_ERROR"
        )


class InternalServerError(BaseAPIError):
    """服务器内部错误"""
    
    def __init__(self, message: str = "服务器内部错误", 
                 original_error: Optional[Exception] = None):
        details = {}
        if original_error and is_development_environment():
            details['original_error'] = str(original_error)
            details['error_type'] = type(original_error).__name__
        
        super().__init__(
            message=message,
            status_code=500,
            error_code="INTERNAL_SERVER_ERROR",
            details=details if details else None
        )


class ErrorHandler:
    """统一错误处理器"""
    
    def __init__(self):
        self.response_builder = get_response_builder()
        
        # 错误类型映射
        self.error_type_mapping = {
            ValueError: self._handle_value_error,
            TypeError: self._handle_type_error,
            KeyError: self._handle_key_error,
            AttributeError: self._handle_attribute_error,
            ConnectionError: self._handle_connection_error,
            TimeoutError: self._handle_timeout_error,
        }
    
    def handle_error(self, error: Exception, 
                    request_context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        统一错误处理入口
        
        Args:
            error: 异常对象
            request_context: 请求上下文信息
            
        Returns:
            API Gateway 错误响应
        """
        # 记录错误信息
        self._log_error(error, request_context)
        
        # 处理自定义 API 错误
        if isinstance(error, BaseAPIError):
            return self._handle_api_error(error)
        
        # 处理已知的系统错误
        error_type = type(error)
        if error_type in self.error_type_mapping:
            return self.error_type_mapping[error_type](error)
        
        # 处理未知错误
        return self._handle_unknown_error(error)
    
    def _handle_api_error(self, error: BaseAPIError) -> Dict[str, Any]:
        """处理自定义 API 错误"""
        return self.response_builder.error_response(
            error_message=error.message,
            status_code=error.status_code,
            error_code=error.error_code,
            details=error.details
        )
    
    def _handle_value_error(self, error: ValueError) -> Dict[str, Any]:
        """处理 ValueError"""
        return self.response_builder.error_response(
            error_message=f"参数值错误: {str(error)}",
            status_code=400,
            error_code="VALUE_ERROR"
        )
    
    def _handle_type_error(self, error: TypeError) -> Dict[str, Any]:
        """处理 TypeError"""
        return self.response_builder.error_response(
            error_message="参数类型错误",
            status_code=400,
            error_code="TYPE_ERROR"
        )
    
    def _handle_key_error(self, error: KeyError) -> Dict[str, Any]:
        """处理 KeyError"""
        missing_key = str(error).strip("'\"")
        return self.response_builder.error_response(
            error_message=f"缺少必需参数: {missing_key}",
            status_code=400,
            error_code="MISSING_PARAMETER"
        )
    
    def _handle_attribute_error(self, error: AttributeError) -> Dict[str, Any]:
        """处理 AttributeError"""
        return self.response_builder.error_response(
            error_message="对象属性错误",
            status_code=500,
            error_code="ATTRIBUTE_ERROR"
        )
    
    def _handle_connection_error(self, error: ConnectionError) -> Dict[str, Any]:
        """处理连接错误"""
        return self.response_builder.error_response(
            error_message="外部服务连接失败，请稍后重试",
            status_code=502,
            error_code="CONNECTION_ERROR"
        )
    
    def _handle_timeout_error(self, error: TimeoutError) -> Dict[str, Any]:
        """处理超时错误"""
        return self.response_builder.error_response(
            error_message="请求超时，请稍后重试",
            status_code=504,
            error_code="TIMEOUT_ERROR"
        )
    
    def _handle_unknown_error(self, error: Exception) -> Dict[str, Any]:
        """处理未知错误"""
        # 在开发环境显示详细错误信息
        if is_development_environment():
            details = {
                'error_type': type(error).__name__,
                'error_message': str(error),
                'traceback': traceback.format_exc()
            }
        else:
            details = None
        
        return self.response_builder.error_response(
            error_message="服务器内部错误",
            status_code=500,
            error_code="INTERNAL_SERVER_ERROR",
            details=details
        )
    
    def _log_error(self, error: Exception, 
                  request_context: Optional[Dict[str, Any]] = None):
        """记录错误日志"""
        error_info = {
            'error_type': type(error).__name__,
            'error_message': str(error),
            'timestamp': datetime.now().isoformat()
        }
        
        # 添加请求上下文
        if request_context:
            error_info.update({
                'request_id': request_context.get('request_id'),
                'method': request_context.get('method'),
                'path': request_context.get('path'),
                'source_ip': request_context.get('source_ip')
            })
        
        # 根据错误类型选择日志级别
        if isinstance(error, BaseAPIError):
            if error.status_code < 500:
                logger.warning(f"客户端错误: {error_info}")
            else:
                logger.error(f"服务器错误: {error_info}")
        else:
            logger.error(f"未处理错误: {error_info}", exc_info=True)


# 全局错误处理器实例
_error_handler = None


def get_error_handler() -> ErrorHandler:
    """获取错误处理器实例（单例模式）"""
    global _error_handler
    if _error_handler is None:
        _error_handler = ErrorHandler()
    return _error_handler


def handle_error(error: Exception, 
                request_context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """
    处理错误的便捷函数
    
    Args:
        error: 异常对象
        request_context: 请求上下文
        
    Returns:
        API Gateway 错误响应
    """
    error_handler = get_error_handler()
    return error_handler.handle_error(error, request_context)


# 装饰器：自动错误处理
def auto_error_handler(func):
    """
    自动错误处理装饰器
    
    用法:
    @auto_error_handler
    def my_handler(event, context):
        # 可能抛出异常的代码
        pass
    """
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            # 尝试从参数中获取请求上下文
            request_context = None
            if args and isinstance(args[0], dict):
                event = args[0]
                request_context = {
                    'request_id': event.get('requestContext', {}).get('requestId'),
                    'method': event.get('httpMethod'),
                    'path': event.get('path'),
                    'source_ip': event.get('requestContext', {}).get('identity', {}).get('sourceIp')
                }
            
            return handle_error(e, request_context)
    
    return wrapper