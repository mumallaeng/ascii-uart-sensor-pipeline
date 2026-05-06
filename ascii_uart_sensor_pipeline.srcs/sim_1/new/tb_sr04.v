`timescale 1ns / 1ps

module tb_sr04 ();

    localparam CLK_PERIOD_NS = 10;
    localparam SIM_TIMEOUT_NS = 5_000;

    reg clk;
    reg rst;
    wire w_tick_us;
    integer tick_count;
    time last_tick_time;

    sr04_tick_gen_us dut2 (
        .clk(clk),
        .rst(rst),
        .tick_us(w_tick_us)
    );

    always #(CLK_PERIOD_NS / 2) clk = ~clk;

    initial begin
        clk            = 0;
        rst            = 1;
        tick_count     = 0;
        last_tick_time = 0;

        #20;
        rst = 0;

        #SIM_TIMEOUT_NS;
        $display("FAIL: w_tick_us did not pulse within %0d ns", SIM_TIMEOUT_NS);
        $finish;
    end

    always @(posedge w_tick_us) begin
        tick_count = tick_count + 1;

        if (tick_count > 1) begin
            $display("[%0t] w_tick_us pulse %0d, interval=%0t",
                     $time, tick_count, $time - last_tick_time);
        end else begin
            $display("[%0t] w_tick_us pulse %0d", $time, tick_count);
        end

        last_tick_time = $time;

        if (tick_count == 3) begin
            $display("PASS: w_tick_us pulses every 1 us");
            $finish;
        end
    end

endmodule
