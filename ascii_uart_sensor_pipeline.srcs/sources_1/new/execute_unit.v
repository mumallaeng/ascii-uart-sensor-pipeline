`timescale 1ns / 1ps

`include "ascii_uart_sensor_pipeline_defs.vh"

// execute_unit은 decision 결과를 실제 기능 블록 경계로 넘기는 wrapper다.
// 현재 단계에서는 watch/stopwatch만 먼저 연결하고,
// SR04/DHT11은 팀원 요청 문서 기준으로 후속 연동한다.
module execute_unit (
    input clk,
    input rst,
    input [`CTX_W-1:0] i_current_context,
    input i_watch_12h,
    input i_dht11_show_humi,
    input i_watch_display_toggle_pulse,
    input i_watch_set_mode_toggle_pulse,
    input i_watch_set_index_next_pulse,
    input i_watch_value_inc_pulse,
    input i_watch_value_inc_tens_pulse,
    input i_watch_value_dec_pulse,
    input i_watch_value_dec_tens_pulse,
    input i_stopwatch_display_toggle_pulse,
    input i_stopwatch_clear_pulse,
    input i_stopwatch_count_dir_toggle_pulse,
    input i_stopwatch_run_toggle_pulse,
    input i_soft_clear_pulse,
    input i_sr04_refresh_req,
    input i_dht11_refresh_req,
    input i_echo,
    inout io_dht11,
    output o_display_mode,
    output o_watch_set_mode,
    output [1:0] o_watch_set_index,
    output [23:0] o_watch_live_time,
    output [23:0] o_watch_set_time,
    output [6:0] o_stopwatch_msec,
    output [5:0] o_stopwatch_sec,
    output [5:0] o_stopwatch_min,
    output [4:0] o_stopwatch_hour,
    output [3:0] o_watch_stopwatch_fnd_com,
    output [7:0] o_watch_stopwatch_fnd_data,
    output [3:0] o_sr04_fnd_com,
    output [7:0] o_sr04_fnd_data,
    output [3:0] o_dht11_fnd_com,
    output [7:0] o_dht11_fnd_data,
    output [8:0] o_sr04_distance_cm,
    output [7:0] o_dht11_temp,
    output [7:0] o_dht11_humi,
    output o_sr04_trig,
    output o_led_watch_12h,
    output o_led_stopwatch,
    output o_led_dht11_valid
);

    // soft clear는 execute 경계에서는 공통 reset처럼 취급한다.
    wire w_execute_rst = rst | i_soft_clear_pulse;

    watch_stopwatch_unit U_WATCH_STOPWATCH_UNIT (
        .clk(clk),
        .rst(w_execute_rst),
        .i_is_stopwatch_context(i_current_context == `CTX_STOPWATCH),
        .i_watch_12h(i_watch_12h),
        .i_display_toggle_pulse(i_watch_display_toggle_pulse | i_stopwatch_display_toggle_pulse),
        .i_watch_set_mode_toggle_pulse(i_watch_set_mode_toggle_pulse),
        .i_watch_set_index_next_pulse(i_watch_set_index_next_pulse),
        .i_watch_value_inc_pulse(i_watch_value_inc_pulse),
        .i_watch_value_inc_tens_pulse(i_watch_value_inc_tens_pulse),
        .i_watch_value_dec_pulse(i_watch_value_dec_pulse),
        .i_watch_value_dec_tens_pulse(i_watch_value_dec_tens_pulse),
        .i_stopwatch_clear_pulse(i_stopwatch_clear_pulse),
        .i_stopwatch_count_dir_toggle_pulse(i_stopwatch_count_dir_toggle_pulse),
        .i_stopwatch_run_toggle_pulse(i_stopwatch_run_toggle_pulse),
        .o_display_mode(o_display_mode),
        .o_watch_set_mode(o_watch_set_mode),
        .o_watch_set_index(o_watch_set_index),
        .o_watch_live_time(o_watch_live_time),
        .o_watch_set_time(o_watch_set_time),
        .o_stopwatch_msec(o_stopwatch_msec),
        .o_stopwatch_sec(o_stopwatch_sec),
        .o_stopwatch_min(o_stopwatch_min),
        .o_stopwatch_hour(o_stopwatch_hour),
        .o_fnd_com(o_watch_stopwatch_fnd_com),
        .o_fnd_data(o_watch_stopwatch_fnd_data),
        .o_led_watch_12h(o_led_watch_12h),
        .o_led_stopwatch(o_led_stopwatch)
    );

    // 센서 wrapper는 hierarchy와 top 경계를 먼저 확정하기 위한 placeholder다.
    // 실제 측정 core 연동은 팀원 요청 문서 기준으로 대체한다.
    sr04_unit U_SR04_UNIT (
        .clk(clk),
        .rst(w_execute_rst),
        .i_refresh_req(i_sr04_refresh_req),
        .echo(i_echo),
        .trig(o_sr04_trig),
        .o_distance_cm(o_sr04_distance_cm),
        .o_fnd_com(o_sr04_fnd_com),
        .o_fnd_data(o_sr04_fnd_data)
    );

    dht11_unit U_DHT11_UNIT (
        .clk(clk),
        .rst(w_execute_rst),
        .i_refresh_req(i_dht11_refresh_req),
        .i_show_humi(i_dht11_show_humi),
        .dht11_io(io_dht11),
        .o_temp(o_dht11_temp),
        .o_humi(o_dht11_humi),
        .o_valid(o_led_dht11_valid),
        .o_fnd_com(o_dht11_fnd_com),
        .o_fnd_data(o_dht11_fnd_data)
    );

