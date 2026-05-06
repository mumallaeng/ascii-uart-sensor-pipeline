`timescale 1ns / 1ps

module sr04_unit (
    input clk,
    input rst,
    input i_refresh_req,
    input echo,
    output trig,
    output [11:0] o_distance_mm,
    output [3:0] o_fnd_com,
    output [7:0] o_fnd_data
);

    wire w_tick_us;
   
    sr04_controller U_SR04_CNTL (
        .clk(clk),
        .rst(rst),
        .sr04_start(i_refresh_req),
        .tick_us(w_tick_us),
        .echo(echo),
        .trig(trig),
        .o_distance_mm(o_distance_mm)
    );

    sr04_fnd_controller U_FND_CNTL (
        .clk(clk),
        .rst(rst),
        .i_distance_mm(o_distance_mm),
        .fnd_com(o_fnd_com),
        .fnd_data(o_fnd_data)
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
    output [11:0] o_distance_mm
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
    reg [11:0] distance_reg, distance_next;
    reg echo_sync_ff0, echo_sync_ff1;

    wire echo_sync;

    assign echo_sync = echo_sync_ff1;
    assign trig = (c_state == START);
    assign o_distance_mm = distance_reg;

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
            distance_reg      <= 12'd0;
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
                    distance_next = (echo_high_cnt_reg * 10) / 58;
                    n_state = IDLE;
                end else if (tick_us) begin
                    if (echo_high_cnt_reg == ECHO_TIMEOUT_US - 1) begin
                        distance_next = (echo_high_cnt_reg * 10) / 58;
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
