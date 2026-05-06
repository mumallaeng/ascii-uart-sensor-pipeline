`timescale 1ns / 1ps

module tb_watch_set ();

    reg clk;
    reg rst;
    reg i_set_mode;
    reg [1:0] i_set_index;
    reg i_index_shift;
    reg i_increment;
    reg i_increment_tens;
    reg i_decrement;
    reg i_decrement_tens;
    reg [1:0] i_time_24;
    reg [23:0] i_live_time;
    wire [23:0] o_set_time;

    localparam UNIT_HOUR = 2'd0;
    localparam UNIT_MIN  = 2'd1;
    localparam UNIT_SEC  = 2'd2;
    localparam UNIT_MSEC = 2'd3;

    time_set_module U0 (
        .clk(clk),
        .rst(rst),
        .i_set_mode(i_set_mode),
        .i_set_index(i_set_index),
        .i_index_shift(i_index_shift),
        .i_increment(i_increment),
        .i_increment_tens(i_increment_tens),
        .i_decrement(i_decrement),
        .i_decrement_tens(i_decrement_tens),
        .i_time_24(i_time_24),
        .i_live_time(i_live_time),
        .o_set_time(o_set_time)
    );

    // 100MHz 대신 단순 10ns period clock로 테스트 진행
    always #5 clk = ~clk;

    // increment를 1클럭 펄스로 넣어 현재 선택 단위를 1 증가
    task pulse_increment;
    begin
        i_increment = 1'b1;
        @(negedge clk);
        i_increment = 1'b0;
    end
    endtask

    // increment_tens를 1클럭 펄스로 넣어 현재 선택 단위를 10 증가
    task pulse_increment_tens;
    begin
        i_increment_tens = 1'b1;
        @(negedge clk);
        i_increment_tens = 1'b0;
    end
    endtask

    // decrement를 1클럭 펄스로 넣어 현재 선택 단위를 1 감소
    task pulse_decrement;
    begin
        i_decrement = 1'b1;
        @(negedge clk);
        i_decrement = 1'b0;
    end
    endtask

    // decrement_tens를 1클럭 펄스로 넣어 현재 선택 단위를 10 감소
    task pulse_decrement_tens;
    begin
        i_decrement_tens = 1'b1;
        @(negedge clk);
        i_decrement_tens = 1'b0;
    end
    endtask

    // index_shift를 1클럭 펄스로 넣어 편집 단위를 다음 단위로 넘김.
    task pulse_shift;
    begin
        i_index_shift = 1'b1;
        @(negedge clk);
        i_index_shift = 1'b0;
    end
    endtask

    // 기대하는 hour/min/sec/msec 값과 실제 o_set_time을 비교
    task expect_set_time;
        input [4:0] exp_hour;
        input [5:0] exp_min;
        input [5:0] exp_sec;
        input [6:0] exp_msec;
    begin
        @(negedge clk);
        if (o_set_time !== {exp_hour, exp_min, exp_sec, exp_msec}) begin
            $display("FAIL tb_watch_set: expected %0d:%0d:%0d:%0d, got %0d:%0d:%0d:%0d",
                     exp_hour, exp_min, exp_sec, exp_msec,
                     o_set_time[23:19], o_set_time[18:13], o_set_time[12:7], o_set_time[6:0]);
            $fatal;
        end
    end
    endtask

    initial begin
        // 초기값: reset asserted, set 모드 off, 입력 펄스 모두 0
        clk = 1'b0;
        rst = 1'b1;
        i_set_mode = 1'b0;
        i_set_index = UNIT_MSEC;
        i_index_shift = 1'b0;
        i_increment = 1'b0;
        i_increment_tens = 1'b0;
        i_decrement = 1'b0;
        i_decrement_tens = 1'b0;
        i_time_24 = 2'b00;
        i_live_time = 24'd0;

        // reset 해제 후부터 본격 테스트 시작
        repeat (3) @(negedge clk);
        rst = 1'b0;

        // 1) set 모드가 아닐 때는 실시간 시계값을 그대로 따라가야 함.
        i_live_time = {5'd9, 6'd12, 6'd34, 7'd56};
        expect_set_time(5'd9, 6'd12, 6'd34, 7'd56);

        i_live_time = {5'd10, 6'd22, 6'd44, 7'd77};
        expect_set_time(5'd10, 6'd22, 6'd44, 7'd77);

        // 2) set 모드 진입 시 현재 실시간값을 기준으로 편집 시작해야 함.
        i_set_index = UNIT_SEC;
        i_set_mode = 1'b1;
        expect_set_time(5'd10, 6'd22, 6'd44, 7'd77);

        // 3) set 모드에서는 live_time이 바뀌어도 편집 버스는 유지되어야 함.
        i_live_time = {5'd20, 6'd30, 6'd40, 7'd50};
        expect_set_time(5'd10, 6'd22, 6'd44, 7'd77);

        // 4) SEC 선택 상태에서 +1 / -1이 sec에만 반영되는지 확인함.
        pulse_increment;
        expect_set_time(5'd10, 6'd22, 6'd45, 7'd77);

        pulse_decrement;
        expect_set_time(5'd10, 6'd22, 6'd44, 7'd77);

        // 5) SEC 선택 상태에서 +10 / -10도 sec에만 반영되는지 확인함.
        pulse_increment_tens;
        expect_set_time(5'd10, 6'd22, 6'd54, 7'd77);

        pulse_decrement_tens;
        expect_set_time(5'd10, 6'd22, 6'd44, 7'd77);

        // 6) set 모드 중에도 24h -> 12h -> 24h 전환이 즉시 반영되어야 함.
        i_set_mode = 1'b0;
        i_live_time = {5'd23, 6'd22, 6'd44, 7'd77};
        expect_set_time(5'd23, 6'd22, 6'd44, 7'd77);

        i_set_index = UNIT_HOUR;
        i_set_mode = 1'b1;
        expect_set_time(5'd23, 6'd22, 6'd44, 7'd77);

        i_time_24 = 2'b01;
        expect_set_time(5'd11, 6'd22, 6'd44, 7'd77);

        pulse_increment;
        expect_set_time(5'd12, 6'd22, 6'd44, 7'd77);

        pulse_increment;
        expect_set_time(5'd1, 6'd22, 6'd44, 7'd77);

        i_time_24 = 2'b00;
        expect_set_time(5'd1, 6'd22, 6'd44, 7'd77);

        // 7) 현재 구현에서는 FSM이 i_set_index를 직접 넘겨주므로
        //    TB에서도 편집 단위를 직접 바꿔가며 검증함.
        i_set_mode = 1'b0;
        i_time_24 = 2'b00;
        i_live_time = {5'd10, 6'd22, 6'd44, 7'd77};
        expect_set_time(5'd10, 6'd22, 6'd44, 7'd77);

        i_set_index = UNIT_MIN;
        i_set_mode = 1'b1;
        expect_set_time(5'd10, 6'd22, 6'd44, 7'd77);

        pulse_increment;  // MIN +1
        expect_set_time(5'd10, 6'd23, 6'd44, 7'd77);

        // 8) MIN 단위에서 59 -> 0, 0 -> 59 wrap 동작 확인함.
        i_set_mode = 1'b0;
        i_live_time = {5'd10, 6'd59, 6'd44, 7'd77};
        expect_set_time(5'd10, 6'd59, 6'd44, 7'd77);

        i_set_index = UNIT_MIN;
        i_set_mode = 1'b1;
        expect_set_time(5'd10, 6'd59, 6'd44, 7'd77);

        pulse_increment;
        expect_set_time(5'd10, 6'd0, 6'd44, 7'd77);

        pulse_decrement;
        expect_set_time(5'd10, 6'd59, 6'd44, 7'd77);

        // 9) HOUR 단위에서 23 -> 0, 0 -> 23 wrap 동작 확인함.
        i_set_mode = 1'b0;
        i_live_time = {5'd23, 6'd10, 6'd20, 7'd30};
        expect_set_time(5'd23, 6'd10, 6'd20, 7'd30);

        i_set_index = UNIT_HOUR;
        i_set_mode = 1'b1;
        expect_set_time(5'd23, 6'd10, 6'd20, 7'd30);

        pulse_increment;
        expect_set_time(5'd0, 6'd10, 6'd20, 7'd30);

        pulse_decrement;
        expect_set_time(5'd23, 6'd10, 6'd20, 7'd30);

        // 10) MSEC 단위에서 99 -> 0, 0 -> 99 wrap 동작 확인함.
        i_set_mode = 1'b0;
        i_live_time = {5'd1, 6'd2, 6'd3, 7'd99};
        expect_set_time(5'd1, 6'd2, 6'd3, 7'd99);

        i_set_index = UNIT_MSEC;
        i_set_mode = 1'b1;
        expect_set_time(5'd1, 6'd2, 6'd3, 7'd99);

        pulse_increment;
        expect_set_time(5'd1, 6'd2, 6'd3, 7'd0);

        pulse_decrement;
        expect_set_time(5'd1, 6'd2, 6'd3, 7'd99);

        // 11) hour와 msec의 tens 편집도 wrap 포함해 동작하는지 확인함.
        i_set_mode = 1'b0;
        i_live_time = {5'd18, 6'd2, 6'd3, 7'd95};
        expect_set_time(5'd18, 6'd2, 6'd3, 7'd95);

        i_set_index = UNIT_HOUR;
        i_set_mode = 1'b1;
        expect_set_time(5'd18, 6'd2, 6'd3, 7'd95);

        pulse_increment_tens;
        expect_set_time(5'd4, 6'd2, 6'd3, 7'd95);

        i_set_index = UNIT_MSEC;
        @(negedge clk);
        pulse_increment_tens;
        expect_set_time(5'd4, 6'd2, 6'd3, 7'd5);

        pulse_decrement_tens;
        expect_set_time(5'd4, 6'd2, 6'd3, 7'd95);

        // 모든 케이스를 통과하면 PASS 출력 후 종료
        $display("PASS tb_watch_set");
        $finish;
    end

endmodule
