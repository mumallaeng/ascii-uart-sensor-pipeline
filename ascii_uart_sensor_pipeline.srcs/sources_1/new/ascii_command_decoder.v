`timescale 1ns / 1ps

`include "ascii_uart_sensor_pipeline_defs.vh"

module ascii_command_decoder (
    input clk,
    input rst,
    input token_valid,
    input [`AUSP_CMD_W-1:0] token_code,
    output reg cmd_btnR,
    output reg cmd_btnR_hold,
    output reg cmd_btnL,
    output reg cmd_btnU,
    output reg cmd_btnD,
    output reg cmd_snap,
    output reg cmd_clr
);

    localparam IDLE = 1'b0;
    localparam EMIT_PULSE = 1'b1;

    reg state_reg, state_next;
    reg [`AUSP_CMD_W-1:0] token_code_reg, token_code_next;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg <= IDLE;
            token_code_reg <= `AUSP_CMD_NONE;
        end else begin
            state_reg <= state_next;
            token_code_reg <= token_code_next;
        end
    end

    always @(*) begin
        state_next = state_reg;
        token_code_next = token_code_reg;

        cmd_btnR = 1'b0;
        cmd_btnR_hold = 1'b0;
        cmd_btnL = 1'b0;
        cmd_btnU = 1'b0;
        cmd_btnD = 1'b0;
        cmd_snap = 1'b0;
        cmd_clr = 1'b0;

        case (state_reg)
            IDLE: begin
                if (token_valid) begin
                    token_code_next = token_code;
                    state_next = EMIT_PULSE;
                end
            end

            EMIT_PULSE: begin
                case (token_code_reg)
                    `AUSP_CMD_BTNR: cmd_btnR = 1'b1;
                    `AUSP_CMD_BTNR_HOLD: cmd_btnR_hold = 1'b1;
                    `AUSP_CMD_BTNL: cmd_btnL = 1'b1;
                    `AUSP_CMD_BTNU: cmd_btnU = 1'b1;
                    `AUSP_CMD_BTND: cmd_btnD = 1'b1;
                    `AUSP_CMD_SNAP: cmd_snap = 1'b1;
                    `AUSP_CMD_CLR: cmd_clr = 1'b1;
                    default: begin
                    end
                endcase
                state_next = IDLE;
            end

            default: begin
                state_next = IDLE;
                token_code_next = `AUSP_CMD_NONE;
            end
        endcase
    end

endmodule
