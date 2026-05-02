`timescale 1ns / 1ps

module ascii_frame_sender #(
    parameter integer FRAME_MAX_BYTES = 24
) (
    input                            clk,
    input                            rst,
    input                            start,
    input                            i_tx_full,
    input      [FRAME_MAX_BYTES*8-1:0] i_frame_data,
    input      [5:0]                 i_frame_len,
    output reg [7:0]                 push_data,
    output reg                       push,
    output reg                       busy
);

    localparam [2:0] IDLE      = 3'd0;
    localparam [2:0] LOAD_META = 3'd1;
    localparam [2:0] WAIT_SLOT = 3'd2;
    localparam [2:0] PUSH_BYTE = 3'd3;
    localparam [2:0] ADVANCE   = 3'd4;
    localparam [2:0] DONE      = 3'd5;

    reg [2:0] state_reg, state_next;
    reg [5:0] idx_reg, idx_next;
    reg [5:0] frame_len_reg, frame_len_next;
    reg [FRAME_MAX_BYTES*8-1:0] frame_data_reg, frame_data_next;

    function [7:0] get_frame_byte;
        input [FRAME_MAX_BYTES*8-1:0] frame_data;
        input [5:0]                   index;
        begin
            get_frame_byte = frame_data[(index * 8) +: 8];
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg      <= IDLE;
            idx_reg        <= 6'd0;
            frame_len_reg  <= 6'd0;
            frame_data_reg <= {(FRAME_MAX_BYTES*8){1'b0}};
        end else begin
            state_reg      <= state_next;
            idx_reg        <= idx_next;
            frame_len_reg  <= frame_len_next;
            frame_data_reg <= frame_data_next;
        end
    end

    always @(*) begin
        state_next      = state_reg;
        idx_next        = idx_reg;
        frame_len_next  = frame_len_reg;
        frame_data_next = frame_data_reg;

        push_data = 8'd0;
        push      = 1'b0;
        busy      = 1'b0;

        case (state_reg)
            IDLE: begin
                if (start) begin
                    state_next = LOAD_META;
                end
            end

            LOAD_META: begin
                // Latch the whole frame so page changes do not corrupt an in-flight line.
                idx_next        = 6'd0;
                frame_len_next  = i_frame_len;
                frame_data_next = i_frame_data;
                busy            = 1'b1;

                if (i_frame_len == 6'd0) begin
                    state_next = DONE;
                end else begin
                    state_next = WAIT_SLOT;
                end
            end

            WAIT_SLOT: begin
                busy = 1'b1;
                if (!i_tx_full) begin
                    state_next = PUSH_BYTE;
                end
            end

            PUSH_BYTE: begin
                busy      = 1'b1;
                push      = 1'b1;
                push_data = get_frame_byte(frame_data_reg, idx_reg);
                state_next = ADVANCE;
            end

            ADVANCE: begin
                busy = 1'b1;
                if (idx_reg + 1'b1 >= frame_len_reg) begin
                    state_next = DONE;
                end else begin
                    idx_next   = idx_reg + 1'b1;
                    state_next = WAIT_SLOT;
                end
            end

            DONE: begin
                state_next = IDLE;
            end

            default: begin
                state_next = IDLE;
            end
        endcase
    end

endmodule
