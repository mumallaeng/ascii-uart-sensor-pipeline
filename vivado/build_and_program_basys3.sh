#!/bin/zsh

# ascii_uart_sensor_pipeline full build helper for macOS host.
# - Host: macOS with zsh + openFPGALoader
# - Build: Vivado 2020.2 inside Docker container
# - Flow: full resynthesis -> implementation -> bitstream -> optional program

set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
project_root=$(cd "$script_dir/.." && pwd)

container_name="${VIVADO_CONTAINER_NAME:-vivado_container}"
vivado_version="${VIVADO_VERSION:-2020.2}"
top_name="${TOP_NAME:-ascii_uart_sensor_pipeline}"
board_name="${OPENFPGA_BOARD:-basys3}"
docker_cpu_count="$(docker info --format '{{.NCPU}}' 2>/dev/null || echo 4)"
if [[ "${VIVADO_MAX_THREADS:-}" != "" ]]
then
    vivado_max_threads="$VIVADO_MAX_THREADS"
elif (( docker_cpu_count > 8 ))
then
    vivado_max_threads=8
else
    vivado_max_threads="$docker_cpu_count"
fi
build_only=0
flash_mode=0
build_mode="full"
xvc_bridge_pid_file="${VIVADO_XVC_PID_FILE:-$HOME/git/.worktrees/vivado-2020.2/openfpgaloader-xvc.pid}"

stop_xvc_bridge_if_running() {
    local bridge_pid=""

    if [ ! -r "$xvc_bridge_pid_file" ]
    then
        return 0
    fi

    bridge_pid="$(tr -d '\n\r\t ' < "$xvc_bridge_pid_file")"
    if [ -z "$bridge_pid" ]
    then
        return 0
    fi

    if kill -0 "$bridge_pid" >/dev/null 2>&1
    then
        echo "Stopping openFPGALoader XVC bridge before direct programming..."
        kill "$bridge_pid" >/dev/null 2>&1 || true
        sleep 2
    fi

    rm -f "$xvc_bridge_pid_file"
}

while [[ $# -gt 0 ]]
do
    case "$1" in
        --build-only)
            build_only=1
            shift
            ;;
        --synth-only)
            build_mode="synth_only"
            build_only=1
            shift
            ;;
        --impl-only)
            build_mode="impl_only"
            build_only=1
            shift
            ;;
        --flash)
            flash_mode=1
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 [--build-only] [--synth-only] [--impl-only] [--flash]" >&2
            echo "This helper is for macOS host + Vivado Docker container." >&2
            exit 1
            ;;
    esac
done

host_synth_dcp="$project_root/ascii_uart_sensor_pipeline.runs/synth_1/${top_name}.dcp"
host_bit="$project_root/ascii_uart_sensor_pipeline.runs/impl_1/${top_name}_nonproject.bit"

if ! docker ps --format '{{.Names}}' | grep -Fxq "$container_name"
then
    echo "Container '$container_name' is not running." >&2
    echo "Start the 2020.2 Vivado container first." >&2
    exit 1
fi

if [[ -n "${ASCII_UART_SENSOR_PIPELINE_CONTAINER_ROOT:-}" ]]
then
    container_project_root="$ASCII_UART_SENSOR_PIPELINE_CONTAINER_ROOT"
else
    container_project_root="$(docker exec "$container_name" bash -lc '
for d in \
    /home/user/git/ascii-uart-sensor-pipeline \
    /home/user/git/ascii-uart-sensor-pipeline-main \
    /home/user/git/ascii_uart_sensor_pipeline \
    /home/user/git/ascii_uart_sensor_pipeline-main \
    /home/user/git/Stopwatchpiece
do
    if [ -f "$d/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/common_control.v" ]; then
        printf "%s" "$d"
        exit 0
    fi
done
exit 1
')"
fi

if [[ -z "${container_project_root:-}" ]]
then
    echo "Unable to locate project root inside container." >&2
    echo "Set ASCII_UART_SENSOR_PIPELINE_CONTAINER_ROOT explicitly if needed." >&2
    exit 1
fi

