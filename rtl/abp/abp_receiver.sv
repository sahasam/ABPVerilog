/* Alternating bit protocol: packet receiver.
 * Receives packets, processes them according to the ABP protocol,
 * increments the value, and transmits the new packet.
 */

`timescale 1ns/1ns
`default_nettype none

module abp_receiver
#(
   // Width of AXI Stream interfaces in bits
   parameter integer DATA_WIDTH = 8,
   // Number of bytes to read from packet to counter
   parameter integer VALUE_SIZE = 4,
   // Number of bytes in a packet
   parameter integer PACKET_SIZE = 64
)
(
   input wire                      aclk,
   input wire                      aresetn,

   // Slave AXI Stream interface
   input  wire                     s_axis_tvalid,
   input  wire [DATA_WIDTH-1:0]    s_axis_tdata,
   input  wire                     s_axis_tlast,
   output wire                     s_axis_tready,

   // Master AXI Stream interface
   output wire                     m_axis_tvalid,
   output wire [DATA_WIDTH-1:0]    m_axis_tdata,
   output wire                     m_axis_tlast,
   input  wire                     m_axis_tready
);

   // Internal signals
   wire                      rx_abp_valid;
   wire [VALUE_SIZE*8-1:0]   rx_abp_value;
   wire                      rx_abp_bit;
   wire                      rx_abp_ready;

   wire                      tx_abp_valid;
   wire [VALUE_SIZE*8-1:0]   tx_abp_value;
   wire                      tx_abp_bit;
   wire                      tx_abp_ready;

   // Instantiate abp_packet_rx
   abp_packet_rx #(
      .DATA_WIDTH(DATA_WIDTH),
      .VALUE_SIZE(VALUE_SIZE),
      .PACKET_SIZE(PACKET_SIZE)
   ) rx_inst (
      .aclk(aclk),
      .resetn(aresetn),
      .eth_rx_tvalid(s_axis_tvalid),
      .eth_rx_tdata(s_axis_tdata),
      .eth_rx_tlast(s_axis_tlast),
      .eth_rx_tready(s_axis_tready),
      .abp_tx_ready(rx_abp_ready),
      .abp_tx_valid(rx_abp_valid),
      .abp_tx_value(rx_abp_value),
      .abp_tx_bit(rx_abp_bit),
      .busy(),
      .error_early_termination()
   );

   // Increment the value
   assign tx_abp_value = rx_abp_value;
   assign tx_abp_bit = rx_abp_bit;
   assign tx_abp_valid = rx_abp_valid;
   assign rx_abp_ready = tx_abp_ready;

   // Instantiate abp_packet_tx
   abp_packet_tx #(
      .DATA_WIDTH(DATA_WIDTH),
      .VALUE_SIZE(VALUE_SIZE),
      .PACKET_SIZE(PACKET_SIZE)
   ) tx_inst (
      .aclk(aclk),
      .resetn(aresetn),
      .m_eth_tx_tvalid(m_axis_tvalid),
      .m_eth_tx_tdata(m_axis_tdata),
      .m_eth_tx_tlast(m_axis_tlast),
      .m_eth_tx_tready(m_axis_tready),
      .s_abp_ready(tx_abp_ready),
      .s_abp_valid(tx_abp_valid),
      .s_abp_value(tx_abp_value),
      .s_abp_bit(tx_abp_bit),
      .busy()
   );

endmodule
