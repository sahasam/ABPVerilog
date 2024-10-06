# Cocotb Makefile with parameterized tests using PLUSARGS

# Default configurations
TOPLEVEL_LANG ?= verilog
SIM ?= icarus

# Source files and Python path
VERILOG_SOURCES = $(wildcard ../rtl/abp/*.sv)
PYTHONPATH := .:$(PYTHONPATH)

# Test configuration
TEST_CONFIG := \
    abp_packet_rx:DATA_WIDTH=8:VALUE_SIZE=4:PACKET_SIZE=64 \
    abp_packet_tx:DATA_WIDTH=8:VALUE_SIZE=4:PACKET_SIZE=64 \
    abp_receiver:DATA_WIDTH=8:VALUE_SIZE=4:PACKET_SIZE=64

# Helper functions
define get_test_name
$(word 1,$(subst :, ,$(1)))
endef

define get_test_params
$(patsubst $(call get_test_name,$(1)):%,%,$(1))
endef

define get_parameters_as_arguments
$(subst $(space),$(space),$(patsubst %,-P$(call get_test_name,$(1)).%,$(subst :, ,$(call get_test_params,$(filter $(1):%,$(TEST_CONFIG))))))
endef

# Generate the list of tests
TESTS := $(foreach cfg,$(TEST_CONFIG),$(call get_test_name,$(cfg)))

# Cocotb-specific variables
TOPLEVEL ?= $(TESTS)
MODULE ?= $(addsuffix _test,$(TOPLEVEL))
SIM_BUILD_DIR ?= ./sim_build

# Include Cocotb's Makefile
include $(shell cocotb-config --makefiles)/Makefile.sim

# Custom targets
.PHONY: all_tests clean_all $(TESTS)

$(TESTS):
	@echo "Running test: $@"
	$(MAKE) sim \
		TOPLEVEL=$@ \
		MODULE=$@_test \
		COCOTB_RESULTS_FILE=$(SIM_BUILD_DIR)/$@_results.xml \
		SIM_BUILD=$(SIM_BUILD_DIR)/$@ \
		COMPILE_ARGS="$(call get_parameters_as_arguments,$@) -g2012"
	@python3 utils/combine_sim_results.py $(foreach test,$(TESTS),$(SIM_BUILD)/$(test)_results.xml)

all_tests: $(TESTS)

# Debug targets
print-%:
	@echo '$*=$($*)'

print-parameters-%:
	@echo 'PLUSARGS for $*: $(call get_parameters_as_arguments,$*)'

print-sources:
	@echo 'VERILOG_SOURCES: $(VERILOG_SOURCES)'

print-test-config:
	@echo 'TEST_CONFIG: $(TEST_CONFIG)'