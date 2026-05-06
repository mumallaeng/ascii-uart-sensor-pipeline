`timescale 1ns / 1ps

module tb_stopwatch_datapath ();

    reg clk;
    reg rst;
    reg i_clear, i_updown, i_runstop;
    wire [6:0] msec;
    wire [5:0] sec;
    wire [5:0] min;
    wire [4:0] hour;

    parameter SEC_DELAY = 1_000_000;
    parameter MIN_DELAY = SEC_DELAY * 60;

    stopwatch_datapath #(
        .MAIN_CLK_100MHZ(100_000_000),
        .BASIC_TIME     (100_000_000),
        .MSEC_WIDTH     (7),
        .SEC_WIDTH      (6),
        .MIN_WIDTH      (6),
        .HOUR_WIDTH     (5),
        .MSEC_TIMES     (100),
        .SEC_TIMES      (60),
        .MIN_TIMES      (60),
        .HOUR_TIMES     (24)
    ) U0 (
        .clk(clk),
        .rst(rst),
        .i_runstop(i_runstop),
        .i_clear(i_clear),
        .i_updown(i_updown),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        i_clear = 0;
        i_updown = 0;
        i_runstop = 0;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        rst = 0;

        i_runstop = 1;
        repeat (100) #(SEC_DELAY);




        i_clear = 1;
        repeat (1) #(SEC_DELAY);
        i_clear   = 0;

        i_runstop = 0;
        repeat (10) #(SEC_DELAY);


        i_updown = 1;
        repeat (100) #(SEC_DELAY);

        $finish;
        $stop;
    end




endmodule
