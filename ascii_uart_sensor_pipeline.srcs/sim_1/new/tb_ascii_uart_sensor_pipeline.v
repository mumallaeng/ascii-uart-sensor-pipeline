`timescale 1ns / 1ps

// Top integration TB:
// INPUT -> decision_unit -> execute_unit -> display_unit -> remote_output_unit까지
// 한 번에 묶은 상태에서 top 외부 관찰 결과만 본다.
//
// 주의:
// - SR04/DHT11 최신 payload는 아직 placeholder wrapper 기준이라
//   이 TB에서는 sensor 값의 "정확한 숫자"까지 비교하지 않는다.
// - 대신 `SR04=` / `DHT11=` 줄이 정상적으로 나오고,
//   context/메타 라인이 기대대로 이어지는지만 본다.
module tb_ascii_uart_sensor_pipeline;
    // top TB는 기능 검증이 목적이므로 baud tick만 simulation 전용으로 줄여서
    // 시리얼 왕복을 훨씬 빠르게 본다.
    localparam integer SIM_BAUD_F_COUNT = 8;
    localparam integer BIT_PERIOD_NS = SIM_BAUD_F_COUNT * 16 * 10;
    localparam integer MAX_EXPECT_BYTES = 32;
    localparam integer TB_RESET_CYCLES = 16;

    reg clk;
    reg tb_rst;
    reg btnU;
    reg btnD;
    reg btnL;
    reg btnR;
    reg btnC;
    reg sw0;
    reg sw1;
    reg sw15;
    reg rx;
    reg echo;
    wire dht11_io;
    wire tx;
    wire trig;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire [2:0] led;
    wire w_tb_uart_b_tick;
    wire [7:0] w_tb_uart_rx_data;
    wire w_tb_uart_rx_done;

    // DUT 내부 RX/TX와 testbench RX가 모두 같은 빠른 baud tick을 쓰게 맞춘다.
    defparam DUT.U_REMOTE_INPUT_UNIT.U_UART_RX_FIFO.U_BAUD_TICK_GEN.F_COUNT = SIM_BAUD_F_COUNT;
    defparam DUT.U_REMOTE_OUTPUT_UNIT.U_UART_TX_UNIT.U_UART_TX_FIFO.U_UART.U_BAUD_TICK_GEN.F_COUNT = SIM_BAUD_F_COUNT;
    defparam U_TB_BAUD_TICK_GEN.F_COUNT = SIM_BAUD_F_COUNT;

    ascii_uart_sensor_pipeline DUT (
        .clk(clk),
        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),
        .btnC(btnC),
        .sw0(sw0),
        .sw1(sw1),
        .sw15(sw15),
        .rx(rx),
        .echo(echo),
        .dht11_io(dht11_io),
        .tx(tx),
        .trig(trig),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .led(led)
    );

    // DUT의 tx를 testbench 안에서 다시 UART RX로 복원해서
    // 실제 시리얼 프레임이 어떤 바이트로 보이는지 검증한다.
    baud_tick_gen U_TB_BAUD_TICK_GEN (
        .clk(clk),
        .rst(tb_rst),
        .o_b_tick(w_tb_uart_b_tick)
    );

    uart_rx U_TB_UART_RX (
        .clk(clk),
        .rst(tb_rst),
        .b_tick(w_tb_uart_b_tick),
        .rx(tx),
        .rx_data(w_tb_uart_rx_data),
        .rx_done(w_tb_uart_rx_done)
    );

    always #5 clk = ~clk;

    task automatic send_uart_byte;
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

    task automatic recv_uart_byte;
        output reg [7:0] data_byte;
        begin
            @(posedge w_tb_uart_rx_done);
            data_byte = w_tb_uart_rx_data;
        end
    endtask

    task automatic expect_uart_bytes;
        input [MAX_EXPECT_BYTES*8-1:0] expected_text;
        input integer expected_len;
        integer idx;
        reg [7:0] rx_byte;
        reg [7:0] expected_byte;
        begin
            for (idx = 0; idx < expected_len; idx = idx + 1) begin
                expected_byte = expected_text[((expected_len - 1 - idx) * 8) +: 8];
                recv_uart_byte(rx_byte);
                if (rx_byte !== expected_byte) begin
                    $fatal(
                        1,
                        "UART text mismatch at idx=%0d expected=%02h actual=%02h",
                        idx,
                        expected_byte,
                        rx_byte
                    );
                end
            end
        end
    endtask

    task automatic expect_prefix_and_skip_line;
        input [MAX_EXPECT_BYTES*8-1:0] prefix_text;
        input integer prefix_len;
        reg [7:0] rx_byte;
        reg [7:0] prev_byte;
        reg line_done;
        begin
            expect_uart_bytes(prefix_text, prefix_len);
            prev_byte = 8'h00;
            line_done = 1'b0;
            while (!line_done) begin
                recv_uart_byte(rx_byte);
                if ((prev_byte == 8'h0D) && (rx_byte == 8'h0A)) begin
                    line_done = 1'b1;
                end
                prev_byte = rx_byte;
            end
        end
    endtask

    task automatic send_text_status;
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

    task automatic send_text_unknown_cmd;
        begin
            send_uart_byte("b");
            send_uart_byte("n");
            send_uart_byte("t");
            send_uart_byte("R");
            send_uart_byte(8'h0D);
        end
    endtask

    task automatic send_text_status_with_delete_edit;
        begin
            // terminal에서 흔히 들어오는 delete를 앞뒤로 섞어도
            // 최종 token이 status로 복원되는지 확인한다.
            send_uart_byte(8'h7F);
            send_uart_byte("s");
            send_uart_byte("t");
            send_uart_byte("x");
            send_uart_byte(8'h7F);
            send_uart_byte("a");
            send_uart_byte("t");
            send_uart_byte("u");
            send_uart_byte("s");
            send_uart_byte(8'h0D);
        end
    endtask

    task automatic expect_status_frame;
        input [1:0] expected_context;
        begin
            expect_uart_bytes({"SRC=rmt", 8'h0D, 8'h0A}, 9);
            expect_uart_bytes({"CMD=stat", 8'h0D, 8'h0A}, 10);
            expect_uart_bytes({"EVT=stat", 8'h0D, 8'h0A}, 10);
            case (expected_context)
                2'd0: expect_uart_bytes({"CTX=wt", 8'h0D, 8'h0A}, 8);
                2'd3: expect_uart_bytes({"CTX=dht11", 8'h0D, 8'h0A}, 11);
                default: $fatal(1, "unexpected expected_context=%0d", expected_context);
            endcase
            expect_uart_bytes({"ACT=stat_rpt", 8'h0D, 8'h0A}, 14);

            // 시간/센서 줄은 prefix만 고정하고 실제 값은 스킵한다.
            // 이렇게 해야 현재 placeholder wrapper와 나중의 실제 센서 연동을
            // 같은 top TB로 모두 수용할 수 있다.
            expect_prefix_and_skip_line("WT=", 3);
            expect_prefix_and_skip_line("SW=", 3);
            expect_prefix_and_skip_line("SR04=", 5);
            expect_prefix_and_skip_line("DHT11=", 6);
            expect_uart_bytes({8'h0D, 8'h0A}, 2);
        end
    endtask

    initial begin
        #(BIT_PERIOD_NS * 8000);
        $fatal(1, "tb_ascii_uart_sensor_pipeline timeout");
    end

    initial begin
        clk = 1'b0;
        tb_rst = 1'b1;
        btnU = 1'b0;
        btnD = 1'b0;
        btnL = 1'b0;
        btnR = 1'b0;
        btnC = 1'b0;
        sw0 = 1'b0;
        sw1 = 1'b0;
        sw15 = 1'b0;
        rx = 1'b1;
        echo = 1'b0;

        repeat (TB_RESET_CYCLES) @(negedge clk);
        tb_rst = 1'b0;
        repeat (TB_RESET_CYCLES) @(negedge clk);

        // reset 직후에는 UART line idle과 기본 제어 출력만 확인한다.
        if (tx !== 1'b1) $fatal(1, "tx idle mismatch");
        if (trig !== 1'b0) $fatal(1, "trig default mismatch");
        if (led !== 3'b000) $fatal(1, "led default mismatch");

        // Scenario 1: WATCH context status 응답.
        $display("TB scenario1: watch status");
        #(BIT_PERIOD_NS * 2);
        send_text_status();
        expect_status_frame(2'd0);

        // Scenario 2: DHT11 context status 응답.
        $display("TB scenario2: dht11 status");
        sw1 = 1'b1;
        sw0 = 1'b1;
        repeat (4) @(posedge clk);
        send_text_status();
        expect_status_frame(2'd3);

        // Scenario 3: unknown command 응답.
        $display("TB scenario3: unknown command");
        send_text_unknown_cmd();
        expect_uart_bytes({"ERR=unk_cmd", 8'h0D, 8'h0A, 8'h0D, 8'h0A}, 15);

        // Scenario 4: delete/backspace가 섞여도 command가 정상 복원되는지 확인.
        $display("TB scenario4: status with delete edit");
        sw1 = 1'b0;
        sw0 = 1'b0;
        repeat (4) @(posedge clk);
        send_text_status_with_delete_edit();
        expect_status_frame(2'd0);

        $display("tb_ascii_uart_sensor_pipeline: PASS");
        $finish;
    end

endmodule
