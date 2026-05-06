`timescale 1ns / 1ps

module input_conditioning #(
    parameter CLK_FREQ_HZ      = 100_000_000,
    parameter BD_HZ            = 100_000,
    parameter HOLD_TIME_BTN_R  = 200_000_000,
    parameter HOLD_TIME_BTN_UD = 150_000_000,
    parameter HOLD_TIME_BTN_L  = 150_000_000,
    parameter HOLD_TIME_BTN_C  = 1_000_000_000,
    parameter REPEAT_TIME_BTN_UD = 20_000_000
) (
    input clk,
    input rst,
    input btnU,
    input btnD,
    input btnL,
    input btnR,
    input btnC,
    input sw0,
    input sw15,
    output o_btnU,
    output o_btnD,
    output o_btnL,
    output o_btnR,
    output o_btnC,
    output o_btnU_hold,
    output o_btnD_hold,
    output o_btnL_hold,
    output o_btnR_hold,
    output o_sw0,
    output o_sw15
);

    // Project note:
    // - btnU/D/L/R keep the original watch_stopwatch short/hold semantics.
    // - btnC is added as a project-level clear input and only uses short pulse.
    // - sw0/sw15 pass-through stays for legacy watch_stopwatch compatibility.
    assign o_sw0  = sw0;
    assign o_sw15 = sw15;

    debouncer #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BD_HZ(BD_HZ),
        .HOLD_TIME(HOLD_TIME_BTN_UD),
        .REPEAT_ENABLE(1),
        .REPEAT_TIME(REPEAT_TIME_BTN_UD)
    ) U_BTN_U (
        .clk(clk),
        .rst(rst),
        .i_btn(btnU),
        .o_btn(o_btnU),
        .o_btn_hold(o_btnU_hold)
    );

    debouncer #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BD_HZ(BD_HZ),
        .HOLD_TIME(HOLD_TIME_BTN_UD),
        .REPEAT_ENABLE(1),
        .REPEAT_TIME(REPEAT_TIME_BTN_UD)
    ) U_BTN_D (
        .clk(clk),
        .rst(rst),
        .i_btn(btnD),
        .o_btn(o_btnD),
        .o_btn_hold(o_btnD_hold)
    );

    debouncer #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BD_HZ(BD_HZ),
        .HOLD_TIME(HOLD_TIME_BTN_L)
    ) U_BTN_L (
        .clk(clk),
        .rst(rst),
        .i_btn(btnL),
        .o_btn(o_btnL),
        .o_btn_hold(o_btnL_hold)
    );

    debouncer #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BD_HZ(BD_HZ),
        .HOLD_TIME(HOLD_TIME_BTN_R)
    ) U_BTN_R (
        .clk(clk),
        .rst(rst),
        .i_btn(btnR),
        .o_btn(o_btnR),
        .o_btn_hold(o_btnR_hold)
    );

    // btnC is intentionally short-pulse only. A very large HOLD_TIME keeps the
    // debouncer from converting normal test/button use into hold behavior.
    debouncer #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BD_HZ(BD_HZ),
        .HOLD_TIME(HOLD_TIME_BTN_C)
    ) U_BTN_C (
        .clk(clk),
        .rst(rst),
        .i_btn(btnC),
        .o_btn(o_btnC),
        .o_btn_hold()
    );

endmodule
