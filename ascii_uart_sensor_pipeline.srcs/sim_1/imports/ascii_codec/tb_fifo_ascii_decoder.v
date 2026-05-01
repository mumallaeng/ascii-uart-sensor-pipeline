`timescale 1ns / 1ps

module tb_fifo_ascii_decoder ();

    parameter DEPTH = 4;

    reg clk, rst, push;
    reg [7:0] push_data;

    wire w_pop;
    wire w_empty;
    wire [7:0] w_pop_data;

    wire btnC;
    wire btnR;
    wire btnL;
    wire btnU;
    wire btnD;
    wire btnS;

    parameter C = 8'h43;
    parameter R = 8'h52;
    parameter L = 8'h4C;
    parameter U = 8'h55;
    parameter D = 8'h44;
    parameter S = 8'h53;

    ascii_decoder U_AS_DE (
        .clk(clk),
        .rst(rst),
        .i_rx_empty(w_empty),
        .btn_data(w_pop_data),
        .pop(w_pop),
        .btnC(btnC),
        .btnR(btnR),
        .btnL(btnL),
        .btnU(btnU),
        .btnD(btnD),
        .btnS(btnS)
    );


    fifo #(
        .DEPTH(DEPTH),
        .BIT_WIDTH(($clog2(DEPTH) - 1))
    ) U_FIFO (
        .clk(clk),
        .rst(rst),
        .push_data(push_data),
        .push(push),
        .pop(w_pop),
        .pop_data(w_pop_data),
        .full(),
        .empty(w_empty)
    );

    always #5 clk = ~clk;



    initial begin
        clk = 0;
        rst = 1;
        push_data = 0;
        push = 0;

        //reset
        #10;
        rst = 0;
        @(posedge clk);
        #1;
        // push only to occurrupt
        push = 1;

        push_data = C;
        #10;
        push_data = R;
        #10;
        push_data = L;
        #10;
        push_data = U;
        #10;
        push_data = D;
        #10;
        push_data = S;
        #10;

        push = 0;



        #100;
        $stop;

    end



endmodule
