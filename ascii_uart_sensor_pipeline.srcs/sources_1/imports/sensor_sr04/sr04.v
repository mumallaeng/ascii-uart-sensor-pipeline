`timescale 1ns / 1ps

module sr04 (
    input clk,
    input rst,
    input btn_R,
    input echo,
    output trig,
    output [3:0] fnd_com,
    output [7:0] fnd_data
);

    wire w_sr04_start;
    wire w_tick_us;
    wire [8:0] w_distance;

    button_debounce U_BTN_DEBOUNCE (
        .clk(clk),
        .rst(rst),
        .i_btn(btn_R),
        .o_btn_sync(),
        .o_btn_level(),
        .o_btn_tick(w_sr04_start)
    );

    sr04_controller U_SR04_CNTL (
        .clk(clk),
        .rst(rst),
        .sr04_start(w_sr04_start),
        .tick_us(w_tick_us),
        .echo(echo),
        .trig(trig),
        .distance(w_distance)
    );

    sr04_fnd_controller U_FND_CNTL (
        .clk(clk),
        .rst(rst),
        .fnd_in({5'b00000, w_distance}),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

    sr04_tick_gen_us U_TICK_GEN (
        .clk(clk),
        .rst(rst),
        .tick_us(w_tick_us)
    );
endmodule

module sr04_controller (
    input clk,
    input rst,
    input sr04_start,
    input tick_us,
    input echo,
    output trig,
    output [8:0] distance
);

    localparam [1:0] IDLE = 2'd0;
    localparam [1:0] START = 2'd1;
    localparam [1:0] WAIT = 2'd2;
    localparam [1:0] RESPONSE = 2'd3;

    localparam integer TRIG_PULSE_US = 10;
    localparam integer ECHO_TIMEOUT_US = 30_000;
    localparam integer TRIG_COUNT_WIDTH = (TRIG_PULSE_US <= 1) ? 1 : $clog2(TRIG_PULSE_US);
    localparam integer ECHO_COUNT_WIDTH = (ECHO_TIMEOUT_US <= 1) ? 1 : $clog2(ECHO_TIMEOUT_US);

    reg [1:0] c_state, n_state;
    reg [TRIG_COUNT_WIDTH-1:0] trig_cnt_reg, trig_cnt_next;
    reg [ECHO_COUNT_WIDTH-1:0] echo_wait_cnt_reg, echo_wait_cnt_next;
    reg [ECHO_COUNT_WIDTH-1:0] echo_high_cnt_reg, echo_high_cnt_next;
    reg [8:0] distance_reg, distance_next;
    reg echo_sync_ff0, echo_sync_ff1;

    wire echo_sync;

    assign echo_sync = echo_sync_ff1;
    assign trig = (c_state == START);
    assign distance = distance_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            echo_sync_ff0 <= 1'b0;
            echo_sync_ff1 <= 1'b0;
        end else begin
            echo_sync_ff0 <= echo;
            echo_sync_ff1 <= echo_sync_ff0;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state           <= IDLE;
            trig_cnt_reg      <= {TRIG_COUNT_WIDTH{1'b0}};
            echo_wait_cnt_reg <= {ECHO_COUNT_WIDTH{1'b0}};
            echo_high_cnt_reg <= {ECHO_COUNT_WIDTH{1'b0}};
            distance_reg      <= 9'd0;
        end else begin
            c_state           <= n_state;
            trig_cnt_reg      <= trig_cnt_next;
            echo_wait_cnt_reg <= echo_wait_cnt_next;
            echo_high_cnt_reg <= echo_high_cnt_next;
            distance_reg      <= distance_next;
        end
    end

    always @(*) begin
        n_state             = c_state;
        trig_cnt_next       = trig_cnt_reg;
        echo_wait_cnt_next  = echo_wait_cnt_reg;
        echo_high_cnt_next  = echo_high_cnt_reg;
        distance_next       = distance_reg;

        case (c_state)
            IDLE: begin
                trig_cnt_next      = {TRIG_COUNT_WIDTH{1'b0}};
                echo_wait_cnt_next = {ECHO_COUNT_WIDTH{1'b0}};
                echo_high_cnt_next = {ECHO_COUNT_WIDTH{1'b0}};
                if (sr04_start) begin
                    n_state = START;
                end
            end
            START: begin
                if (tick_us) begin
                    if (trig_cnt_reg == TRIG_PULSE_US - 1) begin
                        trig_cnt_next = {TRIG_COUNT_WIDTH{1'b0}};
                        n_state = WAIT;
                    end else begin
                        trig_cnt_next = trig_cnt_reg + 1'b1;
                    end
                end
            end
            WAIT: begin
                if (echo_sync) begin
                    echo_wait_cnt_next = {ECHO_COUNT_WIDTH{1'b0}};
                    echo_high_cnt_next = {ECHO_COUNT_WIDTH{1'b0}};
                    n_state = RESPONSE;
                end else if (tick_us) begin
                    if (echo_wait_cnt_reg == ECHO_TIMEOUT_US - 1) begin
                        echo_wait_cnt_next = {ECHO_COUNT_WIDTH{1'b0}};
                        n_state = IDLE;
                    end else begin
                        echo_wait_cnt_next = echo_wait_cnt_reg + 1'b1;
                    end
                end
            end
            RESPONSE: begin
                if (!echo_sync) begin
                    distance_next = echo_high_cnt_reg / 58;
                    n_state = IDLE;
                end else if (tick_us) begin
                    if (echo_high_cnt_reg == ECHO_TIMEOUT_US - 1) begin
                        distance_next = echo_high_cnt_reg / 58;
                        n_state = IDLE;
                    end else begin
                        echo_high_cnt_next = echo_high_cnt_reg + 1'b1;
                    end
                end
            end
            default: begin
                n_state = IDLE;
            end
        endcase
    end

endmodule

module sr04_tick_gen_us (
    input clk,
    input rst,
    output reg tick_us
);

    parameter F_COUNT = 100_000_000 / 1_000_000;  // 100MHz / 1MHz = 100
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_us     <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_us <= 1'b1;
            end else tick_us <= 1'b0;
        end
    end

endmodule
