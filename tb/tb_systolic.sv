`timescale 1ns/1ps
`default_nettype none

// ═══════════════════════════════════════════════════════════════════════════════
// Systolic Array Testbench - Professional Version
// Author: Claude Sonnet 4.5
// Date: 2026-01-24
//
// Features:
// - FSDB waveform generation for Verdi
// - Matrix multiplication test cases
// - Weight loading and switching verification
// - Self-checking with expected results
// ═══════════════════════════════════════════════════════════════════════════════

module tb_systolic;

    // ═══════════════════════════════════════════════════════════════════════════
    // 信号声明
    // ═══════════════════════════════════════════════════════════════════════════

    logic clk;
    logic rst;

    // Input signals from left side
    logic signed [15:0] sys_data_in_11;
    logic signed [15:0] sys_data_in_21;
    logic sys_start;

    // Output signals
    logic signed [15:0] sys_data_out_21;
    logic signed [15:0] sys_data_out_22;
    logic sys_valid_out_21;
    logic sys_valid_out_22;

    // Input signals from top (weights)
    logic signed [15:0] sys_weight_in_11;
    logic signed [15:0] sys_weight_in_12;
    logic sys_accept_w_1;
    logic sys_accept_w_2;

    // Control signals
    logic sys_switch_in;
    logic signed [15:0] ub_rd_col_size_in;
    logic ub_rd_col_size_valid_in;

    // 测试统计
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;

    // ═══════════════════════════════════════════════════════════════════════════
    // DUT 实例化
    // ═══════════════════════════════════════════════════════════════════════════

    systolic #(
        .SYSTOLIC_ARRAY_WIDTH(2)
    ) dut (
        .clk(clk),
        .rst(rst),
        .sys_data_in_11(sys_data_in_11),
        .sys_data_in_21(sys_data_in_21),
        .sys_start(sys_start),
        .sys_data_out_21(sys_data_out_21),
        .sys_data_out_22(sys_data_out_22),
        .sys_valid_out_21(sys_valid_out_21),
        .sys_valid_out_22(sys_valid_out_22),
        .sys_weight_in_11(sys_weight_in_11),
        .sys_weight_in_12(sys_weight_in_12),
        .sys_accept_w_1(sys_accept_w_1),
        .sys_accept_w_2(sys_accept_w_2),
        .sys_switch_in(sys_switch_in),
        .ub_rd_col_size_in(ub_rd_col_size_in),
        .ub_rd_col_size_valid_in(ub_rd_col_size_valid_in)
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
        $fsdbDumpfile("../../waveforms/tb_systolic.fsdb");
        $fsdbDumpvars(0, tb_systolic);
        $fsdbDumpMDA();
    end

    // ═══════════════════════════════════════════════════════════════════════════
    // 辅助任务
    // ═══════════════════════════════════════════════════════════════════════════

    // 复位任务
    task reset_dut();
        rst = 1;
        sys_data_in_11 = 0;
        sys_data_in_21 = 0;
        sys_start = 0;
        sys_weight_in_11 = 0;
        sys_weight_in_12 = 0;
        sys_accept_w_1 = 0;
        sys_accept_w_2 = 0;
        sys_switch_in = 0;
        ub_rd_col_size_in = 0;
        ub_rd_col_size_valid_in = 0;
        repeat(5) @(posedge clk);
        rst = 0;
        @(posedge clk);
    endtask

    // 使能列任务
    task enable_columns(input int num_cols);
        @(posedge clk);
        ub_rd_col_size_in = num_cols;
        ub_rd_col_size_valid_in = 1;
        @(posedge clk);
        ub_rd_col_size_valid_in = 0;
        @(posedge clk);
    endtask

    // 加载权重任务 - 根据golden model修正
    // 权重加载顺序：先加载下层，让它传播到下一个PE，然后加载上层
    task load_weights(
        input logic signed [15:0] w11,
        input logic signed [15:0] w12,
        input logic signed [15:0] w21,
        input logic signed [15:0] w22
    );
        $display("[%0t] 加载权重: W11=%h, W12=%h, W21=%h, W22=%h",
                 $time, w11, w12, w21, w22);

        // Cycle 1: 先加载列1的下层权重 W21
        // 这个权重会通过PE11传播到PE21
        @(posedge clk);
        sys_weight_in_11 = w21;
        sys_accept_w_1 = 1;
        sys_accept_w_2 = 0;

        // Cycle 2: 加载列1的上层权重 W11 和列2的下层权重 W22
        // PE11接收W11，PE21接收传播下来的W21
        // PE12接收W22
        @(posedge clk);
        sys_weight_in_11 = w11;
        sys_accept_w_1 = 1;
        sys_weight_in_12 = w22;
        sys_accept_w_2 = 1;

        // Cycle 3: 加载列2的上层权重 W12，并切换权重
        // PE12接收W12，PE22接收传播下来的W22
        @(posedge clk);
        sys_accept_w_1 = 0;
        sys_weight_in_12 = w12;
        sys_accept_w_2 = 1;
        sys_switch_in = 1;  // 同时切换权重

        // Cycle 4: 完成切换
        @(posedge clk);
        sys_accept_w_2 = 0;
        sys_switch_in = 0;

        @(posedge clk);

        $display("[%0t] 权重加载完成", $time);
    endtask

    // 发送激活数据任务
    // 注意：数据需要持续发送，让它流过整个阵列
    task send_activation(
        input logic signed [15:0] a11,
        input logic signed [15:0] a21
    );
        @(posedge clk);
        sys_data_in_11 = a11;
        sys_data_in_21 = a21;
        sys_start = 1;
        @(posedge clk);
        // 保持数据和valid信号，让数据流过阵列
        @(posedge clk);
        sys_start = 0;
        sys_data_in_11 = 0;
        sys_data_in_21 = 0;
    endtask

    // 检查结果任务
    task check_result(
        input string test_name,
        input logic signed [15:0] expected_21,
        input logic signed [15:0] expected_22,
        input int tolerance
    );
        int diff_21, diff_22;

        test_count++;

        // Wait for valid output with timeout
        fork
            begin
                wait(sys_valid_out_21 && sys_valid_out_22);
            end
            begin
                repeat(20) @(posedge clk);
            end
        join_any
        disable fork;

        @(posedge clk);

        diff_21 = (sys_data_out_21 > expected_21) ?
                  (sys_data_out_21 - expected_21) : (expected_21 - sys_data_out_21);
        diff_22 = (sys_data_out_22 > expected_22) ?
                  (sys_data_out_22 - expected_22) : (expected_22 - sys_data_out_22);

        if (diff_21 <= tolerance && diff_22 <= tolerance) begin
            $display("✅ [PASS] %s", test_name);
            $display("   Expected: OUT21=%h, OUT22=%h", expected_21, expected_22);
            $display("   Got:      OUT21=%h, OUT22=%h", sys_data_out_21, sys_data_out_22);
            pass_count++;
        end else begin
            $display("❌ [FAIL] %s", test_name);
            $display("   Expected: OUT21=%h, OUT22=%h", expected_21, expected_22);
            $display("   Got:      OUT21=%h, OUT22=%h", sys_data_out_21, sys_data_out_22);
            $display("   Diff:     OUT21=%0d, OUT22=%0d", diff_21, diff_22);
            fail_count++;
        end
    endtask

    // Q8.8 定点数转换函数
    function automatic logic signed [15:0] float_to_q88(real f);
        return $rtoi(f * 256.0);
    endfunction

    function automatic real q88_to_float(logic signed [15:0] q);
        return $itor(q) / 256.0;
    endfunction

    // ═══════════════════════════════════════════════════════════════════════════
    // 测试用例
    // ═══════════════════════════════════════════════════════════════════════════

    initial begin
        $display("═══════════════════════════════════════════════════════════════════");
        $display("🚀 Systolic Array Testbench 开始");
        $display("═══════════════════════════════════════════════════════════════════");
        $display("");

        // 初始化
        reset_dut();

        // 使能两列
        enable_columns(2);

        // ───────────────────────────────────────────────────────────────────────
        // Test 1: 简单矩阵乘法 (单位矩阵)
        // ───────────────────────────────────────────────────────────────────────
        $display("───────────────────────────────────────────────────────────────────");
        $display("Test 1: 单位矩阵测试");
        $display("───────────────────────────────────────────────────────────────────");

        // 权重矩阵 W = [1.0  0.0]
        //              [0.0  1.0]
        load_weights(
            float_to_q88(1.0),   // W11
            float_to_q88(0.0),   // W12
            float_to_q88(0.0),   // W21
            float_to_q88(1.0)    // W22
        );

        // 激活向量 A = [2.0, 3.0]
        send_activation(
            float_to_q88(2.0),   // A11
            float_to_q88(3.0)    // A21
        );

        // 期望输出: [2.0, 3.0]
        check_result("单位矩阵",
                    float_to_q88(2.0),
                    float_to_q88(3.0),
                    5);

        repeat(5) @(posedge clk);

        // ───────────────────────────────────────────────────────────────────────
        // Test 2: 简单乘法
        // ───────────────────────────────────────────────────────────────────────
        $display("───────────────────────────────────────────────────────────────────");
        $display("Test 2: 简单乘法测试");
        $display("───────────────────────────────────────────────────────────────────");

        reset_dut();
        enable_columns(2);

        // 权重矩阵 W = [2.0  0.0]
        //              [0.0  3.0]
        load_weights(
            float_to_q88(2.0),   // W11
            float_to_q88(0.0),   // W12
            float_to_q88(0.0),   // W21
            float_to_q88(3.0)    // W22
        );

        // 激活向量 A = [1.0, 1.0]
        send_activation(
            float_to_q88(1.0),   // A11
            float_to_q88(1.0)    // A21
        );

        // 期望输出: [2.0, 3.0]
        check_result("简单乘法",
                    float_to_q88(2.0),
                    float_to_q88(3.0),
                    5);

        repeat(5) @(posedge clk);

        // ───────────────────────────────────────────────────────────────────────
        // Test 3: 全1测试
        // ───────────────────────────────────────────────────────────────────────
        $display("───────────────────────────────────────────────────────────────────");
        $display("Test 3: 全1测试");
        $display("───────────────────────────────────────────────────────────────────");

        reset_dut();
        enable_columns(2);

        // 权重矩阵 W = [1.0  1.0]
        //              [1.0  1.0]
        load_weights(
            float_to_q88(1.0),   // W11
            float_to_q88(1.0),   // W12
            float_to_q88(1.0),   // W21
            float_to_q88(1.0)    // W22
        );

        // 激活向量 A = [1.0, 1.0]
        send_activation(
            float_to_q88(1.0),   // A11
            float_to_q88(1.0)    // A21
        );

        // 期望输出: [2.0, 2.0] (每列累加)
        check_result("全1测试",
                    float_to_q88(2.0),
                    float_to_q88(2.0),
                    5);

        repeat(5) @(posedge clk);

        // ───────────────────────────────────────────────────────────────────────
        // Test 4: 负数测试
        // ───────────────────────────────────────────────────────────────────────
        $display("───────────────────────────────────────────────────────────────────");
        $display("Test 4: 负数测试");
        $display("───────────────────────────────────────────────────────────────────");

        reset_dut();
        enable_columns(2);

        // 权重矩阵 W = [-1.0   0.0]
        //              [ 0.0  -1.0]
        load_weights(
            float_to_q88(-1.0),  // W11
            float_to_q88(0.0),   // W12
            float_to_q88(0.0),   // W21
            float_to_q88(-1.0)   // W22
        );

        // 激活向量 A = [2.0, 3.0]
        send_activation(
            float_to_q88(2.0),   // A11
            float_to_q88(3.0)    // A21
        );

        // 期望输出: [-2.0, -3.0]
        check_result("负数测试",
                    float_to_q88(-2.0),
                    float_to_q88(-3.0),
                    5);

        repeat(5) @(posedge clk);

        // ───────────────────────────────────────────────────────────────────────
        // Test 5: 小数测试
        // ───────────────────────────────────────────────────────────────────────
        $display("───────────────────────────────────────────────────────────────────");
        $display("Test 5: 小数测试");
        $display("───────────────────────────────────────────────────────────────────");

        reset_dut();
        enable_columns(2);

        // 权重矩阵 W = [0.5  0.0]
        //              [0.0  0.25]
        load_weights(
            float_to_q88(0.5),   // W11
            float_to_q88(0.0),   // W12
            float_to_q88(0.0),   // W21
            float_to_q88(0.25)   // W22
        );

        // 激活向量 A = [4.0, 8.0]
        send_activation(
            float_to_q88(4.0),   // A11
            float_to_q88(8.0)    // A21
        );

        // 期望输出: [2.0, 2.0]
        check_result("小数测试",
                    float_to_q88(2.0),
                    float_to_q88(2.0),
                    5);

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
        $display("通过率:   %0.1f%%", (pass_count * 100.0) / test_count);
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
        #100000;  // 100us timeout
        $display("❌ 测试超时!");
        $finish;
    end

endmodule
