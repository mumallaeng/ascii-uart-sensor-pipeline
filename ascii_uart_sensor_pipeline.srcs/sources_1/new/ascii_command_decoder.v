`timescale 1ns / 1ps

module ascii_command_decoder (
    input        clk,
    input        rst,
    input        i_rx_empty,
    input  [7:0] i_rx_data,
    output reg   pop,
    output reg   cmdC,
    output reg   cmdR,
    output reg   cmdL,
    output reg   cmdU,
    output reg   cmdD,
    output reg   cmdS
);

    localparam IDLE     = 1'b0;
    localparam DATA_POP = 1'b1;

    reg state_reg, state_next;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg <= IDLE;
        end else begin
            state_reg <= state_next;
        end
    end

    always @(*) begin
        state_next = state_reg;

        pop  = 1'b0;
        cmdC = 1'b0;
        cmdR = 1'b0;
        cmdL = 1'b0;
        cmdU = 1'b0;
        cmdD = 1'b0;
        cmdS = 1'b0;

        case (state_reg)
            IDLE: begin
                if (!i_rx_empty) begin
                    state_next = DATA_POP;
                end
            end

            DATA_POP: begin
                pop = 1'b1;
                state_next = IDLE;

                case (i_rx_data)
                    8'h43, 8'h63: cmdC = 1'b1;  // C / c
                    8'h52, 8'h72: cmdR = 1'b1;  // R / r
                    8'h4C, 8'h6C: cmdL = 1'b1;  // L / l
                    8'h55, 8'h75: cmdU = 1'b1;  // U / u
                    8'h44, 8'h64: cmdD = 1'b1;  // D / d
                    8'h53, 8'h73: cmdS = 1'b1;  // S / s
                    default: begin
                    end
                endcase
            end

            default: begin
                state_next = IDLE;
            end
        endcase
    end

endmodule
