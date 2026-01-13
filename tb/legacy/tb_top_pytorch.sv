`timescale 1ns/1ps

module tb_top_pytorch;

    logic clk, reset;
    logic start;
    logic done;

    logic        in_a_valid;
    logic [31:0] in_a_data;
    logic        in_a_ready;

    logic        in_b_valid;
    logic [31:0] in_b_data;
    logic        in_b_ready;

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
        .c00(c00), .c01(c01), .c02(c02), .c03(c03),
        .c10(c10), .c11(c11), .c12(c12), .c13(c13),
        .c20(c20), .c21(c21), .c22(c22), .c23(c23),
        .c30(c30), .c31(c31), .c32(c32), .c33(c33)
    );

    always #5 clk = ~clk;

    integer fd, r, i;
    integer expC [0:15];
    reg [31:0] ahex, bhex;

    task push_word(input [31:0] a_word, input [31:0] b_word);
    begin
        // wait until both FIFOs can accept
        while (!(in_a_ready && in_b_ready)) @(posedge clk);

        in_a_valid = 1; in_a_data = a_word;
        in_b_valid = 1; in_b_data = b_word;
        @(posedge clk);

        in_a_valid = 0; in_a_data = 32'h0;
        in_b_valid = 0; in_b_data = 32'h0;
    end
    endtask

    task check_C;
    begin
        if (c00 !== expC[0])  $fatal(1, "C00 mismatch got %0d exp %0d", c00, expC[0]);
        if (c01 !== expC[1])  $fatal(1, "C01 mismatch got %0d exp %0d", c01, expC[1]);
        if (c02 !== expC[2])  $fatal(1, "C02 mismatch got %0d exp %0d", c02, expC[2]);
        if (c03 !== expC[3])  $fatal(1, "C03 mismatch got %0d exp %0d", c03, expC[3]);

        if (c10 !== expC[4])  $fatal(1, "C10 mismatch got %0d exp %0d", c10, expC[4]);
        if (c11 !== expC[5])  $fatal(1, "C11 mismatch got %0d exp %0d", c11, expC[5]);
        if (c12 !== expC[6])  $fatal(1, "C12 mismatch got %0d exp %0d", c12, expC[6]);
        if (c13 !== expC[7])  $fatal(1, "C13 mismatch got %0d exp %0d", c13, expC[7]);

        if (c20 !== expC[8])  $fatal(1, "C20 mismatch got %0d exp %0d", c20, expC[8]);
        if (c21 !== expC[9])  $fatal(1, "C21 mismatch got %0d exp %0d", c21, expC[9]);
        if (c22 !== expC[10]) $fatal(1, "C22 mismatch got %0d exp %0d", c22, expC[10]);
        if (c23 !== expC[11]) $fatal(1, "C23 mismatch got %0d exp %0d", c23, expC[11]);

        if (c30 !== expC[12]) $fatal(1, "C30 mismatch got %0d exp %0d", c30, expC[12]);
        if (c31 !== expC[13]) $fatal(1, "C31 mismatch got %0d exp %0d", c31, expC[13]);
        if (c32 !== expC[14]) $fatal(1, "C32 mismatch got %0d exp %0d", c32, expC[14]);
        if (c33 !== expC[15]) $fatal(1, "C33 mismatch got %0d exp %0d", c33, expC[15]);
    end
    endtask

    initial begin
        $dumpfile("sim/top_pytorch.vcd");
        $dumpvars(0, tb_top_pytorch);

        clk = 0;
        reset = 1;
        start = 0;

        in_a_valid = 0; in_a_data = 0;
        in_b_valid = 0; in_b_data = 0;

        repeat (3) @(posedge clk);
        reset = 0;

        fd = $fopen("stream_vectors.txt", "r");
        if (fd == 0) $fatal(1, "Could not open stream_vectors.txt");

        // ---- READ EXACTLY 12 HEX PAIRS (no skipping) ----
        for (i = 0; i < 12; i = i + 1) begin
            r = $fscanf(fd, "%h %h\n", ahex, bhex);
            if (r != 2) $fatal(1, "Bad stream HEX line %0d (need 'HEX HEX')", i);
            push_word(ahex, bhex);
        end

        // ---- READ EXACTLY 16 EXPECTED INTS ----
        for (i = 0; i < 16; i = i + 1) begin
            r = $fscanf(fd, "%d\n", expC[i]);
            if (r != 1) $fatal(1, "Bad expected C int line %0d", i);
        end

        $fclose(fd);

        // Start controller AFTER preload
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait (done == 1);
        @(posedge clk);

        check_C();

        $display("PASS: top (FIFO+controller+sa4x4) matches expected C.");
        $finish;
    end

endmodule
