# Alternating Bit Protocol - SystemVerilog

Simple 1Gb packet processor on the Xilinx KR260 Robotics kit. A constantly increasing number is 

![ABP Block Diagram](./etc/ABP%20Block%20Diagram.png)

## What is the Alternating Bit Protocol?
The Alternating Bit Protocol (ABP) is a simple network protocol that ensures reliable data transmission over an unreliable channel. Think of it as a basic version of TCP that uses just a single bit (0 or 1) to keep track of which messages have been received successfully.

### How It Works

##### Sender's Side:

1. Sends a packet with a bit (0 or 1) attached
2. Waits for acknowledgment before sending the next packet
3. Keeps resending the same packet until acknowledged


##### Receiver's Side:

1. Receives packet and checks the bit
2. Sends acknowledgment with the same bit
3. Only accepts packets with the expected bit


##### The "Alternating" Part:

After successful transmission, both sides flip their bits (0→1 or 1→0). This helps detect duplicates and lost messages

```
Sender                     Receiver
  |                           |
  |----Packet(0)------------->|
  |                           |
  |<---Acknowledgment(0)------|
  |                           |
  |----Packet(1)------------->|
  |                           |
  |<---Acknowledgment(1)------|
  |                           |
```

### Module Summary

##### abp_packet_tx.sv

The transmitter module (`abp_packet_tx`) implements the sender side of ABP using the AXI Stream interface. The module takes a 32-bit value and an alternating bit as input, increments the value, and generates fixed-size packets (configurable, default 64 bytes) where the value is split across the first 4 bytes and the alternating bit is placed in the final byte. It manages the complete AXI-Stream handshake process for reliable transmission to an Ethernet MAC.

##### abp_packet_rx.sv

The receiver module (`abp_packet_rx`) handles the receiving side of the protocol, accepting AXI Stream packets from an Ethernet MAC. It reconstructs the original 32-bit value from the first 4 bytes of each packet and extracts the alternating bit from the final byte. The module includes error detection for malformed packets (early termination) and implements proper handshaking to ensure reliable data reception and processing.The module takes a 32-bit value and an alternating bit as input, increments the value, and generates fixed-size packets (configurable, default 64 bytes) where the value is split across the first 4 bytes and the alternating bit is placed in the final bit. It manages the complete AXI-Stream handshake process for reliable transmission to an Ethernet MAC.

##### abp_transmitter.sv
The transmitter controller (`abp_transmitter`) implements the complete sender-side protocol logic including timeout handling and retransmission. It manages packet transmission, tracks the alternating bit, handles acknowledgments, and implements a timeout mechanism to retransmit packets when no acknowledgment is received within a configurable number of cycles.

##### abp_receiver.sv

The receiver controller (`abp_receiver`) implements the complete receiver-side protocol logic, managing packet reception and acknowledgment generation. It receives packets, processes them according to the ABP protocol, and generates appropriate acknowledgment packets, ensuring reliable communication even over unreliable channels.

---

Working:
- Zynq PS
- Xilinx Virtual Cable
- ILAs to collect data

To do
- [x] Create vivado sim to test integration. Full project simulation in Vivado.
    - [x] Modify tb for ABP
- [x] Hook SV components to Vivado project
    - [x] Finish ABP_Receiver
- [x] Create Alice/Bob parametrizable builds/deploys
- [ ] Create AXI4-Lite interface for Memory Mapped access from Processing System
- [x] Create/Verify Alternating bit protocol in SV
- [ ] Hook Alternating bit protocol registers to Memory Mapped interface
- [ ] Create polling driver example in python