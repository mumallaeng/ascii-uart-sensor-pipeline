## Basys3 constraints for ascii_uart_sensor_pipeline
## Current scope: INPUT-stage bring-up only
##
## Constrained ports:
## - clk
## - rst
## - btnU, btnD, btnL, btnR, btnC
## - sw[0], sw[1], sw[15]
## - rx
##
## Notes:
## - top still exposes OUTPUT / SENSOR ports (`tx`, `trig`, `fnd_*`, `led`,
##   `echo`, `dht11_io`) that are intentionally left unconstrained at this stage.
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

## Configuration options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
