# Check IP
if { [file isdirectory ../IP] } {
    # if the IP files exist, we already generated the IP, so we can just
    # read the ip definition (.xci)
    import_ip ../IP/tri_mode_ethernet_mac_0/tri_mode_ethernet_mac_0.xci
    import_ip ../IP/ila_0/ila_0.xci
} else {
    # IP folder does not exist. Create IP folder
    file mkdir ../IP
    
    # create_ip requires that a project is open in memory. Create project 
    # but don't do anything with it
    create_project -in_memory 
    set_property board_part xilinx.com:kr260_som:part0:1.1 [current_project]
    set_property board_connections {som240_1_connector xilinx.com:kr260_carrier:som240_1_connector:1.0 som240_2_connector xilinx.com:kr260_carrier:som240_2_connector:1.0} [current_project]
    
    # paste commands from Journal file to recreate IP
    create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_0 -dir ../IP
    set_property -dict [list \
        CONFIG.C_DATA_DEPTH {16384} \
        CONFIG.C_NUM_OF_PROBES {16} \
    ] [get_ips ila_0]

    create_ip -name tri_mode_ethernet_mac -vendor xilinx.com -library ip \
        -version 9.0 -module_name tri_mode_ethernet_mac_0 \
        -dir ../IP
    set_property -dict [list \
        CONFIG.MAC_Speed {1000_Mbps} \
        CONFIG.Management_Frequency {125.00} \
        CONFIG.Physical_Interface {RGMII} \
        CONFIG.SupportLevel {1} \
        CONFIG.Make_MDIO_External {false} \
    ] [get_ips tri_mode_ethernet_mac_0]


    generate_target all [get_ips]
    synth_ip [get_ips]
}