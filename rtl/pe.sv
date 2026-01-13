// rtl/pe.sv
module pe #(
    parameter int ACC_W = 32
) (
    input  logic                 clk,
    input  logic                 reset,   
    input  logic                 en,     

    input  logic signed [7:0]     a_in,
    input  logic signed [7:0]     b_in,

    output logic signed [7:0]     a_out,
    output logic signed [7:0]     b_out,

    output logic signed [ACC_W-1:0] acc_out
);

    // Internal register
    logic signed [ACC_W-1:0] acc_reg;

    // Compute product as signed 16-bit
    logic signed [15:0] product;
    assign product = a_in * b_in; 

    always_ff @(posedge clk) begin
        if (reset) begin
            acc_reg <= '0;
            a_out   <= '0;
            b_out   <= '0;
        end else if (en) begin
            a_out <= a_in;
            b_out <= b_in;
            acc_reg <= acc_reg + {{(ACC_W-16){product[15]}}, product}; // sign-extend
        end
    end

    assign acc_out = acc_reg;

endmodule
