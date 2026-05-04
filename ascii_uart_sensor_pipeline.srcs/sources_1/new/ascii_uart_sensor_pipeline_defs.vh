`ifndef ASCII_UART_SENSOR_PIPELINE_DEFS_VH
`define ASCII_UART_SENSOR_PIPELINE_DEFS_VH

// Shared command/context/event/action code definitions.
`define CTX_W 2
`define CTX_WATCH 2'd0
`define CTX_STOPWATCH 2'd1
`define CTX_SR04 2'd2
`define CTX_DHT11 2'd3

`define SRC_W 1
`define SRC_LOCAL 1'd0
`define SRC_REMOTE 1'd1

`define CMD_W 4
`define CMD_NONE 4'd0
`define CMD_BTNR 4'd1
`define CMD_BTNR_HOLD 4'd2
`define CMD_BTNL 4'd3
`define CMD_BTNU 4'd4
`define CMD_BTND 4'd5
`define CMD_STATUS 4'd6
`define CMD_CLR 4'd7

`define EVT_W 4
`define EVT_NONE 4'd0
`define EVT_BTNR_SHORT 4'd1
`define EVT_BTNR_HOLD 4'd2
`define EVT_BTNL_SHORT 4'd3
`define EVT_BTNU_SHORT 4'd4
`define EVT_BTND_SHORT 4'd5
`define EVT_STATUS 4'd6
`define EVT_CLR 4'd7

`define ACT_W 4
`define ACT_NONE 4'd0
`define ACT_DISPLAY_TOGGLE 4'd1
`define ACT_WATCH_SET_TOGGLE 4'd2
`define ACT_WATCH_EDIT 4'd3
`define ACT_STOPWATCH_RUNSTOP 4'd4
`define ACT_STOPWATCH_CLEAR 4'd5
`define ACT_STOPWATCH_DIRECTION 4'd6
`define ACT_STATUS_REPORT 4'd7
`define ACT_SOFT_RESET 4'd8

`endif
