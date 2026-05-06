`timescale 1ns / 1ps

module legacy_stopwatch_datapath #(
    parameter integer MSEC_WIDTH = 7,
    parameter integer SEC_WIDTH = 6,
    parameter integer MIN_WIDTH = 6,
    parameter integer HOUR_WIDTH = 5,
    parameter integer MSEC_TIMES = 100,
    parameter integer SEC_TIMES = 60,
    parameter integer MIN_TIMES = 60,
    parameter integer HOUR_TIMES = 24,
    parameter integer DEFAULT_TICK = 1'b1
) (
    input clk,
    input rst,
    input i_run_stop,
    input i_clear,
    input i_down_mode,
    output [MSEC_WIDTH-1:0] msec,
    output [SEC_WIDTH-1:0] sec,
    output [MIN_WIDTH-1:0] min,
    output [HOUR_WIDTH-1:0] hour
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;

    legacy_tick_counter #(
        .TIMES(MSEC_TIMES),
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_MSEC_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_tick_100hz),
        .i_clear(i_clear),
        .i_down(i_down_mode),
        .time_count(msec),
        .o_tick(w_sec_tick)
    );

    legacy_tick_counter #(
        .TIMES(SEC_TIMES),
        .BIT_WIDTH(SEC_WIDTH)
    ) U_SEC_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_sec_tick),
        .i_clear(i_clear),
        .i_down(i_down_mode),
        .time_count(sec),
        .o_tick(w_min_tick)
    );

    legacy_tick_counter #(
        .TIMES(MIN_TIMES),
        .BIT_WIDTH(MIN_WIDTH)
    ) U_MIN_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_min_tick),
        .i_clear(i_clear),
        .i_down(i_down_mode),
        .time_count(min),
        .o_tick(w_hour_tick)
    );

    legacy_tick_counter #(
        .TIMES(HOUR_TIMES),
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_HOUR_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_hour_tick),
        .i_clear(i_clear),
        .i_down(i_down_mode),
        .time_count(hour),
        .o_tick()
    );

    legacy_tick_gen_100hz U_TICK_GEN_100HZ (
        .clk(clk),
        .rst(rst),
        .i_run_stop(i_run_stop),
        .i_clear(i_clear),
        .o_tick_100hz(w_tick_100hz)
    );
endmodule

module legacy_tick_counter #(
    parameter TIMES = 100,
    parameter BIT_WIDTH = 7
) (
    input clk,
    input rst,
    input i_tick,
    input i_clear,
    input i_down,
    output [BIT_WIDTH-1:0] time_count,
    output reg o_tick
);

    reg [BIT_WIDTH-1:0] count_reg;
    reg [BIT_WIDTH-1:0] count_next;

    assign time_count = count_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count_reg <= 0;
        end else if (i_clear) begin
            count_reg <= 0;
        end else if (i_tick) begin
            count_reg <= count_next;
        end
    end

    always @(*) begin
        count_next = count_reg;
        o_tick = 1'b0;

        if (i_tick) begin
            if (i_down) begin
                count_next = count_reg - 1;
                if (count_reg == 0) begin
                    o_tick = 1'b1;
                    count_next = TIMES - 1;
                end
            end else begin
                count_next = count_reg + 1;
                if (count_reg == TIMES - 1) begin
                    o_tick = 1'b1;
                    count_next = 0;
                end
            end
        end else if (i_clear) begin
            count_next = 0;
        end
    end
endmodule

module legacy_tick_gen_100hz #(
    localparam integer CLK_FREQ_HZ = 100_000_000,
    localparam integer TICK_HZ = 100,
    localparam integer TICK_COUNT = CLK_FREQ_HZ / TICK_HZ
) (
    input clk,
    input rst,
    input i_run_stop,
    input i_clear,
    output reg o_tick_100hz
);

    reg [$clog2(TICK_COUNT)-1:0] count_100hz;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count_100hz  <= 0;
            o_tick_100hz <= 1'b0;
        end else if (i_clear) begin
            count_100hz  <= 0;
            o_tick_100hz <= 1'b0;
        end else if (i_run_stop) begin
            count_100hz <= count_100hz + 1'b1;
            if (count_100hz == TICK_COUNT - 1) begin
                count_100hz  <= 0;
                o_tick_100hz <= 1'b1;
            end else begin
                o_tick_100hz <= 1'b0;
            end
        end else begin
            o_tick_100hz <= 1'b0;
        end
    end
endmodule
