`timescale 1ns / 1ps
module tb_dht11_jm ();
    // 시뮬레이션 파라미터
    parameter [7:0] HUMI_INT = 8'd60;  // 습도 정수부
    parameter [7:0] TEMP_INT = 8'd25;  // 온도 정수부
    parameter [39:0] DATA_STREAM = {
        HUMI_INT, 8'h00, TEMP_INT, 8'h00, HUMI_INT + TEMP_INT
    };
    reg clk;
    reg rst;
    reg btn_R;
    reg sw15;
    reg dht_sensor_data;
    reg io_oe; // io_oe = 1 → testbench가 센서 역할을 하면서 dht11 선을 직접 제어
               // io_oe = 0 → testbench는 dht11 선을 놓음, high-Z 상태
    //wire [5:0] led;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire dht11;
    // pullup (dht11);

    //  tb io mode 변환.
    assign dht11 = (io_oe) ? dht_sensor_data : 1'bz; // 센서 입장에서 io를 제어해주는 것

    dht11 dut (
    .clk(clk),
    .rst(rst),
    .btn_R(btn_R),
    .sw15(sw15),
    .led(led),
    .fnd_com(fnd_com),
    .fnd_data(fnd_data),
    .dht11(dht11)
);

    always #5 clk = ~clk;
    integer i = 0;

    initial begin
        clk = 0;
        rst = 1;
        io_oe = 0;
        // dht_sensor_data = 1'b1; // dht11의 IDLE 상태에선 HIGH 유지
        btn_R = 0;
        sw15 = 0; // 온도

        #100;
        rst = 0;
        #100;
        btn_R = 1;
        sw15 = 1; // 습도
        #1_000_000;
        btn_R = 0;
        #100;
        wait (!dht11);
        // 18msec 대기
        wait (dht11);
        #30000; // 겹치는 구간 z 잠깐 발생할 수도 있음
        // 입력 모드로 변환
        io_oe = 1; // FPGA 입력
        #5000;
        dht_sensor_data = 1'b0; // SYNCL
        #75000;
        dht_sensor_data = 1'b1; // SYNCH
        #80000;
        for (i = 39; i >= 0; i = i - 1) begin
            dht_sensor_data = 0; // DATA SYNC 0
            #50000;
            dht_sensor_data = 1'b1; // DATA SYNC
            #(DATA_STREAM[i] ? 70000 : 26000); // HIGH의 시간을 재서 DATA 0인지 1인지 판별

        end
        dht_sensor_data = 0; // DATA DECISION이 끝나고 STOP으로 감
        #50000;
        io_oe = 0; // FPGA 출력
        #50000;
        $stop;
    end




endmodule
