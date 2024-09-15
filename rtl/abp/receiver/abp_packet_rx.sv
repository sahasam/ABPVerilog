/* Alternating Bit Protocol: Packet receiver
 * receieves a stream of one packet off the wire, and creates aggregated signals about the value and bit
 * in the packet.
 */

`timescale 1ns/1ns
`default_nettype none

module abp_packet_rx
#(
    // Width of RX Axi Stream (bits)
    parameter integer DATA_WIDTH = 0,

    // #of bytes to read from packet to counter
    parameter integer VALUE_SIZE = 0,

    // #of bytes in a packet
    parameter integer PACKET_SIZE = 0
) (
    input wire         aclk,
    input wire         resetn,

    // Ethernet Frame Input
    input  wire                     eth_rx_tvalid,
    input  wire  [DATA_WIDTH-1:0]   eth_rx_tdata,
    input  wire                     eth_rx_tlast,
    output logic                    eth_rx_tready,

    // ABP Frame Output
    input  wire                       abp_tx_ready,
    output logic                      abp_tx_valid,
    output logic [VALUE_SIZE*8-1:0]   abp_tx_value,
    output logic                      abp_tx_bit,

    // Status signals
    output logic        busy,
    output logic        error_early_termination
);

localparam integer CounterWidth = $clog2(PACKET_SIZE);

initial begin
    busy = 1'b0;
end

logic eth_rx_tready_reg = 1'b0, eth_rx_tready_next;
logic abp_tx_valid_reg = 1'b0, abp_tx_valid_next;

logic [VALUE_SIZE*8-1:0] abp_value_reg = {VALUE_SIZE*8{1'b0}}, abp_value_next;
logic [DATA_WIDTH-1:0] abp_bit_reg = {DATA_WIDTH{1'b0}}, abp_bit_next;

logic read_abp_payload_reg = 1'b1, read_abp_payload_next;
logic [CounterWidth-1:0] byte_counter_reg = 1'b0, byte_counter_next;

logic error_early_termination_reg = 1'b0, error_early_termination_next;


assign eth_rx_tready = eth_rx_tready_reg;
assign abp_tx_valid = abp_tx_valid_reg;
assign abp_tx_value = abp_value_reg;
assign abp_tx_bit = abp_bit_reg[0];
assign error_early_termination = error_early_termination_reg;

always_comb begin
    abp_tx_valid_next = abp_tx_valid_reg && !abp_tx_ready;
    eth_rx_tready_next = 1'b1;

    abp_value_next = abp_value_reg;
    abp_bit_next = abp_bit_reg;

    byte_counter_next = {$clog2(PACKET_SIZE){1'b0}};

    error_early_termination_next = error_early_termination_reg;


    // ETHERNET PACKET IN
    if (eth_rx_tvalid && eth_rx_tready) begin
        byte_counter_next = byte_counter_reg + 1;

        `define _PACKET_FIELD_(offset, field) \
            if (byte_counter_reg == offset) begin \
                field = eth_rx_tdata; \
            end

        `_PACKET_FIELD_(0, abp_value_next[31:24])
        `_PACKET_FIELD_(1, abp_value_next[23:16])
        `_PACKET_FIELD_(2, abp_value_next[15:8])
        `_PACKET_FIELD_(3, abp_value_next[7:0])
        `_PACKET_FIELD_(63, abp_bit_next)

        `undef _PACKET_FIELD_
    end

    // End of Ethernet Packet in
    if (eth_rx_tlast) begin
        if (byte_counter_reg < 63) begin
            error_early_termination_next = 1'b1;
        end else begin
            abp_tx_valid_next = 1'b1;
            error_early_termination_next = 1'b0;
        end

        byte_counter_next = {CounterWidth{1'b0}};
    end
end

always_ff @(posedge aclk) begin
    abp_tx_valid_reg <= abp_tx_valid_next;
    abp_value_reg <= abp_value_next;
    abp_bit_reg <= abp_bit_next;
    byte_counter_reg <= byte_counter_next;
    error_early_termination_reg <= error_early_termination_next;
    eth_rx_tready_reg <= eth_rx_tready_next;

    if (!resetn) begin
        abp_tx_valid_reg <= 1'b0;
        abp_value_reg <= {VALUE_SIZE*8{1'b0}};
        abp_bit_reg <= {DATA_WIDTH-1{1'b0}};
        byte_counter_reg <= {CounterWidth-1{1'b0}};
        error_early_termination_reg <= 1'b0;
        eth_rx_tready_reg <= 1'b0;
    end
end

endmodule
