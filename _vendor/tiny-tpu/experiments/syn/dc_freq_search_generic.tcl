set SMIC180_SC_PATH "/home/jjt/pdk/smic180/SC/aci/sc-m/synopsys"
set SMIC180_IO_PATH "/home/jjt/pdk/smic180/IO/SP018W_V1p8a/syn"
set CORNER "tt_1v8_25c"
set CLK_PORT "clk"

set REPORT_DIR [file join $OUT_DIR reports]
set OUTPUT_DIR [file join $OUT_DIR outputs]
set LOG_DIR [file join $OUT_DIR logs]
set UNMAPPED_DDC [file join $OUTPUT_DIR unmapped.ddc]

file mkdir $REPORT_DIR
file mkdir [file join $REPORT_DIR freq_search]
file mkdir $OUTPUT_DIR
file mkdir $LOG_DIR

set_app_var search_path [list . $SMIC180_SC_PATH $SMIC180_IO_PATH]
set_app_var target_library [list ${CORNER}.db SP018W_V1p8_typ.db]
set_app_var link_library [concat "*" $target_library]
set_app_var hdlin_enable_vpp true
set_app_var hdlin_auto_save_templates true
set_app_var hdlin_check_no_latch true

puts "=========================================="
puts "Frequency Search - tiny-tpu local experiment"
puts "Design: $DESIGN_NAME"
puts "Filelist: $FILELIST"
puts "Out dir: $OUT_DIR"
puts "Range: [expr 1000.0/$MAX_PERIOD] - [expr 1000.0/$MIN_PERIOD] MHz"
puts "=========================================="

analyze -format sverilog -vcs "-f $FILELIST"
elaborate $DESIGN_NAME -parameters "SYSTOLIC_ARRAY_WIDTH=$SYSTOLIC_WIDTH"
current_design *
link
uniquify

set FULL_DESIGN_NAME [get_object_name [current_design]]
puts "Design name after elaborate: $FULL_DESIGN_NAME"
write -format ddc -hierarchy -output $UNMAPPED_DDC

proc apply_constraints {period max_area clk_port} {
    set input_delay  [expr $period * 0.3]
    set output_delay [expr $period * 0.3]

    create_clock -name sys_clk -period $period [get_ports $clk_port]
    set_clock_uncertainty -setup 0.3 [get_clocks sys_clk]
    set_clock_uncertainty -hold  0.1 [get_clocks sys_clk]
    set_clock_transition 0.15 [get_clocks sys_clk]

    set all_in [remove_from_collection [all_inputs] [get_ports "$clk_port rst"]]
    set_input_delay  $input_delay  -clock sys_clk $all_in
    set_output_delay $output_delay -clock sys_clk [all_outputs]

    set_ideal_network [get_ports rst]
    set_false_path -from [get_ports rst]

    set_max_transition 1.0 [current_design]
    set_max_fanout 16 [current_design]

    if {$max_area > 0} {
        set_max_area $max_area
    }
}

proc get_qor_results {} {
    redirect -variable qor_rpt {report_qor}

    set wns -999.0
    set area -1.0

    if {[regexp {Design\s+WNS:\s+([-\d.]+)} $qor_rpt -> val]} {
        set wns [expr -1.0 * $val]
    }

    if {[regexp {Design Area:\s+([\d.]+)} $qor_rpt -> val]} {
        set area $val
    } elseif {[regexp {Cell Area:\s+([\d.]+)} $qor_rpt -> val]} {
        set area $val
    }

    return [list $wns $area]
}

set low  $MIN_PERIOD
set high $MAX_PERIOD
set best_period $MAX_PERIOD
set iteration 0

set log_lines [list]
lappend log_lines "Iter | Period(ns) | Freq(MHz) |  WNS(ns) |    Area    | Status"
lappend log_lines "-----|------------|-----------|----------|------------|-------"

