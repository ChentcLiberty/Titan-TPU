`timescale 1ns/1ps

module tb_gradient_descent;

    // 信号定义
    logic clk;
    logic rst;
    logic [15:0] lr_in;
    logic [15:0] value_old_in;
    logic [15:0] grad_in;
    logic grad_descent_valid_in;
    logic grad_bias_or_weight;
    logic [15:0] value_updated_out;
    logic grad_descent_done_out;

    // 定点数格式: Q8.8
    function automatic [15:0] real_to_fxp(input real val);
        return $signed(val * 256.0);
    endfunction

    function automatic real fxp_to_real(input [15:0] val);
        return $signed(val) / 256.0;
    endfunction

    // DUT 实例化
    gradient_descent dut (
        .clk(clk),
        .rst(rst),
        .lr_in(lr_in),
        .value_old_in(value_old_in),
        .grad_in(grad_in),
        .grad_descent_valid_in(grad_descent_valid_in),
        .grad_bias_or_weight(grad_bias_or_weight),
        .value_updated_out(value_updated_out),
        .grad_descent_done_out(grad_descent_done_out)
    );

    // 时钟生成
    initial clk = 0;
    always #5 clk = ~clk;

    // 测试变量
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;
    real tolerance = 0.02;

    // 偏置更新测试
    task automatic test_bias_update(
        input string test_name,
        input real old_val,
        input real lr,
        input real grad
    );
        real expected, actual;
        logic [15:0] result;

        test_count++;
        $display("\n[Test %0d] %s", test_count, test_name);
        $display("  old=%.4f, lr=%.4f, grad=%.4f", old_val, lr, grad);

        // 复位确保清零
        rst = 1;
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        // 设置输入
        value_old_in = real_to_fxp(old_val);
        lr_in = real_to_fxp(lr);
        grad_in = real_to_fxp(grad);
        grad_bias_or_weight = 1'b1;  // 偏置模式
        grad_descent_valid_in = 1'b1;

        @(posedge clk);
        @(posedge clk);
        result = value_updated_out;
        grad_descent_valid_in = 1'b0;

        expected = old_val - lr * grad;
        actual = fxp_to_real(result);

        $display("  期望: %.4f, 实际: %.4f", expected, actual);

        if ($abs(actual - expected) < tolerance) begin
            $display("  ✓ PASS");
            pass_count++;
        end else begin
            $display("  ✗ FAIL (误差=%.4f)", actual - expected);
            fail_count++;
        end
    endtask

    // 权重累积更新测试
    task automatic test_weight_accumulate(
        input string test_name,
        input real old_val,
        input real lr,
        input real grad1,
        input real grad2,
        input real grad3
    );
        real expected, actual;
        logic [15:0] result;

        test_count++;
        $display("\n[Test %0d] %s", test_count, test_name);
        $display("  old=%.4f, lr=%.4f", old_val, lr);
        $display("  梯度: [%.4f, %.4f, %.4f]", grad1, grad2, grad3);

        // 复位
        rst = 1;
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        // 设置输入
        value_old_in = real_to_fxp(old_val);
        lr_in = real_to_fxp(lr);
        grad_bias_or_weight = 1'b0;  // 权重模式

        // 第一次更新 - 此时 done=0，会使用 value_old_in
        grad_in = real_to_fxp(grad1);
        grad_descent_valid_in = 1'b1;
        $display("  [DEBUG] value_old_in=0x%04h, lr_in=0x%04h, grad_in=0x%04h", value_old_in, lr_in, grad_in);
        $display("  [DEBUG] grad_bias_or_weight=%b, done=%b", grad_bias_or_weight, grad_descent_done_out);
        $display("  [DEBUG] sub_in_a=0x%04h, mul_out=0x%04h, sub_value_out=0x%04h", dut.sub_in_a, dut.mul_out, dut.sub_value_out);
        @(posedge clk);  // done 变为 1
        $display("  [DEBUG] after clk1: done=%b, value_updated_out=0x%04h", grad_descent_done_out, value_updated_out);
        $display("  [DEBUG] after clk1: sub_in_a=0x%04h, mul_out=0x%04h", dut.sub_in_a, dut.mul_out);
        @(posedge clk);  // output 更新
        $display("  [DEBUG] after clk2: done=%b, value_updated_out=0x%04h", grad_descent_done_out, value_updated_out);
        $display("  第1次更新后: output=0x%04h (%.4f)", value_updated_out, fxp_to_real(value_updated_out));

        // 第二次更新 - 此时 done=1，会使用 value_updated_out
        grad_in = real_to_fxp(grad2);
        @(posedge clk);
        @(posedge clk);
        $display("  第2次更新后: output=0x%04h (%.4f)", value_updated_out, fxp_to_real(value_updated_out));

        // 第三次更新
        grad_in = real_to_fxp(grad3);
        @(posedge clk);
        @(posedge clk);
        $display("  第3次更新后: output=0x%04h (%.4f)", value_updated_out, fxp_to_real(value_updated_out));

        result = value_updated_out;
        grad_descent_valid_in = 1'b0;

        expected = old_val - lr * (grad1 + grad2 + grad3);
        actual = fxp_to_real(result);

        $display("  期望: %.4f, 实际: %.4f", expected, actual);

        if ($abs(actual - expected) < tolerance) begin
            $display("  ✓ PASS");
            pass_count++;
        end else begin
            $display("  ✗ FAIL (误差=%.4f)", actual - expected);
            fail_count++;
        end
    endtask

    // 主测试流程
    initial begin
        $display("========================================");
        $display("Gradient Descent Testbench (简化版)");
        $display("========================================");

        // 初始化
        rst = 1;
        lr_in = 0;
        value_old_in = 0;
        grad_in = 0;
        grad_descent_valid_in = 0;
        grad_bias_or_weight = 0;

        repeat(5) @(posedge clk);
        rst = 0;
        repeat(2) @(posedge clk);

        // 偏置更新测试
        test_bias_update("偏置基本更新", 1.0, 0.1, 0.5);
        test_bias_update("偏置负梯度", 1.0, 0.1, -2.0);
        test_bias_update("偏置负初始值", -1.5, 0.25, 0.5);
        test_bias_update("偏置零梯度", 3.0, 0.1, 0.0);

        // 权重累积更新测试
        test_weight_accumulate("权重累积更新", 10.0, 0.1, 1.0, 2.0, 1.5);
        test_weight_accumulate("权重小学习率累积", 5.0, 0.01, 0.5, 1.0, 0.5);

        // 复位测试
        test_count++;
        $display("\n[Test %0d] 复位测试", test_count);
        value_old_in = real_to_fxp(5.0);
        lr_in = real_to_fxp(0.1);
        grad_in = real_to_fxp(1.0);
        grad_descent_valid_in = 1'b1;
        @(posedge clk);
        rst = 1;
        @(posedge clk);
        rst = 0;
        grad_descent_valid_in = 1'b0;
        @(posedge clk);

        if (value_updated_out == 0 && grad_descent_done_out == 0) begin
            $display("  ✓ PASS");
            pass_count++;
        end else begin
            $display("  ✗ FAIL");
            fail_count++;
        end

        // 测试总结
        repeat(5) @(posedge clk);

        $display("\n========================================");
        $display("测试总结");
        $display("========================================");
        $display("总测试数: %0d", test_count);
        $display("通过: %0d", pass_count);
        $display("失败: %0d", fail_count);
        $display("========================================");

        if (fail_count == 0) begin
            $display("✓ 所有测试通过!");
        end else begin
            $display("✗ 有 %0d 个测试失败", fail_count);
        end

        $finish;
    end

    // 波形输出
    initial begin
        $fsdbDumpfile("tb_gradient_descent.fsdb");
        $fsdbDumpvars(0, tb_gradient_descent);
    end

endmodule
