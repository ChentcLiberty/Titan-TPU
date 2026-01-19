# 12 - 脚本集合

> 所有项目脚本的源码，可以直接复制使用

---

## 📋 目录

1. [环境设置脚本](#1-环境设置脚本)
2. [Claude Debug 脚本](#2-claude-debug-脚本)
3. [VCS Makefile](#3-vcs-makefile)
4. [一键安装脚本](#4-一键安装脚本)

---

## 1. 环境设置脚本

### 文件: `/home/jjt/Titan_TPU_V2/env_setup.sh`

```bash
#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Titan-TPU V2 环境配置脚本
# ═══════════════════════════════════════════════════════════════════════════════

# License 服务器
export LM_LICENSE_FILE=27000@localhost.localdomain:/home/jjt/install/cadence/cadence.dat:/home/jjt/install/mentor/license/license.dat

# Synopsys VCS
export VCS_HOME=/home/jjt/install/synopsys/vcs/vcs/T-2022.06
export VCS_ARCH_OVERRIDE=linux
export PATH=$VCS_HOME/bin:$PATH

# Synopsys Verdi
export VERDI_HOME=/home/jjt/install/synopsys/verdi/verdi/T-2022.06
export PATH=$VERDI_HOME/bin:$PATH

# Synopsys Design Compiler
export DC_HOME=/home/jjt/install/synopsys/dc/syn/T-2022.03-SP2
export PATH=$DC_HOME/bin:$PATH

# 项目路径
export TITAN_TPU_ROOT=/home/jjt/Titan_TPU_V2
export TINY_TPU_SRC=$TITAN_TPU_ROOT/_vendor/tiny-tpu-v2/src
export AXI_SRC=$TITAN_TPU_ROOT/_vendor/verilog-axi/rtl

# 提示信息
echo "═══════════════════════════════════════════════════════════════════"
echo "✅ Titan-TPU V2 环境已加载"
echo "═══════════════════════════════════════════════════════════════════"
echo "   VCS:   $(which vcs 2>/dev/null || echo 'Not found')"
echo "   Verdi: $(which verdi 2>/dev/null || echo 'Not found')"
echo "   DC:    $(which dc_shell 2>/dev/null || echo 'Not found')"
echo ""
echo "   项目根目录: $TITAN_TPU_ROOT"
echo "   TPU 源码:   $TINY_TPU_SRC"
echo "═══════════════════════════════════════════════════════════════════"
```

**使用方法:**
```bash
source /home/jjt/Titan_TPU_V2/env_setup.sh
```

---

## 2. Claude Debug 脚本

### 文件: `/home/jjt/Titan_TPU_V2/claude_debug.py`

```python
#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
Titan-TPU V2 Claude Debug 助手
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
    
    return {
        "api_key": "YOUR_API_KEY_HERE",  # ⚠️ 修改这里
        "base_url": "https://www.zz166.cn/v1",
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 4000
    }

CONFIG = load_config()

# ═══════════════════════════════════════════════════════════════════════════════
# Prompt 模板
# ═══════════════════════════════════════════════════════════════════════════════

PROMPTS = {
    "debug": """你是资深芯片设计工程师，精通 SystemVerilog 和 VCS 调试。

## 任务
分析并修复以下错误。

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
1. 分析错误原因
2. 给出修复后的代码
3. 解释修复原理
4. 预防建议

用中文回答。""",

    "review": """你是资深芯片设计工程师，进行代码审查。

## 代码
文件: {filename}
```systemverilog
{code}
```

## 审查要点
1. 语法
2. 可综合性
3. 时序
4. 风格
5. Bug

用中文回答。""",

    "explain": """你是芯片设计老师。

## 任务
解释以下代码，适合新手。

## 代码
文件: {filename}
```systemverilog
{code}
```

用简单中文解释。""",

    "design": """你是 AI 加速器架构师。

## 项目
Titan-TPU V2 (基于 tiny-tpu-v2)

## 任务
{task}

## 要求
1. 架构图 (ASCII)
2. 接口定义
3. RTL 代码
4. 验证要点

用中文回答。""",

    "ask": """你是 AI 加速器架构师和老师。

## 问题
{question}

用中文详细回答，适合新手。"""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 核心函数
# ═══════════════════════════════════════════════════════════════════════════════

def read_file(filepath):
    if not filepath:
        return None, None
    
    path = Path(filepath)
    if not path.exists():
        path = Path('/home/jjt/Titan_TPU_V2') / filepath
        
    if not path.exists():
        return None, filepath
        
    try:
        with open(path, 'r', encoding='utf-8', errors='ignore') as f:
            return f.read(), str(path)
    except:
        return None, str(path)

def call_claude(prompt):
    if CONFIG["api_key"] == "YOUR_API_KEY_HERE":
        return "❌ 请先配置 API 密钥"
    
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
    
    except Exception as e:
        return f"❌ 错误: {e}"

def save_log(command, args, response):
    log_dir = Path('/home/jjt/Titan_TPU_V2/logs/claude_sessions')
    log_dir.mkdir(parents=True, exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = log_dir / f"{command}_{timestamp}.md"
    
    with open(log_file, 'w', encoding='utf-8') as f:
        f.write(f"# Claude Session: {command}\n")
        f.write(f"**时间**: {datetime.now()}\n")
        f.write(f"**参数**: {args}\n\n")
        f.write(f"## 回答\n{response}\n")
    
    return log_file

# ═══════════════════════════════════════════════════════════════════════════════
# 命令处理
# ═══════════════════════════════════════════════════════════════════════════════

def cmd_debug(args):
    if len(args) < 1:
        return "用法: python claude_debug.py debug <错误> [文件]"
    
    error = args[0]
    code_file = args[1] if len(args) > 1 else None
    code, filename = read_file(code_file)
    
    prompt = PROMPTS["debug"].format(
        error=error,
        filename=filename or "未提供",
        code=code or "未提供"
    )
    return call_claude(prompt)

def cmd_review(args):
    if len(args) < 1:
        return "用法: python claude_debug.py review <文件>"
    
    code, filename = read_file(args[0])
    if not code:
        return f"❌ 文件未找到: {args[0]}"
    
    prompt = PROMPTS["review"].format(filename=filename, code=code)
    return call_claude(prompt)

def cmd_explain(args):
    if len(args) < 1:
        return "用法: python claude_debug.py explain <文件>"
    
    code, filename = read_file(args[0])
    if not code:
        return f"❌ 文件未找到: {args[0]}"
    
    prompt = PROMPTS["explain"].format(filename=filename, code=code)
    return call_claude(prompt)

def cmd_design(args):
    if len(args) < 1:
        return "用法: python claude_debug.py design <任务>"
    
    task = " ".join(args)
    prompt = PROMPTS["design"].format(task=task)
    return call_claude(prompt)

def cmd_ask(args):
    if len(args) < 1:
        return "用法: python claude_debug.py ask <问题>"
    
    question = " ".join(args)
    prompt = PROMPTS["ask"].format(question=question)
    return call_claude(prompt)

def print_help():
    print("""
═══════════════════════════════════════════════════════════════════════════════
🤖 Titan-TPU Claude Debug

命令:
  debug   <错误> [文件]    调试 VCS 错误
  review  <文件>          代码审查
  explain <文件>          解释代码
  design  <任务>          设计模块
  ask     <问题>          通用问题

示例:
  python claude_debug.py debug "Error-[ICPD]" pe.sv
  python claude_debug.py review pe.sv
  python claude_debug.py explain systolic.sv
  python claude_debug.py design "设计ECC编码器"
  python claude_debug.py ask "什么是脉动阵列"
═══════════════════════════════════════════════════════════════════════════════
""")

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
    }
    
    if command not in commands:
        print(f"❌ 未知命令: {command}")
        return
    
    print("🤖 处理中...")
    print("─" * 60)
    
    response = commands[command](args)
    print(response)
    
    if command not in ["help"]:
        log_file = save_log(command, args, response)
        print("─" * 60)
        print(f"📝 日志: {log_file}")

if __name__ == "__main__":
    main()
```

**使用方法:**
```bash
chmod +x claude_debug.py
python claude_debug.py help
```

---

## 3. VCS Makefile

### 文件: `/home/jjt/Titan_TPU_V2/sim/vcs/Makefile`

```makefile
# ═══════════════════════════════════════════════════════════════════════════════
# Titan-TPU V2 VCS Makefile
# ═══════════════════════════════════════════════════════════════════════════════

# 工具
VCS = vcs
VERDI = verdi

# 路径
PROJECT_ROOT = /home/jjt/Titan_TPU_V2
SRC_DIR = $(PROJECT_ROOT)/_vendor/tiny-tpu-v2/src
TB_DIR = $(PROJECT_ROOT)/tb
LOG_DIR = $(PROJECT_ROOT)/sim/logs
WAVE_DIR = $(PROJECT_ROOT)/sim/waveforms

# VCS 选项
VCS_FLAGS = \
    -full64 \
    -sverilog \
    -debug_access+all \
    -timescale=1ns/1ps \
    +v2k \
    -notice

# 源文件
FXP_SRC = $(SRC_DIR)/fixedpoint.sv
PE_SRC = $(SRC_DIR)/pe.sv
SYSTOLIC_SRC = $(SRC_DIR)/systolic.sv
VPU_SRC = $(SRC_DIR)/vpu.sv
BUFFER_SRC = $(SRC_DIR)/unified_buffer.sv
CTRL_SRC = $(SRC_DIR)/control_unit.sv
TPU_SRC = $(SRC_DIR)/tpu.sv

# ═══════════════════════════════════════════════════════════════════════════════
# 目标
# ═══════════════════════════════════════════════════════════════════════════════

.PHONY: all pe systolic tpu clean help dirs

all: help

dirs:
	@mkdir -p $(LOG_DIR) $(WAVE_DIR)

# PE 测试
pe: dirs
	@echo "═══════════════════════════════════════════════════════════════════"
	@echo "🔧 编译 PE 模块"
	@echo "═══════════════════════════════════════════════════════════════════"
	$(VCS) $(VCS_FLAGS) \
		$(FXP_SRC) \
		$(PE_SRC) \
		$(TB_DIR)/tb_pe.sv \
		-o pe_sim \
		-l $(LOG_DIR)/pe_compile.log
	@echo ""
	@echo "🚀 运行仿真..."
	./pe_sim -l $(LOG_DIR)/pe_sim.log
	@echo ""
	@echo "✅ PE 测试完成!"

# Systolic Array 测试
systolic: dirs
	@echo "🔧 编译 Systolic Array..."
	$(VCS) $(VCS_FLAGS) \
		$(FXP_SRC) \
		$(PE_SRC) \
		$(SYSTOLIC_SRC) \
		$(TB_DIR)/tb_systolic.sv \
		-o systolic_sim \
		-l $(LOG_DIR)/systolic_compile.log
	./systolic_sim -l $(LOG_DIR)/systolic_sim.log

# 语法检查
check_pe: dirs
	$(VCS) $(VCS_FLAGS) -parse_only $(FXP_SRC) $(PE_SRC)
	@echo "✅ PE 语法检查通过"

# Verdi
verdi:
	$(VERDI) -ssf $(WAVE_DIR)/*.fsdb &

# 清理
clean:
	rm -rf *_sim *.daidir csrc *.log *.key simv* ucli.key
	rm -rf $(LOG_DIR)/* $(WAVE_DIR)/*
	@echo "🧹 清理完成"

# 帮助
help:
	@echo "═══════════════════════════════════════════════════════════════════"
	@echo "🚀 Titan-TPU V2 Makefile"
	@echo "═══════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "  make pe        - PE 模块测试"
	@echo "  make systolic  - Systolic Array 测试"
	@echo "  make check_pe  - PE 语法检查"
	@echo "  make verdi     - 打开 Verdi"
	@echo "  make clean     - 清理"
	@echo ""
	@echo "═══════════════════════════════════════════════════════════════════"
```

---

## 4. 一键安装脚本

### 文件: `setup_titan_tpu.sh`

```bash
#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Titan-TPU V2 一键安装脚本
# ═══════════════════════════════════════════════════════════════════════════════

set -e

PROJECT_ROOT=/home/jjt/Titan_TPU_V2

echo "═══════════════════════════════════════════════════════════════════"
echo "🚀 Titan-TPU V2 安装开始"
echo "═══════════════════════════════════════════════════════════════════"

# 1. 创建目录结构
echo ""
echo "[1/5] 创建目录结构..."
mkdir -p $PROJECT_ROOT/{_vendor,rtl/{ecc,sparse,axi},tb,uvm/{env,tests},sim/{vcs,logs,waveforms},syn/{scripts,reports},model,doc,logs/claude_sessions}

# 2. 下载依赖 (如果还没有)
echo ""
echo "[2/5] 检查依赖..."
cd $PROJECT_ROOT/_vendor

if [ ! -d "tiny-tpu-v2" ]; then
    echo "   下载 tiny-tpu-v2..."
    git clone https://github.com/tiny-tpu-v2/tiny-tpu.git tiny-tpu-v2
else
    echo "   tiny-tpu-v2 已存在"
fi

if [ ! -d "verilog-axi" ]; then
    echo "   下载 verilog-axi..."
    git clone https://github.com/alexforencich/verilog-axi.git verilog-axi
else
    echo "   verilog-axi 已存在"
fi

# 3. 创建环境脚本
echo ""
echo "[3/5] 创建环境脚本..."
cat > $PROJECT_ROOT/env_setup.sh << 'EOF'
#!/bin/bash
export LM_LICENSE_FILE=27000@localhost.localdomain:/home/jjt/install/cadence/cadence.dat:/home/jjt/install/mentor/license/license.dat
export VCS_HOME=/home/jjt/install/synopsys/vcs/vcs/T-2022.06
export VERDI_HOME=/home/jjt/install/synopsys/verdi/verdi/T-2022.06
export DC_HOME=/home/jjt/install/synopsys/dc/syn/T-2022.03-SP2
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$DC_HOME/bin:$PATH
export TITAN_TPU_ROOT=/home/jjt/Titan_TPU_V2
echo "✅ Titan-TPU V2 环境已加载"
EOF
chmod +x $PROJECT_ROOT/env_setup.sh

# 4. 创建 Makefile
echo ""
echo "[4/5] 创建 Makefile..."
cat > $PROJECT_ROOT/sim/vcs/Makefile << 'EOF'
VCS = vcs
SRC = /home/jjt/Titan_TPU_V2/_vendor/tiny-tpu-v2/src
TB = /home/jjt/Titan_TPU_V2/tb
LOG = /home/jjt/Titan_TPU_V2/sim/logs
FLAGS = -full64 -sverilog -debug_access+all -timescale=1ns/1ps

pe:
	@mkdir -p $(LOG)
	$(VCS) $(FLAGS) $(SRC)/fixedpoint.sv $(SRC)/pe.sv $(TB)/tb_pe.sv -o pe_sim -l $(LOG)/pe_compile.log
	./pe_sim -l $(LOG)/pe_sim.log

clean:
	rm -rf *_sim *.daidir csrc *.log simv*
EOF

# 5. 创建基础 testbench
echo ""
echo "[5/5] 创建 testbench..."
cat > $PROJECT_ROOT/tb/tb_pe.sv << 'EOF'
`timescale 1ns/1ps
module tb_pe;
    logic clk, rst;
    logic signed [15:0] pe_psum_in, pe_weight_in, pe_input_in;
    logic pe_accept_w_in, pe_valid_in, pe_switch_in, pe_enabled;
    logic signed [15:0] pe_psum_out, pe_weight_out, pe_input_out;
    logic pe_valid_out, pe_switch_out;

    pe #(.DATA_WIDTH(16)) dut (.*);

    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        $display("🧪 PE Testbench");
        rst = 1; pe_enabled = 0;
        {pe_psum_in, pe_weight_in, pe_input_in} = '0;
        {pe_accept_w_in, pe_valid_in, pe_switch_in} = '0;
        
        repeat(5) @(posedge clk);
        rst = 0; pe_enabled = 1;
        @(posedge clk);

        // 加载权重 1.0
        pe_weight_in = 16'h0100;
        pe_accept_w_in = 1;
        @(posedge clk);
        pe_accept_w_in = 0;
        
        // 切换
        pe_switch_in = 1;
        @(posedge clk);
        pe_switch_in = 0;
        @(posedge clk);

        // MAC: 1.0 * 2.0 + 0 = 2.0
        pe_input_in = 16'h0200;
        pe_psum_in = 16'h0000;
        pe_valid_in = 1;
        @(posedge clk);
        pe_valid_in = 0;
        repeat(2) @(posedge clk);
        
        if (pe_psum_out == 16'h0200)
            $display("✅ PASS!");
        else
            $display("❌ FAIL: got %h", pe_psum_out);

        #100; $finish;
    end
endmodule
EOF

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "✅ 安装完成!"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo "下一步:"
echo "  cd $PROJECT_ROOT"
echo "  source env_setup.sh"
echo "  cd sim/vcs"
echo "  make pe"
echo ""
echo "═══════════════════════════════════════════════════════════════════"
```

**使用方法:**
```bash
chmod +x setup_titan_tpu.sh
./setup_titan_tpu.sh
```

---

## 📋 Bash 别名配置

添加到 `~/.bashrc`:

```bash
# ═══════════════════════════════════════════════════════════════════════════════
# Titan-TPU V2 快捷命令
# ═══════════════════════════════════════════════════════════════════════════════

# 环境
alias tpu-env='cd /home/jjt/Titan_TPU_V2 && source venv/bin/activate && source env_setup.sh'

# Claude Debug
alias claude-debug='python /home/jjt/Titan_TPU_V2/claude_debug.py debug'
alias claude-review='python /home/jjt/Titan_TPU_V2/claude_debug.py review'
alias claude-explain='python /home/jjt/Titan_TPU_V2/claude_debug.py explain'
alias claude-design='python /home/jjt/Titan_TPU_V2/claude_debug.py design'
alias claude-ask='python /home/jjt/Titan_TPU_V2/claude_debug.py ask'

# 仿真
alias tpu-pe='cd /home/jjt/Titan_TPU_V2/sim/vcs && make pe'
alias tpu-clean='cd /home/jjt/Titan_TPU_V2/sim/vcs && make clean'

# 跳转
alias tpu-src='cd /home/jjt/Titan_TPU_V2/_vendor/tiny-tpu-v2/src'
alias tpu-tb='cd /home/jjt/Titan_TPU_V2/tb'
```

---

*文档版本: v1.0 | 更新时间: 2025-01-16*
