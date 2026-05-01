`timescale 1ns / 1ps

module button_debounce #(
    parameter integer SAMPLE_COUNT_MAX = 100_000,
    parameter integer STABLE_SAMPLES = 8
) (
    input clk,
    input rst,
    input i_btn,
    output o_btn_sync,
    output o_btn_level,
    output o_btn_tick
);

    localparam integer SAMPLE_COUNTER_WIDTH = (SAMPLE_COUNT_MAX <= 1) ? 1 : $clog2(SAMPLE_COUNT_MAX);

    reg sync_ff0, sync_ff1;
    reg [SAMPLE_COUNTER_WIDTH-1:0] sample_counter_reg;
    reg sample_tick_reg;
    reg [STABLE_SAMPLES-1:0] history_reg;
    reg level_reg, level_d1_reg;

    wire [STABLE_SAMPLES-1:0] history_next;

    assign history_next = {history_reg[STABLE_SAMPLES-2:0], sync_ff1};
    assign o_btn_sync = sync_ff1;
    assign o_btn_level = level_reg;
    assign o_btn_tick = level_reg & ~level_d1_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_ff0 <= 1'b0;
            sync_ff1 <= 1'b0;
        end else begin
            sync_ff0 <= i_btn;
            sync_ff1 <= sync_ff0;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sample_counter_reg <= {SAMPLE_COUNTER_WIDTH{1'b0}};
            sample_tick_reg <= 1'b0;
        end else begin
            sample_tick_reg <= 1'b0;
            if (sample_counter_reg == SAMPLE_COUNT_MAX - 1) begin
                sample_counter_reg <= {SAMPLE_COUNTER_WIDTH{1'b0}};
                sample_tick_reg <= 1'b1;
            end else begin
                sample_counter_reg <= sample_counter_reg + 1'b1;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            history_reg <= {STABLE_SAMPLES{1'b0}};
        end else if (sample_tick_reg) begin
            history_reg <= history_next;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            level_reg <= 1'b0;
        end else if (sample_tick_reg) begin
            if (&history_next) begin
                level_reg <= 1'b1;
            end else if (~|history_next) begin
                level_reg <= 1'b0;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            level_d1_reg <= 1'b0;
        end else begin
            level_d1_reg <= level_reg;
        end
    end

endmodule
