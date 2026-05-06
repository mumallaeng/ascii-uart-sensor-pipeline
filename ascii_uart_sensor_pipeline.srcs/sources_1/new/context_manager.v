`timescale 1ns / 1ps

`include "ascii_uart_sensor_pipeline_defs.vh"

module context_manager (
    input clk,
    input rst,
    input [1:0] i_sw_context,
    input i_sw15,
    output reg [`CTX_W-1:0] o_current_context,
    output reg o_context_change_pulse,
    output o_watch_12h,
    output o_dht11_show_humi,
    output o_dht11_show_fahrenheit
);

    // sw[1:0], sw15는 보드의 기계식/비동기 입력이므로
    // context_manager 안에서 먼저 2FF synchronizer를 거친 뒤 해석한다.
    // 이렇게 하면 context 전환과 sensor view decode가 clk edge 근처 전환에 덜 민감해진다.
    reg [1:0] r_sw_context_ff0;
    reg [1:0] r_sw_context_ff1;
    reg       r_sw15_ff0;
    reg       r_sw15_ff1;

    wire [`CTX_W-1:0] w_decoded_context;

    assign w_decoded_context =
        (r_sw_context_ff1 == 2'b00) ? `CTX_WATCH :
        (r_sw_context_ff1 == 2'b01) ? `CTX_STOPWATCH :
        (r_sw_context_ff1 == 2'b10) ? (r_sw15_ff1 ? `CTX_DHT11 : `CTX_SR04) :
                                      `CTX_DHT11;

    assign o_watch_12h = (o_current_context == `CTX_WATCH) && r_sw15_ff1;
    assign o_dht11_show_humi = (r_sw_context_ff1 == 2'b10) && r_sw15_ff1;
    assign o_dht11_show_fahrenheit = (r_sw_context_ff1 == 2'b11) && r_sw15_ff1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_sw_context_ff0 <= 2'b00;
            r_sw_context_ff1 <= 2'b00;
            r_sw15_ff0 <= 1'b0;
            r_sw15_ff1 <= 1'b0;
            o_current_context <= `CTX_WATCH;
            o_context_change_pulse <= 1'b0;
        end else begin
            r_sw_context_ff0 <= i_sw_context;
            r_sw_context_ff1 <= r_sw_context_ff0;
            r_sw15_ff0 <= i_sw15;
            r_sw15_ff1 <= r_sw15_ff0;

            o_context_change_pulse <= (w_decoded_context != o_current_context);
            o_current_context <= w_decoded_context;
        end
    end

endmodule
