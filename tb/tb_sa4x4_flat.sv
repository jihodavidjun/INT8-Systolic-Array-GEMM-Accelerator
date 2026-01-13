// tb/tb_sa4x4_flat.sv
`timescale 1ns/1ps

module tb_sa4x4_flat;

    localparam int N = 4;
    localparam int ACC_W = 32;

    logic clk, reset, en;

    // Flattened inputs
    logic signed [7:0] a0, a1, a2, a3;
    logic signed [7:0] b0, b1, b2, b3;

    // Flattened outputs
    logic signed [ACC_W-1:0] c00, c01, c02, c03;
    logic signed [ACC_W-1:0] c10, c11, c12, c13;
    logic signed [ACC_W-1:0] c20, c21, c22, c23;
    logic signed [ACC_W-1:0] c30, c31, c32, c33;

    // DUT
    sa4x4 #(.ACC_W(ACC_W)) dut (
        .clk(clk), .reset(reset), .en(en),
        .a0(a0), .a1(a1), .a2(a2), .a3(a3),
        .b0(b0), .b1(b1), .b2(b2), .b3(b3),
        .c00(c00), .c01(c01), .c02(c02), .c03(c03),
        .c10(c10), .c11(c11), .c12(c12), .c13(c13),
        .c20(c20), .c21(c21), .c22(c22), .c23(c23),
        .c30(c30), .c31(c31), .c32(c32), .c33(c33)
    );

    always #5 clk = ~clk;

    // Reference matrices
    logic signed [7:0] A [N][N];
    logic signed [7:0] B [N][N];
    logic signed [ACC_W-1:0] C_ref [N][N];

    integer i, j, k;

    task compute_reference;
        begin
            for (i = 0; i < N; i++) begin
                for (j = 0; j < N; j++) begin
                    C_ref[i][j] = '0;
                    for (k = 0; k < N; k++) begin
                        C_ref[i][j] += A[i][k] * B[k][j];
                    end
                end
            end
        end
    endtask

    // Inject one systolic time step t using skew rule
    task inject_time(input int t);
        int kk;
        begin
            // Row 0
            kk = t - 0; a0 = (kk>=0 && kk<N) ? A[0][kk] : 0;
            kk = t - 1; a1 = (kk>=0 && kk<N) ? A[1][kk] : 0;
            kk = t - 2; a2 = (kk>=0 && kk<N) ? A[2][kk] : 0;
            kk = t - 3; a3 = (kk>=0 && kk<N) ? A[3][kk] : 0;

            // Col 0
            kk = t - 0; b0 = (kk>=0 && kk<N) ? B[kk][0] : 0;
            kk = t - 1; b1 = (kk>=0 && kk<N) ? B[kk][1] : 0;
            kk = t - 2; b2 = (kk>=0 && kk<N) ? B[kk][2] : 0;
            kk = t - 3; b3 = (kk>=0 && kk<N) ? B[kk][3] : 0;

            @(posedge clk); #1;
        end
    endtask

    task check_outputs;
        begin
            if (c00 !== C_ref[0][0]) $fatal(1,"Mismatch C[0][0]: got %0d exp %0d", c00, C_ref[0][0]);
            if (c01 !== C_ref[0][1]) $fatal(1,"Mismatch C[0][1]: got %0d exp %0d", c01, C_ref[0][1]);
            if (c02 !== C_ref[0][2]) $fatal(1,"Mismatch C[0][2]: got %0d exp %0d", c02, C_ref[0][2]);
            if (c03 !== C_ref[0][3]) $fatal(1,"Mismatch C[0][3]: got %0d exp %0d", c03, C_ref[0][3]);

            if (c10 !== C_ref[1][0]) $fatal(1,"Mismatch C[1][0]: got %0d exp %0d", c10, C_ref[1][0]);
            if (c11 !== C_ref[1][1]) $fatal(1,"Mismatch C[1][1]: got %0d exp %0d", c11, C_ref[1][1]);
            if (c12 !== C_ref[1][2]) $fatal(1,"Mismatch C[1][2]: got %0d exp %0d", c12, C_ref[1][2]);
            if (c13 !== C_ref[1][3]) $fatal(1,"Mismatch C[1][3]: got %0d exp %0d", c13, C_ref[1][3]);

            if (c20 !== C_ref[2][0]) $fatal(1,"Mismatch C[2][0]: got %0d exp %0d", c20, C_ref[2][0]);
            if (c21 !== C_ref[2][1]) $fatal(1,"Mismatch C[2][1]: got %0d exp %0d", c21, C_ref[2][1]);
            if (c22 !== C_ref[2][2]) $fatal(1,"Mismatch C[2][2]: got %0d exp %0d", c22, C_ref[2][2]);
            if (c23 !== C_ref[2][3]) $fatal(1,"Mismatch C[2][3]: got %0d exp %0d", c23, C_ref[2][3]);

            if (c30 !== C_ref[3][0]) $fatal(1,"Mismatch C[3][0]: got %0d exp %0d", c30, C_ref[3][0]);
            if (c31 !== C_ref[3][1]) $fatal(1,"Mismatch C[3][1]: got %0d exp %0d", c31, C_ref[3][1]);
            if (c32 !== C_ref[3][2]) $fatal(1,"Mismatch C[3][2]: got %0d exp %0d", c32, C_ref[3][2]);
            if (c33 !== C_ref[3][3]) $fatal(1,"Mismatch C[3][3]: got %0d exp %0d", c33, C_ref[3][3]);
        end
    endtask

    initial begin
        $dumpfile("sim/sa4x4.vcd");
        $dumpvars(0, tb_sa4x4_flat);

        clk = 0; reset = 1; en = 0;
        a0=0; a1=0; a2=0; a3=0;
        b0=0; b1=0; b2=0; b3=0;

        // Deterministic A and identity B
        for (i = 0; i < N; i++) begin
            for (j = 0; j < N; j++) begin
                A[i][j] = 8'(i*N + j + 1);
                B[i][j] = (i == j) ? 8'sd1 : 8'sd0;
            end
        end

        compute_reference();

        repeat (3) @(posedge clk);
        reset = 0;

        @(posedge clk);
        en = 1;

        for (int t = 0; t < 12; t++) begin
            inject_time(t);
        end

        repeat (2) @(posedge clk);
        en = 0;
        @(posedge clk); #1;

        check_outputs();
        $display("PASS: 4x4 systolic array matches reference GEMM (flattened wrapper).");
        $finish;
    end

endmodule
