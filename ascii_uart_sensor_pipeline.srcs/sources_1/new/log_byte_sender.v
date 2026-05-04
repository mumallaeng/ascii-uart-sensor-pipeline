`timescale 1ns / 1ps

module log_byte_sender #(
    parameter integer FRAME_LEN_W = 8
) (
    input                            clk,
    input                            rst,
    input                            start,
    input                            i_tx_full,
    input      [7:0]                 i_frame_byte,
    input      [FRAME_LEN_W-1:0]     i_frame_len,
    output     [FRAME_LEN_W-1:0]     o_frame_byte_index,
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
    reg [FRAME_LEN_W-1:0] idx_reg, idx_next;
    reg [FRAME_LEN_W-1:0] frame_len_reg, frame_len_next;
    assign o_frame_byte_index = idx_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg      <= IDLE;
            idx_reg        <= {FRAME_LEN_W{1'b0}};
            frame_len_reg  <= {FRAME_LEN_W{1'b0}};
        end else begin
            state_reg      <= state_next;
            idx_reg        <= idx_next;
            frame_len_reg  <= frame_len_next;
        end
    end

    always @(*) begin
        state_next      = state_reg;
        idx_next        = idx_reg;
        frame_len_next  = frame_len_reg;

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
                // 송신 중인 status log는 remote_output_unit의 active 상태로 고정돼 있다.
                // sender는 전체 문자열을 다시 복사하지 않고 길이와 현재 index만 관리한다.
                idx_next        = {FRAME_LEN_W{1'b0}};
                frame_len_next  = i_frame_len;
                busy            = 1'b1;

                if (i_frame_len == {FRAME_LEN_W{1'b0}}) begin
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
                push_data = i_frame_byte;
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
