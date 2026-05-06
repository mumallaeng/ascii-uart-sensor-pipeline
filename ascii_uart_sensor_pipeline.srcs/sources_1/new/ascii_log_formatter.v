`timescale 1ns / 1ps

`include "ascii_uart_sensor_pipeline_defs.vh"

module ascii_log_formatter #(
    parameter integer FRAME_MAX_BYTES = 120,
    parameter integer FRAME_LEN_W = (FRAME_MAX_BYTES <= 1) ? 1 : $clog2(FRAME_MAX_BYTES + 1)
) (
    input      [FRAME_LEN_W-1:0] i_byte_index,
    input                         i_unknown_cmd,
    input      [`SRC_W-1:0]      i_log_src,
    input      [`CMD_W-1:0]      i_log_cmd,
    input      [`EVT_W-1:0]      i_log_evt,
    input      [`CTX_W-1:0]      i_current_context,
    input      [`ACT_W-1:0]      i_log_act,
    input      [23:0]            i_watch_live_time,
    input      [4:0]             i_stopwatch_hour,
    input      [5:0]             i_stopwatch_min,
    input      [5:0]             i_stopwatch_sec,
    input      [11:0]            i_sr04_distance_mm,
    input      [7:0]             i_dht_temp,
    input      [7:0]             i_dht_temp_frac,
    input      [7:0]             i_dht_humi,
    input      [7:0]             i_dht_humi_frac,
    input                        i_dht_show_humi,
    input                        i_dht_show_fahrenheit,
    input                        i_dht_valid,
    output reg [7:0]                   o_frame_byte,
    output reg [FRAME_LEN_W-1:0]       o_frame_len
);

    localparam [7:0] ASCII_ZERO    = 8'h30;
    localparam [7:0] ASCII_EQUALS  = 8'h3D;
    localparam [7:0] ASCII_COLON   = 8'h3A;
    localparam [7:0] ASCII_SLASH   = 8'h2F;
    localparam [7:0] ASCII_PERCENT = 8'h25;
    localparam [7:0] ASCII_CR      = 8'h0D;
    localparam [7:0] ASCII_LF      = 8'h0A;

    reg [FRAME_LEN_W-1:0] write_idx;
    wire w_src_remote;

    assign w_src_remote = i_log_src[0];

    task clear_frame;
        begin
            o_frame_byte = 8'h00;
            o_frame_len = {FRAME_LEN_W{1'b0}};
            write_idx = {FRAME_LEN_W{1'b0}};
        end
    endtask

    task append_byte;
        input [7:0] value;
        begin
            if (write_idx < FRAME_MAX_BYTES) begin
                if (write_idx == i_byte_index) begin
                    o_frame_byte = value;
                end
                write_idx = write_idx + 1;
            end
        end
    endtask

    task append_crlf;
        begin
            append_byte(ASCII_CR);
            append_byte(ASCII_LF);
        end
    endtask

    task append_ascii_char;
        input [7:0] value;
        begin
            append_byte(value);
        end
    endtask

    task append_dec2;
        input [7:0] value;
        begin
            append_byte(ASCII_ZERO + ((value / 10) % 10));
            append_byte(ASCII_ZERO + (value % 10));
        end
    endtask

    task append_dec3;
        input [11:0] value;
        begin
            append_byte(ASCII_ZERO + ((value / 100) % 10));
            append_byte(ASCII_ZERO + ((value / 10) % 10));
            append_byte(ASCII_ZERO + (value % 10));
        end
    endtask

    task append_fixed1_from_mm;
        input [11:0] value_mm;
        reg [11:0] value_cm_int;
        reg [3:0] value_cm_frac;
        begin
            value_cm_int = value_mm / 10;
            value_cm_frac = value_mm % 10;
            append_dec3(value_cm_int);
            append_ascii_char(".");
            append_byte(ASCII_ZERO + value_cm_frac);
        end
    endtask

    task append_fixed2;
        input [7:0] value_int;
        input [7:0] value_frac;
        begin
            append_dec2(value_int);
            append_ascii_char(".");
            append_dec2(value_frac);
        end
    endtask

    task append_fixed1_fahrenheit;
        input [7:0] value_c_int;
        input [7:0] value_c_frac;
        reg [15:0] value_c_x100;
        reg [15:0] value_f_x100;
        reg [11:0] value_f_x10;
        begin
            value_c_x100 = (value_c_int * 16'd100) + value_c_frac;
            value_f_x100 = ((value_c_x100 * 16'd9) / 16'd5) + 16'd3200;
            value_f_x10 = value_f_x100 / 10;
            append_dec3((value_f_x10 / 10) % 1000);
            append_ascii_char(".");
            append_byte(ASCII_ZERO + (value_f_x10 % 10));
        end
    endtask

    task append_line_src;
        begin
            append_ascii_char("S");
            append_ascii_char("R");
            append_ascii_char("C");
            append_byte(ASCII_EQUALS);
            if (w_src_remote) begin
                append_ascii_char("r");
                append_ascii_char("m");
                append_ascii_char("t");
            end else begin
                append_ascii_char("l");
                append_ascii_char("c");
                append_ascii_char("l");
            end
            append_crlf();
        end
    endtask

    task append_line_cmd;
        begin
            append_ascii_char("C");
            append_ascii_char("M");
            append_ascii_char("D");
            append_byte(ASCII_EQUALS);
            case (i_log_cmd)
                `CMD_BTNR: begin
                    append_ascii_char("b");
                    append_ascii_char("t");
                    append_ascii_char("n");
                    append_ascii_char("R");
                end
                `CMD_BTNR_HOLD: begin
                    append_ascii_char("b");
                    append_ascii_char("t");
                    append_ascii_char("n");
                    append_ascii_char("R");
                    append_ascii_char("_");
                    append_ascii_char("h");
                end
                `CMD_BTNL: begin
                    append_ascii_char("b");
                    append_ascii_char("t");
                    append_ascii_char("n");
                    append_ascii_char("L");
                end
                `CMD_BTNU: begin
                    append_ascii_char("b");
                    append_ascii_char("t");
                    append_ascii_char("n");
                    append_ascii_char("U");
                end
                `CMD_BTND: begin
                    append_ascii_char("b");
                    append_ascii_char("t");
                    append_ascii_char("n");
                    append_ascii_char("D");
                end
                `CMD_STATUS: begin
                    append_ascii_char("s");
                    append_ascii_char("t");
                    append_ascii_char("a");
                    append_ascii_char("t");
                end
                `CMD_CLR: begin
                    append_ascii_char("c");
                    append_ascii_char("l");
                    append_ascii_char("r");
                end
                default: begin
                    append_ascii_char("n");
                    append_ascii_char("o");
                    append_ascii_char("n");
                    append_ascii_char("e");
                end
            endcase
            append_crlf();
        end
    endtask

    task append_line_evt;
        begin
            append_ascii_char("E");
            append_ascii_char("V");
            append_ascii_char("T");
            append_byte(ASCII_EQUALS);
            case (i_log_evt)
                `EVT_BTNR_SHORT: begin
                    append_ascii_char("b");
                    append_ascii_char("t");
                    append_ascii_char("n");
                    append_ascii_char("R");
                    append_ascii_char("_");
                    append_ascii_char("s");
                end
                `EVT_BTNR_HOLD: begin
                    append_ascii_char("b");
                    append_ascii_char("t");
                    append_ascii_char("n");
                    append_ascii_char("R");
                    append_ascii_char("_");
                    append_ascii_char("h");
                end
                `EVT_BTNL_SHORT: begin
                    append_ascii_char("b");
                    append_ascii_char("t");
                    append_ascii_char("n");
                    append_ascii_char("L");
                    append_ascii_char("_");
                    append_ascii_char("s");
                end
                `EVT_BTNU_SHORT: begin
                    append_ascii_char("b");
                    append_ascii_char("t");
                    append_ascii_char("n");
                    append_ascii_char("U");
                    append_ascii_char("_");
                    append_ascii_char("s");
                end
                `EVT_BTND_SHORT: begin
                    append_ascii_char("b");
                    append_ascii_char("t");
                    append_ascii_char("n");
                    append_ascii_char("D");
                    append_ascii_char("_");
                    append_ascii_char("s");
                end
                `EVT_STATUS: begin
                    append_ascii_char("s");
                    append_ascii_char("t");
                    append_ascii_char("a");
                    append_ascii_char("t");
                end
                `EVT_SOFT_CLEAR: begin
                    append_ascii_char("s");
                    append_ascii_char("o");
                    append_ascii_char("f");
                    append_ascii_char("t");
                    append_ascii_char("_");
                    append_ascii_char("c");
                    append_ascii_char("l");
                    append_ascii_char("r");
                end
                `EVT_CONTEXT_ENTRY_REFRESH: begin
                    append_ascii_char("c");
                    append_ascii_char("t");
                    append_ascii_char("x");
                    append_ascii_char("_");
                    append_ascii_char("r");
                    append_ascii_char("e");
                    append_ascii_char("f");
                end
                `EVT_IGNORED: begin
                    append_ascii_char("i");
                    append_ascii_char("g");
                    append_ascii_char("n");
                    append_ascii_char("o");
                    append_ascii_char("r");
                    append_ascii_char("e");
                    append_ascii_char("d");
                end
                default: begin
                    append_ascii_char("n");
                    append_ascii_char("o");
                    append_ascii_char("n");
                    append_ascii_char("e");
                end
            endcase
            append_crlf();
        end
    endtask

    task append_line_ctx;
        begin
            append_ascii_char("C");
            append_ascii_char("T");
            append_ascii_char("X");
            append_byte(ASCII_EQUALS);
            case (i_current_context)
                `CTX_WATCH: begin
                    append_ascii_char("w");
                    append_ascii_char("t");
                end
                `CTX_STOPWATCH: begin
                    append_ascii_char("s");
                    append_ascii_char("w");
                end
                `CTX_SR04: begin
                    append_ascii_char("s");
                    append_ascii_char("r");
                    append_ascii_char("0");
                    append_ascii_char("4");
                end
                default: begin
                    append_ascii_char("d");
                    append_ascii_char("h");
                    append_ascii_char("t");
                    append_ascii_char("1");
                    append_ascii_char("1");
                end
            endcase
            append_crlf();
        end
    endtask

    task append_line_act;
        begin
            append_ascii_char("A");
            append_ascii_char("C");
            append_ascii_char("T");
            append_byte(ASCII_EQUALS);
            case (i_log_act)
                `ACT_DISPLAY_TOGGLE: begin
                    append_ascii_char("d");
                    append_ascii_char("i");
                    append_ascii_char("s");
                    append_ascii_char("p");
                    append_ascii_char("_");
                    append_ascii_char("t");
                    append_ascii_char("g");
                    append_ascii_char("l");
                    append_ascii_char("e");
                end
                `ACT_SET_MODE_TOGGLE: begin
                    append_ascii_char("s");
                    append_ascii_char("e");
                    append_ascii_char("t");
                    append_ascii_char("_");
                    append_ascii_char("t");
                    append_ascii_char("g");
                    append_ascii_char("l");
                    append_ascii_char("e");
                end
                `ACT_SET_INDEX_NEXT: begin
                    append_ascii_char("i");
                    append_ascii_char("n");
                    append_ascii_char("d");
                    append_ascii_char("x");
                    append_ascii_char("_");
                    append_ascii_char("n");
                    append_ascii_char("e");
                    append_ascii_char("x");
                    append_ascii_char("t");
                end
                `ACT_WATCH_VALUE_INC: begin
                    append_ascii_char("w");
                    append_ascii_char("_");
                    append_ascii_char("i");
                    append_ascii_char("n");
                    append_ascii_char("c");
                end
                `ACT_WATCH_VALUE_INC_TENS: begin
                    append_ascii_char("w");
                    append_ascii_char("_");
                    append_ascii_char("i");
                    append_ascii_char("n");
                    append_ascii_char("c");
                    append_ascii_char("1");
                    append_ascii_char("0");
                end
                `ACT_WATCH_VALUE_DEC: begin
                    append_ascii_char("w");
                    append_ascii_char("_");
                    append_ascii_char("d");
                    append_ascii_char("e");
                    append_ascii_char("c");
                end
                `ACT_WATCH_VALUE_DEC_TENS: begin
                    append_ascii_char("w");
                    append_ascii_char("_");
                    append_ascii_char("d");
                    append_ascii_char("e");
                    append_ascii_char("c");
                    append_ascii_char("1");
                    append_ascii_char("0");
                end
                `ACT_STOPWATCH_CLEAR: begin
                    append_ascii_char("s");
                    append_ascii_char("w");
                    append_ascii_char("_");
                    append_ascii_char("c");
                    append_ascii_char("l");
                    append_ascii_char("r");
                end
                `ACT_STOPWATCH_COUNT_DIR_TOGGLE: begin
                    append_ascii_char("s");
                    append_ascii_char("w");
                    append_ascii_char("_");
                    append_ascii_char("d");
                    append_ascii_char("i");
                    append_ascii_char("r");
                    append_ascii_char("_");
                    append_ascii_char("t");
                    append_ascii_char("g");
                    append_ascii_char("l");
                    append_ascii_char("e");
                end
                `ACT_STOPWATCH_RUN_TOGGLE: begin
                    append_ascii_char("s");
                    append_ascii_char("w");
                    append_ascii_char("_");
                    append_ascii_char("r");
                    append_ascii_char("u");
                    append_ascii_char("n");
                    append_ascii_char("_");
                    append_ascii_char("t");
                    append_ascii_char("g");
                    append_ascii_char("l");
                    append_ascii_char("e");
                end
                `ACT_STATUS_REPORT: begin
                    append_ascii_char("s");
                    append_ascii_char("t");
                    append_ascii_char("a");
                    append_ascii_char("t");
                    append_ascii_char("_");
                    append_ascii_char("r");
                    append_ascii_char("p");
                    append_ascii_char("t");
                end
                `ACT_SOFT_CLEAR: begin
                    append_ascii_char("s");
                    append_ascii_char("o");
                    append_ascii_char("f");
                    append_ascii_char("t");
                    append_ascii_char("_");
                    append_ascii_char("c");
                    append_ascii_char("l");
                    append_ascii_char("r");
                end
                `ACT_IGNORED_IN_SENSOR_CONTEXT: begin
                    append_ascii_char("i");
                    append_ascii_char("g");
                    append_ascii_char("n");
                    append_ascii_char("_");
                    append_ascii_char("s");
                    append_ascii_char("e");
                    append_ascii_char("n");
                    append_ascii_char("s");
                    append_ascii_char("o");
                    append_ascii_char("r");
                end
                `ACT_REFRESH_REQUEST: begin
                    append_ascii_char("r");
                    append_ascii_char("e");
                    append_ascii_char("f");
                    append_ascii_char("r");
                    append_ascii_char("e");
                    append_ascii_char("s");
                    append_ascii_char("h");
                    append_ascii_char("_");
                    append_ascii_char("r");
                    append_ascii_char("q");
                end
                default: begin
                    append_ascii_char("n");
                    append_ascii_char("o");
                    append_ascii_char("n");
                    append_ascii_char("e");
                end
            endcase
            append_crlf();
        end
    endtask

    task append_line_watch;
        begin
            append_ascii_char("W");
            append_ascii_char("T");
            append_byte(ASCII_EQUALS);
            append_dec2({3'b000, i_watch_live_time[23:19]});
            append_byte(ASCII_COLON);
            append_dec2({2'b00, i_watch_live_time[18:13]});
            append_byte(ASCII_COLON);
            append_dec2({2'b00, i_watch_live_time[12:7]});
            append_crlf();
        end
    endtask

    task append_line_stopwatch;
        begin
            append_ascii_char("S");
            append_ascii_char("W");
            append_byte(ASCII_EQUALS);
            append_dec2({3'b000, i_stopwatch_hour});
            append_byte(ASCII_COLON);
            append_dec2({2'b00, i_stopwatch_min});
            append_byte(ASCII_COLON);
            append_dec2({2'b00, i_stopwatch_sec});
            append_crlf();
        end
    endtask

    task append_line_sr04;
        begin
            append_ascii_char("S");
            append_ascii_char("R");
            append_ascii_char("0");
            append_ascii_char("4");
            append_byte(ASCII_EQUALS);
            append_fixed1_from_mm(i_sr04_distance_mm);
            append_ascii_char("c");
            append_ascii_char("m");
            append_crlf();
        end
    endtask

    task append_line_dht11;
        begin
            append_ascii_char("D");
            append_ascii_char("H");
            append_ascii_char("T");
            append_ascii_char("1");
            append_ascii_char("1");
            append_byte(ASCII_EQUALS);
            if (!i_dht_valid) begin
                append_ascii_char("I");
                append_ascii_char("N");
                append_ascii_char("V");
                append_ascii_char("A");
                append_ascii_char("L");
                append_ascii_char("I");
                append_ascii_char("D");
            end else if (i_dht_show_humi) begin
                append_fixed2(i_dht_humi, i_dht_humi_frac);
                append_byte(ASCII_PERCENT);
            end else if (i_dht_show_fahrenheit) begin
                append_fixed1_fahrenheit(i_dht_temp, i_dht_temp_frac);
                append_ascii_char("F");
            end else begin
                append_fixed2(i_dht_temp, i_dht_temp_frac);
                append_ascii_char("C");
            end
            append_crlf();
        end
    endtask

    task append_error_frame;
        begin
            append_ascii_char("E");
            append_ascii_char("R");
            append_ascii_char("R");
            append_byte(ASCII_EQUALS);
            append_ascii_char("u");
            append_ascii_char("n");
            append_ascii_char("k");
            append_ascii_char("_");
            append_ascii_char("c");
            append_ascii_char("m");
            append_ascii_char("d");
            append_crlf();
            append_crlf();
        end
    endtask

    // formatter는 "전체 frame 버스" 대신 "현재 byte index에 해당하는 문자 1개"만 계산한다.
    // 이렇게 하면 status log 문자열 폭이 커져도 1280-bit 대형 버스를 만들지 않는다.
    always @(i_byte_index or i_unknown_cmd or i_log_src or i_log_cmd or i_log_evt or
             i_current_context or i_log_act or i_watch_live_time or
             i_stopwatch_hour or i_stopwatch_min or i_stopwatch_sec or
             i_sr04_distance_mm or i_dht_temp or i_dht_temp_frac or
             i_dht_humi or i_dht_humi_frac or
             i_dht_show_humi or i_dht_show_fahrenheit or
             i_dht_valid) begin
        clear_frame();

        if (i_unknown_cmd) begin
            append_error_frame();
        end else begin
            append_line_src();
            append_line_cmd();
            append_line_evt();
            append_line_ctx();
            append_line_act();
            append_line_watch();
            append_line_stopwatch();
            append_line_sr04();
            append_line_dht11();
            append_crlf();
        end

        o_frame_len = write_idx[FRAME_LEN_W-1:0];
    end

endmodule
