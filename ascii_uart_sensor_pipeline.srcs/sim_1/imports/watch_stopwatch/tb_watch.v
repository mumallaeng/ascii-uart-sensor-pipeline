`timescale 1ns / 1ps

module tb_watch ();

    // watch_datapath 입력 자극용 신호
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
    wire [23:0] o_set_time;
    wire [23:0] o_watch_vault;
    wire o_sec_tick;
    wire o_min_tick;
    wire o_hour_tick;
    wire [6:0] msec;
    wire [5:0] sec;
    wire [5:0] min;
    wire [4:0] hour;

    localparam UNIT_HOUR = 2'd0;
    localparam UNIT_MIN  = 2'd1;
    localparam UNIT_SEC  = 2'd2;
    localparam UNIT_MSEC = 2'd3;
    localparam INIT_HOUR = 5'd13;
    localparam INIT_MIN  = 6'd59;

    // DUT: watch 실시간 카운트와 출력 버스를 만드는 모듈
    watch_datapath #(
        .MSEC_TIMES(100),
        .SEC_TIMES(60),
        .MIN_TIMES(60),
        .HOUR_TIMES(24)
    ) U0 (
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

    // 내부 tick generator를 빠르게 돌려 시뮬레이션 시간 줄이기
    defparam U0.U_TICK_GEN_100HZ.CLK_FREQ_HZ = 1000;
    defparam U0.U_TICK_GEN_100HZ.TICK_HZ = 100;

    // 단순 10ns period clock 사용
    always #5 clk = ~clk;

    // 내부 100Hz tick이 몇 번 발생할 때까지 기다리는 task
    task wait_msec_steps;
        input integer steps;
        integer idx;
    begin
        for (idx = 0; idx < steps; idx = idx + 1) begin
            @(posedge U0.w_tick_100hz);
        end
        @(posedge clk);
    end
    endtask

    // increment를 1클럭 펄스로 넣어 편집 버스의 현재 단위를 1 증가
    task pulse_increment;
    begin
        i_increment = 1'b1;
        @(negedge clk);
        i_increment = 1'b0;
    end
    endtask

    // increment_tens를 1클럭 펄스로 넣어 편집 버스의 현재 단위를 10 증가
    task pulse_increment_tens;
    begin
        i_increment_tens = 1'b1;
        @(negedge clk);
        i_increment_tens = 1'b0;
    end
    endtask

    // decrement를 1클럭 펄스로 넣어 편집 버스의 현재 단위를 1 감소
    task pulse_decrement;
    begin
        i_decrement = 1'b1;
        @(negedge clk);
        i_decrement = 1'b0;
    end
    endtask

    // index_shift를 1클럭 펄스로 넣어 편집 단위를 다음 단위로 이동
    task pulse_shift;
    begin
        i_index_shift = 1'b1;
        @(negedge clk);
        i_index_shift = 1'b0;
    end
    endtask

    // 기대하는 hour/min/sec/msec 값과 실제 시간을 비교
    task expect_time;
        input [4:0] exp_hour;
        input [5:0] exp_min;
        input [5:0] exp_sec;
        input [6:0] exp_msec;
    begin
        @(negedge clk);
        if ({hour, min, sec, msec} !== {exp_hour, exp_min, exp_sec, exp_msec}) begin
            $display("FAIL tb_watch: expected %0d:%0d:%0d:%0d, got %0d:%0d:%0d:%0d",
                     exp_hour, exp_min, exp_sec, exp_msec,
                     hour, min, sec, msec);
            $fatal;
        end
    end
    endtask

    initial begin
        // 초기값: reset asserted, set 모드 off, 제어 입력 모두 0
        clk = 1'b0;
        rst = 1'b1;
        i_set_mode = 1'b0;
        i_set_index = UNIT_SEC;
        i_index_shift = 1'b0;
        i_increment = 1'b0;
        i_increment_tens = 1'b0;
        i_decrement = 1'b0;
        i_decrement_tens = 1'b0;
        i_time_24 = 2'b00;

        // reset 해제 후부터 본격 테스트 시작
        repeat (3) @(negedge clk);
        rst = 1'b0;

        // 1) reset 직후 Watch는 13:59:00.00으로 시작해야 함
        expect_time(INIT_HOUR, INIT_MIN, 6'd0, 7'd0);

        // 2) 1개의 100Hz tick마다 msec가 1씩 증가해야 함
        wait_msec_steps(1);
        expect_time(INIT_HOUR, INIT_MIN, 6'd0, 7'd1);

        wait_msec_steps(9);
        expect_time(INIT_HOUR, INIT_MIN, 6'd0, 7'd10);

        // 3) 100 tick이 지나면 sec가 1 증가하고 msec는 0으로 돌아가야 함
        wait_msec_steps(90);
        expect_time(INIT_HOUR, INIT_MIN, 6'd1, 7'd0);

        // 4) set_mode가 1이어도 live time은 계속 흘러야 함
        i_set_mode = 1'b1;
        wait_msec_steps(20);
        expect_time(INIT_HOUR, INIT_MIN, 6'd1, 7'd20);

        // 5) set_mode 진입 순간의 편집 버스는 당시 live time을 기준으로 잡혀야 함
        @(negedge clk);
        if (o_set_time !== {INIT_HOUR, INIT_MIN, 6'd1, 7'd0}) begin
            $display("FAIL tb_watch: o_set_time should capture live time at set entry");
            $fatal;
        end

        // 6) set 모드 중 24h -> 12h -> 24h 전환이 즉시 표시 버스에 반영되어야 함
        i_time_24 = 2'b01;
        @(negedge clk);
        if (o_set_time !== {5'd1, 6'd59, 6'd1, 7'd0}) begin
            $display("FAIL tb_watch: 12-hour display conversion mismatch");
            $fatal;
        end

        i_time_24 = 2'b00;
        @(negedge clk);
        if (o_set_time !== {INIT_HOUR, INIT_MIN, 6'd1, 7'd0}) begin
            $display("FAIL tb_watch: 24-hour display restore mismatch");
            $fatal;
        end

        // 7) set 모드에서는 편집 버스가 live time과 분리되어 수정되어야 함
        pulse_increment_tens;
        @(negedge clk);
        if (o_set_time !== {INIT_HOUR, INIT_MIN, 6'd11, 7'd0}) begin
            $display("FAIL tb_watch: sec tens increment mismatch");
            $fatal;
        end

        i_set_index = UNIT_MSEC;
        pulse_shift;  // SEC -> MSEC
        @(negedge clk);  // datapath 단독 tb에서는 i_set_index를 직접 바꿔준 뒤 1클럭 동기화 기다림
        pulse_decrement;
        @(negedge clk);
        if (o_set_time !== {INIT_HOUR, INIT_MIN, 6'd11, 7'd99}) begin
            $display("FAIL tb_watch: msec decrement wrap mismatch");
            $fatal;
        end

        // 8) set_mode를 다시 내리면 편집값이 live time으로 1번 반영되어야 함
        i_set_mode = 1'b0;
        expect_time(INIT_HOUR, INIT_MIN, 6'd11, 7'd99);

        // 9) 반영 이후에는 기본 카운트가 다시 진행되어야 함
        wait_msec_steps(5);
        expect_time(INIT_HOUR, INIT_MIN, 6'd12, 7'd4);

        // 10) 출력 버스 묶임도 현재 시간과 동일해야 함
        @(negedge clk);
        if (o_watch_vault !== {hour, min, sec, msec}) begin
            $display("FAIL tb_watch: o_watch_vault mismatch");
            $fatal;
        end

        // 11) set 모드가 꺼진 상태에서는 set 버스가 다시 live time을 따라가야 함
        if (o_set_time !== o_watch_vault) begin
            $display("FAIL tb_watch: o_set_time should follow live time after leaving set mode");
            $fatal;
        end

        // 모든 케이스를 통과하면 PASS 출력 후 종료
        $display("PASS tb_watch");
        $finish;
    end

endmodule
