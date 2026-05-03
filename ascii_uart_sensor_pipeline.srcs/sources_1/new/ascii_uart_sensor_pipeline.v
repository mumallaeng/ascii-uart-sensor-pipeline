`timescale 1ns / 1ps

module ascii_uart_sensor_pipeline (
    input clk,
    input rst,
    input btnU,
    input btnD,
    input btnL,
    input btnR,
    input btnC,
    input [15:0] sw,
    input rx,
    input echo,
    inout dht11_io,
    output tx,
    output trig,
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output [2:0] led
);

    // Top-level integration skeleton.
    // Child modules are connected commit-by-commit as each direct child is implemented.

    assign tx = 1'b1;
    assign trig = 1'b0;
    assign fnd_com = 4'b1111;
    assign fnd_data = 8'hFF;
    assign led = 3'b000;

endmodule
