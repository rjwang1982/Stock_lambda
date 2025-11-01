#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
简单的本地测试脚本，不依赖 SAM

作者: RJ.Wang
邮箱: wangrenjun@gmail.com
创建时间: 2025-10-31
版本: 1.0
许可证: MIT
"""

import sys
import os
import json

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

def test_health_check():
    """测试健康检查端点"""
    print("🧪 测试健康检查端点...")
    
    # 模拟 API Gateway 事件
    event = {
        "httpMethod": "GET",
        "path": "/health",
        "headers": {
            "User-Agent": "test-client"
        },
        "queryStringParameters": None,
        "body": None,
        "requestContext": {
            "requestId": "test-request-id",
            "stage": "test",
            "identity": {
                "sourceIp": "127.0.0.1"
            },
            "apiId": "test-api"
        }
    }
    
    context = type('Context', (), {
        'function_name': 'test-function',
        'function_version': '$LATEST',
        'memory_limit_in_mb': 512,
        'get_remaining_time_in_millis': lambda: 30000
    })()
    
    try:
        # 导入 Lambda 函数（不使用外部依赖）
        from lambda_function import lambda_handler
        
        # 调用处理器
        response = lambda_handler(event, context)
        
        print(f"✅ 响应状态码: {response['statusCode']}")
        print(f"✅ 响应内容: {json.dumps(json.loads(response['body']), indent=2, ensure_ascii=False)}")
        
        return response['statusCode'] == 200
        
    except Exception as e:
        print(f"❌ 测试失败: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def test_root_path():
    """测试根路径端点"""
    print("\n🧪 测试根路径端点...")
    
    event = {
        "httpMethod": "GET",
        "path": "/",
        "headers": {
            "User-Agent": "test-client"
        },
        "queryStringParameters": None,
        "body": None,
        "requestContext": {
            "requestId": "test-request-id-2",
            "stage": "test",
            "identity": {
                "sourceIp": "127.0.0.1"
            },
            "apiId": "test-api"
        }
    }
    
    context = type('Context', (), {
        'function_name': 'test-function',
        'function_version': '$LATEST',
        'memory_limit_in_mb': 512,
        'get_remaining_time_in_millis': lambda: 30000
    })()
    
    try:
        from lambda_function import lambda_handler
        response = lambda_handler(event, context)
        
        print(f"✅ 响应状态码: {response['statusCode']}")
        print(f"✅ 响应内容: {json.dumps(json.loads(response['body']), indent=2, ensure_ascii=False)}")
        
        return response['statusCode'] == 200
        
    except Exception as e:
        print(f"❌ 测试失败: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """运行所有测试"""
    print("🚀 开始本地功能测试...")
    
    tests = [
        ("健康检查", test_health_check),
        ("根路径", test_root_path)
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