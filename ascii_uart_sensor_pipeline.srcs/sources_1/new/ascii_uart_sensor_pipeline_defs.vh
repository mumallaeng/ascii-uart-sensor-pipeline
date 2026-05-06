`ifndef ASCII_UART_SENSOR_PIPELINE_DEFS_VH
`define ASCII_UART_SENSOR_PIPELINE_DEFS_VH

// 프로젝트 공통 command/context/event/action 코드 정의.
// direct child들이 같은 symbolic name을 공유해야 RTL, TB, formatter가
// 모두 동일한 사용자 동작을 기준으로 해석할 수 있다.
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
`define CMD_BTNU_HOLD 4'd8
`define CMD_BTND_HOLD 4'd9

`define EVT_W 4
`define EVT_NONE 4'd0
`define EVT_BTNR_SHORT 4'd1
`define EVT_BTNR_HOLD 4'd2
`define EVT_BTNL_SHORT 4'd3
`define EVT_BTNU_SHORT 4'd4
`define EVT_BTND_SHORT 4'd5
`define EVT_STATUS 4'd6
`define EVT_SOFT_CLEAR 4'd7
`define EVT_CONTEXT_ENTRY_REFRESH 4'd8
// 이후 formatter/log에서 "정책상 무시됨"과 "아무 event도 없음"을
// 구분하고 싶을 때를 위해 남겨 둔 값.
`define EVT_IGNORED 4'd9
`define EVT_CLR `EVT_SOFT_CLEAR

`define ACT_W 4
`define ACT_NONE 4'd0
`define ACT_DISPLAY_TOGGLE 4'd1
`define ACT_SET_MODE_TOGGLE 4'd2
`define ACT_SET_INDEX_NEXT 4'd3
`define ACT_WATCH_VALUE_INC 4'd4
`define ACT_WATCH_VALUE_INC_TENS 4'd5
`define ACT_WATCH_VALUE_DEC 4'd6
`define ACT_WATCH_VALUE_DEC_TENS 4'd7
`define ACT_STOPWATCH_CLEAR 4'd8
`define ACT_STOPWATCH_COUNT_DIR_TOGGLE 4'd9
`define ACT_STOPWATCH_RUN_TOGGLE 4'd10
`define ACT_STATUS_REPORT 4'd11
`define ACT_SOFT_CLEAR 4'd12
`define ACT_IGNORED_IN_SENSOR_CONTEXT 4'd13
`define ACT_REFRESH_REQUEST 4'd14
`define ACT_NO_ACTION 4'd15

// 기존 코드/문서를 한 번에 다 바꾸지 못한 상태를 위해
// 잠시 유지하는 호환 alias들이다.
`define ACT_WATCH_SET_TOGGLE `ACT_SET_MODE_TOGGLE
`define ACT_STOPWATCH_RUNSTOP `ACT_STOPWATCH_RUN_TOGGLE
`define ACT_STOPWATCH_DIRECTION `ACT_STOPWATCH_COUNT_DIR_TOGGLE
`define ACT_SOFT_RESET `ACT_SOFT_CLEAR

`endif
