`timescale 1ns / 1ps

`include "ascii_uart_sensor_pipeline_defs.vh"

// decision_unit 단위 TB:
// INPUT에서 올라온 canonical 의도가
// context별 action/log로 제대로 바뀌는지만 가볍게 확인한다.
module tb_decision_unit;
    reg clk;
    reg rst;

    reg i_btnU;
    reg i_btnD;
    reg i_btnL;
    reg i_btnR;
    reg i_btnC;
    reg i_btnU_hold;
    reg i_btnD_hold;
    reg i_btnL_hold;
    reg i_btnR_hold;
    reg i_cmd_btnR;
    reg i_cmd_btnR_hold;
    reg i_cmd_btnL;
    reg i_cmd_btnU;
    reg i_cmd_btnD;
    reg i_cmd_status;
    reg i_cmd_clr;
    reg [`CTX_W-1:0] i_current_context;
    reg i_context_change_pulse;

    wire o_watch_display_toggle_pulse;
    wire o_watch_set_mode_toggle_pulse;
    wire o_watch_set_index_next_pulse;
    wire o_watch_value_inc_pulse;
    wire o_watch_value_inc_tens_pulse;
    wire o_watch_value_dec_pulse;
    wire o_watch_value_dec_tens_pulse;
    wire o_stopwatch_display_toggle_pulse;
    wire o_stopwatch_clear_pulse;
    wire o_stopwatch_count_dir_toggle_pulse;
    wire o_stopwatch_run_toggle_pulse;
    wire o_soft_clear_pulse;
    wire o_sr04_refresh_req;
    wire o_dht11_refresh_req;
    wire [`SRC_W-1:0] o_log_src;
    wire [`CMD_W-1:0] o_log_cmd;
    wire [`EVT_W-1:0] o_log_evt;
    wire [`ACT_W-1:0] o_log_act;
    wire o_log_req;

    decision_unit DUT (
        .clk(clk),
        .rst(rst),
        .i_btnU(i_btnU),
        .i_btnD(i_btnD),
        .i_btnL(i_btnL),
        .i_btnR(i_btnR),
        .i_btnC(i_btnC),
        .i_btnU_hold(i_btnU_hold),
        .i_btnD_hold(i_btnD_hold),
        .i_btnL_hold(i_btnL_hold),
        .i_btnR_hold(i_btnR_hold),
        .i_cmd_btnR(i_cmd_btnR),
        .i_cmd_btnR_hold(i_cmd_btnR_hold),
        .i_cmd_btnL(i_cmd_btnL),
        .i_cmd_btnU(i_cmd_btnU),
        .i_cmd_btnD(i_cmd_btnD),
        .i_cmd_status(i_cmd_status),
        .i_cmd_clr(i_cmd_clr),
        .i_current_context(i_current_context),
        .i_context_change_pulse(i_context_change_pulse),
        .o_watch_display_toggle_pulse(o_watch_display_toggle_pulse),
        .o_watch_set_mode_toggle_pulse(o_watch_set_mode_toggle_pulse),
        .o_watch_set_index_next_pulse(o_watch_set_index_next_pulse),
        .o_watch_value_inc_pulse(o_watch_value_inc_pulse),
        .o_watch_value_inc_tens_pulse(o_watch_value_inc_tens_pulse),
        .o_watch_value_dec_pulse(o_watch_value_dec_pulse),
        .o_watch_value_dec_tens_pulse(o_watch_value_dec_tens_pulse),
        .o_stopwatch_display_toggle_pulse(o_stopwatch_display_toggle_pulse),
        .o_stopwatch_clear_pulse(o_stopwatch_clear_pulse),
        .o_stopwatch_count_dir_toggle_pulse(o_stopwatch_count_dir_toggle_pulse),
        .o_stopwatch_run_toggle_pulse(o_stopwatch_run_toggle_pulse),
        .o_soft_clear_pulse(o_soft_clear_pulse),
        .o_sr04_refresh_req(o_sr04_refresh_req),
        .o_dht11_refresh_req(o_dht11_refresh_req),
        .o_log_src(o_log_src),
        .o_log_cmd(o_log_cmd),
        .o_log_evt(o_log_evt),
        .o_log_act(o_log_act),
        .o_log_req(o_log_req)
    );

    always #5 clk = ~clk;

    task automatic clear_inputs;
        begin
            i_btnU = 1'b0;
            i_btnD = 1'b0;
            i_btnL = 1'b0;
            i_btnR = 1'b0;
            i_btnC = 1'b0;
            i_btnU_hold = 1'b0;
            i_btnD_hold = 1'b0;
            i_btnL_hold = 1'b0;
            i_btnR_hold = 1'b0;
            i_cmd_btnR = 1'b0;
            i_cmd_btnR_hold = 1'b0;
            i_cmd_btnL = 1'b0;
            i_cmd_btnU = 1'b0;
            i_cmd_btnD = 1'b0;
            i_cmd_status = 1'b0;
            i_cmd_clr = 1'b0;
            i_context_change_pulse = 1'b0;
        end
    endtask

    task automatic expect_no_function_pulses;
        begin
            if (o_watch_display_toggle_pulse !== 1'b0) $fatal(1, "unexpected watch display pulse");
            if (o_watch_set_mode_toggle_pulse !== 1'b0) $fatal(1, "unexpected watch set-mode pulse");
            if (o_watch_set_index_next_pulse !== 1'b0) $fatal(1, "unexpected watch set-index pulse");
            if (o_watch_value_inc_pulse !== 1'b0) $fatal(1, "unexpected watch inc pulse");
            if (o_watch_value_inc_tens_pulse !== 1'b0) $fatal(1, "unexpected watch inc tens pulse");
            if (o_watch_value_dec_pulse !== 1'b0) $fatal(1, "unexpected watch dec pulse");
            if (o_watch_value_dec_tens_pulse !== 1'b0) $fatal(1, "unexpected watch dec tens pulse");
            if (o_stopwatch_display_toggle_pulse !== 1'b0) $fatal(1, "unexpected stopwatch display pulse");
            if (o_stopwatch_clear_pulse !== 1'b0) $fatal(1, "unexpected stopwatch clear pulse");
            if (o_stopwatch_count_dir_toggle_pulse !== 1'b0) $fatal(1, "unexpected stopwatch dir pulse");
            if (o_stopwatch_run_toggle_pulse !== 1'b0) $fatal(1, "unexpected stopwatch run pulse");
            if (o_soft_clear_pulse !== 1'b0) $fatal(1, "unexpected soft clear pulse");
        end
    endtask

    task automatic expect_no_refresh_reqs;
        begin
            if (o_sr04_refresh_req !== 1'b0) $fatal(1, "unexpected sr04 refresh");
            if (o_dht11_refresh_req !== 1'b0) $fatal(1, "unexpected dht11 refresh");
        end
    endtask

    initial begin
        // 이 TB가 확인하는 것:
        // 1) local 우선순위
        // 2) watch/stopwatch context별 action 매핑
        // 3) sensor context entry refresh 정책
        // 4) sensor context에서 버튼 계열 command를 무시하되 로그는 남기는 정책
        clk = 1'b0;
        rst = 1'b1;
        i_current_context = `CTX_WATCH;
        clear_inputs();

        repeat (2) @(posedge clk);
        rst = 1'b0;
        #1;

        // Check 0: idle에서는 아무 pulse도 없고 log 요청도 없어야 한다.
        expect_no_function_pulses();
        expect_no_refresh_reqs();
        if (o_log_req !== 1'b0) $fatal(1, "unexpected log_req in idle");
        if (o_log_evt !== `EVT_NONE) $fatal(1, "unexpected log_evt in idle");
        if (o_log_act !== `ACT_NONE) $fatal(1, "unexpected log_act in idle");

        // Check 1: local과 remote가 겹치면 local btnR이 우선한다.
        clear_inputs();
        i_current_context = `CTX_WATCH;
        i_btnR = 1'b1;
        i_cmd_status = 1'b1;
        #1;
        if (o_watch_display_toggle_pulse !== 1'b1) $fatal(1, "local btnR should win over remote status");
        if (o_log_src !== `SRC_LOCAL) $fatal(1, "expected local src");
        if (o_log_cmd !== `CMD_BTNR) $fatal(1, "expected CMD_BTNR");
        if (o_log_evt !== `EVT_BTNR_SHORT) $fatal(1, "expected EVT_BTNR_SHORT");
        if (o_log_act !== `ACT_DISPLAY_TOGGLE) $fatal(1, "expected ACT_DISPLAY_TOGGLE");
        if (o_log_req !== 1'b1) $fatal(1, "missing log_req for local btnR");
        expect_no_refresh_reqs();

        // Check 2: WATCH에서 U hold는 tens increment로 해석돼야 한다.
        clear_inputs();
        i_current_context = `CTX_WATCH;
        i_btnU_hold = 1'b1;
        #1;
        if (o_watch_value_inc_tens_pulse !== 1'b1) $fatal(1, "expected watch inc tens pulse");
        if (o_watch_value_inc_pulse !== 1'b0) $fatal(1, "unexpected watch inc ones pulse");
        if (o_log_act !== `ACT_WATCH_VALUE_INC_TENS) $fatal(1, "expected ACT_WATCH_VALUE_INC_TENS");
        if (o_log_cmd !== `CMD_BTNU) $fatal(1, "expected CMD_BTNU");
        if (o_log_evt !== `EVT_BTNU_SHORT) $fatal(1, "expected EVT_BTNU_SHORT");
        expect_no_refresh_reqs();

        // Check 3: remote clr는 soft_clear pulse와 remote log를 만들어야 한다.
        clear_inputs();
        i_current_context = `CTX_WATCH;
        i_cmd_clr = 1'b1;
        #1;
        if (o_soft_clear_pulse !== 1'b1) $fatal(1, "expected soft clear pulse");
        if (o_log_src !== `SRC_REMOTE) $fatal(1, "expected remote src for clr");
        if (o_log_cmd !== `CMD_CLR) $fatal(1, "expected CMD_CLR");
        if (o_log_evt !== `EVT_SOFT_CLEAR) $fatal(1, "expected EVT_SOFT_CLEAR");
        if (o_log_act !== `ACT_SOFT_CLEAR) $fatal(1, "expected ACT_SOFT_CLEAR");
        if (o_log_req !== 1'b1) $fatal(1, "missing log_req for clr");
        expect_no_refresh_reqs();

        // Check 4: STOPWATCH에서 btnD short는 run toggle이다.
        clear_inputs();
        i_current_context = `CTX_STOPWATCH;
        i_btnD = 1'b1;
        #1;
        if (o_stopwatch_run_toggle_pulse !== 1'b1) $fatal(1, "expected stopwatch run toggle pulse");
        if (o_log_act !== `ACT_STOPWATCH_RUN_TOGGLE) $fatal(1, "expected ACT_STOPWATCH_RUN_TOGGLE");
        expect_no_refresh_reqs();

        // Check 5: SR04 context 진입은 refresh_req 1회와 refresh log를 만든다.
        clear_inputs();
        i_current_context = `CTX_SR04;
        i_context_change_pulse = 1'b1;
        #1;
        expect_no_function_pulses();
        if (o_sr04_refresh_req !== 1'b1) $fatal(1, "expected sr04 refresh request");
        if (o_dht11_refresh_req !== 1'b0) $fatal(1, "unexpected dht11 refresh on sr04 entry");
        if (o_log_evt !== `EVT_CONTEXT_ENTRY_REFRESH) $fatal(1, "expected refresh log evt for sr04");
        if (o_log_act !== `ACT_REFRESH_REQUEST) $fatal(1, "expected refresh log act for sr04");
        if (o_log_req !== 1'b0) $fatal(1, "auto refresh should not raise log_req yet");

        // Check 6: DHT11 context 진입도 별도 refresh_req를 만들어야 한다.
        clear_inputs();
        i_current_context = `CTX_DHT11;
        i_context_change_pulse = 1'b1;
        #1;
        expect_no_function_pulses();
        if (o_dht11_refresh_req !== 1'b1) $fatal(1, "expected dht11 refresh request");
        if (o_sr04_refresh_req !== 1'b0) $fatal(1, "unexpected sr04 refresh on dht11 entry");
        if (o_log_evt !== `EVT_CONTEXT_ENTRY_REFRESH) $fatal(1, "expected refresh log evt for dht11");
        if (o_log_act !== `ACT_REFRESH_REQUEST) $fatal(1, "expected refresh log act for dht11");
        if (o_log_req !== 1'b0) $fatal(1, "auto refresh should not raise log_req yet");

        // Check 7: sensor context에서 btnR 계열 command는 기능 동작 없이 ignore log만 남긴다.
        clear_inputs();
        i_current_context = `CTX_SR04;
        i_cmd_btnR = 1'b1;
        #1;
        expect_no_function_pulses();
        expect_no_refresh_reqs();
        if (o_log_src !== `SRC_REMOTE) $fatal(1, "expected remote src in sensor ignore case");
        if (o_log_cmd !== `CMD_BTNR) $fatal(1, "expected CMD_BTNR in sensor ignore case");
        if (o_log_evt !== `EVT_BTNR_SHORT) $fatal(1, "expected EVT_BTNR_SHORT in sensor ignore case");
        if (o_log_act !== `ACT_IGNORED_IN_SENSOR_CONTEXT) $fatal(1, "expected sensor ignore act");
        if (o_log_req !== 1'b1) $fatal(1, "ignored sensor command should still request log");

        // Check 8: status는 context와 무관하게 status_report로 기록돼야 한다.
        clear_inputs();
        i_current_context = `CTX_DHT11;
        i_cmd_status = 1'b1;
        #1;
        expect_no_function_pulses();
        expect_no_refresh_reqs();
        if (o_log_src !== `SRC_REMOTE) $fatal(1, "expected remote src for status");
        if (o_log_cmd !== `CMD_STATUS) $fatal(1, "expected CMD_STATUS");
        if (o_log_evt !== `EVT_STATUS) $fatal(1, "expected EVT_STATUS");
        if (o_log_act !== `ACT_STATUS_REPORT) $fatal(1, "expected ACT_STATUS_REPORT");
        if (o_log_req !== 1'b1) $fatal(1, "status should raise log_req");

        $display("tb_decision_unit: PASS");
        $finish;
    end
endmodule
