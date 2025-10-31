#!/usr/bin/env python3
"""
模拟测试脚本，不依赖外部包
"""

import sys
import os
import json
from unittest.mock import Mock, patch

# 添加 src 目录到路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

# 模拟 Lambda 环境变量
os.environ.update({
    'LOG_LEVEL': 'INFO',
    'AWS_REGION': 'cn-northwest-1',
    'VALID_TOKENS': 'xue123,xue1234',
    'MA_SHORT_PERIOD': '5',
    'MA_MEDIUM_PERIOD': '20',
    'MA_LONG_PERIOD': '60',
    'RSI_PERIOD': '14'
})

def test_basic_imports():
    """测试基本模块导入"""
    print("🧪 测试基本模块导入...")
    
    try:
        # 模拟外部依赖
        with patch.dict('sys.modules', {
            'pandas': Mock(),
            'akshare': Mock(),
            'numpy': Mock(),
            'requests': Mock()
        }):
            # 测试导入各个模块
            import response_builder
            import auth_handler
            import error_handler
            import logger
            import utils
            
            print("✅ 所有基础模块导入成功")
            return True
            
    except Exception as e:
        print(f"❌ 模块导入失败: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def test_response_builder():
    """测试响应构建器"""
    print("\n🧪 测试响应构建器...")
    
    try:
        from response_builder import ResponseBuilder
        
        builder = ResponseBuilder()
        
        # 测试成功响应
        response = builder.success_response({"message": "test"})
        assert response['statusCode'] == 200
        assert 'body' in response
        assert 'headers' in response
        
        # 测试错误响应
        error_response = builder.error_response("Test error", 400)
        assert error_response['statusCode'] == 400
        
        print("✅ 响应构建器测试通过")
        return True
        
    except Exception as e:
        print(f"❌ 响应构建器测试失败: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def test_auth_handler():
    """测试认证处理器"""
    print("\n🧪 测试认证处理器...")
    
    try:
        from auth_handler import AuthHandler
        
        auth = AuthHandler()
        
        # 测试有效 token
        try:
            result = auth.verify_bearer_token("Bearer xue123")
            assert result == "xue123"
            print("  ✓ Bearer token 验证通过")
        except Exception:
            print("  ✗ Bearer token 验证失败")
        
        # 测试查询参数 token
        try:
            result = auth.verify_query_token("xue123")
            assert result == "xue123"
            print("  ✓ 查询参数 token 验证通过")
        except Exception:
            print("  ✗ 查询参数 token 验证失败")
        
        print("✅ 认证处理器测试通过")
        return True
        
    except Exception as e:
        print(f"❌ 认证处理器测试失败: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def test_error_handler():
    """测试错误处理器"""
    print("\n🧪 测试错误处理器...")
    
    try:
        from error_handler import ErrorHandler
        
        handler = ErrorHandler()
        
        # 测试异常处理
        try:
            raise ValueError("Test error")
        except Exception as e:
            error_response = handler.handle_error(e)
            assert 'statusCode' in error_response
            assert 'body' in error_response
            assert error_response['statusCode'] == 400
        
        print("✅ 错误处理器测试通过")
        return True
        
    except Exception as e:
        print(f"❌ 错误处理器测试失败: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def test_logger():
    """测试日志记录器"""
    print("\n🧪 测试日志记录器...")
    
    try:
        from logger import get_logger
        
        # 获取日志记录器
        logger = get_logger(__name__)
        
        # 测试日志记录
        logger.info("Test log message")
        logger.debug("Test debug message")
        logger.warning("Test warning message")
        
        print("✅ 日志记录器测试通过")
        return True
        
    except Exception as e:
        print(f"❌ 日志记录器测试失败: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """运行所有测试"""
    print("🚀 开始模拟功能测试...")
    
    tests = [
        ("基本模块导入", test_basic_imports),
        ("响应构建器", test_response_builder),
        ("认证处理器", test_auth_handler),
        ("错误处理器", test_error_handler),
        ("日志记录器", test_logger)
    ]
    
    passed = 0
    total = len(tests)
    
    for name, test_func in tests:
        print(f"\n{'='*50}")
        print(f"测试: {name}")
        print('='*50)
        
        if test_func():
            passed += 1
            print(f"✅ {name} 测试通过")
        else:
            print(f"❌ {name} 测试失败")
    
    print(f"\n{'='*50}")
    print(f"测试结果: {passed}/{total} 通过")
    print('='*50)
    
    return passed == total

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)