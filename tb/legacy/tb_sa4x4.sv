// tb/tb_sa4x4.sv
`timescale 1ns/1ps

module tb_sa4x4;
    localparam int N = 4;
    localparam int ACC_W = 32;

    logic clk, reset, en;

    logic signed [7:0] a_in [N];
    logic signed [7:0] b_in [N];
    logic signed [ACC_W-1:0] c_out [N][N];

    // DUT
    saNxN #(.N(N), .ACC_W(ACC_W)) dut (
        .clk(clk),
        .reset(reset),
        .en(en),
        .a_in(a_in),
        .b_in(b_in),
        .c_out(c_out)
    );

    always #5 clk = ~clk;

    logic signed [7:0] A [N][N];
    logic signed [7:0] B [N][N];
    logic signed [ACC_W-1:0] C_ref [N][N];

    integer i, j, k;

    // Task
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

    // Task: inject one systolic time step t using skew rule
    task inject_time(input int t);
        int ii, jj;
        int kk;
        begin
            // Drive A edge inputs
            for (ii = 0; ii < N; ii++) begin
                kk = t - ii; 
                if (kk >= 0 && kk < N) a_in[ii] = A[ii][kk];
                else                   a_in[ii] = 0;
            end

            // Drive B edge inputs
            for (jj = 0; jj < N; jj++) begin
                kk = t - jj; 
                if (kk >= 0 && kk < N) b_in[jj] = B[kk][jj];
                else                   b_in[jj] = 0;
            end

            // Advance one cycle 
            @(posedge clk); #1;
        end
    endtask

    // Task: compare DUT output vs reference
    task check_outputs;
        begin
            for (i = 0; i < N; i++) begin
                for (j = 0; j < N; j++) begin
                    if (c_out[i][j] !== C_ref[i][j]) begin
                        $fatal(1,
                          "Mismatch C[%0d][%0d]: got %0d exp %0d",
                          i, j, c_out[i][j], C_ref[i][j]);
                    end
                end
            end
        end
    endtask

    // Main test
    initial begin
        $dumpfile("sim/sa4x4.vcd");
        $dumpvars(0, tb_sa4x4);

        // init
        clk = 0;
        reset = 1;
        en = 0;

        for (i = 0; i < N; i++) begin
            a_in[i] = 0;
            b_in[i] = 0;
        end

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

        // Run the systolic stream
        for (int t = 0; t < 12; t++) begin
            inject_time(t);
        end

        // Freeze accumulators and check
        en = 0;
        @(posedge clk); #1;

        check_outputs();

        $display("PASS: 4x4 systolic array matches reference GEMM.");
        $finish;
    end

endmodule
