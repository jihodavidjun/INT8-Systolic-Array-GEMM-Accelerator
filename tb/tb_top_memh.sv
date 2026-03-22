`timescale 1ns/1ps

module tb_top_memh;

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

    // mem files
    reg [31:0] Awords [0:11];
    reg [31:0] Bwords [0:11];
    reg [31:0] Cexp_u [0:15];
    integer i;

    function automatic integer s32(input reg [31:0] x);
        s32 = $signed(x);
    endfunction

    task automatic push_word(input [31:0] a_word, input [31:0] b_word);
    begin
        // ---- Push A ----
        while (!in_a_ready) @(posedge clk);
        in_a_data  <= a_word;
        in_a_valid <= 1'b1;
        @(posedge clk);             
        in_a_valid <= 1'b0;
        in_a_data  <= 32'h0;
        $display("preload i=%0d a_count=%0d b_count=%0d a_ready=%0b b_ready=%0b",
         i, dut.u_fifo_a.count, dut.u_fifo_b.count, in_a_ready, in_b_ready);

        // ---- Push B ----
        while (!in_b_ready) @(posedge clk);
        in_b_data  <= b_word;
        in_b_valid <= 1'b1;
        @(posedge clk);
        in_b_valid <= 1'b0;
        in_b_data  <= 32'h0;
        $display("preload i=%0d a_count=%0d b_count=%0d a_ready=%0b b_ready=%0b",
         i, dut.u_fifo_a.count, dut.u_fifo_b.count, in_a_ready, in_b_ready);

        @(posedge clk);
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
        $dumpfile("sim/top_memh.vcd");
        $dumpvars(0, tb_top_memh);

        clk = 0;
        reset = 1;
        start = 0;

        in_a_valid = 0; in_a_data = 0;
        in_b_valid = 0; in_b_data = 0;

        $readmemh("data/stream_a.memh", Awords);
        $readmemh("data/stream_b.memh", Bwords);
        $readmemh("data/exp_c.memh", Cexp_u);

        $display("A0 word = %h, B0 word = %h", Awords[0], Bwords[0]);

        repeat (3) @(posedge clk);
        reset = 0;

        // Preload 12 words
        for (i = 0; i < 12; i = i + 1) begin
            push_word(Awords[i], Bwords[i]);
        end

        $monitor("t=%0t pop=%0b en=%0b Aword=%h Bword=%h | a=%0d,%0d,%0d,%0d b=%0d,%0d,%0d,%0d",
         $time,
         dut.pop_a, dut.en_sa,
         dut.fifo_a_rd, dut.fifo_b_rd,
         dut.a0, dut.a1, dut.a2, dut.a3,
         dut.b0, dut.b1, dut.b2, dut.b3);

        // Confirm preload 
        $display("After preload: fifo_a_count=%0d fifo_b_count=%0d",
                 dut.u_fifo_a.count, dut.u_fifo_b.count);

        // Start controller
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
