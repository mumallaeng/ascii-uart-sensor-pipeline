`timescale 1ns / 1ps

module legacy_top_watch_stopwatch #(
    parameter CLK_FREQ_HZ = 100_000_000,
    parameter BD_HZ       = 100_000,
    parameter HOLD_TIME   = 100_000_000,
    parameter BASIC_TIME  = 100,
    parameter SCAN_HZ     = 1000,

    parameter MSEC_WIDTH = 7,
    parameter SEC_WIDTH  = 6,
    parameter MIN_WIDTH  = 6,
    parameter HOUR_WIDTH = 5,
    parameter MSEC_TIMES = 100,
    parameter SEC_TIMES  = 60,
    parameter MIN_TIMES  = 60,
    parameter HOUR_TIMES = 24

) (
    input        clk,
    input        rst,
    input        btnR,
    input        btnL,
    input        btnU,
    input        btnD,
    input        sw0,
    input        sw15,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output       led0,
    output       led15
);

    // 타이머 시간 값 와이어
    wire [  MSEC_WIDTH  -1:0] w_stopwatch_msec;
    wire [  SEC_WIDTH   -1:0] w_stopwatch_sec;
    wire [  MIN_WIDTH   -1:0] w_stopwatch_min;
    wire [  HOUR_WIDTH  -1:0] w_stopwatch_hour;

    // 타이머 시간 값 와이어
    wire [  MSEC_WIDTH  -1:0] w_watch_msec;
    wire [  SEC_WIDTH   -1:0] w_watch_sec;
    wire [  MIN_WIDTH   -1:0] w_watch_min;
    wire [  HOUR_WIDTH  -1:0] w_watch_hour;

    //최종 시간 출력
    wire [MSEC_WIDTH    -1:0] w_display_msec;
    wire [SEC_WIDTH     -1:0] w_display_sec;
    wire [MIN_WIDTH     -1:0] w_display_min;
    wire [    HOUR_WIDTH-1:0] w_display_hour;
    wire                      w_display_mode;


    wire                      w_btnR;
    wire                      w_btnL;
    wire                      w_btnU;
    wire                      w_btnD;
    wire                      w_btnR_hold;
    wire                      w_btnL_hold;
    wire                      w_btnU_hold;
    wire                      w_btnD_hold;
    wire                      w_btnC;
    wire                      w_sw0;
    wire                      w_sw15;


    // 타이머 시간 값 와이어



    input_conditioning #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),  // 100MHz
        .BD_HZ      (BD_HZ),        // 100kHz
        .HOLD_TIME  (HOLD_TIME)     // 1초
    ) U_BUTTON_EVENT_DECODER (
        .clk        (clk),
        .rst        (rst),
        .btnU       (btnU),
        .btnD       (btnD),
        .btnL       (btnL),
        .btnR       (btnR),
        .btnC       (1'b0),
        .sw0        (sw0),
        .sw15       (sw15),
        .o_btnU     (w_btnR),
        .o_btnD     (w_btnL),
        .o_btnL     (w_btnU),
        .o_btnR     (w_btnD),
        .o_btnC     (w_btnC),
        .o_btnU_hold(w_btnR_hold),
        .o_btnD_hold(w_btnL_hold),
        .o_btnL_hold(w_btnU_hold),
        .o_btnR_hold(w_btnD_hold),
        .o_sw0      (w_sw0),
        .o_sw15     (w_sw15)
    );


    stopwatch_unit #(
        .MAIN_CLK_100MHZ(CLK_FREQ_HZ),
        .BASIC_TIME     (BASIC_TIME),
        .MSEC_WIDTH     (MSEC_WIDTH),
        .SEC_WIDTH      (SEC_WIDTH),
        .MIN_WIDTH      (MIN_WIDTH),
        .HOUR_WIDTH     (HOUR_WIDTH),
        .MSEC_TIMES     (MSEC_TIMES),
        .SEC_TIMES      (SEC_TIMES),
        .MIN_TIMES      (MIN_TIMES),
        .HOUR_TIMES     (HOUR_TIMES)
    ) U_STOPWATCH (
        .clk   (clk),
        .rst   (rst),
        .i_btnD(w_btnD),
        .i_btnL(w_btnL),
        .i_btnU(w_btnU),
        .i_sw0 (w_sw0),
        .msec  (w_stopwatch_msec),
        .sec   (w_stopwatch_sec),
        .min   (w_stopwatch_min),
        .hour  (w_stopwatch_hour)
    );

    //// WATCH 자리


    common_control U_common_cont (
        .clk           (clk),
        .rst           (rst),
        .i_btnR_hold   (w_btnR_hold),
        .o_display_mode(w_display_mode)

    );

    display_select#(
        .MAIN_CLK_100MHZ(CLK_FREQ_HZ),
        .MSEC_WIDTH     (MSEC_WIDTH),
        .SEC_WIDTH      (SEC_WIDTH),
        .MIN_WIDTH      (MIN_WIDTH),
        .HOUR_WIDTH     (HOUR_WIDTH)
    ) (
        .i_stopwatch_msec(w_stopwatch_msec),
        .i_stopwatch_sec(w_stopwatch_sec),
        .i_stopwatch_min(w_stopwatch_min),
        .i_stopwatch_hour(w_stopwatch_hour),
        .i_watch_msec(w_watch_msec),
        .i_watch_sec(w_watch_sec),
        .i_watch_min(w_watch_min),
        .i_watch_hour(w_watch_hour),
        .i_sw0(w_sw0),
        .i_sw15(w_sw15),
        .o_display_msec(w_display_msec),
        .o_display_sec(w_display_min),
        .o_display_min(w_display_min),
        .o_display_hour(w_display_hour),
        .o_led_12_hour(led15),
        .o_led_stopwatch(led0)

    );



    fnd_controller #(
        .MAIN_CLK_100MHZ(CLK_FREQ_HZ),
        .SCAN_HZ        (SCAN_HZ),
        .MSEC_WIDTH     (MSEC_WIDTH),
        .SEC_WIDTH      (SEC_WIDTH),
        .MIN_WIDTH      (MIN_WIDTH),
        .HOUR_WIDTH     (HOUR_WIDTH)
    ) U_FND_CONTROLLER (
        .clk           (clk),
        .rst           (rst),
        .i_display_mode(w_display_mode),
        .msec          (w_display_msec),
        .sec           (w_display_sec),
        .min           (w_display_min),
        .hour          (w_display_hour),
        .fnd_com       (fnd_com),
        .fnd_data      (fnd_data)
    );



endmodule