while {[expr $high - $low] > $TOLERANCE} {
    incr iteration
    set mid [expr ($low + $high) / 2.0]
    set freq [expr 1000.0 / $mid]

    puts ""
    puts "============================================================"
    puts "Iter $iteration: [format %.2f $freq] MHz ([format %.2f $mid] ns)"
    puts "Range: [format %.2f $low] - [format %.2f $high] ns"
    puts "============================================================"

    remove_design -all
    read_ddc $UNMAPPED_DDC
    current_design $FULL_DESIGN_NAME
    link

    apply_constraints $mid $MAX_AREA $CLK_PORT
    compile_ultra -gate_clock -no_autoungroup

    set results [get_qor_results]
    set wns  [lindex $results 0]
    set area [lindex $results 1]

    puts ""
    puts ">>> WNS=[format %.3f $wns] Area=[format %.0f $area]"

    if {$wns >= 0} {
        set best_period $mid
        set high $mid
        set status "PASS"
        puts ">>> PASS -> try higher freq"
    } else {
        set low $mid
        set status "FAIL"
        puts ">>> FAIL -> try lower freq"
    }

    lappend log_lines [format "%4d | %10.2f | %9.2f | %8.3f | %10.0f | %s" \
        $iteration $mid $freq $wns $area $status]

    report_qor > [file join $REPORT_DIR freq_search qor_iter${iteration}_[format %.1f $mid]ns.rpt]
}

set final_freq [expr 1000.0 / $best_period]

puts ""
puts "=========================================="
puts "Search done! Max: [format %.2f $final_freq] MHz ([format %.2f $best_period] ns)"
puts "Final synthesis..."
puts "=========================================="

remove_design -all
read_ddc $UNMAPPED_DDC
current_design $FULL_DESIGN_NAME
link

apply_constraints $best_period $MAX_AREA $CLK_PORT
compile_ultra -gate_clock -no_autoungroup
compile_ultra -incremental -gate_clock

report_timing -transition_time -nets -attributes -nosplit -max_paths 10 \
    > [file join $REPORT_DIR freq_search timing_final.rpt]
report_timing -delay min -max_paths 10 \
    > [file join $REPORT_DIR freq_search timing_hold_final.rpt]
report_area -hierarchy > [file join $REPORT_DIR freq_search area_final.rpt]
report_power -hierarchy > [file join $REPORT_DIR freq_search power_final.rpt]
report_qor > [file join $REPORT_DIR freq_search qor_final.rpt]
report_constraint -all_violators \
    > [file join $REPORT_DIR freq_search constraints_violators_final.rpt]
report_clock_gating -gating_elements > [file join $REPORT_DIR clock_gating_final.rpt]

change_names -rules verilog -hierarchy
write -format verilog -hierarchy -output [file join $OUTPUT_DIR ${DESIGN_NAME}_maxfreq_syn.v]
write -format ddc -hierarchy -output [file join $OUTPUT_DIR ${DESIGN_NAME}_maxfreq_syn.ddc]
write_sdc [file join $OUTPUT_DIR ${DESIGN_NAME}_maxfreq_syn.sdc]
write_sdf [file join $OUTPUT_DIR ${DESIGN_NAME}_maxfreq_syn.sdf]

set summary_fp [open [file join $OUT_DIR summary.txt] w]
puts $summary_fp "Design: $DESIGN_NAME"
puts $summary_fp "Top: [get_object_name [current_design]]"
puts $summary_fp "Best period (ns): [format %.2f $best_period]"
puts $summary_fp "Max frequency (MHz): [format %.2f $final_freq]"
foreach line $log_lines {
    puts $summary_fp $line
}
close $summary_fp

puts ""
puts "=========================================="
puts "FREQUENCY SEARCH RESULTS"
puts "=========================================="
puts "Max Frequency: [format %.2f $final_freq] MHz"
puts "Clock Period:  [format %.2f $best_period] ns"
puts "Iterations:    $iteration"
puts ""
puts "Final Timing:"
report_timing -nosplit -nworst 1
puts ""
puts "Final Area:"
report_area -nosplit
puts ""
puts "Reports: $REPORT_DIR/freq_search"
puts "Outputs: $OUTPUT_DIR"
puts "=========================================="

file delete -force $UNMAPPED_DDC
exit
