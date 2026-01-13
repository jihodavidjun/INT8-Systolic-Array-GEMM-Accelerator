// tb/tb_sa2x2.sv
`timescale 1ns/1ps

module tb_sa2x2;

    logic clk, reset, en;

    logic signed [7:0] a_row0_in, a_row1_in;
    logic signed [7:0] b_col0_in, b_col1_in;

    logic signed [31:0] c00, c01, c10, c11;

    sa2x2 dut (
        .clk(clk), .reset(reset), .en(en),
        .a_row0_in(a_row0_in), .a_row1_in(a_row1_in),
        .b_col0_in(b_col0_in), .b_col1_in(b_col1_in),
        .c00(c00), .c01(c01), .c10(c10), .c11(c11)
    );

    always #5 clk = ~clk; 

    task inject(
        input logic signed [7:0] a0,
        input logic signed [7:0] a1,
        input logic signed [7:0] b0,
        input logic signed [7:0] b1
    );
        begin
            a_row0_in = a0;
            a_row1_in = a1;
            b_col0_in = b0;
            b_col1_in = b1;
            @(posedge clk); #1;
        end
    endtask

    initial begin
        $dumpfile("sim/sa2x2.vcd");
        $dumpvars(0, tb_sa2x2);

        clk = 0; reset = 1; en = 0;
        a_row0_in = 0; a_row1_in = 0;
        b_col0_in = 0; b_col1_in = 0;

        repeat (3) @(posedge clk);
        reset = 0;

        @(posedge clk);
        en = 1;

        // Matrices:
        // A = [[1,2],[3,4]]
        // B = [[5,6],[7,8]]
        // Expected:
        // C00=19, C01=22, C10=43, C11=50

        // t=0
        inject(8'sd1, 8'sd0, 8'sd5, 8'sd0);

        // t=1
        inject(8'sd2, 8'sd3, 8'sd7, 8'sd6);

        // t=2
        inject(8'sd0, 8'sd4, 8'sd0, 8'sd8);

        // Flush
        inject(0,0,0,0);
        inject(0,0,0,0);

        // Hold and check
        en = 0;
        @(posedge clk); #1;

        if (c00 !== 32'sd19) $fatal(1, "c00 mismatch: got %0d exp 19", c00);
        if (c01 !== 32'sd22) $fatal(1, "c01 mismatch: got %0d exp 22", c01);
        if (c10 !== 32'sd43) $fatal(1, "c10 mismatch: got %0d exp 43", c10);
        if (c11 !== 32'sd50) $fatal(1, "c11 mismatch: got %0d exp 50", c11);

        $display("PASS: 2x2 systolic array computes A*B correctly (aligned schedule).");
        $finish;
    end

endmodule
