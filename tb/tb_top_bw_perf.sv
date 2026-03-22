`timescale 1ns/1ps

module tb_top_bw_perf;

    localparam int N = 4;
    localparam int FEED_WORDS = 12;
    localparam int FLUSH_CYCLES = 4; // Must match top/controller instantiation.
    localparam int WORKLOAD_MACS = N * N * FEED_WORDS;
    localparam int MAX_WAIT_CYCLES = 5000;

    logic clk, reset;
    logic start;
    logic done;

    logic        in_a_valid;
    logic [31:0] in_a_data;
    logic        in_a_ready;

    logic        in_b_valid;
    logic [31:0] in_b_data;
    logic        in_b_ready;

    logic [31:0] total_feed_cycles;
    logic [31:0] active_feed_cycles;
    logic [31:0] stall_feed_cycles;

    logic signed [31:0] c00, c01, c02, c03,
                        c10, c11, c12, c13,
                        c20, c21, c22, c23,
                        c30, c31, c32, c33;

    top dut (
        .clk(clk),
        .reset(reset),
        .in_a_valid(in_a_valid),
        .in_a_data(in_a_data),
        .in_a_ready(in_a_ready),
        .in_b_valid(in_b_valid),
        .in_b_data(in_b_data),
        .in_b_ready(in_b_ready),
        .start(start),
        .done(done),
        .total_feed_cycles(total_feed_cycles),
        .active_feed_cycles(active_feed_cycles),
        .stall_feed_cycles(stall_feed_cycles),
        .c00(c00), .c01(c01), .c02(c02), .c03(c03),
        .c10(c10), .c11(c11), .c12(c12), .c13(c13),
        .c20(c20), .c21(c21), .c22(c22), .c23(c23),
        .c30(c30), .c31(c31), .c32(c32), .c33(c33)
    );

    always #5 clk = ~clk;

    reg [31:0] Awords [0:FEED_WORDS-1];
    reg [31:0] Bwords [0:FEED_WORDS-1];
    reg [31:0] Cexp_u [0:15];

    integer i;
    integer gap_cycles;
    integer preload_words;
    integer start_delay_cycles;
    integer csv_fd;

    reg [8*64-1:0] case_name;
    reg [8*256-1:0] csv_path;

    function automatic integer s32(input reg [31:0] x);
        s32 = $signed(x);
    endfunction

    task automatic push_word_pair(input [31:0] a_word, input [31:0] b_word);
    begin
        while (!(in_a_ready && in_b_ready)) @(posedge clk);
        in_a_data  <= a_word;
        in_b_data  <= b_word;
        in_a_valid <= 1'b1;
        in_b_valid <= 1'b1;
        @(posedge clk);
        in_a_valid <= 1'b0;
        in_b_valid <= 1'b0;
        in_a_data  <= 32'h0;
        in_b_data  <= 32'h0;
    end
    endtask

    task automatic stream_from_idx(input integer first_idx);
        integer idx;
        integer g;
    begin
        for (idx = first_idx; idx < FEED_WORDS; idx = idx + 1) begin
            push_word_pair(Awords[idx], Bwords[idx]);
            for (g = 0; g < gap_cycles; g = g + 1) @(posedge clk);
        end
    end
    endtask

    task check_C;
        integer exp0;
    begin
        exp0 = s32(Cexp_u[0]);
        if (c00 !== exp0) $fatal(1, "C00 mismatch got %0d exp %0d", c00, exp0);
        if (c01 !== s32(Cexp_u[1]))  $fatal(1, "C01 mismatch got %0d exp %0d", c01, s32(Cexp_u[1]));
        if (c02 !== s32(Cexp_u[2]))  $fatal(1, "C02 mismatch got %0d exp %0d", c02, s32(Cexp_u[2]));
        if (c03 !== s32(Cexp_u[3]))  $fatal(1, "C03 mismatch got %0d exp %0d", c03, s32(Cexp_u[3]));

        if (c10 !== s32(Cexp_u[4]))  $fatal(1, "C10 mismatch got %0d exp %0d", c10, s32(Cexp_u[4]));
        if (c11 !== s32(Cexp_u[5]))  $fatal(1, "C11 mismatch got %0d exp %0d", c11, s32(Cexp_u[5]));
        if (c12 !== s32(Cexp_u[6]))  $fatal(1, "C12 mismatch got %0d exp %0d", c12, s32(Cexp_u[6]));
        if (c13 !== s32(Cexp_u[7]))  $fatal(1, "C13 mismatch got %0d exp %0d", c13, s32(Cexp_u[7]));

        if (c20 !== s32(Cexp_u[8]))  $fatal(1, "C20 mismatch got %0d exp %0d", c20, s32(Cexp_u[8]));
        if (c21 !== s32(Cexp_u[9]))  $fatal(1, "C21 mismatch got %0d exp %0d", c21, s32(Cexp_u[9]));
        if (c22 !== s32(Cexp_u[10])) $fatal(1, "C22 mismatch got %0d exp %0d", c22, s32(Cexp_u[10]));
        if (c23 !== s32(Cexp_u[11])) $fatal(1, "C23 mismatch got %0d exp %0d", c23, s32(Cexp_u[11]));

        if (c30 !== s32(Cexp_u[12])) $fatal(1, "C30 mismatch got %0d exp %0d", c30, s32(Cexp_u[12]));
        if (c31 !== s32(Cexp_u[13])) $fatal(1, "C31 mismatch got %0d exp %0d", c31, s32(Cexp_u[13]));
        if (c32 !== s32(Cexp_u[14])) $fatal(1, "C32 mismatch got %0d exp %0d", c32, s32(Cexp_u[14]));
        if (c33 !== s32(Cexp_u[15])) $fatal(1, "C33 mismatch got %0d exp %0d", c33, s32(Cexp_u[15]));
    end
    endtask

    initial begin
        real util_feed_pct;
        real stall_pct;
        real tput_feed_macs_per_cycle;
        real tput_exec_macs_per_cycle;
        real macs_per_input_byte;
        integer input_bytes;
        integer exec_cycles;

        $dumpfile("sim/top_bw_perf.vcd");
        $dumpvars(0, tb_top_bw_perf);

        clk = 0;
        reset = 1;
        start = 0;
        in_a_valid = 0; in_a_data = 0;
        in_b_valid = 0; in_b_data = 0;

        gap_cycles = 0;
        preload_words = 0;
        start_delay_cycles = 0;
        case_name = "unnamed";
        csv_path = "";

        void'($value$plusargs("GAP=%d", gap_cycles));
        void'($value$plusargs("PRELOAD=%d", preload_words));
        void'($value$plusargs("START_DELAY=%d", start_delay_cycles));
        void'($value$plusargs("CASE=%s", case_name));

        if (preload_words < 0) preload_words = 0;
        if (preload_words > FEED_WORDS) preload_words = FEED_WORDS;
        if (gap_cycles < 0) gap_cycles = 0;
        if (start_delay_cycles < 0) start_delay_cycles = 0;
        if ((preload_words == 0) && (start_delay_cycles == 0)) begin
            start_delay_cycles = 1;
            $display("INFO: forcing START_DELAY=1 for PRELOAD=0 to avoid zero-buffer startup race.");
        end

        $readmemh("data/stream_a.memh", Awords);
        $readmemh("data/stream_b.memh", Bwords);
        $readmemh("data/exp_c.memh", Cexp_u);

        repeat (3) @(posedge clk);
        reset = 0;

        // Optional preload before kicking controller.
        for (i = 0; i < preload_words; i = i + 1) begin
            push_word_pair(Awords[i], Bwords[i]);
        end

        repeat (start_delay_cycles) @(posedge clk);
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // Stream remaining words while controller is running.
        if (preload_words < FEED_WORDS) begin
            fork
                stream_from_idx(preload_words);
            join_none
        end

        fork
            begin
                wait (done == 1);
            end
            begin
                repeat (MAX_WAIT_CYCLES) @(posedge clk);
                $fatal(1, "Timeout waiting for done. gap=%0d preload=%0d", gap_cycles, preload_words);
            end
        join_any
        disable fork;
        @(posedge clk);

        check_C();

        exec_cycles = total_feed_cycles + FLUSH_CYCLES;
        input_bytes = active_feed_cycles * 8; // 1 x 32b A word + 1 x 32b B word per active cycle.

        if (total_feed_cycles > 0) begin
            util_feed_pct = 100.0 * $itor(active_feed_cycles) / $itor(total_feed_cycles);
            stall_pct = 100.0 * $itor(stall_feed_cycles) / $itor(total_feed_cycles);
            tput_feed_macs_per_cycle = $itor(WORKLOAD_MACS) / $itor(total_feed_cycles);
        end else begin
            util_feed_pct = 0.0;
            stall_pct = 0.0;
            tput_feed_macs_per_cycle = 0.0;
        end

        if (exec_cycles > 0) begin
            tput_exec_macs_per_cycle = $itor(WORKLOAD_MACS) / $itor(exec_cycles);
        end else begin
            tput_exec_macs_per_cycle = 0.0;
        end

        if (input_bytes > 0) begin
            macs_per_input_byte = $itor(WORKLOAD_MACS) / $itor(input_bytes);
        end else begin
            macs_per_input_byte = 0.0;
        end

        $display("PERF_SUMMARY case=%0s gap=%0d preload=%0d feed_total=%0d active=%0d stall=%0d util_feed_pct=%0.2f stall_pct=%0.2f macs=%0d tput_feed_mac_per_cycle=%0.3f tput_exec_mac_per_cycle=%0.3f in_bytes=%0d macs_per_input_byte=%0.3f reuse_a=%0d reuse_b=%0d",
                 case_name, gap_cycles, preload_words,
                 total_feed_cycles, active_feed_cycles, stall_feed_cycles,
                 util_feed_pct, stall_pct, WORKLOAD_MACS,
                 tput_feed_macs_per_cycle, tput_exec_macs_per_cycle,
                 input_bytes, macs_per_input_byte, N, N);

        if ($value$plusargs("PERF_CSV=%s", csv_path)) begin
            csv_fd = $fopen(csv_path, "a");
            if (csv_fd == 0) begin
                $fatal(1, "Could not open PERF_CSV file: %0s", csv_path);
            end
            $fwrite(csv_fd,
                    "%0s,%0d,%0d,%0d,%0d,%0d,%0.2f,%0.2f,%0d,%0.3f,%0.3f,%0d,%0.3f,%0d,%0d\n",
                    case_name, gap_cycles, preload_words,
                    total_feed_cycles, active_feed_cycles, stall_feed_cycles,
                    util_feed_pct, stall_pct, WORKLOAD_MACS,
                    tput_feed_macs_per_cycle, tput_exec_macs_per_cycle,
                    input_bytes, macs_per_input_byte, N, N);
            $fclose(csv_fd);
        end

        $display("PASS: top bandwidth/perf characterization run completed.");
        $finish;
    end

endmodule
