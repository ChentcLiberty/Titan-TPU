debLoadSimResult /home/jjt/TitanTPU/sim/waveforms/tb_unified_buffer.fsdb
wvCreateWindow
wvSetPosition -win $_nWave2 {("G1" 0)}
wvOpenFile -win $_nWave2 {/home/jjt/TitanTPU/sim/waveforms/tb_unified_buffer.fsdb}
wvGetSignalSetScope -win $_nWave2 "/tb_unified_buffer"
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"1.Clock_Reset" \
{/tb_unified_buffer/clk} \
{/tb_unified_buffer/rst} \
}
wvAddSignal -win $_nWave2 -group {"2.Test_Stats" \
{/tb_unified_buffer/test_count\[31:0\]} \
{/tb_unified_buffer/pass_count\[31:0\]} \
{/tb_unified_buffer/fail_count\[31:0\]} \
}
wvAddSignal -win $_nWave2 -group {"3.Host_Write" \
{/tb_unified_buffer/ub_wr_host_data_in\[0\]\[15:0\]} \
{/tb_unified_buffer/ub_wr_host_data_in\[1\]\[15:0\]} \
{/tb_unified_buffer/ub_wr_host_valid_in\[0\]} \
{/tb_unified_buffer/ub_wr_host_valid_in\[1\]} \
}
wvAddSignal -win $_nWave2 -group {"4.Read_Control" \
{/tb_unified_buffer/ub_rd_start_in} \
{/tb_unified_buffer/ub_ptr_select\[8:0\]} \
{/tb_unified_buffer/ub_rd_addr_in\[15:0\]} \
{/tb_unified_buffer/ub_rd_row_size\[15:0\]} \
{/tb_unified_buffer/ub_rd_col_size\[15:0\]} \
{/tb_unified_buffer/ub_rd_transpose} \
}
wvAddSignal -win $_nWave2 -group {"5.Memory_CRITICAL" \
{/tb_unified_buffer/dut/ub_memory\[0\]\[15:0\]} \
{/tb_unified_buffer/dut/ub_memory\[1\]\[15:0\]} \
{/tb_unified_buffer/dut/ub_memory\[2\]\[15:0\]} \
{/tb_unified_buffer/dut/ub_memory\[3\]\[15:0\]} \
{/tb_unified_buffer/dut/wr_ptr\[15:0\]} \
}
wvAddSignal -win $_nWave2 -group {"6.Weight_Output_Test1" \
{/tb_unified_buffer/ub_rd_weight_data_out_0\[15:0\]} \
{/tb_unified_buffer/ub_rd_weight_data_out_1\[15:0\]} \
{/tb_unified_buffer/ub_rd_weight_valid_out_0} \
{/tb_unified_buffer/ub_rd_weight_valid_out_1} \
}
wvAddSignal -win $_nWave2 -group {"7.Input_Output_Test2_3" \
{/tb_unified_buffer/ub_rd_input_data_out_0\[15:0\]} \
{/tb_unified_buffer/ub_rd_input_data_out_1\[15:0\]} \
{/tb_unified_buffer/ub_rd_input_valid_out_0} \
{/tb_unified_buffer/ub_rd_input_valid_out_1} \
}
wvAddSignal -win $_nWave2 -group {"8.Internal_FSM" \
{/tb_unified_buffer/dut/rd_input_ptr\[15:0\]} \
{/tb_unified_buffer/dut/rd_input_time_counter\[15:0\]} \
{/tb_unified_buffer/dut/rd_weight_ptr\[15:0\]} \
{/tb_unified_buffer/dut/rd_weight_time_counter\[15:0\]} \
}
wvAddSignal -win $_nWave2 -group {"G9" \
}
wvSetPosition -win $_nWave2 {("G9" 0)}
wvSetRadix -win $_nWave2 -format Hex
wvZoomAll -win $_nWave2
wvSelectSignal -win $_nWave2 {( "1.Clock_Reset" 1 )}
