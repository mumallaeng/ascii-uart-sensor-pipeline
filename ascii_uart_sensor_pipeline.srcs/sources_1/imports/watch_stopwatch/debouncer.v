`timescale 1ns / 1ps

module debouncer #(
    parameter CLK_FREQ_HZ = 100_000_000,
    parameter BD_HZ       = 100_000,
    parameter HOLD_TIME   = 100_000_000,
    parameter REPEAT_ENABLE = 0,
    parameter REPEAT_TIME = 20_000_000
) (
    input clk,
    input rst,
    input i_btn,
    output reg o_btn,
    output reg o_btn_hold
);

    localparam integer SAMPLE_COUNT = CLK_FREQ_HZ / BD_HZ;

    reg [$clog2(SAMPLE_COUNT)-1:0] sample_count_reg;
    reg sample_tick;
    reg [7:0] sync_reg;
    reg btn_db_reg;
    reg btn_db_d_reg;
    reg [31:0] hold_count_reg;
    reg hold_fired_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin  // debounce sample tick 초기화
            sample_count_reg <= 0;
            sample_tick      <= 1'b0;
        end else if (sample_count_reg == SAMPLE_COUNT - 1) begin
            sample_count_reg <= 0;
            sample_tick      <= 1'b1;
        end else begin
            sample_count_reg <= sample_count_reg + 1'b1;
            sample_tick      <= 1'b0;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin  // 샘플 히스토리와 stable button 상태 초기화
            sync_reg   <= 8'b0;
            btn_db_reg <= 1'b0;
        end else if (sample_tick) begin
            sync_reg <= {sync_reg[6:0], i_btn};

            if (&{sync_reg[6:0], i_btn}) begin
                btn_db_reg <= 1'b1;
            end else if (~|{sync_reg[6:0], i_btn}) begin
                btn_db_reg <= 1'b0;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin  // edge/hold 관련 레지스터와 출력 초기화
            btn_db_d_reg  <= 1'b0;
            hold_count_reg <= 32'd0;
            hold_fired_reg <= 1'b0;
            o_btn         <= 1'b0;
            o_btn_hold    <= 1'b0;
        end else begin
            btn_db_d_reg <= btn_db_reg;
            o_btn        <= 1'b0;
            o_btn_hold   <= 1'b0;

            if (btn_db_reg) begin  // 안정적으로 눌린 상태이면 hold 카운트 진행
                if (!hold_fired_reg) begin
                    if (hold_count_reg == HOLD_TIME - 1) begin
                        hold_count_reg <= 32'd0;
                        hold_fired_reg <= 1'b1;
                        o_btn_hold     <= 1'b1;
                    end else begin
                        hold_count_reg <= hold_count_reg + 1'b1;
                    end
                end else if (REPEAT_ENABLE) begin
                    if (hold_count_reg == REPEAT_TIME - 1) begin
                        hold_count_reg <= 32'd0;
                        o_btn_hold     <= 1'b1;  // hold 이후에는 repeat 주기마다 추가 pulse 발생
                    end else begin
                        hold_count_reg <= hold_count_reg + 1'b1;
                    end
                end
            end else begin
                // release edge에서 hold가 발생하지 않았으면 short 이벤트 1회 출력
                if (btn_db_d_reg && !hold_fired_reg) begin
                    o_btn <= 1'b1;
                end

                hold_count_reg <= 32'd0;
                hold_fired_reg <= 1'b0;
            end
        end
    end

endmodule
