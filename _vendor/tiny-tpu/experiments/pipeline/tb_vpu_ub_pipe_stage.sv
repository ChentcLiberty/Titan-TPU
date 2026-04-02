`timescale 1ns/1ps

module tb_vpu_ub_pipe_stage;
    localparam int SYSTOLIC_ARRAY_WIDTH = 2;
    localparam int DATA_WIDTH = 16;

    logic clk;
    logic rst;
    logic [DATA_WIDTH-1:0] data_in [0:SYSTOLIC_ARRAY_WIDTH-1];
    logic valid_in [0:SYSTOLIC_ARRAY_WIDTH-1];
    logic [DATA_WIDTH-1:0] data_out [0:SYSTOLIC_ARRAY_WIDTH-1];
    logic valid_out [0:SYSTOLIC_ARRAY_WIDTH-1];

    vpu_ub_pipe_stage #(
        .SYSTOLIC_ARRAY_WIDTH(SYSTOLIC_ARRAY_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .valid_in(valid_in),
        .data_out(data_out),
        .valid_out(valid_out)
    );

    always #5 clk = ~clk;

    task automatic sample_after_clk;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        $fsdbDumpfile("../waves/pipeline_unit.fsdb");
        $fsdbDumpvars(0, tb_vpu_ub_pipe_stage);
    end

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        data_in[0] = '0;
        data_in[1] = '0;
        valid_in[0] = 1'b0;
        valid_in[1] = 1'b0;

        repeat (2) @(posedge clk);
        rst = 1'b0;

        @(negedge clk);
        data_in[0] = 16'h0011;
        data_in[1] = 16'h0022;
        valid_in[0] = 1'b1;
        valid_in[1] = 1'b1;

        sample_after_clk();
        if (valid_out[0] !== 1'b1 || valid_out[1] !== 1'b1) begin
            $fatal(1, "pipeline_unit: valid did not assert after one cycle");
        end
        if (data_out[0] !== 16'h0011 || data_out[1] !== 16'h0022) begin
            $fatal(1, "pipeline_unit: data did not appear after one cycle");
        end

        @(negedge clk);
        data_in[0] = 16'h00AA;
        data_in[1] = 16'h00BB;
        valid_in[0] = 1'b1;
        valid_in[1] = 1'b0;

        sample_after_clk();
        if (data_out[0] !== 16'h00AA || data_out[1] !== 16'h00BB) begin
            $fatal(1, "pipeline_unit: back-to-back data propagation mismatch");
        end
        if (valid_out[0] !== 1'b1 || valid_out[1] !== 1'b0) begin
            $fatal(1, "pipeline_unit: back-to-back valid propagation mismatch");
        end

        sample_after_clk();
        $display("pipeline_unit: PASS");
        $finish;
    end
endmodule
