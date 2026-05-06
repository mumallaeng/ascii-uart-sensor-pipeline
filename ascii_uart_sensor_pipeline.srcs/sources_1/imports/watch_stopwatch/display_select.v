`timescale 1ns / 1ps

module display_select #(
    parameter MSEC_WIDTH = 7,
    parameter SEC_WIDTH  = 6,
    parameter MIN_WIDTH  = 6,
    parameter HOUR_WIDTH = 5
) (
    input [MSEC_WIDTH-1:0] i_stopwatch_msec,
    input [SEC_WIDTH-1:0] i_stopwatch_sec,
    input [MIN_WIDTH-1:0] i_stopwatch_min,
    input [HOUR_WIDTH-1:0] i_stopwatch_hour,
    input [MSEC_WIDTH-1:0] i_watch_msec,
    input [SEC_WIDTH-1:0] i_watch_sec,
    input [MIN_WIDTH-1:0] i_watch_min,
    input [HOUR_WIDTH-1:0] i_watch_hour,
    input i_sw0,
    input i_sw15,
    output reg [MSEC_WIDTH-1:0] o_display_msec,
    output reg [SEC_WIDTH-1:0] o_display_sec,
    output reg [MIN_WIDTH-1:0] o_display_min,
    output reg [HOUR_WIDTH-1:0] o_display_hour,
    output reg o_led_12_hour,
    output reg o_led_stopwatch
);

    always @(*) begin
        if (!i_sw0) begin  // sw0=0이면 Watch 선택
            o_display_msec = i_watch_msec;
            o_display_sec  = i_watch_sec;
            o_display_min  = i_watch_min;
            o_display_hour = i_watch_hour;
            o_led_stopwatch    = 1'b0;
            o_led_12_hour  = i_sw15;
        end else begin  // sw0=1이면 Stopwatch 선택
            o_display_msec = i_stopwatch_msec;
            o_display_sec  = i_stopwatch_sec;
            o_display_min  = i_stopwatch_min;
            o_display_hour = i_stopwatch_hour;
            o_led_stopwatch    = 1'b1;
            o_led_12_hour  = 1'b0;
        end
    end

endmodule
