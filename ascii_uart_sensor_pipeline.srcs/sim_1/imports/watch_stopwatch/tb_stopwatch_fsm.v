`timescale 1ns / 1ps

module tb_stopwatch_fsm ();

    reg  clk;
    reg  rst;
    reg  i_btnD;
    reg  i_btnL;
    reg  i_btnU;
    reg  i_sw0;
    wire o_runstop;
    wire o_clear;
    wire o_updown;

    stopwatch_fsm U0 (
        .clk(clk),
        .rst(rst),
        .i_btnD(i_btnD),
        .i_btnL(i_btnL),
        .i_btnU(i_btnU),
        .i_sw0(i_sw0),
        .o_runstop(o_runstop),
        .o_clear(o_clear),
        .o_updown(o_updown)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        i_btnU = 0;
        i_btnL = 0;
        i_btnD = 0;
        repeat (3) @(negedge clk);
        rst = 0;

        repeat (3) @(negedge clk);

        begin : sw_off


            i_btnD = 1;
            @(negedge clk);
            i_btnD = 0;

            repeat (10) @(negedge clk);

            i_btnL = 1;
            @(negedge clk);
            i_btnL = 0;

            repeat (10) @(negedge clk);

            i_btnU = 1;
            @(negedge clk);
            i_btnU = 0;
        end
        repeat (20) @(negedge clk);
        i_sw0 = 1;
        begin
            i_btnD = 1;
            @(negedge clk);
            i_btnD = 0;

            repeat (10) @(negedge clk);

            i_btnL = 1;
            @(negedge clk);
            i_btnL = 0;

            repeat (10) @(negedge clk);

            i_btnU = 1;
            @(negedge clk);
            i_btnU = 0;
        end
        repeat (20) @(negedge clk);
        begin
            i_btnD = 1;
            @(negedge clk);
            i_btnD = 0;

            repeat (10) @(negedge clk);

            i_btnL = 1;
            @(negedge clk);
            i_btnL = 0;

            repeat (10) @(negedge clk);

            i_btnU = 1;
            @(negedge clk);
            i_btnU = 0;
        end


        $stop;

    end



endmodule
