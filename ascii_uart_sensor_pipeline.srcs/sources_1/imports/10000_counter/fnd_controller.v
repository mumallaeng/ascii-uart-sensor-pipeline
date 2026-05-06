`timescale 1ns / 1ps

module fnd_controller #(
    parameter MAIN_CLK_100MHZ = 100_000_000,
    parameter SCAN_HZ         = 1000,
    parameter MSEC_WIDTH      = 7,
    parameter SEC_WIDTH       = 6,
    parameter MIN_WIDTH       = 6,
    parameter HOUR_WIDTH      = 5
) (
    input clk,
    input rst,
    input i_display_mode,  // sw[0] , 0 : msec_sec, 1 : mon_hour
    input i_show_center_dot,
    input [2:0] i_set_index,  // setting index
    input [MSEC_WIDTH  -1:0] msec,
    input [SEC_WIDTH   -1:0] sec,
    input [MIN_WIDTH   -1:0] min,
    input [HOUR_WIDTH  -1:0] hour,
    output [3:0] fnd_com,
    output [7:0] fnd_data
);

    wire [3:0] w_out_mux;
    wire [3:0] w_out_mux_msec_sec;
    wire [3:0] w_out_mux_min_hour;
    wire [3:0] w_msec_digit_1, w_msec_digit_10;
    wire [3:0] w_sec_digit_1, w_sec_digit_10;
    wire [3:0] w_min_digit_1, w_min_digit_10;
    wire [3:0] w_hour_digit_1, w_hour_digit_10;
    wire [ 2:0] w_digit_sel;
    wire        w_1khz;
    localparam integer BLINK_HALF_PERIOD = (MAIN_CLK_100MHZ / 2 <= 1) ? 1 : (MAIN_CLK_100MHZ / 2);
    localparam integer BLINK_COUNTER_WIDTH = (BLINK_HALF_PERIOD <= 1) ? 1 : $clog2(BLINK_HALF_PERIOD);

    reg [BLINK_COUNTER_WIDTH-1:0] blink_counter_reg;
    reg                           half_sec_sig;
    wire [3:0]  w_msec_digit_1_disp, w_msec_digit_10_disp;
    wire [3:0]  w_sec_digit_1_disp, w_sec_digit_10_disp;
    wire [3:0]  w_min_digit_1_disp, w_min_digit_10_disp;
    wire [3:0]  w_hour_digit_1_disp, w_hour_digit_10_disp;

    reg blink_msec, blink_sec, blink_min, blink_hour;

    assign w_msec_digit_1_disp  = blink_msec ? 4'hf : w_msec_digit_1;
    assign w_msec_digit_10_disp = blink_msec ? 4'hf : w_msec_digit_10;
    assign w_sec_digit_1_disp   = blink_sec  ? 4'hf : w_sec_digit_1;
    assign w_sec_digit_10_disp  = blink_sec  ? 4'hf : w_sec_digit_10;
    assign w_min_digit_1_disp   = blink_min  ? 4'hf : w_min_digit_1;
    assign w_min_digit_10_disp  = blink_min  ? 4'hf : w_min_digit_10;
    assign w_hour_digit_1_disp  = blink_hour ? 4'hf : w_hour_digit_1;
    assign w_hour_digit_10_disp = blink_hour ? 4'hf : w_hour_digit_10;

    always @(posedge clk or posedge rst) begin
        if (rst) begin  // reset이면 blink 위상 초기화
            blink_counter_reg <= {BLINK_COUNTER_WIDTH{1'b0}};
            half_sec_sig      <= 1'b0;
        end else if (blink_counter_reg == BLINK_HALF_PERIOD - 1) begin
            blink_counter_reg <= {BLINK_COUNTER_WIDTH{1'b0}};
            half_sec_sig      <= ~half_sec_sig;  // 0.5초마다 blink 위상 토글
        end else begin
            blink_counter_reg <= blink_counter_reg + 1'b1;
        end
    end

    always @(*) begin
        blink_msec = 1'b0;
        blink_sec  = 1'b0;
        blink_min  = 1'b0;
        blink_hour = 1'b0;

        // set 모드에서는 현재 선택 단위만 half_sec_sig 기준으로 깜빡이게 함
        if (i_set_index != 3'b111 && half_sec_sig) begin
            case (i_set_index[1:0])
                2'b00:   blink_hour = 1'b1;
                2'b01:   blink_min  = 1'b1;
                2'b10:   blink_sec  = 1'b1;
                2'b11:   blink_msec = 1'b1;
                default: begin
                    blink_msec = 1'b0;
                end
            endcase
        end
    end

    //digit split
    digit_splitter #(
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_MSEC_DS (
        .digit_in(msec),  //관련된 입력 14bit로
        .digit_1(w_msec_digit_1),
        .digit_10(w_msec_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(SEC_WIDTH)
    ) U_SEC_DS (
        .digit_in(sec),  //관련된 입력 14bit로
        .digit_1(w_sec_digit_1),
        .digit_10(w_sec_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(MIN_WIDTH)
    ) U_MIN_DS (
        .digit_in(min),  //관련된 입력 14bit로
        .digit_1(w_min_digit_1),
        .digit_10(w_min_digit_10)
    );

    digit_splitter #(
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_HOUR_DS (
        .digit_in(hour),  //관련된 입력 14bit로
        .digit_1(w_hour_digit_1),
        .digit_10(w_hour_digit_10)
    );

    mux_8x1 U_MUX_MSEC_SEC (
        .in0    (w_msec_digit_1_disp),     // digit 1
        .in1    (w_msec_digit_10_disp),    // digit 10
        .in2    (w_sec_digit_1_disp),      // digit 100
        .in3    (w_sec_digit_10_disp),     // digit 1000
        .in4    (4'hf),               // right-end dot는 사용하지 않음
        .in5    (4'hf),               // digit 10
        .in6    (i_show_center_dot ? 4'he : 4'hf), // 가운데 점은 watch에서만 켬
        .in7    (4'hf),               // digit 1000
        .sel    (w_digit_sel),        // to select input
        .out_mux(w_out_mux_msec_sec)
    );

    mux_8x1 U_MUX_MIN_HOUR (
        .in0    (w_min_digit_1_disp),      // digit 1
        .in1    (w_min_digit_10_disp),     // digit 10
        .in2    (w_hour_digit_1_disp),     // digit 100
        .in3    (w_hour_digit_10_disp),    // digit 1000
        .in4    (4'hf),               // right-end dot는 사용하지 않음
        .in5    (4'hf),
        .in6    (i_show_center_dot ? 4'he : 4'hf), // 가운데 점은 watch에서만 켬
        .in7    (4'hf),
        .sel    (w_digit_sel),        // to select input
        .out_mux(w_out_mux_min_hour)
    );

    mux_2x1 U_MUX_2X1 (
        .in0(w_out_mux_msec_sec),
        .in1(w_out_mux_min_hour),
        .sel(i_display_mode),
        .out_mux(w_out_mux)
    );

    bcd U_BCD (
        .bin     (w_out_mux),
        .bcd_data(fnd_data)
    );


    clk_div_1khz #(
        .MAIN_CLK_100MHZ(MAIN_CLK_100MHZ),
        .SCAN_HZ(SCAN_HZ)
    ) U_CLK_DIV_1KHZ (
        .clk(clk),
        .rst(rst),
        .o_1khz(w_1khz)
    );

    counter_8 U_COUNTER_8 (
        .clk(w_1khz),
        .rst(rst),
        .digit_sel(w_digit_sel)
    );


    decoder_2x4 U_DECODER_2x4 (
        .decoder_in(w_digit_sel[1:0]),
        .fnd_com(fnd_com)
    );

endmodule


module clk_div_1khz #(
    parameter integer MAIN_CLK_100MHZ = 100_000_000,
    parameter integer SCAN_HZ = 1000
) (
    input  clk,
    input  rst,
    output o_1khz
);

    localparam integer HALF_PERIOD_COUNT = MAIN_CLK_100MHZ / (SCAN_HZ * 2);
    localparam integer COUNTER_WIDTH = (HALF_PERIOD_COUNT <= 1) ? 1 : $clog2(
        HALF_PERIOD_COUNT
    );

    reg [COUNTER_WIDTH-1:0] counter_reg;
    reg o_1khz_reg;

    assign o_1khz = o_1khz_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= {COUNTER_WIDTH{1'b0}};
            o_1khz_reg  <= 1'b0;
        end else begin
            if (counter_reg == HALF_PERIOD_COUNT - 1) begin
                counter_reg <= {COUNTER_WIDTH{1'b0}};
                o_1khz_reg  <= ~o_1khz_reg;
            end else begin
                counter_reg <= counter_reg + 1'b1;
            end
        end
    end

endmodule

module counter_8 (
    input clk,
    input rst,
    output [2:0] digit_sel
);
    reg [2:0] counter_reg;

    assign digit_sel = counter_reg;  // 4가지 경우

    always @(posedge clk, posedge rst) begin //clk 신호의 상승엣지가 발생할때마다 begin end 구현해라
        if (rst) begin
            counter_reg <= 0;  // 0 초기화 <= 0
        end else begin
            counter_reg <= counter_reg + 1;
        end
    end

endmodule



module decoder_2x4 (
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


module digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input  [BIT_WIDTH   -1 : 0] digit_in,  //관련된 입력 14bit로
    output [             3 : 0] digit_1,
    output [             3 : 0] digit_10
);
    assign digit_1  = digit_in % 10;  // digit 1
    assign digit_10 = (digit_in / 10) % 10;  // digit 10

endmodule

module mux_4x1 (
    input [3:0] in0,  // digit 1
    input [3:0] in1,  // digit 10
    input [3:0] in2,  // digit 100
    input [3:0] in3,  // digit 1000
    input [1:0] sel,  // to select input
    output [3:0] out_mux
);
    reg [3:0] out_reg;
    assign out_mux = out_reg;

    // mux, (*) all input : sensitivity list
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



module mux_8x1 (
    input [3:0] in0,  // digit 1
    input [3:0] in1,  // digit 10
    input [3:0] in2,  // digit 100
    input [3:0] in3,  // digit 1000
    input [3:0] in4,  //
    input [3:0] in5,  //
    input [3:0] in6,  // 
    input [3:0] in7,  //
    input [2:0] sel,  // to select input
    output [3:0] out_mux
);
    reg [3:0] out_reg;
    assign out_mux = out_reg;

    // mux, (*) all input : sensitivity list
    always @(*) begin
        case (sel)
            3'b000:  out_reg = in0;
            3'b001:  out_reg = in1;
            3'b010:  out_reg = in2;
            3'b011:  out_reg = in3;
            3'b100:  out_reg = in4;
            3'b101:  out_reg = in5;
            3'b110:  out_reg = in6;
            3'b111:  out_reg = in7;
            default: out_reg = 4'b0000;
        endcase
    end
endmodule


module bcd (
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
            4'b1110: bcd_data = 8'h7F;
            4'b1111: bcd_data = 8'hFF;
            default: bcd_data = 8'hFF;
        endcase
    end

endmodule

module mux_2x1 (
    input [3:0] in0,
    input [3:0] in1,
    input sel,
    output [3:0] out_mux
);

    assign out_mux = (sel) ? in1 : in0;  // in0 : msec_sec, min_hour

endmodule

module comparator (
    input      [6:0] msec,
    output reg       half_sec_sig
);

    always @(*) begin
        if (msec < 50) half_sec_sig = 0;
        else half_sec_sig = 1;
    end
endmodule
