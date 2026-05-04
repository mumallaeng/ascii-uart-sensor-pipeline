`timescale 1ns / 1ps

module ascii_uart_sensor_pipeline (
    input clk,
    input rst,
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

    // Top-level integration skeleton.
    // INPUT-stage direct children are instantiated here first.
    // CONTROL / FUNCTION / OUTPUT blocks will be connected follow-up.

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

    wire [1:0] w_current_context;
    wire w_context_change_pulse;
    wire w_watch_12h;
    wire w_dht11_show_humi;

    wire w_cmd_btnR;
    wire w_cmd_btnR_hold;
    wire w_cmd_btnL;
    wire w_cmd_btnU;
    wire w_cmd_btnD;
    wire w_cmd_status;
    wire w_cmd_clr;
    wire w_unknown_cmd;

    input_conditioning U_INPUT_CONDITIONING (
        .clk(clk),
        .rst(rst),
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
        .rst(rst),
        .i_sw_context(sw[1:0]),
        .i_sw15(w_sw15),
        .o_current_context(w_current_context),
        .o_context_change_pulse(w_context_change_pulse),
        .o_watch_12h(w_watch_12h),
        .o_dht11_show_humi(w_dht11_show_humi)
    );

    remote_input_unit U_REMOTE_INPUT_UNIT (
        .clk(clk),
        .rst(rst),
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

    assign tx = 1'b1;
    assign trig = 1'b0;
    assign fnd_com = 4'b1111;
    assign fnd_data = 8'hFF;
    assign led = 3'b000;

endmodule
