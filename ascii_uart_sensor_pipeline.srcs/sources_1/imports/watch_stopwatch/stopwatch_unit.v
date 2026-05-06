`timescale 1ns / 1ps



module stopwatch_unit #(
    parameter MAIN_CLK_100MHZ = 100_000_000,
    parameter BASIC_TIME      = 100,

    parameter MSEC_WIDTH = 7,
    parameter SEC_WIDTH  = 6,
    parameter MIN_WIDTH  = 6,
    parameter HOUR_WIDTH = 5,
    parameter MSEC_TIMES = 100,
    parameter SEC_TIMES  = 60,
    parameter MIN_TIMES  = 60,
    parameter HOUR_TIMES = 24
) (
    input clk,
    input rst,
    input i_btnD,
    input i_btnL,
    input i_btnU,
    input i_sw0,
    output [MSEC_WIDTH  -1:0] msec,
    output [SEC_WIDTH   -1:0] sec,
    output [MIN_WIDTH   -1:0] min,
    output [HOUR_WIDTH  -1:0] hour
);

    wire w_runstop, w_clear, w_updown;

    stopwatch_fsm U_STOPWATCH_CONTROL_UNIT (
        .clk(clk),
        .rst(rst),
        .i_btnD(i_btnD),
        .i_btnL(i_btnL),
        .i_btnU(i_btnU),
        .i_sw0(i_sw0),
        .o_runstop(w_runstop),
        .o_clear(w_clear),
        .o_updown(w_updown)
    );

    stopwatch_datapath #(
        .MAIN_CLK_100MHZ(MAIN_CLK_100MHZ),
        .BASIC_TIME(BASIC_TIME),
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH(SEC_WIDTH),
        .MIN_WIDTH(MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH),
        .MSEC_TIMES(MSEC_TIMES),
        .SEC_TIMES(SEC_TIMES),
        .MIN_TIMES(MIN_TIMES),
        .HOUR_TIMES(HOUR_TIMES)
    ) U_STOPWATCH_DATAPATH (
        .clk(clk),
        .rst(rst),
        .i_runstop(w_runstop),
        .i_clear(w_clear),
        .i_updown(w_updown),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );





endmodule
