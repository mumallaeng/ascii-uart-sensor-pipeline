`timescale 1ns / 1ps

// Commit-1 top TB:
// verifies the top skeleton with only remote_input_unit integrated.
module tb_ascii_uart_sensor_pipeline;
    // 9600 baud bit period in ns for the UART command stimulus.
    localparam integer BIT_PERIOD_NS = 104166;

    reg clk;
    reg rst;
    reg btnU;
    reg btnD;
    reg btnL;
    reg btnR;
    reg btnC;
    reg [15:0] sw;
    reg rx;
    reg echo;
    wire dht11_io;
    wire tx;
    wire trig;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire [2:0] led;

    // Sticky flags summarize the important internal observations for the saved
    // WCFG: btnR path seen, status path seen, and unknown path never seen.
    reg seen_btnR;
    reg seen_status;
    reg seen_unknown_cmd;

    ascii_uart_sensor_pipeline DUT (
        .clk(clk),
        .rst(rst),
        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),
        .btnC(btnC),
        .sw(sw),
        .rx(rx),
        .echo(echo),
        .dht11_io(dht11_io),
        .tx(tx),
        .trig(trig),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .led(led)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst) begin
            seen_btnR <= 1'b0;
            seen_status <= 1'b0;
            seen_unknown_cmd <= 1'b0;
        end else begin
            // Observe the currently integrated direct child through top-level internal wires.
            if (DUT.w_cmd_btnR) seen_btnR <= 1'b1;
            if (DUT.w_cmd_status) seen_status <= 1'b1;
            if (DUT.w_unknown_cmd) seen_unknown_cmd <= 1'b1;
        end
    end

    // UART byte sender used by all command tasks below.
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

    // Scenario 1: "btnR\\r" should reach the top-level internal command wire.
    task send_text_btnR;
        begin
            send_uart_byte("b");
            send_uart_byte("t");
            send_uart_byte("n");
            send_uart_byte("R");
            send_uart_byte(8'h0D);
        end
    endtask

    // Scenario 2: "status\\r" should reach the top-level internal command wire.
    task send_text_status;
        begin
            send_uart_byte("s");
            send_uart_byte("t");
            send_uart_byte("a");
            send_uart_byte("t");
            send_uart_byte("u");
            send_uart_byte("s");
            send_uart_byte(8'h0D);
        end
    endtask

    initial begin
        // This top-level TB is intentionally limited to the current commit scope:
        // only remote_input_unit is connected inside the top module.
        // Unused local/sensor inputs stay quiet in this initial integration stage.
        clk = 1'b0;
        rst = 1'b1;
        btnU = 1'b0;
        btnD = 1'b0;
        btnL = 1'b0;
        btnR = 1'b0;
        btnC = 1'b0;
        sw = 16'h0000;
        rx = 1'b1;
        echo = 1'b0;
        seen_btnR = 1'b0;
        seen_status = 1'b0;
        seen_unknown_cmd = 1'b0;

        repeat (5) @(negedge clk);
        rst = 1'b0;

        // Check 0: unimplemented top outputs still stay at their safe defaults.
        if (tx !== 1'b1) $fatal(1, "tx default output mismatch");
        if (trig !== 1'b0) $fatal(1, "trig default output mismatch");
        if (fnd_com !== 4'b1111) $fatal(1, "fnd_com default output mismatch");
        if (fnd_data !== 8'hFF) $fatal(1, "fnd_data default output mismatch");
        if (led !== 3'b000) $fatal(1, "led default output mismatch");

        // Check 1: btnR command reaches top-level internal remote-input wiring.
        #(BIT_PERIOD_NS * 2);
        send_text_btnR();
        #(BIT_PERIOD_NS * 20);
        if (!seen_btnR) $fatal(1, "top internal btnR pulse missing");

        // Check 2: status command reaches top-level internal remote-input wiring.
        send_text_status();
        #(BIT_PERIOD_NS * 20);
        if (!seen_status) $fatal(1, "top internal status pulse missing");

        // Check 3: no unknown command should be reported in this test.
        if (seen_unknown_cmd) $fatal(1, "unexpected top unknown_cmd pulse");

        $display("tb_ascii_uart_sensor_pipeline: PASS");
        $finish;
    end
endmodule
