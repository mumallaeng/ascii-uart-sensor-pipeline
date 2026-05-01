`timescale 1ns / 1ps

module time_set_module #(
    parameter integer MSEC_WIDTH = 7,
    parameter integer SEC_WIDTH  = 6,
    parameter integer MIN_WIDTH  = 6,
    parameter integer HOUR_WIDTH = 5,
    parameter integer MSEC_TIMES = 100,
    parameter integer SEC_TIMES  = 60,
    parameter integer MIN_TIMES  = 60,
    parameter integer HOUR_TIMES = 24,
    parameter integer INIT_HOUR  = 13,
    parameter integer INIT_MIN   = 59
) (
    input clk,
    input rst,
    input i_set_mode,
    input [1:0] i_set_index,
    input i_index_shift,
    input i_increment,
    input i_increment_tens,
    input i_decrement,
    input i_decrement_tens,
    input [1:0] i_time_24,
    input [23:0] i_live_time,
    output [23:0] o_set_time,
    output [23:0] o_set_time_load
);

    localparam MSEC_LSB = 0;
    localparam MSEC_MSB = 6;
    localparam SEC_LSB  = 7;
    localparam SEC_MSB  = 12;
    localparam MIN_LSB  = 13;
    localparam MIN_MSB  = 18;
    localparam HOUR_LSB = 19;
    localparam HOUR_MSB = 23;

    localparam UNIT_HOUR = 2'd0;
    localparam UNIT_MIN  = 2'd1;
    localparam UNIT_SEC  = 2'd2;
    localparam UNIT_MSEC = 2'd3;

    localparam [MSEC_WIDTH-1:0] MSEC_MAX = MSEC_TIMES - 1;
    localparam [SEC_WIDTH-1:0]  SEC_MAX  = SEC_TIMES  - 1;
    localparam [MIN_WIDTH-1:0]  MIN_MAX  = MIN_TIMES  - 1;
    localparam [HOUR_WIDTH-1:0] HOUR_MAX = HOUR_TIMES - 1;
    localparam integer TENS_STEP = 10;

    reg [1:0] set_index_reg;
    reg [1:0] set_index_next;
    reg set_mode_d_reg;

    reg [MSEC_WIDTH-1:0] set_msec_reg;
    reg [SEC_WIDTH-1:0] set_sec_reg;
    reg [MIN_WIDTH-1:0] set_min_reg;
    reg [HOUR_WIDTH-1:0] set_hour_reg;

    reg [MSEC_WIDTH-1:0] set_msec_next;
    reg [SEC_WIDTH-1:0] set_sec_next;
    reg [MIN_WIDTH-1:0] set_min_next;
    reg [HOUR_WIDTH-1:0] set_hour_next;

    wire [MSEC_WIDTH-1:0] live_msec;
    wire [SEC_WIDTH-1:0] live_sec;
    wire [MIN_WIDTH-1:0] live_min;
    wire [HOUR_WIDTH-1:0] live_hour;
    wire [HOUR_WIDTH-1:0] set_display_hour;
    wire is_12_hour;

    function [MSEC_WIDTH-1:0] wrap_add_msec;
        input [MSEC_WIDTH-1:0] value;
        input integer step;
        integer sum;
    begin
        sum = value + step;
        if (sum >= MSEC_TIMES) wrap_add_msec = sum - MSEC_TIMES;
        else wrap_add_msec = sum[MSEC_WIDTH-1:0];
    end
    endfunction

    function [SEC_WIDTH-1:0] wrap_add_sec;
        input [SEC_WIDTH-1:0] value;
        input integer step;
        integer sum;
    begin
        sum = value + step;
        if (sum >= SEC_TIMES) wrap_add_sec = sum - SEC_TIMES;
        else wrap_add_sec = sum[SEC_WIDTH-1:0];
    end
    endfunction

    function [MIN_WIDTH-1:0] wrap_add_min;
        input [MIN_WIDTH-1:0] value;
        input integer step;
        integer sum;
    begin
        sum = value + step;
        if (sum >= MIN_TIMES) wrap_add_min = sum - MIN_TIMES;
        else wrap_add_min = sum[MIN_WIDTH-1:0];
    end
    endfunction

    function [HOUR_WIDTH-1:0] wrap_add_hour;
        input [HOUR_WIDTH-1:0] value;
        input integer step;
        integer sum;
    begin
        sum = value + step;
        if (sum >= HOUR_TIMES) wrap_add_hour = sum - HOUR_TIMES;
        else wrap_add_hour = sum[HOUR_WIDTH-1:0];
    end
    endfunction

    function [MSEC_WIDTH-1:0] wrap_sub_msec;
        input [MSEC_WIDTH-1:0] value;
        input integer step;
        integer diff;
    begin
        diff = value - step;
        if (diff < 0) wrap_sub_msec = diff + MSEC_TIMES;
        else wrap_sub_msec = diff[MSEC_WIDTH-1:0];
    end
    endfunction

    function [SEC_WIDTH-1:0] wrap_sub_sec;
        input [SEC_WIDTH-1:0] value;
        input integer step;
        integer diff;
    begin
        diff = value - step;
        if (diff < 0) wrap_sub_sec = diff + SEC_TIMES;
        else wrap_sub_sec = diff[SEC_WIDTH-1:0];
    end
    endfunction

    function [MIN_WIDTH-1:0] wrap_sub_min;
        input [MIN_WIDTH-1:0] value;
        input integer step;
        integer diff;
    begin
        diff = value - step;
        if (diff < 0) wrap_sub_min = diff + MIN_TIMES;
        else wrap_sub_min = diff[MIN_WIDTH-1:0];
    end
    endfunction

    function [HOUR_WIDTH-1:0] wrap_sub_hour;
        input [HOUR_WIDTH-1:0] value;
        input integer step;
        integer diff;
    begin
        diff = value - step;
        if (diff < 0) wrap_sub_hour = diff + HOUR_TIMES;
        else wrap_sub_hour = diff[HOUR_WIDTH-1:0];
    end
    endfunction

    assign live_msec = i_live_time[MSEC_MSB:MSEC_LSB];
    assign live_sec  = i_live_time[SEC_MSB:SEC_LSB];
    assign live_min  = i_live_time[MIN_MSB:MIN_LSB];
    assign live_hour = i_live_time[HOUR_MSB:HOUR_LSB];

    // 현재 프로젝트에서는 i_time_24의 LSB를 12h/24h 선택 비트로 사용
    assign is_12_hour = i_time_24[0];

    // load용 버스는 항상 내부 24시간제 값을 그대로 사용
    assign o_set_time_load = {set_hour_reg, set_min_reg, set_sec_reg, set_msec_reg};

    // 표시용 버스는 12시간제 선택 시 hour만 변환해서 내보냄
    assign set_display_hour =
        (!is_12_hour)               ? set_hour_reg :
        (set_hour_reg == 5'd0)      ? 5'd12 :
        (set_hour_reg <= 5'd12)     ? set_hour_reg :
                                      set_hour_reg - 5'd12;

    assign o_set_time = {set_display_hour, set_min_reg, set_sec_reg, set_msec_reg};

    always @(posedge clk or posedge rst) begin
        if (rst) begin  // reset이면 설정 버스와 set index 초기화
            set_index_reg  <= UNIT_HOUR;
            set_mode_d_reg <= 1'b0;
            set_msec_reg   <= 0;
            set_sec_reg    <= 0;
            set_min_reg    <= INIT_MIN[MIN_WIDTH-1:0];
            set_hour_reg   <= INIT_HOUR[HOUR_WIDTH-1:0];
        end else begin  // 평소에는 설정 버스와 set index 업데이트
            set_index_reg  <= set_index_next;
            set_mode_d_reg <= i_set_mode;
            set_msec_reg   <= set_msec_next;
            set_sec_reg    <= set_sec_next;
            set_min_reg    <= set_min_next;
            set_hour_reg   <= set_hour_next;
        end
    end

    always @(*) begin
        set_index_next = set_index_reg;

        set_msec_next = set_msec_reg;
        set_sec_next  = set_sec_reg;
        set_min_next  = set_min_reg;
        set_hour_next = set_hour_reg;

        if (!i_set_mode) begin
            // set 모드가 아니면 설정 버스가 현재 실시간 시계값을 따라가게 함.
            set_msec_next = live_msec;
            set_sec_next  = live_sec;
            set_min_next  = live_min;
            set_hour_next = live_hour;
        end else if (!set_mode_d_reg) begin
            // set 모드로 처음 진입한 순간에는 현재 시계를 기준으로 편집 시작함.
            set_index_next = i_set_index;
            set_msec_next  = live_msec;
            set_sec_next   = live_sec;
            set_min_next   = live_min;
            set_hour_next  = live_hour;
        end else if (i_index_shift) begin
            // 현재 편집 단위는 FSM이 결정하므로 그대로 따라감.
            set_index_next = i_set_index;
        end else if (i_increment) begin
            set_index_next = i_set_index;
            // increment 펄스가 들어오면 현재 선택 단위만 1 증가시킴.
            case (set_index_reg)
                UNIT_HOUR: set_hour_next = wrap_add_hour(set_hour_reg, 1);
                UNIT_MIN:  set_min_next  = wrap_add_min(set_min_reg, 1);
                UNIT_SEC:  set_sec_next  = wrap_add_sec(set_sec_reg, 1);
                UNIT_MSEC: set_msec_next = wrap_add_msec(set_msec_reg, 1);
                default: begin
                    set_msec_next = set_msec_reg;
                end
            endcase
        end else if (i_increment_tens) begin
            set_index_next = i_set_index;
            // hold increment 펄스가 들어오면 현재 선택 단위만 10 증가시킴.
            case (set_index_reg)
                UNIT_HOUR: set_hour_next = wrap_add_hour(set_hour_reg, TENS_STEP);
                UNIT_MIN:  set_min_next  = wrap_add_min(set_min_reg, TENS_STEP);
                UNIT_SEC:  set_sec_next  = wrap_add_sec(set_sec_reg, TENS_STEP);
                UNIT_MSEC: set_msec_next = wrap_add_msec(set_msec_reg, TENS_STEP);
                default: begin
                    set_msec_next = set_msec_reg;
                end
            endcase
        end else if (i_decrement) begin
            set_index_next = i_set_index;
            // decrement 펄스가 들어오면 현재 선택 단위만 1 감소시킴.
            case (set_index_reg)
                UNIT_HOUR: set_hour_next = wrap_sub_hour(set_hour_reg, 1);
                UNIT_MIN:  set_min_next  = wrap_sub_min(set_min_reg, 1);
                UNIT_SEC:  set_sec_next  = wrap_sub_sec(set_sec_reg, 1);
                UNIT_MSEC: set_msec_next = wrap_sub_msec(set_msec_reg, 1);
                default: begin
                    set_msec_next = set_msec_reg;
                end
            endcase
        end else if (i_decrement_tens) begin
            set_index_next = i_set_index;
            // hold decrement 펄스가 들어오면 현재 선택 단위만 10 감소시킴.
            case (set_index_reg)
                UNIT_HOUR: set_hour_next = wrap_sub_hour(set_hour_reg, TENS_STEP);
                UNIT_MIN:  set_min_next  = wrap_sub_min(set_min_reg, TENS_STEP);
                UNIT_SEC:  set_sec_next  = wrap_sub_sec(set_sec_reg, TENS_STEP);
                UNIT_MSEC: set_msec_next = wrap_sub_msec(set_msec_reg, TENS_STEP);
                default: begin
                    set_msec_next = set_msec_reg;
                end
            endcase
        end else begin
            // 입력이 없는 set 상태에서도 현재 편집 단위는 FSM 출력과 동기화함.
            set_index_next = i_set_index;
        end
    end

endmodule
