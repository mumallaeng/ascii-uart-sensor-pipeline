`timescale 1ns / 1ps

module tb_legacy_stopwatch_datapath ();

    localparam integer FAST_TICK_DIV = 2;

    reg clk;
    reg rst;
    reg i_run_stop;
    reg i_clear;
    reg i_down_mode;
    reg tb_tick_100hz;

    integer fast_tick_count;

    wire [6:0] msec;
    wire [5:0] sec;
    wire [5:0] min;
    wire [4:0] hour;

    legacy_stopwatch_datapath dut (
        .clk(clk),
        .rst(rst),
        .i_run_stop(i_run_stop),
        .i_clear(i_clear),
        .i_down_mode(i_down_mode),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );

    always #5 clk = ~clk;

    initial begin
        force dut.w_tick_100hz = tb_tick_100hz;
    end

    always @(negedge clk or posedge rst) begin
        if (rst) begin
            tb_tick_100hz   <= 1'b0;
            fast_tick_count <= 0;
        end else if (!i_run_stop || i_clear) begin
            tb_tick_100hz   <= 1'b0;
            fast_tick_count <= 0;
        end else if (fast_tick_count == FAST_TICK_DIV - 1) begin
            tb_tick_100hz   <= 1'b1;
            fast_tick_count <= 0;
        end else begin
            tb_tick_100hz   <= 1'b0;
            fast_tick_count <= fast_tick_count + 1;
        end
    end

    task wait_clks;
        input integer cycles;
        integer i;
        begin
            for (i = 0; i < cycles; i = i + 1) begin
                @(negedge clk);
            end
        end
    endtask

    task preload_time;
        input [4:0] preload_hour;
        input [5:0] preload_min;
        input [5:0] preload_sec;
        input [6:0] preload_msec;
        begin
            dut.U_HOUR_COUNTER.count_reg = preload_hour;
            dut.U_MIN_COUNTER.count_reg  = preload_min;
            dut.U_SEC_COUNTER.count_reg  = preload_sec;
            dut.U_MSEC_COUNTER.count_reg = preload_msec;
            #1;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        i_run_stop = 1'b0;
        i_clear = 1'b0;
        i_down_mode = 1'b0;

        wait_clks(3);
        rst = 1'b0;

        preload_time(5'd22, 6'd59, 6'd59, 7'd99);
        i_run_stop = 1'b1;
        wait (hour == 5'd23 && min == 6'd0 && sec == 6'd0 && msec == 7'd0);

        i_clear = 1'b1;
        wait_clks(2);
        if (msec !== 0 || sec !== 0 || min !== 0 || hour !== 0) begin
            $display("ERROR: clear failed. hour=%0d min=%0d sec=%0d msec=%0d",
                     hour, min, sec, msec);
            release dut.w_tick_100hz;
            $stop;
        end
        i_clear = 1'b0;

        i_down_mode = 1'b1;
        wait (hour == 5'd23 && min == 6'd59 && sec == 6'd59 && msec == 7'd99);

        $display("PASS: stopwatch datapath simulation finished quickly.");
        release dut.w_tick_100hz;
        $finish;
    end

endmodule
