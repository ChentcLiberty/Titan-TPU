`timescale 1ns/1ps

module tb_q8_8_saturation;
    logic [15:0] mul_a;
    logic [15:0] mul_b;
    logic [15:0] add_a;
    logic [15:0] add_b;
    logic [15:0] mul_out;
    logic mul_overflow;
    logic [15:0] add_out;
    logic add_overflow;

    fxp_mul mul_dut (
        .ina(mul_a),
        .inb(mul_b),
        .out(mul_out),
        .overflow(mul_overflow)
    );

    fxp_add add_dut (
        .ina(add_a),
        .inb(add_b),
        .out(add_out),
        .overflow(add_overflow)
    );

    initial begin
        $fsdbDumpfile("../waves/overflow_unit.fsdb");
        $fsdbDumpvars(0, tb_q8_8_saturation);
    end

    initial begin
        // 80.0 * 2.0 = 160.0 -> should saturate to positive max in Q8.8.
        mul_a = 16'h5000;
        mul_b = 16'h0200;
        // 100.0 + 50.0 = 150.0 -> should also saturate.
        add_a = 16'h6400;
        add_b = 16'h3200;
        #1;

        if (mul_overflow !== 1'b1) begin
            $fatal(1, "overflow_unit: multiply overflow flag did not assert");
        end
        if (mul_out !== 16'h7FFF) begin
            $fatal(1, "overflow_unit: multiply did not saturate to positive max");
        end
        if (add_overflow !== 1'b1) begin
            $fatal(1, "overflow_unit: add overflow flag did not assert");
        end
        if (add_out !== 16'h7FFF) begin
            $fatal(1, "overflow_unit: add did not saturate to positive max");
        end

        // -100.0 * 2.0 = -200.0 -> should saturate to negative min.
        mul_a = 16'h9C00;
        mul_b = 16'h0200;
        #1;

        if (mul_overflow !== 1'b1) begin
            $fatal(1, "overflow_unit: negative multiply overflow flag did not assert");
        end
        if (mul_out !== 16'h8000) begin
            $fatal(1, "overflow_unit: negative multiply did not saturate to negative min");
        end

        $display("overflow_unit: PASS");
        $finish;
    end
endmodule
