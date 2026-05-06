`timescale 1ns / 1ps

module tb_remote_input_unit;
    localparam integer BIT_PERIOD_NS = 104166;

    reg clk;
    reg rst;
    reg rx;

    wire cmd_btnR;
    wire cmd_btnR_hold;
    wire cmd_btnL;
    wire cmd_btnU;
    wire cmd_btnD;
    wire cmd_snap;
    wire cmd_clr;
    wire unknown_cmd;

    reg seen_btnR;
    reg seen_snap;

    remote_input_unit DUT (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .cmd_btnR(cmd_btnR),
        .cmd_btnR_hold(cmd_btnR_hold),
        .cmd_btnL(cmd_btnL),
        .cmd_btnU(cmd_btnU),
        .cmd_btnD(cmd_btnD),
        .cmd_snap(cmd_snap),
        .cmd_clr(cmd_clr),
        .unknown_cmd(unknown_cmd)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst) begin
            seen_btnR <= 1'b0;
            seen_snap <= 1'b0;
        end else begin
            if (cmd_btnR) seen_btnR <= 1'b1;
            if (cmd_snap) seen_snap <= 1'b1;
        end
    end

    task send_uart_byte;
        input [7:0] data_byte;
        integer bit_idx;
        begin
            rx = 1'b0;
            #(BIT_PERIOD_NS);
            for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                rx = data_byte[bit_idx];
                #(BIT_PERIOD_NS);
            end
            rx = 1'b1;
            #(BIT_PERIOD_NS);
        end
    endtask

    task send_text_btnR;
        begin
            send_uart_byte("b");
            send_uart_byte("t");
            send_uart_byte("n");
            send_uart_byte("R");
            send_uart_byte(8'h0D);
        end
    endtask

    task send_text_snap;
        begin
            send_uart_byte("s");
            send_uart_byte("n");
            send_uart_byte("a");
            send_uart_byte("p");
            send_uart_byte(8'h0D);
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        rx = 1'b1;
        seen_btnR = 1'b0;
        seen_snap = 1'b0;

        repeat (5) @(negedge clk);
        rst = 1'b0;

        #(BIT_PERIOD_NS * 2);
        send_text_btnR();
        #(BIT_PERIOD_NS * 20);
        if (!seen_btnR) $fatal(1, "cmd_btnR pulse missing");

        send_text_snap();
        #(BIT_PERIOD_NS * 20);
        if (!seen_snap) $fatal(1, "cmd_snap pulse missing");

        if (unknown_cmd) $fatal(1, "unexpected unknown_cmd pulse");

        $display("tb_remote_input_unit: PASS");
        $finish;
    end
endmodule
