`timescale 1ns / 1ps

module tb_sr04 ();

  
    localparam integer CLK_PERIOD_NS = 10;
    localparam integer US_NS = 1000;
    localparam integer SIM_TIMEOUT_NS = 20_000_000;
    localparam integer DIST_TOLERANCE_MM = 2; // 기대값, 실제값 차이가 2mm 이내면 통과

    reg clk;
    reg rst;
    reg i_refresh_req;
    reg echo;
    wire trig;
    wire [11:0] o_distance_mm;
    wire [3:0] o_fnd_com;
    wire [7:0] o_fnd_data;

    sr04_unit dut (
        .clk(clk),
        .rst(rst),
        .i_refresh_req(i_refresh_req),
        .echo(echo),
        .trig(trig),
        .o_distance_mm(o_distance_mm),
        .o_fnd_com(o_fnd_com),
        .o_fnd_data(o_fnd_data)
    );

    always #(CLK_PERIOD_NS / 2) clk = ~clk;

    // DUT에게 "초음파 한 번 쏴라"라고 요청하는 1-clock pulse.
    
    task automatic request_measure;
        begin
            @(negedge clk);
            i_refresh_req = 1'b1;
            @(negedge clk);
            i_refresh_req = 1'b0;
        end
    endtask

   
    // 실제 센서 동작:
    // 1. FPGA가 trig를 약 10us 동안 high로 만든다.
    // 2. 센서는 초음파가 되돌아온 뒤 echo를 high로 만든다.
    // 3. echo high 폭은 거리 왕복 시간에 비례한다.
    // 메인 코드에서는 아래 식으로 거리(mm)를 계산한다.
    //   distance_mm = echo_high_us * 10 / 58
    //
    // 따라서 TB에서는 원하는 거리(mm)를 넣고, 반대로 echo high 시간을 만든다.
    //   echo_high_us = distance_mm * 58 / 10
    
    task automatic drive_sr04_echo_mm;
        input integer distance_mm;
        input integer return_delay_us;
        integer echo_high_us;
        begin
            echo_high_us = (distance_mm * 58 + 9) / 10;

            // DUT가 trig pulse를 내보내는 것을 기다린다.
            // trig가 내려간 뒤에 echo를 돌려준다.
            wait (trig === 1'b1);
            wait (trig === 1'b0);

            // 초음파가 물체에 닿고 돌아오기 전까지의 짧은 대기 시간.
            // 이 값은 측정 거리 계산에는 들어가지 않는다.
            // DUT는 echo가 high인 시간만 세서 거리를 계산한다.
            #(return_delay_us * US_NS);
            echo = 1'b1;
            #(echo_high_us * US_NS);
            echo = 1'b0;
        end
    endtask

    // DUT가 계산한 거리값이 기대한 mm 값과 맞는지 확인한다.
    task automatic expect_distance_mm;
        input integer expected_mm;
        input integer previous_mm;
        integer diff_mm;
        begin
            wait (o_distance_mm !== previous_mm[11:0]);
            diff_mm = (o_distance_mm > expected_mm) ?
                      (o_distance_mm - expected_mm) :
                      (expected_mm - o_distance_mm);

            if (diff_mm > DIST_TOLERANCE_MM) begin
                $fatal(1,
                       "distance mismatch expected=%0dmm actual=%0dmm diff=%0dmm",
                       expected_mm, o_distance_mm, diff_mm);
            end

            $display("[%0t] distance expected=%0dmm actual=%0dmm",
                     $time, expected_mm, o_distance_mm);
        end
    endtask

    // 거리 테스트 함수 선언

    task automatic run_distance_case;
        input integer distance_mm;
        integer previous_mm;
        begin
            previous_mm = o_distance_mm;
            $display("SR04 case: %0dmm", distance_mm);
            fork
                begin
                    request_measure();
                end
                begin
                    drive_sr04_echo_mm(distance_mm, 100);
                end
            join

            expect_distance_mm(distance_mm, previous_mm);
            repeat (20) @(posedge clk);
        end
    endtask

    initial begin
        // 시뮬레이션이 어딘가에서 멈추면 무한 대기하지 않도록 전체 timeout을 둔다.
        #SIM_TIMEOUT_NS;
        $fatal(1, "tb_sr04 timeout");
    end

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        i_refresh_req = 1'b0;
        echo = 1'b0;

        repeat (8) @(negedge clk);
        rst = 1'b0;
        repeat (8) @(negedge clk);

        if (trig !== 1'b0) $fatal(1, "trig default mismatch");
        if (o_distance_mm !== 12'd0) $fatal(1, "distance default mismatch");

        // 최소 쪽 테스트: 20mm = 2cm.
        run_distance_case(20);

        // 최대 거리 테스트: 4000mm = 400cm.
        // HC-SR04 일반 스펙의 최대 측정 범위를 반영한 케이스다.
        run_distance_case(4000);

        $display("tb_sr04: PASS");
        $finish;
    end

endmodule
