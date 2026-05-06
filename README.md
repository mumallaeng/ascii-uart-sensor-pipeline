English | [한국어](README.ko.md)

# ASCII UART Sensor Pipeline

2026.05.01~2026.05.06

> A project carried out as part of the *[Consortium] On-Device AI System Semiconductor Design, 2nd Cohort* curriculum.

▶ [Demo Video](https://youtu.be/VrtHO9WrXKs?si=LZ4agQC4BuWus110)

<table>
<tr>
<td><img width="420" alt="1_watch" src="https://github.com/user-attachments/assets/0afb560c-f2cb-41e0-9457-b428ca7ca6e3" /><br><strong>Watch mode</strong><br>Time display with local and remote control</td>
<td><img width="420" alt="2_stopwatch" src="https://github.com/user-attachments/assets/8296ab21-5c27-4957-a155-201a11fee898" /><br><strong>Stopwatch mode</strong><br>Start, stop, reset, and UART control</td>
</tr>
<tr>
<td><img width="420" alt="3_dht11" src="https://github.com/user-attachments/assets/f2ced895-1c53-4a81-82f3-c23c49742243" /><br><strong>DHT11</strong><br>Temperature/humidity display and UART output</td>
<td><img width="420" alt="4_sr04" src="https://github.com/user-attachments/assets/36209465-2c2a-4196-829f-4bbfb9b43fbc" /><br><strong>SR04</strong><br>Ultrasonic distance display and UART output</td>
</tr>
</table>

| Member | Responsibility |
|---|---|
| Yeonwoo Gim ([@mumallaeng](https://github.com/mumallaeng)) | Integration and verification of top `remote_input_unit` |
| Gyeongmin Park ([@gyeongminbag27-arch](https://github.com/gyeongminbag27-arch)) | Integration and verification of the SR04 ultrasonic sensor |
| Jimin Yu ([@jimin-max](https://github.com/jimin-max)) | Integration and verification of the DHT11 temperature/humidity sensor |

## 1. Overview

### 1.1 Purpose and Goals

The purpose of this project is to integrate the functionality that had been separated across the previous stopwatch/watch and UART LOOPBACK assignments into a single FPGA system. The final goal is to run watch/stopwatch, UART/FIFO, SR04, and DHT11 simultaneously on a Basys 3 board, and to unify local button/switch input and remote UART commands under a single control scheme.

The core goals are as follows:

- Integrate functionality into a single top module.
- Normalize local and remote input into the same canonical event.
- Build a structure that outputs to the FND and a UART log at the same time.
- Keep sensor values at their latest reading regardless of the current display context.

<img width="1118" alt="Purpose" src="https://github.com/user-attachments/assets/80aecc92-f39a-4999-9a6d-bd992886136b" />

<img width="1095" alt="Goals" src="https://github.com/user-attachments/assets/dc088cd6-5606-41ac-b53a-0c00296a7095" />

### 1.2 Design Scope

- ascii_uart_sensor_pipeline top integration
- Retaining watch/stopwatch functionality
- UART RX/TX, FIFO buffer, ASCII command parsing/log formatting
- SR04 distance sensor integration
- DHT11 temperature/humidity sensor integration
- Context-based FND output
- Verification based on unit TBs and an integrated TB

### 1.3 Project Summary

This project extends the local-display-centered structure of the Timepiecer line beyond the UART LOOPBACK stage, resulting in an integrated system that also handles external command input and sensor status reporting.

The final top module is ascii_uart_sensor_pipeline, and the current structure is organized into three stages: INPUT / CONTROL / OUTPUT.

- **INPUT**: Button conditioning, context selection, UART command reception
- **CONTROL**: Event interpretation, action dispatch, sensor refresh control
- **OUTPUT**: FND display, ASCII event log transmission

### 1.4 Specification Summary

| Item | Details |
|---|---|
| FPGA board | Digilent Basys 3 |
| System clock | 100 MHz |
| UART baseline | 9600 bps, 16x oversampling |
| FIFO | 4-depth byte buffer |
| Sensor interface | SR04 (JA), DHT11 (JB) |
| Display device | 4-digit FND, LED |
| Top module | ascii_uart_sensor_pipeline |

## 2. Project Management

### 2.1 Schedule

| Stage | Period | Key Tasks |
|---|---|---|
| Requirements review | 2026.05.01 | Defined integration criteria for existing watch/stopwatch, UART, SR04, DHT11 |
| Architecture design | 2026.05.02 | Organized the INPUT/CONTROL/OUTPUT structure and context/UI rules |
| RTL integration | 2026.05.03 ~ 2026.05.05 | Wired up the top module, remote I/O, display, and sensor latest-value paths |
| Verification hardening | 2026.05.05 | Organized tb_decision_unit, tb_dht11, tb_sr04, and the top TB |
| Documentation | 2026.05.06 | Organized presentation materials, schedule, dev log, and completion report |

### 2.2 Development Environment

| Category | Technology |
|---|---|
| Version control | Git |
| Documentation | Microsoft Word, PowerPoint, Excel, Markdown |
| Collaboration materials | Google Drive shared deliverables |
| Verification logs | Icarus Verilog run results, Vivado project files |

### 2.3 Design Environment

| Category | Details |
|---|---|
| Language | Verilog HDL |
| FPGA | Digilent Basys 3 (Artix-7 XC7A35T) |
| EDA | Vivado 2020.2 |
| Simulator | Vivado XSim, Icarus Verilog |

## 3. Architecture

### 3.1 System Structure

#### 3.1.1 Top Module

<img width="2171" alt="top  ascii_uart_sensor_pipeline-lv2 drawio" src="https://github.com/user-attachments/assets/4d613e6c-a3fb-4218-9f9a-25e4c9343482" />

As of the current main branch, the top module's direct children are the following 7:

- input_conditioning
- context_manager
- remote_input_unit
- decision_unit
- execute_unit
- display_unit
- remote_output_unit

Grouped by function, they can be organized as follows:

| Category | Modules | Role |
|---|---|---|
| INPUT | input_conditioning, context_manager, remote_input_unit | Conditioning button pulses, resolving switch context, receiving UART commands |
| CONTROL | decision_unit, execute_unit | Resolving input priority, dispatching actions, executing watch/stopwatch/sensor logic |
| OUTPUT | display_unit, remote_output_unit | FND display, UART log transmission |

The ascii_uart_sensor_pipeline top module is the upper-level wrapper that integrates local input, remote UART input, watch/stopwatch state, SR04/DHT11 latest values, FND display, and UART log transmission into a single layer. The upper structure can be explained by splitting input_conditioning, context_manager, and remote_input_unit into INPUT; decision_unit and execute_unit into CONTROL; and display_unit and remote_output_unit into OUTPUT.

context_manager determines WATCH, STOPWATCH, SR04, DHT11, and their sub-views based on sw[1:0] and sw15, while decision_unit normalizes local pulses and remote commands into the same canonical event. execute_unit maintains watch/stopwatch state and sensor latest values, and display_unit selects and outputs the representative value for the current context to the FND.

The UART log output was designed so that when a status or event log request comes in, log_entry_collector inside remote_output_unit gathers the SRC, CMD, EVT, CTX, ACT metadata together with the WT, SW, SR04, and DHT11 latest status; ascii_log_formatter computes only the single ASCII character corresponding to the current byte index; and log_byte_sender pushes it sequentially into uart_tx_fifo. In other words, the FND shows the representative value for the current context while UART emits the current system state as an ASCII log — giving the system a dual-output structure.

**INPUT block**

<img width="1617" alt="INPUT_block_diagram" src="https://github.com/user-attachments/assets/da7982b7-ce0a-4bd2-8b70-db3512a164fc" />

| Module | Role |
|---|---|
| input_conditioning | Conditions local button input into short/hold pulses |
| context_manager | Determines the current context and sensor view |
| remote_input_unit | Converts UART ASCII commands into internal command pulses |
| uart_rx_fifo | The RX boundary that turns serial rx into an ASCII byte stream |
| ascii_command_parser | Resolves a multi-byte ASCII command into a CMD_* token |
| cmd_token_pulser | Converts a CMD_* token into a 1-cycle command pulse |

<img width="1618" alt="INPUT_ascii_command_parser" src="https://github.com/user-attachments/assets/11a5db06-d9ae-472e-b550-97f6800e3acd" />
<img width="4180" alt="INPUT_ascii_command_parser-ASM" src="https://github.com/user-attachments/assets/ecfcf5bd-fe44-48a2-8210-b49543364023" />

<img width="1430" alt="INPUT_RTL_1" src="https://github.com/user-attachments/assets/5b9e0a1b-f086-47f6-bd21-a3c1bbc34b69" />
<img width="1567" alt="INPUT_RTL_2" src="https://github.com/user-attachments/assets/87b65ab7-d8c9-46e7-a914-6ab6c3ce05d9" />

<img width="1224" alt="remote_input_unit" src="https://github.com/user-attachments/assets/d03be2f2-ec9e-419b-a77b-68d8828f1734" />


<br/>
<br/>
<br/>

**CONTROL block**

<img width="1579" alt="CONTROL_block_diagram" src="https://github.com/user-attachments/assets/4b819c54-06a8-4bff-ae1d-3dbdb27e69a8" />

| Module | Role |
|---|---|
| decision_unit | The policy block that translates input into control meaning for the current context |
| execute_unit | The execution block that produces the actual time functions and sensor latest values |
| event_selector | The block that resolves local/remote input into a canonical event |
| action_dispatcher | The block that dispatches a canonical event into a watch/stopwatch/sensor action |
| watch_stopwatch_unit | The time-function block that actually produces watch and stopwatch state |
| sr04_unit | The block that produces the ultrasonic sensor's latest distance and FND candidate |
| dht11_unit | The block that produces the temperature/humidity sensor's latest values and FND candidate |

<img width="1575" alt="CONTROL_decision_RTL_1" src="https://github.com/user-attachments/assets/1243582b-c9d1-4445-a90c-1bff18e06d1d" />
<img width="1570" alt="CONTROL_decision_RTL_2" src="https://github.com/user-attachments/assets/aab4dace-72ec-4ab7-8f62-c8ce31efec7f" />
<img width="1523" alt="CONTROL_excute_RTL_1" src="https://github.com/user-attachments/assets/05e1ff72-3908-48e7-940e-6b44833b3d8d" />


<br/>
<br/>
<br/>

**OUTPUT block**

<img width="1672" alt="OUTPUT_block_diagram" src="https://github.com/user-attachments/assets/a5488ea2-56a2-476f-8a31-3f729acead5f" />

| Module | Role |
|---|---|
| display_unit | The block that makes the final selection of the FND candidate for the current context |
| remote_output_unit | The block that emits the latest status and log metadata as a UART status log |
| log_entry_collector | The block that gathers the latest values and metadata needed for one status log entry |
| ascii_log_formatter | The block that converts status information into ASCII log bytes |
| uart_tx_unit | The block that hands ASCII log bytes off to the actual UART TX boundary |
| log_byte_sender | The FSM block that pushes the log one byte at a time, in order |

<img width="1774" alt="OUTPUT-log_byte_sender-FSM" src="https://github.com/user-attachments/assets/f21c3cec-c972-469f-a4b1-11c8536a5384" />
<img width="1536" alt="OUTPUT_log_byte_sender-ASM" src="https://github.com/user-attachments/assets/63f3f0c4-6e2b-4d00-99d1-0ad5366bdc9b" />

<br/>
<br/>
<br/>

#### 3.1.2 SR04 Sensor

<img width="596" alt="SR04_BlockDiagram" src="https://github.com/user-attachments/assets/df68deee-0eca-4cda-a0c9-4da355fc8b8c" />

In this design, the SR04 ultrasonic sensor is organized as one independent functional block, SR04_UNIT. SR04_UNIT communicates directly with the SR04 ultrasonic sensor to measure the distance to an object and outputs the measured data to the FND panel.

The HC-SR04 sensor operates based on the TRIG and ECHO signals.

The FPGA outputs a HIGH pulse of about 10us on the TRIG pin to start ultrasonic transmission, and the sensor emits a 40kHz ultrasonic pulse. Once the ultrasonic wave reflects off an object and returns, the sensor holds the ECHO pin HIGH. The hold time of the ECHO signal is proportional to the round-trip time of the ultrasonic wave, and the FPGA measures that pulse width to calculate the distance.

The calculated distance value is passed to the FND output module through the internal control logic, allowing the user to check distance information in real time.

On the SR04 sensor, the transmit and receive signals for sending the ultrasonic wave and receiving it back are separated into tx and rx ports.

**SR04_Controller I/O Table**

| Signal | Direction | Width | Details | Connection |
|---|---|---|---|---|
| clk | Input | 1bit | System clock signal | FPGA system clock |
| rst | Input | 1bit | System reset signal | Reset control |
| refresh_req | Input | 1bit | Request signal to start a distance measurement | remote_unit |
| echo | Input | 1bit | Pin on which the reflected ultrasonic signal returns | HC-SR04-TRIG |
| trig | Output | 1bit | Trigger signal output for ultrasonic transmission | HC-SR04 TRIG |
| fnd_com | Output | 4bit | FND digit-select control signal | 7-segment FND |
| fnd_data | Output | 8bit | FND segment data output signal | 7-segment FND |

- Data flow definition: refresh_req input -> send sr04_start signal -> send tick_us until tick_cnt reaches 10 -> echo signal returns -> distance measured -> back to idle

#### 3.1.3 DHT11 Sensor

<img width="521" alt="DHT11_BlockDiagram" src="https://github.com/user-attachments/assets/6b0a1e46-08cb-4165-832d-85965e648636" />

In this design, the DHT11 temperature/humidity sensor is organized as one independent functional block, DHT11_UNIT. DHT11_UNIT communicates directly with the DHT11 sensor to receive temperature and humidity data, and separates the received data into integer and fractional parts for output. It also verifies the checksum of the received data to judge its validity, and generates the output signals needed to display the measured values on the FND.

The DHT11 sensor performs bidirectional communication with the FPGA over a single DATA line. Accordingly, dht11_io was designed as an inout signal: it is used as an output when the FPGA sends the start signal to the sensor, and as an input when the sensor transmits data.

**DHT11 I/O Definition**

| Category | Signal | Bits | Description |
|---|---|---|---|
| Input | i_refresh_req | 1bit | Request signal to start a DHT11 measurement |
| Input | i_show_humi | 1bit | Signal selecting humidity display |
| Input | i_show_fahrenheit | 1bit | Signal selecting Fahrenheit display |
| Inout | dht11_io | 1bit | DHT11 DATA bidirectional communication signal |
| Output | o_temp | 8bit | Temperature integer part |
| Output | o_temp_frac | 8bit | Temperature fractional part |
| Output | o_humi | 8bit | Humidity integer part |
| Output | o_humi_frac | 8bit | Humidity fractional part |
| Output | o_valid | 1bit | Checksum verification result |
| Output | o_fnd_com | 4bit | FND digit-select signal |
| Output | o_fnd_data | 8bit | FND segment output signal |

- Data flow definition: i_refresh_req input → send DHT11 start signal → receive 40 bits of data over dht11_io → split into temperature/humidity integer and fractional parts → verify checksum → output valid data → generate FND output according to the display mode

### 3.2 Theory & Background

#### 3.2.1 Top Module

The ascii_uart_sensor_pipeline top module is the upper-level wrapper that integrates local input, remote UART input, watch/stopwatch state, SR04/DHT11 latest values, FND display, and UART log transmission into a single layer. The upper structure can be explained by splitting input_conditioning, context_manager, and remote_input_unit into INPUT; decision_unit and execute_unit into CONTROL; and display_unit and remote_output_unit into OUTPUT.

context_manager determines WATCH, STOPWATCH, SR04, DHT11, and their sub-views based on sw[1:0] and sw15, while decision_unit normalizes local pulses and remote commands into the same canonical event. execute_unit maintains watch/stopwatch state and sensor latest values, and display_unit selects and outputs the representative value for the current context to the FND.

The UART log output was designed so that when a status or event log request comes in, log_entry_collector inside remote_output_unit first gathers the SRC, CMD, EVT, CTX, ACT metadata together with the WT, SW, SR04, and DHT11 latest status into a single snapshot; ascii_log_formatter computes only the single ASCII character corresponding to the current byte index; and log_byte_sender pushes it sequentially into uart_tx_fifo. In other words, the FND shows the representative value for the current context while UART emits the current system state as an ASCII log — giving the system a dual-output structure.

Here, the UART response format was fixed to a line-oriented ASCII format of `field=value<LF>`, so that a person can read it directly from a serial terminal, and a TB or ILA can also verify the byte order directly. Once a single status request is accepted, the context, action result, watch/stopwatch values, and sensor latest values at the moment the command was accepted are bundled into a single response frame and transmitted, so in integrated verification this log serves as direct evidence of the design's behavior.

An example of the log output is as follows. For a status request, the current main and top TB use the following abbreviated, line-oriented ASCII response.

<img width="245" alt="event-log" src="https://github.com/user-attachments/assets/669f4f79-5dbb-43b3-bd7e-75010f116c33" />

In the example above, SRC means the input source, CMD the raw text of the received command, and EVT the canonical event normalized by decision_unit. CTX means the active context at the moment the log was captured, ACT the actual execution result, WT and SW the watch and stopwatch snapshots, and SR04 and DHT11 the latest sensor values at that moment. From a verification standpoint, the key points to check are therefore whether a single status request leads to exactly one such complete snapshot, and whether that same snapshot is maintained until the last byte is transmitted.

To fix the log interpretation criteria, the allowed values for CMD alias, EVT, and ACT were defined as follows.

#### 3.2.2 SR04 Sensor

**SR04 Pinmap**

<img width="304" alt="SR04-PINMAP" src="https://github.com/user-attachments/assets/c2e20cf4-c98d-42a4-bd09-0596046e0abb" />

| Pin No. | Pin Name | Details |
|---|---|---|
| 1 | vcc | VCC power pin (Max: 5V) |
| 2 | Trigger | Emits an ultrasonic pulse when the FPGA board applies a HIGH signal to the Trigger pin for 10us. |
| 3 | Echo | Held HIGH while the transmitted ultrasonic wave reflects off an object and returns to the sensor. Distance is calculated from the duration of the HIGH interval. |
| 4 | Ground | Serves as the reference voltage |

##### 3.2.2.1 SR04 Pinmap Structure

<img width="438" alt="SR04-signal" src="https://github.com/user-attachments/assets/055ab2a6-41da-4e85-be0c-ee74142b4f73" />

This design uses the HC-SR04 ultrasonic sensor to measure the distance to an object. The SR04 sensor operates by measuring the time between sending an ultrasonic wave and receiving its reflection to calculate distance. The FPGA drives the sensor via the Trigger signal and calculates distance by measuring the HIGH hold time of the Echo signal.

The SR04 sensor starts a distance measurement once a HIGH pulse of 10us or more is applied to the Trigger pin. Internally, the sensor sends an 8-cycle burst of 40kHz ultrasonic waves and receives the signal that reflects back off an object. After the ultrasonic wave is sent, the echo pin goes HIGH, and switches back to LOW once the wave returns to the sensor. The HIGH hold time of the Echo pin is therefore proportional to the round-trip time of the ultrasonic wave.

The FPGA measures the HIGH time of the Echo pin in microseconds and uses it to calculate the distance to the object.

The distance calculation formula provided in the datasheet is as follows.

$$
Distance(cm) = \frac{Echo pulse width(us)}{58}
$$

Based on this formula, the distance between the object and the ultrasonic sensor is measured.

#### 3.2.3 DHT11 Sensor

##### 3.2.3.1 DHT11 Circuit Connection Structure

<img width="495" alt="image" src="https://github.com/user-attachments/assets/930daa07-8d9c-4711-b44f-36718a4b4422" />

DHT11 is a digital sensor that measures temperature and humidity, converting the internally measured values into digital data before passing them to an external device. It communicates over a single DATA line, transmitting temperature and humidity information in a 40-bit data format.

The DHT11 sensor communicates with the FPGA over a single DATA line. Since the DATA line must normally be held HIGH, a pull-up resistor of about 5kΩ is connected between VDD and DATA.

Because the DATA line is bidirectional, the FPGA and the DHT11 must not drive the DATA line at the same time. Accordingly, the FPGA drives the DATA line directly only while sending the start signal, and switches to a High-Z state afterward so the sensor can drive the DATA line.

##### 3.2.3.2 DHT11 Operating Principle

<img width="712" alt="image" src="https://github.com/user-attachments/assets/49c09790-7172-40f5-baaa-0cc3b40ce6cd" />

The DHT11 communication process is broadly divided into three stages: sending the start signal, the sensor's response, and data transmission.

First, the FPGA pulls the DATA line LOW to signal the start of a measurement to the DHT11 sensor. This LOW signal must be held for at least about 18ms, after which the DATA line is pulled back HIGH while the FPGA waits for the sensor's response.

Once the sensor detects the start signal, it sends a response signal. The DHT11 first holds the DATA line LOW for about 80us, then HIGH for about 80us. This response signal lets the FPGA confirm that the sensor has begun communication normally.

After the response signal, actual data transmission begins. The DHT11 transmits a total of 40 bits of data, with each bit consisting of a LOW interval followed by a HIGH interval. Each bit first holds LOW for about 50us, after which the HIGH hold time determines whether the bit is 0 or 1.

**DHT11 DATA Bit Discrimination**

| Category | LOW Interval | HIGH Interval | Meaning |
|---|---|---|---|
| DATA 0 | ~50us | ~26-28us | Bit value 0 |
| DATA 1 | ~50us | ~70us | Bit value 1 |

##### 3.2.3.3 40-bit Data Composition and Checksum Verification

The DHT11 sensor transmits the measured temperature and humidity data as a total of 40 bits of digital data. This data is divided into 8-bit units, consisting of humidity information, temperature information, and a checksum for data verification.

**DHT11 Bit Composition**

| Category | Bits | Meaning |
|---|---|---|
| Humidity integer part | 8bit | Integer portion of the humidity value |
| Humidity fractional part | 8bit | Fractional portion of the humidity value |
| Temperature integer part | 8bit | Integer portion of the temperature value |
| Temperature fractional part | 8bit | Fractional portion of the temperature value |
| Checksum | 8bit | Value used to verify the received data |

The checksum is used to verify whether the data was received correctly, by comparing the sum of the preceding 4 bytes against the checksum byte sent last by the sensor. If the computed checksum value matches the received checksum value, the data is judged to have been received correctly; if not, it is judged to be a communication error or data corruption.

## 4. Detailed Design

### 4.1 RTL Design

- Module composition
- Description of the main structure (flowchart or ASM, etc.)

#### 4.1.1 Top Module

<img width="1704" alt="TOP_RTL_01" src="https://github.com/user-attachments/assets/54ba419a-8db0-4444-a2c0-137ed981d02a" />

<img width="1400" alt="TOP_RTL_02" src="https://github.com/user-attachments/assets/86e18524-7a7c-444b-bd87-62bcde4401e8" />
<img width="1343" alt="TOP_RTL_03" src="https://github.com/user-attachments/assets/348c0a4d-f15f-48ef-88c8-3668721f42ac" />
<img width="1447" alt="TOP_RTL_04" src="https://github.com/user-attachments/assets/9db8b010-5b6b-42b1-9971-6df45b22d98b" />
<img width="1367" alt="TOP_RTL_05" src="https://github.com/user-attachments/assets/85acbd7a-ff25-46f2-af22-ed47c5dc33b1" />

The overall structure was confirmed through top module RTL schematics 1-4.

#### 4.1.2 SR04 Sensor

##### 4.1.2.1 RTL Design


<img width="1400" alt="image" src="https://github.com/user-attachments/assets/d50047dc-6ff4-4488-9d07-e74d9e8158e7" />


| Module | Details |
|---|---|
| U_TICK_GEN | The module that generates the tick |
| U_SR04_CNTL | The main module that controls the ultrasonic sensor |
| U_FND_CNTL | The module that connects the FND segment section with SR04_CNTL |

As shown in the table, the SR04 circuit is composed of a total of 3 modules.

##### 4.1.2.2 FSM State Diagram

| State | Behavior |
|---|---|
| IDLE | The initial state; after trig = 0 is applied, transitions to START once sr04_start == 1. |
| START | After trig = 1 is applied, ultrasonic transmission begins. The count is incremented based on tick_us. Once tick_cnt == 11, it transitions to WAIT. |
| WAIT | Waits for the Echo signal. Once echo == 1, tick_cnt is set to 0, after which it transitions to RESPONSE. |
| RESPONSE | While echo = 1, tick_cnt is incremented based on tick_us to measure the Echo pulse width. Once echo == 0, measurement ends, the operation distance = tick_cnt/58 is performed, and it returns to IDLE. |

The FSM of the HC-SR04 Ultrasonic Sensor was built to control the sensor's distance-measurement process in stages. In the initial IDLE state, the trig signal is held at 0 while waiting for the sr04_start input that starts sensor operation. Once the condition sr04_start == 1 is satisfied and the sr04_start signal is activated, it transitions to the START state.

In the START state, trig is driven to 1 to generate the ultrasonic transmission. The count is then incremented by 1 tick (unit: sec) based on the tick_us signal, holding the HIGH signal for about 10us. Once the specified time has elapsed, ultrasonic transmission is complete, so trig is reset back to 0 and it transitions to WAIT.

The WAIT state is the process of waiting for the ultrasonic wave to reflect off an object and return. In this state, the Echo signal is continuously monitored, and once echo == 1 is applied, the reflected wave is judged to have been received. The counter is then reset for distance measurement, and it transitions to RESPONSE.

In the RESPONSE state, the duration for which the Echo signal is held HIGH is measured. The tick_cnt value is incremented based on tick_us to accumulate the Echo pulse width. Once the Echo signal switches to LOW, the round-trip time of the ultrasonic wave is judged to have ended and measurement stops. Distance calculation is then performed based on the measured time value, using the conversion formula provided in the HC-SR04 datasheet, distance = tick_cnt / 58, to calculate the distance in cm. Once the distance calculation is complete, the FSM returns to the initial IDLE state to wait for the next measurement.

#### 4.1.3 DHT11 Sensor

##### 4.1.3.1 RTL Design

<img width="1400" alt="image" src="https://github.com/user-attachments/assets/030e9648-ec8d-4dc2-a2c8-0b5ba552e9e5" />

| Module | Main Role |
|---|---|
| dht11_unit | The top module that ties together all DHT11 sensor functionality |
| dht11_controller | DHT11 communication control, FSM operation, 40-bit data reception, and checksum verification |
| dht11_tick_gen_us | Generates a 1us tick based on the 100MHz clock |
| dht11_fnd_controller | Generates the output used to display the temperature/humidity values on the FND |

dht11_unit receives i_refresh_req from outside and starts a DHT11 measurement. The measured results are output as o_temp, o_temp_frac, o_humi, and o_humi_frac, and the checksum verification result is output as o_valid. It also lets the value shown on the FND be selected via the i_show_humi and i_show_fahrenheit signals.

###### 4.1.3.1.1 DHT11 ASM

This ASM was designed following the DHT11 communication procedure in the order: waiting for a measurement request, sending the START signal, confirming the sensor's response, receiving 40 bits of data, discriminating and storing each bit, and completing reception. In particular, during data reception, bits are distinguished as 0 or 1 based on the HIGH hold time, and the discriminated bits are stored sequentially.

**DHT11 STATE Description**

| State | Core Behavior |
|---|---|
| IDLE | Waits for a measurement start request |
| START | Pulls the DATA line LOW to send the start signal to the DHT11 |
| WAIT | After the start signal, holds the DATA line HIGH while waiting |
| SYNCL | Confirms the sensor response's LOW interval |
| SYNCH | Confirms the sensor response's HIGH interval |
| DATA_SYNC | Waits for the LOW interval that starts each bit |
| DATA_COUNT | Measures the time DATA is HIGH using tick_cnt |
| DATA_DECISION | Discriminates 0/1 based on the HIGH time and stores it in data_reg |
| STOP | Returns to IDLE once 40-bit reception is complete |

### 4.2 Datapath / Control

- Definition of the computation structure
- State control logic

#### 4.2.1 Top Module

#### 4.2.2 SR04 Sensor

##### 4.2.2.1 Datapath Structure

| Data Category | Owning Module | Meaning | Main Signals |
|---|---|---|---|
| Transmit path (Tx_Path) | sr04_controller | Trigger pulse generation / ultrasonic transmission control | sr04_start, trig |
| Receive path (Rx_Path) | sr04_controller | Echo pulse input / measuring the reflected-wave receive time | echo |
| Timing path | tick_gen | Generates the 1us-unit timing clock | tick_us, clk |
| Distance calculation path | sr04_controller | Distance computation based on the echo pulse width | o_distance_mm |

The data path centers on the Tx path for ultrasonic transmission and the Rx path for reflected-wave reception. The tick_us signal generated in the tick_gen module is used as the FSM's timing reference, and sr04_controller uses it to generate the trigger pulse and measure the Echo pulse width. The measured Echo hold time is used in the distance-conversion computation and is ultimately output as the distance data o_distance_mm.

#### 4.2.3 DHT11 Sensor

##### 4.2.3.1 Datapath Structure

The datapath of the DHT11 sensor module was designed to store the 40-bit data received from the sensor and split it into temperature/humidity data and a checksum. Since the DHT11 transmits data over a single DATA line, the input signal is processed under FSM control after going through a synchronization step.

Bits received from the DHT11 are stored sequentially in data_reg[39:0]. Each bit is judged as 0 or 1 based on the HIGH hold time of the DATA line, and the judged bits are accumulated by shifting.

Once 40-bit reception is complete, data_reg is split as follows.

**DHT11 Data Ranges**

| Data Range | Meaning | Output |
|---|---|---|
| data_reg[39:32] | Humidity integer part | o_humi |
| data_reg[31:24] | Humidity fractional part | o_humi_frac |
| data_reg[23:16] | Temperature integer part | o_temp |
| data_reg[15:8] | Temperature fractional part | o_temp_frac |
| data_reg[7:0] | Checksum | Used for o_valid verification |

Checksum verification is performed by comparing the sum of the preceding 4 bytes against the last checksum byte.

Checksum = humidity integer part + humidity fractional part + temperature integer part + temperature fractional part

If the computed checksum value matches the received checksum, o_valid = 1 is output; if not, o_valid = 0 is output.

The FND output stage selects which data to display based on the i_show_humi and i_show_fahrenheit signals. If i_show_humi = 1, the humidity value is shown; if i_show_humi = 0, the temperature value is shown. In the temperature-display state, if i_show_fahrenheit = 1, the Celsius value is converted to Fahrenheit before being output to the FND.

##### 4.2.3.2 Control State Management

The DHT11 control section was designed on an FSM basis. The FSM is composed of stages matching the DHT11 communication order: sending the start signal, confirming the sensor response, receiving data, discriminating bits, and completing reception.

**DHT11 STATE Types**

| State | Control Behavior |
|---|---|
| IDLE | Waits for a measurement start request |
| START | Pulls the DATA line LOW to send the start signal |
| WAIT | Waits after the start signal ends, before the sensor responds |
| SYNCL | Confirms the DHT11 response's LOW interval |
| SYNCH | Confirms the DHT11 response's HIGH interval |
| DATA_SYNC | Waits for the LOW interval that starts each bit |
| DATA_COUNT | Measures the DATA HIGH hold time |
| DATA_DECISION | Discriminates 0/1 based on the HIGH time and stores it |
| STOP | Returns to IDLE once 40-bit reception is complete |

The FSM judges timing conditions based on the tick_us signal. tick_us is a 1us-unit reference signal, and tick_cnt_reg is used to measure the time needed at each state.

**DHT11 out_sel Behavior**

| out_sel_reg | Behavior |
|---|---|
| 1 | The FPGA drives the DATA line |
| 0 | The FPGA releases control of the DATA line, receiving sensor input |

Since the DHT11 DATA line is bidirectional, the control logic uses out_sel_reg to decide whether the FPGA is driving the DATA line.

### 4.3 Timing Design

- Definition of critical paths
- Pipeline partitioning

#### 4.3.1 SR04 Sensor Timing Diagram

##### 4.3.1.1 SR04 - Timing Diagram

<img width="305" alt="image" src="https://github.com/user-attachments/assets/2eae144e-1480-4f32-b90a-a467be81be56" />

The timing diagram of the HC-SR04 Ultrasonic Sensor shows how the sensor's control signals and distance-measurement process behave according to the FSM state changes. In the initial IDLE state, both the trig and echo signals are held LOW while waiting for the sr04_start measurement-start signal.

Once the sr04_start signal is applied, the FSM transitions to START and drives the trig signal HIGH to transmit the ultrasonic wave. At this point, the tick_cnt value increases based on tick_us, holding the trigger pulse for about 10us. Once the specified time has elapsed, trig is reset back to LOW and it transitions to WAIT. In the WAIT state, it waits for the ultrasonic wave to reflect off an object and return. While the Echo signal stays LOW, once the reflected wave is received the echo signal switches to HIGH and the FSM transitions to RESPONSE. During this process, the tick_cnt value is reset for distance measurement.

In the RESPONSE state, while the echo signal stays high, tick_cnt is incremented based on tick_us to measure the Echo pulse width. Once reflected-wave reception ends and the echo signal switches to LOW, distance measurement stops, and distance calculation is performed based on the accumulated tick_cnt value. Once the calculation is complete, the FSM returns to IDLE to wait for the next measurement.

#### 4.3.2 DHT11 Sensor

Because the DHT11 module's communication speed operates on the order of us/ms, the sensor's own data-change rate is very slow compared to the FPGA's internal clock. However, since state transitions, counter increments, data storage, checksum verification, and FND-display computation are all performed on the clk basis inside the RTL, the timing of each combinational-logic path must still be considered.

**DHT11 Timing Categories**

| Category | Path | Description |
|---|---|---|
| FSM state-transition path | c_state, tick_cnt_reg, dht11_sync2 → n_state | The path that decides the next state based on the current state and input conditions |
| Counter path | tick_cnt_reg → comparison → tick_cnt_next | The path that judges time conditions such as 19ms, 80us, 50us |
| Data-storage path | tick_cnt_reg → 0/1 discrimination → data_next | The path that judges a bit value based on the DATA HIGH hold time and stores it in data_reg |
| Checksum-verification path | data_reg[39:8] → addition → comparison → valid | The path that compares the sum of the received 4 bytes against the checksum byte |
| FND-display path | temperature/humidity data → digit split → BCD conversion → fnd_data | The path that converts the received value into segment values for FND display |

### 4.4 Design Strategy

- Timing optimization
- Low-power design
- Ensuring stability (glitch prevention, CDC handling, etc.)

#### 4.4.1 SR04 Sensor

##### 4.4.1.1 Timing Optimization

The SR04 outputs the trig signal HIGH for a set duration, then measures how long the echo signal stays HIGH to calculate the distance. Accordingly, this design uses a tick_us-based counter to reliably measure the trig hold time and the echo pulse width.

The FSM operates in the order IDLE -> START -> WAIT -> RESPONSE, and was designed so that only the counter needed at each state is active. This reduces unnecessary computation and ensures the counter operates on an accurate timing reference during the echo-measurement interval.

##### 4.4.1.2 Low-Power Design

The SR04 control section does not run at all times; it was designed to start a measurement only when the sr04_start signal is applied. In the IDLE state, the trig output and echo counter operation are disabled to reduce unnecessary switching activity. By activating the counter and FSM only at the moment a sensor measurement is needed, a simple but effective low-power design that reduces unnecessary activity was applied.

##### 4.4.1.3 Ensuring Stability (Glitch Prevention, CDC Handling, etc.)

Since the SR04's echo signal is an externally applied sensor signal, it is not fully synchronized with the FPGA's internal clock. Accordingly, a synchronizer was applied to the echo input for actual FPGA deployment to reduce the possibility of metastability.

In addition, since the FSM could remain stuck in WAIT or RESPONSE if the echo signal fails to arrive normally, a timeout condition was added to return to IDLE if echo is not detected within a set time.

#### 4.4.2 DHT11 Sensor

##### 4.4.2.1 Timing Optimization

Since the DHT11 sensor operates based on us/ms-level timing conditions, precise time control is important. To this end, this design does not compute time directly from the FPGA's reference clock, but instead generates a 1us-unit tick_us signal via the dht11_tick_gen_us module.

The DHT11 controller increments tick_cnt_reg only while tick_us is 1, and uses this to measure the start-signal hold time, the sensor-response interval, and the DATA HIGH hold time. This structure allows the design to reliably control the 18ms-plus start signal, the 80us response interval, and the DATA 0/1 discrimination time.

In addition, during DATA-bit discrimination, the HIGH hold time is measured in the DATA_COUNT state, and the bit value is judged in a separate DATA_DECISION state. By splitting time measurement and data storage across states in this way, the FSM structure is simplified and timing analysis is made easier.

##### 4.4.2.2 Ensuring Stability

Because the DHT11 is a sensor connected outside the FPGA, its DATA signal is not synchronized with the FPGA clock. Using this asynchronous input directly in the FSM could cause metastability or unstable state transitions.

To prevent this, this design applies a 2-stage synchronizer using dht11_sync1 and dht11_sync2.

Rather than using the raw dht11_io signal directly, the FSM performs state transitions based on the synchronized dht11_sync2. This allows the external sensor signal to be processed reliably within the FPGA clock domain.

In addition, the DHT11 DATA line is a bidirectional signal that carries both input and output over a single wire. If the FPGA and the sensor were to drive the DATA line at the same time, a signal conflict could occur. To prevent this, out_sel_reg is used to distinguish which side controls the DATA line.

## 5. Simulation & Verification

### 5.1 Testbench

| Item | What It Checks |
|---|---|
| tb_decision_unit.v | Local priority, per-context action mapping, refresh/log policy, handling of ignored sensor commands |
| tb_dht11.v | 40-bit reception, temp/humi splitting, the checksum-valid path |
| tb_sr04.v | The distance-conversion path and representative distance cases |
| tb_ascii_uart_sensor_pipeline.v | Watch status, DHT11 status, unknown command, and delete/backspace recovery scenarios |

| Related TB | Confirmed Result |
|---|---|
| context_manager RTL + decision/top path | Context changes are reflected after the synchronizer, and the change pulse can be explained as a single-shot event |
| tb_decision_unit.v, tb_ascii_uart_sensor_pipeline.v | Confirmed the structure by which a status request leads to log_req, a frame response, and the UART response line |
| tb_sr04.v | Passed the 20mm case; the 4000mm case needs its timeout re-tuned |
| tb_dht11.v | Confirmed TEMP = 25.56, HUMI = 60.34, VALID = 1 |

### 5.2 Simulation Scenarios

#### 5.2.1 Top Module

| Scenario | What It Verifies | Confirmed Result |
|---|---|---|
| Scenario 1 | Local priority and event dispatch | Confirmed local input priority and per-context action mapping in tb_decision_unit |
| Scenario 2 | Refresh/log control after a context change | Confirmed the refresh_req and log_req generation structure when entering a sensor context |
| Scenario 3 | The status command -> log response path | Confirmed the status -> log_req -> response structure via the tb_decision_unit + top path |
| Scenario 4 | Unknown command / delete-backspace recovery | Confirmed the response-frame recovery scenario via the top TB |

#### 5.2.2 SR04 Sensor

| Scenario | What It Verifies | Confirmed Result |
|---|---|---|
| Scenario 1 | State change after the measurement-start signal is applied | Transitions to START when sr04_start = 1 is applied; trig = 1 is output |
| Scenario 2 | State change after the ultrasonic trigger signal output | Confirmed trig falls to 0 and is held for a set duration, then waits for echo = 1 |
| Scenario 3 | Echo signal reception and normal recovery | Confirmed the distance-measurement count proceeds while echo = 1, and recovery once echo falls to 0 |

#### 5.2.3 DHT11 Sensor

| Scenario | What It Verifies | Confirmed Result |
|---|---|---|
| Scenario 1 | State change before DATA reception | Confirmed START → SYNCL → SYNCH → DATA_SYNC |
| Scenario 2 | Receiving DATA 0 | Judged as 0 after measuring a short HIGH time |
| Scenario 3 | Receiving DATA 1 | Judged as 1 after measuring a long HIGH time |
| Scenario 4 | Storing DATA | Bit stored in data_reg and bit_cnt_reg incremented |
| Scenario 5 | Completing 40-bit reception | Moves to STOP once bit_cnt_reg = 39 |
| Scenario 6 | Checksum verification | valid = 1 output |
| Scenario 7 | FND output | Temperature/humidity data is reflected in the FND output |

### 5.3 Waveform Analysis

#### 5.3.1 SR04 Sensor

**State change after the measurement-start signal is applied**
<img width="900" alt="image" src="https://github.com/user-attachments/assets/27fc339a-594d-4cec-a9c7-790442098a10" />

This waveform confirms the change in trig output once the sr04_start signal is applied after the start of an ultrasonic-sensor measurement. After sr04_start = 1 is applied, the FSM transitions from IDLE to START, and the trig signal for the ultrasonic-measurement interval is confirmed to activate to 1.

**State change after the ultrasonic trigger signal output**
<img width="900" alt="image" src="https://github.com/user-attachments/assets/9527addd-8b9d-4d67-a2d0-d67c5d09b227" />

The trig signal is confirmed to activate to 1 to start ultrasonic transmission and then fall back to 0. Afterward, during the wait interval, echo rising to 1 is judged as reception of the response signal, and once echo returns to 0, measurement ends and the FSM is confirmed to return to its initial state.

**Echo signal reception and normal recovery**
<img width="900" alt="image" src="https://github.com/user-attachments/assets/9386d660-616b-4a30-8c55-12f184d3d4cb" />

After the trig output, once echo rises to 1 during the wait interval it is judged as reception of the reflected wave. Once echo falls to 0, distance calculation is performed and the FSM is confirmed to return to its initial state.

#### 5.3.2 DHT11 Sensor

**Before DATA reception**
<img width="900" alt="image" src="https://github.com/user-attachments/assets/d9779a7c-8498-440c-afd3-6eb7c79a491a" />

This waveform confirms whether control of the DATA line switches correctly between the FPGA and sensor before the DHT11 transmits DATA.

Initially, out_sel_reg = 1 and the FPGA drives the DATA line to send the start signal. Afterward, out_sel_reg becomes 0 to receive the sensor's response, and the FPGA releases control of the DATA line.

Then io_oe = 1, and the testbench's virtual DHT11 sensor drives the DATA line, beginning the sensor response and data transmission.

Since c_state changes in the order START → SYNCL → SYNCH → DATA_SYNC in the waveform, it confirms that after sending the start signal, the sensor's response was confirmed and the design entered the DATA-reception stage normally.

**Receiving DATA 0**
<img width="900" alt="image" src="https://github.com/user-attachments/assets/0b40ad0d-4037-4cbc-8493-6eebd2e17bd9" />

This waveform confirms the process of receiving a DATA 0 bit from the DHT11.

In the DATA_SYNC state, the design waits for the LOW interval that starts each bit, and moves to DATA_COUNT once the DATA signal goes HIGH.

In the DATA_COUNT state, the time DATA is held HIGH is measured with tick_cnt_reg. In the waveform, tick_cnt_reg increases to about 26us before DATA falls LOW, so this bit is judged as DATA 0.

**Receiving DATA 1**
<img width="900" alt="image" src="https://github.com/user-attachments/assets/50e2882b-98f3-40f9-bd4e-8764139efc1e" />

This waveform confirms the process of receiving a DATA 1 bit from the DHT11.

In the DATA_COUNT state, the time the DATA signal is held HIGH is measured with tick_cnt_reg.

In the waveform, DATA is held HIGH for a long time, with tick_cnt_reg increasing to about 70us before DATA falls LOW.

Since the DHT11 judges a bit value as 1 when the HIGH hold time is long, this interval can be interpreted as a DATA 1 reception state.

**Storing DATA**
<img width="900" alt="image" src="https://github.com/user-attachments/assets/2223ae99-b7f4-4c3c-adea-a2428c3d7acb" />

This waveform confirms the process, based on the HIGH time measured in DATA_COUNT, of storing the bit value in the DATA_DECISION state.

Since tick_cnt_reg increased to about 69us in the DATA_COUNT state, it is judged as a HIGH interval longer than the reference value.

Accordingly, in the DATA_DECISION state, this bit is discriminated as DATA 1, and a 1 is stored toward the LSB end of data_reg.

**Receiving all 40 bits of DATA**
<img width="900" alt="image" src="https://github.com/user-attachments/assets/fdcebaea-74b9-40bf-8996-2a9dea777b59" />

This waveform confirms the process by which the design moves to the STOP state once 40-bit DATA reception from the DHT11 is complete.

During data reception, the DATA_SYNC → DATA_COUNT → DATA_DECISION states repeat, and the number of bits received is counted with bit_cnt_reg.

In the waveform, bit_cnt_reg is confirmed to increase up to 39. This means reception of a total of 40 bits, from bit 0 through bit 39, is complete.

Once 40-bit reception ends, the FSM no longer waits for the next bit and moves to STOP.

**Confirming Valid**
<img width="900" alt="image" src="https://github.com/user-attachments/assets/1cad2c9a-6c45-418a-91cb-9516524aa99b" />

This waveform confirms the process by which valid is output as 1 once 40-bit DATA reception from the DHT11 is complete.

The received data_reg value was stored identically to the DATA_STREAM value sent by the testbench.

```
data_reg    = 3C00190055
DATA_STREAM = 3C00190055
```

### 5.4 Troubleshooting
<img width="400" alt="image" src="https://github.com/user-attachments/assets/202d0ad3-132b-4d9e-aab8-b83bf661e830" />
<img width="400" alt="image" src="https://github.com/user-attachments/assets/1f04df5b-1ace-4c27-8860-c5da21a6abb1" />

After programming the FPGA, ASCII input verification was performed using screen as the serial terminal. screen is a lightweight, CLI-based program that does not display input in real time and only prints out results.

During verification, an unk_com log was printed out even though a command had been entered correctly. Root-cause analysis found that when Delete or Backspace was pressed, its ASCII code ended up included in the command string, which caused it to be treated as an invalid command.

Accordingly, exception handling was added so that Delete and Backspace ASCII codes in the input data are ignored. After the fix, re-verification confirmed that commands operate normally even after Delete and Backspace input.

## 6. FPGA Result Video

https://youtu.be/VrtHO9WrXKs?si=ZH545mWVWntkPZft

## 7. Conclusion

Through this UART+FIFO+SENSOR+stopwatch_watch project, building on the previous stopwatch/watch and UART LOOPBACK projects, we were able to extend a local control system into an integrated system also capable of remote control and sensor status reporting.

In the end, we organized the ascii_uart_sensor_pipeline top structure, context-based display of watch/stopwatch and sensor data, reception of remote commands and event-log responses, maintenance of sensor latest values, and verification based on unit testbenches and an integrated testbench, into a single coherent flow.