endmodule

// watch_stopwatch_unit은 기존 재사용 블록을 프로젝트용 control pulse에 맞춰
// 다시 묶은 execute 하위 wrapper다.
module watch_stopwatch_unit #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer BASIC_TIME = 100,
    parameter integer MSEC_WIDTH = 7,
    parameter integer SEC_WIDTH = 6,
    parameter integer MIN_WIDTH = 6,
    parameter integer HOUR_WIDTH = 5,
    parameter integer MSEC_TIMES = 100,
    parameter integer SEC_TIMES = 60,
    parameter integer MIN_TIMES = 60,
    parameter integer HOUR_TIMES = 24
) (
    input clk,
    input rst,
    input i_is_stopwatch_context,
    input i_watch_12h,
    input i_display_toggle_pulse,
    input i_watch_set_mode_toggle_pulse,
    input i_watch_set_index_next_pulse,
    input i_watch_value_inc_pulse,
    input i_watch_value_inc_tens_pulse,
    input i_watch_value_dec_pulse,
    input i_watch_value_dec_tens_pulse,
    input i_stopwatch_clear_pulse,
    input i_stopwatch_count_dir_toggle_pulse,
    input i_stopwatch_run_toggle_pulse,
    output o_display_mode,
    output o_watch_set_mode,
    output [1:0] o_watch_set_index,
    output [23:0] o_watch_live_time,
    output [23:0] o_watch_set_time,
    output [MSEC_WIDTH-1:0] o_stopwatch_msec,
    output [SEC_WIDTH-1:0] o_stopwatch_sec,
    output [MIN_WIDTH-1:0] o_stopwatch_min,
    output [HOUR_WIDTH-1:0] o_stopwatch_hour,
    output [3:0] o_fnd_com,
    output [7:0] o_fnd_data,
    output o_led_watch_12h,
    output o_led_stopwatch
);

    localparam [2:0] FND_INDEX_OFF = 3'b111;

    wire w_display_mode;
    wire w_watch_index_shift;
    wire w_watch_increment;
    wire w_watch_increment_tens;
    wire w_watch_decrement;
    wire w_watch_decrement_tens;
    wire w_watch_sec_tick;
    wire w_watch_min_tick;
    wire w_watch_hour_tick;
    wire [MSEC_WIDTH-1:0] w_watch_msec;
    wire [SEC_WIDTH-1:0] w_watch_sec;
    wire [MIN_WIDTH-1:0] w_watch_min;
    wire [HOUR_WIDTH-1:0] w_watch_hour;
    wire [MSEC_WIDTH-1:0] w_display_msec;
    wire [SEC_WIDTH-1:0] w_display_sec;
    wire [MIN_WIDTH-1:0] w_display_min;
    wire [HOUR_WIDTH-1:0] w_display_hour;
    wire [2:0] w_fnd_set_index;

    assign o_display_mode = w_display_mode;
    assign o_led_stopwatch = i_is_stopwatch_context;
    assign o_led_watch_12h = (!i_is_stopwatch_context) & i_watch_12h;
    // stopwatch에서는 set mode 개념이 없으므로 blink index를 항상 끈다.
    // watch set mode일 때만 기존 FND helper가 선택 자리 깜빡임을 만들 수 있게 넘긴다.
    assign w_fnd_set_index = (!i_is_stopwatch_context && o_watch_set_mode) ? {1'b0, o_watch_set_index} : FND_INDEX_OFF;

    // 표시 모드 토글은 WATCH/STOPWATCH가 공통으로 공유하는 상태다.
    common_control U_COMMON_CONTROL (
        .clk(clk),
        .rst(rst),
        .i_sw0(i_is_stopwatch_context),
        .i_btnR(i_display_toggle_pulse),
        .o_display_mode(w_display_mode)
    );

    watch_fsm U_WATCH_FSM (
        .clk(clk),
        .rst(rst),
        .i_display_mode(w_display_mode),
        .i_btnL(i_watch_set_index_next_pulse),
        .i_btnU(i_watch_value_inc_pulse),
        .i_btnD(i_watch_value_dec_pulse),
        .i_btnU_hold(i_watch_value_inc_tens_pulse),
        .i_btnD_hold(i_watch_value_dec_tens_pulse),
        .i_btnR_hold(i_watch_set_mode_toggle_pulse),
        .i_sw0(i_is_stopwatch_context),
        .o_set_mode(o_watch_set_mode),
        .o_set_index(o_watch_set_index),
        .o_index_shift(w_watch_index_shift),
        .o_increment(w_watch_increment),
        .o_increment_tens(w_watch_increment_tens),
        .o_decrement(w_watch_decrement),
        .o_decrement_tens(w_watch_decrement_tens)
    );

    watch_datapath #(
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
    ) U_WATCH_DATAPATH (
        .clk(clk),
        .rst(rst),
        .i_set_mode(o_watch_set_mode),
        .i_set_index(o_watch_set_index),
        .i_index_shift(w_watch_index_shift),
        .i_increment(w_watch_increment),
        .i_increment_tens(w_watch_increment_tens),
        .i_decrement(w_watch_decrement),
        .i_decrement_tens(w_watch_decrement_tens),
        .i_time_24({1'b0, i_watch_12h}),
        .o_set_time(o_watch_set_time),
        .o_watch_vault(o_watch_live_time),
        .o_sec_tick(w_watch_sec_tick),
        .o_min_tick(w_watch_min_tick),
        .o_hour_tick(w_watch_hour_tick),
        .msec(w_watch_msec),
        .sec(w_watch_sec),
        .min(w_watch_min),
        .hour(w_watch_hour)
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
        .i_btnD(i_stopwatch_run_toggle_pulse),
        .i_btnL(i_stopwatch_clear_pulse),
        .i_btnU(i_stopwatch_count_dir_toggle_pulse),
        .i_sw0(i_is_stopwatch_context),
        .msec(o_stopwatch_msec),
        .sec(o_stopwatch_sec),
        .min(o_stopwatch_min),
        .hour(o_stopwatch_hour)
    );

    // watch_datapath의 o_set_time은 set 모드가 아닐 때 live time을 따라가므로,
    // 기존 display helper 입장에서는 이 버스 하나만 받아도 표시 후보를 만들 수 있다.
    display_select #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH(SEC_WIDTH),
        .MIN_WIDTH(MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) U_DISPLAY_SELECT (
        .i_stopwatch_msec(o_stopwatch_msec),
        .i_stopwatch_sec(o_stopwatch_sec),
        .i_stopwatch_min(o_stopwatch_min),
        .i_stopwatch_hour(o_stopwatch_hour),
        .i_watch_msec(o_watch_set_time[6:0]),
        .i_watch_sec(o_watch_set_time[12:7]),
        .i_watch_min(o_watch_set_time[18:13]),
        .i_watch_hour(o_watch_set_time[23:19]),
        .i_sw0(i_is_stopwatch_context),
        .i_sw15(i_watch_12h),
        .o_display_msec(w_display_msec),
        .o_display_sec(w_display_sec),
        .o_display_min(w_display_min),
        .o_display_hour(w_display_hour),
        .o_led_12_hour(),
        .o_led_stopwatch()
    );

    // 여기서 만든 FND 후보는 top direct child인 display_unit이
    // sensor 후보들과 다시 한 번 context 기준으로 고른다.
    fnd_controller #(
        .MAIN_CLK_100MHZ(CLK_FREQ_HZ),
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH(SEC_WIDTH),
        .MIN_WIDTH(MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH)
    ) U_FND_CONTROLLER (
        .clk(clk),
        .rst(rst),
        .i_display_mode(w_display_mode),
        .i_show_center_dot(!i_is_stopwatch_context),
        .i_set_index(w_fnd_set_index),
        .msec(w_display_msec),
        .sec(w_display_sec),
        .min(w_display_min),
        .hour(w_display_hour),
        .fnd_com(o_fnd_com),
        .fnd_data(o_fnd_data)
    );

endmodule
