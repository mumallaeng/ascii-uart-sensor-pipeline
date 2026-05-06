`timescale 1ns / 1ps

module common_control (
    input clk,
    input rst,
    input i_sw0,
    input i_btnR,
    output reg o_display_mode
);

    reg r_sw0_d;

    always @(posedge clk) begin
        if (rst) begin
            // i_sw0에 따라 reset 기본 표시를 정하되, 비동기 reset에서 입력 의존값을
            // 직접 쓰지 않도록 동기식으로 처리한다.
            o_display_mode <= ~i_sw0;
            r_sw0_d <= i_sw0;
        end else begin
            // WATCH <-> STOPWATCH context가 바뀌면 각 context의 기본 표시로 다시 맞춘다.
            if (i_sw0 != r_sw0_d) begin
                o_display_mode <= ~i_sw0;
            end else if (i_btnR) begin  // btnR short가 들어오면 HH:MM <-> SS:MS 토글
                o_display_mode <= ~o_display_mode;
            end

            r_sw0_d <= i_sw0;
        end
    end

endmodule
