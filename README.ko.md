[English](README.md) | 한국어

# ASCII UART Sensor Pipeline

2026.05.01~2026.05.06

> [컨소시엄] 온디바이스AI 시스템반도체 설계 2기 교육과정 Verilog 수업에서 진행된 과제입니다.

▶ [시연 영상](https://youtu.be/VrtHO9WrXKs?si=LZ4agQC4BuWus110)

<table>
<tr>
<td><img width="420" alt="1_watch" src="https://github.com/user-attachments/assets/0afb560c-f2cb-41e0-9457-b428ca7ca6e3" /><br><strong>시계 모드</strong><br>시간 표시 및 로컬·원격 제어</td>
<td><img width="420" alt="2_stopwatch" src="https://github.com/user-attachments/assets/8296ab21-5c27-4957-a155-201a11fee898" /><br><strong>스톱워치 모드</strong><br>시작·정지·초기화 및 UART 제어</td>
</tr>
<tr>
<td><img width="420" alt="3_dht11" src="https://github.com/user-attachments/assets/f2ced895-1c53-4a81-82f3-c23c49742243" /><br><strong>DHT11</strong><br>온·습도 측정값 표시 및 UART 출력</td>
<td><img width="420" alt="4_sr04" src="https://github.com/user-attachments/assets/36209465-2c2a-4196-829f-4bbfb9b43fbc" /><br><strong>SR04</strong><br>초음파 거리 측정값 표시 및 UART 출력</td>
</tr>
</table>

| 담당자 | 담당 내용 |
|---|---|
| 김연우 ([@mumallaeng](https://github.com/mumallaeng)) | top `remote_input_unit` 통합 및 검증 |
| 박경민 ([@gyeongminbag27-arch](https://github.com/gyeongminbag27-arch)) | 초음파 센서 SR04 통합 및 검증 |
| 유지민 ([@jimin-max](https://github.com/jimin-max)) | 온습도 센서 DHT11 통합 및 검증 |

## 1. 개요 (Overview)

### 1.1 목적 및 목표

이번 프로젝트의 목적은 이전 stopwatch/watch와 UART LOOPBACK 과제에서 분리되어 있던 기능을 하나의 FPGA 시스템으로 통합하는 것이다. 최종 목표는 Basys 3 보드 위에서 watch/stopwatch, UART/FIFO, SR04, DHT11를 동시에 운용하고, 로컬 버튼/스위치와 원격 UART 명령을 같은 제어 체계로 묶는 것이다.

핵심 목표는 아래와 같다.

- top module 하나로 기능을 통합한다.
- 로컬 입력과 원격 입력을 같은 canonical event로 정규화한다.
- FND와 UART log를 동시에 출력하는 구조를 만든다.
- 센서 값이 현재 화면 문맥과 무관하게 최신값으로 유지되도록 한다.

<img width="1118" alt="목적" src="https://github.com/user-attachments/assets/80aecc92-f39a-4999-9a6d-bd992886136b" />

<img width="1095" alt="목표" src="https://github.com/user-attachments/assets/dc088cd6-5606-41ac-b53a-0c00296a7095" />

### 1.2 설계 범위

- ascii_uart_sensor_pipeline top 통합
- watch/stopwatch 기능 유지
- UART RX/TX, FIFO buffer, ASCII command parsing/log formatting
- SR04 거리 센서 연동
- DHT11 온습도 센서 연동
- context 기반 FND 출력
- 단위 TB와 통합 TB 기반 검증

### 1.3 프로젝트 요약

이 프로젝트는 Timepiecer 계열의 로컬 표시 중심 구조를 UART LOOPBACK 이후 단계로 확장하여, 외부 명령 입력과 센서 상태 보고까지 포함하는 통합 시스템으로 만든 결과물이다.

최종 top module은 ascii_uart_sensor_pipeline이며, 현재 구조는 INPUT / CONTROL / OUTPUT 3단계로 정리된다.

- **INPUT**: 버튼 정형화, context 선택, UART 명령 수신
- **CONTROL**: 이벤트 해석, action 분배, 센서 refresh 제어
- **OUTPUT**: FND 표시, ASCII event log 송신

### 1.4 설계 사양 요약 (Specification Summary)

| 항목 | 내용 |
|---|---|
| FPGA 보드 | Digilent Basys 3 |
| 시스템 클럭 | 100 MHz |
| UART 기준 | 9600 bps, 16x oversampling |
| FIFO | 4-depth byte buffer |
| 센서 인터페이스 | SR04(JA), DHT11(JB) |
| 표시 장치 | 4-digit FND, LED |
| top module | ascii_uart_sensor_pipeline |

## 2. 프로젝트 관리 (Project Management)

### 2.1 일정 계획 (Schedule)

| 단계 | 기간 | 주요 작업 |
|---|---|---|
| 요구사항 정리 | 2026.05.01 | 기존 watch/stopwatch, UART, SR04, DHT11 통합 기준 정의 |
| 아키텍처 설계 | 2026.05.02 | INPUT/CONTROL/OUTPUT 구조와 context/UI 규칙 정리 |
| RTL 통합 | 2026.05.03 ~ 2026.05.05 | top 연결, remote I/O, display, sensor latest value 경로 정리 |
| 검증 보강 | 2026.05.05 | tb_decision_unit, tb_dht11, tb_sr04, top TB 정리 |
| 문서 정리 | 2026.05.06 | 발표자료, 일정표, 일지, 완료보고서 정리 |

### 2.2 개발 환경 (Development Environment)

| 분류 | 기술 |
|---|---|
| 형상관리 | Git |
| 문서 | Microsoft Word, PowerPoint, Excel, Markdown |
| 협업 자료 | Google Drive shared deliverables |
| 검증 로그 | Icarus Verilog 실행 결과, Vivado project files |

### 2.3 설계 환경 (Design Environment)

| 분류 | 내용 |
|---|---|
| 언어 | Verilog HDL |
| FPGA | Digilent Basys 3 (Artix-7 XC7A35T) |
| EDA | Vivado 2020.2 |
| Simulator | Vivado XSim, Icarus Verilog |

## 3. 아키텍처 설계 (Architecture)

### 3.1 시스템 구조

#### 3.1.1 Top Module

<img width="2171" alt="top  ascii_uart_sensor_pipeline-lv2 drawio" src="https://github.com/user-attachments/assets/4d613e6c-a3fb-4218-9f9a-25e4c9343482" />

현재 main 기준 top direct child는 아래 7개다.

- input_conditioning
- context_manager
- remote_input_unit
- decision_unit
- execute_unit
- display_unit
- remote_output_unit

이를 기능 관점으로 다시 묶으면 아래와 같다.

| 구분 | 모듈 | 역할 |
|---|---|---|
| INPUT | input_conditioning, context_manager, remote_input_unit | 버튼 pulse 정리, switch context 해석, UART 명령 수신 |
| CONTROL | decision_unit, execute_unit | 입력 우선순위 해석, action 분배, watch/stopwatch/sensor 실행 |
| OUTPUT | display_unit, remote_output_unit | FND 표시, UART log 송신 |

ascii_uart_sensor_pipeline top module은 local 입력, remote UART 입력, watch/stopwatch 상태, SR04/DHT11 latest value, FND 표시, UART log 송신을 하나의 계층에서 통합하는 상위 래퍼이다. 상위 구조는 input_conditioning, context_manager, remote_input_unit을 INPUT으로, decision_unit과 execute_unit을 CONTROL로, display_unit과 remote_output_unit을 OUTPUT으로 분리해 설명할 수 있다.

context_manager는 sw[1:0]과 sw15를 기준으로 WATCH, STOPWATCH, SR04, DHT11 및 세부 view를 확정하며, decision_unit은 local pulse와 remote command를 같은 canonical event로 정규화한다. execute_unit은 watch/stopwatch 상태와 sensor latest value를 유지하고, display_unit은 현재 context에 맞는 대표 값을 FND에 선택 출력한다.

UART log 출력은 status 또는 event log 요청이 들어오면 remote_output_unit 내부의 log_entry_collector가 SRC, CMD, EVT, CTX, ACT 메타데이터와 WT, SW, SR04, DHT11 latest status를 묶고, ascii_log_formatter가 현재 byte index에 해당하는 ASCII 문자 1개만 계산하며, log_byte_sender가 이를 uart_tx_fifo로 순차 push하는 구조로 설계하였다. 즉 FND는 current context 대표값을 보여주고, UART는 현재 시스템 상태를 ASCII log로 내보내는 이중 출력 구조를 갖는다.

**INPUT 블록**

<img width="1617" alt="INPUT_block_diagram" src="https://github.com/user-attachments/assets/da7982b7-ce0a-4bd2-8b70-db3512a164fc" />

| 모듈 | 역할 |
|---|---|
| input_conditioning | 로컬 버튼 입력을 short/hold pulse로 정리 |
| context_manager | 현재 context와 sensor view를 결정 |
| remote_input_unit | UART ASCII command를 내부 command pulse로 변경 |
| uart_rx_fifo | serial rx를 ASCII byte stream으로 바꾸는 RX 경계 |
| ascii_command_parser | multi-byte ASCII command를 CMD_* token으로 해석 |
| cmd_token_pulser | CMD_* token을 1-cycle command pulse로 변경 |

<img width="1618" alt="INPUT_ascii_command_parser" src="https://github.com/user-attachments/assets/11a5db06-d9ae-472e-b550-97f6800e3acd" />
<img width="4180" alt="INPUT_ascii_command_parser-ASM" src="https://github.com/user-attachments/assets/ecfcf5bd-fe44-48a2-8210-b49543364023" />

<img width="1430" alt="INPUT_RTL_1" src="https://github.com/user-attachments/assets/5b9e0a1b-f086-47f6-bd21-a3c1bbc34b69" />
<img width="1567" alt="INPUT_RTL_2" src="https://github.com/user-attachments/assets/87b65ab7-d8c9-46e7-a914-6ab6c3ce05d9" />

<img width="1224" alt="remote_input_unit" src="https://github.com/user-attachments/assets/d03be2f2-ec9e-419b-a77b-68d8828f1734" />


<br/>
<br/>
<br/>

**CONTROL 블록**

<img width="1579" alt="CONTROL_block_diagram" src="https://github.com/user-attachments/assets/4b819c54-06a8-4bff-ae1d-3dbdb27e69a8" />

| 모듈 | 역할 |
|---|---|
| decision_unit | 입력을 현재 context 기준 제어 의미로 바꾸는 정책 블록 |
| execute_unit | 실제 시간 기능과 센서 latest value를 만드는 실행 블록 |
| event_selector | local/remote 입력을 canonical event로 정리하는 블록 |
| action_dispatcher | canonical event를 watch/stopwatch/sensor action으로 분기하는 블록 |
| watch_stopwatch_unit | watch와 stopwatch 상태를 실제로 만드는 시간 기능 블록 |
| sr04_unit | 초음파 센서 latest 거리값과 FND 후보를 만드는 블록 |
| dht11_unit | 온습도 센서 latest 값과 FND 후보를 만드는 블록 |

<img width="1575" alt="CONTROL_decision_RTL_1" src="https://github.com/user-attachments/assets/1243582b-c9d1-4445-a90c-1bff18e06d1d" />
<img width="1570" alt="CONTROL_decision_RTL_2" src="https://github.com/user-attachments/assets/aab4dace-72ec-4ab7-8f62-c8ce31efec7f" />
<img width="1523" alt="CONTROL_excute_RTL_1" src="https://github.com/user-attachments/assets/05e1ff72-3908-48e7-940e-6b44833b3d8d" />


<br/>
<br/>
<br/>

**OUTPUT 블록**

<img width="1672" alt="OUTPUT_block_diagram" src="https://github.com/user-attachments/assets/a5488ea2-56a2-476f-8a31-3f729acead5f" />

| 모듈 | 역할 |
|---|---|
| display_unit | 현재 context에 맞는 FND 후보를 최종 선택하는 블록 |
| remote_output_unit | latest 상태와 log meta를 UART status log로 내보내는 블록 |
| log_entry_collector | status log 1건에 필요한 latest 값과 meta를 모으는 블록 |
| ascii_log_formatter | status 정보를 ASCII log byte로 바꾸는 블록 |
| uart_tx_unit | ASCII log byte를 실제 UART TX 경계로 넘기는 블록 |
| log_byte_sender | log를 1바이트씩 순서대로 push하는 FSM 블록 |

<img width="1774" alt="OUTPUT-log_byte_sender-FSM" src="https://github.com/user-attachments/assets/f21c3cec-c972-469f-a4b1-11c8536a5384" />
<img width="1536" alt="OUTPUT_log_byte_sender-ASM" src="https://github.com/user-attachments/assets/63f3f0c4-6e2b-4d00-99d1-0ad5366bdc9b" />

<br/>
<br/>
<br/>

#### 3.1.2 SR04 SENSOR

<img width="596" alt="SR04_BlockDiagram" src="https://github.com/user-attachments/assets/df68deee-0eca-4cda-a0c9-4da355fc8b8c" />

본 설계에서는 SR04 초음파 센서를 하나의 독립적인 기능 블록 SR04_UNIT으로 구성하였다. SR04_UNIT은 초음파 센서 SR04와 직접 통신하여 물체와의 거리를 측정하고, 측정된 데이터를 FND 패널로 출력한다.

HC-SR04 센서는 TRIG와 ECHO 신호를 기반으로 동작한다.

FPGA는 TRIG 핀에 약 10us의 HIGH pulse를 출력하여 초음파 전송을 시작하며, 센서는 40kHz 초음파를 송신한다. 이후 초음파가 물체에 반사되어 돌아오면 센서는 ECHO 핀을 HIGH 상태로 유지한다. ECHO 신호의 유지 시간은 초음파 왕복 시간에 비례하며, FPGA는 해당 pulse width를 측정하여 거리를 계산한다.

계산된 거리 값은 내부 제어 로직을 통해 FND 출력 모듈로 전달되며 사용자는 실시간으로 거리정보를 확인할 수 있다.

sr04 센서는 초음파를 송신하고 다시 복귀하는 수신신호가 tx,rx로 송수신의 포트가 구분되어있다.

**SR04_Controller 입출력 표**

| 신호명 | 방향 | 길이 | 상세 설명 | 연결부 |
|---|---|---|---|---|
| clk | 입력 | 1bit | 시스템 클럭 신호 | FPGA 시스템 클럭 |
| rst | 입력 | 1bit | 시스템 초기화 신호 | Reset 제어부 |
| refresh_req | 입력 | 1bit | 거리 측정을 시작하기 위한 요청 신호 | remote_unit |
| echo | 입력 | 1bit | 초음파 반사 신호가 복귀하는 핀 | HC-SR04-TRIG |
| trig | 출력 | 1bit | 초음파 송신을 위한 Trigger 신호 출력 | HC-SR04 TRIG |
| fnd_com | 출력 | 4bit | FND 자리 선택 제어 신호 | 7-segment-FND |
| fnd_data | 출력 | 8bit | FND 세그먼트 데이터 출력 신호 | 7-segment-FND |

- 데이터 흐름 정의: refresh_req 신호 입력 -> sr04_start 신호 전송 -> tick_cnt가 10이 될 때까지 tick_us를 송신 -> echo 신호 복귀 -> 거리 측정 -> 초기상태

#### 3.1.3 DHT11 SENSOR

<img width="521" alt="DHT11_BlockDiagram" src="https://github.com/user-attachments/assets/6b0a1e46-08cb-4165-832d-85965e648636" />

본 설계에서는 DHT11 온습도 센서를 하나의 독립적인 기능 블록인 DHT11_UNIT으로 구성하였다. DHT11_UNIT은 DHT11 센서와 직접 통신하여 온도와 습도 데이터를 수신하고, 수신된 데이터를 정수부와 소수부로 분리하여 출력하는 역할을 한다. 또한 수신 데이터의 checksum을 검증하여 데이터의 유효성을 판단하고, 측정값을 FND에 표시하기 위한 출력 신호를 생성한다.

DHT11 센서는 하나의 DATA 라인을 통해 FPGA와 양방향 통신을 수행한다. 따라서, dht11_io는 inout 신호로 설계하였다. FPGA가 센서에 start 신호를 보낼 때는 출력 신호로 사용되고, 센서가 데이터를 전송할 때는 입력 신호로 사용된다.

**DHT11 입출력 정의**

| 구분 | 신호명 | 비트 수 | 설명 |
|---|---|---|---|
| 입력 | i_refresh_req | 1bit | DHT11 측정 시작 요청 신호 |
| 입력 | i_show_humi | 1bit | 습도 표시 선택 신호 |
| 입력 | i_show_fahrenheit | 1bit | 화씨 표시 선택 신호 |
| 입출력 | dht11_io | 1bit | DHT11 DATA 양방향 통신 신호 |
| 출력 | o_temp | 8bit | 온도 정수부 |
| 출력 | o_temp_frac | 8bit | 온도 소수부 |
| 출력 | o_humi | 8bit | 습도 정수부 |
| 출력 | o_humi_frac | 8bit | 습도 소수부 |
| 출력 | o_valid | 1bit | checksum 검증 결과 |
| 출력 | o_fnd_com | 4bit | FND 자리 선택 신호 |
| 출력 | o_fnd_data | 8bit | FND segment 출력 신호 |

- 데이터 흐름 정의: i_refresh_req 입력 → DHT11 start 신호 전송 → dht11_io를 통해 40bit 데이터 수신 → 온도/습도 정수부 및 소수부 분리 → checksum 검증 → 유효 데이터 출력 → 표시 모드에 따라 FND 출력 생성

### 3.2 설계 이론 및 배경 (Theory & Background)

#### 3.2.1 Top Module

ascii_uart_sensor_pipeline top module은 local 입력, remote UART 입력, watch/stopwatch 상태, SR04/DHT11 latest value, FND 표시, UART log 송신을 하나의 계층에서 통합하는 상위 래퍼이다. 상위 구조는 input_conditioning, context_manager, remote_input_unit을 INPUT으로, decision_unit과 execute_unit을 CONTROL로, display_unit과 remote_output_unit을 OUTPUT으로 분리해 설명할 수 있다.

context_manager는 sw[1:0]과 sw15를 기준으로 WATCH, STOPWATCH, SR04, DHT11 및 세부 view를 확정하며, decision_unit은 local pulse와 remote command를 같은 canonical event로 정규화한다. execute_unit은 watch/stopwatch 상태와 sensor latest value를 유지하고, display_unit은 현재 context에 맞는 대표 값을 FND에 선택 출력한다.

UART log 출력은 status 또는 event log 요청이 들어오면 remote_output_unit 내부의 log_entry_collector가 SRC, CMD, EVT, CTX, ACT 메타데이터와 WT, SW, SR04, DHT11 latest status를 하나의 snapshot으로 먼저 묶고, ascii_log_formatter가 현재 byte index에 해당하는 ASCII 문자 1개만 계산하며, log_byte_sender가 이를 uart_tx_fifo로 순차 push하는 구조로 설계하였다. 즉 FND는 current context 대표값을 보여주고, UART는 현재 시스템 상태를 ASCII log로 내보내는 이중 출력 구조를 갖는다.

이때 UART 응답 포맷은 사람이 시리얼 터미널에서 바로 읽을 수 있고, TB나 ILA에서도 byte 순서를 그대로 검증할 수 있도록 항목명=값<LF> 형태의 줄 단위 ASCII 형식으로 고정하였다. 한 번의 status 요청이 수락되면 명령 수락 시점의 context, action result, watch/stopwatch 값, sensor latest value가 하나의 응답 프레임으로 묶여 전송되므로, 통합 검증에서는 이 로그가 설계 동작의 직접 증거 자료가 된다.

로그 출력 예시는 다음과 같다. status 요청 기준으로는 현재 main과 top TB에서 아래와 같은 축약형 줄 단위 ASCII 응답을 사용한다.

<img width="245" alt="event-log" src="https://github.com/user-attachments/assets/669f4f79-5dbb-43b3-bd7e-75010f116c33" />

위 예시에서 SRC는 입력 출처를, CMD는 수신 명령 원문을, EVT는 decision_unit에서 정규화한 canonical event를 의미한다. 또한 CTX는 로그 capture 시점의 active context, ACT는 실제 실행 결과, WT와 SW는 watch 및 stopwatch snapshot, SR04와 DHT11은 해당 시점의 latest sensor value를 의미한다. 따라서 검증 관점에서는 status 1회가 이런 완전한 snapshot 1건으로 이어지는지, 그리고 마지막 byte가 전송될 때까지 동일 snapshot이 유지되는지가 핵심 확인 포인트가 된다.

로그 해석 기준을 고정하기 위해 CMD alias, EVT, ACT 허용값을 다음과 같이 정의하였다.

#### 3.2.2 SR04 SENSOR

**SR04 핀맵**

<img width="304" alt="SR04-PINMAP" src="https://github.com/user-attachments/assets/c2e20cf4-c98d-42a4-bd09-0596046e0abb" />

| 핀번호 | 핀명 | 상세 설명 |
|---|---|---|
| 1 | vcc | VCC 파워 핀 (Max: 5V) |
| 2 | Tigger | FPGA 보드에서 Trigger 핀에 10us 동안 High 신호 인가시 초음파를 송신한다. |
| 3 | Echo | 송신된 초음파가 물체에 반사되어 다시 센서로 돌아오는 동안 High 상태를 유지한다. High 구간의 시간을 통해 거리를 계산한다. |
| 4 | Ground | 기준 전압 역할 수행 |

##### 3.2.2.1 SR04 핀맵 구조

<img width="438" alt="SR04-signal" src="https://github.com/user-attachments/assets/055ab2a6-41da-4e85-be0c-ee74142b4f73" />

본 설계에서는 HC-SR04 초음파 센서를 사용하여 물체와의 거리를 측정한다. SR04 센서는 초음파를 송신한 후 반사되어 돌아오는 시간을 측정하여 거리를 계산하는 방식으로 동작한다. FPGA에서는 Trigger 신호를 통해 센서를 동작시키고, Echo 신호의 HIGH 유지 시간을 측정하여 거리를 계산한다.

SR04 센서는 Trigger 핀에 10us 이상의 HIGH 펄스가 입력되면 거리 측정을 시작한다. 센서는 내부적으로 40kHz 초음파를 8회 송신하며, 물체에 반사되어 돌아오는 신호를 수신한다. 초음파가 송신된 후 echo 핀은 HIGH 상태가 되며 다시 센서에 도달하면 LOW 상태로 전환된다. 따라서 Echo 핀의 HIGH 유지 시간은 초음파의 왕복시간과 비례한다.

FPGA에서는 Echo 핀의 HIGH 시간을 마이크로초 단위로 측정하고 이를 이용하여 물체와의 거리를 계산한다.

데이터 시트에서 제공하는 거리 계산 공식은 다음과 같다.

$$
Distance(cm) = \frac{Echo pulse width(us)}{58}
$$

이 공식을 기반으로 물체와 초음파센서 사이의 거리를 측정한다.

#### 3.2.3 DHT11 SENSOR

##### 3.2.3.1 DHT11 회로 연결 구조

<img width="495" alt="image" src="https://github.com/user-attachments/assets/930daa07-8d9c-4711-b44f-36718a4b4422" />

DHT11은 온도와 습도를 측정하는 디지털 센서로, 내부에서 측정된 값을 디지털 데이터 형태로 변환하여 외부 장치에 전달한다. 하나의 DATA 라인을 이용해 통신하며, 온도와 습도 정보를 40bit 데이터 형식으로 전송한다.

DHT11 센서는 하나의 DATA 라인을 통해 FPGA와 통신한다. DATA 라인은 평소 HIGH 상태를 유지해야 하므로 VDD와 DATA 사이에 약 5kΩ의 pull-up 저항이 연결된다.

DATA 라인은 양방향 신호이기 때문에 FPGA와 DHT11이 동시에 DATA 라인을 제어하면 안 된다. 따라서 FPGA는 start 신호를 보낼 때만 DATA 라인을 직접 제어하고, 이후에는 High-Z 상태로 전환하여 센서가 DATA 라인을 제어할 수 있도록 한다.

##### 3.2.3.2 DHT11 동작원리

<img width="712" alt="image" src="https://github.com/user-attachments/assets/49c09790-7172-40f5-baaa-0cc3b40ce6cd" />

DHT11의 통신 과정은 크게 start 신호 전송, 센서 응답, 데이터 전송 단계로 구분된다.

먼저 FPGA는 DHT11 센서에 측정 시작을 알리기 위해 DATA 라인을 LOW로 내린다. 이 LOW 신호는 약 18ms 이상 유지되어야 하며, 이후 DATA 라인을 다시 HIGH로 올린 뒤 센서의 응답을 기다린다.

센서는 start 신호를 감지하면 응답 신호를 보낸다. DHT11은 먼저 DATA 라인을 약 80us 동안 LOW로 유지하고, 이어서 약 80us 동안 HIGH로 유지한다. 이 응답 신호를 통해 FPGA는 센서가 정상적으로 통신을 시작했음을 확인할 수 있다.

응답 신호 이후에는 실제 데이터 전송이 시작된다. DHT11은 총 40bit 데이터를 전송하며, 각 bit는 LOW 구간과 HIGH 구간으로 구성된다. 각 bit는 먼저 약 50us 동안 LOW를 유지한 뒤, HIGH 유지 시간에 따라 0과 1이 구분된다.

**DHT11 DATA bit 판별 방식**

| 구분 | LOW 구간 | HIGH 구간 | 의미 |
|---|---|---|---|
| DATA 0 | 약 50us | 약 26~28us | bit 값 0 |
| DATA 1 | 약 50us | 약 70us | bit 값 1 |

##### 3.2.3.3 40bit 데이터 구성 및 Checksum 검증

DHT11 센서는 측정한 온도와 습도 데이터를 총 40bit의 디지털 데이터로 전송한다. 이 데이터는 8bit 단위로 구분되며, 습도 정보, 온도 정보, 그리고 데이터 검증을 위한 checksum으로 구성된다.

**DHT11 bit 구성**

| 구분 | 비트 수 | 의미 |
|---|---|---|
| 습도 정수부 | 8bit | 습도 값의 정수 부분 |
| 습도 소수부 | 8bit | 습도 값의 소수 부분 |
| 온도 정수부 | 8bit | 온도 값의 정수 부분 |
| 온도 소수부 | 8bit | 온도 값의 소수 부분 |
| Checksum | 8bit | 수신 데이터 검증용 값 |

Checksum은 앞의 4byte 값을 더한 결과와 센서가 마지막에 전송한 checksum 값을 비교하여 데이터가 정상적으로 수신되었는지 확인하는 데 사용된다. 계산된 checksum 값과 수신된 checksum 값이 일치하면 데이터가 정상적으로 수신된 것으로 판단하고, 일치하지 않으면 통신 오류 또는 데이터 손상으로 판단한다.

## 4. 상세 설계 (Detailed Design)

### 4.1 RTL 설계

- Module 구성
- 주요 구조 설명(순서도 혹은 ASM 등)

#### 4.1.1 Top Module

<img width="1704" alt="TOP_RTL_01" src="https://github.com/user-attachments/assets/54ba419a-8db0-4444-a2c0-137ed981d02a" />

<img width="1400" alt="TOP_RTL_02" src="https://github.com/user-attachments/assets/86e18524-7a7c-444b-bd87-62bcde4401e8" />
<img width="1343" alt="TOP_RTL_03" src="https://github.com/user-attachments/assets/348c0a4d-f15f-48ef-88c8-3668721f42ac" />
<img width="1447" alt="TOP_RTL_04" src="https://github.com/user-attachments/assets/9db8b010-5b6b-42b1-9971-6df45b22d98b" />
<img width="1367" alt="TOP_RTL_05" src="https://github.com/user-attachments/assets/85acbd7a-ff25-46f2-af22-ed47c5dc33b1" />

top module RTL schematic 1~4를 통해 전체 구조를 확인하였다.

#### 4.1.2 SR04 SENSOR

##### 4.1.2.1 RTL 설계


<img width="1400" alt="image" src="https://github.com/user-attachments/assets/d50047dc-6ff4-4488-9d07-e74d9e8158e7" />


| 모듈명 | 상세설명 |
|---|---|
| U_TICK_GEN | tick을 생성하는 모듈 |
| U_SR04_CNTL | 초음파 센서를 제어하는 메인 모듈 |
| U_FND_CNTL | FND-segment 부와 SR04_CNTL을 연결하는 모듈 |

sr04의 회로도는 표와 같이 총 3개의 모듈로 구성된다.

##### 4.1.2.2 FSM 상태도

| state | 상태 동작 |
|---|---|
| IDLE | 초기 상태로 trig =0입력 후 sr04_start ==1일 때 START 상태로 천이한다. |
| START | trig =1 입력 후 초음파 송신을 시작한다. tick_us를 기준으로 카운트를 증가시킨다. tick_cnt ==11이 되면 WAIT 상태로 천이한다. |
| WAIT | Echo 신호를 대기하는 상태이다. echo==1이면 tick_cnt =0으로 입력된다. 이후 RESPONSE 상태로 천이한다. |
| RESPONSE | echo =1인 동안 tick_us를 기준으로 tick_cnt를 증가시켜 Echo pulse width를 측정한다. echo ==0이 되면 측정을 종료한 후 distance = tick_cnt/58 연산을 수행한 뒤 IDLE 상태로 복귀한다. |

HC-SR04 Ultrasonic Sensor의 FSM은 초음파 센서의 거리 측정 과정을 단계적으로 제어하기 위해 구성하였다. 초기 상태인 IDLE에서는 trig 신호를 0으로 유지하며 센서가 동작을 시작하기 위한 sr04_start 입력을 대기한다. sr04_start ==1의 조건을 만족하여 sr04_start 신호가 활성화되면 START 상태로 천이된다.

START 상태에서는 초음파 송신을 생성하기 위해 trig를 1로 출력한다. 이후 tick_us신호를 기준으로 1tick(단위: sec) 카운트를 증가시키며 약 10s 동안 HIGH 신호를 유지한다. 지정된 시간이 경과하면 초음파 송신이 완료되므로 trig를 다시 0으로 초기화한 뒤 WAIT 상태로 천이된다.

WAIT 상태는 초음파가 물체에 반사되어 돌아오기를 대기하는 과정이다. 이 상태에서는 Echo 신호를 지속적으로 감시하며, echo ==1이 입력되면 반사파가 수신되었다고 판단한다. 이후 거리 측정을 위해 카운터를 초기화하고 RESPONSE 상태로 천이한다.

RESPONSE 상태에서는 Echo 신호가 HIGH를 유지하는 시간을 측정한다. tick_us를 기준으로 tick_cnt 값을 증가시키며 Echo pulse Width를 누적 측정한다. Echo 신호가 LOW로 전환되면 초음파의 왕복 시간이 종료되었다고 판단 후 측정을 종료한다. 측정된 시간값을 기반으로 거리 계산을 수행하며, HC-SR04 데이터 시트에서 제공하는 변환식을 이용하여 distance = tick_cnt /58 연산을 통해 cm 단위 거리값을 계산한다. 거리 계산이 완료되면 FSM은 다시 초기 상태인 IDLE로 복귀하여 다음 측정을 대기한다.

#### 4.1.3 DHT11 SENSOR

##### 4.1.3.1 RTL 설계

<img width="1400" alt="image" src="https://github.com/user-attachments/assets/030e9648-ec8d-4dc2-a2c8-0b5ba552e9e5" />

| 모듈명 | 주요 역할 |
|---|---|
| dht11_unit | DHT11 센서 전체 기능을 묶는 top module |
| dht11_controller | DHT11 통신 제어, FSM 동작, 40bit 데이터 수신 및 checksum 검증 |
| dht11_tick_gen_us | 100MHz clock을 기준으로 1us tick 생성 |
| dht11_fnd_controller | 온도/습도 값을 FND에 표시하기 위한 출력 생성 |

dht11_unit은 외부로부터 i_refresh_req를 입력받아 DHT11 측정을 시작한다. 측정된 결과는 o_temp, o_temp_frac, o_humi, o_humi_frac로 출력되며, checksum 검증 결과는 o_valid로 출력된다. 또한 i_show_humi와 i_show_fahrenheit 신호를 통해 FND에 표시할 값을 선택할 수 있도록 하였다.

###### 4.1.3.1.1 DHT11 ASM

본 ASM은 DHT11의 통신 절차에 따라 측정 요청 대기, START 신호 전송, 센서 응답 확인, 40bit 데이터 수신, bit 판별 및 저장, 수신 완료 순서로 설계하였다. 특히 데이터 수신 과정에서는 HIGH 유지 시간을 기준으로 0과 1을 구분하고, 판별된 bit를 순차적으로 저장하도록 구성하였다.

**DHT11 STATE 설명**

| 상태 | 핵심 동작 |
|---|---|
| IDLE | 측정 시작 요청 대기 |
| START | DATA 라인을 LOW로 내려 DHT11에 start 신호 전송 |
| WAIT | start 신호 이후 DATA 라인을 HIGH로 유지하며 대기 |
| SYNCL | 센서 응답 LOW 구간 확인 |
| SYNCH | 센서 응답 HIGH 구간 확인 |
| DATA_SYNC | 각 bit의 시작 LOW 구간 대기 |
| DATA_COUNT | DATA가 HIGH인 시간을 tick_cnt로 측정 |
| DATA_DECISION | HIGH 시간에 따라 0/1 판별 후 data_reg에 저장 |
| STOP | 40bit 수신 완료 후 IDLE 상태로 복귀 |

### 4.2 Datapath / Control

- 연산 구조 정의
- 상태 제어 로직

#### 4.2.1 Top Module

#### 4.2.2 SR04 SENSOR

##### 4.2.2.1 Datapath 연산구조

| 데이터 구분 | 주체 모듈 | 의미 | 주요 신호 |
|---|---|---|---|
| 송신 경로 (Tx_Path) | sr04_controller | trigger pulse 생성/초음파 송신 제어 | sr04_start, trig |
| 수신 경로 (Rx_Path) | sr04_controller | echo pulse 입력/반사파 수신 시간 측정 | echo |
| Timing Path | tick_gen | 1us 단위 timing clk 생성 | tick_us, clk |
| Distance calculation Path | sr04_controller | echo pulse width 기반 거리 연산 | o_distance_mm |

Data Path는 초음파 송신을 위한 Tx Path와 반사파 수신을 위한 Rx Path를 중심으로 구성된다. tick_gen 모듈에서 생성된 tick_us 신호는 FSM의 timing 기준으로 사용되며, sr04_controller는 이를 기반으로 trigger pulse 생성과 Echo pulse width 측정을 수행한다. 측정된 Echo 유지 시간은 거리 변환 연산에 사용되며 최종적으로 거리 데이터 o_distance_mm 형태로 출력된다.

#### 4.2.3 DHT11 SENSOR

##### 4.2.3.1 Datapath 연산 구조

DHT11 센서 모듈의 datapath는 센서로부터 수신한 40bit 데이터를 저장하고, 이를 온도/습도 데이터와 checksum으로 분리하는 구조로 설계하였다. DHT11은 하나의 DATA 라인을 통해 데이터를 전송하므로, 입력 신호는 동기화 과정을 거친 후 FSM의 제어에 따라 처리된다.

DHT11에서 수신한 bit는 data_reg[39:0]에 순차적으로 저장된다. 각 bit는 DATA 라인의 HIGH 유지 시간을 기준으로 0 또는 1로 판단되며, 판단된 bit는 shift 방식으로 누적된다.

40bit 수신이 완료되면 data_reg는 다음과 같이 분리된다.

**DHT11 Data 범위**

| 데이터 범위 | 의미 | 출력 |
|---|---|---|
| data_reg[39:32] | 습도 정수부 | o_humi |
| data_reg[31:24] | 습도 소수부 | o_humi_frac |
| data_reg[23:16] | 온도 정수부 | o_temp |
| data_reg[15:8] | 온도 소수부 | o_temp_frac |
| data_reg[7:0] | Checksum | o_valid 검증에 사용 |

Checksum 검증은 앞의 4byte를 더한 값과 마지막 checksum byte를 비교하여 수행한다.

Checksum = 습도 정수부 + 습도 소수부 + 온도 정수부 + 온도 소수부

계산된 checksum 값이 수신된 checksum과 일치하면 o_valid = 1이 출력되고, 일치하지 않으면 o_valid = 0이 출력된다.

FND 출력부에서는 i_show_humi와 i_show_fahrenheit 신호에 따라 표시할 데이터를 선택한다. i_show_humi = 1이면 습도 값을 표시하고, i_show_humi = 0이면 온도 값을 표시한다. 온도 표시 상태에서 i_show_fahrenheit = 1이면 섭씨 값을 화씨로 변환하여 FND에 출력한다.

##### 4.2.3.2 Control 상태 제어

DHT11 제어부는 FSM 기반으로 설계하였다. FSM은 DHT11의 통신 순서에 맞추어 start 신호 전송, 센서 응답 확인, 데이터 수신, bit 판별, 수신 완료 단계로 구성된다.

**DHT11 STATE 종류**

| 상태 | 제어 동작 |
|---|---|
| IDLE | 측정 시작 요청 대기 |
| START | DATA 라인을 LOW로 내려 start 신호 전송 |
| WAIT | start 신호 종료 후 센서 응답 전 대기 |
| SYNCL | DHT11 응답 LOW 구간 확인 |
| SYNCH | DHT11 응답 HIGH 구간 확인 |
| DATA_SYNC | 각 bit의 시작 LOW 구간 대기 |
| DATA_COUNT | DATA HIGH 유지 시간 측정 |
| DATA_DECISION | HIGH 시간 기준으로 0/1 판별 후 저장 |
| STOP | 40bit 수신 완료 후 IDLE 복귀 |

FSM은 tick_us 신호를 기준으로 시간 조건을 판단한다. tick_us는 1us 단위의 기준 신호이며, tick_cnt_reg는 각 상태에서 필요한 시간을 측정하는 데 사용된다.

**DHT11 out_sel 동작**

| out_sel_reg | 동작 |
|---|---|
| 1 | FPGA가 DATA 라인 제어 |
| 0 | FPGA가 DATA 라인 제어 해제, 센서 입력 수신 |

DHT11 DATA 라인은 양방향 신호이므로, 제어 로직에서는 out_sel_reg를 이용해 FPGA의 DATA 라인 제어 여부를 결정한다.

### 4.3 Timing 설계

- Critical Path 정의
- Pipeline 분할

#### 4.3.1 SR04 SENSOR Timing diagram

##### 4.3.1.1 SR04 - timing diagram

<img width="305" alt="image" src="https://github.com/user-attachments/assets/2eae144e-1480-4f32-b90a-a467be81be56" />

HC-SR04 Ultrasonic Sensor의 타이밍 다이어그램은 FSM 상태 변화에 따라 초음파 센서의 제어신호와 거리 측정 과정이 어떻게 동작하는지를 나타낸다. 초기 상태인 IDLE에서는 trig와 echo 신호가 모두 LOW인 상태를 유지하며 측정 시작 신호인 sr04_start를 대기한다.

sr04_start 신호가 입력되면 FSM은 START 상태로 천이되며, 초음파 송신을 위해 trig 신호를 HIGH로 출력한다. 이때 tick_us를 기준으로 tick_cnt 값이 증가하며 약 10us 동안 trigger pulse를 유지한다. 지정된 시간이 경과하면 trig를 다시 LOW로 초기화하고 WAIT 상태로 천이한다. WAIT 상태에서는 초음파가 물체에 반사되어 돌아오기를 대기한다. Echo 신호가 LOW 상태를 유지하다가 반사파가 수신되면 echo 신호가 HIGH로 전환되며 FSM은 RESPONSE 상태로 천이한다. 이 과정에서 거리 측정을 위해 tick_cnt 값이 초기화된다.

RESPONSE 상태에서는 echo 신호가 high를 유지하는 동안 tick_us를 기준으로 tick_cnt를 증가시켜 Echo pulse width를 측정한다. 이후 반사파 수신이 종료되어 echo 신호가 LOW로 전환되면 거리측정을 종료하고, 누적된 tick_cnt 값을 기반으로 거리 계산을 수행한다. 계산이 완료되면 FSM은 다시 IDLE 상태로 복귀하여 다음 측정을 대기한다.

#### 4.3.2 DHT11 SENSOR

DHT11 모듈은 센서의 통신 속도가 us/ms 단위로 동작하기 때문에, 센서 자체의 데이터 변화 속도는 FPGA 내부 clock에 비해 매우 느리다. 그러나 RTL 내부에서는 clk 기준으로 상태 전이, 카운터 증가, 데이터 저장, checksum 검증, FND 표시 연산이 수행되므로 각 조합논리 경로의 timing을 고려해야 한다.

**DHT11 timing 구분**

| 구분 | 경로 | 설명 |
|---|---|---|
| FSM 상태 전이 경로 | c_state, tick_cnt_reg, dht11_sync2 → n_state | 현재 상태와 입력 조건을 기준으로 다음 상태를 결정하는 경로 |
| 카운터 경로 | tick_cnt_reg → 비교 연산 → tick_cnt_next | 19ms, 80us, 50us 등의 시간 조건을 판단하는 경로 |
| 데이터 저장 경로 | tick_cnt_reg → 0/1 판별 → data_next | DATA HIGH 유지 시간을 기준으로 bit 값을 판단하고 data_reg에 저장하는 경로 |
| Checksum 검증 경로 | data_reg[39:8] → 덧셈 → 비교 → valid | 수신된 4byte 합과 checksum byte를 비교하는 경로 |
| FND 표시 경로 | 온도/습도 데이터 → 자리수 분리 → BCD 변환 → fnd_data | 수신된 값을 FND 표시용 segment 값으로 변환하는 경로 |

### 4.4 설계 전략 (Design Strategy)

- Timing Optimization
- Low Power Design
- 안정성 확보 (Glitch 방지, CDC 처리 등)

#### 4.4.1 SR04 SENSOR

##### 4.4.1.1 Timing Optimization

sr04는 trig 신호를 일정시간 동안 HIGH로 출력된 뒤, echo 신호가 HIGH로 유지되는 시간을 측정하여 거리값을 계산한다. 따라서 본 설계에서는 tick_us 기준의 counter를 사용하여 trig 유지시간과 echo pulse width를 안정적으로 측정하도록 구성하였다.

FSM은 IDLE -> START -> WAIT -> RESPONSE 순서로 동작하며, 각 상태에서 필요한 counter만 활성화되도록 설계하였다. 이를 통해 불필요한 연산을 줄이고 echo 측정 구간에서는 counter가 정확한 타이밍 기준으로 동작하도록 하였다.

##### 4.4.1.2 Low Power Design

sr04 제어부는 항상 동작하지 않고 sr04_start 신호가 입력되었을 때만 측정을 시작하도록 설계하였다. IDLE 상태에서는 trig 출력과 echo counter 동작을 비활성화하여 불필요한 switching activity를 줄였다. 센서 측정이 필요한 순간에만 counter와 FSM이 활성화되도록 하여 단순하지만 불필요한 동작을 줄이는 방식의 low power 설계를 적용하였다.

##### 4.4.1.3 안정성 확보 (Glitch 방지, CDC 처리 등)

SR04의 echo 신호는 외부 센서에서 입력되는 신호이므로 FPGA 내부 clock과 완전히 동기화되어 있지 않다. 따라서 실제 FPGA 적용시에는 echo 입력에 synchronizer를 적용하여 metastablity 가능성을 감소시켰다.

또한 echo 신호가 정상적으로 들어오지 않을 경우 FSM이 WAIT 또는 RESPONSE 상태에 머무를 수 있으므로 일정시간 이상 echo가 감지되지 않으면 다시 IDLE 상태로 복귀하는 time out 조건을 추가하였다.

#### 4.4.2 DHT11 SENSOR

##### 4.4.2.1 Timing Optimization

DHT11 센서는 us/ms 단위의 timing 조건을 기반으로 동작하므로, 정확한 시간 제어가 중요하다. 이를 위해 본 설계에서는 FPGA의 기준 clock을 직접 사용하여 시간을 계산하지 않고, dht11_tick_gen_us 모듈을 통해 1us 단위의 tick_us 신호를 생성하였다.

DHT11 controller는 tick_us가 1일 때만 tick_cnt_reg를 증가시키며, 이를 기준으로 start 신호 유지 시간, 센서 응답 구간, DATA HIGH 유지 시간을 측정한다. 이 구조를 통해 18ms 이상의 start 신호, 80us 응답 구간, DATA 0/1 판별 시간을 안정적으로 제어할 수 있다.

또한 DATA bit 판별 과정에서는 DATA_COUNT 상태에서 HIGH 유지 시간을 측정하고, DATA_DECISION 상태에서 bit 값을 판단하도록 분리하였다. 시간 측정과 데이터 저장 동작을 상태별로 나누어 설계함으로써 FSM 구조를 단순화하고 timing 분석이 용이하도록 하였다.

##### 4.4.2.2 안정성 확보

DHT11은 FPGA 외부에 연결되는 센서이므로, DATA 신호가 FPGA clock과 동기화되어 있지 않다. 이러한 비동기 입력을 FSM에서 바로 사용할 경우 metastability나 불안정한 상태 전이가 발생할 수 있다.

이를 방지하기 위해 본 설계에서는 dht11_sync1, dht11_sync2를 이용한 2단 싱크로나이저를 적용하였다.

FSM은 원래의 dht11_io 신호를 직접 사용하지 않고, 동기화된 dht11_sync2를 기준으로 상태 전이를 수행한다. 이를 통해 외부 센서 신호를 FPGA clock domain에 맞춰 안정적으로 처리할 수 있도록 하였다.

또한 DHT11 DATA 라인은 하나의 선으로 입력과 출력을 모두 수행하는 양방향 신호이다. 따라서 FPGA와 센서가 동시에 DATA 라인을 제어하면 신호 충돌이 발생할 수 있다. 이를 방지하기 위해 out_sel_reg를 사용하여 DATA 라인의 제어 주체를 구분하였다.

## 5. 시뮬레이션 및 검증 (Simulation & Verification)

### 5.1 Testbench

| 항목 | 확인 내용 |
|---|---|
| tb_decision_unit.v | local 우선순위, context별 action 매핑, refresh/log 정책, ignored sensor command 처리 |
| tb_dht11.v | 40bit 수신, temp/humi 분리, checksum valid 경로 확인 |
| tb_sr04.v | 거리 환산 경로와 대표 거리 케이스 확인 |
| tb_ascii_uart_sensor_pipeline.v | watch status, dht11 status, unknown command, delete/backspace 복원 시나리오 확인 |

| 관련 TB | 확인 결과 |
|---|---|
| context_manager RTL + decision/top 경로 | context 변경은 synchronizer 뒤에서 반영되고 change pulse는 단발 이벤트로 설명 가능 |
| tb_decision_unit.v, tb_ascii_uart_sensor_pipeline.v | status 요청이 log_req, frame 응답, UART response line으로 이어지는 구조를 확인 |
| tb_sr04.v | 20mm 케이스 통과, 4000mm 케이스는 timeout 재조정 필요 |
| tb_dht11.v | TEMP = 25.56, HUMI = 60.34, VALID = 1 확인 |

### 5.2 시뮬레이션 시나리오

#### 5.2.1 Top Module

| 시나리오 | 검증 내용 | 확인 결과 |
|---|---|---|
| 시나리오 1 | local 우선순위와 event dispatch 확인 | tb_decision_unit에서 local input 우선순위와 context별 action mapping 확인 |
| 시나리오 2 | context 변경 후 refresh/log 제어 확인 | sensor context 진입 시 refresh_req와 log_req 생성 구조 확인 |
| 시나리오 3 | status command -> log response 경로 확인 | tb_decision_unit + top 경로에서 status -> log_req -> response 구조 확인 |
| 시나리오 4 | unknown command / delete-backspace 복원 확인 | top TB 기준 response frame 복원 시나리오 확인 |

#### 5.2.2 SR04 SENSOR

| 시나리오 | 검증내용 | 확인결과 |
|---|---|---|
| 시나리오 1 | 측정 시작 신호 입력 후 상태 변화 | sr04_start =1입력시 START 상태로 전이. trig =1로 출력 |
| 시나리오 2 | 초음파 트리거 신호 출력 후 상태 변화 | trig =0으로 하강 이후 일정 시간 유지, echo =1 입력 대기 확인 |
| 시나리오 3 | echo 신호 수신 및 정상 복귀 | echo=1 동안 거리 측정을 위한 카운트 진행. echo=0으로 하강, 복귀 확인 |

#### 5.2.3 DHT11 SENSOR

| 시나리오 | 검증 내용 | 확인 결과 |
|---|---|---|
| 시나리오 1 | DATA 수신 전 상태 변화 | START → SYNCL → SYNCH → DATA_SYNC 확인 |
| 시나리오 2 | DATA 0 수신 | 짧은 HIGH 시간 측정 후 0으로 판단 |
| 시나리오 3 | DATA 1 수신 | 긴 HIGH 시간 측정 후 1로 판단 |
| 시나리오 4 | DATA 저장 | data_reg에 bit 저장 및 bit_cnt_reg 증가 |
| 시나리오 5 | 40bit 수신 완료 | bit_cnt_reg = 39 이후 STOP 상태 이동 |
| 시나리오 6 | checksum 검증 | valid = 1 출력 |
| 시나리오 7 | FND 출력 | 온습도 데이터가 FND 출력으로 반영 |

### 5.3 Waveform 분석

#### 5.3.1 SR04 SENSOR

**측정 시작 신호 입력 후 상태 변화**
<img width="900" alt="image" src="https://github.com/user-attachments/assets/27fc339a-594d-4cec-a9c7-790442098a10" />

해당 파형은 초음파 센서 측정 시작 후 sr04_start 신호가 입력되었을 때 trig 출력 변화를 확인한 결과이다. sr04_start =1 입력 이후 FSM이 IDLE에서 START로 전이되며 초음파 측정 시간을 위한 trig 신호가 1로 활성화되는 것을 확인하였다.

**초음파 트리거 신호 출력 후 상태 변화**
<img width="900" alt="image" src="https://github.com/user-attachments/assets/9527addd-8b9d-4d67-a2d0-d67c5d09b227" />

trig 신호가 1로 활성화되어 초음파 전송이 시작되고 이후 0으로 하강하는 것을 확인하였다. 이후 대기 구간에서 echo가 1로 상승하면 응답 신호 수신으로 판단하며, echo가 다시 0으로 복귀하면 측정을 종료하고 FSM이 초기상태로 돌아가는 것을 확인하였다.

**echo 신호 수신 및 정상 복귀**
<img width="900" alt="image" src="https://github.com/user-attachments/assets/9386d660-616b-4a30-8c55-12f184d3d4cb" />

trig 출력 이후 대기구간에서 echo가 1로 상승하면 반사파 수신으로 판단한다. echo가 0으로 하강하면 거리계산을 수행하고 FSM이 초기상태로 복귀하는 것을 확인하였다.

#### 5.3.2 DHT11 SENSOR

**DATA 수신 전**
<img width="900" alt="image" src="https://github.com/user-attachments/assets/d9779a7c-8498-440c-afd3-6eb7c79a491a" />

해당 파형은 DHT11이 DATA를 전송하기 전, FPGA와 센서의 DATA 라인 제어가 정상적으로 전환되는지 확인한 결과이다.

초기에는 out_sel_reg = 1로 FPGA가 DATA 라인을 제어하여 start 신호를 전송한다. 이후 센서 응답을 받기 위해 out_sel_reg = 0이 되며 FPGA는 DATA 라인 제어를 해제한다.

그 후 io_oe = 1이 되어 testbench의 가상 DHT11 센서가 DATA 라인을 제어하고, 센서 응답 및 데이터 전송이 시작된다.

파형에서 c_state가 START → SYNCL → SYNCH → DATA_SYNC 순서로 변화하므로, start 신호 전송 후 센서 응답을 확인하고 DATA 수신 단계로 정상 진입했음을 확인할 수 있다.

**DATA 0 수신**
<img width="900" alt="image" src="https://github.com/user-attachments/assets/0b40ad0d-4037-4cbc-8493-6eebd2e17bd9" />

해당 파형은 DHT11에서 DATA 0을 수신하는 과정을 확인한 결과이다.

DATA_SYNC 상태에서는 각 bit의 시작 LOW 구간을 기다리고, DATA 신호가 HIGH가 되면 DATA_COUNT 상태로 이동한다.

DATA_COUNT 상태에서는 DATA가 HIGH로 유지되는 시간을 tick_cnt_reg로 측정한다. 파형에서 tick_cnt_reg가 약 26us까지 증가한 후 DATA가 LOW로 내려가므로, 이 bit는 DATA 0으로 판단된다.

**DATA 1 수신**
<img width="900" alt="image" src="https://github.com/user-attachments/assets/50e2882b-98f3-40f9-bd4e-8764139efc1e" />

해당 파형은 DHT11에서 DATA 1을 수신하는 과정을 확인한 결과이다.

DATA_COUNT 상태에서는 DATA 신호가 HIGH로 유지되는 시간을 tick_cnt_reg로 측정한다.

파형에서 DATA가 HIGH 상태를 길게 유지하며, tick_cnt_reg가 약 70us까지 증가한 후 DATA가 LOW로 내려가는 것을 확인할 수 있다.

DHT11은 HIGH 유지 시간이 길면 bit 값을 1로 판단하므로, 해당 구간은 DATA 1 수신 상태로 해석할 수 있다.

**DATA 저장**
<img width="900" alt="image" src="https://github.com/user-attachments/assets/2223ae99-b7f4-4c3c-adea-a2428c3d7acb" />

해당 파형은 DATA_COUNT에서 측정한 HIGH 시간을 기준으로, DATA_DECISION 상태에서 bit 값을 저장하는 과정을 확인한 결과이다.

DATA_COUNT 상태에서 tick_cnt_reg가 약 69us까지 증가했으므로, 기준값보다 긴 HIGH 구간으로 판단된다.

따라서 DATA_DECISION 상태에서 해당 bit를 DATA 1로 판별하고, data_reg의 LSB 방향으로 1이 저장된다.

**DATA 40bit 수신**
<img width="900" alt="image" src="https://github.com/user-attachments/assets/fdcebaea-74b9-40bf-8996-2a9dea777b59" />

해당 파형은 DHT11의 40bit 데이터 수신이 완료된 후 STOP 상태로 이동하는 과정을 확인한 결과이다.

데이터 수신 중에는 DATA_SYNC → DATA_COUNT → DATA_DECISION 상태가 반복되며, 수신된 bit 수는 bit_cnt_reg로 카운트된다.

파형에서 bit_cnt_reg가 39까지 증가한 것을 확인할 수 있다. 이는 0번 bit부터 39번 bit까지, 총 40bit 데이터 수신이 완료되었다는 의미이다.

40bit 수신이 끝나면 FSM은 더 이상 다음 bit를 기다리지 않고 STOP 상태로 이동한다.

**Vaild 확인**
<img width="900" alt="image" src="https://github.com/user-attachments/assets/1cad2c9a-6c45-418a-91cb-9516524aa99b" />

해당 파형은 DHT11의 40bit 데이터 수신이 완료된 후 valid가 1로 출력되는 과정을 확인한 결과이다.

수신된 data_reg 값과 testbench에서 전송한 DATA_STREAM 값이 동일하게 저장되었다.

```
data_reg    = 3C00190055
DATA_STREAM = 3C00190055
```

### 5.4 트러블슈팅
<img width="400" alt="image" src="https://github.com/user-attachments/assets/202d0ad3-132b-4d9e-aab8-b83bf661e830" />
<img width="400" alt="image" src="https://github.com/user-attachments/assets/1f04df5b-1ace-4c27-8860-c5da21a6abb1" />

FPGA 프로그램 후 serial terminal인 screen을 사용하여 ASCII 입력 검증을 수행하였다. screen은 CLI 기반 경량 프로그램으로, 입력값이 실시간으로 표시되지 않고 결과값만 출력된다.

검증 중 명령을 정상 입력했음에도 unk_com 로그가 출력되는 문제가 발생하였다. 원인 분석 결과, Delete 또는 Backspace 입력 시 해당 ASCII Code가 명령 문자열에 포함되어 유효하지 않은 명령으로 처리되는 것을 확인하였다.

이에 따라 입력 데이터에 Delete 및 Backspace ASCII Code가 포함될 경우 무시하도록 예외 처리를 추가하였다. 수정 후 재검증 결과, Delete와 Backspace 입력 이후에도 명령이 정상 동작함을 확인하였다.

## 6. FPGA 결과 동영상

https://youtu.be/VrtHO9WrXKs?si=ZH545mWVWntkPZft

## 7. 결론

이번 UART+FIFO+SENSOR+stopwatch_watch 프로젝트를 통해 이전 stopwatch/watch와 UART LOOPBACK 프로젝트를 기반으로, 로컬 제어 시스템을 원격 제어와 센서 상태 보고까지 가능한 통합 시스템으로 확장할 수 있었다.

최종적으로 ascii_uart_sensor_pipeline top 구조, watch/stopwatch와 sensor의 context 기반 표시, remote command 수신과 event log 응답, sensor latest value 유지, 그리고 단위 testbench와 통합 testbench 기준 검증을 하나의 흐름으로 정리하였다.
