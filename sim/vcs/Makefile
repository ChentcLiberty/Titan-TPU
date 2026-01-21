# ═══════════════════════════════════════════════════════════════════════════════
# Titan-TPU V2 - VCS Professional Makefile
# Author: Chen Weidong
# Date: 2026-01-20
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# 工具配置
# ═══════════════════════════════════════════════════════════════════════════════
VCS     = vcs
SIMV    = ./simv
VERDI   = verdi

# ═══════════════════════════════════════════════════════════════════════════════
# 目录配置（使用相对路径）
# ═══════════════════════════════════════════════════════════════════════════════
ROOT_DIR    = ../..
SRC_DIR     = $(ROOT_DIR)/_vendor/tiny-tpu/src
TB_DIR      = $(ROOT_DIR)/tb
BUILD_DIR   = ./build
LOG_DIR     = ./logs
WAVE_DIR    = ../waveforms
COV_DIR     = ./coverage

# ═══════════════════════════════════════════════════════════════════════════════
# 编译选项
# ═══════════════════════════════════════════════════════════════════════════════

# 基础选项
VCS_BASE_FLAGS = \
	-full64 \
	-sverilog \
	-timescale=1ns/1ps \
	-notice \
	-line \
	+v2k

# Debug 选项（用于 Verdi 调试）
VCS_DEBUG_FLAGS = \
	-debug_access+all \
	-debug_region+cell+encrypt \
	-kdb \
	+vcs+fsdbon \
	+fsdb+autoflush

# 覆盖率选项
VCS_COV_FLAGS = \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir $(COV_DIR)/cm.vdb

# 性能优化选项
VCS_OPT_FLAGS = \
	-O3 \
	+rad

# 警告控制
VCS_WARN_FLAGS = \
	+warn=all \
	-error=PCWM-L

# 组合所有选项
VCS_FLAGS = $(VCS_BASE_FLAGS) $(VCS_DEBUG_FLAGS) $(VCS_WARN_FLAGS)

# 仿真选项
SIM_FLAGS = \
	-l $(LOG_DIR)/sim.log \
	+fsdb+autoflush

# ═══════════════════════════════════════════════════════════════════════════════
# 源文件列表
# ═══════════════════════════════════════════════════════════════════════════════
FXP_SRC      = $(SRC_DIR)/fixedpoint.sv
PE_SRC       = $(SRC_DIR)/pe.sv
SYSTOLIC_SRC = $(SRC_DIR)/systolic.sv
VPU_SRC      = $(SRC_DIR)/vpu.sv
BUFFER_SRC   = $(SRC_DIR)/unified_buffer.sv
CTRL_SRC     = $(SRC_DIR)/control_unit.sv
TPU_SRC      = $(SRC_DIR)/tpu.sv

# ═══════════════════════════════════════════════════════════════════════════════
# 目标定义
# ═══════════════════════════════════════════════════════════════════════════════

.PHONY: all clean help dirs pe systolic check verdi cov regression report

# 默认目标
all: help

# 创建必要的目录
dirs:
	@mkdir -p $(BUILD_DIR) $(LOG_DIR) $(WAVE_DIR) $(COV_DIR)

# ═══════════════════════════════════════════════════════════════════════════════
# PE 模块测试
# ═══════════════════════════════════════════════════════════════════════════════
pe: dirs
	@echo "═══════════════════════════════════════════════════════════════════"
	@echo "🔧 编译 PE 模块"
	@echo "═══════════════════════════════════════════════════════════════════"
	$(VCS) $(VCS_FLAGS) \
		-o $(BUILD_DIR)/pe_simv \
		-l $(LOG_DIR)/pe_compile.log \
		$(FXP_SRC) \
		$(PE_SRC) \
		$(TB_DIR)/tb_pe.sv
	@echo ""
	@echo "🚀 运行仿真..."
	@echo "═══════════════════════════════════════════════════════════════════"
	cd $(BUILD_DIR) && ./pe_simv $(SIM_FLAGS)
	@echo ""
	@echo "✅ PE 测试完成!"
	@echo "📊 日志文件: $(LOG_DIR)/sim.log"
	@echo "📈 波形文件: $(WAVE_DIR)/tb_pe.fsdb"