container_synth_dcp="$container_project_root/ascii_uart_sensor_pipeline.runs/synth_1/${top_name}.dcp"
container_bit="$container_project_root/ascii_uart_sensor_pipeline.runs/impl_1/${top_name}_nonproject.bit"
container_timing_rpt="$container_project_root/ascii_uart_sensor_pipeline.runs/impl_1/${top_name}_timing_summary_nonproject.rpt"
container_util_rpt="$container_project_root/ascii_uart_sensor_pipeline.runs/impl_1/${top_name}_utilization_nonproject.rpt"
container_routed_dcp="$container_project_root/ascii_uart_sensor_pipeline.runs/impl_1/${top_name}_routed_nonproject.dcp"

docker exec "$container_name" bash -lc "
set -euo pipefail
if [ ! -x \"/home/user/Xilinx/Vivado/$vivado_version/bin/vivado\" ]; then
    echo 'Vivado $vivado_version is not installed in this container.' >&2
    exit 1
fi

cat > /tmp/${top_name}_build_nonproject.tcl <<'EOF'
set_param general.maxThreads $vivado_max_threads
create_project -in_memory -part xc7a35tcpg236-1

file mkdir [file dirname $container_synth_dcp]
file mkdir [file dirname $container_bit]
set build_mode {$build_mode}

set rtl_inc_dir $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/new
set rtl_files [list \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/common_control.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/debouncer.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/display_select.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/10000_counter/fnd_controller.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/input_conditioning.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/time_set_module.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/watch_datapath.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/watch_fsm.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/stopwatch_datapath.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/stopwatch_fsm.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/stopwatch_unit.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/uart/uart.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/uart/uart_rx.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/fifo/fifo.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/new/ascii_log_formatter.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/new/log_byte_sender.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/new/cmd_token_pulser.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/new/context_manager.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/new/decision_unit.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/new/dht11.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/new/display_unit.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/new/remote_output_unit.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/new/execute_unit.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/new/fnd_controller_dht11.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/new/fnd_controller_sr04.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/new/remote_input_unit.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/new/sr04.v \
    $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/new/ascii_uart_sensor_pipeline.v \
]

if {\$build_mode eq {impl_only}} {
    if {![file exists $container_synth_dcp]} {
        error [format {Missing synth checkpoint: %s} $container_synth_dcp]
    }
    open_checkpoint $container_synth_dcp
} else {
    foreach rtl_file \$rtl_files {
        read_verilog \$rtl_file
    }

    read_xdc $container_project_root/ascii_uart_sensor_pipeline.srcs/constrs_1/new/Basys-3-Master.xdc
    read_xdc $container_project_root/ascii_uart_sensor_pipeline.srcs/constrs_1/new/ascii_uart_sensor_pipeline.xdc

    synth_design -top $top_name -part xc7a35tcpg236-1
    write_checkpoint -force $container_synth_dcp

    if {\$build_mode eq {synth_only}} {
        exit
    }
}

opt_design
place_design
phys_opt_design
route_design

write_checkpoint -force $container_routed_dcp
report_timing_summary -file $container_timing_rpt
report_utilization -file $container_util_rpt
write_bitstream -force $container_bit
exit
EOF

cd /home/user
source /home/user/Xilinx/Vivado/$vivado_version/settings64.sh
/home/user/Xilinx/Vivado/$vivado_version/bin/vivado -mode batch -nolog -nojournal -notrace -source /tmp/${top_name}_build_nonproject.tcl
"

if [ "$build_mode" = "synth_only" ]
then
    if [ ! -f "$host_synth_dcp" ]
    then
        echo "Synthesis checkpoint was not generated: $host_synth_dcp" >&2
        exit 1
    fi

    echo "Synthesis checkpoint generated:"
    echo "  $host_synth_dcp"
    exit 0
fi

if [ ! -f "$host_bit" ]
then
    echo "Bitstream was not generated: $host_bit" >&2
    exit 1
fi

echo "Bitstream generated:"
echo "  $host_bit"
echo "Synthesis checkpoint generated:"
echo "  $host_synth_dcp"
echo "Program command:"
echo "  openFPGALoader -b $board_name $host_bit"

if [ "$build_only" -eq 1 ]
then
    exit 0
fi

if ! command -v openFPGALoader >/dev/null 2>&1
then
    echo "openFPGALoader is not installed." >&2
    exit 1
fi

# XVC bridge mode keeps the FTDI cable open. Stop it before direct programming.
stop_xvc_bridge_if_running

if [ "$flash_mode" -eq 1 ]
then
    openFPGALoader -b "$board_name" -f "$host_bit"
else
    openFPGALoader -b "$board_name" "$host_bit"
fi
