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
    reg [8:0] distance;
    button_debounce U_BD_SR04_START (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_R),
        .o_btn(w_sr04_start)
    );

    sr04_controller(
        .clk(clk),
        .rst(rst),
        .sr04_start(w_sr04_start),
        .tick_us(w_tick_us),
        .echo(echo),
        .trig(trig),
        .distance(w_distance)

    ); tick_gen_us(
        .clk(clk), .rst(rst), .tick_us(w_tick_us)
    );

    FND_CTRL U_FND (
        .clk(clk),
        .rst(rst),
        .sw({5'b00000, w_distance}),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );
    ila_1 U_ILA1 (
        .clk(clk),
        .probe0(w_sr04_start),
        .probe1(w_distancne)
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
    // sr04
    parameter IDLE = 0, START = 1, WAIT = 2, RESPONSE = 3;
    // reg [8:0] distance;
    reg [3:0] c_state, n_state;
    assign distance = distance_reg[8:0];
    reg [$clog(11_000)-1:0] tick_cnt_reg, tick_cnt_next;
    reg sr04_reg, se04_next;



    // count register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            bit_cnt_reg <= 0;
            tick_cnt_reg <= 0;
            tick_us <= 0;
            trig <= 0;
            sr04_reg <= 1'b1;

        end else begin
            c_state <= n_state;
            bit_cnt_reg <= bit_cnt_next;
            tick_cnt_reg <= tick_cnt_next;
            sr04_reg <= sr04_next;

        end


    end

    always @(*) begin
        n_state = c_state;
        bit_cnt_next = bit_cnt_reg;
        tick_cnt_next = tick_cnt_reg;
        sr04_next = sr04_reg;

        case (c_state)  // current state
            // IDLE

            IDLE: begin
                sr04_next = 1'b1;
                trig = 1'b0;

                if (sr04_start) begin
                    bit_cnt_next = 0;
                    tick_cnt_next = 0;
                    n_state = START;
                end
            end


            // START

            START: begin
                trig = 1'b1;
                if (tick_us) begin
                    if (tick_cnt_reg <= 11) begin
                        tick_cnt_next = tick_cnt_reg + 1;

                    end else begin
                        tick_cnt_next = 0;
                        n_state = WAIT;
                    end
                end
            end


            // WAIT
            WAIT: begin
                trig = 1'b0;
                if (tick_us) begin
                    if (echo) begin
                        tick_cnt_next = 0;
                        n_state = RESPONSE;
                    end
                end
            end
            // RESPONSE

            RESPONSE: begin
                if (tick_us) tick_cnt <= tick_cnt + 1;
                if (!echo) distance_reg = tick_cnt / 58;
            end

        endcase
        // sr04
    end

endmodule

module tick_gen_us (
    input clk,
    input rst,
    output reg tick_us
);

    parameter F_COUNT = 100_000_000 / 1_000_000;
    reg [$clog2(F_COUNT)-1:0] counter_reg;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_us <= 1'b0;

        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_us <= 1'b1;
            end else begin
                tick_us <= 1'b0;
            end
        end

    end

endmodule