# ═══════════════════════════════════════════════════════════════════════════════
# Systolic Array 测试
# ═══════════════════════════════════════════════════════════════════════════════
systolic: dirs
	@echo "═══════════════════════════════════════════════════════════════════"
	@echo "🔧 编译 Systolic Array"
	@echo "═══════════════════════════════════════════════════════════════════"
	$(VCS) $(VCS_FLAGS) \
		-o $(BUILD_DIR)/systolic_simv \
		-l $(LOG_DIR)/systolic_compile.log \
		$(FXP_SRC) \
		$(PE_SRC) \
		$(SYSTOLIC_SRC) \
		$(TB_DIR)/tb_systolic.sv
	@echo ""
	@echo "🚀 运行仿真..."
	@echo "═══════════════════════════════════════════════════════════════════"
	cd $(BUILD_DIR) && ./systolic_simv $(SIM_FLAGS)
	@echo ""
	@echo "✅ Systolic Array 测试完成!"

# ═══════════════════════════════════════════════════════════════════════════════
# 语法检查（快速检查，不生成可执行文件）
# ═══════════════════════════════════════════════════════════════════════════════
check: dirs
	@echo "🔍 语法检查..."
	$(VCS) -q $(VCS_BASE_FLAGS) \
		-parse_only \
		$(FXP_SRC) \
		$(PE_SRC) \
		2>&1 | tee $(LOG_DIR)/check.log
	@echo "✅ 语法检查完成"

