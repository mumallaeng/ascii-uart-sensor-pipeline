`timescale 1ns / 1ps

`include "ascii_uart_sensor_pipeline_defs.vh"

// decision_unit은 CONTROL 구간의 정책 경계다.
// watch/stopwatch/sensor 기능 자체를 구현하지는 않고,
// 1) local/remote 요청을 canonical event로 정규화한 뒤
// 2) current_context 기준으로 의미를 해석한다.
module decision_unit (
    input clk,
    input rst,
    input i_btnU,
    input i_btnD,
    input i_btnL,
    input i_btnR,
    input i_btnC,
    input i_btnU_hold,
    input i_btnD_hold,
    input i_btnL_hold,
    input i_btnR_hold,
    input i_cmd_btnR,
    input i_cmd_btnR_hold,
    input i_cmd_btnL,
    input i_cmd_btnU,
    input i_cmd_btnD,
    input i_cmd_status,
    input i_cmd_clr,
    input [`CTX_W-1:0] i_current_context,
    input i_context_change_pulse,
    output o_watch_display_toggle_pulse,
    output o_watch_set_mode_toggle_pulse,
    output o_watch_set_index_next_pulse,
    output o_watch_value_inc_pulse,
    output o_watch_value_inc_tens_pulse,
    output o_watch_value_dec_pulse,
    output o_watch_value_dec_tens_pulse,
    output o_stopwatch_display_toggle_pulse,
    output o_stopwatch_clear_pulse,
    output o_stopwatch_count_dir_toggle_pulse,
    output o_stopwatch_run_toggle_pulse,
    output o_soft_clear_pulse,
    output o_sr04_refresh_req,
    output o_dht11_refresh_req,
    output [`SRC_W-1:0] o_log_src,
    output [`CMD_W-1:0] o_log_cmd,
    output [`EVT_W-1:0] o_log_evt,
    output [`ACT_W-1:0] o_log_act,
    output o_log_req
);

    wire w_canonical_evt_valid;
    wire [`SRC_W-1:0] w_canonical_src;
    wire [`CMD_W-1:0] w_canonical_cmd;
    wire [`EVT_W-1:0] w_canonical_evt;
    wire w_canonical_step_tens;

    // 지금은 조합 정책 중심이지만, 나중에 상태를 갖는 정책으로 커져도
    // top 인터페이스를 다시 바꾸지 않도록 clk/rst를 경계에 남겨 둔다.
    wire unused_clk = clk;
    wire unused_rst = rst;

    event_selector U_EVENT_SELECTOR (
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
        .o_canonical_evt_valid(w_canonical_evt_valid),
        .o_canonical_src(w_canonical_src),
        .o_canonical_cmd(w_canonical_cmd),
        .o_canonical_evt(w_canonical_evt),
        .o_canonical_step_tens(w_canonical_step_tens)
    );

    action_dispatcher U_ACTION_DISPATCHER (
        .i_canonical_evt_valid(w_canonical_evt_valid),
        .i_canonical_src(w_canonical_src),
        .i_canonical_cmd(w_canonical_cmd),
        .i_canonical_evt(w_canonical_evt),
        .i_canonical_step_tens(w_canonical_step_tens),
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

endmodule

// event_selector는 입력 source 차이를 없애는 단계다.
// local button pulse와 remote command pulse를 하나의 canonical event로
// 맞추고, 같은 cycle에 겹치면 local을 우선한다.
module event_selector (
    input i_btnU,
    input i_btnD,
    input i_btnL,
    input i_btnR,
    input i_btnC,
    input i_btnU_hold,
    input i_btnD_hold,
    input i_btnL_hold,
    input i_btnR_hold,
    input i_cmd_btnR,
    input i_cmd_btnR_hold,
    input i_cmd_btnL,
    input i_cmd_btnU,
    input i_cmd_btnD,
    input i_cmd_status,
    input i_cmd_clr,
    output reg o_canonical_evt_valid,
    output reg [`SRC_W-1:0] o_canonical_src,
    output reg [`CMD_W-1:0] o_canonical_cmd,
    output reg [`EVT_W-1:0] o_canonical_evt,
    output reg o_canonical_step_tens
);

    always @(*) begin
        o_canonical_evt_valid = 1'b0;
        o_canonical_src = `SRC_LOCAL;
        o_canonical_cmd = `CMD_NONE;
        o_canonical_evt = `EVT_NONE;
        o_canonical_step_tens = 1'b0;

        // local과 remote가 같은 cycle에 겹치면 local이 우선한다.
        // 이 priority chain이 그 정책을 실제로 담고 있는 유일한 위치다.
        if (i_btnC) begin
            o_canonical_evt_valid = 1'b1;
            o_canonical_cmd = `CMD_CLR;
            o_canonical_evt = `EVT_SOFT_CLEAR;
        end else if (i_btnR_hold) begin
            o_canonical_evt_valid = 1'b1;
            o_canonical_cmd = `CMD_BTNR_HOLD;
            o_canonical_evt = `EVT_BTNR_HOLD;
        end else if (i_btnR) begin
            o_canonical_evt_valid = 1'b1;
            o_canonical_cmd = `CMD_BTNR;
            o_canonical_evt = `EVT_BTNR_SHORT;
        end else if (i_btnL) begin
            o_canonical_evt_valid = 1'b1;
            o_canonical_cmd = `CMD_BTNL;
            o_canonical_evt = `EVT_BTNL_SHORT;
        end else if (i_btnU_hold) begin
            o_canonical_evt_valid = 1'b1;
            o_canonical_cmd = `CMD_BTNU;
            o_canonical_evt = `EVT_BTNU_SHORT;
            // event 종류는 여전히 "up"이지만,
            // dispatcher는 hold 기반의 tens-step인지도 알아야 한다.
            o_canonical_step_tens = 1'b1;
        end else if (i_btnU) begin
            o_canonical_evt_valid = 1'b1;
            o_canonical_cmd = `CMD_BTNU;
            o_canonical_evt = `EVT_BTNU_SHORT;
        end else if (i_btnD_hold) begin
            o_canonical_evt_valid = 1'b1;
            o_canonical_cmd = `CMD_BTND;
            o_canonical_evt = `EVT_BTND_SHORT;
            o_canonical_step_tens = 1'b1;
        end else if (i_btnD) begin
            o_canonical_evt_valid = 1'b1;
            o_canonical_cmd = `CMD_BTND;
            o_canonical_evt = `EVT_BTND_SHORT;
        end else if (i_cmd_clr) begin
            o_canonical_evt_valid = 1'b1;
            o_canonical_src = `SRC_REMOTE;
            o_canonical_cmd = `CMD_CLR;
            o_canonical_evt = `EVT_SOFT_CLEAR;
        end else if (i_cmd_btnR_hold) begin
            o_canonical_evt_valid = 1'b1;
            o_canonical_src = `SRC_REMOTE;
            o_canonical_cmd = `CMD_BTNR_HOLD;
            o_canonical_evt = `EVT_BTNR_HOLD;
        end else if (i_cmd_btnR) begin
            o_canonical_evt_valid = 1'b1;
            o_canonical_src = `SRC_REMOTE;
            o_canonical_cmd = `CMD_BTNR;
            o_canonical_evt = `EVT_BTNR_SHORT;
        end else if (i_cmd_btnL) begin
            o_canonical_evt_valid = 1'b1;
            o_canonical_src = `SRC_REMOTE;
            o_canonical_cmd = `CMD_BTNL;
            o_canonical_evt = `EVT_BTNL_SHORT;
        end else if (i_cmd_btnU) begin
            o_canonical_evt_valid = 1'b1;
            o_canonical_src = `SRC_REMOTE;
            o_canonical_cmd = `CMD_BTNU;
            o_canonical_evt = `EVT_BTNU_SHORT;
        end else if (i_cmd_btnD) begin
            o_canonical_evt_valid = 1'b1;
            o_canonical_src = `SRC_REMOTE;
            o_canonical_cmd = `CMD_BTND;
            o_canonical_evt = `EVT_BTND_SHORT;
        end else if (i_cmd_status) begin
            o_canonical_evt_valid = 1'b1;
            o_canonical_src = `SRC_REMOTE;
            o_canonical_cmd = `CMD_STATUS;
            o_canonical_evt = `EVT_STATUS;
        end

        // 현재 revision에서는 btnL hold에 프로젝트 차원의 의미를 주지 않는다.
        // 다만 나중에 정책이 추가돼도 인터페이스를 다시 바꾸지 않도록
        // 입력 포트는 미리 열어 둔다.
        if (i_btnL_hold) begin
        end
    end

endmodule

// action_dispatcher는 context를 반영해 실제 의미를 부여하는 단계다.
// canonical event 하나를 받아서
// - function_unit 제어 pulse
// - sensor refresh request
// - event log metadata
// 로 바꾼다.
module action_dispatcher (
    input i_canonical_evt_valid,
    input [`SRC_W-1:0] i_canonical_src,
    input [`CMD_W-1:0] i_canonical_cmd,
    input [`EVT_W-1:0] i_canonical_evt,
    input i_canonical_step_tens,
    input [`CTX_W-1:0] i_current_context,
    input i_context_change_pulse,
    output reg o_watch_display_toggle_pulse,
    output reg o_watch_set_mode_toggle_pulse,
    output reg o_watch_set_index_next_pulse,
    output reg o_watch_value_inc_pulse,
    output reg o_watch_value_inc_tens_pulse,
    output reg o_watch_value_dec_pulse,
    output reg o_watch_value_dec_tens_pulse,
    output reg o_stopwatch_display_toggle_pulse,
    output reg o_stopwatch_clear_pulse,
    output reg o_stopwatch_count_dir_toggle_pulse,
    output reg o_stopwatch_run_toggle_pulse,
    output reg o_soft_clear_pulse,
    output reg o_sr04_refresh_req,
    output reg o_dht11_refresh_req,
    output reg [`SRC_W-1:0] o_log_src,
    output reg [`CMD_W-1:0] o_log_cmd,
    output reg [`EVT_W-1:0] o_log_evt,
    output reg [`ACT_W-1:0] o_log_act,
    output reg o_log_req
);

    always @(*) begin
        // 기본값은 "이번 cycle에 아무 동작도 없음"이다.
        // 실제로 의미가 있는 context/event만 필요한 신호를 덮어쓴다.
        o_watch_display_toggle_pulse = 1'b0;
        o_watch_set_mode_toggle_pulse = 1'b0;
        o_watch_set_index_next_pulse = 1'b0;
        o_watch_value_inc_pulse = 1'b0;
        o_watch_value_inc_tens_pulse = 1'b0;
        o_watch_value_dec_pulse = 1'b0;
        o_watch_value_dec_tens_pulse = 1'b0;
        o_stopwatch_display_toggle_pulse = 1'b0;
        o_stopwatch_clear_pulse = 1'b0;
        o_stopwatch_count_dir_toggle_pulse = 1'b0;
        o_stopwatch_run_toggle_pulse = 1'b0;
        o_soft_clear_pulse = 1'b0;
        o_sr04_refresh_req = 1'b0;
        o_dht11_refresh_req = 1'b0;
        o_log_src = `SRC_LOCAL;
        o_log_cmd = `CMD_NONE;
        o_log_evt = `EVT_NONE;
        o_log_act = `ACT_NONE;
        o_log_req = 1'b0;

        // 센서 refresh는 버튼성 command가 아니라 context 진입으로 발생한다.
        // 다만 이 자동 정책 동작도 event log에는 남긴다.
        if (i_context_change_pulse && (i_current_context == `CTX_SR04)) begin
            o_sr04_refresh_req = 1'b1;
            o_log_evt = `EVT_CONTEXT_ENTRY_REFRESH;
            o_log_act = `ACT_REFRESH_REQUEST;
        end else if (i_context_change_pulse && (i_current_context == `CTX_DHT11)) begin
            o_dht11_refresh_req = 1'b1;
            o_log_evt = `EVT_CONTEXT_ENTRY_REFRESH;
            o_log_act = `ACT_REFRESH_REQUEST;
        end

        if (i_canonical_evt_valid) begin
            o_log_src = i_canonical_src;
            o_log_cmd = i_canonical_cmd;
            o_log_evt = i_canonical_evt;
            o_log_act = `ACT_NO_ACTION;
            // canonical event가 valid라면, 나중에 context가 기능 동작을
            // 무시하더라도 event_log_unit 쪽에서는 이 요청을 볼 수 있어야 한다.
            o_log_req = 1'b1;

            case (i_canonical_evt)
                `EVT_SOFT_CLEAR: begin
                    o_soft_clear_pulse = 1'b1;
                    o_log_act = `ACT_SOFT_CLEAR;
                end

                `EVT_STATUS: begin
                    o_log_act = `ACT_STATUS_REPORT;
                end

                default: begin
                    case (i_current_context)
                        `CTX_WATCH: begin
                            // WATCH는 기존 watch_fsm 의도를 그대로 따른다.
                            // short up/down은 ones step, hold up/down은 tens step이다.
                            case (i_canonical_evt)
                                `EVT_BTNR_SHORT: begin
                                    o_watch_display_toggle_pulse = 1'b1;
                                    o_log_act = `ACT_DISPLAY_TOGGLE;
                                end
                                `EVT_BTNR_HOLD: begin
                                    o_watch_set_mode_toggle_pulse = 1'b1;
                                    o_log_act = `ACT_SET_MODE_TOGGLE;
                                end
                                `EVT_BTNL_SHORT: begin
                                    o_watch_set_index_next_pulse = 1'b1;
                                    o_log_act = `ACT_SET_INDEX_NEXT;
                                end
                                `EVT_BTNU_SHORT: begin
                                    if (i_canonical_step_tens) begin
                                        o_watch_value_inc_tens_pulse = 1'b1;
                                        o_log_act = `ACT_WATCH_VALUE_INC_TENS;
                                    end else begin
                                        o_watch_value_inc_pulse = 1'b1;
                                        o_log_act = `ACT_WATCH_VALUE_INC;
                                    end
                                end
                                `EVT_BTND_SHORT: begin
                                    if (i_canonical_step_tens) begin
                                        o_watch_value_dec_tens_pulse = 1'b1;
                                        o_log_act = `ACT_WATCH_VALUE_DEC_TENS;
                                    end else begin
                                        o_watch_value_dec_pulse = 1'b1;
                                        o_log_act = `ACT_WATCH_VALUE_DEC;
                                    end
                                end
                                default: begin
                                    o_log_act = `ACT_NO_ACTION;
                                end
                            endcase
                        end

                        `CTX_STOPWATCH: begin
                            // STOPWATCH는 기존 3버튼 제어 의미를 유지하고,
                            // btnR_short만 display mode 전환 의미를 공유한다.
                            case (i_canonical_evt)
                                `EVT_BTNR_SHORT: begin
                                    o_stopwatch_display_toggle_pulse = 1'b1;
                                    o_log_act = `ACT_DISPLAY_TOGGLE;
                                end
                                `EVT_BTNL_SHORT: begin
                                    o_stopwatch_clear_pulse = 1'b1;
                                    o_log_act = `ACT_STOPWATCH_CLEAR;
                                end
                                `EVT_BTNU_SHORT: begin
                                    o_stopwatch_count_dir_toggle_pulse = 1'b1;
                                    o_log_act = `ACT_STOPWATCH_COUNT_DIR_TOGGLE;
                                end
                                `EVT_BTND_SHORT: begin
                                    o_stopwatch_run_toggle_pulse = 1'b1;
                                    o_log_act = `ACT_STOPWATCH_RUN_TOGGLE;
                                end
                                default: begin
                                    o_log_act = `ACT_NO_ACTION;
                                end
                            endcase
                        end

                        `CTX_SR04,
                        `CTX_DHT11: begin
                            // 센서 context는 status/context-entry 정책에만 반응한다.
                            // 버튼 등가 command는 로그에는 남기되,
                            // 실제 기능 제어로는 의도적으로 연결하지 않는다.
                            o_log_act = `ACT_IGNORED_IN_SENSOR_CONTEXT;
                        end

                        default: begin
                            o_log_act = `ACT_NO_ACTION;
                        end
                    endcase
                end
            endcase
        end
    end

endmodule
