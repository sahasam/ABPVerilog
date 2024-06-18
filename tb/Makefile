TOPLEVEL_LANG ?= verilog

SIM ?= icarus  # Specify your simulator here (icarus, modelsim, etc.)

TOPLEVEL ?= top_module_name  # Replace with the name of your top-level module

MODULE ?= test_module_name  # Replace with the name of your Python test module (without the .py extension)

# Path to your Verilog sources
VERILOG_SOURCES += $(wildcard ../rtl/abp/receiver/*.sv)
VERILOG_SOURCES += $(wildcard ../rtl/abp/bram.sv)  

# Path to your Cocotb test
PYTHONPATH = ./:$(PYTHONPATH)

include $(shell cocotb-config --makefiles)/Makefile.sim

receiver_transmitter:
	$(MAKE) TOPLEVEL=abp_receiver_transmitter MODULE=abp_receiver_transmitter_test

receiver_receiver:
	$(MAKE) TOPLEVEL=abp_receiver_receiver MODULE=abp_receiver_receiver_test