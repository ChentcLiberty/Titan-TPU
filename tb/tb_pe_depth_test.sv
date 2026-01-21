`timescale 1ns/1ps
`default_nettype none

// ═══════════════════════════════════════════════════════════════════════════════
// PE Module Testbench - 层次控制测试
// 用于验证 $fsdbDumpvars() 的 depth 参数功能
// ═══════════════════════════════════════════════════════════════════════════════

module tb_pe_depth_test;

    logic clk;
    logic rst;
    logic signed [15:0] pe_psum_in;
    logic signed [15:0] pe_weight_in;
    logic pe_accept_w_in;
    logic signed [15:0] pe_input_in;
    logic pe_valid_in;
    logic pe_switch_in;
    logic pe_enabled;
    logic signed [15:0] pe_psum_out;
    logic signed [15:0] pe_weight_out;
    logic signed [15:0] pe_input_out;
    logic pe_valid_out;
    logic pe_switch_out;

    // DUT 实例化
    pe #(.DATA_WIDTH(16)) dut (
        .clk(clk),
        .rst(rst),
        .pe_psum_in(pe_psum_in),
        .pe_weight_in(pe_weight_in),
        .pe_accept_w_in(pe_accept_w_in),
        .pe_input_in(pe_input_in),
        .pe_valid_in(pe_valid_in),
        .pe_switch_in(pe_switch_in),
        .pe_enabled(pe_enabled),
        .pe_psum_out(pe_psum_out),
        .pe_weight_out(pe_weight_out),
        .pe_input_out(pe_input_out),
        .pe_valid_out(pe_valid_out),
        .pe_switch_out(pe_switch_out)
    );

    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // FSDB 波形生成 - 测试不同的 depth 参数
    initial begin
        $display("═══════════════════════════════════════════════════════════════════");
        $display("🧪 测试 $fsdbDumpvars() 层次控制功能");
        $display("═══════════════════════════════════════════════════════════════════");

        // 测试1：depth=0（dump所有层次）
        $fsdbDumpfile("../../waveforms/tb_pe_depth0.fsdb");
        $fsdbDumpvars(0, tb_pe_depth_test);
        $display("✅ depth=0: dump所有层次（tb_pe_depth_test + dut + dut内部所有模块）");

        // 测试2：depth=1（只dump当前层）
        // $fsdbDumpfile("../../waveforms/tb_pe_depth1.fsdb");
        // $fsdbDumpvars(1, tb_pe_depth_test);
        // $display("✅ depth=1: 只dump tb_pe_depth_test这一层的信号");

        // 测试3：depth=2（dump两层）
        // $fsdbDumpfile("../../waveforms/tb_pe_depth2.fsdb");
        // $fsdbDumpvars(2, tb_pe_depth_test);
        // $display("✅ depth=2: dump tb_pe_depth_test + dut这两层");

        $display("═══════════════════════════════════════════════════════════════════\n");
    end

    // 简单测试
    initial begin
        rst = 1;
        pe_enabled = 0;
        pe_valid_in = 0;
        pe_accept_w_in = 0;
        pe_switch_in = 0;
        pe_input_in = 16'h0000;
        pe_weight_in = 16'h0000;
        pe_psum_in = 16'h0000;

        repeat(3) @(posedge clk);
        rst = 0;
        pe_enabled = 1;

        // 加载权重
        @(posedge clk);
        pe_accept_w_in = 1;
        pe_weight_in = 16'h0200;  // 2.0
        @(posedge clk);
        pe_accept_w_in = 0;

        // 切换权重
        @(posedge clk);
        pe_switch_in = 1;
        @(posedge clk);
        pe_switch_in = 0;
        @(posedge clk);

        // MAC运算
        pe_input_in = 16'h0300;  // 3.0
        pe_psum_in = 16'h0100;   // 1.0
        pe_valid_in = 1;
        @(posedge clk);
        @(posedge clk);
        pe_valid_in = 0;

        repeat(10) @(posedge clk);

        $display("✅ 测试完成！");
        $display("📊 FSDB文件已生成：../../waveforms/tb_pe_depth0.fsdb");
        $finish(0);
    end

    // 超时保护
    initial begin
        #1000;
        $display("❌ 测试超时!");
        $finish(2);
    end

endmodule

`default_nettype wire
