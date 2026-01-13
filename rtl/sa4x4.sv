// rtl/sa4x4.sv
module sa4x4 #(
    parameter int ACC_W = 32
)(
    input  logic clk,
    input  logic reset,
    input  logic en,

    input  logic signed [7:0] a0, a1, a2, a3,   
    input  logic signed [7:0] b0, b1, b2, b3,

    output logic signed [ACC_W-1:0] c00, c01, c02, c03,
    output logic signed [ACC_W-1:0] c10, c11, c12, c13,
    output logic signed [ACC_W-1:0] c20, c21, c22, c23,
    output logic signed [ACC_W-1:0] c30, c31, c32, c33
);

    // Internal interconnect 
    logic signed [7:0] a_to_pe [4][4];
    logic signed [7:0] b_to_pe [4][4];
    logic signed [7:0] a_fwd   [4][4];
    logic signed [7:0] b_fwd   [4][4];

    // Left edge A injections
    assign a_to_pe[0][0] = a0;  assign a_to_pe[1][0] = a1;
    assign a_to_pe[2][0] = a2;  assign a_to_pe[3][0] = a3;

    // Top edge B injections
    assign b_to_pe[0][0] = b0;  assign b_to_pe[0][1] = b1;
    assign b_to_pe[0][2] = b2;  assign b_to_pe[0][3] = b3;

    // Internal A propagation (right)
    assign a_to_pe[0][1] = a_fwd[0][0];
    assign a_to_pe[0][2] = a_fwd[0][1];
    assign a_to_pe[0][3] = a_fwd[0][2];

    assign a_to_pe[1][1] = a_fwd[1][0];
    assign a_to_pe[1][2] = a_fwd[1][1];
    assign a_to_pe[1][3] = a_fwd[1][2];

    assign a_to_pe[2][1] = a_fwd[2][0];
    assign a_to_pe[2][2] = a_fwd[2][1];
    assign a_to_pe[2][3] = a_fwd[2][2];

    assign a_to_pe[3][1] = a_fwd[3][0];
    assign a_to_pe[3][2] = a_fwd[3][1];
    assign a_to_pe[3][3] = a_fwd[3][2];

    // Internal B propagation (down)
    assign b_to_pe[1][0] = b_fwd[0][0];
    assign b_to_pe[2][0] = b_fwd[1][0];
    assign b_to_pe[3][0] = b_fwd[2][0];

    assign b_to_pe[1][1] = b_fwd[0][1];
    assign b_to_pe[2][1] = b_fwd[1][1];
    assign b_to_pe[3][1] = b_fwd[2][1];

    assign b_to_pe[1][2] = b_fwd[0][2];
    assign b_to_pe[2][2] = b_fwd[1][2];
    assign b_to_pe[3][2] = b_fwd[2][2];

    assign b_to_pe[1][3] = b_fwd[0][3];
    assign b_to_pe[2][3] = b_fwd[1][3];
    assign b_to_pe[3][3] = b_fwd[2][3];

    // 16 PE instances
    pe #(.ACC_W(ACC_W)) pe00(.clk(clk),.reset(reset),.en(en),.a_in(a_to_pe[0][0]),.b_in(b_to_pe[0][0]),.a_out(a_fwd[0][0]),.b_out(b_fwd[0][0]),.acc_out(c00));
    pe #(.ACC_W(ACC_W)) pe01(.clk(clk),.reset(reset),.en(en),.a_in(a_to_pe[0][1]),.b_in(b_to_pe[0][1]),.a_out(a_fwd[0][1]),.b_out(b_fwd[0][1]),.acc_out(c01));
    pe #(.ACC_W(ACC_W)) pe02(.clk(clk),.reset(reset),.en(en),.a_in(a_to_pe[0][2]),.b_in(b_to_pe[0][2]),.a_out(a_fwd[0][2]),.b_out(b_fwd[0][2]),.acc_out(c02));
    pe #(.ACC_W(ACC_W)) pe03(.clk(clk),.reset(reset),.en(en),.a_in(a_to_pe[0][3]),.b_in(b_to_pe[0][3]),.a_out(a_fwd[0][3]),.b_out(b_fwd[0][3]),.acc_out(c03));

    pe #(.ACC_W(ACC_W)) pe10(.clk(clk),.reset(reset),.en(en),.a_in(a_to_pe[1][0]),.b_in(b_to_pe[1][0]),.a_out(a_fwd[1][0]),.b_out(b_fwd[1][0]),.acc_out(c10));
    pe #(.ACC_W(ACC_W)) pe11(.clk(clk),.reset(reset),.en(en),.a_in(a_to_pe[1][1]),.b_in(b_to_pe[1][1]),.a_out(a_fwd[1][1]),.b_out(b_fwd[1][1]),.acc_out(c11));
    pe #(.ACC_W(ACC_W)) pe12(.clk(clk),.reset(reset),.en(en),.a_in(a_to_pe[1][2]),.b_in(b_to_pe[1][2]),.a_out(a_fwd[1][2]),.b_out(b_fwd[1][2]),.acc_out(c12));
    pe #(.ACC_W(ACC_W)) pe13(.clk(clk),.reset(reset),.en(en),.a_in(a_to_pe[1][3]),.b_in(b_to_pe[1][3]),.a_out(a_fwd[1][3]),.b_out(b_fwd[1][3]),.acc_out(c13));

    pe #(.ACC_W(ACC_W)) pe20(.clk(clk),.reset(reset),.en(en),.a_in(a_to_pe[2][0]),.b_in(b_to_pe[2][0]),.a_out(a_fwd[2][0]),.b_out(b_fwd[2][0]),.acc_out(c20));
    pe #(.ACC_W(ACC_W)) pe21(.clk(clk),.reset(reset),.en(en),.a_in(a_to_pe[2][1]),.b_in(b_to_pe[2][1]),.a_out(a_fwd[2][1]),.b_out(b_fwd[2][1]),.acc_out(c21));
    pe #(.ACC_W(ACC_W)) pe22(.clk(clk),.reset(reset),.en(en),.a_in(a_to_pe[2][2]),.b_in(b_to_pe[2][2]),.a_out(a_fwd[2][2]),.b_out(b_fwd[2][2]),.acc_out(c22));
    pe #(.ACC_W(ACC_W)) pe23(.clk(clk),.reset(reset),.en(en),.a_in(a_to_pe[2][3]),.b_in(b_to_pe[2][3]),.a_out(a_fwd[2][3]),.b_out(b_fwd[2][3]),.acc_out(c23));

    pe #(.ACC_W(ACC_W)) pe30(.clk(clk),.reset(reset),.en(en),.a_in(a_to_pe[3][0]),.b_in(b_to_pe[3][0]),.a_out(a_fwd[3][0]),.b_out(b_fwd[3][0]),.acc_out(c30));
    pe #(.ACC_W(ACC_W)) pe31(.clk(clk),.reset(reset),.en(en),.a_in(a_to_pe[3][1]),.b_in(b_to_pe[3][1]),.a_out(a_fwd[3][1]),.b_out(b_fwd[3][1]),.acc_out(c31));
    pe #(.ACC_W(ACC_W)) pe32(.clk(clk),.reset(reset),.en(en),.a_in(a_to_pe[3][2]),.b_in(b_to_pe[3][2]),.a_out(a_fwd[3][2]),.b_out(b_fwd[3][2]),.acc_out(c32));
    pe #(.ACC_W(ACC_W)) pe33(.clk(clk),.reset(reset),.en(en),.a_in(a_to_pe[3][3]),.b_in(b_to_pe[3][3]),.a_out(a_fwd[3][3]),.b_out(b_fwd[3][3]),.acc_out(c33));

endmodule
