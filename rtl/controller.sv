`timescale 1ns/1ps

module controller #(
    parameter int FEED_CYCLES  = 12,
    parameter int FLUSH_CYCLES = 4
)(
    input  logic clk,
    input  logic reset,

    input  logic start,
    input  logic fifo_a_empty,
    input  logic fifo_b_empty,

    output logic pop_a,
    output logic pop_b,
    output logic en_sa,
    output logic done
);

    parameter int S_IDLE  = 0;
    parameter int S_FEED  = 1;
    parameter int S_FLUSH = 2;
    parameter int S_DONE  = 3;

    integer state;
    integer feed_cnt;
    integer flush_cnt;

    always @(posedge clk) begin
        if (reset) begin
            state     <= S_IDLE;
            feed_cnt  <= 0;
            flush_cnt <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    feed_cnt  <= 0;
                    flush_cnt <= 0;
                    if (start) state <= S_FEED;
                end

                S_FEED: begin
                    if (!fifo_a_empty && !fifo_b_empty) begin
                        feed_cnt <= feed_cnt + 1;
                        if (feed_cnt == FEED_CYCLES-1) begin
                            state <= S_FLUSH;
                            flush_cnt <= 0;
                        end
                    end
                end

                S_FLUSH: begin
                    flush_cnt <= flush_cnt + 1;
                    if (flush_cnt == FLUSH_CYCLES-1) begin
                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    state <= S_DONE;
                end
            endcase
        end
    end

    always @(*) begin
        pop_a = 0;
        pop_b = 0;
        en_sa = 0;
        done  = 0;

        case (state)
            S_IDLE: begin end

            S_FEED: begin
                if (!fifo_a_empty && !fifo_b_empty) begin
                    pop_a = 1;
                    pop_b = 1;
                    en_sa = 1;
                end
            end

            // keep array enabled while zeros flush through
            S_FLUSH: begin
                en_sa = 1;
            end

            S_DONE: begin
                done = 1;
            end
        endcase
    end

endmodule
