`timescale 1ns / 1ps

module tb_watch_fsm ();

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

    wire o_set_mode;
    wire [1:0] o_set_index;
    wire o_index_shift;
    wire o_increment;
    wire o_increment_tens;
    wire o_decrement;
    wire o_decrement_tens;

    localparam UNIT_HOUR = 2'd0;
    localparam UNIT_MIN  = 2'd1;
    localparam UNIT_SEC  = 2'd2;
    localparam UNIT_MSEC = 2'd3;

    watch_fsm U0 (
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
        .o_set_mode(o_set_mode),
        .o_set_index(o_set_index),
        .o_index_shift(o_index_shift),
        .o_increment(o_increment),
        .o_increment_tens(o_increment_tens),
        .o_decrement(o_decrement),
        .o_decrement_tens(o_decrement_tens)
    );

    // 단순 10ns period clock 사용
    always #5 clk = ~clk;

    // 버튼 입력을 1클럭 동안만 넣어 FSM의 1회 동작을 확인
    task pulse_btnL;
    begin
        i_btnL = 1'b1;
        @(posedge clk);
        i_btnL = 1'b0;
    end
    endtask

    task pulse_btnU;
    begin
        i_btnU = 1'b1;
        @(posedge clk);
        i_btnU = 1'b0;
    end
    endtask

    task pulse_btnD;
    begin
        i_btnD = 1'b1;
        @(posedge clk);
        i_btnD = 1'b0;
    end
    endtask

    task pulse_btnU_hold;
    begin
        i_btnU_hold = 1'b1;
        @(posedge clk);
        i_btnU_hold = 1'b0;
    end
    endtask

    task pulse_btnD_hold;
    begin
        i_btnD_hold = 1'b1;
        @(posedge clk);
        i_btnD_hold = 1'b0;
    end
    endtask

    task pulse_btnR_hold;
    begin
        i_btnR_hold = 1'b1;
        @(posedge clk);
        i_btnR_hold = 1'b0;
    end
    endtask

    // set mode와 제어 펄스가 기대값과 같은지 비교
    task expect_outputs;
        input exp_set_mode;
        input [1:0] exp_set_index;
        input exp_index_shift;
        input exp_increment;
        input exp_increment_tens;
        input exp_decrement;
        input exp_decrement_tens;
    begin
        @(negedge clk);
        if ({o_set_mode, o_set_index, o_index_shift, o_increment, o_increment_tens, o_decrement, o_decrement_tens} !==
            {exp_set_mode, exp_set_index, exp_index_shift, exp_increment, exp_increment_tens, exp_decrement, exp_decrement_tens}) begin
            $display("FAIL tb_watch_fsm: output mismatch");
            $fatal;
        end
    end
    endtask

    initial begin
        // 초기값: reset asserted, 모든 버튼 입력 0
        clk = 1'b0;
        rst = 1'b1;
        i_display_mode = 1'b1;
        i_btnL = 1'b0;
        i_btnU = 1'b0;
        i_btnD = 1'b0;
        i_btnU_hold = 1'b0;
        i_btnD_hold = 1'b0;
        i_btnR_hold = 1'b0;
        i_sw0 = 1'b0;

        repeat (3) @(negedge clk);
        rst = 1'b0;

        // 1) reset 직후에는 VIEW 상태여야 함
        expect_outputs(1'b0, UNIT_MIN, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        // 2) HH:MM 표시 상태에서 BtnR hold로 SET 상태 진입 시 min부터 편집해야 함
        pulse_btnR_hold;
        expect_outputs(1'b1, UNIT_MIN, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        // 3) BtnL은 HH:MM 안에서 MIN <-> HOUR만 토글해야 함
        pulse_btnL;
        expect_outputs(1'b1, UNIT_HOUR, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);
        expect_outputs(1'b1, UNIT_HOUR, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        // 4) BtnU short는 현재 선택 단위(hour)에 increment 펄스 1번 출력
        pulse_btnU;
        expect_outputs(1'b1, UNIT_HOUR, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0);
        expect_outputs(1'b1, UNIT_HOUR, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        // 5) BtnU hold는 increment_tens 펄스 1번 출력
        pulse_btnU_hold;
        expect_outputs(1'b1, UNIT_HOUR, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
        expect_outputs(1'b1, UNIT_HOUR, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        // 6) BtnD short는 decrement 펄스 1번 출력
        pulse_btnD;
        expect_outputs(1'b1, UNIT_HOUR, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0);
        expect_outputs(1'b1, UNIT_HOUR, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        // 7) BtnD hold는 decrement_tens 펄스 1번 출력
        pulse_btnD_hold;
        expect_outputs(1'b1, UNIT_HOUR, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1);
        expect_outputs(1'b1, UNIT_HOUR, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        // 8) SET 상태에서 BtnR hold가 들어오면 VIEW로 복귀
        pulse_btnR_hold;
        expect_outputs(1'b0, UNIT_MIN, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        // 9) SS:MS 표시 상태에서 SET 진입 시 msec부터 편집해야 함
        i_display_mode = 1'b0;
        @(negedge clk);
        pulse_btnR_hold;
        expect_outputs(1'b1, UNIT_MSEC, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        // 10) set 중 display mode가 HH:MM으로 바뀌면 right stays right라서 msec -> min으로 remap되어야 함
        i_display_mode = 1'b1;
        @(posedge clk);
        expect_outputs(1'b1, UNIT_MIN, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        // 11) 다시 SS:MS로 바꾸면 min -> msec으로 remap되어야 함
        i_display_mode = 1'b0;
        @(posedge clk);
        expect_outputs(1'b1, UNIT_MSEC, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        // 12) sw0가 1이면 강제로 VIEW 유지
        pulse_btnR_hold;
        expect_outputs(1'b0, UNIT_MSEC, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
        pulse_btnR_hold;
        expect_outputs(1'b1, UNIT_MSEC, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
        i_sw0 = 1'b1;
        expect_outputs(1'b0, UNIT_MSEC, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
        i_sw0 = 1'b0;

        $display("PASS tb_watch_fsm");
        $finish;
    end

endmodule
