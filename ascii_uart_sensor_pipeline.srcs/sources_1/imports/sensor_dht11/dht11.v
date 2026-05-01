`timescale 1ns / 1ps

module dht11 (
    input clk,
    input rst,
    input dht11_start,
    inout dht11,
    output [7:0] humidity,
    output [7:0] temperature,
    output valid
);

    dht11_controller u_controller (
        .clk(clk),
        .rst(rst),
        .dht11_start(dht11_start),
        .dht11(dht11),
        .humidity(humidity),
        .temperature(temperature),
        .valid(valid)
    );
endmodule

module dht11_controller (
    input clk,
    input rst,
    input dht11_start,
    inout dht11,
    output [7:0] humidity,
    output [7:0] temperature,
    output valid
);

    localparam [3:0] IDLE = 4'd0,
                     START = 4'd1,
                     WAIT = 4'd2,
                     SYNC_LOW = 4'd3,
                     SYNC_HIGH = 4'd4,
                     DATA_SYNC = 4'd5,
                     DATA_COUNT = 4'd6,
                     DATA_DECISION = 4'd7,
                     STOP = 4'd8;

    localparam integer START_LOW_US = 19_000;
    localparam integer RELEASE_US = 30;
    localparam integer RESPONSE_TIMEOUT_US = 200;
    localparam integer BIT_HIGH_THRESHOLD_US = 50;
    localparam integer STOP_US = 100;
    localparam integer COUNT_W = 16;

    wire tick_us;

    reg [3:0] c_state, n_state;
    reg [5:0] bit_cnt_reg, bit_cnt_next;
    reg [COUNT_W-1:0] tick_cnt_reg, tick_cnt_next;
    reg out_sel_reg, out_sel_next;
    reg dht11_reg, dht11_next;
    reg [39:0] data_reg, data_next;
    reg valid_reg, valid_next;

    function checksum_ok;
        input [39:0] data_word;
        begin
            checksum_ok = (
                data_word[7:0] == (
                    data_word[39:32] + data_word[31:24] +
                    data_word[23:16] + data_word[15:8]
                )
            );
        end
    endfunction

    assign dht11 = out_sel_reg ? dht11_reg : 1'bz;
    assign humidity = data_reg[39:32];
    assign temperature = data_reg[23:16];
    assign valid = valid_reg;

    dht11_tick_gen_us u_tick_gen (
        .clk(clk),
        .rst(rst),
        .tick_us(tick_us)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state      <= IDLE;
            bit_cnt_reg  <= 6'd0;
            tick_cnt_reg <= {COUNT_W{1'b0}};
            out_sel_reg  <= 1'b1;
            dht11_reg    <= 1'b1;
            data_reg     <= 40'd0;
            valid_reg    <= 1'b0;
        end else begin
            c_state      <= n_state;
            bit_cnt_reg  <= bit_cnt_next;
            tick_cnt_reg <= tick_cnt_next;
            out_sel_reg  <= out_sel_next;
            dht11_reg    <= dht11_next;
            data_reg     <= data_next;
            valid_reg    <= valid_next;
        end
    end

    always @(*) begin
        n_state       = c_state;
        bit_cnt_next  = bit_cnt_reg;
        tick_cnt_next = tick_cnt_reg;
        out_sel_next  = out_sel_reg;
        dht11_next    = dht11_reg;
        data_next     = data_reg;
        valid_next    = valid_reg;

        case (c_state)
            IDLE: begin
                out_sel_next  = 1'b1;
                dht11_next    = 1'b1;
                bit_cnt_next  = 6'd0;
                tick_cnt_next = {COUNT_W{1'b0}};
                if (dht11_start) begin
                    data_next  = 40'd0;
                    valid_next = 1'b0;
                    n_state    = START;
                end
            end

            START: begin
                out_sel_next = 1'b1;
                dht11_next   = 1'b0;
                if (tick_us) begin
                    if (tick_cnt_reg >= START_LOW_US - 1) begin
                        tick_cnt_next = {COUNT_W{1'b0}};
                        dht11_next    = 1'b1;
                        n_state       = WAIT;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                    end
                end
            end

            WAIT: begin
                out_sel_next = 1'b1;
                dht11_next   = 1'b1;
                if (tick_us) begin
                    if (tick_cnt_reg >= RELEASE_US - 1) begin
                        tick_cnt_next = {COUNT_W{1'b0}};
                        out_sel_next  = 1'b0;
                        n_state       = SYNC_LOW;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                    end
                end
            end

            SYNC_LOW: begin
                out_sel_next = 1'b0;
                if (tick_us) begin
                    if (!dht11) begin
                        tick_cnt_next = {COUNT_W{1'b0}};
                        n_state       = SYNC_HIGH;
                    end else if (tick_cnt_reg >= RESPONSE_TIMEOUT_US - 1) begin
                        tick_cnt_next = {COUNT_W{1'b0}};
                        valid_next    = 1'b0;
                        n_state       = IDLE;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                    end
                end
            end

            SYNC_HIGH: begin
                out_sel_next = 1'b0;
                if (tick_us) begin
                    if (dht11) begin
                        tick_cnt_next = {COUNT_W{1'b0}};
                        n_state       = DATA_SYNC;
                    end else if (tick_cnt_reg >= RESPONSE_TIMEOUT_US - 1) begin
                        tick_cnt_next = {COUNT_W{1'b0}};
                        valid_next    = 1'b0;
                        n_state       = IDLE;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                    end
                end
            end

            DATA_SYNC: begin
                out_sel_next = 1'b0;
                if (tick_us) begin
                    if (!dht11) begin
                        tick_cnt_next = {COUNT_W{1'b0}};
                        n_state       = DATA_COUNT;
                    end else if (tick_cnt_reg >= RESPONSE_TIMEOUT_US - 1) begin
                        tick_cnt_next = {COUNT_W{1'b0}};
                        valid_next    = 1'b0;
                        n_state       = IDLE;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                    end
                end
            end

            DATA_COUNT: begin
                out_sel_next = 1'b0;
                if (tick_us) begin
                    if (dht11) begin
                        tick_cnt_next = {COUNT_W{1'b0}};
                        n_state       = DATA_DECISION;
                    end else if (tick_cnt_reg >= RESPONSE_TIMEOUT_US - 1) begin
                        tick_cnt_next = {COUNT_W{1'b0}};
                        valid_next    = 1'b0;
                        n_state       = IDLE;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                    end
                end
            end

            DATA_DECISION: begin
                out_sel_next = 1'b0;
                if (tick_us) begin
                    if (!dht11) begin
                        data_next = {
                            data_reg[38:0],
                            (tick_cnt_reg >= BIT_HIGH_THRESHOLD_US)
                        };
                        bit_cnt_next = bit_cnt_reg + 1'b1;
                        tick_cnt_next = {COUNT_W{1'b0}};

                        if (bit_cnt_reg == 6'd39) begin
                            valid_next = checksum_ok(
                                {
                                    data_reg[38:0],
                                    (tick_cnt_reg >= BIT_HIGH_THRESHOLD_US)
                                }
                            );
                            n_state = STOP;
                        end else begin
                            n_state = DATA_SYNC;
                        end
                    end else if (tick_cnt_reg >= RESPONSE_TIMEOUT_US - 1) begin
                        tick_cnt_next = {COUNT_W{1'b0}};
                        valid_next    = 1'b0;
                        n_state       = IDLE;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                    end
                end
            end

            STOP: begin
                out_sel_next = 1'b1;
                dht11_next   = 1'b1;
                if (tick_us) begin
                    if (tick_cnt_reg >= STOP_US - 1) begin
                        tick_cnt_next = {COUNT_W{1'b0}};
                        n_state       = IDLE;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1'b1;
                    end
                end
            end

            default: begin
                n_state = IDLE;
            end
        endcase
    end

endmodule

module dht11_tick_gen_us (
    input clk,
    input rst,
    output reg tick_us
);

    parameter F_COUNT = 100_000_000 / 1_000_000;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_reg <= {($clog2(F_COUNT)) {1'b0}};
            tick_us     <= 1'b0;
        end else begin
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= {($clog2(F_COUNT)) {1'b0}};
                tick_us     <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1'b1;
                tick_us     <= 1'b0;
            end
        end
    end

endmodule
