`timescale 1ns / 1ps

module ascii_decoder (
    input clk,
    input rst,
    input i_rx_empty,
    input [7:0] btn_data,
    output reg pop,
    output reg btnC,
    output reg btnR,
    output reg btnL,
    output reg btnU,
    output reg btnD,
    output reg btnS
    // output btnC,
    // output btnC,
    // output btnC,
    // output btnC,
);

    parameter IDLE = 0, DATA_POP = 1;
    reg state_reg, state_next;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state_reg <= 0;
        end else begin
            state_reg <= state_next;
        end
    end

    always @(*) begin
        state_next = state_reg;
        pop = 0;
        btnC = 0;
        btnR = 0;
        btnL = 0;
        btnU = 0;
        btnD = 0;
        btnS = 0;
        case (state_reg)
            IDLE: begin
                if (!i_rx_empty) begin
                    state_next = DATA_POP;
                end
            end
            DATA_POP: begin
                pop = 1;
                state_next = IDLE;
                case (btn_data)
                    /*C*/8'h43, 8'h63: btnC = 1;
                    /*R*/8'h52, 8'h72: btnR = 1;
                    /*L*/8'h4C, 8'h6C: btnL = 1;
                    /*U*/8'h55, 8'h75: btnU = 1;
                    /*D*/8'h44, 8'h64: btnD = 1;
                    /*D*/8'h53, 8'h73: btnS = 1;
                endcase
            end
        endcase

    end






endmodule
