`timescale 1ns / 1ps

module watch_stopwatch #(
    parameter CLK_FREQ_HZ      = 100_000_000,
    parameter BD_HZ            = 100_000,
    parameter HOLD_TIME_BTN_R  = 200_000_000,
    parameter HOLD_TIME_BTN_UD = 150_000_000,
    parameter HOLD_TIME_BTN_L  = 150_000_000,
    parameter REPEAT_TIME_BTN_UD = 20_000_000,
    parameter BASIC_TIME       = 100,
    parameter SCAN_HZ          = 1000,
    parameter MSEC_WIDTH       = 7,
    parameter SEC_WIDTH        = 6,
    parameter MIN_WIDTH        = 6,
    parameter HOUR_WIDTH       = 5,
    parameter MSEC_TIMES       = 100,
    parameter SEC_TIMES        = 60,
    parameter MIN_TIMES        = 60,
    parameter HOUR_TIMES       = 24
) (
    input clk,
    input rst,
    input btnR,
    input btnL,
    input btnU,
    input btnD,
    input sw0,
    input sw15,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output [1:0] led
);

    wire w_btnU;
    wire w_btnD;
    wire w_btnL;
    wire w_btnR;
    wire w_btnU_hold;
    wire w_btnD_hold;
    wire w_btnL_hold;
    wire w_btnR_hold;
    wire w_btnC;
    wire w_sw0;
    wire w_sw15;

    wire [MSEC_WIDTH-1:0] w_stopwatch_msec;
    wire [SEC_WIDTH-1:0]  w_stopwatch_sec;
    wire [MIN_WIDTH-1:0]  w_stopwatch_min;
    wire [HOUR_WIDTH-1:0] w_stopwatch_hour;

    wire [23:0] w_watch_set_time;
    wire w_watch_set_mode;
    wire [1:0] w_watch_set_index;

    wire w_display_mode;
    wire w_led_12_hour;
    wire w_led_stopwatch;

    // 버튼 입력은 debouncer를 거쳐 short/hold 이벤트로 정리함.
    input_conditioning #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BD_HZ(BD_HZ),
        .HOLD_TIME_BTN_R(HOLD_TIME_BTN_R),
        .HOLD_TIME_BTN_UD(HOLD_TIME_BTN_UD),
        .HOLD_TIME_BTN_L(HOLD_TIME_BTN_L),
        .REPEAT_TIME_BTN_UD(REPEAT_TIME_BTN_UD)
    ) U_INPUT_CONDITIONING (
        .clk(clk),
        .rst(rst),
        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),
        .btnC(1'b0),
        .sw0(sw0),
        .sw15(sw15),
        .o_btnU(w_btnU),
        .o_btnD(w_btnD),
        .o_btnL(w_btnL),
        .o_btnR(w_btnR),
        .o_btnC(w_btnC),
        .o_btnU_hold(w_btnU_hold),
        .o_btnD_hold(w_btnD_hold),
        .o_btnL_hold(w_btnL_hold),
        .o_btnR_hold(w_btnR_hold),
        .o_sw0(w_sw0),
        .o_sw15(w_sw15)
    );

    // display mode는 btnR short로 언제든 토글 가능함.
    // btnR hold는 debouncer에서 short와 분리되므로 set 진입/종료와 충돌하지 않음.
    common_control U_COMMON_CONTROL (
        .clk(clk),
        .rst(rst),
        .i_sw0(w_sw0),
        .i_btnR(w_btnR),
        .o_display_mode(w_display_mode)
    );

    stopwatch_unit #(
        .MAIN_CLK_100MHZ(CLK_FREQ_HZ),
        .BASIC_TIME(BASIC_TIME),
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH(SEC_WIDTH),
        .MIN_WIDTH(MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH),
        .MSEC_TIMES(MSEC_TIMES),
        .SEC_TIMES(SEC_TIMES),
        .MIN_TIMES(MIN_TIMES),
        .HOUR_TIMES(HOUR_TIMES)
    ) U_STOPWATCH (
        .clk(clk),
        .rst(rst),
        .i_btnD(w_btnD),
        .i_btnL(w_btnL),
        .i_btnU(w_btnU),
        .i_sw0(w_sw0),
        .msec(w_stopwatch_msec),
        .sec(w_stopwatch_sec),
        .min(w_stopwatch_min),
        .hour(w_stopwatch_hour)
    );

    watch_unit #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .TICK_HZ(BASIC_TIME),
        .MSEC_TIMES(MSEC_TIMES),
        .SEC_TIMES(SEC_TIMES),
        .MIN_TIMES(MIN_TIMES),
        .HOUR_TIMES(HOUR_TIMES),
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH(SEC_WIDTH),
        .MIN_WIDTH(MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) U_WATCH (
        .clk(clk),
        .rst(rst),
        .i_display_mode(w_display_mode),
        .i_btnL(w_btnL),
        .i_btnU(w_btnU),
        .i_btnD(w_btnD),
        .i_btnU_hold(w_btnU_hold),
        .i_btnD_hold(w_btnD_hold),
        .i_btnR_hold(w_btnR_hold),
        .i_sw0(w_sw0),
        .i_sw15(w_sw15),
        .o_set_mode(w_watch_set_mode),
        .o_set_index(w_watch_set_index),
        .o_set_time(w_watch_set_time)
    );

    display_unit #(
        .MAIN_CLK_100MHZ(CLK_FREQ_HZ),
        .SCAN_HZ(SCAN_HZ),
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH(SEC_WIDTH),
        .MIN_WIDTH(MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) U_DISPLAY (
        .clk(clk),
        .rst(rst),
        .i_display_mode(w_display_mode),
        .i_sw0(w_sw0),
        .i_sw15(w_sw15),
        .i_watch_set_mode(w_watch_set_mode),
        .i_watch_set_index(w_watch_set_index),
        .i_stopwatch_msec(w_stopwatch_msec),
        .i_stopwatch_sec(w_stopwatch_sec),
        .i_stopwatch_min(w_stopwatch_min),
        .i_stopwatch_hour(w_stopwatch_hour),
        .i_watch_set_time(w_watch_set_time),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .o_led_12_hour(w_led_12_hour),
        .o_led_stopwatch(w_led_stopwatch)
    );

    assign led[0] = w_led_stopwatch;
    assign led[1] = w_led_12_hour;

endmodule

module watch_unit #(
    parameter CLK_FREQ_HZ = 100_000_000,
    parameter TICK_HZ     = 100,
    parameter MSEC_TIMES  = 100,
    parameter SEC_TIMES   = 60,
    parameter MIN_TIMES   = 60,
    parameter HOUR_TIMES  = 24,
    parameter MSEC_WIDTH  = 7,
    parameter SEC_WIDTH   = 6,
    parameter MIN_WIDTH   = 6,
    parameter HOUR_WIDTH  = 5
) (
    input clk,
    input rst,
    input i_display_mode,
    input i_btnL,
    input i_btnU,
    input i_btnD,
    input i_btnU_hold,
    input i_btnD_hold,
    input i_btnR_hold,
    input i_sw0,
    input i_sw15,
    output o_set_mode,
    output [1:0] o_set_index,
    output [23:0] o_set_time
);

    wire w_index_shift;
    wire w_increment;
    wire w_increment_tens;
    wire w_decrement;
    wire w_decrement_tens;

    watch_fsm U_WATCH_FSM (
        .clk(clk),
        .rst(rst),
        .i_display_mode(i_display_mode),
        .i_btnL(i_btnL),
        .i_btnU(i_btnU),
        .i_btnD(i_btnD),
        .i_btnU_hold(i_btnU_hold),
        .i_btnD_hold(i_btnD_hold),
        .i_btnR_hold(i_btnR_hold),
        .i_sw0(i_sw0),
        .o_set_mode(o_set_mode),
        .o_set_index(o_set_index),
        .o_index_shift(w_index_shift),
        .o_increment(w_increment),
        .o_increment_tens(w_increment_tens),
        .o_decrement(w_decrement),
        .o_decrement_tens(w_decrement_tens)
    );

    watch_datapath #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .TICK_HZ(TICK_HZ),
        .MSEC_TIMES(MSEC_TIMES),
        .SEC_TIMES(SEC_TIMES),
        .MIN_TIMES(MIN_TIMES),
        .HOUR_TIMES(HOUR_TIMES),
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH(SEC_WIDTH),
        .MIN_WIDTH(MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) U_WATCH_DATAPATH (
        .clk(clk),
        .rst(rst),
        .i_set_mode(o_set_mode),
        .i_set_index(o_set_index),
        .i_index_shift(w_index_shift),
        .i_increment(w_increment),
        .i_increment_tens(w_increment_tens),
        .i_decrement(w_decrement),
        .i_decrement_tens(w_decrement_tens),
        .i_time_24({1'b0, i_sw15}),
        .o_set_time(o_set_time),
        .o_watch_vault(),
        .o_sec_tick(),
        .o_min_tick(),
        .o_hour_tick(),
        .msec(),
        .sec(),
        .min(),
        .hour()
    );

endmodule

module display_select_logic #(
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
    output [MSEC_WIDTH-1:0] o_display_msec,
    output [SEC_WIDTH-1:0] o_display_sec,
    output [MIN_WIDTH-1:0] o_display_min,
    output [HOUR_WIDTH-1:0] o_display_hour,
    output o_led_12_hour,
    output o_led_stopwatch
);

    display_select #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH(SEC_WIDTH),
        .MIN_WIDTH(MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) U_DISPLAY_SELECT (
        .i_stopwatch_msec(i_stopwatch_msec),
        .i_stopwatch_sec(i_stopwatch_sec),
        .i_stopwatch_min(i_stopwatch_min),
        .i_stopwatch_hour(i_stopwatch_hour),
        .i_watch_msec(i_watch_msec),
        .i_watch_sec(i_watch_sec),
        .i_watch_min(i_watch_min),
        .i_watch_hour(i_watch_hour),
        .i_sw0(i_sw0),
        .i_sw15(i_sw15),
        .o_display_msec(o_display_msec),
        .o_display_sec(o_display_sec),
        .o_display_min(o_display_min),
        .o_display_hour(o_display_hour),
        .o_led_12_hour(o_led_12_hour),
        .o_led_stopwatch(o_led_stopwatch)
    );

endmodule

module display_unit #(
    parameter MAIN_CLK_100MHZ = 100_000_000,
    parameter SCAN_HZ         = 1000,
    parameter MSEC_WIDTH      = 7,
    parameter SEC_WIDTH       = 6,
    parameter MIN_WIDTH       = 6,
    parameter HOUR_WIDTH      = 5
) (
    input clk,
    input rst,
    input i_display_mode,
    input i_sw0,
    input i_sw15,
    input i_watch_set_mode,
    input [1:0] i_watch_set_index,
    input [MSEC_WIDTH-1:0] i_stopwatch_msec,
    input [SEC_WIDTH-1:0] i_stopwatch_sec,
    input [MIN_WIDTH-1:0] i_stopwatch_min,
    input [HOUR_WIDTH-1:0] i_stopwatch_hour,
    input [23:0] i_watch_set_time,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output o_led_12_hour,
    output o_led_stopwatch
);

    localparam [2:0] FND_INDEX_OFF = 3'b111;

    wire [MSEC_WIDTH-1:0] w_display_msec;
    wire [SEC_WIDTH-1:0]  w_display_sec;
    wire [MIN_WIDTH-1:0]  w_display_min;
    wire [HOUR_WIDTH-1:0] w_display_hour;
    wire [2:0] w_fnd_set_index;

    assign w_fnd_set_index = (!i_sw0 && i_watch_set_mode) ? {1'b0, i_watch_set_index} : FND_INDEX_OFF;

    display_select_logic #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH(SEC_WIDTH),
        .MIN_WIDTH(MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) U_DISPLAY_SELECT_LOGIC (
        .i_stopwatch_msec(i_stopwatch_msec),
        .i_stopwatch_sec(i_stopwatch_sec),
        .i_stopwatch_min(i_stopwatch_min),
        .i_stopwatch_hour(i_stopwatch_hour),
        .i_watch_msec(i_watch_set_time[6:0]),
        .i_watch_sec(i_watch_set_time[12:7]),
        .i_watch_min(i_watch_set_time[18:13]),
        .i_watch_hour(i_watch_set_time[23:19]),
        .i_sw0(i_sw0),
        .i_sw15(i_sw15),
        .o_display_msec(w_display_msec),
        .o_display_sec(w_display_sec),
        .o_display_min(w_display_min),
        .o_display_hour(w_display_hour),
        .o_led_12_hour(o_led_12_hour),
        .o_led_stopwatch(o_led_stopwatch)
    );

    fnd_controller #(
        .MAIN_CLK_100MHZ(MAIN_CLK_100MHZ),
        .SCAN_HZ(SCAN_HZ),
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH(SEC_WIDTH),
        .MIN_WIDTH(MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) U_FND_CONTROLLER (
        .clk(clk),
        .rst(rst),
        .i_display_mode(i_display_mode),
        .i_show_center_dot(!i_sw0),
        .i_set_index(w_fnd_set_index),
        .msec(w_display_msec),
        .sec(w_display_sec),
        .min(w_display_min),
        .hour(w_display_hour),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

endmodule
