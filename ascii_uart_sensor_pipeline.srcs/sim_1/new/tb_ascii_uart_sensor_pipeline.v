`timescale 1ns / 1ps

// Top smoke TB:
// 현재 top skeleton에서 INPUT과 decision_unit은 연결돼 있고,
// function/output은 아직 기본값으로 묶여 있는 상태를 확인한다.
module tb_ascii_uart_sensor_pipeline;
    // UART command 자극에 쓰는 9600 baud bit period(ns).
    localparam integer BIT_PERIOD_NS = 104166;

    reg clk;
    reg rst;
    reg btnU;
    reg btnD;
    reg btnL;
    reg btnR;
    reg btnC;
    reg [15:0] sw;
    reg rx;
    reg echo;
    wire dht11_io;
    wire tx;
    wire trig;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire [2:0] led;

    // 저장한 WCFG에서 중요하게 볼 내부 관찰 결과를
    // sticky flag로 요약해 둔다.
    reg seen_btnR;
    reg seen_status;
    reg seen_unknown_cmd;

    ascii_uart_sensor_pipeline DUT (
        .clk(clk),
        .rst(rst),
        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),
        .btnC(btnC),
        .sw(sw),
        .rx(rx),
        .echo(echo),
        .dht11_io(dht11_io),
        .tx(tx),
        .trig(trig),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .led(led)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst) begin
            seen_btnR <= 1'b0;
            seen_status <= 1'b0;
            seen_unknown_cmd <= 1'b0;
        end else begin
            // 현재 top에 연결된 remote-input 경로를
            // top 내부 wire 기준으로 관찰한다.
            if (DUT.w_cmd_btnR) seen_btnR <= 1'b1;
            if (DUT.w_cmd_status) seen_status <= 1'b1;
            if (DUT.w_unknown_cmd) seen_unknown_cmd <= 1'b1;
        end
    end

    // 아래 command task들이 공통으로 쓰는 UART byte sender.
    task send_uart_byte;
        input [7:0] data_byte;
        integer bit_idx;
        begin
            rx = 1'b0;
            #(BIT_PERIOD_NS);
            for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                rx = data_byte[bit_idx];
                #(BIT_PERIOD_NS);
            end
            rx = 1'b1;
            #(BIT_PERIOD_NS);
        end
    endtask

    // Scenario 1: "btnR\\r"가 top 내부 command wire까지 도달해야 한다.
    task send_text_btnR;
        begin
            send_uart_byte("b");
            send_uart_byte("t");
            send_uart_byte("n");
            send_uart_byte("R");
            send_uart_byte(8'h0D);
        end
    endtask

    // Scenario 2: "status\\r"가 top 내부 command wire까지 도달해야 한다.
    task send_text_status;
        begin
            send_uart_byte("s");
            send_uart_byte("t");
            send_uart_byte("a");
            send_uart_byte("t");
            send_uart_byte("u");
            send_uart_byte("s");
            send_uart_byte(8'h0D);
        end
    endtask

    initial begin
        // local/sensor 입력은 조용히 두고,
        // 이 TB는 top shell이 remote ASCII command를 계속 올바르게 라우팅하는지,
        // 그리고 downstream이 붙기 전까지 안전한 출력 기본값을 유지하는지만 본다.
        clk = 1'b0;
        rst = 1'b1;
        btnU = 1'b0;
        btnD = 1'b0;
        btnL = 1'b0;
        btnR = 1'b0;
        btnC = 1'b0;
        sw = 16'h0000;
        rx = 1'b1;
        echo = 1'b0;
        seen_btnR = 1'b0;
        seen_status = 1'b0;
        seen_unknown_cmd = 1'b0;

        repeat (5) @(negedge clk);
        rst = 1'b0;

        // Check 0: 아직 미구현인 top 출력은 안전 기본값을 유지해야 한다.
        if (tx !== 1'b1) $fatal(1, "tx default output mismatch");
        if (trig !== 1'b0) $fatal(1, "trig default output mismatch");
        if (fnd_com !== 4'b1111) $fatal(1, "fnd_com default output mismatch");
        if (fnd_data !== 8'hFF) $fatal(1, "fnd_data default output mismatch");
        if (led !== 3'b000) $fatal(1, "led default output mismatch");

        // Check 1: btnR command가 top 내부 remote-input wiring까지 도달해야 한다.
        #(BIT_PERIOD_NS * 2);
        send_text_btnR();
        #(BIT_PERIOD_NS * 20);
        if (!seen_btnR) $fatal(1, "top internal btnR pulse missing");

        // Check 2: status command가 top 내부 remote-input wiring까지 도달해야 한다.
        send_text_status();
        #(BIT_PERIOD_NS * 20);
        if (!seen_status) $fatal(1, "top internal status pulse missing");

        // Check 3: 이 시나리오에서는 unknown command가 나오면 안 된다.
        if (seen_unknown_cmd) $fatal(1, "unexpected top unknown_cmd pulse");

        $display("tb_ascii_uart_sensor_pipeline: PASS");
        $finish;
    end
endmodule
