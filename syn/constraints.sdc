# SDC Constraints for tiny-tpu
# PDK: SMIC 180nm

#==============================================================================
# Clock Definition
#==============================================================================
# Target: 100MHz (10ns) as starting point for SMIC 180nm
set CLK_PERIOD 10.0
set CLK_PORT "clk"

create_clock -name sys_clk -period ${CLK_PERIOD} [get_ports ${CLK_PORT}]

# Clock uncertainty (SMIC 180nm typical values)
set_clock_uncertainty -setup 0.3 [get_clocks sys_clk]
set_clock_uncertainty -hold  0.1 [get_clocks sys_clk]

# Clock transition (180nm typical)
set_clock_transition 0.15 [get_clocks sys_clk]

#==============================================================================
# Input/Output Delays (30% of clock period)
#==============================================================================
set INPUT_DELAY  [expr ${CLK_PERIOD} * 0.3]
set OUTPUT_DELAY [expr ${CLK_PERIOD} * 0.3]

set ALL_INPUTS [remove_from_collection [all_inputs] [get_ports "${CLK_PORT} rst"]]

set_input_delay  ${INPUT_DELAY}  -clock sys_clk ${ALL_INPUTS}
set_output_delay ${OUTPUT_DELAY} -clock sys_clk [all_outputs]

#==============================================================================
# Reset
#==============================================================================
set_ideal_network [get_ports rst]
set_false_path -from [get_ports rst]

#==============================================================================
# Design Rules (SMIC 180nm)
#==============================================================================
set_max_transition 1.0 [current_design]
set_max_fanout 16 [current_design]

#==============================================================================
# Area
#==============================================================================
set_max_area 0

puts "Constraints loaded: ${CLK_PERIOD} ns ([expr 1000.0/${CLK_PERIOD}] MHz)"
