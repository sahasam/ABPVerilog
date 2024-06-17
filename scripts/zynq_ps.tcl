# Sahas Munamala
# Created: Sat Oct 07 2023, 08:14PM PDT
# Modified for XVC setup: Sat Jun 15 2023, 08:36PM PDT
# - Added Debug Bridge IP, Axi Interconnect, 

#######################################
# Project Specific Configuration
#
# These commands allow for vivado to use it's knowledge of the
# KR260 SOM pinout and configuration in the KR260 dev board
# and automate block design features.
#
# TODO: Move this to its own file. It should run from create_project.tcl
set_property board_part xilinx.com:kr260_som:part0:1.1 [current_project]
set_property board_connections {som240_1_connector xilinx.com:kr260_carrier:som240_1_connector:1.0 som240_2_connector xilinx.com:kr260_carrier:som240_2_connector:1.0} [current_project]

create_bd_design "zynq_ps"

#######################################
# Create
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.5 zynq_ultra_ps
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset
create_bd_cell -type ip -vlnv xilinx.com:ip:debug_bridge:3.0 debug_bridge_0


#######################################
# Configure
# zynq ps
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps]
set_property -dict [list \
  CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {125} \
  CONFIG.PSU__USE__M_AXI_GP0 {1} \
  CONFIG.PSU__USE__M_AXI_GP1 {0} \
] [get_bd_cells zynq_ultra_ps]

# debug bridge
set_property CONFIG.C_DEBUG_MODE {2} [get_bd_cells debug_bridge_0]

# axi interconnect
set_property CONFIG.NUM_MI {1} [get_bd_cells axi_interconnect_0]


#######################################
# Connect
connect_bd_net [get_bd_pins zynq_ultra_ps/pl_resetn0] [get_bd_pins proc_sys_reset/ext_reset_in]
connect_bd_net [get_bd_pins zynq_ultra_ps/pl_clk0] [get_bd_pins proc_sys_reset/slowest_sync_clk]

# axi interconnect
connect_bd_intf_net [get_bd_intf_pins debug_bridge_0/S_AXI] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M00_AXI]
connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps/M_AXI_HPM0_FPD] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI]

# clocks
connect_bd_net [get_bd_pins zynq_ultra_ps/pl_clk0] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins zynq_ultra_ps/pl_clk0]
connect_bd_net [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins zynq_ultra_ps/pl_clk0]
connect_bd_net [get_bd_pins debug_bridge_0/s_axi_aclk] [get_bd_pins zynq_ultra_ps/pl_clk0]
connect_bd_net [get_bd_pins zynq_ultra_ps/maxihpm0_fpd_aclk] [get_bd_pins zynq_ultra_ps/pl_clk0]

# resets
connect_bd_net [get_bd_pins proc_sys_reset/interconnect_aresetn] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins proc_sys_reset/interconnect_aresetn]
connect_bd_net [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins proc_sys_reset/interconnect_aresetn]
connect_bd_net [get_bd_pins debug_bridge_0/s_axi_aresetn] [get_bd_pins proc_sys_reset/peripheral_aresetn]

# Set debug bridge accessible at 0xA000_0000
assign_bd_address -target_address_space /zynq_ultra_ps/Data [get_bd_addr_segs debug_bridge_0/S_AXI/Reg0] -force
set_property offset 0xA0000000 [get_bd_addr_segs {zynq_ultra_ps/Data/SEG_debug_bridge_0_Reg0}]

#######################################
# Save block design
regenerate_bd_layout
validate_bd_design
save_bd_design [current_bd_design]
close_bd_design [current_bd_design]
