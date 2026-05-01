`timescale 1ns / 1ps


module stopwatch_fsm (
    input      clk,
    input      rst,
    input      i_btnD,
    input      i_btnL,
    input      i_btnU,
    input      i_sw0,
    output reg o_runstop,
    output reg o_clear,
    output     o_updown
);

    localparam [1:0] STOP = 2'b00;
    localparam [1:0] UPDOWN = 2'b01;
    localparam [1:0] CLEAR = 2'b10;
    localparam [1:0] RUN = 2'b11;

    reg updown_state;
    reg [1:0] current_state, next_state;
    reg [1:0] previous_state;

    assign o_updown = updown_state;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            current_state  <= STOP;
            previous_state <= STOP;
            updown_state   <= 0;
        end else begin
            current_state  <= next_state;
            previous_state <= current_state;
            if (current_state == UPDOWN) updown_state <= ~updown_state;
            else updown_state <= updown_state;
        end
    end

    always @(*) begin
        next_state = current_state;
        if (i_sw0) begin
            case (current_state)
                STOP:
                if (i_btnD) next_state = RUN;
                else if (i_btnL) next_state = CLEAR;
                else if (i_btnU) next_state = UPDOWN;

                RUN:
                if (i_btnD) next_state = STOP;
                else if (i_btnL) next_state = CLEAR;
                else if (i_btnU) next_state = UPDOWN;


                UPDOWN:
                if (previous_state == STOP) next_state = STOP;
                else if (previous_state == RUN) next_state = RUN;

                CLEAR:
                if (previous_state == STOP) next_state = STOP;
                else if (previous_state == RUN) next_state = RUN;
            endcase
        end
    end

    always @(*) begin
        o_runstop = 0;
        o_clear   = 0;
        case (current_state)
            STOP: begin
                o_runstop = 0;
                o_clear   = 0;
            end
            RUN: begin
                o_runstop = 1;
            end
            CLEAR: begin
                o_clear = 1;
            end
        endcase
    end


endmodule
