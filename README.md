# Alternating Bit Protocol - Verilog

Uses a modified tri-mode-ethernet-mac example design, and adds custom register mapped rtl to control
the abp protocol and collect metrics

Working:
- Zynq PS
- Xilinx Virtual Cable
- ILAs to collect data

To do
- [x] Create vivado sim to test integration. Full project simulation in Vivado.
    - [x] Modify tb for ABP
- [x] Hook SV components to Vivado project
    - [x] Finish ABP_Receiver
- [ ] Create Alice/Bob parametrizable builds/deploys
- [ip] Create AXI4-Lite interface
- [ip] Create/Verify Alternating bit protocol in SV
- [ ] Hook Alternating bit protocol to Register interface
- [ ] Create polling driver example in python