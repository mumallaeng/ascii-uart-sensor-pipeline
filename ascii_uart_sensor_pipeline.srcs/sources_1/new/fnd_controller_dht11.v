`timescale 1ns / 1ps

module dht11_fnd_controller #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer SCAN_HZ = 1000
) (
    input clk,
    input rst,
    // input sw0, // sw1 sw0 = 11일 때 온습도모드
    // input sw1,
    input sw15, // sw15이 0일 때 온도, 1일 때 습도
    input [7:0] tm,
    input [7:0] hm,
    // input [13:0] fnd_in,
    output [3:0] fnd_com,
    output [7:0] fnd_data
);

    wire [3:0] w_out_mux_tm, w_out_mux_hm, w_out_mux;
    wire [3:0] w_tm_digit_1, w_tm_digit_10, w_tm_digit_100, w_tm_digit_1000;
    wire [3:0] w_hm_digit_1, w_hm_digit_10, w_hm_digit_100, w_hm_digit_1000;
    wire [1:0] w_digit_sel;
    wire w_scan_tick;

    dht11_digit_splitter U_tm_DIGIT_SPLIT (
        .digit_in(tm),
        .digit_1(w_tm_digit_1),
        .digit_10(w_tm_digit_10),
        .digit_100(w_tm_digit_100),
        .digit_1000(w_tm_digit_1000)
    );

    dht11_digit_splitter U_hm_DIGIT_SPLIT (
        .digit_in(hm),
        .digit_1(w_hm_digit_1),
        .digit_10(w_hm_digit_10),
        .digit_100(w_hm_digit_100),
        .digit_1000(w_hm_digit_1000)
    );

    dht11_mux_4x1 U_MUX_4X1_TM (
        .in0(w_tm_digit_1),  // digit 1
        .in1(w_tm_digit_10),  // digit 10
        .in2(w_tm_digit_100), // digit 100
        .in3(w_tm_digit_1000), // digit 1000
        .sel(w_digit_sel),  // to select input
        .out_mux(w_out_mux_tm)
    );

    dht11_mux_4x1 U_MUX_4X1_HM (
        .in0(w_hm_digit_1),  // digit 1
        .in1(w_hm_digit_10),  // digit 10
        .in2(w_hm_digit_100), // digit 100
        .in3(w_hm_digit_1000), // digit 1000
        .sel(w_digit_sel),  // to select input
        .out_mux(w_out_mux_hm)
    );

    dht11_mux_2x1 U_MUX_2X1 (
    .in0(w_out_mux_tm),  // digit 1
    .in1(w_out_mux_hm),  // digit 10
    .sel(sw15),  // to select input
    .out_mux(w_out_mux)
);


    dht11_bcd U_BCD (
        .bin(w_out_mux),
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

    assign digit_sel = counter_reg;  // 4가지 경우

    always @(posedge clk, posedge rst) begin //clk 신호의 상승엣지가 발생할때마다 begin end 구현해라
        if (rst) begin
            counter_reg <= 0;  // 0 초기화 <= 0
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
    input  [ 7:0] digit_in,   //관련된 입력 14bit로
    output [ 3:0] digit_1,
    output [ 3:0] digit_10,
    output [ 3:0] digit_100,
    output [ 3:0] digit_1000
);
    assign digit_1 = digit_in % 10;  // digit 1
    assign digit_10 = (digit_in / 10) % 10;  // digit 10
    assign digit_100 = (digit_in / 100) % 10;  // digit 100
    assign digit_1000 = (digit_in / 1000) % 10;  // digit 1000



endmodule

module dht11_mux_4x1 (
    input [3:0] in0,  // digit 1
    input [3:0] in1,  // digit 10
    input [3:0] in2,  // digit 100
    input [3:0] in3,  // digit 1000
    input [1:0] sel,  // to select input
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

module dht11_mux_2x1 (
    input [3:0] in0,  // digit 1
    input [3:0] in1,  // digit 10
    input sel,  // to select input
    output [3:0] out_mux
);
    reg [3:0] out_reg;
    assign out_mux = out_reg;

    always @(*) begin
        case (sel)
            1'b0:   out_reg = in0;
            1'b1:   out_reg = in1;
            default: out_reg = 8'b0000_0000;
        endcase
    end

endmodule


module dht11_bcd (
    input [3:0] bin,
    output reg [7:0] bcd_data
);

    always @(bin) begin
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
    end

endmodule
