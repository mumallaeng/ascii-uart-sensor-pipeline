`timescale 1ns / 1ps

module dht11_fnd_controller #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer SCAN_HZ = 1000
) (
    input clk,
    input rst,
    input i_show_humi,
    input i_show_fahrenheit,
    input [7:0] i_temp_int,
    input [7:0] i_temp_frac,
    input [7:0] i_humi_int,
    input [7:0] i_humi_frac,
    output [3:0] fnd_com,
    output [7:0] fnd_data
);

    wire [13:0] w_temp_scaled;
    wire [13:0] w_humi_scaled;
    wire [13:0] w_temp_fahrenheit_scaled;
    wire [13:0] w_selected_scaled;
    wire [15:0] w_temp_c_x100;
    wire [15:0] w_temp_f_x100;
    wire w_decimal_enable;
    wire [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000;
    wire [3:0] w_out_mux;
    wire [1:0] w_digit_sel;
    wire w_scan_tick;

    // humidity / celsius는 센서가 주는 2자리 소수까지 그대로 사용한다.
    // 예: 25.56C -> 2556, 60.34% -> 6034
    assign w_temp_c_x100 = ({8'b00000000, i_temp_int} * 16'd100) + {8'b00000000, i_temp_frac};
    assign w_temp_scaled = ({6'b000000, i_temp_int} * 14'd100) + {6'b000000, i_temp_frac};
    assign w_humi_scaled = ({6'b000000, i_humi_int} * 14'd100) + {6'b000000, i_humi_frac};
    // fahrenheit는 최대 122.0F 범위라 3자리 정수 + 1자리 소수로 표현한다.
    // 예: 25.56C -> 78.0F -> 780
    assign w_temp_f_x100 = ((w_temp_c_x100 * 16'd9) / 16'd5) + 16'd3200;
    assign w_temp_fahrenheit_scaled = w_temp_f_x100 / 16'd10;

    assign w_selected_scaled = i_show_humi ? w_humi_scaled :
                               i_show_fahrenheit ? w_temp_fahrenheit_scaled :
                               w_temp_scaled;
    assign w_decimal_enable = i_show_fahrenheit ? (w_digit_sel == 2'b01) : (w_digit_sel == 2'b10);

    dht11_digit_splitter U_DIGIT_SPLIT (
        .digit_in(w_selected_scaled),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000)
    );

    dht11_mux_4x1 U_MUX_4X1 (
        .in0(w_digit_1),
        .in1(w_digit_10),
        .in2(w_digit_100),
        .in3(w_digit_1000),
        .sel(w_digit_sel),
        .out_mux(w_out_mux)
    );

    dht11_bcd U_BCD (
        .bin(w_out_mux),
        .i_decimal_enable(w_decimal_enable),
        .bcd_data(fnd_data)
    );

    dht11_clk_div_1khz #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .SCAN_HZ(SCAN_HZ)
    ) U_CLK_DIV_1KHZ (
        .clk(clk),
        .rst(rst),
        .o_scan_tick(w_scan_tick)
    );

    dht11_counter_4 U_COUNTER_4 (
        .clk(clk),
        .rst(rst),
        .i_scan_tick(w_scan_tick),
        .digit_sel(w_digit_sel)
    );

    dht11_decoder_2x4 U_DECODER_2x4 (
        .decoder_in(w_digit_sel),
        .fnd_com(fnd_com)
    );

endmodule

module dht11_clk_div_1khz #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer SCAN_HZ = 1000
) (
    input  clk,
    input  rst,
    output o_scan_tick
);

    localparam integer HALF_PERIOD_COUNT = CLK_FREQ_HZ / (SCAN_HZ * 2);
    localparam integer COUNTER_WIDTH = (HALF_PERIOD_COUNT <= 1) ? 1 : $clog2(
        HALF_PERIOD_COUNT
    );

    reg [COUNTER_WIDTH-1:0] counter_reg;
    reg scan_tick_reg;

    assign o_scan_tick = scan_tick_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= {COUNTER_WIDTH{1'b0}};
            scan_tick_reg <= 1'b0;
        end else begin
            scan_tick_reg <= 1'b0;
            if (counter_reg == HALF_PERIOD_COUNT - 1) begin
                counter_reg <= {COUNTER_WIDTH{1'b0}};
                scan_tick_reg <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1'b1;
            end
        end
    end

endmodule

module dht11_counter_4 (
    input clk,
    input rst,
    input i_scan_tick,
    output [1:0] digit_sel
);
    reg [1:0] counter_reg;

    assign digit_sel = counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
        end else if (i_scan_tick) begin
            counter_reg <= counter_reg + 1;
        end
    end

endmodule

module dht11_decoder_2x4 (
    input [1:0] decoder_in,
    output reg [3:0] fnd_com
);

    always @(*) begin
        case (decoder_in)
            2'b00:   fnd_com = 4'b1110;
            2'b01:   fnd_com = 4'b1101;
            2'b10:   fnd_com = 4'b1011;
            2'b11:   fnd_com = 4'b0111;
            default: fnd_com = 4'b1111;
        endcase
    end
endmodule

module dht11_digit_splitter (
    input  [13:0] digit_in,
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100,
    output [3:0] digit_1000
);
    assign digit_1 = digit_in % 10;
    assign digit_10 = (digit_in / 10) % 10;
    assign digit_100 = (digit_in / 100) % 10;
    assign digit_1000 = (digit_in / 1000) % 10;

endmodule

module dht11_mux_4x1 (
    input [3:0] in0,
    input [3:0] in1,
    input [3:0] in2,
    input [3:0] in3,
    input [1:0] sel,
    output [3:0] out_mux
);
    reg [3:0] out_reg;
    assign out_mux = out_reg;

    always @(*) begin
        case (sel)
            2'b00:   out_reg = in0;
            2'b01:   out_reg = in1;
            2'b10:   out_reg = in2;
            2'b11:   out_reg = in3;
            default: out_reg = 4'b0000;
        endcase
    end

endmodule

module dht11_bcd (
    input [3:0] bin,
    input i_decimal_enable,
    output reg [7:0] bcd_data
);

    always @(*) begin
        case (bin)
            4'b0000: bcd_data = 8'hC0;
            4'b0001: bcd_data = 8'hF9;
            4'b0010: bcd_data = 8'hA4;
            4'b0011: bcd_data = 8'hB0;
            4'b0100: bcd_data = 8'h99;
            4'b0101: bcd_data = 8'h92;
            4'b0110: bcd_data = 8'h82;
            4'b0111: bcd_data = 8'hF8;
            4'b1000: bcd_data = 8'h80;
            4'b1001: bcd_data = 8'h90;
            4'b1010: bcd_data = 8'h88;
            4'b1011: bcd_data = 8'h83;
            4'b1100: bcd_data = 8'hC6;
            4'b1101: bcd_data = 8'hA1;
            4'b1110: bcd_data = 8'h86;
            4'b1111: bcd_data = 8'h8E;
            default: bcd_data = 8'hFF;
        endcase

        // humidity / celsius는 2자리 소수, fahrenheit는 1자리 소수로 점등 위치를 바꾼다.
        if (i_decimal_enable) begin
            bcd_data[7] = 1'b0;
        end
    end

endmodule
