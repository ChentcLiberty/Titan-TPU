`timescale 1ns/1ps

module tb_vpu_ub_skid_stage_random;
    localparam int SYSTOLIC_ARRAY_WIDTH = 2;
    localparam int DATA_WIDTH = 16;
    localparam int NUM_BEATS = 16;
    localparam int MAX_CYCLES = 200;

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

    logic [DATA_WIDTH-1:0] exp_data_0 [0:NUM_BEATS-1];
    logic [DATA_WIDTH-1:0] exp_data_1 [0:NUM_BEATS-1];
    logic [31:0] lfsr;

    integer send_idx;
    integer recv_idx;
    integer cycle_count;
    integer hold_cycles;
    integer stall_cycles;
    integer fire_cycles;

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

    function automatic logic [31:0] lfsr_step(input logic [31:0] cur);
        lfsr_step = {cur[30:0], cur[31] ^ cur[21] ^ cur[1] ^ cur[0]};
    endfunction

    function automatic logic ready_jitter(input integer cyc, input logic [31:0] cur);
        logic forced_low;
        logic pseudo_low;
        begin
            forced_low = ((cyc % 4) == 1);
            pseudo_low = !(cur[0] | cur[2]);
            ready_jitter = !(forced_low || pseudo_low);
        end
    endfunction

    task automatic drive_source;
        begin
            if (send_idx < NUM_BEATS) begin
                data_in[0] = exp_data_0[send_idx];
                data_in[1] = exp_data_1[send_idx];
                valid_in[0] = 1'b1;
                valid_in[1] = 1'b1;
            end else begin
                data_in[0] = '0;
                data_in[1] = '0;
                valid_in[0] = 1'b0;
                valid_in[1] = 1'b0;
            end
        end
    endtask

    initial begin
        $fsdbDumpfile("../waves/handshake_random_unit.fsdb");
        $fsdbDumpvars(0, tb_vpu_ub_skid_stage_random);
    end

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        ready_in = 1'b1;
        data_in[0] = '0;
        data_in[1] = '0;
        valid_in[0] = 1'b0;
        valid_in[1] = 1'b0;
        lfsr = 32'h1ACE_B00C;

        send_idx = 0;
        recv_idx = 0;
        cycle_count = 0;
        hold_cycles = 0;
        stall_cycles = 0;
        fire_cycles = 0;

        for (int i = 0; i < NUM_BEATS; i++) begin
            exp_data_0[i] = 16'h1100 + i;
            exp_data_1[i] = 16'h2200 + (i * 16'h0003);
        end

        repeat (2) @(posedge clk);
        rst = 1'b0;
    end

    initial begin
        wait (rst == 1'b0);

        @(negedge clk);
        drive_source();

        forever begin
            @(negedge clk);
            cycle_count = cycle_count + 1;

            if (send_idx == NUM_BEATS && recv_idx < NUM_BEATS) begin
                ready_in = 1'b1;
            end else begin
                lfsr = lfsr_step(lfsr);
                ready_in = ready_jitter(cycle_count, lfsr);
            end

            drive_source();
        end
    end

    initial begin
        logic src_accept;
        logic sink_fire;
        logic [DATA_WIDTH-1:0] fired_data_0;
        logic [DATA_WIDTH-1:0] fired_data_1;

        wait (rst == 1'b0);

        forever begin
            @(posedge clk);
            src_accept = valid_in[0] && ready_out;
            sink_fire = fire_out;
            fired_data_0 = data_out[0];
            fired_data_1 = data_out[1];

            if (sink_fire) begin
                if (recv_idx >= NUM_BEATS) begin
                    $fatal(1, "handshake_random_unit: received more beats than expected");
                end
                if (fired_data_0 !== exp_data_0[recv_idx] || fired_data_1 !== exp_data_1[recv_idx]) begin
                    $fatal(1, "handshake_random_unit: fired payload mismatch at beat %0d", recv_idx);
                end
                recv_idx = recv_idx + 1;
                fire_cycles = fire_cycles + 1;
            end

            if (src_accept) begin
                if (send_idx >= NUM_BEATS) begin
                    $fatal(1, "handshake_random_unit: source accepted more beats than expected");
                end
                send_idx = send_idx + 1;
            end

            #1;

            if (overflow_out !== 1'b0) begin
                $fatal(1, "handshake_random_unit: overflow asserted even though source obeyed ready_out");
            end

            if (holding_out) begin
                hold_cycles = hold_cycles + 1;

                if (send_idx <= recv_idx) begin
                    $fatal(1, "handshake_random_unit: hold state without an outstanding beat");
                end
                if (data_out[0] !== exp_data_0[recv_idx] || data_out[1] !== exp_data_1[recv_idx]) begin
                    $fatal(1, "handshake_random_unit: held payload mismatch at beat %0d", recv_idx);
                end
                if (valid_out[0] !== 1'b1 || valid_out[1] !== 1'b1) begin
                    $fatal(1, "handshake_random_unit: valid_out dropped while holding data");
                end
                if (!ready_in) begin
                    stall_cycles = stall_cycles + 1;
                end
            end

            if (send_idx == NUM_BEATS && recv_idx == NUM_BEATS && !holding_out) begin
                if (hold_cycles == 0 || stall_cycles == 0) begin
                    $fatal(1, "handshake_random_unit: random ready did not create a real hold/stall scenario");
                end

                $display(
                    "handshake_random_unit: PASS sends=%0d fires=%0d hold_cycles=%0d stall_cycles=%0d final_lfsr=0x%08h",
                    send_idx,
                    fire_cycles,
                    hold_cycles,
                    stall_cycles,
                    lfsr
                );
                $finish;
            end
        end
    end

    initial begin
        wait (rst == 1'b0);
        repeat (MAX_CYCLES) @(posedge clk);
        $fatal(1, "handshake_random_unit: timeout send_idx=%0d recv_idx=%0d", send_idx, recv_idx);
    end
endmodule
