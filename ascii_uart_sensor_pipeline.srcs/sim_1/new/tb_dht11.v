`timescale 1ns / 1ps
module tb_dht11 ();
    // 시뮬레이션 파라미터
    parameter [7:0] HUMI_INT = 8'd60;  // 습도 정수부
    parameter [7:0] TEMP_INT = 8'd25;  // 온도 정수부

    parameter [39:0] DATA_STREAM = {
        HUMI_INT, 8'h00, TEMP_INT, 8'h00, HUMI_INT + TEMP_INT
    };

    reg clk;
    reg rst;

    // dht11_unit 입력
    reg i_dht11_refresh_req;
    reg i_dht11_show_humi;

    // testbench가 가짜 DHT11 센서 역할을 하기 위한 신호
    reg dht_sensor_data;
    reg io_oe; // io_oe = 1 → testbench가 센서 역할을 하면서 dht11 선을 직접 제어
               // io_oe = 0 → testbench는 dht11 선을 놓음, high-Z 상태

    // dht11_unit 출력
    wire [7:0] o_dht11_temp;
    wire [7:0] o_dht11_humi;
    wire o_led_dht11_valid;
    wire [3:0] o_dht11_fnd_com;
    wire [7:0] o_dht11_fnd_data;

    // DHT11 양방향 DATA line
    wire io_dht11;

    // // 아무도 DATA line을 잡지 않을 때 HIGH 유지
    // pullup PULLUP_DHT11 (io_dht11);

    // testbench가 센서 역할을 할 때만 io_dht11을 제어
    assign io_dht11 = (io_oe) ? dht_sensor_data : 1'bz;

    dht11_unit dut (
        .clk(clk),
        .rst(rst),
        .i_refresh_req(i_dht11_refresh_req),
        .i_show_humi(i_dht11_show_humi),
        .dht11_io(io_dht11),
        .o_temp(o_dht11_temp),
        .o_humi(o_dht11_humi),
        .o_valid(o_led_dht11_valid),
        .o_fnd_com(o_dht11_fnd_com),
        .o_fnd_data(o_dht11_fnd_data)
    );

    always #5 clk = ~clk;

    integer i = 0;
    initial begin
        clk = 0;
        rst = 1;

        i_dht11_refresh_req = 1'b0;
        i_dht11_show_humi = 1'b0;  // 0: 온도 표시, 1: 습도 표시

        io_oe = 1'b0;  // 처음에는 testbench가 DATA line을 잡지 않음
        dht_sensor_data = 1'b1;  // DHT11 idle 상태는 HIGH

        // reset
        #100;
        rst = 0;
        #100;

        // =========================
        // 1. 습도 표시 모드 선택
        // =========================
        i_dht11_show_humi = 1'b1;  // 습도 표시 모드

        // =========================
        // 2. DHT11 측정 시작 요청
        // =========================
        @(posedge clk);
        i_dht11_refresh_req = 1'b1;

        @(posedge clk);
        i_dht11_refresh_req = 1'b0;

        // =========================
        // 3. DUT가 start signal을 보내는지 대기
        // =========================
        wait (io_dht11 === 1'b0);  // DUT가 DATA line을 LOW로 당김
        wait (io_dht11 === 1'b1);  // DUT가 START LOW를 끝냄

        // DUT가 WAIT 상태를 지나고 DATA line을 놓을 시간 확보
        #40_000;  // 40us

        // =========================
        // 4. testbench가 DHT11 센서 역할 시작
        // =========================
        dht_sensor_data = 1'b0;
        io_oe = 1'b1;

        // DHT11 response LOW 약 80us
        #80_000;

        // DHT11 response HIGH 약 80us
        dht_sensor_data = 1'b1;
        #80_000;

        // =========================
        // 5. 40bit 데이터 전송
        // =========================
        for (i = 39; i >= 0; i = i - 1) begin
            // 각 bit 시작 LOW 약 50us
            dht_sensor_data = 1'b0;
            #50_000;

            // HIGH 시간으로 0/1 구분
            dht_sensor_data = 1'b1;

            if (DATA_STREAM[i]) begin
                #70_000;  // bit = 1
            end else begin
                #26_000;  // bit = 0
            end
        end

        // =========================
        // 6. 전송 종료
        // =========================
        dht_sensor_data = 1'b0;
        #50_000;

        // testbench가 DATA line을 놓음
        io_oe = 1'b0;
        dht_sensor_data = 1'b1;

        // 결과 반영 대기
        #1_000_000;

        // =========================
        // 7. 온도 표시 모드로 변경
        // =========================
        i_dht11_show_humi = 1'b0;  // 온도 표시 모드
        #1_000_000;

        $display("TEMP = %0d, HUMI = %0d, VALID = %b", o_dht11_temp,
                 o_dht11_humi, o_led_dht11_valid);

        $stop;
    end


endmodule
