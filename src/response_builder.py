#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
API Gateway 响应构建器

构建符合 API Gateway 格式的 HTTP 响应，支持成功和错误响应。
处理 CORS、内容类型和状态码。

作者: RJ.Wang
邮箱: wangrenjun@gmail.com
创建时间: 2025-10-31
版本: 1.0
许可证: MIT
"""

import json
import logging
from typing import Any, Dict, Optional, Union
from datetime import datetime

# 配置日志
logger = logging.getLogger(__name__)


class ResponseBuilder:
    """API Gateway 响应构建器"""
    
    def __init__(self):
        """初始化响应构建器"""
        # 默认响应头
        self.default_headers = {
            'Content-Type': 'application/json; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Max-Age': '600'
        }
    
    def build_response(self, 
                      status_code: int,
                      body: Any,
                      headers: Optional[Dict[str, str]] = None,
                      is_base64_encoded: bool = False) -> Dict[str, Any]:
        """
        构建 API Gateway 响应
        
        Args:
            status_code: HTTP 状态码
            body: 响应体（将被序列化为 JSON）
            headers: 额外的响应头
            is_base64_encoded: 是否为 base64 编码
            
        Returns:
            API Gateway 响应格式的字典
        """
        # 合并响应头
        response_headers = self.default_headers.copy()
        if headers:
            response_headers.update(headers)
        
        # 序列化响应体
        if isinstance(body, (dict, list)):
            body_str = json.dumps(body, ensure_ascii=False, default=self._json_serializer)
        elif isinstance(body, str):
            body_str = body
        else:
            body_str = str(body)
        
        response = {
            'statusCode': status_code,
            'headers': response_headers,
            'body': body_str,
            'isBase64Encoded': is_base64_encoded
        }
        
        logger.debug(f"构建响应: {status_code}, body长度: {len(body_str)}")
        return response
    
    def success_response(self, 
                        data: Any,
                        status_code: int = 200,
                        message: Optional[str] = None,
                        headers: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
        """
        构建成功响应
        
        Args:
            data: 响应数据
            status_code: HTTP 状态码（默认 200）
            message: 可选的消息
            headers: 额外的响应头
            
        Returns:
            API Gateway 成功响应
        """
        body = {
            'success': True,
            'data': data,
            'timestamp': datetime.now().isoformat()
        }
        
        if message:
            body['message'] = message
        
        logger.info(f"成功响应: {status_code}")
        return self.build_response(status_code, body, headers)
    
    def error_response(self,
                      error_message: str,
                      status_code: int = 500,
                      error_code: Optional[str] = None,
                      details: Optional[Dict[str, Any]] = None,
                      headers: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
        """
        构建错误响应
        
        Args:
            error_message: 错误消息
            status_code: HTTP 状态码
            error_code: 错误代码
            details: 错误详情
            headers: 额外的响应头
            
        Returns:
            API Gateway 错误响应
        """
        body = {
            'success': False,
            'error': error_message,
            'timestamp': datetime.now().isoformat()
        }
        
        if error_code:
            body['error_code'] = error_code
        
        if details:
            body['details'] = details
        
        logger.warning(f"错误响应: {status_code} - {error_message}")
        return self.build_response(status_code, body, headers)
    
    def validation_error_response(self,
                                 field_errors: Dict[str, str],
                                 message: str = "请求参数验证失败") -> Dict[str, Any]:
        """
        构建参数验证错误响应
        
        Args:
            field_errors: 字段错误映射
            message: 错误消息
            
        Returns:
            API Gateway 验证错误响应
        """
        return self.error_response(
            error_message=message,
            status_code=400,
            error_code="VALIDATION_ERROR",
            details={'field_errors': field_errors}
        )
    
    def authentication_error_response(self,
                                    message: str = "认证失败") -> Dict[str, Any]:
        """
        构建认证错误响应
        
        Args:
            message: 错误消息
            
        Returns:
            API Gateway 认证错误响应
        """
        return self.error_response(
            error_message=message,
            status_code=401,
            error_code="AUTHENTICATION_ERROR"
        )
    
    def authorization_error_response(self,
                                   message: str = "权限不足") -> Dict[str, Any]:
        """
        构建授权错误响应
        
        Args:
            message: 错误消息
            
        Returns:
            API Gateway 授权错误响应
        """
        return self.error_response(
            error_message=message,
            status_code=403,
            error_code="AUTHORIZATION_ERROR"
        )
    
    def not_found_response(self,
                          resource: str = "资源") -> Dict[str, Any]:
        """
        构建资源未找到响应
        
        Args:
            resource: 资源名称
            
        Returns:
            API Gateway 404 响应
        """
        return self.error_response(
            error_message=f"{resource}未找到",
            status_code=404,
            error_code="NOT_FOUND"
        )
    
    def method_not_allowed_response(self,
                                  allowed_methods: Optional[list] = None) -> Dict[str, Any]:
        """
        构建方法不允许响应
        
        Args:
            allowed_methods: 允许的方法列表
            
        Returns:
            API Gateway 405 响应
        """
        headers = {}
        if allowed_methods:
            headers['Allow'] = ', '.join(allowed_methods)
        
        return self.error_response(
            error_message="HTTP 方法不允许",
            status_code=405,
            error_code="METHOD_NOT_ALLOWED",
            headers=headers
        )
    
    def internal_server_error_response(self,
                                     message: str = "服务器内部错误",
                                     include_details: bool = False,
                                     error_details: Optional[str] = None) -> Dict[str, Any]:
        """
        构建服务器内部错误响应
        
        Args:
            message: 错误消息
            include_details: 是否包含错误详情（生产环境应为 False）
            error_details: 错误详情
            
        Returns:
            API Gateway 500 响应
        """
        details = None
        if include_details and error_details:
            details = {'error_details': error_details}
        
        return self.error_response(
            error_message=message,
            status_code=500,
            error_code="INTERNAL_SERVER_ERROR",
            details=details
        )
    
    def cors_preflight_response(self) -> Dict[str, Any]:
        """
        构建 CORS 预检响应
        
        Returns:
            API Gateway CORS 预检响应
        """
        return self.build_response(
            status_code=200,
            body='',
            headers={
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Max-Age': '86400'
            }
        )
    
    def health_check_response(self,
                            service_name: str = "股票分析API",
                            version: str = "1.0.0") -> Dict[str, Any]:
        """
        构建健康检查响应
        
        Args:
            service_name: 服务名称
            version: 服务版本
            
        Returns:
            API Gateway 健康检查响应
        """
        data = {
            'status': 'healthy',
            'service': service_name,
            'version': version,
            'timestamp': datetime.now().isoformat()
        }
        
        return self.success_response(data, message="服务运行正常")
    
    def _json_serializer(self, obj: Any) -> str:
        """
        JSON 序列化器，处理特殊类型
        
        Args:
            obj: 要序列化的对象
            
        Returns:
            序列化后的字符串
        """
        if isinstance(obj, datetime):
            return obj.isoformat()
        
        # 处理 pandas/numpy 类型
        if hasattr(obj, 'item'):  # numpy scalar
            return obj.item()
        
        if hasattr(obj, 'to_dict'):  # pandas objects
            return obj.to_dict()
        
        # 默认转换为字符串
        return str(obj)


# 全局响应构建器实例（Lambda 容器复用优化）
_response_builder = None


def get_response_builder() -> ResponseBuilder:
    """
    获取响应构建器实例（单例模式）
    
    Returns:
        ResponseBuilder 实例
    """
    global _response_builder
    if _response_builder is None:
        _response_builder = ResponseBuilder()
    return _response_builder


# 便捷函数
def success_response(data: Any, 
                    status_code: int = 200,
                    message: Optional[str] = None) -> Dict[str, Any]:
    """构建成功响应的便捷函数"""
    builder = get_response_builder()
    return builder.success_response(data, status_code, message)


def error_response(error_message: str,
                  status_code: int = 500,
                  error_code: Optional[str] = None) -> Dict[str, Any]:
    """构建错误响应的便捷函数"""
    builder = get_response_builder()
    return builder.error_response(error_message, status_code, error_code)


def authentication_error() -> Dict[str, Any]:
    """构建认证错误响应的便捷函数"""
    builder = get_response_builder()
    return builder.authentication_error_response()


def authorization_error() -> Dict[str, Any]:
    """构建授权错误响应的便捷函数"""
    builder = get_response_builder()
    return builder.authorization_error_response()


def validation_error(field_errors: Dict[str, str]) -> Dict[str, Any]:
    """构建验证错误响应的便捷函数"""
    builder = get_response_builder()
    return builder.validation_error_response(field_errors)


def health_check_response() -> Dict[str, Any]:
    """构建健康检查响应的便捷函数"""
    builder = get_response_builder()
    return builder.health_check_response()