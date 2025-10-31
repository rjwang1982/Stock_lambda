#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
认证处理模块

处理 Bearer Token 认证，支持环境变量配置和多种认证场景。
适配 Lambda 环境，移除 FastAPI 依赖。

Author: RJ.Wang (Lambda 适配)
License: MIT
"""

import os
import logging
from typing import Optional, List, Dict, Any

# 配置日志
logger = logging.getLogger(__name__)


class AuthenticationError(Exception):
    """认证错误异常"""
    def __init__(self, message: str, status_code: int = 401):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)


class AuthHandler:
    """认证处理器"""
    
    def __init__(self):
        """初始化认证处理器"""
        self.valid_tokens = self._load_valid_tokens()
        logger.info(f"已加载 {len(self.valid_tokens)} 个有效 Token")
    
    def _load_valid_tokens(self) -> List[str]:
        """
        从环境变量加载有效的 Token 列表
        
        Returns:
            有效 Token 列表
        """
        # 从环境变量获取 Token 列表（逗号分隔）
        tokens_str = os.environ.get('VALID_TOKENS', 'xue123,xue1234')
        
        # 分割并清理 Token
        tokens = [token.strip() for token in tokens_str.split(',') if token.strip()]
        
        if not tokens:
            logger.warning("未配置有效 Token，使用默认 Token")
            tokens = ['xue123', 'xue1234']
        
        return tokens
    
    def verify_bearer_token(self, authorization_header: Optional[str]) -> str:
        """
        验证 Bearer Token
        
        Args:
            authorization_header: Authorization 请求头值
            
        Returns:
            验证通过的 Token
            
        Raises:
            AuthenticationError: 认证失败
        """
        # 检查是否提供了 Authorization 头
        if not authorization_header:
            logger.warning("缺少 Authorization 请求头")
            raise AuthenticationError(
                "Missing Authorization Header",
                status_code=401
            )
        
        # 解析 Bearer Token
        try:
            scheme, _, token = authorization_header.partition(" ")
            
            if scheme.lower() != "bearer":
                logger.warning(f"无效的认证方案: {scheme}")
                raise AuthenticationError(
                    "Invalid Authorization scheme. Use 'Bearer <token>'",
                    status_code=401
                )
            
            if not token:
                logger.warning("Bearer Token 为空")
                raise AuthenticationError(
                    "Missing Bearer token",
                    status_code=401
                )
            
        except Exception as e:
            logger.error(f"解析 Authorization 头失败: {str(e)}")
            raise AuthenticationError(
                "Invalid Authorization header format",
                status_code=401
            )
        
        # 验证 Token
        if token not in self.valid_tokens:
            logger.warning(f"无效的 Token: {token[:10]}...")
            raise AuthenticationError(
                "Invalid or Expired Token",
                status_code=403
            )
        
        logger.info(f"Token 验证成功: {token[:10]}...")
        return token
    
    def verify_query_token(self, token: Optional[str]) -> str:
        """
        验证查询参数中的 Token（用于 GET 请求）
        
        Args:
            token: 查询参数中的 token 值
            
        Returns:
            验证通过的 Token
            
        Raises:
            AuthenticationError: 认证失败
        """
        if not token:
            logger.warning("缺少 token 查询参数")
            raise AuthenticationError(
                "Missing token parameter. Use ?token=your_token",
                status_code=401
            )
        
        if token not in self.valid_tokens:
            logger.warning(f"无效的查询 Token: {token[:10]}...")
            raise AuthenticationError(
                "Invalid token. Use ?token=xue123",
                status_code=403
            )
        
        logger.info(f"查询 Token 验证成功: {token[:10]}...")
        return token
    
    def extract_auth_from_event(self, event: Dict[str, Any]) -> Optional[str]:
        """
        从 API Gateway 事件中提取认证信息
        
        Args:
            event: API Gateway 事件
            
        Returns:
            Authorization 头的值，如果不存在则返回 None
        """
        # 尝试从不同位置获取 Authorization 头
        headers = event.get('headers', {})
        
        # API Gateway 可能会将头名称转换为小写
        auth_header = (
            headers.get('Authorization') or 
            headers.get('authorization') or
            headers.get('AUTHORIZATION')
        )
        
        if auth_header:
            logger.debug("从请求头中找到 Authorization")
            return auth_header
        
        # 检查多值头（API Gateway v2.0）
        multi_headers = event.get('multiValueHeaders', {})
        auth_values = (
            multi_headers.get('Authorization') or
            multi_headers.get('authorization') or
            multi_headers.get('AUTHORIZATION')
        )
        
        if auth_values and isinstance(auth_values, list) and auth_values:
            logger.debug("从多值请求头中找到 Authorization")
            return auth_values[0]
        
        return None
    
    def extract_query_token_from_event(self, event: Dict[str, Any]) -> Optional[str]:
        """
        从 API Gateway 事件中提取查询参数 token
        
        Args:
            event: API Gateway 事件
            
        Returns:
            token 查询参数的值，如果不存在则返回 None
        """
        # 单值查询参数
        query_params = event.get('queryStringParameters') or {}
        if isinstance(query_params, dict):
            token = query_params.get('token')
            if token:
                logger.debug("从查询参数中找到 token")
                return token
        
        # 多值查询参数
        multi_query_params = event.get('multiValueQueryStringParameters') or {}
        if isinstance(multi_query_params, dict):
            token_values = multi_query_params.get('token')
            if token_values and isinstance(token_values, list) and token_values:
                logger.debug("从多值查询参数中找到 token")
                return token_values[0]
        
        return None
    
    def authenticate_request(self, event: Dict[str, Any], 
                           allow_query_token: bool = False) -> str:
        """
        认证 API Gateway 请求
        
        Args:
            event: API Gateway 事件
            allow_query_token: 是否允许查询参数认证（用于 GET 请求）
            
        Returns:
            验证通过的 Token
            
        Raises:
            AuthenticationError: 认证失败
        """
        # 优先尝试 Bearer Token 认证
        auth_header = self.extract_auth_from_event(event)
        if auth_header:
            return self.verify_bearer_token(auth_header)
        
        # 如果允许，尝试查询参数认证
        if allow_query_token:
            query_token = self.extract_query_token_from_event(event)
            if query_token:
                return self.verify_query_token(query_token)
        
        # 都没有找到认证信息
        logger.warning("请求中未找到认证信息")
        if allow_query_token:
            raise AuthenticationError(
                "Missing authentication. Use Authorization header or ?token=your_token",
                status_code=401
            )
        else:
            raise AuthenticationError(
                "Missing Authorization header",
                status_code=401
            )
    
    def add_token(self, token: str) -> None:
        """
        动态添加有效 Token（用于测试或动态配置）
        
        Args:
            token: 要添加的 Token
        """
        if token not in self.valid_tokens:
            self.valid_tokens.append(token)
            logger.info(f"已添加新 Token: {token[:10]}...")
    
    def remove_token(self, token: str) -> bool:
        """
        移除有效 Token
        
        Args:
            token: 要移除的 Token
            
        Returns:
            是否成功移除
        """
        if token in self.valid_tokens:
            self.valid_tokens.remove(token)
            logger.info(f"已移除 Token: {token[:10]}...")
            return True
        return False
    
    def get_token_count(self) -> int:
        """获取当前有效 Token 数量"""
        return len(self.valid_tokens)


# 全局认证处理器实例（Lambda 容器复用优化）
_auth_handler = None


def get_auth_handler() -> AuthHandler:
    """
    获取认证处理器实例（单例模式）
    
    Returns:
        AuthHandler 实例
    """
    global _auth_handler
    if _auth_handler is None:
        _auth_handler = AuthHandler()
    return _auth_handler


# 便捷函数
def authenticate_event(event: Dict[str, Any], allow_query_token: bool = False) -> str:
    """
    认证 API Gateway 事件的便捷函数
    
    Args:
        event: API Gateway 事件
        allow_query_token: 是否允许查询参数认证
        
    Returns:
        验证通过的 Token
        
    Raises:
        AuthenticationError: 认证失败
    """
    auth_handler = get_auth_handler()
    return auth_handler.authenticate_request(event, allow_query_token)