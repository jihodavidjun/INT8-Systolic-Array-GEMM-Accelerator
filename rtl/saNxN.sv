// rtl/saNxN.sv
module saNxN #(
    parameter int N = 4,
    parameter int ACC_W = 32
)(
    input  logic clk,
    input  logic reset,
    input  logic en,

    input  logic signed [7:0] a_in [N],     
    input  logic signed [7:0] b_in [N],

    output logic signed [ACC_W-1:0] c_out [N][N]
);

    logic signed [7:0] a_to_pe [N][N];
    logic signed [7:0] b_to_pe [N][N];

    logic signed [7:0] a_fwd  [N][N];
    logic signed [7:0] b_fwd  [N][N];

    genvar i, j;

    generate
        for (i = 0; i < N; i++) begin : GEN_ROW
            for (j = 0; j < N; j++) begin : GEN_COL

                // Boundary/neighbor connections
                if (j == 0) begin
                    assign a_to_pe[i][j] = a_in[i];
                end else begin
                    assign a_to_pe[i][j] = a_fwd[i][j-1];
                end

                if (i == 0) begin
                    assign b_to_pe[i][j] = b_in[j];
                end else begin
                    assign b_to_pe[i][j] = b_fwd[i-1][j];
                end

                // PE instance
                pe #(.ACC_W(ACC_W)) u_pe (
                    .clk(clk),
                    .reset(reset),
                    .en(en),
                    .a_in(a_to_pe[i][j]),
                    .b_in(b_to_pe[i][j]),
                    .a_out(a_fwd[i][j]),
                    .b_out(b_fwd[i][j]),
                    .acc_out(c_out[i][j])
                );

            end
        end
    endgenerate

endmodule
