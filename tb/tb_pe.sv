// tb/tb_pe.sv
`timescale 1ns/1ps

module tb_pe;

    logic clk, reset, en;
    logic signed [7:0]  a_in, b_in;
    logic signed [7:0]  a_out, b_out;
    logic signed [31:0] acc_out;

    // DUT
    pe dut (
        .clk(clk),
        .reset(reset),
        .en(en),
        .a_in(a_in),
        .b_in(b_in),
        .a_out(a_out),
        .b_out(b_out),
        .acc_out(acc_out)
    );

    // 100MHz clock (10ns period)
    always #5 clk = ~clk;

    // Scoreboard
    logic signed [31:0] expected_acc;

    task drive(input logic signed [7:0] a, input logic signed [7:0] b);
        begin
            a_in = a;
            b_in = b;
        end
    endtask

    task step_and_check(input logic signed [7:0] a, input logic signed [7:0] b);
        begin
            drive(a, b);
            @(posedge clk); #1;

            expected_acc += (a * b);

            if (acc_out !== expected_acc)
                $fatal(1, "Mismatch: a=%0d b=%0d acc=%0d exp=%0d", a, b, acc_out, expected_acc);
        end
    endtask

    initial begin
        $dumpfile("sim/pe.vcd");
        $dumpvars(0, tb_pe);

        clk = 0;
        reset = 1;
        en = 0;
        a_in = 0;
        b_in = 0;
        expected_acc = 0;

        repeat (3) @(posedge clk);
        reset = 0;

        @(posedge clk);
        en = 1;

        // Test vectors (include negatives)
        step_and_check( 8'sd3,   8'sd4);     // +12
        step_and_check(-8'sd2,   8'sd7);     // -14
        step_and_check( 8'sd10, -8'sd10);    // -100
        step_and_check(-8'sd8,  -8'sd8);     // +64

        // Hold-state test
        en = 0;
        drive(8'sd100, 8'sd2);
        @(posedge clk); #1;
        if (acc_out !== expected_acc)
            $fatal(1, "Mismatch when en=0: acc=%0d exp=%0d", acc_out, expected_acc);

        $display("PASS: PE basic MAC + signed behavior verified.");
        $finish;
    end

endmodule
