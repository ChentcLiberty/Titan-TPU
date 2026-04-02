`timescale 1ns/1ps

module tb_vpu_ub_skid_stage;
    localparam int SYSTOLIC_ARRAY_WIDTH = 2;
    localparam int DATA_WIDTH = 16;

    logic clk;
    logic rst;
    logic [DATA_WIDTH-1:0] data_in [0:SYSTOLIC_ARRAY_WIDTH-1];
    logic valid_in [0:SYSTOLIC_ARRAY_WIDTH-1];
    logic ready_in;
    logic ready_out;
    logic [DATA_WIDTH-1:0] data_out [0:SYSTOLIC_ARRAY_WIDTH-1];
    logic valid_out [0:SYSTOLIC_ARRAY_WIDTH-1];
    logic fire_out;
    logic holding_out;
    logic overflow_out;

    vpu_ub_skid_stage #(
        .SYSTOLIC_ARRAY_WIDTH(SYSTOLIC_ARRAY_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .valid_in(valid_in),
        .ready_in(ready_in),
        .ready_out(ready_out),
        .data_out(data_out),
        .valid_out(valid_out),
        .fire_out(fire_out),
        .holding_out(holding_out),
        .overflow_out(overflow_out)
    );

    always #5 clk = ~clk;

    task automatic sample_after_clk;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        $fsdbDumpfile("../waves/handshake_unit.fsdb");
        $fsdbDumpvars(0, tb_vpu_ub_skid_stage);
    end

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        ready_in = 1'b0;
        data_in[0] = '0;
        data_in[1] = '0;
        valid_in[0] = 1'b0;
        valid_in[1] = 1'b0;

        repeat (2) @(posedge clk);
        rst = 1'b0;

        // First stalled beat should be held.
        @(negedge clk);
        data_in[0] = 16'h0101;
        data_in[1] = 16'h0202;
        valid_in[0] = 1'b1;
        valid_in[1] = 1'b1;

        sample_after_clk();
        if (holding_out !== 1'b1) begin
            $fatal(1, "handshake_unit: first stalled beat was not held");
        end
        if (data_out[0] !== 16'h0101 || data_out[1] !== 16'h0202) begin
            $fatal(1, "handshake_unit: held payload mismatch");
        end
        if (overflow_out !== 1'b0) begin
            $fatal(1, "handshake_unit: overflow should be low on first stalled beat");
        end

        // A waiting source beat may appear while ready_out=0, but it must be held stable.
        @(negedge clk);
        data_in[0] = 16'h0303;
        data_in[1] = 16'h0404;
        valid_in[0] = 1'b1;
        valid_in[1] = 1'b1;

        sample_after_clk();
        if (overflow_out !== 1'b0) begin
            $fatal(1, "handshake_unit: stable waiting beat should not trigger overflow");
        end
        if (data_out[0] !== 16'h0101 || data_out[1] !== 16'h0202) begin
            $fatal(1, "handshake_unit: held payload changed while source was waiting");
        end

        // Changing that blocked beat before ready returns is a real protocol violation.
        @(negedge clk);
        data_in[0] = 16'h0505;
        data_in[1] = 16'h0606;
        valid_in[0] = 1'b1;
        valid_in[1] = 1'b1;

        sample_after_clk();
        if (overflow_out !== 1'b1) begin
            $fatal(1, "handshake_unit: overflow did not assert when blocked input changed");
        end
        if (data_out[0] !== 16'h0101 || data_out[1] !== 16'h0202) begin
            $fatal(1, "handshake_unit: held payload changed during blocked-input overwrite");
        end

        // Release stall and check the held beat fires once.
        @(negedge clk);
        ready_in = 1'b1;
        valid_in[0] = 1'b0;
        valid_in[1] = 1'b0;

        @(posedge clk);
        if (fire_out !== 1'b1) begin
            $fatal(1, "handshake_unit: held beat did not fire when ready returned");
        end

        sample_after_clk();
        if (holding_out !== 1'b0) begin
            $fatal(1, "handshake_unit: hold state did not clear after release");
        end

        $display("handshake_unit: PASS");
        $finish;
    end
endmodule
