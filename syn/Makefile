# Makefile for DC Synthesis
# SMIC 180nm PDK

DC_SHELL = /home/jjt/install/synopsys/dc/syn/T-2022.03-SP2/bin/dc_shell-xg-t
DESIGN = tpu
SCRIPT = dc_script.tcl

# Directories
REPORTS_DIR = reports
OUTPUTS_DIR = outputs
LOGS_DIR = logs

.PHONY: all clean syn check_env sweep_freq

all: check_env syn

check_env:
	@echo "Checking environment..."
	@which $(DC_SHELL) > /dev/null || (echo "Error: dc_shell not found in PATH"; exit 1)
	@echo "DC shell found: $$(which $(DC_SHELL))"

syn: check_env
	@echo "Starting synthesis..."
	@mkdir -p $(REPORTS_DIR) $(OUTPUTS_DIR) $(LOGS_DIR)
	$(DC_SHELL) -f $(SCRIPT) | tee $(LOGS_DIR)/dc_synthesis.log
	@echo ""
	@echo "==================================================================="
	@echo "Synthesis Complete!"
	@echo "==================================================================="
	@echo "Check the following files:"
	@echo "  - Timing report: $(REPORTS_DIR)/timing.rpt"
	@echo "  - Area report:   $(REPORTS_DIR)/area.rpt"
	@echo "  - QoR report:    $(REPORTS_DIR)/qor.rpt"
	@echo "  - Netlist:       $(OUTPUTS_DIR)/$(DESIGN)_syn.v"
	@echo "==================================================================="
	@echo ""
	@echo "Quick timing summary:"
	@grep -A 5 "Timing Path Group" $(REPORTS_DIR)/qor.rpt || true
	@echo ""
	@echo "Frequency achieved:"
	@grep -E "clock.*\(MHz\)" $(REPORTS_DIR)/qor.rpt || grep "clock" $(REPORTS_DIR)/timing.rpt | head -5 || true

# Frequency sweep - test different clock periods
sweep_freq:
	@echo "Running frequency sweep..."
	@for period in 20 15 10 8 6 5 4 3 2; do \
		echo ""; \
		echo "================================================================="; \
		echo "Testing clock period: $$period ns ($$((1000/period)) MHz)"; \
		echo "================================================================="; \
		sed -i.bak "s/set CLK_PERIOD .*/set CLK_PERIOD $$period.0/" constraints.sdc; \
		$(MAKE) syn 2>&1 | tee $(LOGS_DIR)/sweep_$${period}ns.log; \
		if grep -q "VIOLATED" $(REPORTS_DIR)/timing.rpt; then \
			echo "TIMING VIOLATION at $$period ns"; \
			echo "Maximum frequency is approximately $$((1000/period)) MHz"; \
			break; \
		else \
			echo "TIMING MET at $$period ns ($$((1000/period)) MHz)"; \
		fi; \
	done
	@mv constraints.sdc.bak constraints.sdc

# View reports
view_timing:
	@less $(REPORTS_DIR)/timing.rpt

view_area:
	@less $(REPORTS_DIR)/area.rpt

view_qor:
	@less $(REPORTS_DIR)/qor.rpt

view_power:
	@less $(REPORTS_DIR)/power.rpt

# Clean generated files
clean:
	rm -rf $(REPORTS_DIR) $(OUTPUTS_DIR) $(LOGS_DIR)
	rm -rf work alib* *.log *.svf *.pvl command.log
	rm -rf *.mr *.syn *.ddc

help:
	@echo "Makefile for DC Synthesis"
	@echo ""
	@echo "Targets:"
	@echo "  make syn         - Run synthesis with current constraints"
	@echo "  make sweep_freq  - Test multiple frequencies to find max"
	@echo "  make view_timing - View timing report"
	@echo "  make view_area   - View area report"
	@echo "  make view_qor    - View QoR summary"
	@echo "  make clean       - Remove generated files"
	@echo ""
	@echo "To modify target frequency:"
	@echo "  Edit constraints.sdc and change CLK_PERIOD value"
