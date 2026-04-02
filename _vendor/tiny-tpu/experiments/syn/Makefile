DC_SHELL ?= dc_shell

EXP_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

.PHONY: baseline_freq pipeline_freq clean

baseline_freq:
	$(DC_SHELL) -x "source $(EXP_DIR)/run_baseline.tcl"

pipeline_freq:
	$(DC_SHELL) -x "source $(EXP_DIR)/run_pipeline.tcl"

clean:
	rm -rf $(EXP_DIR)/out
