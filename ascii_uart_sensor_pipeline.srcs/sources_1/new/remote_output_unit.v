`timescale 1ns / 1ps

`include "ascii_uart_sensor_pipeline_defs.vh"

// remote_output_unit은 decision/execute에서 올라온 메타와 상태를 모아
// remote UART TX용 ASCII log 응답으로 내보내는 OUTPUT 경계다.
module remote_output_unit #(
    parameter integer FRAME_MAX_BYTES = 120,
    parameter integer FRAME_LEN_W = (FRAME_MAX_BYTES <= 1) ? 1 : $clog2(FRAME_MAX_BYTES + 1),
    parameter integer TX_FIFO_DEPTH = 32
) (
    input clk,
    input rst,
    input i_unknown_cmd,
    input [`SRC_W-1:0] i_log_src,
    input [`CMD_W-1:0] i_log_cmd,
    input [`EVT_W-1:0] i_log_evt,
    input [`ACT_W-1:0] i_log_act,
    input i_log_req,
    input [`CTX_W-1:0] i_current_context,
    input [23:0] i_watch_live_time,
    input [4:0] i_stopwatch_hour,
    input [5:0] i_stopwatch_min,
    input [5:0] i_stopwatch_sec,
    input [11:0] i_sr04_distance_mm,
    input [7:0] i_dht_temp,
    input [7:0] i_dht_temp_frac,
    input [7:0] i_dht_humi,
    input [7:0] i_dht_humi_frac,
    input i_dht_show_humi,
    input i_dht_show_fahrenheit,
    input i_dht_valid,
    output o_tx
);

    wire w_collect_req;
    wire w_collect_unknown_cmd;
    wire [`SRC_W-1:0] w_collect_src;
    wire [`CMD_W-1:0] w_collect_cmd;
    wire [`EVT_W-1:0] w_collect_evt;
    wire [`ACT_W-1:0] w_collect_act;
    wire [`CTX_W-1:0] w_collect_ctx;
    wire [23:0] w_collect_watch_live_time;
    wire [4:0] w_collect_stopwatch_hour;
    wire [5:0] w_collect_stopwatch_min;
    wire [5:0] w_collect_stopwatch_sec;
    wire [11:0] w_collect_sr04_distance_mm;
    wire [7:0] w_collect_dht_temp;
    wire [7:0] w_collect_dht_temp_frac;
    wire [7:0] w_collect_dht_humi;
    wire [7:0] w_collect_dht_humi_frac;
    wire w_collect_dht_show_humi;
    wire w_collect_dht_show_fahrenheit;
    wire w_collect_dht_valid;

    reg r_pending_valid;
    reg r_pending_unknown_cmd;
    reg [`SRC_W-1:0] r_pending_src;
    reg [`CMD_W-1:0] r_pending_cmd;
    reg [`EVT_W-1:0] r_pending_evt;
    reg [`ACT_W-1:0] r_pending_act;
    reg [`CTX_W-1:0] r_pending_ctx;
    reg [23:0] r_pending_watch_live_time;
    reg [4:0] r_pending_stopwatch_hour;
    reg [5:0] r_pending_stopwatch_min;
    reg [5:0] r_pending_stopwatch_sec;
    reg [11:0] r_pending_sr04_distance_mm;
    reg [7:0] r_pending_dht_temp;
    reg [7:0] r_pending_dht_temp_frac;
    reg [7:0] r_pending_dht_humi;
    reg [7:0] r_pending_dht_humi_frac;
    reg r_pending_dht_show_humi;
    reg r_pending_dht_show_fahrenheit;
    reg r_pending_dht_valid;

    reg r_active_unknown_cmd;
    reg [`SRC_W-1:0] r_active_src;
    reg [`CMD_W-1:0] r_active_cmd;
    reg [`EVT_W-1:0] r_active_evt;
    reg [`ACT_W-1:0] r_active_act;
    reg [`CTX_W-1:0] r_active_ctx;
    reg [23:0] r_active_watch_live_time;
    reg [4:0] r_active_stopwatch_hour;
    reg [5:0] r_active_stopwatch_min;
    reg [5:0] r_active_stopwatch_sec;
    reg [11:0] r_active_sr04_distance_mm;
    reg [7:0] r_active_dht_temp;
    reg [7:0] r_active_dht_temp_frac;
    reg [7:0] r_active_dht_humi;
    reg [7:0] r_active_dht_humi_frac;
    reg r_active_dht_show_humi;
    reg r_active_dht_show_fahrenheit;
    reg r_active_dht_valid;

    wire [7:0] w_frame_byte;
    wire [FRAME_LEN_W-1:0] w_frame_len;
    wire [FRAME_LEN_W-1:0] w_frame_byte_index;
    wire w_tx_busy;
    wire w_tx_full;
    wire w_sender_start;

    log_entry_collector U_LOG_ENTRY_COLLECTOR (
        .i_unknown_cmd(i_unknown_cmd),
        .i_log_src(i_log_src),
        .i_log_cmd(i_log_cmd),
        .i_log_evt(i_log_evt),
        .i_log_act(i_log_act),
        .i_log_req(i_log_req),
        .i_current_context(i_current_context),
        .i_watch_live_time(i_watch_live_time),
        .i_stopwatch_hour(i_stopwatch_hour),
        .i_stopwatch_min(i_stopwatch_min),
        .i_stopwatch_sec(i_stopwatch_sec),
        .i_sr04_distance_mm(i_sr04_distance_mm),
        .i_dht_temp(i_dht_temp),
        .i_dht_temp_frac(i_dht_temp_frac),
        .i_dht_humi(i_dht_humi),
        .i_dht_humi_frac(i_dht_humi_frac),
        .i_dht_show_humi(i_dht_show_humi),
        .i_dht_show_fahrenheit(i_dht_show_fahrenheit),
        .i_dht_valid(i_dht_valid),
        .o_collect_req(w_collect_req),
        .o_unknown_cmd(w_collect_unknown_cmd),
        .o_log_src(w_collect_src),
        .o_log_cmd(w_collect_cmd),
        .o_log_evt(w_collect_evt),
        .o_log_act(w_collect_act),
        .o_current_context(w_collect_ctx),
        .o_watch_live_time(w_collect_watch_live_time),
        .o_stopwatch_hour(w_collect_stopwatch_hour),
        .o_stopwatch_min(w_collect_stopwatch_min),
        .o_stopwatch_sec(w_collect_stopwatch_sec),
        .o_sr04_distance_mm(w_collect_sr04_distance_mm),
        .o_dht_temp(w_collect_dht_temp),
        .o_dht_temp_frac(w_collect_dht_temp_frac),
        .o_dht_humi(w_collect_dht_humi),
        .o_dht_humi_frac(w_collect_dht_humi_frac),
        .o_dht_show_humi(w_collect_dht_show_humi),
        .o_dht_show_fahrenheit(w_collect_dht_show_fahrenheit),
        .o_dht_valid(w_collect_dht_valid)
    );

    // pending은 "다음에 보낼 status log 1건"을 잡아두는 1-depth queue다.
    // active는 "지금 송신 중인 status 정보 1건"을 고정해 두는 레지스터 묶음이다.
    // 이렇게 분리하면 sender가 1280-bit frame 전체를 다시 복사하지 않아도
    // in-flight frame이 중간에 바뀌지 않는다.
    assign w_sender_start = r_pending_valid && !w_tx_busy;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_pending_valid <= 1'b0;
            r_pending_unknown_cmd <= 1'b0;
            r_pending_src <= `SRC_LOCAL;
            r_pending_cmd <= `CMD_NONE;
            r_pending_evt <= `EVT_NONE;
            r_pending_act <= `ACT_NONE;
            r_pending_ctx <= `CTX_WATCH;
            r_pending_watch_live_time <= 24'd0;
            r_pending_stopwatch_hour <= 5'd0;
            r_pending_stopwatch_min <= 6'd0;
            r_pending_stopwatch_sec <= 6'd0;
            r_pending_sr04_distance_mm <= 12'd0;
            r_pending_dht_temp <= 8'd0;
            r_pending_dht_temp_frac <= 8'd0;
            r_pending_dht_humi <= 8'd0;
            r_pending_dht_humi_frac <= 8'd0;
            r_pending_dht_show_humi <= 1'b0;
            r_pending_dht_show_fahrenheit <= 1'b0;
            r_pending_dht_valid <= 1'b0;
            r_active_unknown_cmd <= 1'b0;
            r_active_src <= `SRC_LOCAL;
            r_active_cmd <= `CMD_NONE;
            r_active_evt <= `EVT_NONE;
            r_active_act <= `ACT_NONE;
            r_active_ctx <= `CTX_WATCH;
            r_active_watch_live_time <= 24'd0;
            r_active_stopwatch_hour <= 5'd0;
            r_active_stopwatch_min <= 6'd0;
            r_active_stopwatch_sec <= 6'd0;
            r_active_sr04_distance_mm <= 12'd0;
            r_active_dht_temp <= 8'd0;
            r_active_dht_temp_frac <= 8'd0;
            r_active_dht_humi <= 8'd0;
            r_active_dht_humi_frac <= 8'd0;
            r_active_dht_show_humi <= 1'b0;
            r_active_dht_show_fahrenheit <= 1'b0;
            r_active_dht_valid <= 1'b0;
        end else if (!r_pending_valid && w_collect_req) begin
            r_pending_valid <= 1'b1;
            r_pending_unknown_cmd <= w_collect_unknown_cmd;
            r_pending_src <= w_collect_src;
            r_pending_cmd <= w_collect_cmd;
            r_pending_evt <= w_collect_evt;
            r_pending_act <= w_collect_act;
            r_pending_ctx <= w_collect_ctx;
            r_pending_watch_live_time <= w_collect_watch_live_time;
            r_pending_stopwatch_hour <= w_collect_stopwatch_hour;
            r_pending_stopwatch_min <= w_collect_stopwatch_min;
            r_pending_stopwatch_sec <= w_collect_stopwatch_sec;
            r_pending_sr04_distance_mm <= w_collect_sr04_distance_mm;
            r_pending_dht_temp <= w_collect_dht_temp;
            r_pending_dht_temp_frac <= w_collect_dht_temp_frac;
            r_pending_dht_humi <= w_collect_dht_humi;
            r_pending_dht_humi_frac <= w_collect_dht_humi_frac;
            r_pending_dht_show_humi <= w_collect_dht_show_humi;
            r_pending_dht_show_fahrenheit <= w_collect_dht_show_fahrenheit;
            r_pending_dht_valid <= w_collect_dht_valid;
        end else if (w_sender_start) begin
            r_pending_valid <= 1'b0;
            r_active_unknown_cmd <= r_pending_unknown_cmd;
            r_active_src <= r_pending_src;
            r_active_cmd <= r_pending_cmd;
            r_active_evt <= r_pending_evt;
            r_active_act <= r_pending_act;
            r_active_ctx <= r_pending_ctx;
            r_active_watch_live_time <= r_pending_watch_live_time;
            r_active_stopwatch_hour <= r_pending_stopwatch_hour;
            r_active_stopwatch_min <= r_pending_stopwatch_min;
            r_active_stopwatch_sec <= r_pending_stopwatch_sec;
            r_active_sr04_distance_mm <= r_pending_sr04_distance_mm;
            r_active_dht_temp <= r_pending_dht_temp;
            r_active_dht_temp_frac <= r_pending_dht_temp_frac;
            r_active_dht_humi <= r_pending_dht_humi;
            r_active_dht_humi_frac <= r_pending_dht_humi_frac;
            r_active_dht_show_humi <= r_pending_dht_show_humi;
            r_active_dht_show_fahrenheit <= r_pending_dht_show_fahrenheit;
            r_active_dht_valid <= r_pending_dht_valid;
        end
    end

    ascii_log_formatter #(
        .FRAME_MAX_BYTES(FRAME_MAX_BYTES),
        .FRAME_LEN_W(FRAME_LEN_W)
    ) U_ASCII_LOG_FORMATTER (
        .i_byte_index(w_frame_byte_index),
        .i_unknown_cmd(r_active_unknown_cmd),
        .i_log_src(r_active_src),
        .i_log_cmd(r_active_cmd),
        .i_log_evt(r_active_evt),
        .i_current_context(r_active_ctx),
        .i_log_act(r_active_act),
        .i_watch_live_time(r_active_watch_live_time),
        .i_stopwatch_hour(r_active_stopwatch_hour),
        .i_stopwatch_min(r_active_stopwatch_min),
        .i_stopwatch_sec(r_active_stopwatch_sec),
        .i_sr04_distance_mm(r_active_sr04_distance_mm),
        .i_dht_temp(r_active_dht_temp),
        .i_dht_temp_frac(r_active_dht_temp_frac),
        .i_dht_humi(r_active_dht_humi),
        .i_dht_humi_frac(r_active_dht_humi_frac),
        .i_dht_show_humi(r_active_dht_show_humi),
        .i_dht_show_fahrenheit(r_active_dht_show_fahrenheit),
        .i_dht_valid(r_active_dht_valid),
        .o_frame_byte(w_frame_byte),
        .o_frame_len(w_frame_len)
    );

    uart_tx_unit #(
        .FRAME_LEN_W(FRAME_LEN_W),
        .FIFO_DEPTH(TX_FIFO_DEPTH)
    ) U_UART_TX_UNIT (
        .clk(clk),
        .rst(rst),
        .i_start(w_sender_start),
        .i_frame_byte(w_frame_byte),
        .i_frame_len(w_frame_len),
        .o_frame_byte_index(w_frame_byte_index),
        .o_busy(w_tx_busy),
        .o_full(w_tx_full),
        .o_tx(o_tx)
    );

