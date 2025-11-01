# Project Structure & Organization

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**创建时间：** 2025-10-31

## Directory Layout

```
Stock_lambda/
├── src/                    # Lambda function source code
│   ├── lambda_function.py  # Main handler and routing
│   ├── stock_analyzer.py   # Core analysis logic
│   ├── auth_handler.py     # Authentication handling
│   ├── response_builder.py # API response formatting
│   ├── error_handler.py    # Centralized error handling
│   ├── logger.py          # Structured logging
│   └── utils.py           # Utility functions
├── layers/dependencies/    # Lambda Layer for heavy dependencies
│   ├── requirements-layer.txt
│   ├── Dockerfile
│   ├── Makefile
│   └── build-simple.sh
├── events/                # API Gateway test events
├── scripts/               # Deployment and build scripts
├── tests/                 # Unit and integration tests
├── docs/                  # Comprehensive documentation
├── template.yaml          # SAM infrastructure template
├── samconfig.toml         # SAM deployment configuration
└── requirements.txt       # Function-level dependencies
```

## Code Organization Principles

### Module Responsibilities
- **lambda_function.py**: Entry point, request routing, CORS handling
- **stock_analyzer.py**: Technical analysis calculations, data fetching
- **auth_handler.py**: Bearer token validation, multi-token support
- **response_builder.py**: Standardized JSON responses, error formatting
- **error_handler.py**: Custom exceptions, unified error handling
- **logger.py**: Structured JSON logging with business context
- **utils.py**: Data validation, date handling, parameter extraction

### File Naming Conventions
- **Python files**: snake_case (e.g., `stock_analyzer.py`)
- **Configuration files**: lowercase with extensions (e.g., `template.yaml`)
- **Documentation**: UPPERCASE.md (e.g., `README.md`, `API_USAGE.md`)
- **Scripts**: kebab-case with .sh extension (e.g., `build-layer.sh`)

### Import Structure
```python
# Standard library imports first
import os
import json
from typing import Dict, Any

# Third-party imports
import pandas as pd
import akshare as ak

# Local module imports
from auth_handler import authenticate_event
from response_builder import get_response_builder
```

## Configuration Files

### Core Configuration
- **template.yaml**: SAM template with all AWS resources
- **samconfig.toml**: Deployment parameters and profiles
- **requirements.txt**: Lightweight function dependencies

### Environment-Specific
- Environment variables configured via SAM parameters
- Separate parameter sets for dev/test/prod environments
- Sensitive values (tokens) marked with `NoEcho: true`

## Documentation Structure
- **README.md**: Complete project overview and quick start
- **docs/API_USAGE.md**: Detailed API documentation with examples
- **docs/DEPLOYMENT.md**: Step-by-step deployment guide
- **docs/ENVIRONMENT_VARIABLES.md**: Configuration reference
- **PROJECT_STRUCTURE.md**: Detailed directory explanation

## Testing Organization
- **events/**: JSON test events for different API scenarios
- **tests/**: Unit tests following pytest conventions
- Local testing via `sam local` commands

## Build Artifacts
- **.aws-sam/**: SAM build output (gitignored)
- **layers/dependencies/python/**: Built layer packages (gitignored)
- Generated during build process, not committed to version control

## Deployment Scripts
- **scripts/deploy.sh**: Automated deployment with validation
- **scripts/build-layer.sh**: Layer building automation
- **scripts/pre-deploy-check.sh**: Pre-deployment validation

## Code Style Guidelines
- **Python**: Follow PEP 8 with 4-space indentation
- **Docstrings**: Google-style docstrings for all functions
- **Type Hints**: Use typing module for function signatures
- **Error Handling**: Custom exception classes with descriptive messages
- **Logging**: Structured JSON logs with correlation IDs

---

**作者：** RJ.Wang  
**邮箱：** wangrenjun@gmail.com  
**文档版本：** v1.0  
**最后更新：** 2025-10-31  
**适用于：** 项目结构, 代码规范, AWS Lambda