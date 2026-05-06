`timescale 1ns / 1ps

`include "ascii_uart_sensor_pipeline_defs.vh"

module ascii_uart_sensor_pipeline (
    input clk,
    input btnU,
    input btnD,
    input btnL,
    input btnR,
    input btnC,
    input [15:0] sw,
    input rx,
    input echo,
    inout dht11_io,
    output tx,
    output trig,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output [2:0] led
);

    // 현재 top은 INPUT, decision_unit, execute_unit, display_unit까지 연결된 상태다.
    // 보드 bring-up에서는 sw14 같은 임시 reset 입력을 쓰지 않기 위해
    // configuration 직후 짧은 power-on reset만 내부에서 만들어 공통 rst로 쓴다.
    reg [7:0] r_por_reset_count = 8'd0;
    wire w_reset;

    assign w_reset = (r_por_reset_count != 8'hFF);

    always @(posedge clk) begin
        if (w_reset) begin
            r_por_reset_count <= r_por_reset_count + 1'b1;
        end
    end

    // INPUT 구간에서 정리된 local button/switch bundle.
    wire w_btnU;
    wire w_btnD;
    wire w_btnL;
    wire w_btnR;
    wire w_btnC;
    wire w_btnU_hold;
    wire w_btnD_hold;
    wire w_btnL_hold;
    wire w_btnR_hold;
    wire w_sw0;
    wire w_sw15;

    // INPUT 구간 context decode 결과.
    wire [1:0] w_current_context;
    wire w_context_change_pulse;
    wire w_watch_12h;
    wire w_dht11_show_humi;

    // INPUT 구간 remote command bundle.
    wire w_cmd_btnR;
    wire w_cmd_btnR_hold;
    wire w_cmd_btnL;
    wire w_cmd_btnU;
    wire w_cmd_btnD;
    wire w_cmd_status;
    wire w_cmd_clr;
    wire w_unknown_cmd;

    // CONTROL 구간 decision 결과.
    wire w_watch_display_toggle_pulse;
    wire w_watch_set_mode_toggle_pulse;
    wire w_watch_set_index_next_pulse;
    wire w_watch_value_inc_pulse;
    wire w_watch_value_inc_tens_pulse;
    wire w_watch_value_dec_pulse;
    wire w_watch_value_dec_tens_pulse;
    wire w_stopwatch_display_toggle_pulse;
    wire w_stopwatch_clear_pulse;
    wire w_stopwatch_count_dir_toggle_pulse;
    wire w_stopwatch_run_toggle_pulse;
    wire w_soft_clear_pulse;
    wire w_sr04_refresh_req;
    wire w_dht11_refresh_req;
    wire [`SRC_W-1:0] w_log_src;
    wire [`CMD_W-1:0] w_log_cmd;
    wire [`EVT_W-1:0] w_log_evt;
    wire [`ACT_W-1:0] w_log_act;
    wire w_log_req;

    // EXECUTE 구간 watch/stopwatch 상태 출력.
    wire w_execute_display_mode;
    wire w_execute_watch_set_mode;
    wire [1:0] w_execute_watch_set_index;
    wire [23:0] w_execute_watch_live_time;
    wire [23:0] w_execute_watch_set_time;
    wire [6:0] w_execute_stopwatch_msec;
    wire [5:0] w_execute_stopwatch_sec;
    wire [5:0] w_execute_stopwatch_min;
    wire [4:0] w_execute_stopwatch_hour;
    wire [3:0] w_execute_watch_stopwatch_fnd_com;
    wire [7:0] w_execute_watch_stopwatch_fnd_data;
    wire [3:0] w_execute_sr04_fnd_com;
    wire [7:0] w_execute_sr04_fnd_data;
    wire [3:0] w_execute_dht11_fnd_com;
    wire [7:0] w_execute_dht11_fnd_data;
    wire [8:0] w_execute_sr04_distance_cm;
    wire [7:0] w_execute_dht11_temp;
    wire [7:0] w_execute_dht11_humi;
    wire w_execute_sr04_trig;
    wire w_execute_led_watch_12h;
    wire w_execute_led_stopwatch;
    wire w_execute_led_dht11_valid;

    // OUTPUT 구간 display 결과.
    wire [3:0] w_display_fnd_com;
    wire [7:0] w_display_fnd_data;
    wire w_remote_output_tx;

    input_conditioning U_INPUT_CONDITIONING (
        .clk(clk),
        .rst(w_reset),
        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),
        .btnC(btnC),
        .sw0(sw[0]),
        .sw15(sw[15]),
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

    context_manager U_CONTEXT_MANAGER (
        .clk(clk),
        .rst(w_reset),
        .i_sw_context(sw[1:0]),
        .i_sw15(w_sw15),
        .o_current_context(w_current_context),
        .o_context_change_pulse(w_context_change_pulse),
        .o_watch_12h(w_watch_12h),
        .o_dht11_show_humi(w_dht11_show_humi)
    );

    remote_input_unit U_REMOTE_INPUT_UNIT (
        .clk(clk),
        .rst(w_reset),
        .rx(rx),
        .cmd_btnR(w_cmd_btnR),
        .cmd_btnR_hold(w_cmd_btnR_hold),
        .cmd_btnL(w_cmd_btnL),
        .cmd_btnU(w_cmd_btnU),
        .cmd_btnD(w_cmd_btnD),
        .cmd_status(w_cmd_status),
        .cmd_clr(w_cmd_clr),
        .unknown_cmd(w_unknown_cmd)
    );

    decision_unit U_DECISION_UNIT (
        .clk(clk),
        .rst(w_reset),
        .i_btnU(w_btnU),
        .i_btnD(w_btnD),
        .i_btnL(w_btnL),
        .i_btnR(w_btnR),
        .i_btnC(w_btnC),
        .i_btnU_hold(w_btnU_hold),
        .i_btnD_hold(w_btnD_hold),
        .i_btnL_hold(w_btnL_hold),
        .i_btnR_hold(w_btnR_hold),
        .i_cmd_btnR(w_cmd_btnR),
        .i_cmd_btnR_hold(w_cmd_btnR_hold),
        .i_cmd_btnL(w_cmd_btnL),
        .i_cmd_btnU(w_cmd_btnU),
        .i_cmd_btnD(w_cmd_btnD),
        .i_cmd_status(w_cmd_status),
        .i_cmd_clr(w_cmd_clr),
        .i_current_context(w_current_context),
        .i_context_change_pulse(w_context_change_pulse),
        .o_watch_display_toggle_pulse(w_watch_display_toggle_pulse),
        .o_watch_set_mode_toggle_pulse(w_watch_set_mode_toggle_pulse),
        .o_watch_set_index_next_pulse(w_watch_set_index_next_pulse),
        .o_watch_value_inc_pulse(w_watch_value_inc_pulse),
        .o_watch_value_inc_tens_pulse(w_watch_value_inc_tens_pulse),
        .o_watch_value_dec_pulse(w_watch_value_dec_pulse),
        .o_watch_value_dec_tens_pulse(w_watch_value_dec_tens_pulse),
        .o_stopwatch_display_toggle_pulse(w_stopwatch_display_toggle_pulse),
        .o_stopwatch_clear_pulse(w_stopwatch_clear_pulse),
        .o_stopwatch_count_dir_toggle_pulse(w_stopwatch_count_dir_toggle_pulse),
        .o_stopwatch_run_toggle_pulse(w_stopwatch_run_toggle_pulse),
        .o_soft_clear_pulse(w_soft_clear_pulse),
        .o_sr04_refresh_req(w_sr04_refresh_req),
        .o_dht11_refresh_req(w_dht11_refresh_req),
        .o_log_src(w_log_src),
        .o_log_cmd(w_log_cmd),
        .o_log_evt(w_log_evt),
        .o_log_act(w_log_act),
        .o_log_req(w_log_req)
    );

    execute_unit U_EXECUTE_UNIT (
        .clk(clk),
        .rst(w_reset),
        .i_current_context(w_current_context),
        .i_watch_12h(w_watch_12h),
        .i_dht11_show_humi(w_dht11_show_humi),
        .i_watch_display_toggle_pulse(w_watch_display_toggle_pulse),
        .i_watch_set_mode_toggle_pulse(w_watch_set_mode_toggle_pulse),
        .i_watch_set_index_next_pulse(w_watch_set_index_next_pulse),
        .i_watch_value_inc_pulse(w_watch_value_inc_pulse),
        .i_watch_value_inc_tens_pulse(w_watch_value_inc_tens_pulse),
        .i_watch_value_dec_pulse(w_watch_value_dec_pulse),
        .i_watch_value_dec_tens_pulse(w_watch_value_dec_tens_pulse),
        .i_stopwatch_display_toggle_pulse(w_stopwatch_display_toggle_pulse),
        .i_stopwatch_clear_pulse(w_stopwatch_clear_pulse),
        .i_stopwatch_count_dir_toggle_pulse(w_stopwatch_count_dir_toggle_pulse),
        .i_stopwatch_run_toggle_pulse(w_stopwatch_run_toggle_pulse),
        .i_soft_clear_pulse(w_soft_clear_pulse),
        .i_sr04_refresh_req(w_sr04_refresh_req),
        .i_dht11_refresh_req(w_dht11_refresh_req),
        .i_echo(echo),
        .io_dht11(dht11_io),
        .o_display_mode(w_execute_display_mode),
        .o_watch_set_mode(w_execute_watch_set_mode),
        .o_watch_set_index(w_execute_watch_set_index),
        .o_watch_live_time(w_execute_watch_live_time),
        .o_watch_set_time(w_execute_watch_set_time),
        .o_stopwatch_msec(w_execute_stopwatch_msec),
        .o_stopwatch_sec(w_execute_stopwatch_sec),
        .o_stopwatch_min(w_execute_stopwatch_min),
        .o_stopwatch_hour(w_execute_stopwatch_hour),
        .o_watch_stopwatch_fnd_com(w_execute_watch_stopwatch_fnd_com),
        .o_watch_stopwatch_fnd_data(w_execute_watch_stopwatch_fnd_data),
        .o_sr04_fnd_com(w_execute_sr04_fnd_com),
        .o_sr04_fnd_data(w_execute_sr04_fnd_data),
        .o_dht11_fnd_com(w_execute_dht11_fnd_com),
        .o_dht11_fnd_data(w_execute_dht11_fnd_data),
        .o_sr04_distance_cm(w_execute_sr04_distance_cm),
        .o_dht11_temp(w_execute_dht11_temp),
        .o_dht11_humi(w_execute_dht11_humi),
        .o_sr04_trig(w_execute_sr04_trig),
        .o_led_watch_12h(w_execute_led_watch_12h),
        .o_led_stopwatch(w_execute_led_stopwatch),
        .o_led_dht11_valid(w_execute_led_dht11_valid)
    );

    display_unit U_DISPLAY_UNIT (
        .i_current_context(w_current_context),
        .i_watch_stopwatch_fnd_com(w_execute_watch_stopwatch_fnd_com),
        .i_watch_stopwatch_fnd_data(w_execute_watch_stopwatch_fnd_data),
        .i_sr04_fnd_com(w_execute_sr04_fnd_com),
        .i_sr04_fnd_data(w_execute_sr04_fnd_data),
        .i_dht11_fnd_com(w_execute_dht11_fnd_com),
        .i_dht11_fnd_data(w_execute_dht11_fnd_data),
        .o_fnd_com(w_display_fnd_com),
        .o_fnd_data(w_display_fnd_data)
    );

    remote_output_unit U_REMOTE_OUTPUT_UNIT (
        .clk(clk),
        .rst(w_reset),
        .i_unknown_cmd(w_unknown_cmd),
        .i_log_src(w_log_src),
        .i_log_cmd(w_log_cmd),
        .i_log_evt(w_log_evt),
        .i_log_act(w_log_act),
        .i_log_req(w_log_req),
        .i_current_context(w_current_context),
        .i_watch_live_time(w_execute_watch_live_time),
        .i_stopwatch_hour(w_execute_stopwatch_hour),
        .i_stopwatch_min(w_execute_stopwatch_min),
        .i_stopwatch_sec(w_execute_stopwatch_sec),
        .i_sr04_distance_cm(w_execute_sr04_distance_cm),
        .i_dht_temp(w_execute_dht11_temp),
        .i_dht_humi(w_execute_dht11_humi),
        .i_dht_valid(w_execute_led_dht11_valid),
        .o_tx(w_remote_output_tx)
    );

    assign trig = w_execute_sr04_trig;
    assign tx = w_remote_output_tx;
    assign fnd_com = w_display_fnd_com;
    assign fnd_data = w_display_fnd_data;
    // 보드 bring-up 단계에서는 LED를 sensor valid/status보다
    // switch/context debug 쪽에 우선 배정한다.
    // led[0] = current_context bit0
    // led[1] = current_context bit1
    // led[2] = sw15 option
    assign led = {w_sw15, w_current_context[1], w_current_context[0]};

endmodule