endmodule

// log_entry_collector는 흩어진 상태/메타 신호를 remote_output_unit 기준으로 묶는다.
// 현재 revision에서는 별도 가공 없이 "이 status log를 잡아야 한다"는 경계만 분리한다.
module log_entry_collector (
    input i_unknown_cmd,
    input [`SRC_W-1:0] i_log_src,
    input [`CMD_W-1:0] i_log_cmd,
    input [`EVT_W-1:0] i_log_evt,
    input [`ACT_W-1:0] i_log_act,
    input i_log_req,
    input [`CTX_W-1:0] i_current_context,
    input [23:0] i_watch_live_time,
    input [4:0] i_stopwatch_hour,
    input [5:0] i_stopwatch_min,
    input [5:0] i_stopwatch_sec,
    input [11:0] i_sr04_distance_mm,
    input [7:0] i_dht_temp,
    input [7:0] i_dht_temp_frac,
    input [7:0] i_dht_humi,
    input [7:0] i_dht_humi_frac,
    input i_dht_show_humi,
    input i_dht_show_fahrenheit,
    input i_dht_valid,
    output o_collect_req,
    output o_unknown_cmd,
    output [`SRC_W-1:0] o_log_src,
    output [`CMD_W-1:0] o_log_cmd,
    output [`EVT_W-1:0] o_log_evt,
    output [`ACT_W-1:0] o_log_act,
    output [`CTX_W-1:0] o_current_context,
    output [23:0] o_watch_live_time,
    output [4:0] o_stopwatch_hour,
    output [5:0] o_stopwatch_min,
    output [5:0] o_stopwatch_sec,
    output [11:0] o_sr04_distance_mm,
    output [7:0] o_dht_temp,
    output [7:0] o_dht_temp_frac,
    output [7:0] o_dht_humi,
    output [7:0] o_dht_humi_frac,
    output o_dht_show_humi,
    output o_dht_show_fahrenheit,
    output o_dht_valid
);

    assign o_collect_req = i_unknown_cmd | i_log_req;
    assign o_unknown_cmd = i_unknown_cmd;
    assign o_log_src = i_log_src;
    assign o_log_cmd = i_log_cmd;
    assign o_log_evt = i_log_evt;
    assign o_log_act = i_log_act;
    assign o_current_context = i_current_context;
    assign o_watch_live_time = i_watch_live_time;
    assign o_stopwatch_hour = i_stopwatch_hour;
    assign o_stopwatch_min = i_stopwatch_min;
    assign o_stopwatch_sec = i_stopwatch_sec;
    assign o_sr04_distance_mm = i_sr04_distance_mm;
    assign o_dht_temp = i_dht_temp;
    assign o_dht_temp_frac = i_dht_temp_frac;
    assign o_dht_humi = i_dht_humi;
    assign o_dht_humi_frac = i_dht_humi_frac;
    assign o_dht_show_humi = i_dht_show_humi;
    assign o_dht_show_fahrenheit = i_dht_show_fahrenheit;
    assign o_dht_valid = i_dht_valid;

