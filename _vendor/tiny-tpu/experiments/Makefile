VCS          ?= vcs
VERDI_HOME   ?= /home/jjt/install/synopsys/verdi/verdi/T-2022.06

MAKEFILE_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ROOT_DIR     := $(abspath $(MAKEFILE_DIR)/..)
SRC_DIR      := $(ROOT_DIR)/src
EXP_DIR      := $(MAKEFILE_DIR)
BUILD_DIR    := $(EXP_DIR)/out/build
LOG_DIR      := $(EXP_DIR)/out/logs
WAVE_DIR     := $(EXP_DIR)/out/waves

VCS_BASE_FLAGS = \
	-full64 \
	-sverilog \
	-timescale=1ns/1ps \
	-notice \
	-line \
	+v2k

VCS_DEBUG_FLAGS = \
	-debug_access+all \
	-kdb \
	-P $(VERDI_HOME)/share/PLI/VCS/LINUX64/novas.tab \
	$(VERDI_HOME)/share/PLI/VCS/LINUX64/pli.a

VCS_WARN_FLAGS = \
	+warn=all

VCS_FLAGS = $(VCS_BASE_FLAGS) $(VCS_DEBUG_FLAGS) $(VCS_WARN_FLAGS)
RUN_FLAGS =

PIPELINE_SIMV  = $(BUILD_DIR)/pipeline_unit_simv
HANDSHAKE_SIMV = $(BUILD_DIR)/handshake_unit_simv
HANDSHAKE_RANDOM_SIMV = $(BUILD_DIR)/handshake_random_unit_simv
OVERFLOW_SIMV  = $(BUILD_DIR)/overflow_unit_simv

PIPELINE_MDIR  = $(BUILD_DIR)/pipeline_unit_simv.daidir/csrc
HANDSHAKE_MDIR = $(BUILD_DIR)/handshake_unit_simv.daidir/csrc
HANDSHAKE_RANDOM_MDIR = $(BUILD_DIR)/handshake_random_unit_simv.daidir/csrc
OVERFLOW_MDIR  = $(BUILD_DIR)/overflow_unit_simv.daidir/csrc

PIPELINE_SRCS = \
	$(SRC_DIR)/pipeline_exp/vpu_ub_pipe_stage.sv \
	$(EXP_DIR)/pipeline/tb_vpu_ub_pipe_stage.sv

HANDSHAKE_SRCS = \
	$(SRC_DIR)/handshake_exp/vpu_ub_skid_stage.sv \
	$(EXP_DIR)/handshake/tb_vpu_ub_skid_stage.sv

HANDSHAKE_RANDOM_SRCS = \
	$(SRC_DIR)/handshake_exp/vpu_ub_skid_stage.sv \
	$(EXP_DIR)/handshake/tb_vpu_ub_skid_stage_random.sv

OVERFLOW_SRCS = \
	$(SRC_DIR)/fixedpoint.sv \
	$(EXP_DIR)/overflow/tb_q8_8_saturation.sv

.PHONY: dirs pipeline_unit handshake_unit handshake_random_unit overflow_unit clean

dirs:
	mkdir -p $(BUILD_DIR) $(LOG_DIR) $(WAVE_DIR)

pipeline_unit: dirs
	$(VCS) $(VCS_FLAGS) -Mdir=$(PIPELINE_MDIR) -o $(PIPELINE_SIMV) -l $(LOG_DIR)/pipeline_compile.log $(PIPELINE_SRCS)
	cd $(BUILD_DIR) && ./$(notdir $(PIPELINE_SIMV)) $(RUN_FLAGS) -l $(LOG_DIR)/pipeline_run.log

handshake_unit: dirs
	$(VCS) $(VCS_FLAGS) -Mdir=$(HANDSHAKE_MDIR) -o $(HANDSHAKE_SIMV) -l $(LOG_DIR)/handshake_compile.log $(HANDSHAKE_SRCS)
	cd $(BUILD_DIR) && ./$(notdir $(HANDSHAKE_SIMV)) $(RUN_FLAGS) -l $(LOG_DIR)/handshake_run.log

handshake_random_unit: dirs
	$(VCS) $(VCS_FLAGS) -Mdir=$(HANDSHAKE_RANDOM_MDIR) -o $(HANDSHAKE_RANDOM_SIMV) -l $(LOG_DIR)/handshake_random_compile.log $(HANDSHAKE_RANDOM_SRCS)
	cd $(BUILD_DIR) && ./$(notdir $(HANDSHAKE_RANDOM_SIMV)) $(RUN_FLAGS) -l $(LOG_DIR)/handshake_random_run.log

overflow_unit: dirs
	$(VCS) $(VCS_FLAGS) -Mdir=$(OVERFLOW_MDIR) -o $(OVERFLOW_SIMV) -l $(LOG_DIR)/overflow_compile.log $(OVERFLOW_SRCS)
	cd $(BUILD_DIR) && ./$(notdir $(OVERFLOW_SIMV)) $(RUN_FLAGS) -l $(LOG_DIR)/overflow_run.log

AXI_SIMV      = $(BUILD_DIR)/tpu_soc_axil_simv
AXI_MDIR      = $(BUILD_DIR)/tpu_soc_axil_simv.daidir/csrc

AXI_SRCS = \
	$(ROOT_DIR)/src_axi/fixedpoint.sv \
	$(ROOT_DIR)/src_axi/pe.sv \
	$(ROOT_DIR)/src_axi/leaky_relu_child.sv \
	$(ROOT_DIR)/src_axi/leaky_relu_parent.sv \
	$(ROOT_DIR)/src_axi/leaky_relu_derivative_child.sv \
	$(ROOT_DIR)/src_axi/leaky_relu_derivative_parent.sv \
	$(ROOT_DIR)/src_axi/systolic.sv \
	$(ROOT_DIR)/src_axi/bias_child.sv \
	$(ROOT_DIR)/src_axi/bias_parent.sv \
	$(ROOT_DIR)/src_axi/control_unit.sv \
	$(ROOT_DIR)/src_axi/vpu.sv \
	$(ROOT_DIR)/src_axi/loss_parent.sv \
	$(ROOT_DIR)/src_axi/loss_child.sv \
	$(ROOT_DIR)/src_axi/gradient_descent.sv \
	$(ROOT_DIR)/src_axi/unified_buffer_v3.sv \
	$(ROOT_DIR)/src_axi/tpu.sv \
	$(ROOT_DIR)/src_axi/tpu_frontend_axil.sv \
	$(ROOT_DIR)/src_axi/tpu_soc.sv \
	$(ROOT_DIR)/test/tb_tpu_soc_axil.sv

tpu_soc_axil: dirs
	$(VCS) $(VCS_FLAGS) -Mdir=$(AXI_MDIR) -o $(AXI_SIMV) -l $(LOG_DIR)/tpu_soc_axil_compile.log $(AXI_SRCS)
	cd $(BUILD_DIR) && ./$(notdir $(AXI_SIMV)) $(RUN_FLAGS) -l $(LOG_DIR)/tpu_soc_axil_run.log

clean:
	rm -rf $(EXP_DIR)/out
