# Vivado 2020.2 XPR Editing Guide

이 문서는 `ascii-uart-sensor-pipeline`에서 Vivado 2020.2 프로젝트 파일을 수동으로 점검하거나 재구성할 때의 기준을 정리한 것이다.

## 기준 문서

- AMD Vivado Design Suite User Guide: System-Level Design Entry UG895 2020.2
- AMD Vivado Design Suite User Guide: Logic Simulation UG900 2020.2
- AMD Vivado Design Suite Tcl Command Reference Guide UG835 2020.2

참고 명령과 개념:

- `add_files -fileset sources_1 ...`
- `add_files -fileset sim_1 ...`
- `set_property top <design_top> [get_filesets sources_1]`
- `set_property top <sim_top> [get_filesets sim_1]`
- WCFG는 `sim_1` 파일셋과 `XSimWcfgFile` 설정이 함께 맞아야 함

## 2020.2에서 꼭 지켜야 하는 규칙

1. `sources_1`, `sim_1`, `constrs_1`를 구분해서 생각할 것
2. 파일 삭제만으로는 project 추적이 없어지지 않으므로, `xpr`에도 old entry가 남아 있지 않아야 함
3. `sim_1`에는 현재 검토 커밋에 필요한 TB와 WCFG만 둘 것
4. `sources_1`에는 현재 검토 커밋에서 필요한 RTL과 그 의존 파일만 둘 것
5. `*.vh`는 header이므로 `Non-module Files`로 보여도 정상
6. `TopModule`은 `sources_1`과 `sim_1`에서 각각 따로 맞출 것

## 수동 편집 시 체크 포인트

### `sources_1`

- `<FileSet Name="sources_1" Type="DesignSrcs" ...>`
- 여기에 현재 커밋에 필요한 RTL만 남겨야 함
- 각 `<File Path="...">` 블록 전체를 기준으로 추가/삭제
- 커밋 범위 밖의 모듈이 보이면 해당 `<File ...>` 블록을 제거

### `sim_1`

- `<FileSet Name="sim_1" Type="SimulationSrcs" ...>`
- 현재 커밋 TB만 남겨야 함
- WCFG도 여기에 `<File Path="$PPRDIR/wcfg/...">` 형태로 있어야 함
- old `tb_watch*`, `tb_fifo*`, `tb_uart*`가 남아 있으면 제거

### sim top / WCFG

- `sim_1`의 `<Config>`에서 확인
- `<Option Name="TopModule" Val="tb_..."/>`
- `<Option Name="XSimWcfgFile" Val="$PPRDIR/wcfg/..."/>`
- 둘이 현재 검토 TB와 WCFG에 정확히 대응해야 함

## 1번 커밋 기준 예시

현재 1번 커밋은 `remote_input_unit` 기준이다.

### `sources_1`에 있어야 하는 파일

- `imports/uart/uart.v`
- `imports/uart/uart_rx.v`
- `imports/fifo/fifo.v`
- `new/ascii_uart_sensor_pipeline_defs.vh`
- `new/ascii_command_decoder.v`
- `new/remote_input_unit.v`

### `sim_1`에 있어야 하는 파일

- `sim_1/new/tb_input_unit.v`
- `wcfg/tb_input_unit_wave.wcfg`

### `sources_1` top

- `remote_input_unit`

### `sim_1` top

- `tb_input_unit`

## assistant용 작업 프롬프트

아래 기준을 만족하도록 `ascii_uart_sensor_pipeline.xpr`와 `vivado/create_ascii_uart_sensor_pipeline_project.tcl`을 수정하라.

1. Vivado 버전은 2020.2 기준
2. `sources_1`, `sim_1`, `constrs_1`를 분리해서 다룰 것
3. 현재 검토 커밋 범위 밖의 `sources_1` RTL, `sim_1` TB, old WCFG는 제거할 것
4. `sim_1`에는 현재 TB와 현재 WCFG만 보이게 할 것
5. `sources_1` top, `sim_1` top, `XSimWcfgFile`을 현재 검토 대상에 맞출 것
6. `*.vh`가 `Non-module Files`로 보이는 것은 허용
7. 변경 후 `xpr`에서 old file path가 남아 있지 않은지 다시 검색으로 확인할 것

## 확인 명령 예시

```sh
rg -n "tb_watch|tb_stopwatch|tb_fifo|tb_uart|tb_dht11|tb_sr04|sensor_dht11" ascii_uart_sensor_pipeline.xpr vivado/create_ascii_uart_sensor_pipeline_project.tcl
```

위 검색 결과가 비어 있어야, 현재 범위 밖의 old entry가 제거된 것이다.
