# 05 - CentOS 7 Claude Code 完整配置指南

> 本文档详细说明如何在 CentOS 7 VMware 虚拟机上配置 Claude API

---

## 📋 目录

1. [环境要求](#1-环境要求)
2. [Python 环境配置](#2-python-环境配置)
3. [Claude API 配置](#3-claude-api-配置)
4. [claude_debug.py 脚本详解](#4-claude_debugpy-脚本详解)
5. [快捷命令配置](#5-快捷命令配置)
6. [使用示例](#6-使用示例)
7. [故障排除](#7-故障排除)

---

## 1. 环境要求

### 1.1 硬件环境

```yaml
主机系统: Windows 10/11
虚拟机软件: VMware Workstation 15+
虚拟机系统: CentOS 7
内存分配: 建议 8GB+
网络: 需要能访问外网 (API调用)
```

### 1.2 软件依赖

| 软件 | 最低版本 | 检查命令 | 用途 |
|------|----------|----------|------|
| Python | 3.8+ | `python3 --version` | 运行脚本 |
| pip | 最新 | `pip3 --version` | 安装依赖 |
| git | 2.0+ | `git --version` | 代码管理 |
| curl | 任意 | `curl --version` | 网络测试 |

### 1.3 API 信息

```yaml
购买渠道: 咸鱼
API 地址: https://www.zz166.cn/v1
API 密钥: [你购买后获得的密钥]
计费方式: [根据你的套餐]
```

---

## 2. Python 环境配置

### 2.1 检查现有 Python

```bash
# 检查 Python 版本
python3 --version

# 如果版本低于 3.8，需要升级
```

### 2.2 安装 Python 3.8 (如果需要)

```bash
# 方法1: 使用 SCL (推荐)
sudo yum install -y centos-release-scl
sudo yum install -y rh-python38

# 启用 Python 3.8
scl enable rh-python38 bash

# 永久启用 (添加到 ~/.bashrc)
echo 'source /opt/rh/rh-python38/enable' >> ~/.bashrc
source ~/.bashrc

# 验证
python3 --version  # 应该显示 3.8.x
```

```bash
# 方法2: 从源码编译 (备选)
sudo yum groupinstall -y "Development Tools"
sudo yum install -y openssl-devel bzip2-devel libffi-devel

cd /tmp
wget https://www.python.org/ftp/python/3.8.12/Python-3.8.12.tgz
tar -xzf Python-3.8.12.tgz
cd Python-3.8.12
./configure --enable-optimizations
make -j$(nproc)
sudo make altinstall

# 验证
python3.8 --version
```

### 2.3 创建项目虚拟环境

```bash
# 进入项目目录
cd /home/jjt/Titan_TPU_V2

# 创建虚拟环境
python3 -m venv venv

# 激活虚拟环境
source venv/bin/activate

# 验证 (命令行前缀应该变成 (venv))
which python  # 应该显示 /home/jjt/Titan_TPU_V2/venv/bin/python
```

### 2.4 安装 Python 依赖

```bash
# 确保虚拟环境已激活
source /home/jjt/Titan_TPU_V2/venv/bin/activate

# 升级 pip
pip install --upgrade pip

# 安装依赖
pip install anthropic      # Anthropic 官方 SDK
pip install requests       # HTTP 请求
pip install rich           # 美化输出 (可选)
pip install typer          # 命令行界面 (可选)

# 验证安装
pip list | grep anthropic
```

---

## 3. Claude API 配置

### 3.1 测试 API 连通性

```bash
# 测试网络连接
curl -I https://www.zz166.cn

# 如果返回 HTTP 200，说明网络正常
```

### 3.2 创建 API 配置文件

```bash
# 创建配置目录
mkdir -p ~/.config/claude

# 创建配置文件
cat > ~/.config/claude/config.json << 'EOF'
{
    "api_key": "YOUR_API_KEY_HERE",
    "base_url": "https://www.zz166.cn/v1",
    "model": "claude-sonnet-4-20250514",
    "max_tokens": 4000,
    "timeout": 60
}
EOF

# 设置权限 (只有自己能读)
chmod 600 ~/.config/claude/config.json

# ⚠️ 编辑配置，填入你的 API 密钥
nano ~/.config/claude/config.json
```

### 3.3 测试 API 调用

```bash
# 创建测试脚本
cat > /tmp/test_claude.py << 'EOF'
#!/usr/bin/env python3
import anthropic
import json

# 读取配置
with open('/home/jjt/.config/claude/config.json', 'r') as f:
    config = json.load(f)

# 创建客户端
client = anthropic.Anthropic(
    api_key=config['api_key'],
    base_url=config['base_url']
)

# 测试调用
try:
    message = client.messages.create(
        model=config['model'],
        max_tokens=100,
        messages=[{"role": "user", "content": "你好，请回复'测试成功'"}]
    )
    print("✅ API 测试成功!")
    print(f"回复: {message.content[0].text}")
except Exception as e:
    print(f"❌ API 测试失败: {e}")
EOF

# 运行测试
source /home/jjt/Titan_TPU_V2/venv/bin/activate
python /tmp/test_claude.py
```

---

## 4. claude_debug.py 脚本详解

### 4.1 完整脚本源码

```bash
# 创建完整的 claude_debug.py
cat > /home/jjt/Titan_TPU_V2/claude_debug.py << 'PYTHONSCRIPT'
#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
Titan-TPU V2 Claude Debug 助手
═══════════════════════════════════════════════════════════════════════════════

功能:
  - debug:   调试 VCS 编译/仿真错误
  - review:  代码审查
  - explain: 解释代码原理
  - design:  设计新模块
  - ask:     通用问题

用法:
  python claude_debug.py <命令> [参数]

示例:
  python claude_debug.py debug "Error-[ICPD]" pe.sv
  python claude_debug.py review _vendor/tiny-tpu-v2/src/pe.sv
  python claude_debug.py explain _vendor/tiny-tpu-v2/src/systolic.sv
  python claude_debug.py design "设计 ECC 编码器"
  python claude_debug.py ask "什么是 Weight Stationary?"

═══════════════════════════════════════════════════════════════════════════════
"""

import anthropic
import sys
import os
import json
from pathlib import Path
from datetime import datetime

# ═══════════════════════════════════════════════════════════════════════════════
# 配置
# ═══════════════════════════════════════════════════════════════════════════════

def load_config():
    """加载配置"""
    config_paths = [
        Path.home() / '.config' / 'claude' / 'config.json',
        Path('/home/jjt/Titan_TPU_V2/.claude_config.json'),
    ]
    
    for path in config_paths:
        if path.exists():
            with open(path, 'r') as f:
                return json.load(f)
    
    # 默认配置 (需要手动修改)
    return {
        "api_key": "YOUR_API_KEY_HERE",
        "base_url": "https://www.zz166.cn/v1",
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 4000
    }

CONFIG = load_config()

# ═══════════════════════════════════════════════════════════════════════════════
# Prompt 模板
# ═══════════════════════════════════════════════════════════════════════════════

PROMPTS = {
    "debug": """你是一个资深芯片设计工程师，精通 SystemVerilog 和 VCS/Verdi 调试。

## 任务
分析并修复以下编译/仿真错误。

## 错误信息
```
{error}
```

## 相关代码
文件: {filename}
```systemverilog
{code}
```

## 要求
1. **错误分析**: 解释错误的原因
2. **修复代码**: 给出修复后的完整代码块
3. **修复原理**: 解释为什么这样修复
4. **预防建议**: 如何避免类似错误

请用中文回答。""",

    "review": """你是一个资深芯片设计工程师，进行 RTL 代码审查。

## 任务
审查以下 SystemVerilog 代码。

## 代码
文件: {filename}
```systemverilog
{code}
```

## 审查要点
1. **语法检查**: 是否有语法错误
2. **可综合性**: 是否会推断出锁存器、多驱动等问题
3. **时序设计**: 复位设计、跨时钟域处理
4. **代码风格**: 命名规范、注释、可读性
5. **潜在 Bug**: 边界条件、溢出、未初始化等
6. **优化建议**: 面积/时序/功耗优化

## 输出格式
对每个问题，给出:
- 行号
- 问题描述
- 严重程度 (高/中/低)
- 修复建议

请用中文回答。""",

    "explain": """你是一个经验丰富的芯片设计老师。

## 任务
解释以下代码的工作原理，适合新手理解。

## 代码
文件: {filename}
```systemverilog
{code}
```

## 解释要点
1. **模块功能**: 这个模块是做什么的？
2. **端口说明**: 每个输入输出端口的作用？
3. **核心逻辑**: 内部是怎么工作的？
4. **数据流**: 数据是怎么流动的？
5. **关键设计**: 有哪些关键的设计决策？
6. **时序图**: 如果可能，画一个简单的时序图 (ASCII)

请用简单易懂的中文解释。""",

    "design": """你是一个资深 AI 加速器架构师。

## 项目背景
- 项目名: Titan-TPU V2
- 基于: tiny-tpu-v2 (SystemVerilog, 2×2 脉动阵列)
- 魔改目标: ECC + Sparse + AXI

## 设计任务
{task}

## 输出要求
1. **需求分析**: 明确功能需求
2. **架构设计**: 模块划分和数据流 (ASCII图)
3. **接口定义**: 完整的端口列表
4. **RTL 代码**: 完整可综合的 SystemVerilog 代码
5. **验证要点**: 关键测试用例
6. **面试问题**: 可能被问到的问题及回答

请用中文回答。""",

    "ask": """你是一个资深 AI 加速器架构师和老师。

## 背景
我正在做一个 TPU 项目 (基于 tiny-tpu-v2)，需要你的帮助。

## 问题
{question}

## 要求
- 用中文回答
- 适合新手理解
- 如果涉及代码，请给出示例
- 如果涉及概念，请用类比解释

请详细回答。"""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 核心函数
# ═══════════════════════════════════════════════════════════════════════════════

def read_file(filepath):
    """读取文件内容"""
    if not filepath:
        return None, None
    
    path = Path(filepath)
    if not path.exists():
        # 尝试相对于项目根目录
        project_root = Path('/home/jjt/Titan_TPU_V2')
        path = project_root / filepath
        
    if not path.exists():
        return None, filepath
        
    try:
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            return f.read(), str(path)
    except Exception as e:
        return None, str(path)

def call_claude(prompt):
    """调用 Claude API"""
    if CONFIG["api_key"] == "YOUR_API_KEY_HERE":
        return "❌ 错误: 请先配置 API 密钥!\n\n编辑 ~/.config/claude/config.json"
    
    try:
        client = anthropic.Anthropic(
            api_key=CONFIG["api_key"],
            base_url=CONFIG["base_url"]
        )
        
        message = client.messages.create(
            model=CONFIG["model"],
            max_tokens=CONFIG["max_tokens"],
            messages=[{"role": "user", "content": prompt}]
        )
        
        return message.content[0].text
    
    except anthropic.APIConnectionError:
        return "❌ 网络错误: 无法连接到 API 服务器\n请检查网络和 API 地址"
    except anthropic.AuthenticationError:
        return "❌ 认证错误: API 密钥无效\n请检查你的 API 密钥"
    except anthropic.RateLimitError:
        return "❌ 频率限制: 请求过于频繁\n请稍后再试"
    except Exception as e:
        return f"❌ 未知错误: {e}"

def save_log(command, args, response):
    """保存会话日志"""
    log_dir = Path('/home/jjt/Titan_TPU_V2/logs/claude_sessions')
    log_dir.mkdir(parents=True, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = log_dir / f"{command}_{timestamp}.md"
    
    with open(log_file, 'w', encoding='utf-8') as f:
        f.write(f"# Claude Debug Session\n\n")
        f.write(f"**时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"**命令**: `{command}`\n")
        f.write(f"**参数**: `{args}`\n\n")
        f.write(f"---\n\n")
        f.write(f"## 回答\n\n{response}\n")
    
    return log_file

# ═══════════════════════════════════════════════════════════════════════════════
# 命令处理
# ═══════════════════════════════════════════════════════════════════════════════

def cmd_debug(args):
    """调试命令"""
    if len(args) < 1:
        return "用法: python claude_debug.py debug <错误信息> [代码文件]"
    
    error_msg = args[0]
    code_file = args[1] if len(args) > 1 else None
    
    code, filename = read_file(code_file)
    if code_file and not code:
        return f"❌ 文件未找到: {code_file}"
    
    prompt = PROMPTS["debug"].format(
        error=error_msg,
        filename=filename or "未提供",
        code=code or "未提供代码"
    )
    
    return call_claude(prompt)

def cmd_review(args):
    """代码审查命令"""
    if len(args) < 1:
        return "用法: python claude_debug.py review <代码文件>"
    
    code, filename = read_file(args[0])
    if not code:
        return f"❌ 文件未找到: {args[0]}"
    
    prompt = PROMPTS["review"].format(filename=filename, code=code)
    return call_claude(prompt)

def cmd_explain(args):
    """解释命令"""
    if len(args) < 1:
        return "用法: python claude_debug.py explain <代码文件>"
    
    code, filename = read_file(args[0])
    if not code:
        return f"❌ 文件未找到: {args[0]}"
    
    prompt = PROMPTS["explain"].format(filename=filename, code=code)
    return call_claude(prompt)

def cmd_design(args):
    """设计命令"""
    if len(args) < 1:
        return "用法: python claude_debug.py design <任务描述>"
    
    task = " ".join(args)
    prompt = PROMPTS["design"].format(task=task)
    return call_claude(prompt)

def cmd_ask(args):
    """通用问题命令"""
    if len(args) < 1:
        return "用法: python claude_debug.py ask <问题>"
    
    question = " ".join(args)
    prompt = PROMPTS["ask"].format(question=question)
    return call_claude(prompt)

# ═══════════════════════════════════════════════════════════════════════════════
# 主函数
# ═══════════════════════════════════════════════════════════════════════════════

def print_help():
    """打印帮助"""
    print(__doc__)

def main():
    if len(sys.argv) < 2:
        print_help()
        return
    
    command = sys.argv[1].lower()
    args = sys.argv[2:]
    
    commands = {
        "debug": cmd_debug,
        "review": cmd_review,
        "explain": cmd_explain,
        "design": cmd_design,
        "ask": cmd_ask,
        "help": lambda x: print_help(),
        "-h": lambda x: print_help(),
        "--help": lambda x: print_help(),
    }
    
    if command not in commands:
        print(f"❌ 未知命令: {command}")
        print("使用 'python claude_debug.py help' 查看帮助")
        return
    
    print("═" * 70)
    print("🤖 Titan-TPU Claude Debug")
    print("═" * 70)
    print()
    
    response = commands[command](args)
    print(response)
    
    # 保存日志
    if command not in ["help", "-h", "--help"]:
        log_file = save_log(command, args, response)
        print()
        print("─" * 70)
        print(f"📝 日志已保存: {log_file}")

if __name__ == "__main__":
    main()
PYTHONSCRIPT

# 设置执行权限
chmod +x /home/jjt/Titan_TPU_V2/claude_debug.py

echo "✅ claude_debug.py 创建完成"
```

### 4.2 脚本功能说明

| 命令 | 功能 | 参数 | 示例 |
|------|------|------|------|
| `debug` | 调试错误 | 错误信息 [代码文件] | `debug "Error-[ICPD]" pe.sv` |
| `review` | 代码审查 | 代码文件 | `review systolic.sv` |
| `explain` | 解释代码 | 代码文件 | `explain pe.sv` |
| `design` | 设计模块 | 任务描述 | `design "设计ECC编码器"` |
| `ask` | 通用问题 | 问题内容 | `ask "什么是脉动阵列"` |

---

## 5. 快捷命令配置

### 5.1 添加 Bash 别名

```bash
# 编辑 ~/.bashrc
cat >> ~/.bashrc << 'EOF'

# ═══════════════════════════════════════════════════════════════════════════════
# Titan-TPU V2 快捷命令
# ═══════════════════════════════════════════════════════════════════════════════

# 环境激活
alias tpu-env='cd /home/jjt/Titan_TPU_V2 && source venv/bin/activate && source env_setup.sh && echo "✅ TPU 环境已激活"'

# Claude Debug 命令
alias claude-debug='python /home/jjt/Titan_TPU_V2/claude_debug.py debug'
alias claude-review='python /home/jjt/Titan_TPU_V2/claude_debug.py review'
alias claude-explain='python /home/jjt/Titan_TPU_V2/claude_debug.py explain'
alias claude-design='python /home/jjt/Titan_TPU_V2/claude_debug.py design'
alias claude-ask='python /home/jjt/Titan_TPU_V2/claude_debug.py ask'

# 仿真命令
alias tpu-pe='cd /home/jjt/Titan_TPU_V2/sim/vcs && make pe'
alias tpu-systolic='cd /home/jjt/Titan_TPU_V2/sim/vcs && make systolic'
alias tpu-clean='cd /home/jjt/Titan_TPU_V2/sim/vcs && make clean'

# 快速跳转
alias tpu-src='cd /home/jjt/Titan_TPU_V2/_vendor/tiny-tpu-v2/src'
alias tpu-tb='cd /home/jjt/Titan_TPU_V2/tb'
alias tpu-sim='cd /home/jjt/Titan_TPU_V2/sim/vcs'
alias tpu-log='cd /home/jjt/Titan_TPU_V2/logs'

# ═══════════════════════════════════════════════════════════════════════════════
EOF

# 重新加载
source ~/.bashrc
```

### 5.2 快捷命令速查表

| 命令 | 功能 |
|------|------|
| `tpu-env` | 激活项目环境 |
| `claude-debug` | 调试错误 |
| `claude-review` | 代码审查 |
| `claude-explain` | 解释代码 |
| `claude-design` | 设计模块 |
| `claude-ask` | 通用问题 |
| `tpu-pe` | 运行 PE 测试 |
| `tpu-systolic` | 运行 Systolic 测试 |
| `tpu-clean` | 清理仿真文件 |
| `tpu-src` | 跳转到源码目录 |
| `tpu-tb` | 跳转到 testbench 目录 |

---

## 6. 使用示例

### 6.1 调试 VCS 编译错误

```bash
# 激活环境
tpu-env

# 假设 VCS 报错:
# Error-[ICPD] Illegal combination of drivers
# Variable "weight_reg_active"...

# 使用 Claude 调试
claude-debug "Error-[ICPD] weight_reg_active 被 always_comb 和 always_ff 同时驱动" _vendor/tiny-tpu-v2/src/pe.sv
```

### 6.2 代码审查

```bash
# 审查 PE 模块
claude-review _vendor/tiny-tpu-v2/src/pe.sv

# 审查 Systolic 模块
claude-review _vendor/tiny-tpu-v2/src/systolic.sv
```

### 6.3 学习代码原理

```bash
# 解释 PE 模块
claude-explain _vendor/tiny-tpu-v2/src/pe.sv

# 解释定点数库
claude-explain _vendor/tiny-tpu-v2/src/fixedpoint.sv
```

### 6.4 设计新模块

```bash
# 设计 ECC 编码器
claude-design "设计一个 Hamming(39,32) SECDED ECC 编码器，输入 32 位数据，输出 39 位编码数据"

# 设计 Sparse PE
claude-design "设计一个支持零值跳过的 Sparse PE，当输入或权重为零时跳过计算，并添加 Clock Gating"
```

### 6.5 通用问题

```bash
# 概念问题
claude-ask "什么是 Weight Stationary 数据流？和 Output Stationary 有什么区别？"

# 设计问题
claude-ask "如何在 SystemVerilog 中实现 Clock Gating？"
```

---

## 7. 故障排除

### 7.1 常见错误

| 错误 | 原因 | 解决方案 |
|------|------|----------|
| `API 密钥无效` | 密钥错误或过期 | 检查配置文件中的 api_key |
| `无法连接到服务器` | 网络问题 | 检查网络，确认能访问 www.zz166.cn |
| `模块 anthropic 不存在` | 未安装依赖 | `pip install anthropic` |
| `文件未找到` | 路径错误 | 检查文件路径，使用绝对路径 |
| `频率限制` | 调用太频繁 | 等待几分钟再试 |

### 7.2 调试步骤

```bash
# 1. 检查 Python 环境
which python
python --version

# 2. 检查虚拟环境
source /home/jjt/Titan_TPU_V2/venv/bin/activate
pip list | grep anthropic

# 3. 检查配置文件
cat ~/.config/claude/config.json

# 4. 测试 API 连接
curl -I https://www.zz166.cn

# 5. 查看错误日志
ls -la /home/jjt/Titan_TPU_V2/logs/claude_sessions/
```

### 7.3 重置环境

```bash
# 删除虚拟环境
rm -rf /home/jjt/Titan_TPU_V2/venv

# 重新创建
cd /home/jjt/Titan_TPU_V2
python3 -m venv venv
source venv/bin/activate
pip install anthropic requests
```

---

## 📋 检查清单

配置完成后，确认以下事项:

- [ ] Python 3.8+ 已安装
- [ ] 虚拟环境已创建 (`/home/jjt/Titan_TPU_V2/venv`)
- [ ] anthropic 库已安装
- [ ] API 密钥已配置
- [ ] `claude_debug.py` 可执行
- [ ] 快捷命令已添加到 `~/.bashrc`
- [ ] `tpu-env` 命令正常工作
- [ ] `claude-ask "测试"` 返回正常

---

*文档版本: v1.0 | 更新时间: 2025-01-16*
