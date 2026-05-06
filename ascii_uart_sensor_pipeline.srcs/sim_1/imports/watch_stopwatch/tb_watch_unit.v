`timescale 1ns / 1ps

module tb_watch_unit ();

    localparam UNIT_HOUR = 2'd0;
    localparam UNIT_MIN  = 2'd1;

    reg clk;
    reg rst;
    reg i_display_mode;
    reg i_btnL;
    reg i_btnU;
    reg i_btnD;
    reg i_btnU_hold;
    reg i_btnD_hold;
    reg i_btnR_hold;
    reg i_sw0;
    reg [1:0] i_time_24;

    wire w_set_mode;
    wire [1:0] w_set_index;
    wire w_index_shift;
    wire w_increment;
    wire w_increment_tens;
    wire w_decrement;
    wire w_decrement_tens;

    wire [23:0] o_set_time;
    wire [23:0] o_watch_vault;
    wire o_sec_tick;
    wire o_min_tick;
    wire o_hour_tick;
    wire [6:0] msec;
    wire [5:0] sec;
    wire [5:0] min;
    wire [4:0] hour;

    watch_fsm U_FSM (
        .clk(clk),
        .rst(rst),
        .i_display_mode(i_display_mode),
        .i_btnL(i_btnL),
        .i_btnU(i_btnU),
        .i_btnD(i_btnD),
        .i_btnU_hold(i_btnU_hold),
        .i_btnD_hold(i_btnD_hold),
        .i_btnR_hold(i_btnR_hold),
        .i_sw0(i_sw0),
        .o_set_mode(w_set_mode),
        .o_set_index(w_set_index),
        .o_index_shift(w_index_shift),
        .o_increment(w_increment),
        .o_increment_tens(w_increment_tens),
        .o_decrement(w_decrement),
        .o_decrement_tens(w_decrement_tens)
    );

    watch_datapath #(
        .CLK_FREQ_HZ(1000),
        .TICK_HZ(100)
    ) U_DP (
        .clk(clk),
        .rst(rst),
        .i_set_mode(w_set_mode),
        .i_set_index(w_set_index),
        .i_index_shift(w_index_shift),
        .i_increment(w_increment),
        .i_increment_tens(w_increment_tens),
        .i_decrement(w_decrement),
        .i_decrement_tens(w_decrement_tens),
        .i_time_24(i_time_24),
        .o_set_time(o_set_time),
        .o_watch_vault(o_watch_vault),
        .o_sec_tick(o_sec_tick),
        .o_min_tick(o_min_tick),
        .o_hour_tick(o_hour_tick),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );

    always #5 clk = ~clk;

    task pulse_btnR_hold;
    begin
        i_btnR_hold = 1'b1;
        @(negedge clk);
        i_btnR_hold = 1'b0;
        @(negedge clk);
    end
    endtask

    task pulse_btnL;
    begin
        i_btnL = 1'b1;
        @(negedge clk);
        i_btnL = 1'b0;
        @(negedge clk);
    end
    endtask

    task pulse_btnU;
    begin
        i_btnU = 1'b1;
        @(negedge clk);
        i_btnU = 1'b0;
        @(negedge clk);
    end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        i_display_mode = 1'b1;  // HH:MM
        i_btnL = 1'b0;
        i_btnU = 1'b0;
        i_btnD = 1'b0;
        i_btnU_hold = 1'b0;
        i_btnD_hold = 1'b0;
        i_btnR_hold = 1'b0;
        i_sw0 = 1'b0;
        i_time_24 = 2'b00;      // 24h

        repeat (3) @(negedge clk);
        rst = 1'b0;

        // 1) set 진입: HH:MM 기준 오른쪽(MIN)부터 시작
        pulse_btnR_hold;
        if (!w_set_mode || w_set_index !== UNIT_MIN) begin
            $display("FAIL tb_watch_unit: set entry mismatch");
            $fatal;
        end

        // 2) 왼쪽으로 한 번 이동 후 hour 편집
        pulse_btnL;
        if (w_set_index !== UNIT_HOUR) begin
            $display("FAIL tb_watch_unit: hour index mismatch");
            $fatal;
        end

        pulse_btnU;
        if (o_set_time[23:19] !== 5'd14) begin
            $display("FAIL tb_watch_unit: hour edit mismatch");
            $fatal;
        end

        // 3) 12h 전환 시 set_time 표시만 즉시 2로 바뀌어야 함
        i_time_24 = 2'b01;
        @(negedge clk);
        if (o_set_time[23:19] !== 5'd2) begin
            $display("FAIL tb_watch_unit: 12h display mismatch");
            $fatal;
        end

        // 4) set 종료 시 실제 내부 시계값은 14시로 반영되어야 함
        pulse_btnR_hold;
        if (w_set_mode) begin
            $display("FAIL tb_watch_unit: failed to exit set mode");
            $fatal;
        end
        if (hour !== 5'd14 || min !== 6'd59) begin
            $display("FAIL tb_watch_unit: apply set mismatch");
            $fatal;
        end

        $display("PASS tb_watch_unit");
        $finish;
    end

endmodule
