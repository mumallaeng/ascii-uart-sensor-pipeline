`timescale 1ns / 1ps

module tb_watch_stopwatch ();

    localparam UNIT_HOUR = 2'd0;
    localparam UNIT_MIN  = 2'd1;
    localparam UNIT_SEC  = 2'd2;
    localparam UNIT_MSEC = 2'd3;
    localparam INIT_HOUR = 5'd13;
    localparam INIT_MIN  = 6'd59;
    localparam MSEC_TIMES = 100;

    // top 입력 자극용 신호
    reg clk;
    reg rst;
    reg btnR;
    reg btnL;
    reg btnU;
    reg btnD;
    reg sw0;
    reg sw15;
    reg [6:0] msec_before_hold;

    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire [1:0] led;

    // DUT: Stopwatch + Watch + Display 경로를 최종 연결한 상위 모듈
    watch_stopwatch #(
        .CLK_FREQ_HZ(1000),
        .BD_HZ(100),
        .HOLD_TIME_BTN_R(200),
        .HOLD_TIME_BTN_UD(150),
        .HOLD_TIME_BTN_L(150),
        .REPEAT_TIME_BTN_UD(80),
        .BASIC_TIME(100),
        .SCAN_HZ(100)
    ) UUT (
        .clk(clk),
        .rst(rst),
        .btnR(btnR),
        .btnL(btnL),
        .btnU(btnU),
        .btnD(btnD),
        .sw0(sw0),
        .sw15(sw15),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .led(led)
    );

    always #5 clk = ~clk;

    // 단순 clock 지연용 task
    task wait_cycles;
        input integer cycles;
        integer idx;
    begin
        for (idx = 0; idx < cycles; idx = idx + 1) begin
            @(negedge clk);
        end
    end
    endtask

    // Watch 내부 100Hz tick 기준으로 기다리기
    task wait_watch_ticks;
        input integer steps;
        integer idx;
    begin
        for (idx = 0; idx < steps; idx = idx + 1) begin
            @(posedge UUT.U_WATCH.U_WATCH_DATAPATH.w_tick_100hz);
        end
        @(negedge clk);
    end
    endtask

    // Stopwatch 내부 100Hz tick 기준으로 기다리기
    task wait_stopwatch_ticks;
        input integer steps;
        integer idx;
    begin
        for (idx = 0; idx < steps; idx = idx + 1) begin
            @(posedge UUT.U_STOPWATCH.U_STOPWATCH_DATAPATH.w_tick_100hz);
        end
        @(negedge clk);
    end
    endtask

    // btnR short 입력: debounce를 통과할 만큼 눌렀다가 release 후 short pulse 발생 대기
    task press_btnR_short;
    begin
        btnR = 1'b1;
        wait_cycles(120);
        btnR = 1'b0;
        wait_cycles(120);
    end
    endtask

    // btnR hold 입력: 2초 hold pulse가 발생할 만큼 길게 누름
    task press_btnR_hold;
    begin
        btnR = 1'b1;
        wait_cycles(320);
        btnR = 1'b0;
        wait_cycles(120);
    end
    endtask

    // btnU short 입력
    task press_btnU_short;
    begin
        btnU = 1'b1;
        wait_cycles(120);
        btnU = 1'b0;
        wait_cycles(120);
    end
    endtask

    // btnU hold 입력: hold 이후 repeat pulse가 계속 나오는지 확인할 때 사용
    task press_btnU_hold;
    begin
        btnU = 1'b1;
        wait_cycles(380);
        btnU = 1'b0;
        wait_cycles(120);
    end
    endtask

    // btnD short 입력
    task press_btnD_short;
    begin
        btnD = 1'b1;
        wait_cycles(120);
        btnD = 1'b0;
        wait_cycles(120);
    end
    endtask

    // btnL short 입력
    task press_btnL_short;
    begin
        btnL = 1'b1;
        wait_cycles(120);
        btnL = 1'b0;
        wait_cycles(120);
    end
    endtask

    // 현재 display 경로가 기대값과 같은지 확인
    task expect_display;
        input [4:0] exp_hour;
        input [5:0] exp_min;
        input [5:0] exp_sec;
        input [6:0] exp_msec;
    begin
        @(negedge clk);
        if ({UUT.U_DISPLAY.w_display_hour, UUT.U_DISPLAY.w_display_min, UUT.U_DISPLAY.w_display_sec, UUT.U_DISPLAY.w_display_msec}
            !== {exp_hour, exp_min, exp_sec, exp_msec}) begin
            $display("FAIL tb_watch_stopwatch: display expected %0d:%0d:%0d:%0d, got %0d:%0d:%0d:%0d",
                     exp_hour, exp_min, exp_sec, exp_msec,
                     UUT.U_DISPLAY.w_display_hour, UUT.U_DISPLAY.w_display_min, UUT.U_DISPLAY.w_display_sec, UUT.U_DISPLAY.w_display_msec);
            $fatal;
        end
    end
    endtask

    function [6:0] wrap_add_msec;
        input [6:0] value;
        input integer step;
        integer sum;
    begin
        sum = value + step;
        if (sum >= MSEC_TIMES) wrap_add_msec = sum - MSEC_TIMES;
        else wrap_add_msec = sum[6:0];
    end
    endfunction

    function integer wrap_delta_msec;
        input [6:0] before_value;
        input [6:0] after_value;
    begin
        if (after_value >= before_value) wrap_delta_msec = after_value - before_value;
        else wrap_delta_msec = after_value + MSEC_TIMES - before_value;
    end
    endfunction

    initial begin
        // 초기값: reset asserted, Watch 선택, 24시간제
        clk  = 1'b0;
        rst  = 1'b1;
        btnR = 1'b0;
        btnL = 1'b0;
        btnU = 1'b0;
        btnD = 1'b0;
        sw0  = 1'b0;
        sw15 = 1'b0;

        wait_cycles(5);
        rst = 1'b0;

        // 1) reset 직후 기본 화면은 Watch, HH:MM, 24시간제 기준 13:59이어야 함
        expect_display(INIT_HOUR, INIT_MIN, 6'd0, 7'd0);
        if (led !== 2'b00) begin
            $display("FAIL tb_watch_stopwatch: LED reset state mismatch");
            $fatal;
        end

        // 2) Watch는 기본적으로 계속 흐르며 display가 이를 따라가야 함
        wait_watch_ticks(15);
        expect_display(UUT.U_WATCH.U_WATCH_DATAPATH.hour,
                       UUT.U_WATCH.U_WATCH_DATAPATH.min,
                       UUT.U_WATCH.U_WATCH_DATAPATH.sec,
                       UUT.U_WATCH.U_WATCH_DATAPATH.msec);

        // 3) Watch에서도 set 모드가 아닐 때는 btnR short로 display mode를 토글할 수 있어야 함
        if (UUT.w_display_mode !== 1'b1) begin
            $display("FAIL tb_watch_stopwatch: initial watch display mode mismatch");
            $fatal;
        end
        press_btnR_short;
        @(negedge clk);
        if (UUT.w_display_mode !== 1'b0) begin
            $display("FAIL tb_watch_stopwatch: watch display mode did not toggle");
            $fatal;
        end
        // 4) SS:MS 상태에서 btnR hold로 set 모드에 진입하면 msec부터 편집해야 함
        press_btnR_hold;
        if (!UUT.w_watch_set_mode) begin
            $display("FAIL tb_watch_stopwatch: failed to enter watch set mode");
            $fatal;
        end
        if (UUT.w_watch_set_index !== UNIT_MSEC) begin
            $display("FAIL tb_watch_stopwatch: ss:ms set entry index mismatch");
            $fatal;
        end

        // 5) ss:ms set 모드에서 btnU hold는 현재 msec 기준으로 tens 편집이 반복되어야 함
        msec_before_hold = UUT.w_watch_set_time[6:0];
        press_btnU_hold;
        if (wrap_delta_msec(msec_before_hold, UUT.w_watch_set_time[6:0]) < 20) begin
            $display("FAIL tb_watch_stopwatch: msec hold-repeat mismatch in ss:ms set mode");
            $fatal;
        end

        // 6) set 중에도 btnR short로 hh:mm으로 전환 가능해야 하고, set 모드는 유지되어야 함
        //    오른쪽 단위를 보고 있었다면 hh:mm에서도 오른쪽(min)으로 유지되어야 함
        press_btnR_short;
        @(negedge clk);
        if (!UUT.w_watch_set_mode) begin
            $display("FAIL tb_watch_stopwatch: set mode was lost after display toggle");
            $fatal;
        end
        if (UUT.w_display_mode !== 1'b1) begin
            $display("FAIL tb_watch_stopwatch: set-mode display mode restore mismatch");
            $fatal;
        end
        if (UUT.w_watch_set_index !== UNIT_MIN) begin
            $display("FAIL tb_watch_stopwatch: set index remap mismatch after display toggle");
            $fatal;
        end

        // 7) hh:mm set 상태에서 오른쪽(min)에서 시작하므로 한번 shift 후 hour를 편집
        press_btnL_short;
        if (UUT.w_watch_set_index !== UNIT_HOUR) begin
            $display("FAIL tb_watch_stopwatch: hour shift mismatch in hh:mm set mode");
            $fatal;
        end
        press_btnU_short;  // 13 -> 14 hour

        if (UUT.w_watch_set_time[23:19] !== 5'd14) begin
            $display("FAIL tb_watch_stopwatch: set hour edit mismatch");
            $fatal;
        end

        // 8) 12시간제를 켜면 편집 버스와 display hour가 즉시 2로 보여야 함
        sw15 = 1'b1;
        @(negedge clk);
        if (UUT.w_watch_set_time[23:19] !== 5'd2) begin
            $display("FAIL tb_watch_stopwatch: 12-hour set display mismatch");
            $fatal;
        end
        expect_display(5'd2, UUT.w_watch_set_time[18:13], UUT.w_watch_set_time[12:7], UUT.w_watch_set_time[6:0]);
        if (led[1] !== 1'b1) begin
            $display("FAIL tb_watch_stopwatch: 12-hour LED mismatch");
            $fatal;
        end

        // 9) btnR hold로 set 종료하면 편집값이 live time에 1회 반영되어야 함
        press_btnR_hold;
        if (UUT.w_watch_set_mode) begin
            $display("FAIL tb_watch_stopwatch: failed to leave watch set mode");
            $fatal;
        end

        @(negedge clk);
        if (UUT.U_WATCH.U_WATCH_DATAPATH.hour !== UUT.U_WATCH.U_WATCH_DATAPATH.w_set_time_load[23:19]) begin
            $display("FAIL tb_watch_stopwatch: live hour was not updated after set exit");
            $fatal;
        end
        if (UUT.U_WATCH.U_WATCH_DATAPATH.min !== UUT.U_WATCH.U_WATCH_DATAPATH.w_set_time_load[18:13]) begin
            $display("FAIL tb_watch_stopwatch: live min was not updated after set exit");
            $fatal;
        end
        if (UUT.U_WATCH.U_WATCH_DATAPATH.sec !== UUT.U_WATCH.U_WATCH_DATAPATH.w_set_time_load[12:7]) begin
            $display("FAIL tb_watch_stopwatch: live sec was not updated after set exit");
            $fatal;
        end
        if (UUT.U_WATCH.U_WATCH_DATAPATH.msec !== UUT.U_WATCH.U_WATCH_DATAPATH.w_set_time_load[6:0]) begin
            $display("FAIL tb_watch_stopwatch: live msec was not updated after set exit");
            $fatal;
        end
        expect_display(5'd2, UUT.w_watch_set_time[18:13], UUT.w_watch_set_time[12:7], UUT.w_watch_set_time[6:0]);

        // 10) Stopwatch 모드로 전환하면 display가 stopwatch 값을 따라가야 함
        sw0 = 1'b1;
        @(negedge clk);
        if (led[0] !== 1'b1) begin
            $display("FAIL tb_watch_stopwatch: stopwatch LED mismatch");
            $fatal;
        end
        expect_display(5'd0, 6'd0, 6'd0, 7'd0);

        // 9) btnD short로 stopwatch run 시작 후 display가 stopwatch msec을 따라감
        press_btnD_short;
        wait_stopwatch_ticks(12);
        @(negedge clk);
        if (UUT.w_stopwatch_msec < 7'd10) begin
            $display("FAIL tb_watch_stopwatch: stopwatch did not start");
            $fatal;
        end
        expect_display(5'd0, 6'd0, 6'd0, UUT.w_stopwatch_msec);

        // 10) Stopwatch 모드에서 btnR short는 display mode를 토글해야 함
        if (UUT.w_display_mode !== 1'b1) begin
            $display("FAIL tb_watch_stopwatch: initial display mode mismatch");
            $fatal;
        end
        press_btnR_short;
        @(negedge clk);
        if (UUT.w_display_mode !== 1'b0) begin
            $display("FAIL tb_watch_stopwatch: display mode did not toggle");
            $fatal;
        end

        // 11) btnL short는 stopwatch clear로 연결되어 값을 0으로 초기화한 뒤 RUN 상태면 다시 카운트함
        press_btnL_short;
        @(negedge clk);
        if (UUT.w_stopwatch_hour !== 5'd0 || UUT.w_stopwatch_min !== 6'd0 || UUT.w_stopwatch_sec !== 6'd0
            || UUT.w_stopwatch_msec > 7'd20) begin
            $display("FAIL tb_watch_stopwatch: stopwatch clear mismatch");
            $fatal;
        end
        expect_display(5'd0, 6'd0, 6'd0, UUT.w_stopwatch_msec);

        // 12) 다시 Watch 모드로 돌아오면 기존 시계값과 12시간 표시가 유지되어야 함
        sw0 = 1'b0;
        @(negedge clk);
        expect_display(UUT.w_watch_set_time[23:19],
                       UUT.w_watch_set_time[18:13],
                       UUT.w_watch_set_time[12:7],
                       UUT.w_watch_set_time[6:0]);

        // FND 출력도 X 없이 생성되어야 함
        if (^fnd_com === 1'bx || ^fnd_data === 1'bx) begin
            $display("FAIL tb_watch_stopwatch: FND output contains X");
            $fatal;
        end

        $display("PASS tb_watch_stopwatch");
        $finish;
    end

endmodule
