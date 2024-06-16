# Alternating Bit Protocol - Verilog

Uses a modified tri-mode-ethernet-mac example design, and adds custom register mapped rtl to control
the abp protocol and collect metrics

Working:
- Zynq PS
- Xilinx Virtual Cable
- ILAs to collect data

To do
- [ ] Create vivado sim to test integration
- [ ] Create Alice/Bob parametrizable builds/deploys
- [ ] Create AXI4-Lite interface
- [ ] Create/Verify Alternating bit protocol in SV
- [ ] Hook Alternating bit protocol to Register interface
- [ ] Create polling driver example in python