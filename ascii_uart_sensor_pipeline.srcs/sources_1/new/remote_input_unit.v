`timescale 1ns / 1ps

`include "ascii_uart_sensor_pipeline_defs.vh"

module remote_input_unit (
    input clk,
    input rst,
    input rx,
    output cmd_btnR,
    output cmd_btnR_hold,
    output cmd_btnL,
    output cmd_btnU,
    output cmd_btnD,
    output cmd_snap,
    output cmd_clr,
    output unknown_cmd
);

    wire byte_valid;
    wire [7:0] rx_byte;
    wire token_valid;
    wire [`AUSP_CMD_W-1:0] token_code;

    uart_rx_fifo U_UART_RX_FIFO (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .o_byte_valid(byte_valid),
        .o_byte(rx_byte)
    );

    pc_command_normalizer U_PC_COMMAND_NORMALIZER (
        .clk(clk),
        .rst(rst),
        .i_byte_valid(byte_valid),
        .i_byte(rx_byte),
        .o_token_valid(token_valid),
        .o_token_code(token_code),
        .o_unknown_token(unknown_cmd)
    );

    ascii_command_decoder U_ASCII_COMMAND_DECODER (
        .clk(clk),
        .rst(rst),
        .token_valid(token_valid),
        .token_code(token_code),
        .cmd_btnR(cmd_btnR),
        .cmd_btnR_hold(cmd_btnR_hold),
        .cmd_btnL(cmd_btnL),
        .cmd_btnU(cmd_btnU),
        .cmd_btnD(cmd_btnD),
        .cmd_snap(cmd_snap),
        .cmd_clr(cmd_clr)
    );

endmodule

module uart_rx_fifo #(
    parameter integer FIFO_DEPTH = 16
) (
    input clk,
    input rst,
    input rx,
    output o_byte_valid,
    output [7:0] o_byte
);

    wire b_tick;
    wire rx_done;
    wire [7:0] rx_data;
    wire fifo_full;
    wire fifo_empty;
    wire [7:0] fifo_pop_data;
    wire fifo_pop;

    assign fifo_pop = !fifo_empty;
    assign o_byte_valid = !fifo_empty;
    assign o_byte = fifo_pop_data;

    baud_tick_gen U_BAUD_TICK_GEN (
        .clk(clk),
        .rst(rst),
        .o_b_tick(b_tick)
    );

    uart_rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .b_tick(b_tick),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    fifo #(
        .DEPTH(FIFO_DEPTH)
    ) U_RX_FIFO (
        .clk(clk),
        .rst(rst),
        .push_data(rx_data),
        .push(rx_done && !fifo_full),
        .pop(fifo_pop),
        .pop_data(fifo_pop_data),
        .full(fifo_full),
        .empty(fifo_empty)
    );

endmodule

module pc_command_normalizer #(
    parameter integer MAX_TOKEN_BYTES = 16
) (
    input clk,
    input rst,
    input i_byte_valid,
    input [7:0] i_byte,
    output reg o_token_valid,
    output reg [`AUSP_CMD_W-1:0] o_token_code,
    output reg o_unknown_token
);

    localparam [2:0] IDLE = 3'd0;
    localparam [2:0] ACCUM = 3'd1;
    localparam [2:0] TOKEN_DONE = 3'd2;
    localparam [2:0] EMIT = 3'd3;
    localparam [2:0] ERROR = 3'd4;

    reg [2:0] state_reg, state_next;
    reg [3:0] token_len_reg, token_len_next;
    reg [7:0] token_mem_reg [0:MAX_TOKEN_BYTES-1];
    reg [7:0] token_mem_next [0:MAX_TOKEN_BYTES-1];
    reg [`AUSP_CMD_W-1:0] token_code_reg, token_code_next;

    integer idx;

    function is_delimiter;
        input [7:0] byte_value;
        begin
            is_delimiter = (byte_value == 8'h0D) || (byte_value == 8'h0A);
        end
    endfunction

    function match_btnR;
        input [3:0] token_len;
        input [7:0] c0, c1, c2, c3;
        begin
            match_btnR = (token_len == 4) &&
                (c0 == "b") && (c1 == "t") && (c2 == "n") && (c3 == "R");
        end
    endfunction

    function match_btnR_hold;
        input [3:0] token_len;
        input [7:0] c0, c1, c2, c3, c4, c5, c6, c7, c8;
        begin
            match_btnR_hold = (token_len == 9) &&
                (c0 == "b") && (c1 == "t") && (c2 == "n") && (c3 == "R") &&
                (c4 == "_") &&
                (c5 == "h") && (c6 == "o") && (c7 == "l") && (c8 == "d");
        end
    endfunction

    function match_btnL;
        input [3:0] token_len;
        input [7:0] c0, c1, c2, c3;
        begin
            match_btnL = (token_len == 4) &&
                (c0 == "b") && (c1 == "t") && (c2 == "n") && (c3 == "L");
        end
    endfunction

    function match_btnU;
        input [3:0] token_len;
        input [7:0] c0, c1, c2, c3;
        begin
            match_btnU = (token_len == 4) &&
                (c0 == "b") && (c1 == "t") && (c2 == "n") && (c3 == "U");
        end
    endfunction

    function match_btnD;
        input [3:0] token_len;
        input [7:0] c0, c1, c2, c3;
        begin
            match_btnD = (token_len == 4) &&
                (c0 == "b") && (c1 == "t") && (c2 == "n") && (c3 == "D");
        end
    endfunction

    function match_snap;
        input [3:0] token_len;
        input [7:0] c0, c1, c2, c3;
        begin
            match_snap = (token_len == 4) &&
                (c0 == "s") && (c1 == "n") && (c2 == "a") && (c3 == "p");
        end
    endfunction

    function match_clr;
        input [3:0] token_len;
        input [7:0] c0, c1, c2;
        begin
            match_clr = (token_len == 3) &&
                (c0 == "c") && (c1 == "l") && (c2 == "r");
        end
    endfunction

    function match_alias;
        input [3:0] token_len;
        input [7:0] c0;
        begin
            match_alias = (token_len == 1) &&
                ((c0 == "r") || (c0 == "l") || (c0 == "u") ||
                 (c0 == "d") || (c0 == "s") || (c0 == "c"));
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg <= IDLE;
            token_len_reg <= 4'd0;
            token_code_reg <= `AUSP_CMD_NONE;
            for (idx = 0; idx < MAX_TOKEN_BYTES; idx = idx + 1) begin
                token_mem_reg[idx] <= 8'h00;
            end
        end else begin
            state_reg <= state_next;
            token_len_reg <= token_len_next;
            token_code_reg <= token_code_next;
            for (idx = 0; idx < MAX_TOKEN_BYTES; idx = idx + 1) begin
                token_mem_reg[idx] <= token_mem_next[idx];
            end
        end
    end

    always @(*) begin
        state_next = state_reg;
        token_len_next = token_len_reg;
        token_code_next = token_code_reg;
        o_token_valid = 1'b0;
        o_token_code = `AUSP_CMD_NONE;
        o_unknown_token = 1'b0;

        for (idx = 0; idx < MAX_TOKEN_BYTES; idx = idx + 1) begin
            token_mem_next[idx] = token_mem_reg[idx];
        end

        case (state_reg)
            IDLE: begin
                token_len_next = 4'd0;
                token_code_next = `AUSP_CMD_NONE;
                if (i_byte_valid && !is_delimiter(i_byte)) begin
                    token_mem_next[0] = i_byte;
                    token_len_next = 4'd1;
                    state_next = ACCUM;
                end
            end

            ACCUM: begin
                if (i_byte_valid) begin
                    if (is_delimiter(i_byte)) begin
                        state_next = TOKEN_DONE;
                    end else if (token_len_reg < MAX_TOKEN_BYTES) begin
                        token_mem_next[token_len_reg] = i_byte;
                        token_len_next = token_len_reg + 1'b1;
                    end else begin
                        state_next = ERROR;
                    end
                end
            end

            TOKEN_DONE: begin
                if (match_btnR(token_len_reg, token_mem_reg[0], token_mem_reg[1], token_mem_reg[2], token_mem_reg[3])) begin
                    token_code_next = `AUSP_CMD_BTNR;
                    state_next = EMIT;
                end else if (match_btnR_hold(token_len_reg, token_mem_reg[0], token_mem_reg[1], token_mem_reg[2], token_mem_reg[3], token_mem_reg[4], token_mem_reg[5], token_mem_reg[6], token_mem_reg[7], token_mem_reg[8])) begin
                    token_code_next = `AUSP_CMD_BTNR_HOLD;
                    state_next = EMIT;
                end else if (match_btnL(token_len_reg, token_mem_reg[0], token_mem_reg[1], token_mem_reg[2], token_mem_reg[3])) begin
                    token_code_next = `AUSP_CMD_BTNL;
                    state_next = EMIT;
                end else if (match_btnU(token_len_reg, token_mem_reg[0], token_mem_reg[1], token_mem_reg[2], token_mem_reg[3])) begin
                    token_code_next = `AUSP_CMD_BTNU;
                    state_next = EMIT;
                end else if (match_btnD(token_len_reg, token_mem_reg[0], token_mem_reg[1], token_mem_reg[2], token_mem_reg[3])) begin
                    token_code_next = `AUSP_CMD_BTND;
                    state_next = EMIT;
                end else if (match_snap(token_len_reg, token_mem_reg[0], token_mem_reg[1], token_mem_reg[2], token_mem_reg[3])) begin
                    token_code_next = `AUSP_CMD_SNAP;
                    state_next = EMIT;
                end else if (match_clr(token_len_reg, token_mem_reg[0], token_mem_reg[1], token_mem_reg[2])) begin
                    token_code_next = `AUSP_CMD_CLR;
                    state_next = EMIT;
                end else if (match_alias(token_len_reg, token_mem_reg[0])) begin
                    case (token_mem_reg[0])
                        "r": token_code_next = `AUSP_CMD_BTNR;
                        "l": token_code_next = `AUSP_CMD_BTNL;
                        "u": token_code_next = `AUSP_CMD_BTNU;
                        "d": token_code_next = `AUSP_CMD_BTND;
                        "s": token_code_next = `AUSP_CMD_SNAP;
                        "c": token_code_next = `AUSP_CMD_CLR;
                        default: token_code_next = `AUSP_CMD_NONE;
                    endcase
                    state_next = EMIT;
                end else begin
                    state_next = ERROR;
                end
            end

            EMIT: begin
                o_token_valid = 1'b1;
                o_token_code = token_code_reg;
                state_next = IDLE;
            end

            ERROR: begin
                o_unknown_token = 1'b1;
                state_next = IDLE;
            end

            default: begin
                state_next = IDLE;
            end
        endcase
    end

endmodule
