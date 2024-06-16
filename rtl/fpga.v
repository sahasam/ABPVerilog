// Sahas Munamala
// Created: Sun Oct 08 2023, 10:40AM PDT

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ns
`default_nettype none

/*
 * FPGA top-level module
 */
module fpga
(
    // asynchronous reset
    input  wire        glbl_rst,

    // 25MHz clock input from board
    input  wire        clk_25mhz_ref,

    // Phy reset
    output wire        phy_gem2_resetn,


    // RGMII Interface
    //----------------
    output wire [3:0]  rgmii_gem2_txd,
    output wire        rgmii_gem2_tx_ctl,
    output wire        rgmii_gem2_txc,
    input  wire [3:0]  rgmii_gem2_rxd,
    input  wire        rgmii_gem2_rx_ctl,
    input  wire        rgmii_gem2_rxc,


    // MDIO Interface
    //---------------
    inout  wire        mdio,
    output wire        mdc
);


/* Zynq Design. This module is generated through Vivado Block Designer
 * in ip/zynq_ps.tcl. Required boilerplate for Kria Designs
 */
zynq_ps zynq_ps_inst ();

/* FPGA Core. Wraps Xilinx Example Design to expose 1g port
 */
fpga_core fpga_core_inst (
    .glbl_rst             (glbl_rst),

    // 25mhz refclk from board crystal
    .clk_25mhz_ref        (clk_25mhz_ref),
    .gtx_clk_bufg_out     (),

    // PHY reset
    .phy_gem2_resetn      (phy_gem2_resetn),

    // RGMII interface
    .rgmii_gem2_txd       (rgmii_gem2_txd),
    .rgmii_gem2_tx_ctl    (rgmii_gem2_tx_ctl),
    .rgmii_gem2_txc       (rgmii_gem2_txc),
    .rgmii_gem2_rxd       (rgmii_gem2_rxd),
    .rgmii_gem2_rx_ctl    (rgmii_gem2_rx_ctl),
    .rgmii_gem2_rxc       (rgmii_gem2_rxc),

    .mdio                 (mdio),
    .mdc                  (mdc),

    .debug_1              (),
    .debug_2              ()
);


endmodule


`resetall
