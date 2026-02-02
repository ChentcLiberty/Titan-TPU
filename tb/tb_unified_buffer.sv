`timescale 1ns/1ps
`default_nettype none

// ═══════════════════════════════════════════════════════════════════════════════
// Unified Buffer Testbench - Basic Functionality Test
// Author: Claude Sonnet 4.5
// Date: 2026-01-27
//
// Features:
// - FSDB waveform generation for Verdi
// - Host write and read verification
// - Weight loading sequence test
// - Input data streaming test
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
    // 辅助任务
    // ═══════════════════════════════════════════════════════════════════════════

    // 复位任务
    task reset_dut();
        rst = 1;
        ub_wr_data_in[0] = 0;
        ub_wr_data_in[1] = 0;
        ub_wr_valid_in[0] = 0;
        ub_wr_valid_in[1] = 0;
        ub_wr_host_data_in[0] = 0;
        ub_wr_host_data_in[1] = 0;
        ub_wr_host_valid_in[0] = 0;
        ub_wr_host_valid_in[1] = 0;
        ub_rd_start_in = 0;
        ub_rd_transpose = 0;
        ub_ptr_select = 0;
        ub_rd_addr_in = 0;
        ub_rd_row_size = 0;
        ub_rd_col_size = 0;
        learning_rate_in = 0;
        repeat(5) @(posedge clk);
        rst = 0;
        @(posedge clk);
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
        @(posedge clk);
        ub_wr_host_data_in[0] = data00;
        ub_wr_host_data_in[1] = data01;
        ub_wr_host_valid_in[0] = 1;
        ub_wr_host_valid_in[1] = 1;

        // 第二行：data10, data11
        @(posedge clk);
        ub_wr_host_data_in[0] = data10;
        ub_wr_host_data_in[1] = data11;
        ub_wr_host_valid_in[0] = 1;
        ub_wr_host_valid_in[1] = 1;

        @(posedge clk);
        ub_wr_host_valid_in[0] = 0;
        ub_wr_host_valid_in[1] = 0;

        @(posedge clk);
        $display("[%0t] Host写入完成", $time);
    endtask

    // 启动读取任务
    task start_read(
        input logic [8:0] ptr_sel,
        input logic [15:0] addr,
        input logic [15:0] rows,
        input logic [15:0] cols,
        input logic transpose
    );
        @(posedge clk);
        ub_ptr_select = ptr_sel;
        ub_rd_addr_in = addr;
        ub_rd_row_size = rows;
        ub_rd_col_size = cols;
        ub_rd_transpose = transpose;
        ub_rd_start_in = 1;

        @(posedge clk);
        ub_rd_start_in = 0;

        $display("[%0t] 启动读取: ptr_sel=%0d, addr=%0d, rows=%0d, cols=%0d, transpose=%0d",
                 $time, ptr_sel, addr, rows, cols, transpose);
    endtask

    // 检查权重读取结果
    task check_weight_read(
        input string test_name,
        input logic [15:0] expected_w0_t0,
        input logic [15:0] expected_w1_t0,
        input logic [15:0] expected_w0_t1,
        input logic [15:0] expected_w1_t1
    );
        logic [15:0] actual_w0_t0, actual_w1_t0;
        logic [15:0] actual_w0_t1, actual_w1_t1;

        test_count++;

        // 等待第一个周期的数据
        wait(ub_rd_weight_valid_out_0 || ub_rd_weight_valid_out_1);
        @(posedge clk);

        actual_w0_t0 = ub_rd_weight_data_out_0;
        actual_w1_t0 = ub_rd_weight_data_out_1;

        // 等待第二个周期的数据
        @(posedge clk);
        actual_w0_t1 = ub_rd_weight_data_out_0;
        actual_w1_t1 = ub_rd_weight_data_out_1;

        if (actual_w0_t0 == expected_w0_t0 && actual_w1_t0 == expected_w1_t0 &&
            actual_w0_t1 == expected_w0_t1 && actual_w1_t1 == expected_w1_t1) begin
            $display("✅ [PASS] %s", test_name);
            $display("   T0: W0=%h, W1=%h", actual_w0_t0, actual_w1_t0);
            $display("   T1: W0=%h, W1=%h", actual_w0_t1, actual_w1_t1);
            pass_count++;
        end else begin
            $display("❌ [FAIL] %s", test_name);
            $display("   Expected T0: W0=%h, W1=%h", expected_w0_t0, expected_w1_t0);
            $display("   Got T0:      W0=%h, W1=%h", actual_w0_t0, actual_w1_t0);
            $display("   Expected T1: W0=%h, W1=%h", expected_w0_t1, expected_w1_t1);
            $display("   Got T1:      W0=%h, W1=%h", actual_w0_t1, actual_w1_t1);
            fail_count++;
        end
    endtask

    // 检查输入读取结果
    task check_input_read(
        input string test_name,
        input logic [15:0] expected_in0_t0,
        input logic [15:0] expected_in1_t0,
        input logic [15:0] expected_in0_t1,
        input logic [15:0] expected_in1_t1
    );
        logic [15:0] actual_in0_t0, actual_in1_t0;
        logic [15:0] actual_in0_t1, actual_in1_t1;

        test_count++;

        // 等待第一个周期的数据
        wait(ub_rd_input_valid_out_0 || ub_rd_input_valid_out_1);
        @(posedge clk);

        actual_in0_t0 = ub_rd_input_data_out_0;
        actual_in1_t0 = ub_rd_input_data_out_1;

        // 等待第二个周期的数据
        @(posedge clk);
        actual_in0_t1 = ub_rd_input_data_out_0;
        actual_in1_t1 = ub_rd_input_data_out_1;

        if (actual_in0_t0 == expected_in0_t0 && actual_in1_t0 == expected_in1_t0 &&
            actual_in0_t1 == expected_in0_t1 && actual_in1_t1 == expected_in1_t1) begin
            $display("✅ [PASS] %s", test_name);
            $display("   T0: IN0=%h, IN1=%h", actual_in0_t0, actual_in1_t0);
            $display("   T1: IN0=%h, IN1=%h", actual_in0_t1, actual_in1_t1);
            pass_count++;
        end else begin
            $display("❌ [FAIL] %s", test_name);
            $display("   Expected T0: IN0=%h, IN1=%h", expected_in0_t0, expected_in1_t0);
            $display("   Got T0:      IN0=%h, IN1=%h", actual_in0_t0, actual_in1_t0);
            $display("   Expected T1: IN0=%h, IN1=%h", expected_in0_t1, expected_in1_t1);
            $display("   Got T1:      IN0=%h, IN1=%h", actual_in0_t1, actual_in1_t1);
            fail_count++;
        end
    endtask

    // ═══════════════════════════════════════════════════════════════════════════
    // 测试用例
    // ═══════════════════════════════════════════════════════════════════════════

    initial begin
        $display("═══════════════════════════════════════════════════════════════════");
        $display("🚀 Unified Buffer Testbench 开始");
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
        // 存储: ub_memory[0]=0x0100, [1]=0x0200, [2]=0x0300, [3]=0x0400
        host_write_matrix(16'h0100, 16'h0200, 16'h0300, 16'h0400);

        // 读取权重（ptr_select=1）
        // 权重从底部开始读：先读[2],[3]，再读[0],[1]
        start_read(9'd1, 16'd0, 16'd2, 16'd2, 1'b0);

        // 检查结果
        // T0: 应该读到下层权重 0x0300, 0x0400
        // T1: 应该读到上层权重 0x0100, 0x0200
        check_weight_read("权重读取",
                         16'h0300, 16'h0400,  // T0
                         16'h0100, 16'h0200); // T1

        repeat(5) @(posedge clk);

        // ───────────────────────────────────────────────────────────────────────
        // Test 2: Host写入并读取输入数据
        // ───────────────────────────────────────────────────────────────────────
        $display("───────────────────────────────────────────────────────────────────");
        $display("Test 2: Host写入输入数据并读取");
        $display("───────────────────────────────────────────────────────────────────");

        reset_dut();

        // 写入2×2输入矩阵到地址0
        // 矩阵: [0x1000 0x2000]
        //       [0x3000 0x4000]
        host_write_matrix(16'h1000, 16'h2000, 16'h3000, 16'h4000);

        // 读取输入数据（ptr_select=0）
        start_read(9'd0, 16'd0, 16'd2, 16'd2, 1'b0);

        // 检查结果
        // T0: 应该读到第一行 0x1000, 0x2000
        // T1: 应该读到第二行 0x3000, 0x4000
        check_input_read("输入数据读取",
                        16'h1000, 16'h2000,  // T0
                        16'h3000, 16'h4000); // T1

        repeat(5) @(posedge clk);

        // ───────────────────────────────────────────────────────────────────────
        // Test 3: 验证行主序存储
        // ───────────────────────────────────────────────────────────────────────
        $display("───────────────────────────────────────────────────────────────────");
        $display("Test 3: 验证行主序存储格式");
        $display("───────────────────────────────────────────────────────────────────");

        reset_dut();

        // 写入特殊模式的矩阵
        // 矩阵: [0xAA00 0xAA01]
        //       [0xAA10 0xAA11]
        host_write_matrix(16'hAA00, 16'hAA01, 16'hAA10, 16'hAA11);

        // 读取输入数据验证顺序
        start_read(9'd0, 16'd0, 16'd2, 16'd2, 1'b0);

        check_input_read("行主序验证",
                        16'hAA00, 16'hAA01,  // 第一行
                        16'hAA10, 16'hAA11); // 第二行

        repeat(10) @(posedge clk);

        // ═══════════════════════════════════════════════════════════════════════
        // 测试总结
        // ═══════════════════════════════════════════════════════════════════════
        $display("");
        $display("═══════════════════════════════════════════════════════════════════");
        $display("📊 测试总结");
        $display("═══════════════════════════════════════════════════════════════════");
        $display("总测试数: %0d", test_count);
        $display("通过数:   %0d", pass_count);
        $display("失败数:   %0d", fail_count);
        if (test_count > 0) begin
            $display("通过率:   %0.1f%%", (pass_count * 100.0) / test_count);
        end
        $display("═══════════════════════════════════════════════════════════════════");

        if (fail_count == 0) begin
            $display("✅ 所有测试通过!");
        end else begin
            $display("❌ 有 %0d 个测试失败", fail_count);
        end

        $display("");
        $finish;
    end

    // 超时保护
    initial begin
        #50000;  // 50us timeout
        $display("❌ 测试超时!");
        $finish;
    end

endmodule
