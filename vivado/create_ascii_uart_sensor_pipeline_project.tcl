set script_dir [file normalize [file dirname [info script]]]
set repo_root [file normalize [file join $script_dir ..]]
set project_name ascii_uart_sensor_pipeline_reference
set project_dir [file normalize [file join $repo_root .vivado $project_name]]

file mkdir $project_dir

create_project $project_name $project_dir -part xc7a35tcpg236-1 -force
set_property target_language Verilog [current_project]

set source_files [list \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports watch_stopwatch common_control.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports watch_stopwatch debouncer.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports watch_stopwatch display_select.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports 10000_counter fnd_controller.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports watch_stopwatch input_conditioning.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports watch_stopwatch time_set_module.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports watch_stopwatch watch_datapath.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports watch_stopwatch watch_fsm.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports watch_stopwatch stopwatch_datapath.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports watch_stopwatch stopwatch_fsm.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports watch_stopwatch stopwatch_unit.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports watch_stopwatch watch_stopwatch.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports 10000_counter button_debounce.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports uart uart.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports uart uart_rx.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports uart uart_loopback.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports fifo fifo.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports uart_fifo uart_fifo_loopback.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports ascii_codec ascii_decoder.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports ascii_codec ascii_sender.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports sensor_sr04 sr04.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports sensor_sr04 sr04_fnd_controller.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sources_1 imports sensor_dht11 dht11.v] \
]

set sim_files [list \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sim_1 imports watch_stopwatch tb_watch_stopwatch.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sim_1 imports watch_stopwatch tb_watch_set.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sim_1 imports watch_stopwatch tb_watch_unit.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sim_1 imports watch_stopwatch tb_watch.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sim_1 imports watch_stopwatch tb_debouncer.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sim_1 imports watch_stopwatch tb_input_conditioning.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sim_1 imports watch_stopwatch tb_stopwatch_datapath.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sim_1 imports watch_stopwatch tb_stopwatch_fsm.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sim_1 imports watch_stopwatch tb_stopwatch_unit.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sim_1 imports uart tb_uart_loopback.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sim_1 imports fifo tb_fifo.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sim_1 imports uart_fifo tb_uart_fifo_loopback.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sim_1 imports ascii_codec tb_fifo_ascii_decoder.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sim_1 imports sensor_sr04 tb_sr04.v] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs sim_1 imports sensor_dht11 tb_dht11.v] \
]

set constraint_files [list \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs constrs_1 new Basys-3-Master.xdc] \
    [file join $repo_root ascii_uart_sensor_pipeline.srcs constrs_1 new ascii_uart_sensor_pipeline.xdc] \
]

add_files -fileset sources_1 $source_files
add_files -fileset sim_1 $sim_files
add_files -fileset constrs_1 $constraint_files

set_property top watch_stopwatch [get_filesets sources_1]
set_property top tb_watch_stopwatch [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Created Vivado project:"
puts "  [file join $project_dir ${project_name}.xpr]"
