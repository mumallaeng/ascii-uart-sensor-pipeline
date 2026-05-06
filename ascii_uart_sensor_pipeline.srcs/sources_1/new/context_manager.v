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
    output o_dht11_show_humi
);

    // Project note:
    // - This block intentionally uses the raw switch inputs in the current
    //   revision. Synchronizer insertion is left for a later follow-up step.
    // - sw[1:0] selects the top-level context.
    // - sw15 is decoded as a context-specific option only after the context is known.

    wire [`CTX_W-1:0] w_decoded_context;

    assign w_decoded_context = i_sw_context;
    assign o_watch_12h = (o_current_context == `CTX_WATCH) && i_sw15;
    assign o_dht11_show_humi = (o_current_context == `CTX_DHT11) && i_sw15;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            o_current_context <= `CTX_WATCH;
            o_context_change_pulse <= 1'b0;
        end else begin
            o_context_change_pulse <= (w_decoded_context != o_current_context);
            o_current_context <= w_decoded_context;
        end
    end

endmodule
