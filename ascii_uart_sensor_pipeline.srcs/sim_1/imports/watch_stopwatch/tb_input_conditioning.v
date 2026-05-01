`timescale 1ns / 1ps

module tb_input_conditioning ();

    reg  clk;
    reg  rst;
    reg  btnU;
    reg  btnD;
    reg  btnL;
    reg  btnR;
    reg  sw0;
    reg  sw15;
    wire o_btnU;
    wire o_btnD;
    wire o_btnL;
    wire o_btnR;
    wire o_btnU_hold;
    wire o_btnD_hold;
    wire o_btnL_hold;
    wire o_btnR_hold;
    wire o_sw0;
    wire o_sw15;

    input_conditioning #(
        .CLK_FREQ_HZ(100_000_000),  // 100MHz
        .BD_HZ      (100_000),      // 100k
        .HOLD_TIME_BTN_R(100_000),
        .HOLD_TIME_BTN_UD(100_000),
        .HOLD_TIME_BTN_L(100_000),
        .REPEAT_TIME_BTN_UD(20_000)
    ) U0 (
        .clk(clk),
        .rst(rst),
        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),
        .sw0(sw0),
        .sw15(sw15),
        .o_btnU(o_btnU),
        .o_btnD(o_btnD),
        .o_btnL(o_btnL),
        .o_btnR(o_btnR),
        .o_btnU_hold(o_btnU_hold),
        .o_btnD_hold(o_btnD_hold),
        .o_btnL_hold(o_btnL_hold),
        .o_btnR_hold(o_btnR_hold),
        .o_sw0(o_sw0),
        .o_sw15(o_sw15)
    );

    always #5 clk = ~clk;

    initial begin
        clk  = 0;
        rst  = 1;
        btnU = 0;
        btnD = 0;
        btnL = 0;
        btnR = 0;
        sw0  = 0;
        sw15 = 0;
        repeat (3) @(negedge clk);
        rst = 0;
        #10;
        btnU = 1;
        btnD = 1;
        btnL = 1;
        btnR = 1;

        #(5 * 1000000);
        btnU = 0;
        btnD = 0;
        btnL = 0;
        btnR = 0;

        repeat (3) @(negedge clk);

        sw0  = 1;
        sw15 = 1;
        repeat (1000) @(negedge clk);
        sw0  = 0;
        sw15 = 0;
        #20;
        $stop;
    end





endmodule