# ═══════════════════════════════════════════════════════════════════════════════
# Verdi 波形查看
# ═══════════════════════════════════════════════════════════════════════════════
verdi:
	@if [ -f $(WAVE_DIR)/*.fsdb ]; then \
		echo "🔍 打开 Verdi..."; \
		$(VERDI) -ssf $(WAVE_DIR)/*.fsdb -nologo & \
	else \
		echo "❌ 未找到波形文件: $(WAVE_DIR)/*.fsdb"; \
		echo "💡 请先运行: make pe"; \
	fi

# ═══════════════════════════════════════════════════════════════════════════════
# 覆盖率收集（高级功能）
# ═══════════════════════════════════════════════════════════════════════════════
cov: dirs
	@echo "📊 编译并收集覆盖率..."
	$(VCS) $(VCS_FLAGS) $(VCS_COV_FLAGS) \
		-o $(BUILD_DIR)/pe_cov_simv \
		-l $(LOG_DIR)/pe_cov_compile.log \
		$(FXP_SRC) \
		$(PE_SRC) \
		$(TB_DIR)/tb_pe.sv
	cd $(BUILD_DIR) && ./pe_cov_simv $(SIM_FLAGS) -cm line+cond+fsm+tgl+branch
	@echo "✅ 覆盖率收集完成: $(COV_DIR)/cm.vdb"

# ═══════════════════════════════════════════════════════════════════════════════
# 回归测试（CI/CD 核心功能）
# ═══════════════════════════════════════════════════════════════════════════════
regression: dirs
	@echo "═══════════════════════════════════════════════════════════════════"
	@echo "🚀 开始回归测试（Regression Test）"
	@echo "═══════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "📋 测试列表:"
	@echo "  1. PE 模块测试"
	@echo "  2. PE 覆盖率测试"
	@echo ""
	@# 初始化测试结果文件
	@echo "# Regression Test Results" > $(LOG_DIR)/regression_summary.txt
	@echo "# Date: $$(date)" >> $(LOG_DIR)/regression_summary.txt
	@echo "" >> $(LOG_DIR)/regression_summary.txt
	@# 运行 PE 测试
	@echo "───────────────────────────────────────────────────────────────────"
	@echo "[1/2] 运行 PE 模块测试..."
	@echo "───────────────────────────────────────────────────────────────────"
	@if $(MAKE) pe > $(LOG_DIR)/regression_pe.log 2>&1; then \
		echo "✅ PE 测试通过" | tee -a $(LOG_DIR)/regression_summary.txt; \
		echo "PASS" > $(LOG_DIR)/pe_result.txt; \
	else \
		echo "❌ PE 测试失败" | tee -a $(LOG_DIR)/regression_summary.txt; \
		echo "FAIL" > $(LOG_DIR)/pe_result.txt; \
	fi
	@echo ""
	@# 运行覆盖率测试
	@echo "───────────────────────────────────────────────────────────────────"
	@echo "[2/2] 运行覆盖率收集..."
	@echo "───────────────────────────────────────────────────────────────────"
	@if $(MAKE) cov > $(LOG_DIR)/regression_cov.log 2>&1; then \
		echo "✅ 覆盖率收集成功" | tee -a $(LOG_DIR)/regression_summary.txt; \
		echo "PASS" > $(LOG_DIR)/cov_result.txt; \
	else \
		echo "❌ 覆盖率收集失败" | tee -a $(LOG_DIR)/regression_summary.txt; \
		echo "FAIL" > $(LOG_DIR)/cov_result.txt; \
	fi
	@echo ""
	@# 生成覆盖率报告
	@$(MAKE) report
	@# 统计结果
	@echo "═══════════════════════════════════════════════════════════════════"
	@echo "📊 回归测试总结"
	@echo "═══════════════════════════════════════════════════════════════════"
	@cat $(LOG_DIR)/regression_summary.txt
	@echo ""
	@# 检查是否所有测试都通过
	@if grep -q "FAIL" $(LOG_DIR)/*_result.txt; then \
		echo "❌ 回归测试失败 - 有测试未通过"; \
		echo ""; \
		echo "📋 详细日志:"; \
		echo "  - $(LOG_DIR)/regression_pe.log"; \
		echo "  - $(LOG_DIR)/regression_cov.log"; \
		echo ""; \
		exit 1; \
	else \
		echo "✅ 所有测试通过!"; \
		echo ""; \
		echo "📊 覆盖率报告: $(COV_DIR)/urgReport/dashboard.html"; \
		echo ""; \
		exit 0; \
	fi

# ═══════════════════════════════════════════════════════════════════════════════
# 生成覆盖率报告（使用 urg 工具）
# ═══════════════════════════════════════════════════════════════════════════════
report:
	@echo "📈 生成覆盖率报告..."
	@if [ -d $(COV_DIR)/cm.vdb ]; then \
		urg -dir $(COV_DIR)/cm.vdb \
			-report $(COV_DIR)/urgReport \
			-format both \
			> $(LOG_DIR)/urg.log 2>&1; \
		echo "✅ 覆盖率报告已生成: $(COV_DIR)/urgReport/dashboard.html"; \
	else \
		echo "⚠️  未找到覆盖率数据库，请先运行: make cov"; \
	fi

# ═══════════════════════════════════════════════════════════════════════════════
# 清理
# ═══════════════════════════════════════════════════════════════════════════════
clean:
	@echo "🧹 清理编译产物..."
	rm -rf $(BUILD_DIR)/* $(LOG_DIR)/* $(WAVE_DIR)/* $(COV_DIR)/*
	rm -rf csrc *.daidir *.log *.key simv* ucli.key DVEfiles inter.vpd
	@echo "✅ 清理完成"

# ═══════════════════════════════════════════════════════════════════════════════
# 帮助信息
# ═══════════════════════════════════════════════════════════════════════════════
help:
	@echo "═══════════════════════════════════════════════════════════════════"
	@echo "🚀 Titan-TPU V2 - VCS Professional Makefile"
	@echo "═══════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "📋 基础命令:"
	@echo "  make pe         - PE 模块测试（生成 FSDB 波形）"
	@echo "  make systolic   - Systolic Array 测试"
	@echo "  make check      - 快速语法检查"
	@echo "  make verdi      - 打开 Verdi 查看波形"
	@echo "  make clean      - 清理所有编译产物"
	@echo ""
	@echo "📊 高级命令:"
	@echo "  make cov        - 收集代码覆盖率"
	@echo "  make report     - 生成覆盖率报告（HTML）"
	@echo "  make regression - 🔥 回归测试（CI/CD 核心）"
	@echo ""
	@echo "═══════════════════════════════════════════════════════════════════"
	@echo "📂 目录结构:"
	@echo "  源码:   $(SRC_DIR)"
	@echo "  测试:   $(TB_DIR)"
	@echo "  构建:   $(BUILD_DIR)"
	@echo "  日志:   $(LOG_DIR)"
	@echo "  波形:   $(WAVE_DIR)"
	@echo "  覆盖率: $(COV_DIR)"
	@echo "═══════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "💡 快速开始:"
	@echo "  1. make pe         # 运行 PE 测试"
	@echo "  2. make verdi      # 查看波形"
	@echo "  3. make regression # 运行回归测试（推荐）"
	@echo ""
	@echo "🎯 CI/CD 流程:"
	@echo "  git commit → make regression → 检查返回码 → 生成报告"
	@echo ""
