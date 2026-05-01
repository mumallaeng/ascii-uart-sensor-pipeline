`timescale 1ns / 1ps

module common_control (
    input clk,
    input rst,
    input i_sw0,
    input i_btnR,
    output reg o_display_mode
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin  // reset이면 watch=HH:MM, stopwatch=SS:MS 기본값으로 초기화
            o_display_mode <= ~i_sw0;
        end else if (i_btnR) begin  // btnR short가 들어오면 HH:MM <-> SS:MS 토글
            o_display_mode <= ~o_display_mode;
        end
    end

endmodule
