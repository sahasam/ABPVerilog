/* Alternating bit protocol: packet receiver.
 * Receives packets and processes them according to the ABP protocol.
 */

`timescale 1ns/1ns
`default_nettype none

module abp_receiver
#(
   // Width of AXI Stream interfaces in bits
   parameter integer DATA_WIDTH = 8
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
   reg expected_bit;
   reg [DATA_WIDTH-1:0] data_reg;
   reg valid_reg;
   reg last_reg;

   // Simple state machine
   always @(posedge aclk or negedge aresetn) begin
      if (!aresetn) begin
         expected_bit <= 1'b0;
         data_reg <= {DATA_WIDTH{1'b0}};
         valid_reg <= 1'b0;
         last_reg <= 1'b0;
      end else if (s_axis_tvalid && s_axis_tready) begin
         expected_bit <= ~expected_bit;
         data_reg <= s_axis_tdata;
         valid_reg <= 1'b1;
         last_reg <= s_axis_tlast;
      end else if (m_axis_tvalid && m_axis_tready) begin
         valid_reg <= 1'b0;
      end
   end

   // Output assignments
   assign s_axis_tready = !valid_reg || m_axis_tready;
   assign m_axis_tvalid = valid_reg;
   assign m_axis_tdata = data_reg;
   assign m_axis_tlast = last_reg;

endmodule
