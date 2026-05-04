`timescale 1ns / 1ps

`include "ascii_uart_sensor_pipeline_defs.vh"

// display_unit은 execute_unit이 만든 표시 후보들 중에서
// 현재 context에 맞는 FND source만 최종 보드 출력으로 내보낸다.
module display_unit (
    input [`CTX_W-1:0] i_current_context,
    input [3:0] i_watch_stopwatch_fnd_com,
    input [7:0] i_watch_stopwatch_fnd_data,
    input [3:0] i_sr04_fnd_com,
    input [7:0] i_sr04_fnd_data,
    input [3:0] i_dht11_fnd_com,
    input [7:0] i_dht11_fnd_data,
    output reg [3:0] o_fnd_com,
    output reg [7:0] o_fnd_data
);

    always @(*) begin
        // 연결이 아직 안 된 후보가 있더라도 보드에 쓰레기 패턴이 안 보이게
        // 기본값은 항상 blank로 두고 필요한 context에서만 덮어쓴다.
        o_fnd_com = 4'b1111;
        o_fnd_data = 8'hFF;

        case (i_current_context)
            `CTX_WATCH,
            `CTX_STOPWATCH: begin
                // WATCH와 STOPWATCH는 execute_unit 안에서 이미 하나의 후보로
                // 정리되어 나오므로 여기서는 그대로 통과만 시킨다.
                o_fnd_com = i_watch_stopwatch_fnd_com;
                o_fnd_data = i_watch_stopwatch_fnd_data;
            end
            `CTX_SR04: begin
                o_fnd_com = i_sr04_fnd_com;
                o_fnd_data = i_sr04_fnd_data;
            end
            `CTX_DHT11: begin
                o_fnd_com = i_dht11_fnd_com;
                o_fnd_data = i_dht11_fnd_data;
            end
            default: begin
                o_fnd_com = 4'b1111;
                o_fnd_data = 8'hFF;
            end
        endcase
    end

endmodule
