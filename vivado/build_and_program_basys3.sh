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
top_name="${TOP_NAME:-watch_stopwatch}"
board_name="${OPENFPGA_BOARD:-basys3}"
build_only=0
flash_mode=0

while [[ $# -gt 0 ]]
do
    case "$1" in
        --build-only)
            build_only=1
            shift
            ;;
        --flash)
            flash_mode=1
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 [--build-only] [--flash]" >&2
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
    /home/user/git/Stopwatchpiece \
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
set_param general.maxThreads 1
create_project -in_memory -part xc7a35tcpg236-1

file mkdir [file dirname $container_synth_dcp]
file mkdir [file dirname $container_bit]

read_verilog $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/common_control.v
read_verilog $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/debouncer.v
read_verilog $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/display_select.v
read_verilog $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/10000_counter/fnd_controller.v
read_verilog $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/input_conditioning.v
read_verilog $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/time_set_module.v
read_verilog $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/watch_datapath.v
read_verilog $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/watch_fsm.v
read_verilog $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/stopwatch_datapath.v
read_verilog $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/stopwatch_fsm.v
read_verilog $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/stopwatch_unit.v
read_verilog $container_project_root/ascii_uart_sensor_pipeline.srcs/sources_1/imports/watch_stopwatch/watch_stopwatch.v

read_xdc $container_project_root/ascii_uart_sensor_pipeline.srcs/constrs_1/new/Basys-3-Master.xdc
read_xdc $container_project_root/ascii_uart_sensor_pipeline.srcs/constrs_1/new/ascii_uart_sensor_pipeline.xdc

synth_design -top $top_name -part xc7a35tcpg236-1
write_checkpoint -force $container_synth_dcp

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

if [ "$flash_mode" -eq 1 ]
then
    openFPGALoader -b "$board_name" -f "$host_bit"
else
    openFPGALoader -b "$board_name" "$host_bit"
fi
