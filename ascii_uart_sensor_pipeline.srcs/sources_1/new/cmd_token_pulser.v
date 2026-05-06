`timescale 1ns / 1ps

`include "ascii_uart_sensor_pipeline_defs.vh"

module cmd_token_pulser (
    input clk,
    input rst,
    input i_cmd_token_valid,
    input [`CMD_W-1:0] i_cmd_token_code,
    output reg cmd_btnR,
    output reg cmd_btnR_hold,
    output reg cmd_btnL,
    output reg cmd_btnU,
    output reg cmd_btnD,
    output reg cmd_status,
    output reg cmd_clr
);

    // One-shot decode FSM matched to the design docs:
    // IDLE -> OUTPUT -> IDLE
    localparam IDLE = 1'b0;
    localparam OUTPUT = 1'b1;

    reg state_reg, state_next;
    reg [`CMD_W-1:0] cmd_token_code_reg, cmd_token_code_next;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg <= IDLE;
            cmd_token_code_reg <= `CMD_NONE;
        end else begin
            state_reg <= state_next;
            cmd_token_code_reg <= cmd_token_code_next;
        end
    end

    always @(*) begin
        state_next = state_reg;
        cmd_token_code_next = cmd_token_code_reg;

        cmd_btnR = 1'b0;
        cmd_btnR_hold = 1'b0;
        cmd_btnL = 1'b0;
        cmd_btnU = 1'b0;
        cmd_btnD = 1'b0;
        cmd_status = 1'b0;
        cmd_clr = 1'b0;

        case (state_reg)
            IDLE: begin
                if (i_cmd_token_valid) begin
                    // Latch one canonical command code, then emit exactly one pulse.
                    cmd_token_code_next = i_cmd_token_code;
                    state_next = OUTPUT;
                end
            end

            OUTPUT: begin
                // Only one command pulse should be asserted in this state.
                case (cmd_token_code_reg)
                    `CMD_BTNR: cmd_btnR = 1'b1;
                    `CMD_BTNR_HOLD: cmd_btnR_hold = 1'b1;
                    `CMD_BTNL: cmd_btnL = 1'b1;
                    `CMD_BTNU: cmd_btnU = 1'b1;
                    `CMD_BTND: cmd_btnD = 1'b1;
                    `CMD_STATUS: cmd_status = 1'b1;
                    `CMD_CLR: cmd_clr = 1'b1;
                    default: begin
                    end
                endcase
                state_next = IDLE;
            end

            default: begin
                state_next = IDLE;
                cmd_token_code_next = `CMD_NONE;
            end
        endcase
    end

endmodule
