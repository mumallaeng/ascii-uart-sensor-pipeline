## Basys3 constraints for ascii_uart_sensor_pipeline
## Current scope: INPUT + CONTROL/EXECUTE bring-up
##
## Constrained ports:
## - clk
## - rst
## - btnU, btnD, btnL, btnR, btnC
## - sw[0], sw[1], sw[15]
## - rx
## - echo, trig, dht11_io
## - led[2:0]
##
## Notes:
## - `echo` / `trig`는 JA 기준 임시 bring-up 매핑을 사용한다.
## - `dht11_io`는 JB 기준 임시 bring-up 매핑을 사용한다.
## - `tx`와 `fnd_*`는 아직 최종 출력부가 아니라서 계속 unconstrained 상태로 둔다.
## - `rst` and `btnC` both need physical inputs right now. Basys3 has only one
##   center button pin in the old project mapping, so `btnC` keeps BTNC and
##   `rst` is temporarily mapped to SW14 for bring-up.

## Clock
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Reset / local buttons
set_property -dict { PACKAGE_PIN T1 IOSTANDARD LVCMOS33 } [get_ports rst]
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports btnU]
set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports btnD]
set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports btnL]
set_property -dict { PACKAGE_PIN T17 IOSTANDARD LVCMOS33 } [get_ports btnR]
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports btnC]

## Switches used by INPUT stage
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports {sw[0]}]
set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports {sw[1]}]
set_property -dict { PACKAGE_PIN R2  IOSTANDARD LVCMOS33 } [get_ports {sw[15]}]

## USB-UART host TX -> FPGA rx
set_property -dict { PACKAGE_PIN B18 IOSTANDARD LVCMOS33 } [get_ports rx]

## JA / JB sensor bring-up pins
set_property -dict { PACKAGE_PIN L2 IOSTANDARD LVCMOS33 } [get_ports echo]
set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 } [get_ports trig]
set_property -dict { PACKAGE_PIN A14 IOSTANDARD LVCMOS33 PULLUP true } [get_ports dht11_io]

## LEDs used by execute_unit status
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {led[2]}]

## Configuration options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
