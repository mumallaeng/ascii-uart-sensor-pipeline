`timescale 1ns / 1ps

module dht11_unit (
    input clk,
    input rst,
    input i_refresh_req,
    input i_show_humi,
    input i_show_fahrenheit,
    inout dht11_io,

    output [7:0] o_temp,
    output [7:0] o_temp_frac,
    output [7:0] o_humi,
    output [7:0] o_humi_frac,
    output       o_valid,
    output [3:0] o_fnd_com,
    output [7:0] o_fnd_data
);


    wire w_tick_us, w_valid;
    wire [7:0] w_humi, w_humi_frac, w_temp, w_temp_frac;

    assign o_temp = w_temp;
    assign o_temp_frac = w_temp_frac;
    assign o_humi = w_humi;
    assign o_humi_frac = w_humi_frac;
    assign o_valid = w_valid;

    dht11_fnd_controller U_FND_CNTL (
        .clk     (clk),
        .rst     (rst),
        .i_show_humi(i_show_humi),
        .i_show_fahrenheit(i_show_fahrenheit),
        .i_temp_int (w_temp),
        .i_temp_frac(w_temp_frac),
        .i_humi_int (w_humi),
        .i_humi_frac(w_humi_frac),
        .fnd_com (o_fnd_com),
        .fnd_data(o_fnd_data)
    );

    dht11_controller U_DNT11_CNTL (
        .clk        (clk),
        .rst        (rst),
        .dht11_start(i_refresh_req),
        .tick_us    (w_tick_us),
        .humidity_int (w_humi),
        .humidity_frac(w_humi_frac),
        .temperature_int(w_temp),
        .temperature_frac(w_temp_frac),
        .valid      (w_valid),
        // valid가 1이면 led ON / check sum 확인
        .dht11      (dht11_io)
    );

    dht11_tick_gen_us U_TICK_GEN (
        .clk    (clk),
        .rst    (rst),
        .tick_us(w_tick_us)
    );

endmodule

module dht11_controller (
    input        clk,
    input        rst,
    input        dht11_start,
    input        tick_us,
    output [7:0] humidity_int,
    output [7:0] humidity_frac,
    output [7:0] temperature_int,
    output [7:0] temperature_frac,
    output       valid,        // valid가 1이면 led ON / check sum 확인
    inout        dht11
);

    parameter IDLE = 0, START = 1, WAIT = 2, SYNCL = 3, SYNCH = 4;
    parameter DATA_SYNC = 5, DATA_COUNT = 6, DATA_DECISION = 7;
    parameter STOP = 8;

    reg [3:0] c_state, n_state;
    reg [5:0] bit_cnt_reg, bit_cnt_next;  // 총 40bit
    reg [$clog2(19_000)-1:0]
        tick_cnt_reg, tick_cnt_next;  // general tick counter (19ms)
    reg out_sel_reg, out_sel_next;  // dht11 io 3state control
    reg dht11_reg, dht11_next;  // dht11 output drive

    reg [39:0] data_reg, data_next;

    reg dht11_sync1, dht11_sync2;

    // dht11 output 3state control
    assign dht11 = (out_sel_reg) ? dht11_reg : 1'bz;

    assign valid = (data_reg[7:0] == (data_reg[39:32] + data_reg[31:24] + data_reg [23:16] + data_reg[15:8])) ? 1:0;

    assign humidity_int = data_reg[39:32];
    assign humidity_frac = data_reg[31:24];
    assign temperature_int = data_reg[23:16];
    assign temperature_frac = data_reg[15:8];

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state      <= IDLE;
            bit_cnt_reg  <= 0;
            tick_cnt_reg <= 0;
            out_sel_reg  <= 1'b1;  // default output mode
            dht11_reg    <= 1'b1;  // default high state
            dht11_sync1  <= 1'b1;
            dht11_sync2  <= 1'b1;
            data_reg     <= 0;
        end else begin
            c_state      <= n_state;
            bit_cnt_reg  <= bit_cnt_next;
            tick_cnt_reg <= tick_cnt_next;
            out_sel_reg  <= out_sel_next;
            dht11_reg    <= dht11_next;
            data_reg     <= data_next;
            dht11_sync1  <= dht11;
            dht11_sync2  <= dht11_sync1;
        end
    end

    always @(*) begin
        n_state       = c_state;
        bit_cnt_next  = bit_cnt_reg;
        tick_cnt_next = tick_cnt_reg;
        out_sel_next  = out_sel_reg;
        dht11_next    = dht11_reg;
        data_next     = data_reg;
        case (c_state)
            IDLE: begin
                dht11_next   = 1'b1;
                out_sel_next = 1'b1;
                if (dht11_start) begin
                    bit_cnt_next  = 0;
                    tick_cnt_next = 0;
                    n_state       = START;
                end
            end
            START: begin
                dht11_next = 1'b0;
                if (tick_us) begin
                    if (tick_cnt_reg > 19_000) begin
                        tick_cnt_next = 0;
                        n_state       = WAIT;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            WAIT: begin
                dht11_next = 1'b1;
                if (tick_us) begin
                    if (tick_cnt_reg > 30) begin
                        tick_cnt_next = 0;
                        n_state       = SYNCL;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            SYNCL: begin
                // output is high impedance "z"
                out_sel_next = 1'b0;
                if (tick_us) begin
                    if ((tick_cnt_reg > 40) && (dht11_sync2)) begin
                        tick_cnt_next = 0;
                        n_state = SYNCH;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            SYNCH: begin
                if (tick_us) begin
                    if ((tick_cnt_reg > 40) && (!dht11_sync2)) begin
                        tick_cnt_next = 0;
                        n_state = DATA_SYNC;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            DATA_SYNC: begin
                if (tick_us) begin
                    if (dht11_sync2) begin
                        tick_cnt_next = 0;
                        n_state = DATA_COUNT;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            DATA_COUNT: begin
                if (tick_us) begin
                    if (!dht11_sync2) begin
                        n_state = DATA_DECISION;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            DATA_DECISION: begin
                if (tick_cnt_reg > 50) begin
                    data_next = {data_reg[38:0], 1'b1};
                    tick_cnt_next = 0;
                end else begin
                    data_next = {data_reg[38:0], 1'b0};
                    tick_cnt_next = 0;
                end
                bit_cnt_next = bit_cnt_reg + 1;
                if (bit_cnt_reg == 39) begin
                    n_state = STOP;
                end else begin
                    n_state = DATA_SYNC;
                end
            end
            STOP: begin
                if (tick_us) begin
                    if (tick_cnt_reg > 50) begin
                        tick_cnt_next = 0;
                        n_state = IDLE;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end

endmodule

module dht11_tick_gen_us (
    input      clk,
    input      rst,
    output reg tick_us
);

    parameter F_COUNT = 100_000_000 / 1_000_000;  // 1us
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
