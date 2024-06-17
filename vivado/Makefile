# Sahas Munamala
# Created: Sun Oct 08 2023, 12:47PM PDT

# FPGA settings
FPGA_PART = xck26-sfvc784-2LV-c
FPGA_TOP  = fpga
FPGA_ARCH = zynquplus

# Files for synthesis
SYNV_FILES  = rtl/fpga.v
SYNV_FILES += rtl/fpga_core.v
SYNV_FILES += rtl/temac_example_design_resets.v
SYNV_FILES += rtl/xlnx-temac/temac_address_swap.v
SYNV_FILES += rtl/xlnx-temac/temac_axi_lite_sm.v
SYNV_FILES += rtl/xlnx-temac/temac_axi_mux.v
SYNV_FILES += rtl/xlnx-temac/temac_axi_pat_check.v
SYNV_FILES += rtl/xlnx-temac/temac_axi_pat_gen.v
SYNV_FILES += rtl/xlnx-temac/temac_axi_pipe.v
SYNV_FILES += rtl/xlnx-temac/temac_basic_pat_gen.v
SYNV_FILES += rtl/xlnx-temac/temac_bram_tdp.v
SYNV_FILES += rtl/xlnx-temac/temac_fifo_block.v
SYNV_FILES += rtl/xlnx-temac/temac_reset_sync.v
SYNV_FILES += rtl/xlnx-temac/temac_rx_client_fifo.v
SYNV_FILES += rtl/xlnx-temac/temac_sync_block.v
SYNV_FILES += rtl/xlnx-temac/temac_syncer_level.v
SYNV_FILES += rtl/xlnx-temac/temac_ten_100_1g_eth_fifo.v
SYNV_FILES += rtl/xlnx-temac/temac_tx_client_fifo.v

SYNSV_FILES  = rtl/abp/receiver/abp_receiver_receiver.sv
SYNSV_FILES += rtl/abp/receiver/abp_receiver_transmitter.sv
SYNSV_FILES += rtl/abp/receiver/abp_receiver.sv
SYNSV_FILES += rtl/abp/bram.sv

# Integration Testbench
TB_FILES  = rtl/sim/demo_tb.v
TB_FILES += rtl/sim/tri_mode_ethernet_mac_0_frame_typ.v

# XDC files
XDC_FILES = xdc/fpga.xdc

# IP
IP_TCL_FILES  = scripts/zynq_ps.tcl
IP_TCL_FILES += scripts/get_ip.tcl


###########################################################
# DO NOT MODIFY
# SPDX-License-Identifier: BSD-2-Clause-Views
# Copyright (c) 2019-2023 The Regents of the University of California

include ../scripts/vivado.mk

program: $(FPGA_TOP).bit
	echo "open_hw" > program.tcl
	echo "connect_hw_server" >> program.tcl
	echo "open_hw_target" >> program.tcl
	echo "current_hw_device [lindex [get_hw_devices] 0]" >> program.tcl
	echo "refresh_hw_device -update_hw_probes false [current_hw_device]" >> program.tcl
	echo "set_property PROGRAM.FILE {$(FPGA_TOP).bit} [current_hw_device]" >> program.tcl
	echo "program_hw_devices [current_hw_device]" >> program.tcl
	echo "exit" >> program.tcl
	vivado -nojournal -nolog -mode batch -source program.tcl

APP_DIR = app

$(APP_DIR)/shell.json:
	@mkdir -p $(@D)
	echo '{"shell_type": "XRT_FLAT", "num_slots": "1"}' > $@

$(APP_DIR)/$(FPGA_TOP).bin: $(FPGA_TOP).bin
	@mkdir -p $(@D)
	cp $< $@

$(APP_DIR)/overlay.dtbo: ../ps/overlay.dtsi
	@mkdir -p $(@D)
	dtc -@ -O dtb -o $@ $^

.PHONY: app
app: $(APP_DIR)/$(FPGA_TOP).bin $(APP_DIR)/shell.json $(APP_DIR)/overlay.dtbo

clean::
	-rm -rf $(APP_DIR)
