`timescale 1ns/1ps
`default_nettype none

// ═══════════════════════════════════════════════════════════════════════════════
// PE Module Testbench - Professional Version
// Author: Chen Weidong
// Date: 2026-01-20
//
// Features:
// - FSDB waveform generation for Verdi
// - Self-checking test cases
// - Comprehensive test coverage
// - Clear pass/fail reporting
// ═══════════════════════════════════════════════════════════════════════════════

module tb_pe;

    // ═══════════════════════════════════════════════════════════════════════════
    // 信号声明
    // ═══════════════════════════════════════════════════════════════════════════

    logic clk;
    logic rst;

    // North wires (from above)
    logic signed [15:0] pe_psum_in;
    logic signed [15:0] pe_weight_in;
    logic pe_accept_w_in;

    // West wires (from left)
    logic signed [15:0] pe_input_in;
    logic pe_valid_in;
    logic pe_switch_in;
    logic pe_enabled;

    // South wires (to below)
    logic signed [15:0] pe_psum_out;
    logic signed [15:0] pe_weight_out;

    // East wires (to right)
    logic signed [15:0] pe_input_out;
    logic pe_valid_out;
    logic pe_switch_out;

    // 测试统计
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;

    // 随机测试配置
    int random_test_num = 10;  // 随机测试数量

    // ═══════════════════════════════════════════════════════════════════════════
    // DUT 实例化
    // ═══════════════════════════════════════════════════════════════════════════

    pe #(
        .DATA_WIDTH(16)
    ) dut (
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

    // ═══════════════════════════════════════════════════════════════════════════
    // Clocking Block - SystemVerilog 标准时序管理
    // ═══════════════════════════════════════════════════════════════════════════
    //
    // Clocking Block 的作用：
    // 1. 自动处理信号的采样和驱动时序
    // 2. 避免竞争条件（race condition）
    // 3. 模拟真实硬件的 setup/hold time
    // 4. 符合 UVM 验证方法学标准
    //
    // 关键概念：
    // - output: testbench 驱动信号到 DUT（在时钟边沿后 #1step 驱动）
    // - input:  testbench 从 DUT 采样信号（在时钟边沿前 #1step 采样）
    // - #1step: 一个仿真时间步，自动适应时钟周期，不是固定的时间值
    //
    // 时序说明：
    //   时钟边沿前 #1step: 采样 DUT 的输出（input 信号）
    //   时钟边沿:          时钟上升沿
    //   时钟边沿后 #1step: 驱动 DUT 的输入（output 信号）
    //
    // ═══════════════════════════════════════════════════════════════════════════

    clocking cb @(posedge clk);
        // 默认配置：输入在时钟边沿前 1step 采样，输出在时钟边沿后 1step 驱动
        default input #1step output #1step;

        // ───────────────────────────────────────────────────────────────────────
        // Output 信号（testbench → DUT）
        // 这些是 DUT 的输入端口，testbench 需要驱动它们
        // ───────────────────────────────────────────────────────────────────────
        output pe_psum_in;      // 部分和输入
        output pe_weight_in;    // 权重输入
        output pe_accept_w_in;  // 权重接受信号
        output pe_input_in;     // 激活值输入
        output pe_valid_in;     // 输入有效信号
        output pe_switch_in;    // 权重切换信号
        output pe_enabled;      // PE 使能信号

        // ───────────────────────────────────────────────────────────────────────
        // Input 信号（DUT → testbench）
        // 这些是 DUT 的输出端口，testbench 需要采样它们
        // ───────────────────────────────────────────────────────────────────────
        input pe_psum_out;      // 部分和输出
        input pe_weight_out;    // 权重输出
        input pe_input_out;     // 激活值输出
        input pe_valid_out;     // 输出有效信号
        input pe_switch_out;    // 权重切换输出
    endclocking

    // ═══════════════════════════════════════════════════════════════════════════
    // 时钟生成 (10ns 周期 = 100MHz)
    // ═══════════════════════════════════════════════════════════════════════════

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ═══════════════════════════════════════════════════════════════════════════
    // FSDB 波形生成（用于 Verdi 调试）
    // ═══════════════════════════════════════════════════════════════════════════

    initial begin
        // 从 build/ 目录到 waveforms/ 需要两层 ../
        // build/ -> ../ -> vcs/ -> ../ -> sim/ -> waveforms/
        $display("═══════════════════════════════════════════════════════════════════");
        $display("🔍 [DEBUG] 开始配置FSDB波形dump");
        $display("═══════════════════════════════════════════════════════════════════");

        $fsdbDumpfile("../../waveforms/tb_pe.fsdb");
        $display("✅ [DEBUG] fsdbDumpfile 已调用");

        // 官方推荐语法：depth=0表示dump所有层次
        $fsdbDumpvars(0, tb_pe);
        $display("✅ [DEBUG] fsdbDumpvars(0, tb_pe) 已调用");
        $display("═══════════════════════════════════════════════════════════════════\n");
    end

    // ═══════════════════════════════════════════════════════════════════════════
    // 断言（Assertion）- 为 UVM 验证做准备
    // ═══════════════════════════════════════════════════════════════════════════

    // 断言1：复位期间输出应该为0
    // 注意：复位是同步复位，需要在复位后的下一个时钟周期检查
    property reset_output_zero;
        @(posedge clk) (rst) |=> (pe_psum_out == 0);
    endproperty
    assert property (reset_output_zero)
        else $error("[ASSERTION FAIL] 复位后输出不为0!");

    // 断言2：数据传播检查 - valid信号传播到输出
    // 注意：在脉动阵列中，valid可以连续多周期保持高电平，这是正常的
    property valid_propagation;
        @(posedge clk) disable iff (rst)
            pe_valid_in |-> ##1 pe_valid_out;
    endproperty
    assert property (valid_propagation)
        else $warning("[ASSERTION WARN] valid 信号未正确传播到输出!");

    // ═══════════════════════════════════════════════════════════════════════════
    // Q8.8 定点数转换函数
    // ═══════════════════════════════════════════════════════════════════════════

    function automatic logic [15:0] to_fixed(real val);
        return $signed($rtoi(val * 256.0)) & 16'hFFFF;
    endfunction

    function automatic real from_fixed(logic [15:0] val);
        logic signed [15:0] signed_val;
        signed_val = val;
        return $itor(signed_val) / 256.0;
    endfunction

    // ═══════════════════════════════════════════════════════════════════════════
    // 测试任务 - 使用 Clocking Block
    // ═══════════════════════════════════════════════════════════════════════════

    // ───────────────────────────────────────────────────────────────────────────
    // 任务：复位 DUT
    // 说明：
    //   - 复位信号 rst 不通过 clocking block，因为它需要立即生效
    //   - 其他信号通过 clocking block 驱动，确保时序正确
    //   - 使用非阻塞赋值（<=）驱动 clocking block 的输出信号
    // ───────────────────────────────────────────────────────────────────────────
    task automatic reset_dut();
        $display("[%0t] 🔄 复位 DUT", $time);

        // 其他信号通过 clocking block 驱动
        cb.pe_enabled <= 0;
        cb.pe_valid_in <= 0;
        cb.pe_accept_w_in <= 0;
        cb.pe_switch_in <= 0;
        cb.pe_input_in <= 16'h0000;
        cb.pe_weight_in <= 16'h0000;
        cb.pe_psum_in <= 16'h0000;

        // 等待1个时钟周期后再拉高复位
        @(cb);
        rst = 1;

        // 等待3个时钟周期
        repeat(3) @(cb);

        // 释放复位（延迟一拍）
        @(cb);
        rst = 0;
        cb.pe_enabled <= 1;

        // 等待1个时钟周期
        @(cb);

        $display("[%0t] ✅ 复位完成\n", $time);
    endtask

    // ───────────────────────────────────────────────────────────────────────────
    // 任务：加载权重到后台寄存器
    // 说明：
    //   - 使用 clocking block 驱动信号，自动处理时序
    //   - cb.signal <= value: 在时钟边沿后 #1step 驱动信号
    //   - @(cb): 等待一个时钟周期
    //   - 必须使用非阻塞赋值（<=）
    //
    // 时序：
    //   T0: 驱动 pe_accept_w_in=1, pe_weight_in=weight_val
    //   T0+1step: 信号实际变化
    //   T1: DUT 在时钟边沿采样信号
    //   T1: 驱动 pe_accept_w_in=0
    //   T1+1step: 信号实际变化
    //   T2: 完成
    // ───────────────────────────────────────────────────────────────────────────
    task automatic load_weight(real weight_val);
        $display("[%0t] 📥 加载权重: %.2f", $time, weight_val);

        // 通过 clocking block 驱动信号（非阻塞赋值）
        cb.pe_accept_w_in <= 1;
        cb.pe_weight_in <= to_fixed(weight_val);

        // 等待一个时钟周期（DUT 采样信号）
        @(cb);

        // 清除 accept 信号
        cb.pe_accept_w_in <= 0;

        // 再等待一个时钟周期（确保信号稳定）
        @(cb);

        $display("[%0t] ✅ 权重已加载到后台寄存器", $time);
    endtask

    // ───────────────────────────────────────────────────────────────────────────
    // 任务：切换权重（后台寄存器 → 前台寄存器）
    // 说明：
    //   - 使用 clocking block 驱动 pe_switch_in 信号
    //   - 权重切换需要1个时钟周期完成（纯时序逻辑）
    //
    // 时序：
    //   T0: 驱动 pe_switch_in=1
    //   T1: DUT 采样信号，执行切换
    //   T1: 驱动 pe_switch_in=0
    //   T2: 切换完成
    // ───────────────────────────────────────────────────────────────────────────
    task automatic switch_weight();
        $display("[%0t] 🔄 切换权重（后台→前台）", $time);

        // 驱动切换信号
        cb.pe_switch_in <= 1;

        // 等待一个时钟周期（DUT 执行切换）
        @(cb);

        // 清除切换信号
        cb.pe_switch_in <= 0;

        // 等待切换完成（纯时序逻辑需要1周期）
        @(cb);

        $display("[%0t] ✅ 权重切换完成", $time);
    endtask

    // ───────────────────────────────────────────────────────────────────────────
    // 任务：MAC 运算验证
    // 说明：
    //   - 使用 clocking block 驱动输入和采样输出
    //   - 驱动输入：cb.signal <= value（非阻塞赋值）
    //   - 采样输出：value = cb.signal（阻塞赋值）
    //   - PE 的流水线延迟是 1 个时钟周期
    //
    // 时序：
    //   T0: 驱动输入信号（pe_input_in, pe_psum_in, pe_valid_in=1）
    //   T0+1step: 信号实际变化
    //   T1: DUT 在时钟边沿采样输入，开始计算
    //   T1: 等待一个时钟周期
    //   T2-1step: clocking block 自动采样输出
    //   T2: 读取采样的输出值
    //   T2: 清除 valid 信号
    // ───────────────────────────────────────────────────────────────────────────
    task automatic mac_operation(
        input real input_val,
        input real psum_val,
        input real expected_out,
        input string test_name
    );
        real actual_out;
        real error;

        test_count++;
        $display("[%0t] 🧮 MAC 运算 [%s]: %.2f * weight + %.2f",
                 $time, test_name, input_val, psum_val);

        // 通过 clocking block 驱动输入信号（非阻塞赋值）
        cb.pe_input_in <= to_fixed(input_val);
        cb.pe_psum_in <= to_fixed(psum_val);
        cb.pe_valid_in <= 1;

        // 等待一个时钟周期（T1: DUT 采样输入）
        @(cb);

        // 等待一个时钟周期（T2: DUT 输出结果，流水线延迟=1）
        @(cb);

        // 通过 clocking block 采样输出（阻塞赋值）
        // 注意：clocking block 已经在 T2-1step 自动采样了输出
        actual_out = from_fixed(cb.pe_psum_out);
        error = $abs(actual_out - expected_out);

        // 清除 valid 信号
        cb.pe_valid_in <= 0;

        $display("[%0t] 📊 期望: %.4f, 实际: %.4f, 误差: %.4f (0x%04h)",
                 $time, expected_out, actual_out, error, cb.pe_psum_out);

        // Q8.8 定点数精度约为 1/256 ≈ 0.0039
        // 考虑到乘法累积误差，设置容差为 0.02（约5个LSB）
        if (error < 0.02) begin
            $display("[%0t] ✅ PASS\n", $time);
            pass_count++;
        end else begin
            $display("[%0t] ❌ FAIL - 误差超出容差范围!\n", $time);
            fail_count++;
        end
    endtask

    // ═══════════════════════════════════════════════════════════════════════════
    // 随机测试任务（为 UVM 做准备）
    // ═══════════════════════════════════════════════════════════════════════════
    task automatic random_mac_test(input int num_tests, input real weight_val);
        real rand_input, rand_psum, expected;
        int seed = $urandom();  // 随机种子

        $display("[%0t] 🎲 开始随机测试 (%0d 次)", $time, num_tests);
        $display("[%0t] 🔑 随机种子: %0d", $time, seed);

        load_weight(weight_val);
        switch_weight();

        for (int i = 0; i < num_tests; i++) begin
            // 生成随机数（范围：-2.0 ~ 2.0）
            // 限制范围以避免超出 Q8.8 表示范围（-128 ~ 127.996）
            // 对于 weight=1.5，最大输出约为 2.0*1.5+2.0=5.0，安全范围内
            rand_input = ($urandom_range(0, 400) - 200) / 100.0;
            rand_psum = ($urandom_range(0, 400) - 200) / 100.0;

            // 计算期望值
            expected = rand_input * weight_val + rand_psum;

            // 检查是否超出 Q8.8 表示范围
            if (expected > 127.0 || expected < -128.0) begin
                $display("[%0t] ⚠️  跳过测试-%0d: 期望值 %.4f 超出 Q8.8 范围",
                         $time, i+1, expected);
                continue;
            end

            // 执行 MAC 运算
            mac_operation(rand_input, rand_psum, expected,
                         $sformatf("随机测试-%0d", i+1));
        end

        $display("[%0t] ✅ 随机测试完成\n", $time);
    endtask

    // ═══════════════════════════════════════════════════════════════════════════
    // 主测试流程
    // ═══════════════════════════════════════════════════════════════════════════

    initial begin
        $display("═══════════════════════════════════════════════════════════════════");
        $display("🧪 PE Module Testbench - Professional Version");
        $display("═══════════════════════════════════════════════════════════════════");
        $display("测试内容:");
        $display("  1. 权重加载到后台寄存器");
        $display("  2. 权重切换到前台寄存器");
        $display("  3. MAC 运算验证 (5个定向测试)");
        $display("  4. 随机测试 (%0d 次)", random_test_num);
        $display("  5. 断言检查（Assertion）");
        $display("═══════════════════════════════════════════════════════════════════\n");

        // ═══════════════════════════════════════════════════════════════════════
        // Test 1: 基础 MAC 运算
        // ═══════════════════════════════════════════════════════════════════════
        $display("[Test 1] 基础 MAC 运算");
        $display("───────────────────────────────────────────────────────────────────");

        reset_dut();
        load_weight(2.0);
        switch_weight();
        mac_operation(3.0, 1.0, 7.0, "基础运算");

        // ═══════════════════════════════════════════════════════════════════════
        // Test 2: 零值测试
        // ═══════════════════════════════════════════════════════════════════════
        $display("[Test 2] 零值测试");
        $display("───────────────────────────────────────────────────────────────────");

        reset_dut();
        load_weight(0.0);
        switch_weight();
        mac_operation(5.0, 0.0, 0.0, "零权重");

        // ═══════════════════════════════════════════════════════════════════════
        // Test 3: 负数测试
        // ═══════════════════════════════════════════════════════════════════════
        $display("[Test 3] 负数测试");
        $display("───────────────────────────────────────────────────────────────────");

        reset_dut();
        load_weight(-1.5);
        switch_weight();
        mac_operation(2.0, 4.0, 1.0, "负权重");

        // ═══════════════════════════════════════════════════════════════════════
        // Test 4: 小数精度测试
        // ═══════════════════════════════════════════════════════════════════════
        $display("[Test 4] 小数精度测试");
        $display("───────────────────────────────────────────────────────────────────");

        reset_dut();
        load_weight(0.5);
        switch_weight();
        mac_operation(1.25, 0.25, 0.875, "小数精度");

        // ═══════════════════════════════════════════════════════════════════════
        // Test 5: 连续 MAC 运算
        // ═══════════════════════════════════════════════════════════════════════
        $display("[Test 6] 连续 MAC 运算");
        $display("───────────────────────────────────────────────────────────────────");

        reset_dut();
        load_weight(1.0);
        switch_weight();
        mac_operation(1.0, 0.0, 1.0, "连续-1");
        mac_operation(2.0, 0.0, 2.0, "连续-2");
        mac_operation(3.0, 0.0, 3.0, "连续-3");

        // ═══════════════════════════════════════════════════════════════════════
        // Test 6: 随机测试（新增！）
        // ═══════════════════════════════════════════════════════════════════════
        $display("[Test 6] 随机测试");
        $display("───────────────────────────────────────────────────────────────────");

        reset_dut();
        random_mac_test(random_test_num, 1.5);  // 权重=1.5，运行10次随机测试

        // ═══════════════════════════════════════════════════════════════════════
        // 测试完成 - 打印统计信息
        // ═══════════════════════════════════════════════════════════════════════

        repeat(10) @(posedge clk);

        $display("═══════════════════════════════════════════════════════════════════");
        $display("📊 测试统计");
        $display("═══════════════════════════════════════════════════════════════════");
        $display("  总测试数: %0d", test_count);
        $display("  通过数:   %0d", pass_count);
        $display("  失败数:   %0d", fail_count);
        $display("  通过率:   %.1f%%", (pass_count * 100.0) / test_count);
        $display("═══════════════════════════════════════════════════════════════════");

        if (fail_count == 0) begin
            $display("✅ 所有测试通过!");
            $display("═══════════════════════════════════════════════════════════════════\n");
            $finish(0);  // 返回 0 表示成功
        end else begin
            $display("❌ 有 %0d 个测试失败!", fail_count);
            $display("═══════════════════════════════════════════════════════════════════\n");
            $finish(1);  // 返回 1 表示失败
        end
    end

    // ═══════════════════════════════════════════════════════════════════════════
    // 超时保护
    // ═══════════════════════════════════════════════════════════════════════════

    initial begin
        #10000;  // 10us 超时
        $display("\n❌ 测试超时!");
        $display("═══════════════════════════════════════════════════════════════════\n");
        $finish(2);  // 返回 2 表示超时
    end

endmodule

`default_nettype wire
