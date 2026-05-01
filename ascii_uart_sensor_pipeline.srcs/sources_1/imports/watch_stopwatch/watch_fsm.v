`timescale 1ns / 1ps

module watch_fsm (
    input clk,
    input rst,
    input i_display_mode,
    input i_btnL,
    input i_btnU,
    input i_btnD,
    input i_btnU_hold,
    input i_btnD_hold,
    input i_btnR_hold,
    input i_sw0,
    output reg o_set_mode,
    output reg [1:0] o_set_index,
    output reg o_index_shift,
    output reg o_increment,
    output reg o_increment_tens,
    output reg o_decrement,
    output reg o_decrement_tens
);

    localparam [2:0] VIEW            = 3'b000;
    localparam [2:0] SET             = 3'b001;
    localparam [2:0] INDEX_SHIFT     = 3'b010;
    localparam [2:0] INCREMENT_ONES  = 3'b011;
    localparam [2:0] INCREMENT_TENS  = 3'b100;
    localparam [2:0] DECREMENT_ONES  = 3'b101;
    localparam [2:0] DECREMENT_TENS  = 3'b110;

    localparam [1:0] UNIT_HOUR = 2'd0;  // HH:MM left
    localparam [1:0] UNIT_MIN  = 2'd1;  // HH:MM right
    localparam [1:0] UNIT_SEC  = 2'd2;  // SS:MS left
    localparam [1:0] UNIT_MSEC = 2'd3;  // SS:MS right

    reg [2:0] current_state;
    reg [2:0] next_state;
    reg [1:0] set_index_reg;
    reg [1:0] set_index_next;
    reg display_mode_d_reg;

    function [1:0] default_unit_for_display;
        input display_mode;
    begin
        if (display_mode) default_unit_for_display = UNIT_MIN;   // HH:MM은 오른쪽(MM)부터 시작
        else              default_unit_for_display = UNIT_MSEC;  // SS:MS는 오른쪽(MS)부터 시작
    end
    endfunction

    function [1:0] remap_unit_for_display;
        input [1:0] current_unit;
        input display_mode;
    begin
        if (display_mode) begin
            case (current_unit)
                UNIT_SEC:  remap_unit_for_display = UNIT_HOUR;
                UNIT_MSEC: remap_unit_for_display = UNIT_MIN;
                default:   remap_unit_for_display = current_unit;
            endcase
        end else begin
            case (current_unit)
                UNIT_HOUR: remap_unit_for_display = UNIT_SEC;
                UNIT_MIN:  remap_unit_for_display = UNIT_MSEC;
                default:   remap_unit_for_display = current_unit;
            endcase
        end
    end
    endfunction

    function [1:0] next_unit;
        input [1:0] current_unit;
        input display_mode;
    begin
        if (display_mode) begin
            case (current_unit)
                UNIT_HOUR: next_unit = UNIT_MIN;
                default:   next_unit = UNIT_HOUR;  // MIN -> HOUR
            endcase
        end else begin
            case (current_unit)
                UNIT_SEC:  next_unit = UNIT_MSEC;
                default:   next_unit = UNIT_SEC;   // MSEC -> SEC
            endcase
        end
    end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin  // reset이면 기본 표시 상태로 초기화
            current_state <= VIEW;
            set_index_reg <= UNIT_MIN;
            display_mode_d_reg <= 1'b1;
        end else begin  // 평소에는 다음 상태로 전이
            current_state <= next_state;
            set_index_reg <= set_index_next;
            display_mode_d_reg <= i_display_mode;
        end
    end

    always @(*) begin
        next_state = current_state;
        set_index_next = set_index_reg;

        // sw0가 Stopwatch를 선택하면 Watch 설정 상태는 유지하지 않고 VIEW로 복귀
        if (i_sw0) begin
            next_state = VIEW;
            set_index_next = default_unit_for_display(i_display_mode);
        end else begin
            case (current_state)
                VIEW: begin
                    if (i_btnR_hold) begin
                        next_state = SET;                                   // Watch가 선택된 상태에서 BtnR hold가 들어오면 설정 모드 진입
                        set_index_next = default_unit_for_display(i_display_mode); // 현재 표시 모드에서 보이는 첫 단위부터 시작
                    end
                end

                SET: begin
                    if (i_display_mode != display_mode_d_reg) begin
                        set_index_next = remap_unit_for_display(set_index_reg, i_display_mode); // set 중 HH:MM <-> SS:MS 토글 시 현재 보이는 단위로 remap
                    end else if (i_btnR_hold) begin
                        next_state = VIEW;                                  // 설정 상태에서 BtnR hold가 들어오면 설정 종료
                        set_index_next = default_unit_for_display(i_display_mode);
                    end else if (i_btnL) begin
                        next_state = INDEX_SHIFT;                           // BtnL은 편집 단위를 다음 단위로 이동
                        set_index_next = next_unit(set_index_reg, i_display_mode);
                    end
                    else if (i_btnU) next_state = INCREMENT_ONES;           // BtnU short는 +1
                    else if (i_btnU_hold) next_state = INCREMENT_TENS;      //      hold는 +10 상태로 진입
                    else if (i_btnD) next_state = DECREMENT_ONES;           // BtnD short는 -1
                    else if (i_btnD_hold) next_state = DECREMENT_TENS;      //      hold는 -10 상태로 진입
                end

                // 아래 처리 상태들은 1클럭 동안만 제어 펄스를 내고 다시 SET으로 복귀
                INDEX_SHIFT: next_state = SET;
                INCREMENT_ONES: next_state = SET;
                INCREMENT_TENS: next_state = SET;
                DECREMENT_ONES: next_state = SET;
                DECREMENT_TENS: next_state = SET;

                default: next_state = VIEW;
            endcase
        end
    end

    always @(*) begin
        // 기본값: Watch는 VIEW에서 set mode off, 나머지 제어신호는 0
        o_set_mode = 1'b0;
        // 현재 편집 중인 단위를 외부에 그대로 내보냄
        o_set_index = set_index_reg;
        o_index_shift = 1'b0;
        o_increment = 1'b0;
        o_increment_tens = 1'b0;
        o_decrement = 1'b0;
        o_decrement_tens = 1'b0;

        case (current_state)
            VIEW: begin
                o_set_mode = 1'b0;
            end

            SET: begin
                o_set_mode = 1'b1;
            end

            INDEX_SHIFT: begin
                o_set_mode = 1'b1;
                o_index_shift = 1'b1;
            end

            INCREMENT_ONES: begin
                o_set_mode = 1'b1;
                o_increment = 1'b1;
            end

            INCREMENT_TENS: begin
                o_set_mode = 1'b1;
                o_increment_tens = 1'b1;
            end

            DECREMENT_ONES: begin
                o_set_mode = 1'b1;
                o_decrement = 1'b1;
            end

            DECREMENT_TENS: begin
                o_set_mode = 1'b1;
                o_decrement_tens = 1'b1;
            end
        endcase
    end

endmodule
