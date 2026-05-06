## Basys3 constraints for ascii_uart_sensor_pipeline
## Current scope: INPUT + CONTROL + OUTPUT bring-up
##
## Constrained ports:
## - clk
## - btnU, btnD, btnL, btnR, btnC
## - sw0, sw1, sw15
## - rx
## - echo, trig, dht11_io
## - fnd_com[3:0], fnd_data[7:0]
## - led[2:0]
##
## Notes:
## - `echo` / `trig`는 JA 기준 임시 bring-up 매핑을 사용한다.
## - `dht11_io`는 JB 기준 임시 bring-up 매핑을 사용한다.
## - `tx`는 USB-UART host RX로 연결한다.
## - global reset은 top 내부 power-on reset으로 처리하므로 외부 rst pin은 없다.

## Clock
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Local buttons
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports btnU]
set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports btnD]
set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports btnL]
set_property -dict { PACKAGE_PIN T17 IOSTANDARD LVCMOS33 } [get_ports btnR]
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports btnC]

## Switches used by INPUT stage
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports sw0]
set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports sw1]
set_property -dict { PACKAGE_PIN R2  IOSTANDARD LVCMOS33 } [get_ports sw15]

## USB-UART host TX -> FPGA rx
set_property -dict { PACKAGE_PIN B18 IOSTANDARD LVCMOS33 } [get_ports rx]
set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 } [get_ports tx]

## JA / JB sensor bring-up pins
set_property -dict { PACKAGE_PIN M18 IOSTANDARD LVCMOS33 } [get_ports echo]
set_property -dict { PACKAGE_PIN K17 IOSTANDARD LVCMOS33 } [get_ports trig]
set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 PULLUP true } [get_ports dht11_io]

## LEDs used for context/option bring-up debug
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {led[1]}]
set_property -dict { PACKAGE_PIN L1 IOSTANDARD LVCMOS33 } [get_ports {led[2]}]

## 7-segment display used by display_unit
set_property -dict { PACKAGE_PIN U2 IOSTANDARD LVCMOS33 } [get_ports {fnd_com[0]}]
set_property -dict { PACKAGE_PIN U4 IOSTANDARD LVCMOS33 } [get_ports {fnd_com[1]}]
set_property -dict { PACKAGE_PIN V4 IOSTANDARD LVCMOS33 } [get_ports {fnd_com[2]}]
set_property -dict { PACKAGE_PIN W4 IOSTANDARD LVCMOS33 } [get_ports {fnd_com[3]}]
set_property -dict { PACKAGE_PIN W7 IOSTANDARD LVCMOS33 } [get_ports {fnd_data[0]}]
set_property -dict { PACKAGE_PIN W6 IOSTANDARD LVCMOS33 } [get_ports {fnd_data[1]}]
set_property -dict { PACKAGE_PIN U8 IOSTANDARD LVCMOS33 } [get_ports {fnd_data[2]}]
set_property -dict { PACKAGE_PIN V8 IOSTANDARD LVCMOS33 } [get_ports {fnd_data[3]}]
set_property -dict { PACKAGE_PIN U5 IOSTANDARD LVCMOS33 } [get_ports {fnd_data[4]}]
set_property -dict { PACKAGE_PIN V5 IOSTANDARD LVCMOS33 } [get_ports {fnd_data[5]}]
set_property -dict { PACKAGE_PIN U7 IOSTANDARD LVCMOS33 } [get_ports {fnd_data[6]}]
set_property -dict { PACKAGE_PIN V7 IOSTANDARD LVCMOS33 } [get_ports {fnd_data[7]}]

## Configuration options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
