# ascii-uart-sensor-pipeline

`ascii-uart-sensor-pipeline`은 Basys 3 보드를 대상으로 하는 Verilog/Vivado
통합 프로젝트입니다.

이 저장소는 아래 기능을 모두 포함한 하나의 시스템을 다룹니다.

- UART 송수신
- FIFO 기반 데이터 버퍼링
- ASCII 디코더 및 인코더
- 초음파 센서 인터페이스
- 온습도 센서 인터페이스
- stopwatch/watch 기능

Vivado 프로젝트에서는 현재 설계와 수업에서 검증한 UART/FIFO, ASCII codec,
SR04, DHT11 관련 소스 및 테스트벤치를
`ascii_uart_sensor_pipeline.srcs/*/imports/` 아래에서 함께 추적합니다.

## 개발 환경

- Verilog HDL
- Xilinx Vivado
- Digilent Basys 3
