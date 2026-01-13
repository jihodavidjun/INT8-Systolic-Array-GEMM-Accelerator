`timescale 1ns/1ps

module top #(
    parameter int FIFO_DEPTH = 32
)(
    input  logic clk,
    input  logic reset,

    input  logic        in_a_valid,
    input  logic [31:0] in_a_data,
    output logic        in_a_ready,

    input  logic        in_b_valid,
    input  logic [31:0] in_b_data,
    output logic        in_b_ready,

    input  logic start,
    output logic done,

    output logic signed [31:0] c00, c01, c02, c03,
                               c10, c11, c12, c13,
                               c20, c21, c22, c23,
                               c30, c31, c32, c33
);

    logic fifo_a_full, fifo_a_empty;
    logic fifo_b_full, fifo_b_empty;
    logic [31:0] fifo_a_rd, fifo_b_rd;

    logic pop_a, pop_b, en_sa, done_raw;

    assign in_a_ready = !fifo_a_full;
    assign in_b_ready = !fifo_b_full;

    fifo #(.WIDTH(32), .DEPTH(FIFO_DEPTH)) u_fifo_a (
        .clk(clk), .reset(reset),
        .wr_en(in_a_valid && in_a_ready),
        .wr_data(in_a_data),
        .full(fifo_a_full),
        .rd_en(pop_a),
        .rd_data(fifo_a_rd),
        .empty(fifo_a_empty),
        .count()
    );

    fifo #(.WIDTH(32), .DEPTH(FIFO_DEPTH)) u_fifo_b (
        .clk(clk), .reset(reset),
        .wr_en(in_b_valid && in_b_ready),
        .wr_data(in_b_data),
        .full(fifo_b_full),
        .rd_en(pop_b),
        .rd_data(fifo_b_rd),
        .empty(fifo_b_empty),
        .count()
    );

    controller #(
        .FEED_CYCLES(12),
        .FLUSH_CYCLES(4)
    ) u_ctrl (
        .clk(clk),
        .reset(reset),
        .start(start),
        .fifo_a_empty(fifo_a_empty),
        .fifo_b_empty(fifo_b_empty),
        .pop_a(pop_a),
        .pop_b(pop_b),
        .en_sa(en_sa),
        .done(done_raw)
    );

    localparam bit MSB_FIRST = 1;

    logic signed [7:0] a0, a1, a2, a3;
    logic signed [7:0] b0, b1, b2, b3;

    always @* begin
        a0 = '0; a1 = '0; a2 = '0; a3 = '0;
        b0 = '0; b1 = '0; b2 = '0; b3 = '0;

        if (pop_a && pop_b) begin
            // LSB-first
            a0 = fifo_a_rd[7:0];
            a1 = fifo_a_rd[15:8];
            a2 = fifo_a_rd[23:16];
            a3 = fifo_a_rd[31:24];

            b0 = fifo_b_rd[7:0];
            b1 = fifo_b_rd[15:8];
            b2 = fifo_b_rd[23:16];
            b3 = fifo_b_rd[31:24];
        end
    end

    sa4x4 dut (
        .clk(clk),
        .reset(reset),
        .en(en_sa),

        .a0(a0), .a1(a1), .a2(a2), .a3(a3),
        .b0(b0), .b1(b1), .b2(b2), .b3(b3),

        .c00(c00), .c01(c01), .c02(c02), .c03(c03),
        .c10(c10), .c11(c11), .c12(c12), .c13(c13),
        .c20(c20), .c21(c21), .c22(c22), .c23(c23),
        .c30(c30), .c31(c31), .c32(c32), .c33(c33)
    );

    assign done = done_raw;

endmodule
