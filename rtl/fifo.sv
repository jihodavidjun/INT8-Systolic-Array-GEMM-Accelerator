`timescale 1ns/1ps

module fifo #(
    parameter int WIDTH = 32,
    parameter int DEPTH = 32
)(
    input  logic                 clk,
    input  logic                 reset,

    input  logic                 wr_en,
    input  logic [WIDTH-1:0]     wr_data,
    output logic                 full,

    input  logic                 rd_en,
    output logic [WIDTH-1:0]     rd_data,
    output logic                 empty,

    output logic [$clog2(DEPTH+1)-1:0] count
);

    localparam int AW = (DEPTH <= 2) ? 1 : $clog2(DEPTH);

    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [AW-1:0] wptr, rptr;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    assign rd_data = mem[rptr];

    logic do_wr, do_rd;
    assign do_wr = wr_en && !full;
    assign do_rd = rd_en && !empty;

    always_ff @(posedge clk) begin
        if (reset) begin
            wptr  <= '0;
            rptr  <= '0;
            count <= '0;
        end else begin
            // write
            if (do_wr) begin
                mem[wptr] <= wr_data;
                if (wptr == DEPTH-1) wptr <= '0;
                else                 wptr <= wptr + 1'b1;
            end

            // read advance
            if (do_rd) begin
                if (rptr == DEPTH-1) rptr <= '0;
                else                 rptr <= rptr + 1'b1;
            end

            // count update
            case ({do_wr, do_rd})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count; 
            endcase
        end
    end

endmodule
