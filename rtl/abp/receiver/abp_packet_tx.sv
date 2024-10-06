/* Alternating bit protocol: packet transmitter.
 * given abp hyperdata, generate the acknowledgement packet/next packet of
 * the sequence.
 */

`timescale 1ns/1ns
`default_nettype none

module abp_packet_tx
#(
    // Width of RX Axi Stream (bits)
    parameter integer DATA_WIDTH = 8,

    // #of bytes to read from packet to counter
    parameter integer VALUE_SIZE = 4,

    // #of bytes in a packet
    parameter integer PACKET_SIZE = 64
) (
    input wire         aclk,
    input wire         resetn,

    // Ethernet Frame Output to MAC
    output wire                     m_eth_tx_tvalid,
    output wire  [DATA_WIDTH-1:0]   m_eth_tx_tdata,
    output wire                     m_eth_tx_tlast,
    input  logic                    m_eth_tx_tready,

    // ABP Hyperdata Input
    output wire                       s_abp_ready,
    input  logic                      s_abp_valid,
    input  logic [VALUE_SIZE*8-1:0]   s_abp_value,
    input  logic                      s_abp_bit,

    // Status signals
    output logic        busy
);

localparam integer CounterWidth = $clog2(PACKET_SIZE);

// Internal Registers
logic [CounterWidth-1:0] byte_counter_reg, byte_counter_next;
logic                    sending_packet_reg, sending_packet_next;
logic [8*VALUE_SIZE-1:0] abp_value_reg, abp_value_next;
logic                    abp_bit_reg, abp_bit_next;

// Ethernet AXIS Frame Registers
logic m_eth_tx_tvalid_reg, m_eth_tx_tvalid_next;
logic m_eth_tx_tlast_reg, m_eth_tx_tlast_next;
logic [DATA_WIDTH-1:0] m_eth_tx_tdata_reg, m_eth_tx_tdata_next;

// ABP Hyperdata Input Handshake Registers
logic s_abp_ready_reg, s_abp_ready_next;

assign m_eth_tx_tvalid = m_eth_tx_tvalid_reg;
assign m_eth_tx_tdata = m_eth_tx_tdata_reg;
assign m_eth_tx_tlast = m_eth_tx_tlast_reg;
assign s_abp_ready = s_abp_ready_reg;
assign busy = sending_packet_reg;

always_comb begin
    m_eth_tx_tvalid_next = m_eth_tx_tvalid_reg;
    m_eth_tx_tlast_next = m_eth_tx_tlast_reg;
    m_eth_tx_tdata_next = m_eth_tx_tdata_reg;
    s_abp_ready_next = s_abp_ready_reg;
    byte_counter_next = byte_counter_reg;
    sending_packet_next = sending_packet_reg;
    abp_value_next = abp_value_reg;
    abp_bit_next = abp_bit_reg;

    if (sending_packet_reg && m_eth_tx_tready) begin
        m_eth_tx_tvalid_next = 1'b1;
        byte_counter_next = byte_counter_reg + 1;

        case (byte_counter_reg)
            0: m_eth_tx_tdata_next = abp_value_reg[3*8 +: 8];
            1: m_eth_tx_tdata_next = abp_value_reg[2*8 +: 8];
            2: m_eth_tx_tdata_next = abp_value_reg[1*8 +: 8];
            3: m_eth_tx_tdata_next = abp_value_reg[0*8 +: 8];
            PACKET_SIZE - 1: begin
                m_eth_tx_tdata_next = {7'd0, abp_bit_reg};
                m_eth_tx_tlast_next = 1'b1;
                sending_packet_next = 1'b0;
            end
            default: m_eth_tx_tdata_next = {DATA_WIDTH{1'b0}};
        endcase

        if (byte_counter_reg == PACKET_SIZE - 1) begin
            m_eth_tx_tlast_next = 1'b1;
            sending_packet_next = 1'b0;
        end
    end else if (!sending_packet_reg) begin
        m_eth_tx_tvalid_next = 1'b0;
        m_eth_tx_tlast_next = 1'b0;
        s_abp_ready_next = 1'b1;
    end

    if (s_abp_ready_reg && s_abp_valid) begin
        s_abp_ready_next = 1'b0;
        sending_packet_next = 1'b1;
        byte_counter_next = {CounterWidth{1'b0}};
        abp_bit_next = s_abp_bit;
        abp_value_next = s_abp_value + 1;
    end
end

always_ff @ (posedge aclk) begin
    if (!resetn) begin
        m_eth_tx_tvalid_reg <= 1'b0;
        m_eth_tx_tlast_reg <= 1'b0;
        m_eth_tx_tdata_reg <= {DATA_WIDTH{1'b0}};
        s_abp_ready_reg <= 1'b0;
        byte_counter_reg <= {CounterWidth{1'b0}};
        sending_packet_reg <= 1'b0;
        abp_value_reg <= {(8*VALUE_SIZE){1'b0}};
        abp_bit_reg <= 1'b0;
    end else begin
        m_eth_tx_tvalid_reg <= m_eth_tx_tvalid_next;
        m_eth_tx_tlast_reg <= m_eth_tx_tlast_next;
        m_eth_tx_tdata_reg <= m_eth_tx_tdata_next;
        s_abp_ready_reg <= s_abp_ready_next;
        byte_counter_reg <= byte_counter_next;
        sending_packet_reg <= sending_packet_next;
        abp_value_reg <= abp_value_next;
        abp_bit_reg <= abp_bit_next;
    end
end

endmodule