endmodule

// uart_tx_unit은 formatter가 만든 log frame을 1바이트씩 흘려 보내고,
// 그 바이트를 FIFO/UART 경계로 넘기는 OUTPUT 말단 블록이다.
module uart_tx_unit #(
    parameter integer FRAME_LEN_W = 8,
    parameter integer FIFO_DEPTH = 128
) (
    input clk,
    input rst,
    input i_start,
    input [7:0] i_frame_byte,
    input [FRAME_LEN_W-1:0] i_frame_len,
    output [FRAME_LEN_W-1:0] o_frame_byte_index,
    output o_busy,
    output o_full,
    output o_tx
);

    wire [7:0] w_push_data;
    wire w_push;

    log_byte_sender #(
        .FRAME_LEN_W(FRAME_LEN_W)
    ) U_LOG_BYTE_SENDER (
        .clk(clk),
        .rst(rst),
        .start(i_start),
        .i_tx_full(o_full),
        .i_frame_byte(i_frame_byte),
        .i_frame_len(i_frame_len),
        .o_frame_byte_index(o_frame_byte_index),
        .push_data(w_push_data),
        .push(w_push),
        .busy(o_busy)
    );

    uart_tx_fifo #(
        .FIFO_DEPTH(FIFO_DEPTH)
    ) U_UART_TX_FIFO (
        .clk(clk),
        .rst(rst),
        .i_push_data(w_push_data),
        .i_push(w_push),
        .o_full(o_full),
        .o_tx(o_tx)
    );

