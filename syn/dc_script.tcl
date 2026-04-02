#!/bin/tcsh -f
#==============================================================================
# Design Compiler Synthesis Script for tiny-tpu
# PDK: SMIC 180nm (sc-m standard cell library)
#==============================================================================

# Set design name (TPU top-level: unified_buffer + systolic + vpu)
set DESIGN_NAME "tpu"
set SYSTOLIC_WIDTH 2

#==============================================================================
# SMIC 180nm Library Setup
#==============================================================================
# PDK paths
set SMIC180_SC_PATH "/home/jjt/pdk/smic180/SC/aci/sc-m/synopsys"
set SMIC180_IO_PATH "/home/jjt/pdk/smic180/IO/SP018W_V1p8a/syn"

# Process corner selection
# Options: tt_1v8_25c (typical), ff_1v98_0c (fast), ss_1v62_125c (slow)
set CORNER "tt_1v8_25c"

# Set search path
set_app_var search_path [list . \
                             ${SMIC180_SC_PATH} \
                             ${SMIC180_IO_PATH}]

# Target library (standard cells + IO)
set_app_var target_library [list ${CORNER}.db \
                                 SP018W_V1p8_typ.db]

# Link library
set_app_var link_library [concat "*" $target_library]

puts "=========================================================================="
puts "SMIC 180nm PDK Configuration"
puts "=========================================================================="
puts "Standard Cell Library: ${CORNER}.db"
puts "IO Library: SP018W_V1p8_typ.db"
puts "Process Corner: ${CORNER}"
puts "=========================================================================="

# Enable SystemVerilog support
set_app_var hdlin_enable_vpp true
set_app_var hdlin_auto_save_templates true
set_app_var hdlin_check_no_latch true

#==============================================================================
# Read and Elaborate Design
#==============================================================================
puts "Reading RTL files..."
analyze -format sverilog -vcs "-f filelist.f"

puts "Elaborating design..."
elaborate ${DESIGN_NAME} -parameters "SYSTOLIC_ARRAY_WIDTH=${SYSTOLIC_WIDTH}"

puts "Linking design..."
current_design ${DESIGN_NAME}
link

# Create output directories
file mkdir reports
file mkdir outputs

# Check design
puts "Checking design..."
check_design > reports/check_design.rpt
uniquify

#==============================================================================
# Apply Constraints
#==============================================================================
puts "Reading constraints..."
source -echo -verbose constraints.sdc

#==============================================================================
# Compile Design
#==============================================================================
puts "Compiling design (compile_ultra)..."
compile_ultra -gate_clock -no_autoungroup

# Incremental optimization
puts "Running incremental optimization..."
compile_ultra -incremental -gate_clock

#==============================================================================
# Generate Reports
#==============================================================================
puts "Generating reports..."

report_timing -transition_time -nets -attributes -nosplit -max_paths 10 \
    > reports/timing.rpt
report_timing -delay min -max_paths 10 > reports/timing_hold.rpt
report_area -hierarchy > reports/area.rpt
report_power -hierarchy > reports/power.rpt
report_qor > reports/qor.rpt
report_constraint -all_violators > reports/constraints_violators.rpt
report_clock_gating -gating_elements > reports/clock_gating.rpt
report_resources -hierarchy > reports/resources.rpt

#==============================================================================
# Write Outputs
#==============================================================================
puts "Writing netlist and constraints..."
change_names -rules verilog -hierarchy
write -format verilog -hierarchy -output outputs/${DESIGN_NAME}_syn.v
write -format ddc -hierarchy -output outputs/${DESIGN_NAME}_syn.ddc
write_sdc outputs/${DESIGN_NAME}_syn.sdc
write_sdf outputs/${DESIGN_NAME}_syn.sdf

#==============================================================================
# Print Summary
#==============================================================================
puts ""
puts "=========================================================================="
puts "Synthesis Complete! (SMIC 180nm, ${CORNER})"
puts "=========================================================================="
puts ""
puts "Quick Timing Summary:"
report_timing -nosplit -nworst 1
puts ""
puts "Quick Area Summary:"
report_area -nosplit
puts ""
puts "Reports:  syn/reports/"
puts "Netlist:  syn/outputs/${DESIGN_NAME}_syn.v"
puts "=========================================================================="

exit
