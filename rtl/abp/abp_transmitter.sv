`timescale 1ns/1ns
`default_nettype none

module abp_transmitter
#(
   parameter integer DATA_WIDTH = 8,
   parameter integer VALUE_SIZE = 4,
   parameter integer PACKET_SIZE = 64,
   parameter integer TIMEOUT_CYCLES = 1200
)
(
   input wire                      aclk,
   input wire                      aresetn,

   // Slave AXI Stream interface (for receiving)
   input  wire                     s_axis_tvalid,
   input  wire [DATA_WIDTH-1:0]    s_axis_tdata,
   input  wire                     s_axis_tlast,
   output wire                     s_axis_tready,

   // Master AXI Stream interface (for transmitting)
   output wire                     m_axis_tvalid,
   output wire [DATA_WIDTH-1:0]    m_axis_tdata,
   output wire                     m_axis_tlast,
   input  wire                     m_axis_tready
);

   // Internal signals
   reg  [VALUE_SIZE*8-1:0]   tx_value_reg = {VALUE_SIZE*8{1'b0}}, tx_value_next;
   reg                       tx_bit_reg = 1'b1, tx_bit_next;
   reg                       expected_bit_reg = 1'b1, expected_bit_next;
   reg                       tx_valid, tx_valid_next;

   wire                      tx_ready;
   wire                      rx_valid;
   wire [VALUE_SIZE*8-1:0]   rx_value;
   wire                      rx_bit;
   wire                      rx_ready;

   // Timeout counter
   reg [$clog2(TIMEOUT_CYCLES)-1:0] timeout_counter, timeout_counter_next;

   // State machine
   typedef enum logic [2:0] {
      IDLE,
      TRANSMIT,
      WAIT_FOR_RX,
      TIMEOUT
   } state_t;

   state_t state_reg, state_next;

   always_ff @(posedge aclk or negedge aresetn) begin
      if (!aresetn) begin
         tx_value_reg <= 0;
         tx_bit_reg <= 1;
         expected_bit_reg <= 1;
         tx_valid <= 1'b0;
         state_reg <= IDLE;
         timeout_counter <= 0;
      end else begin
         tx_value_reg <= tx_value_next;
         tx_bit_reg <= tx_bit_next;
         expected_bit_reg <= expected_bit_next;
         tx_valid <= tx_valid_next;
         state_reg <= state_next;
         timeout_counter <= timeout_counter_next;
      end
   end

   always_comb begin
      tx_value_next = tx_value_reg;
      tx_bit_next = tx_bit_reg;
      expected_bit_next = expected_bit_reg;
      tx_valid_next = tx_valid;
      state_next = state_reg;
      timeout_counter_next = timeout_counter;

      case (state_reg)
         IDLE: begin
            // Initiate first transmission
            tx_value_next = 0;
            tx_bit_next = 1'b1;
            tx_valid_next = 1'b1;
            state_next = TRANSMIT;
            timeout_counter_next = 0;
         end

         TRANSMIT: begin
            if (tx_ready) begin
               tx_valid_next = 1'b0;
               state_next = WAIT_FOR_RX;
               timeout_counter_next = 0;
            end
         end

         WAIT_FOR_RX: begin
            if (rx_valid && rx_ready) begin
               if (rx_bit == expected_bit_reg) begin
                  tx_value_next = rx_value + 1;
                  tx_bit_next = ~rx_bit;
                  expected_bit_next = ~rx_bit;
                  tx_valid_next = 1'b1;
                  state_next = TRANSMIT;
                  timeout_counter_next = 0;
               end
            end else begin
               if (timeout_counter == TIMEOUT_CYCLES - 1) begin
                  state_next = TIMEOUT;
               end else begin
                  timeout_counter_next = timeout_counter + 1;
               end
            end
         end

         TIMEOUT: begin
            // Retransmit the current packet
            tx_valid_next = 1'b1;
            state_next = TRANSMIT;
            timeout_counter_next = 0;
         end

         default: state_next = IDLE;
      endcase
   end

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

      .s_abp_ready(tx_ready),
      .s_abp_valid(tx_valid),
      .s_abp_value(tx_value_reg),
      .s_abp_bit(tx_bit_reg),

      .busy()
   );

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

      .abp_tx_ready(rx_ready),
      .abp_tx_valid(rx_valid),
      .abp_tx_value(rx_value),
      .abp_tx_bit(rx_bit),

      .busy(),
      .error_early_termination()
   );

endmodule
