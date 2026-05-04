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
    output cmd_status,
    output cmd_clr,
    output unknown_cmd
);

    // Remote RX path:
    // serial rx -> uart_rx_fifo -> ascii_command_parser -> cmd_token_pulser
    wire ascii_byte_valid;
    wire [7:0] ascii_byte;
    wire cmd_token_valid;
    wire [`CMD_W-1:0] cmd_token_code;

    uart_rx_fifo U_UART_RX_FIFO (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .o_ascii_byte_valid(ascii_byte_valid),
        .o_ascii_byte(ascii_byte)
    );

    ascii_command_parser U_ASCII_COMMAND_PARSER (
        .clk(clk),
        .rst(rst),
        .i_ascii_byte_valid(ascii_byte_valid),
        .i_ascii_byte(ascii_byte),
        .o_cmd_token_valid(cmd_token_valid),
        .o_cmd_token_code(cmd_token_code),
        .o_unknown_token(unknown_cmd)
    );

    cmd_token_pulser U_CMD_TOKEN_PULSER (
        .clk(clk),
        .rst(rst),
        .i_cmd_token_valid(cmd_token_valid),
        .i_cmd_token_code(cmd_token_code),
        .cmd_btnR(cmd_btnR),
        .cmd_btnR_hold(cmd_btnR_hold),
        .cmd_btnL(cmd_btnL),
        .cmd_btnU(cmd_btnU),
        .cmd_btnD(cmd_btnD),
        .cmd_status(cmd_status),
        .cmd_clr(cmd_clr)
    );

endmodule

module uart_rx_fifo #(
    parameter integer FIFO_DEPTH = 16
) (
    input clk,
    input rst,
    input rx,
    output o_ascii_byte_valid,
    output [7:0] o_ascii_byte
);

    wire b_tick;
    wire rx_done;
    wire [7:0] rx_data;
    wire fifo_full;
    wire fifo_empty;
    wire [7:0] fifo_pop_data;
    wire fifo_pop;

    // Present a simple ASCII-byte-valid stream to downstream logic.
    assign fifo_pop = !fifo_empty;
    assign o_ascii_byte_valid = !fifo_empty;
    assign o_ascii_byte = fifo_pop_data;

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

module ascii_command_parser #(
    parameter integer MAX_CMD_CHARS = 16
) (
    input clk,
    input rst,
    input i_ascii_byte_valid,
    input [7:0] i_ascii_byte,
    output reg o_cmd_token_valid,
    output reg [`CMD_W-1:0] o_cmd_token_code,
    output reg o_unknown_token
);

    // FSM matched to the design docs:
    // IDLE -> COLLECT -> DECODE -> OUTPUT -> IDLE
    //                            \-> ERROR  -> IDLE
    localparam [2:0] IDLE = 3'd0;
    localparam [2:0] COLLECT = 3'd1;
    localparam [2:0] DECODE = 3'd2;
    localparam [2:0] OUTPUT = 3'd3;
    localparam [2:0] ERROR = 3'd4;

    reg [2:0] state_reg, state_next;
    reg [3:0] cmd_char_count_reg, cmd_char_count_next;
    reg [7:0] cmd_chars_reg [0:MAX_CMD_CHARS-1];
    reg [7:0] cmd_chars_next [0:MAX_CMD_CHARS-1];
    reg [`CMD_W-1:0] cmd_token_code_reg, cmd_token_code_next;

    integer idx;

    function is_delimiter;
        input [7:0] byte_value;
        begin
            is_delimiter = (byte_value == 8'h0D) || (byte_value == 8'h0A);
        end
    endfunction

    function match_btnR;
        input [3:0] cmd_char_count;
        input [7:0] c0, c1, c2, c3;
        begin
            match_btnR = (cmd_char_count == 4) &&
                (c0 == "b") && (c1 == "t") && (c2 == "n") && (c3 == "R");
        end
    endfunction

    function match_btnR_hold;
        input [3:0] cmd_char_count;
        input [7:0] c0, c1, c2, c3, c4, c5, c6, c7, c8;
        begin
            match_btnR_hold = (cmd_char_count == 9) &&
                (c0 == "b") && (c1 == "t") && (c2 == "n") && (c3 == "R") &&
                (c4 == "_") &&
                (c5 == "h") && (c6 == "o") && (c7 == "l") && (c8 == "d");
        end
    endfunction

    function match_btnL;
        input [3:0] cmd_char_count;
        input [7:0] c0, c1, c2, c3;
        begin
            match_btnL = (cmd_char_count == 4) &&
                (c0 == "b") && (c1 == "t") && (c2 == "n") && (c3 == "L");
        end
    endfunction

    function match_btnU;
        input [3:0] cmd_char_count;
        input [7:0] c0, c1, c2, c3;
        begin
            match_btnU = (cmd_char_count == 4) &&
                (c0 == "b") && (c1 == "t") && (c2 == "n") && (c3 == "U");
        end
    endfunction

    function match_btnD;
        input [3:0] cmd_char_count;
        input [7:0] c0, c1, c2, c3;
        begin
            match_btnD = (cmd_char_count == 4) &&
                (c0 == "b") && (c1 == "t") && (c2 == "n") && (c3 == "D");
        end
    endfunction

    function match_status;
        input [3:0] cmd_char_count;
        input [7:0] c0, c1, c2, c3, c4, c5;
        begin
            match_status = (cmd_char_count == 6) &&
                (c0 == "s") && (c1 == "t") && (c2 == "a") &&
                (c3 == "t") && (c4 == "u") && (c5 == "s");
        end
    endfunction

    function match_clr;
        input [3:0] cmd_char_count;
        input [7:0] c0, c1, c2;
        begin
            match_clr = (cmd_char_count == 3) &&
                (c0 == "c") && (c1 == "l") && (c2 == "r");
        end
    endfunction

    function match_alias;
        input [3:0] cmd_char_count;
        input [7:0] c0;
        begin
            match_alias = (cmd_char_count == 1) &&
                ((c0 == "r") || (c0 == "l") || (c0 == "u") ||
                 (c0 == "d") || (c0 == "s") || (c0 == "c"));
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg <= IDLE;
            cmd_char_count_reg <= 4'd0;
            cmd_token_code_reg <= `CMD_NONE;
            for (idx = 0; idx < MAX_CMD_CHARS; idx = idx + 1) begin
                cmd_chars_reg[idx] <= 8'h00;
            end
        end else begin
            state_reg <= state_next;
            cmd_char_count_reg <= cmd_char_count_next;
            cmd_token_code_reg <= cmd_token_code_next;
            for (idx = 0; idx < MAX_CMD_CHARS; idx = idx + 1) begin
                cmd_chars_reg[idx] <= cmd_chars_next[idx];
            end
        end
    end

    always @(*) begin
        state_next = state_reg;
        cmd_char_count_next = cmd_char_count_reg;
        cmd_token_code_next = cmd_token_code_reg;
        o_cmd_token_valid = 1'b0;
        o_cmd_token_code = `CMD_NONE;
        o_unknown_token = 1'b0;

        for (idx = 0; idx < MAX_CMD_CHARS; idx = idx + 1) begin
            cmd_chars_next[idx] = cmd_chars_reg[idx];
        end

        case (state_reg)
            IDLE: begin
                cmd_char_count_next = 4'd0;
                cmd_token_code_next = `CMD_NONE;
                if (i_ascii_byte_valid && !is_delimiter(i_ascii_byte)) begin
                    // First ASCII byte of a new command string.
                    cmd_chars_next[0] = i_ascii_byte;
                    cmd_char_count_next = 4'd1;
                    state_next = COLLECT;
                end
            end

            COLLECT: begin
                if (i_ascii_byte_valid) begin
                    if (is_delimiter(i_ascii_byte)) begin
                        // CR/LF ends one command token.
                        state_next = DECODE;
                    end else if (cmd_char_count_reg < MAX_CMD_CHARS) begin
                        // Keep collecting command characters.
                        cmd_chars_next[cmd_char_count_reg] = i_ascii_byte;
                        cmd_char_count_next = cmd_char_count_reg + 1'b1;
                    end else begin
                        // Too long: reject this token.
                        state_next = ERROR;
                    end
                end
            end

            DECODE: begin
                // Normalize full strings and one-char aliases into CMD_* codes.
                if (match_btnR(cmd_char_count_reg, cmd_chars_reg[0], cmd_chars_reg[1], cmd_chars_reg[2], cmd_chars_reg[3])) begin
                    cmd_token_code_next = `CMD_BTNR;
                    state_next = OUTPUT;
                end else if (match_btnR_hold(cmd_char_count_reg, cmd_chars_reg[0], cmd_chars_reg[1], cmd_chars_reg[2], cmd_chars_reg[3], cmd_chars_reg[4], cmd_chars_reg[5], cmd_chars_reg[6], cmd_chars_reg[7], cmd_chars_reg[8])) begin
                    cmd_token_code_next = `CMD_BTNR_HOLD;
                    state_next = OUTPUT;
                end else if (match_btnL(cmd_char_count_reg, cmd_chars_reg[0], cmd_chars_reg[1], cmd_chars_reg[2], cmd_chars_reg[3])) begin
                    cmd_token_code_next = `CMD_BTNL;
                    state_next = OUTPUT;
                end else if (match_btnU(cmd_char_count_reg, cmd_chars_reg[0], cmd_chars_reg[1], cmd_chars_reg[2], cmd_chars_reg[3])) begin
                    cmd_token_code_next = `CMD_BTNU;
                    state_next = OUTPUT;
                end else if (match_btnD(cmd_char_count_reg, cmd_chars_reg[0], cmd_chars_reg[1], cmd_chars_reg[2], cmd_chars_reg[3])) begin
                    cmd_token_code_next = `CMD_BTND;
                    state_next = OUTPUT;
                end else if (match_status(cmd_char_count_reg, cmd_chars_reg[0], cmd_chars_reg[1], cmd_chars_reg[2], cmd_chars_reg[3], cmd_chars_reg[4], cmd_chars_reg[5])) begin
                    cmd_token_code_next = `CMD_STATUS;
                    state_next = OUTPUT;
                end else if (match_clr(cmd_char_count_reg, cmd_chars_reg[0], cmd_chars_reg[1], cmd_chars_reg[2])) begin
                    cmd_token_code_next = `CMD_CLR;
                    state_next = OUTPUT;
                end else if (match_alias(cmd_char_count_reg, cmd_chars_reg[0])) begin
                    case (cmd_chars_reg[0])
                        "r": cmd_token_code_next = `CMD_BTNR;
                        "l": cmd_token_code_next = `CMD_BTNL;
                        "u": cmd_token_code_next = `CMD_BTNU;
                        "d": cmd_token_code_next = `CMD_BTND;
                        "s": cmd_token_code_next = `CMD_STATUS;
                        "c": cmd_token_code_next = `CMD_CLR;
                        default: cmd_token_code_next = `CMD_NONE;
                    endcase
                    state_next = OUTPUT;
                end else begin
                    state_next = ERROR;
                end
            end

            OUTPUT: begin
                // One-cycle canonical command-token pulse toward cmd_token_pulser.
                o_cmd_token_valid = 1'b1;
                o_cmd_token_code = cmd_token_code_reg;
                state_next = IDLE;
            end

            ERROR: begin
                // Keep error reporting separate from valid token output.
                o_unknown_token = 1'b1;
                state_next = IDLE;
            end

            default: begin
                state_next = IDLE;
            end
        endcase
    end

endmodule