endmodule

// uart_tx_fifo는 log_byte_sender가 만든 바이트열을 FIFO에 적재하고,
// UART가 비는 순간 한 바이트씩 꺼내 직렬 송신한다.
module uart_tx_fifo #(
    parameter integer FIFO_DEPTH = 128
) (
    input clk,
    input rst,
    input [7:0] i_push_data,
    input i_push,
    output o_full,
    output o_tx
);

    wire [7:0] w_pop_data;
    wire w_fifo_full;
    wire w_fifo_empty;
    wire w_tx_busy;
    wire w_pop;

    assign w_pop = !w_fifo_empty && !w_tx_busy;
    assign o_full = w_fifo_full;

    fifo #(
        .DEPTH(FIFO_DEPTH)
    ) U_FIFO (
        .clk(clk),
        .rst(rst),
        .push_data(i_push_data),
        .push(i_push),
        .pop(w_pop),
        .pop_data(w_pop_data),
        .full(w_fifo_full),
        .empty(w_fifo_empty)
    );

    uart U_UART (
        .clk(clk),
        .rst(rst),
        .tx_start(w_pop),
        .tx_data(w_pop_data),
        .rx(1'b1),
        .rx_data(),
        .rx_done(),
        .tx_busy(w_tx_busy),
        .tx(o_tx)
    );

endmodule
