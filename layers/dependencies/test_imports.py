#!/usr/bin/env python3
"""测试 Lambda Layer 中的包是否可以正常导入"""

import sys
import os

# 添加 Layer 路径
sys.path.insert(0, '/opt/python')
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'python'))

def test_imports():
    """测试关键包的导入"""
    try:
        import pandas as pd
        print(f"✅ pandas {pd.__version__} 导入成功")
    except ImportError as e:
        print(f"❌ pandas 导入失败: {e}")
        return False
    
    try:
        import numpy as np
        print(f"✅ numpy {np.__version__} 导入成功")
    except ImportError as e:
        print(f"❌ numpy 导入失败: {e}")
        return False
    
    try:
        import akshare as ak
        print(f"✅ akshare 导入成功")
    except ImportError as e:
        print(f"❌ akshare 导入失败: {e}")
        return False
    
    try:
        import requests
        print(f"✅ requests {requests.__version__} 导入成功")
    except ImportError as e:
        print(f"❌ requests 导入失败: {e}")
        return False
    
    return True

if __name__ == "__main__":
    print("🧪 测试 Lambda Layer 包导入...")
    if test_imports():
        print("🎉 所有包导入测试通过！")
        sys.exit(0)
    else:
        print("❌ 包导入测试失败！")
        sys.exit(1)
