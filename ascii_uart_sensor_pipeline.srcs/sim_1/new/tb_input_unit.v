`timescale 1ns / 1ps

`include "ascii_uart_sensor_pipeline_defs.vh"

// INPUT-stage smoke TB:
// runs minimal checks for remote_input_unit, input_conditioning,
// and context_manager in one sequence.
module tb_input_unit;
    localparam integer BIT_PERIOD_NS = 104166;

    reg clk;
    reg rst;
    reg btnU;
    reg btnD;
    reg btnL;
    reg btnR;
    reg btnC;
    reg [1:0] sw_context;
    reg sw15;
    reg rx;

    wire o_btnU;
    wire o_btnD;
    wire o_btnL;
    wire o_btnR;
    wire o_btnC;
    wire o_btnU_hold;
    wire o_btnD_hold;
    wire o_btnL_hold;
    wire o_btnR_hold;
    wire o_sw0;
    wire o_sw15;

    wire [`CTX_W-1:0] current_context;
    wire context_change_pulse;
    wire watch_12h;
    wire dht11_show_humi;

    wire cmd_btnR;
    wire cmd_btnR_hold;
    wire cmd_btnL;
    wire cmd_btnU;
    wire cmd_btnD;
    wire cmd_status;
    wire cmd_clr;
    wire unknown_cmd;

    reg seen_local_btnR;
    reg seen_local_btnR_hold;
    reg seen_local_btnC;
    reg seen_context_change;
    reg seen_remote_btnR;
    reg seen_remote_status;
    reg seen_unknown_cmd;

    // Fast TB parameters:
    // - SAMPLE_COUNT = CLK_FREQ_HZ / BD_HZ = 10 clocks
    // - HOLD_TIME_BTN_R is intentionally larger than one debounce-high plus
    //   one debounce-low window so that both short and hold can be tested.
    input_conditioning #(
        .CLK_FREQ_HZ(1000),
        .BD_HZ(100),
        .HOLD_TIME_BTN_R(140),
        .HOLD_TIME_BTN_UD(40),
        .HOLD_TIME_BTN_L(40),
        .HOLD_TIME_BTN_C(1000),
        .REPEAT_TIME_BTN_UD(10)
    ) DUT_INPUT_CONDITIONING (
        .clk(clk),
        .rst(rst),
        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),
        .btnC(btnC),
        .sw0(sw_context[0]),
        .sw15(sw15),
        .o_btnU(o_btnU),
        .o_btnD(o_btnD),
        .o_btnL(o_btnL),
        .o_btnR(o_btnR),
        .o_btnC(o_btnC),
        .o_btnU_hold(o_btnU_hold),
        .o_btnD_hold(o_btnD_hold),
        .o_btnL_hold(o_btnL_hold),
        .o_btnR_hold(o_btnR_hold),
        .o_sw0(o_sw0),
        .o_sw15(o_sw15)
    );

    // This revision intentionally keeps raw switch handling here so that
    // synchronizer follow-up can be observed later in top-level verification.
    context_manager DUT_CONTEXT_MANAGER (
        .clk(clk),
        .rst(rst),
        .i_sw_context(sw_context),
        .i_sw15(sw15),
        .o_current_context(current_context),
        .o_context_change_pulse(context_change_pulse),
        .o_watch_12h(watch_12h),
        .o_dht11_show_humi(dht11_show_humi)
    );

    remote_input_unit DUT_REMOTE_INPUT_UNIT (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .cmd_btnR(cmd_btnR),
        .cmd_btnR_hold(cmd_btnR_hold),
        .cmd_btnL(cmd_btnL),
        .cmd_btnU(cmd_btnU),
        .cmd_btnD(cmd_btnD),
        .cmd_status(cmd_status),
        .cmd_clr(cmd_clr),
        .unknown_cmd(unknown_cmd)
    );

    always #5 clk = ~clk;

    always @(posedge rst or posedge o_btnR) begin
        if (rst) seen_local_btnR <= 1'b0;
        else seen_local_btnR <= 1'b1;
    end

    always @(posedge rst or posedge o_btnR_hold) begin
        if (rst) seen_local_btnR_hold <= 1'b0;
        else seen_local_btnR_hold <= 1'b1;
    end

    always @(posedge rst or posedge o_btnC) begin
        if (rst) seen_local_btnC <= 1'b0;
        else seen_local_btnC <= 1'b1;
    end

    always @(posedge rst or posedge context_change_pulse) begin
        if (rst) seen_context_change <= 1'b0;
        else seen_context_change <= 1'b1;
    end

    always @(posedge rst or posedge cmd_btnR) begin
        if (rst) seen_remote_btnR <= 1'b0;
        else seen_remote_btnR <= 1'b1;
    end

    always @(posedge rst or posedge cmd_status) begin
        if (rst) seen_remote_status <= 1'b0;
        else seen_remote_status <= 1'b1;
    end

    always @(posedge rst or posedge unknown_cmd) begin
        if (rst) seen_unknown_cmd <= 1'b0;
        else seen_unknown_cmd <= 1'b1;
    end

    task automatic send_uart_byte;
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

    task automatic send_text_btnR;
        begin
            send_uart_byte("b");
            send_uart_byte("t");
            send_uart_byte("n");
            send_uart_byte("R");
            send_uart_byte(8'h0D);
        end
    endtask

    task automatic send_text_status;
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

    task automatic press_btnR_short;
        begin
            btnR = 1'b1;
            // Long enough to pass debounce, short enough to avoid HOLD_TIME_BTN_R.
            repeat (100) @(posedge clk);
            btnR = 1'b0;
            repeat (120) @(posedge clk);
        end
    endtask

    task automatic press_btnR_hold;
        begin
            btnR = 1'b1;
            repeat (230) @(posedge clk);
            btnR = 1'b0;
            repeat (120) @(posedge clk);
        end
    endtask

    task automatic press_btnC_short;
        begin
            btnC = 1'b1;
            repeat (100) @(posedge clk);
            btnC = 1'b0;
            repeat (120) @(posedge clk);
        end
    endtask

    initial begin
        // This TB checks:
        // 1) remote ASCII ingress for btnR and status
        // 2) local button conditioning for btnR short/hold and btnC short
        // 3) local switch decoding into current_context and context option outputs
        clk = 1'b0;
        rst = 1'b1;
        btnU = 1'b0;
        btnD = 1'b0;
        btnL = 1'b0;
        btnR = 1'b0;
        btnC = 1'b0;
        sw_context = 2'b00;
        sw15 = 1'b0;
        rx = 1'b1;
        seen_local_btnR = 1'b0;
        seen_local_btnR_hold = 1'b0;
        seen_local_btnC = 1'b0;
        seen_context_change = 1'b0;
        seen_remote_btnR = 1'b0;
        seen_remote_status = 1'b0;
        seen_unknown_cmd = 1'b0;

        repeat (5) @(negedge clk);
        rst = 1'b0;

        // Check 0: reset default context is watch.
        @(posedge clk);
        #1;
        if (current_context !== `CTX_WATCH) $fatal(1, "default current_context mismatch");
        if (context_change_pulse !== 1'b0) $fatal(1, "unexpected context_change_pulse at reset exit");

        // Check 1: remote btnR command pulse.
        #(BIT_PERIOD_NS * 2);
        send_text_btnR();
        #(BIT_PERIOD_NS * 20);
        if (!seen_remote_btnR) $fatal(1, "remote btnR pulse missing");

        // Check 2: remote status command pulse.
        send_text_status();
        #(BIT_PERIOD_NS * 20);
        if (!seen_remote_status) $fatal(1, "remote status pulse missing");
        if (seen_unknown_cmd) $fatal(1, "unexpected unknown_cmd pulse");

        // Check 3: local btnR short pulse.
        press_btnR_short();
        if (!seen_local_btnR) $fatal(1, "local btnR short pulse missing");

        // Check 4: local btnR hold pulse.
        press_btnR_hold();
        if (!seen_local_btnR_hold) $fatal(1, "local btnR hold pulse missing");

        // Check 5: local btnC short pulse.
        press_btnC_short();
        if (!seen_local_btnC) $fatal(1, "local btnC short pulse missing");

        // Check 6: context transition to DHT11 and sw15 option decode.
        @(negedge clk);
        sw_context = `CTX_DHT11;
        sw15 = 1'b1;
        @(posedge clk);
        #1;
        if (current_context !== `CTX_DHT11) $fatal(1, "failed to enter DHT11 context");
        if (context_change_pulse !== 1'b1) $fatal(1, "missing context_change_pulse on DHT11 entry");
        if (dht11_show_humi !== 1'b1) $fatal(1, "missing DHT11 humi option decode");
        @(posedge clk);
        #1;
        if (context_change_pulse !== 1'b0) $fatal(1, "context_change_pulse should be one cycle");

        // Check 7: transition back to WATCH and watch option decode.
        @(negedge clk);
        sw_context = `CTX_WATCH;
        @(posedge clk);
        #1;
        if (current_context !== `CTX_WATCH) $fatal(1, "failed to return to WATCH context");
        if (context_change_pulse !== 1'b1) $fatal(1, "missing context_change_pulse on WATCH entry");
        if (watch_12h !== 1'b1) $fatal(1, "missing WATCH 12h option decode");

        if (!seen_context_change) $fatal(1, "context_change_pulse was never observed");

        $display("tb_input_unit: PASS");
        $finish;
    end
endmodule
