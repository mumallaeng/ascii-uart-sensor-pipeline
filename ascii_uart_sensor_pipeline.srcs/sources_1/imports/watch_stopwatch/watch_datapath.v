`timescale 1ns / 1ps

module watch_datapath #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer TICK_HZ     = 100,
    parameter integer MSEC_TIMES = 100,
    parameter integer SEC_TIMES  = 60,
    parameter integer MIN_TIMES  = 60,
    parameter integer HOUR_TIMES = 24,
    parameter integer MSEC_WIDTH = 7,
    parameter integer SEC_WIDTH  = 6,
    parameter integer MIN_WIDTH  = 6,
    parameter integer HOUR_WIDTH = 5,
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
    output [23:0] o_set_time,
    output [23:0] o_watch_vault,
    output o_sec_tick,
    output o_min_tick,
    output o_hour_tick,
    output [MSEC_WIDTH-1:0] msec,
    output [SEC_WIDTH-1:0] sec,
    output [MIN_WIDTH-1:0] min,
    output [HOUR_WIDTH-1:0] hour
);

    localparam MSEC_LSB = 0;
    localparam MSEC_MSB = 6;
    localparam SEC_LSB  = 7;
    localparam SEC_MSB  = 12;
    localparam MIN_LSB  = 13;
    localparam MIN_MSB  = 18;
    localparam HOUR_LSB = 19;
    localparam HOUR_MSB = 23;

    wire w_tick_100hz;
    wire w_sec_tick;
    wire w_min_tick;
    wire w_hour_tick;
    wire w_apply_set_time;
    wire [23:0] w_live_time;
    wire [23:0] w_set_time;
    wire [23:0] w_set_time_load;

    reg set_mode_d_reg;

    assign o_sec_tick  = w_sec_tick;
    assign o_min_tick  = w_min_tick;
    assign o_hour_tick = w_hour_tick;

    // 실시간 시계값을 외부로 내보내는 24비트 버스
    // [6:0]=msec, [12:7]=sec, [18:13]=min, [23:19]=hour 순서로 묶음.
    // 현재는 내부 실제 시간을 24시간제 값 그대로 유지함.
    assign w_live_time       = {hour, min, sec, msec};
    assign o_watch_vault = w_live_time;

    // 편집 결과 버스는 time_set_module이 따로 생성함.
    assign o_set_time = w_set_time;

    // set_mode가 1 -> 0으로 떨어지는 순간에만 편집한 시간을 실제 시계값에 반영함.
    assign w_apply_set_time = set_mode_d_reg & ~i_set_mode;

    always @(posedge clk or posedge rst) begin
        if (rst) begin  // reset이면 이전 set_mode 상태를 초기화
            set_mode_d_reg <= 1'b0;
        end else begin  // 평소에는 현재 set_mode를 저장해 falling edge 검출에 사용
            set_mode_d_reg <= i_set_mode;
        end
    end

    // time_set_module은 실시간 시계값을 기준으로 편집 버스를 만들고
    // set 모드가 아닐 때는 live time을 그대로 따라가도록 동작함.
    time_set_module #(
        .MSEC_WIDTH(MSEC_WIDTH),
        .SEC_WIDTH(SEC_WIDTH),
        .MIN_WIDTH(MIN_WIDTH),
        .HOUR_WIDTH(HOUR_WIDTH),
        .MSEC_TIMES(MSEC_TIMES),
        .SEC_TIMES(SEC_TIMES),
        .MIN_TIMES(MIN_TIMES),
        .HOUR_TIMES(HOUR_TIMES),
        .INIT_HOUR(INIT_HOUR),
        .INIT_MIN(INIT_MIN)
    ) U_TIME_SET_MODULE (
        .clk(clk),
        .rst(rst),
        .i_set_mode(i_set_mode),
        .i_set_index(i_set_index),
        .i_index_shift(i_index_shift),
        .i_increment(i_increment),
        .i_increment_tens(i_increment_tens),
        .i_decrement(i_decrement),
        .i_decrement_tens(i_decrement_tens),
        .i_time_24(i_time_24),
        .i_live_time(w_live_time),
        .o_set_time(w_set_time),
        .o_set_time_load(w_set_time_load)
    );

    watch_tick_gen_100hz #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .TICK_HZ(TICK_HZ)
    ) U_TICK_GEN_100HZ (
        .clk(clk),
        .rst(rst),
        .o_tick_100hz(w_tick_100hz)
    );

    watch_tick_counter #(
        .TIMES(MSEC_TIMES),
        .BIT_WIDTH(MSEC_WIDTH),
        .INIT_VALUE(0)
    ) U_MSEC_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_tick_100hz),
        .i_load(w_apply_set_time),
        .i_time(w_set_time_load[MSEC_MSB:MSEC_LSB]),
        .o_time(msec),
        .o_tick(w_sec_tick)
    );

    watch_tick_counter #(
        .TIMES(SEC_TIMES),
        .BIT_WIDTH(SEC_WIDTH),
        .INIT_VALUE(0)
    ) U_SEC_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_sec_tick),
        .i_load(w_apply_set_time),
        .i_time(w_set_time_load[SEC_MSB:SEC_LSB]),
        .o_time(sec),
        .o_tick(w_min_tick)
    );

    watch_tick_counter #(
        .TIMES(MIN_TIMES),
        .BIT_WIDTH(MIN_WIDTH),
        .INIT_VALUE(INIT_MIN)
    ) U_MIN_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_min_tick),
        .i_load(w_apply_set_time),
        .i_time(w_set_time_load[MIN_MSB:MIN_LSB]),
        .o_time(min),
        .o_tick(w_hour_tick)
    );

    watch_tick_counter #(
        .TIMES(HOUR_TIMES),
        .BIT_WIDTH(HOUR_WIDTH),
        .INIT_VALUE(INIT_HOUR)
    ) U_HOUR_COUNTER (
        .clk(clk),
        .rst(rst),
        .i_tick(w_hour_tick),
        .i_load(w_apply_set_time),
        .i_time(w_set_time_load[HOUR_MSB:HOUR_LSB]),
        .o_time(hour),
        .o_tick()
    );
endmodule

module watch_tick_counter #(
    parameter integer TIMES = 100,
    parameter integer BIT_WIDTH = 7,
    parameter integer INIT_VALUE = 0
) (
    input clk,
    input rst,
    input i_tick,
    input i_load,
    input [BIT_WIDTH-1:0] i_time,
    output [BIT_WIDTH-1:0] o_time,
    output reg o_tick
);

    reg [BIT_WIDTH-1:0] time_reg;
    reg [BIT_WIDTH-1:0] time_next;

    assign o_time = time_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin  // reset이면 시간 초기화
            time_reg <= INIT_VALUE[BIT_WIDTH-1:0];
        end else begin  // 평소에는 시간 업데이트
            time_reg <= time_next;
        end
    end

    always @(*) begin
        time_next = time_reg;
        o_tick = 1'b0;

        if (i_load) begin  // load 펄스가 들어오면 입력된 시간으로 현재 값을 갱신
            time_next = i_time;
        end else if (i_tick) begin  // load 펄스가 없을 때는 시간 카운트
            if (time_reg == TIMES - 1) begin  // 최대 시간에 도달하면 시간 초기화하고 tick 발생
                time_next = 0;
                o_tick = 1'b1;
            end else begin  // 최대 시간에 도달하지 않으면 시간 증가
                time_next = time_reg + 1'b1;
            end
        end
    end

endmodule

module watch_tick_gen_100hz #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer TICK_HZ     = 100
) (
    input clk,
    input rst,
    output reg o_tick_100hz
);

    // 입력 클럭에서 몇 번 세면 100Hz tick 1번이 나와야 하는지 계산
    localparam integer TICK_COUNT = CLK_FREQ_HZ / TICK_HZ;

    // TICK_COUNT까지 세기 위한 카운터 레지스터
    reg [$clog2(TICK_COUNT)-1:0] count_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin  // reset이면 카운터와 tick 출력 초기화
            count_reg <= 0;
            o_tick_100hz <= 1'b0;
        end else if (count_reg == TICK_COUNT - 1) begin  // 목표 count에 도달하면
            count_reg <= 0;  // 카운터를 다시 0부터 세기 시작하고
            o_tick_100hz <= 1'b1;  // 이 클럭에서만 tick 1번 발생시키기
        end else begin  // 아직 목표 count에 도달하지 않았으면
            count_reg <= count_reg + 1'b1;  // 카운터 1 증가
            o_tick_100hz <= 1'b0;  // tick은 평소에 0 유지
        end
    end

endmodule
