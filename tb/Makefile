TOPLEVEL_LANG ?= verilog

SIM ?= icarus  # Specify your simulator here (icarus, modelsim, etc.)

TOPLEVEL ?= top_module_name  # Replace with the name of your top-level module

MODULE ?= test_module_name  # Replace with the name of your Python test module (without the .py extension)

# Path to your Verilog sources
VERILOG_SOURCES = $(wildcard ../rtl/abp/*.sv)

# Path to your Cocotb test
PYTHONPATH = ./:$(PYTHONPATH)

PARAMETERS = -Pabp_packet_rx.DATA_WIDTH=8 -Pabp_packet_rx.VALUE_SIZE=4 -Pabp_packet_rx.PACKET_SIZE=64
COMPILE_ARGS += $(PARAMETERS)

include $(shell cocotb-config --makefiles)/Makefile.sim

abp_packet_rx:
	$(MAKE) TOPLEVEL=abp_packet_rx MODULE=abp_packet_rx_test WAVES=1

abp_packet_tx:
	$(MAKE) TOPLEVEL=abp_packet_tx MODULE=abp_packet_tx_test WAVES=1

abp_receiver:
	$(MAKE) TOPLEVEL=abp_receiver MODULE=abp_receiver_test WAVES=1

abp_transmitter:
	$(MAKE) TOPLEVEL=abp_transmitter MODULE=abp_transmitter_test WAVES=1