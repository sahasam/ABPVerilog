# XDC constraints for the Xilinx KR260 board
# part: xck26-sfvc784-2LV-c

# General configuration
set_property BITSTREAM.GENERAL.COMPRESS true           [current_design]

# System clocks
#
# use the 25 MHz clock outputs to the PL from U91
# and feed that into a PLL to convert it to 125 MHz
#set_property -dict {LOC C3 IOSTANDARD LVCMOS18} [get_ports clk_25mhz_ref] ;# HPA_CLK0P_CLK, HPA_CLK0_P, via U91, SOM240_1 A6
#create_clock -period 40.000 -name clk_25mhz [get_ports clk_25mhz_ref]

# LEDs
#set_property -dict {LOC F8   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[0]}] ;# HPA14P som240_1_d13
#set_property -dict {LOC E8   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {led[1]}] ;# HPA14N som240_1_d14
#
#set_property -dict {LOC G8   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {sfp_led[0]}] ;# HPA13P som240_1_a12
#set_property -dict {LOC F7   IOSTANDARD LVCMOS18 SLEW SLOW DRIVE 8} [get_ports {sfp_led[1]}] ;# HPA13N som240_1_a13
#
#set_false_path -to [get_ports {led[*] sfp_led[*]}]
#set_output_delay 0 [get_ports {led[*] sfp_led[*]}]

######################## PMOD 1 Upper ########################
set_property PACKAGE_PIN H12 [get_ports {glbl_rst}]
set_property IOSTANDARD LVCMOS33 [get_ports {glbl_rst}]
#
#set_property PACKAGE_PIN E10 [get_ports {debug_1}]
#set_property IOSTANDARD LVCMOS33 [get_ports {debug_1}]
#
#set_property PACKAGE_PIN D10 [get_ports {debug_2}]
#set_property IOSTANDARD LVCMOS33 [get_ports {debug_2}]

#set_property PACKAGE_PIN C11 [get_ports {pmod1_io[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod1_io[3]}]

######################### PMOD 1 Lower ########################
#set_property PACKAGE_PIN B10 [get_ports {pmod1_io[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod1_io[4]}]

#set_property PACKAGE_PIN E12 [get_ports {pmod1_io[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod1_io[5]}]

#set_property PACKAGE_PIN D11 [get_ports {pmod1_io[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod1_io[6]}]

#set_property PACKAGE_PIN B11 [get_ports {pmod1_io[7]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod1_io[7]}]


# 25mhz input ref clk
set_property -dict {LOC C3 IOSTANDARD LVCMOS18} [get_ports clk_25mhz_ref] ;# HPA_CLK0P_CLK, HPA_CLK0_P, via U91, SOM240_1 A6
create_clock -period 40.000 -name clk_25mhz [get_ports clk_25mhz_ref]     ;

# PL GEM2 RGMII Pins
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS18} [get_ports rgmii_gem2_txd[0]]  ;   # som_240_1_d7   HPA01P
set_property -dict {PACKAGE_PIN D1 IOSTANDARD LVCMOS18} [get_ports rgmii_gem2_txd[1]]  ;   # som_240_1_d8   HPA01N
set_property -dict {PACKAGE_PIN F2 IOSTANDARD LVCMOS18} [get_ports rgmii_gem2_txd[2]]  ;   # som_240_1_d4   HPA02P
set_property -dict {PACKAGE_PIN E2 IOSTANDARD LVCMOS18} [get_ports rgmii_gem2_txd[3]]  ;   # som_240_1_d5   HPA02N
set_property -dict {PACKAGE_PIN F1 IOSTANDARD LVCMOS18} [get_ports rgmii_gem2_tx_ctl]  ;   # som_240_1_c4   HPA00_CCN
set_property -dict {PACKAGE_PIN A2 IOSTANDARD LVCMOS18} [get_ports rgmii_gem2_txc]     ;   # som_240_1_a3   HPA06P_CLK
set_property -dict {PACKAGE_PIN A1 IOSTANDARD LVCMOS18} [get_ports rgmii_gem2_rxd[0]]  ;   # som_240_1_a4   HPA06N
set_property -dict {PACKAGE_PIN B3 IOSTANDARD LVCMOS18} [get_ports rgmii_gem2_rxd[1]]  ;   # som_240_1_b7   HPA07P
set_property -dict {PACKAGE_PIN A3 IOSTANDARD LVCMOS18} [get_ports rgmii_gem2_rxd[2]]  ;   # som_240_1_b8   HPA07N
set_property -dict {PACKAGE_PIN B4 IOSTANDARD LVCMOS18} [get_ports rgmii_gem2_rxd[3]]  ;   # som_240_1_c9   HPA08P
set_property -dict {PACKAGE_PIN A4 IOSTANDARD LVCMOS18} [get_ports rgmii_gem2_rx_ctl]  ;   # som_240_1_c10  HPA08N
set_property -dict {PACKAGE_PIN D4 IOSTANDARD LVCMOS18} [get_ports rgmii_gem2_rxc]     ;   # som_240_1_d10  HPA09P_CLK

# PL GEM2 MDIO Pins
set_property -dict {LOC F3 IOSTANDARD LVCMOS18} [get_ports mdio]  ;   # som_240_1_c7  HPA03N
set_property -dict {LOC G3 IOSTANDARD LVCMOS18} [get_ports mdc]   ;    # som_240_1_c6  HPA03P
set_property -dict {LOC B1 IOSTANDARD LVCMOS18} [get_ports phy_gem2_resetn];

