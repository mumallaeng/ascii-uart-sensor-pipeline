`timescale 1ns / 1ps

module ascii_sender (
    input        clk,
    input        rst,
    input        i_tx_full,
    input        i_btnS,
    input [ 1:0] sw,
    input [23:0] i_time_data,
    input [11:0] i_sensor_sr04,
    input [16:0] i_sensor_dht11,

    output [7:0] push_data,
    output       push
);

    parameter ZERO = 8'h30;
    parameter ONE = 8'h31;
    parameter TWO = 8'h32;
    parameter THREE = 8'h33;
    parameter FOUR = 8'h34;
    parameter FIVE = 8'h35;
    parameter SIX = 8'h36;
    parameter SEVEN = 8'h37;
    parameter EIGHT = 8'h38;
    parameter NINE = 8'h39;
    parameter COLON = 8'h3A;
    parameter EQUALS = 8'h3D;
    parameter CR = 8'h0D;
    parameter SMALL_S = 8'h73;
    parameter C = 8'h43;
    parameter DEG = 8'hB0;
    parameter CAP_S = 8'h53;
    parameter W = 8'h57;
    parameter T = 8'h54;
    parameter R = 8'h52;
    parameter D = 8'h44;
    parameter H = 8'h48;
    parameter SMALL_T = 8'h74;

    parameter IDLE = 0, FULL = 1, DATA_PUSH = 2;

    reg [7:0] setup_data_reg [0:20];
    reg [7:0] setup_data_next[0:20];
    reg [1:0] state_reg, state_next;
    reg [5:0] byte_count_reg, byte_count_next;
    reg [7:0] data_reg, data_next;
    reg push_reg, push_next;
    reg [5:0] count_data;

    assign push_data = data_reg;
    assign push = push_reg;
    integer i, j;

    /*
    출력 데이터 정의
    시계 :
    wt=00:00:00s \n
    13byte

    스탑워치
    sw=00:00:00s \n
    13byte

    초음파
    sr04=000cm \n
    11byte

    온습도
    dht \n
    temp=00도씨 \n
    humi=11
    21byte  

*/


    task sr042ascii;
        input [11:0] data;
        begin
            setup_data_next[0]  = CAP_S;
            setup_data_next[1]  = R;
            setup_data_next[2]  = ZERO;
            setup_data_next[3]  = FOUR;
            setup_data_next[4]  = EQUALS;

            setup_data_next[5]  = data[11:8] + 8'h30;
            setup_data_next[6]  = data[7:4] + 8'h30;
            setup_data_next[7]  = data[3:0] + 8'h30;

            setup_data_next[8]  = DEG;
            setup_data_next[9]  = C;
            setup_data_next[10] = CR;
        end
    endtask

    task dht2ascii;
        input [16:0] data;
        begin
            setup_data_next[0]  = CAP_S;
            setup_data_next[1]  = R;
            setup_data_next[2]  = ZERO;
            setup_data_next[3]  = FOUR;
            setup_data_next[4]  = EQUALS;

            setup_data_next[5]  = data[11:8] + 8'h30;
            setup_data_next[6]  = data[7:4] + 8'h30;
            setup_data_next[7]  = data[3:0] + 8'h30;

            setup_data_next[8]  = DEG;
            setup_data_next[9]  = C;
            setup_data_next[10] = CR;
        end
    endtask

    task data2ascii;
        input [23:0] data;
        input [1:0] sw;
        begin
            if (sw == 2'b00) begin  //시계
                setup_data_next[0] = W;
                setup_data_next[1] = T;
            end else begin
                setup_data_next[0] = CAP_S;
                setup_data_next[1] = W;
            end
            setup_data_next[2]  = EQUALS;
            setup_data_next[3]  = data[23:20] + 8'h30;
            setup_data_next[4]  = data[19:16] + 8'h30;
            setup_data_next[5]  = COLON;

            setup_data_next[6]  = data[15:12] + 8'h30;
            setup_data_next[7]  = data[11:8] + 8'h30;
            setup_data_next[8]  = COLON;

            setup_data_next[9]  = data[7:4] + 8'h30;
            setup_data_next[10] = data[3:0] + 8'h30;
            setup_data_next[11] = SMALL_S;
        end
    endtask



    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state_reg <= IDLE;
            byte_count_reg <= 0;
            data_reg <= 0;
            push_reg <= 0;
            for (i = 0; i < 16; i = i + 1) begin
                setup_data_reg[i] <= 8'b0;
            end
        end else begin
            state_reg <= state_next;
            byte_count_reg <= byte_count_next;
            data_reg <= data_next;
            push_reg <= push_next;
            for (i = 0; i < 16; i = i + 1) begin
                setup_data_reg[i] <= setup_data_next[i];
            end
        end
    end


    always @(*) begin

        state_next = state_reg;
        push_next = push_reg;
        byte_count_next = byte_count_reg;
        data_next = data_reg;
        for (j = 0; j < 16; j = j + 1) begin
            setup_data_next[j] = setup_data_reg[j];
        end

        case (sw)
            2'b00: begin
                data2ascii(i_time_data, sw);
                count_data = 4'd12;
            end
            2'b01: begin
                data2ascii(i_time_data, sw);
                count_data = 4'd12;
            end
            2'b10: begin
                sr042ascii(i_sensor_sr04);
                count_data = 4'd11;  /*초음파*/
            end
            2'b11: begin
                count_data = 4'd21;  /*온습도*/
            end

        endcase

        case (state_reg)
            IDLE: begin
                data_next = 0;
                push_next = 0;
                if (i_btnS && !i_tx_full) begin
                    state_next = DATA_PUSH;
                    byte_count_next = 0;
                    push_next = 1;

                end
            end
            DATA_PUSH: begin
                if (!i_tx_full) begin
                    byte_count_next = byte_count_reg + 1;
                    data_next = setup_data_reg[byte_count_reg];
                    if (byte_count_reg == count_data) begin
                        state_next = IDLE;
                        push_next  = 0;
                    end
                end else begin
                    push_next = 0;
                end

            end
            FULL: begin
                state_next = state_reg;
                push_next  = 0;
                if (i_tx_full) begin
                    state_next = DATA_PUSH;
                    push_next  = 1;
                end
            end
        endcase
    end





endmodule
