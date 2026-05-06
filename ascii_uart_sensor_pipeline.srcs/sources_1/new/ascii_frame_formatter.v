`timescale 1ns / 1ps

module ascii_frame_formatter #(
    parameter integer FRAME_MAX_BYTES = 24
) (
    input  [1:0] i_page,
    input [23:0] i_time_data,
    input [11:0] i_sr04_data,
    input  [7:0] i_dht_temp,
    input  [7:0] i_dht_humi,
    input        i_dht_valid,
    output reg [FRAME_MAX_BYTES*8-1:0] o_frame_data,
    output reg [5:0]                   o_frame_len
);

    localparam [1:0] PAGE_WATCH     = 2'b00;
    localparam [1:0] PAGE_STOPWATCH = 2'b01;
    localparam [1:0] PAGE_SR04      = 2'b10;
    localparam [1:0] PAGE_DHT11     = 2'b11;

    localparam [7:0] ASCII_ZERO   = 8'h30;
    localparam [7:0] ASCII_COLON  = 8'h3A;
    localparam [7:0] ASCII_EQUALS = 8'h3D;
    localparam [7:0] ASCII_COMMA  = 8'h2C;
    localparam [7:0] ASCII_PERCENT = 8'h25;
    localparam [7:0] ASCII_CR     = 8'h0D;
    localparam [7:0] ASCII_S      = 8'h53;
    localparam [7:0] ASCII_W      = 8'h57;
    localparam [7:0] ASCII_R      = 8'h52;
    localparam [7:0] ASCII_O      = 8'h4F;
    localparam [7:0] ASCII_D      = 8'h44;
    localparam [7:0] ASCII_H      = 8'h48;
    localparam [7:0] ASCII_T      = 8'h54;
    localparam [7:0] ASCII_C      = 8'h43;
    localparam [7:0] ASCII_M      = 8'h4D;
    localparam [7:0] ASCII_I      = 8'h49;
    localparam [7:0] ASCII_N      = 8'h4E;
    localparam [7:0] ASCII_V      = 8'h56;
    localparam [7:0] ASCII_A      = 8'h41;
    localparam [7:0] ASCII_L      = 8'h4C;
    localparam [7:0] ASCII_SMALL_S = 8'h73;
    localparam [7:0] ASCII_SMALL_C = 8'h63;
    localparam [7:0] ASCII_SMALL_M = 8'h6D;

    wire [4:0] w_time_hour = i_time_data[23:19];
    wire [5:0] w_time_min  = i_time_data[18:13];
    wire [5:0] w_time_sec  = i_time_data[12:7];

    integer i;

    function [7:0] digit_to_ascii;
        input [3:0] digit;
        begin
            digit_to_ascii = ASCII_ZERO + digit;
        end
    endfunction

    function [7:0] dec_tens_ascii;
        input [7:0] value;
        begin
            dec_tens_ascii = ASCII_ZERO + ((value / 10) % 10);
        end
    endfunction

    function [7:0] dec_ones_ascii;
        input [7:0] value;
        begin
            dec_ones_ascii = ASCII_ZERO + (value % 10);
        end
    endfunction

    function [7:0] dec_hundreds_ascii;
        input [11:0] value;
        begin
            dec_hundreds_ascii = ASCII_ZERO + ((value / 100) % 10);
        end
    endfunction

    task clear_frame;
        begin
            o_frame_data = {(FRAME_MAX_BYTES*8){1'b0}};
            o_frame_len  = 6'd0;
        end
    endtask

    task set_byte;
        input integer index;
        input [7:0] value;
        begin
            o_frame_data[(index*8) +: 8] = value;
        end
    endtask

    task build_time_frame;
        input [7:0] prefix0;
        input [7:0] prefix1;
        input [4:0] hour;
        input [5:0] min;
        input [5:0] sec;
        begin
            set_byte(0,  prefix0);
            set_byte(1,  prefix1);
            set_byte(2,  ASCII_EQUALS);
            set_byte(3,  dec_tens_ascii({3'b000, hour}));
            set_byte(4,  dec_ones_ascii({3'b000, hour}));
            set_byte(5,  ASCII_COLON);
            set_byte(6,  dec_tens_ascii({2'b00, min}));
            set_byte(7,  dec_ones_ascii({2'b00, min}));
            set_byte(8,  ASCII_COLON);
            set_byte(9,  dec_tens_ascii({2'b00, sec}));
            set_byte(10, dec_ones_ascii({2'b00, sec}));
            set_byte(11, ASCII_SMALL_S);
            set_byte(12, ASCII_CR);
            o_frame_len = 6'd13;
        end
    endtask

    task build_sr04_frame;
        input [11:0] distance;
        begin
            set_byte(0,  ASCII_S);
            set_byte(1,  ASCII_R);
            set_byte(2,  ASCII_ZERO);
            set_byte(3,  8'h34);
            set_byte(4,  ASCII_EQUALS);
            set_byte(5,  dec_hundreds_ascii(distance));
            set_byte(6,  dec_tens_ascii(distance[7:0]));
            set_byte(7,  dec_ones_ascii(distance[7:0]));
            set_byte(8,  ASCII_SMALL_C);
            set_byte(9,  ASCII_SMALL_M);
            set_byte(10, ASCII_CR);
            o_frame_len = 6'd11;
        end
    endtask

    task build_dht11_frame;
        input [7:0] temp;
        input [7:0] humi;
        input       valid;
        begin
            if (!valid) begin
                set_byte(0,  ASCII_D);
                set_byte(1,  ASCII_H);
                set_byte(2,  ASCII_T);
                set_byte(3,  8'h31);
                set_byte(4,  8'h31);
                set_byte(5,  ASCII_EQUALS);
                set_byte(6,  ASCII_I);
                set_byte(7,  ASCII_N);
                set_byte(8,  ASCII_V);
                set_byte(9,  ASCII_A);
                set_byte(10, ASCII_L);
                set_byte(11, ASCII_I);
                set_byte(12, ASCII_D);
                set_byte(13, ASCII_CR);
                o_frame_len = 6'd14;
            end else begin
                set_byte(0,  ASCII_D);
                set_byte(1,  ASCII_H);
                set_byte(2,  ASCII_T);
                set_byte(3,  8'h31);
                set_byte(4,  8'h31);
                set_byte(5,  ASCII_EQUALS);
                set_byte(6,  ASCII_T);
                set_byte(7,  dec_tens_ascii(temp));
                set_byte(8,  dec_ones_ascii(temp));
                set_byte(9,  ASCII_C);
                set_byte(10, ASCII_COMMA);
                set_byte(11, ASCII_H);
                set_byte(12, dec_tens_ascii(humi));
                set_byte(13, dec_ones_ascii(humi));
                set_byte(14, ASCII_PERCENT);
                set_byte(15, ASCII_CR);
                o_frame_len = 6'd16;
            end
        end
    endtask

    always @(*) begin
        clear_frame();

        case (i_page)
            PAGE_WATCH: begin
                build_time_frame(ASCII_W, ASCII_T, w_time_hour, w_time_min, w_time_sec);
            end

            PAGE_STOPWATCH: begin
                build_time_frame(ASCII_S, ASCII_W, w_time_hour, w_time_min, w_time_sec);
            end

            PAGE_SR04: begin
                build_sr04_frame(i_sr04_data);
            end

            PAGE_DHT11: begin
                build_dht11_frame(i_dht_temp, i_dht_humi, i_dht_valid);
            end

            default: begin
                clear_frame();
            end
        endcase
    end

endmodule
