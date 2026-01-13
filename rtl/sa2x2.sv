// rtl/sa2x2.sv
module sa2x2 (
    input  logic clk,
    input  logic reset,
    input  logic en,

    // A from the left 
    input  logic signed [7:0] a_row0_in,
    input  logic signed [7:0] a_row1_in,

    // B from the top
    input  logic signed [7:0] b_col0_in,
    input  logic signed [7:0] b_col1_in,

    // Outputs
    output logic signed [31:0] c00,
    output logic signed [31:0] c01,
    output logic signed [31:0] c10,
    output logic signed [31:0] c11
);

    // Interconnect wires
    logic signed [7:0] a00_to_a01, a10_to_a11;
    logic signed [7:0] b00_to_b10, b01_to_b11;

    // PE(0,0)
    pe pe00 (
        .clk(clk), .reset(reset), .en(en),
        .a_in(a_row0_in),
        .b_in(b_col0_in),
        .a_out(a00_to_a01),
        .b_out(b00_to_b10),
        .acc_out(c00)
    );

    // PE(0,1)
    pe pe01 (
        .clk(clk), .reset(reset), .en(en),
        .a_in(a00_to_a01),
        .b_in(b_col1_in),
        .a_out(),              
        .b_out(b01_to_b11),
        .acc_out(c01)
    );

    // PE(1,0)
    pe pe10 (
        .clk(clk), .reset(reset), .en(en),
        .a_in(a_row1_in),
        .b_in(b00_to_b10),
        .a_out(a10_to_a11),
        .b_out(),            
        .acc_out(c10)
    );

    // PE(1,1)
    pe pe11 (
        .clk(clk), .reset(reset), .en(en),
        .a_in(a10_to_a11),
        .b_in(b01_to_b11),
        .a_out(), .b_out(),
        .acc_out(c11)
    );

endmodule
