`timescale 1ns/1ps
`default_nettype none

// ═══════════════════════════════════════════════════════════════════════════════
// Unified Buffer Testbench - With Clocking Block
// Author: Chen Weidong
// Date: 2026-02-03
//
// Features:
// - Clocking Block for proper timing
// - FSDB waveform generation for Verdi
// - Host write and read verification
// - Self-checking with expected results
// ═══════════════════════════════════════════════════════════════════════════════

module tb_unified_buffer;

    // ═══════════════════════════════════════════════════════════════════════════
    // 参数定义
    // ═══════════════════════════════════════════════════════════════════════════

    parameter int UNIFIED_BUFFER_WIDTH = 128;
    parameter int SYSTOLIC_ARRAY_WIDTH = 2;

    // ═══════════════════════════════════════════════════════════════════════════
    // 信号声明
    // ═══════════════════════════════════════════════════════════════════════════

    logic clk;
    logic rst;

    // Write ports from VPU
    logic [15:0] ub_wr_data_in [SYSTOLIC_ARRAY_WIDTH];
    logic ub_wr_valid_in [SYSTOLIC_ARRAY_WIDTH];

    // Write ports from host
    logic [15:0] ub_wr_host_data_in [SYSTOLIC_ARRAY_WIDTH];
    logic ub_wr_host_valid_in [SYSTOLIC_ARRAY_WIDTH];

    // Read control
    logic ub_rd_start_in;
    logic ub_rd_transpose;
    logic [8:0] ub_ptr_select;
    logic [15:0] ub_rd_addr_in;
    logic [15:0] ub_rd_row_size;
    logic [15:0] ub_rd_col_size;
    logic [15:0] learning_rate_in;

    // Read outputs - inputs
    logic [15:0] ub_rd_input_data_out_0;
    logic [15:0] ub_rd_input_data_out_1;
    logic ub_rd_input_valid_out_0;
    logic ub_rd_input_valid_out_1;

    // Read outputs - weights
    logic [15:0] ub_rd_weight_data_out_0;
    logic [15:0] ub_rd_weight_data_out_1;
    logic ub_rd_weight_valid_out_0;
    logic ub_rd_weight_valid_out_1;

    // Read outputs - bias
    logic [15:0] ub_rd_bias_data_out_0;
    logic [15:0] ub_rd_bias_data_out_1;

    // Read outputs - Y matrices
    logic [15:0] ub_rd_Y_data_out_0;
    logic [15:0] ub_rd_Y_data_out_1;

    // Read outputs - H matrices
    logic [15:0] ub_rd_H_data_out_0;
    logic [15:0] ub_rd_H_data_out_1;

    // Column size output
    logic [15:0] ub_rd_col_size_out;
    logic ub_rd_col_size_valid_out;

    // 测试统计
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;

    // ═══════════════════════════════════════════════════════════════════════════
    // DUT 实例化
    // ═══════════════════════════════════════════════════════════════════════════

    unified_buffer #(
        .UNIFIED_BUFFER_WIDTH(UNIFIED_BUFFER_WIDTH),
        .SYSTOLIC_ARRAY_WIDTH(SYSTOLIC_ARRAY_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .ub_wr_data_in(ub_wr_data_in),
        .ub_wr_valid_in(ub_wr_valid_in),
        .ub_wr_host_data_in(ub_wr_host_data_in),
        .ub_wr_host_valid_in(ub_wr_host_valid_in),
        .ub_rd_start_in(ub_rd_start_in),
        .ub_rd_transpose(ub_rd_transpose),
        .ub_ptr_select(ub_ptr_select),
        .ub_rd_addr_in(ub_rd_addr_in),
        .ub_rd_row_size(ub_rd_row_size),
        .ub_rd_col_size(ub_rd_col_size),
        .learning_rate_in(learning_rate_in),
        .ub_rd_input_data_out_0(ub_rd_input_data_out_0),
        .ub_rd_input_data_out_1(ub_rd_input_data_out_1),
        .ub_rd_input_valid_out_0(ub_rd_input_valid_out_0),
        .ub_rd_input_valid_out_1(ub_rd_input_valid_out_1),
        .ub_rd_weight_data_out_0(ub_rd_weight_data_out_0),
        .ub_rd_weight_data_out_1(ub_rd_weight_data_out_1),
        .ub_rd_weight_valid_out_0(ub_rd_weight_valid_out_0),
        .ub_rd_weight_valid_out_1(ub_rd_weight_valid_out_1),
        .ub_rd_bias_data_out_0(ub_rd_bias_data_out_0),
        .ub_rd_bias_data_out_1(ub_rd_bias_data_out_1),
        .ub_rd_Y_data_out_0(ub_rd_Y_data_out_0),
        .ub_rd_Y_data_out_1(ub_rd_Y_data_out_1),
        .ub_rd_H_data_out_0(ub_rd_H_data_out_0),
        .ub_rd_H_data_out_1(ub_rd_H_data_out_1),
        .ub_rd_col_size_out(ub_rd_col_size_out),
        .ub_rd_col_size_valid_out(ub_rd_col_size_valid_out)
    );

    // ═══════════════════════════════════════════════════════════════════════════
    // Clocking Block - 解决时序竞争问题
    // ═══════════════════════════════════════════════════════════════════════════
    //
    // 问题：testbench 在时钟沿后赋值，DUT 在时钟沿采样，导致采样到旧值
    // 解决：使用 clocking block，让信号在时钟沿前稳定
    //
    // ═══════════════════════════════════════════════════════════════════════════

    clocking cb @(posedge clk);
        default input #1step output #1step;

        // Output 信号（testbench → DUT）
        output rst;
        output ub_wr_host_data_in;
        output ub_wr_host_valid_in;
        output ub_rd_start_in;
        output ub_rd_transpose;
        output ub_ptr_select;
        output ub_rd_addr_in;
        output ub_rd_row_size;
        output ub_rd_col_size;
        output learning_rate_in;

        // Input 信号（DUT → testbench）
        input ub_rd_input_data_out_0;
        input ub_rd_input_data_out_1;
        input ub_rd_input_valid_out_0;
        input ub_rd_input_valid_out_1;
        input ub_rd_weight_data_out_0;
        input ub_rd_weight_data_out_1;
        input ub_rd_weight_valid_out_0;
        input ub_rd_weight_valid_out_1;
        input ub_rd_col_size_out;
        input ub_rd_col_size_valid_out;
    endclocking

    // ═══════════════════════════════════════════════════════════════════════════
    // 时钟生成
    // ═══════════════════════════════════════════════════════════════════════════

    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz clock (10ns period)
    end

    // ═══════════════════════════════════════════════════════════════════════════
    // 波形 Dump (FSDB for Verdi)
    // ═══════════════════════════════════════════════════════════════════════════

    initial begin
        $fsdbDumpfile("../../waveforms/tb_unified_buffer.fsdb");
        $fsdbDumpvars(0, tb_unified_buffer);
        $fsdbDumpMDA();
    end

    // ═══════════════════════════════════════════════════════════════════════════
    // 辅助任务 - 使用 Clocking Block
    // ═══════════════════════════════════════════════════════════════════════════

    // 复位任务
    task reset_dut();
        cb.rst <= 1;
        cb.ub_wr_host_data_in <= '{default: '0};
        cb.ub_wr_host_valid_in <= '{default: '0};
        cb.ub_rd_start_in <= 0;
        cb.ub_rd_transpose <= 0;
        cb.ub_ptr_select <= 0;
        cb.ub_rd_addr_in <= 0;
        cb.ub_rd_row_size <= 0;
        cb.ub_rd_col_size <= 0;
        cb.learning_rate_in <= 0;
        // VPU 写入端口直接赋值（不在 clocking block 中）
        ub_wr_data_in[0] = 0;
        ub_wr_data_in[1] = 0;
        ub_wr_valid_in[0] = 0;
        ub_wr_valid_in[1] = 0;
        repeat(5) @(cb);
        cb.rst <= 0;
        @(cb);
    endtask

    // Host写入任务 - 写入2×2矩阵
    task host_write_matrix(
        input logic [15:0] data00,
        input logic [15:0] data01,
        input logic [15:0] data10,
        input logic [15:0] data11
    );
        $display("[%0t] Host写入矩阵: [%h %h; %h %h]",
                 $time, data00, data01, data10, data11);

        // 第一行：data00, data01
        @(cb);
        cb.ub_wr_host_data_in <= '{data01, data00};
        cb.ub_wr_host_valid_in <= '{1'b1, 1'b1};

        // 第二行：data10, data11
        @(cb);
        cb.ub_wr_host_data_in <= '{data11, data10};
        cb.ub_wr_host_valid_in <= '{1'b1, 1'b1};

        @(cb);
        cb.ub_wr_host_valid_in <= '{1'b0, 1'b0};

        @(cb);
        $display("[%0t] Host写入完成", $time);
    endtask

    // 启动读取任务 - 使用 Clocking Block
    task start_read(
        input logic [8:0] ptr_sel,
        input logic [15:0] addr,
        input logic [15:0] rows,
        input logic [15:0] cols,
        input logic transpose
    );
        // 设置读取参数
        @(cb);
        cb.ub_ptr_select <= ptr_sel;
        cb.ub_rd_addr_in <= addr;
        cb.ub_rd_row_size <= rows;
        cb.ub_rd_col_size <= cols;
        cb.ub_rd_transpose <= transpose;
        cb.ub_rd_start_in <= 1;

        // 保持一个周期后拉低
        @(cb);
        cb.ub_rd_start_in <= 0;

        $display("[%0t] 启动读取: ptr_sel=%0d, addr=%0d, rows=%0d, cols=%0d, transpose=%0d",
                 $time, ptr_sel, addr, rows, cols, transpose);
    endtask

    // 检查权重读取结果（2x2矩阵对角馈送模式，需要3个周期）
    task check_weight_read_2x2(
        input string test_name,
        input logic [15:0] expected_w0_t0,
        input logic [15:0] expected_w1_t0,
        input logic [15:0] expected_w0_t1,
        input logic [15:0] expected_w1_t1,
        input logic [15:0] expected_w0_t2,
        input logic [15:0] expected_w1_t2
    );
        logic [15:0] actual_w0_t0, actual_w1_t0;
        logic [15:0] actual_w0_t1, actual_w1_t1;
        logic [15:0] actual_w0_t2, actual_w1_t2;
        logic pass;

        test_count++;

        // 等待第一个周期的数据
        wait(cb.ub_rd_weight_valid_out_0 || cb.ub_rd_weight_valid_out_1);
        @(cb);
        actual_w0_t0 = cb.ub_rd_weight_data_out_0;
        actual_w1_t0 = cb.ub_rd_weight_data_out_1;

        // 第二个周期
        @(cb);
        actual_w0_t1 = cb.ub_rd_weight_data_out_0;
        actual_w1_t1 = cb.ub_rd_weight_data_out_1;

        // 第三个周期
        @(cb);
        actual_w0_t2 = cb.ub_rd_weight_data_out_0;
        actual_w1_t2 = cb.ub_rd_weight_data_out_1;

        pass = (actual_w0_t0 == expected_w0_t0) && (actual_w1_t0 == expected_w1_t0) &&
               (actual_w0_t1 == expected_w0_t1) && (actual_w1_t1 == expected_w1_t1) &&
               (actual_w0_t2 == expected_w0_t2) && (actual_w1_t2 == expected_w1_t2);

        if (pass) begin
            $display("[PASS] %s", test_name);
            $display("   T0: W0=%h, W1=%h", actual_w0_t0, actual_w1_t0);
            $display("   T1: W0=%h, W1=%h", actual_w0_t1, actual_w1_t1);
            $display("   T2: W0=%h, W1=%h", actual_w0_t2, actual_w1_t2);
            pass_count++;
        end else begin
            $display("[FAIL] %s", test_name);
            $display("   Expected T0: W0=%h, W1=%h | Got: W0=%h, W1=%h",
                     expected_w0_t0, expected_w1_t0, actual_w0_t0, actual_w1_t0);
            $display("   Expected T1: W0=%h, W1=%h | Got: W0=%h, W1=%h",
                     expected_w0_t1, expected_w1_t1, actual_w0_t1, actual_w1_t1);
            $display("   Expected T2: W0=%h, W1=%h | Got: W0=%h, W1=%h",
                     expected_w0_t2, expected_w1_t2, actual_w0_t2, actual_w1_t2);
            fail_count++;
        end
    endtask

    // 检查输入读取结果（2x2矩阵对角馈送模式，需要3个周期）
    task check_input_read_2x2(
        input string test_name,
        input logic [15:0] expected_in0_t0,
        input logic [15:0] expected_in1_t0,
        input logic [15:0] expected_in0_t1,
        input logic [15:0] expected_in1_t1,
        input logic [15:0] expected_in0_t2,
        input logic [15:0] expected_in1_t2
    );
        logic [15:0] actual_in0_t0, actual_in1_t0;
        logic [15:0] actual_in0_t1, actual_in1_t1;
        logic [15:0] actual_in0_t2, actual_in1_t2;
        logic pass;

        test_count++;

        // 等待第一个周期的数据
        wait(cb.ub_rd_input_valid_out_0 || cb.ub_rd_input_valid_out_1);
        @(cb);
        actual_in0_t0 = cb.ub_rd_input_data_out_0;
        actual_in1_t0 = cb.ub_rd_input_data_out_1;

        // 第二个周期
        @(cb);
        actual_in0_t1 = cb.ub_rd_input_data_out_0;
        actual_in1_t1 = cb.ub_rd_input_data_out_1;

        // 第三个周期
        @(cb);
        actual_in0_t2 = cb.ub_rd_input_data_out_0;
        actual_in1_t2 = cb.ub_rd_input_data_out_1;

        pass = (actual_in0_t0 == expected_in0_t0) && (actual_in1_t0 == expected_in1_t0) &&
               (actual_in0_t1 == expected_in0_t1) && (actual_in1_t1 == expected_in1_t1) &&
               (actual_in0_t2 == expected_in0_t2) && (actual_in1_t2 == expected_in1_t2);

        if (pass) begin
            $display("[PASS] %s", test_name);
            $display("   T0: IN0=%h, IN1=%h", actual_in0_t0, actual_in1_t0);
            $display("   T1: IN0=%h, IN1=%h", actual_in0_t1, actual_in1_t1);
            $display("   T2: IN0=%h, IN1=%h", actual_in0_t2, actual_in1_t2);
            pass_count++;
        end else begin
            $display("[FAIL] %s", test_name);
            $display("   Expected T0: IN0=%h, IN1=%h | Got: IN0=%h, IN1=%h",
                     expected_in0_t0, expected_in1_t0, actual_in0_t0, actual_in1_t0);
            $display("   Expected T1: IN0=%h, IN1=%h | Got: IN0=%h, IN1=%h",
                     expected_in0_t1, expected_in1_t1, actual_in0_t1, actual_in1_t1);
            $display("   Expected T2: IN0=%h, IN1=%h | Got: IN0=%h, IN1=%h",
                     expected_in0_t2, expected_in1_t2, actual_in0_t2, actual_in1_t2);
            fail_count++;
        end
    endtask

    // ═══════════════════════════════════════════════════════════════════════════
    // 测试用例
    // ═══════════════════════════════════════════════════════════════════════════

    initial begin
        $display("═══════════════════════════════════════════════════════════════════");
        $display("Unified Buffer Testbench (with Clocking Block)");
        $display("═══════════════════════════════════════════════════════════════════");
        $display("");

        // 初始化
        reset_dut();

        // ───────────────────────────────────────────────────────────────────────
        // Test 1: Host写入并读取权重
        // ───────────────────────────────────────────────────────────────────────
        $display("───────────────────────────────────────────────────────────────────");
        $display("Test 1: Host写入权重并读取");
        $display("───────────────────────────────────────────────────────────────────");

        // 写入2×2权重矩阵到地址0
        // 矩阵: [0x0100 0x0200]
        //       [0x0300 0x0400]
        host_write_matrix(16'h0100, 16'h0200, 16'h0300, 16'h0400);

        // 读取权重（ptr_select=1）
        start_read(9'd1, 16'd0, 16'd2, 16'd2, 1'b0);

        // 检查结果（2x2矩阵对角馈送模式，需要3个周期）
        // 矩阵: [0100 0200; 0300 0400] 存储为 memory[0..3]
        // 权重从底部开始读取，对角馈送到脉动阵列
        check_weight_read_2x2("权重读取",
                             16'h0300, 16'h0000,  // T0: W0=0300, W1=无效
                             16'h0100, 16'h0400,  // T1: W0=0100, W1=0400
                             16'h0000, 16'h0200); // T2: W0=无效, W1=0200

        repeat(5) @(cb);

        // ───────────────────────────────────────────────────────────────────────
        // Test 2: Host写入并读取输入数据
        // ───────────────────────────────────────────────────────────────────────
        $display("───────────────────────────────────────────────────────────────────");
        $display("Test 2: Host写入输入数据并读取");
        $display("───────────────────────────────────────────────────────────────────");

        reset_dut();

        // 写入2×2输入矩阵到地址0
        host_write_matrix(16'h1000, 16'h2000, 16'h3000, 16'h4000);

        // 读取输入数据（ptr_select=0）
        start_read(9'd0, 16'd0, 16'd2, 16'd2, 1'b0);

        // 检查结果（2x2矩阵对角馈送模式，需要3个周期）
        // 矩阵: [1000 2000; 3000 4000] 存储为 memory[0..3]
        // 输入从顶部开始读取，对角馈送到脉动阵列左侧
        check_input_read_2x2("输入数据读取",
                            16'h1000, 16'h0000,  // T0: IN0=1000, IN1=无效
                            16'h3000, 16'h2000,  // T1: IN0=3000, IN1=2000
                            16'h0000, 16'h4000); // T2: IN0=无效, IN1=4000

        repeat(5) @(cb);

        // ───────────────────────────────────────────────────────────────────────
        // Test 3: 验证行主序存储
        // ───────────────────────────────────────────────────────────────────────
        $display("───────────────────────────────────────────────────────────────────");
        $display("Test 3: 验证行主序存储格式");
        $display("───────────────────────────────────────────────────────────────────");

        reset_dut();

        host_write_matrix(16'hAA00, 16'hAA01, 16'hAA10, 16'hAA11);

        start_read(9'd0, 16'd0, 16'd2, 16'd2, 1'b0);

        check_input_read_2x2("行主序验证",
                            16'hAA00, 16'h0000,  // T0
                            16'hAA10, 16'hAA01,  // T1
                            16'h0000, 16'hAA11); // T2

        repeat(10) @(cb);

        // ═══════════════════════════════════════════════════════════════════════
        // 测试总结
        // ═══════════════════════════════════════════════════════════════════════
        $display("");
        $display("═══════════════════════════════════════════════════════════════════");
        $display("Test Summary");
        $display("═══════════════════════════════════════════════════════════════════");
        $display("Total:  %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        if (test_count > 0) begin
            $display("Rate:   %0.1f%%", (pass_count * 100.0) / test_count);
        end
        $display("═══════════════════════════════════════════════════════════════════");

        if (fail_count == 0) begin
            $display("All tests passed!");
        end else begin
            $display("%0d test(s) failed", fail_count);
        end

        $display("");
        $finish;
    end

    // 超时保护
    initial begin
        #50000;  // 50us timeout
        $display("Test timeout!");
        $finish;
    end

endmodule
