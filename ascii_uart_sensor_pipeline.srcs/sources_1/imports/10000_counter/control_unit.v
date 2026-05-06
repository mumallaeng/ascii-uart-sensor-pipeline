`timescale 1ns / 1ps

module control_unit (
    input clk,
    input rst,
    input i_run_stop,
    input i_clear,
    input i_btnu,
    input i_btnd,
    input [2:0] i_sw,
    output o_run_stop,
    output reg o_clear,
    output o_down_mode,
    output o_display_sel,
    output [1:0] o_led,
    output [1:0] o_state_dbg
);

    localparam [1:0] STOP  = 2'd0;
    localparam [1:0] RUN   = 2'd1;
    localparam [1:0] CLEAR = 2'd2;
    localparam [1:0] DIR   = 2'd3;

    reg       run_stop_reg;
    reg       down_mode_reg;
    reg [1:0] state_dbg_reg;

    assign o_run_stop    = run_stop_reg;
    assign o_down_mode   = down_mode_reg;
    assign o_display_sel = i_sw[0];
    assign o_led         = {down_mode_reg, run_stop_reg};
    assign o_state_dbg   = state_dbg_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            run_stop_reg  <= 1'b0;
            down_mode_reg <= 1'b0;
            state_dbg_reg <= STOP;
            o_clear       <= 1'b0;
        end else begin
            o_clear       <= 1'b0;
            state_dbg_reg <= run_stop_reg ? RUN : STOP;

            if (i_clear) begin
                o_clear       <= 1'b1;
                state_dbg_reg <= CLEAR;
            end

            if (i_run_stop) begin
                run_stop_reg  <= ~run_stop_reg;
                state_dbg_reg <= ~run_stop_reg ? RUN : STOP;
            end

            if (i_btnu) begin
                down_mode_reg <= 1'b0;
                state_dbg_reg <= DIR;
            end else if (i_btnd) begin
                down_mode_reg <= 1'b1;
                state_dbg_reg <= DIR;
            end
        end
    end

endmodule
