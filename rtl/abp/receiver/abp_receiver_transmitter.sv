/* Alternating Bit Protocol. Receiver Side: Acknowledgment Transmitter
 * Sahas Munamala 06/08/2024
 *
 *
 * This module implements the receiver side of the Alternating Bit Protocol (ABP) with a focus on
 * transmitting acknowledgments. The ABP is a simple data link layer protocol used to ensure reliable
 * transmission over an unreliable communication channel. The receiver sends an acknowledgment (ACK)
 * for each received packet, indicating that the packet has been successfully received.
 *
 * Parameters:
 *   - TIMEOUT_DURATION: The # of clock cycles for which the receiver waits for a new packet before resending
 *                       the acknowledgment.
 *
 * Inputs:
 *   - aclk: Clock signal.
 *   - aresetn: Active-low asynchronous reset signal.
 *   - alternating_bit: The current alternating bit received from the sender.
 *
 * Outputs:
 *   - m_axis_tvalid: Indicates that the acknowledgment data is valid and ready to be transmitted.
 *   - m_axis_tready: Indicates that the external system is ready to accept the acknowledgment data.
 *   - m_axis_tlast: Indicates the last byte of the acknowledgment data.
 *   - m_axis_tdata: The 8-bit data of the acknowledgment packet.
 *   - busy: Indicates that the transmitter is busy sending the acknowledgment.
 *
 * Internal States:
 *   - RESET_STATE: Initial state where the module is reset.
 *   - NEW_DATA: State where the new alternating bit is latched and prepared for acknowledgment.
 *   - ACK_SENDING: State where the acknowledgment packet is being sent.
 *   - ACK_TIMEOUT: State where the module waits for the timeout duration before resending the acknowledgment.
 *
 * Operation:
 *   - The module starts in the RESET_STATE, initializing all internal registers.
 *   - After reset, the module transitions to the NEW_DATA state, where it latches the alternating bit.
 *   - In the ACK_SENDING state, the module transmits the acknowledgment packet byte by byte.
 *     The last byte includes the alternating bit.
 *   - Once the packet is sent, the module transitions to the ACK_TIMEOUT state, where it waits for
 *     either a timeout or a change in the alternating bit to transition back to the NEW_DATA state.
 */

 module abp_receiver_transmitter #(
    parameter TIMEOUT_DURATION = 10
 )(
    input logic       aclk,
    input logic       aresetn,

    output logic       m_axis_tvalid,
    input  logic       m_axis_tready,
    output logic       m_axis_tlast,
    output logic [7:0] m_axis_tdata,

    input  logic        alternating_bit,
    output logic        busy
 );

reg reg_busy = 1'b0;
assign busy = reg_busy;

reg [31:0] timeout_counter = 32'h0000_0000;

reg       reg_tvalid;
reg       reg_tlast;
reg [7:0] reg_tdata;
assign m_axis_tlast = reg_tlast;
assign m_axis_tvalid = reg_tvalid;
assign m_axis_tdata = reg_tdata;
    

reg        c_alternating_bit = 1'b0;
reg [31:0] packet_counter = 32'h0000_0000;

typedef enum logic [3:0] {
    RESET_STATE,
    NEW_DATA,
    ACK_SENDING,
    ACK_TIMEOUT
} transmitter_state;
transmitter_state state;

always_ff @ (posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        reg_busy <= 1'b0;
        timeout_counter <= 32'h0000_0000;
        packet_counter  <= 32'h0000_0000;
        c_alternating_bit <= 1'b0;
        reg_tvalid <= 1'b0;
        reg_tla = 8'd0;st <= 1'b0;
        reg_tdata <= 8'h00;
        state <= RESET_STATE;
    end else begin
        case (state)
            RESET_STATE: begin
                state <= NEW_DATA;
            end

            NEW_DATA: begin
                // latch new alternating bit
                c_alternating_bit <= alternating_bit;
                packet_counter <= 32'h0000_0000;
                state <= ACK_SENDING;
            end

            ACK_SENDING: begin
                if (m_axis_tready) begin
                    if (packet_counter < 63) begin
                        reg_busy <= 1'b1;
                        reg_tdata <= 8'd0;
                        reg_tvalid <= 1'b1;
                        reg_tlast <= 1'b0;
                        packet_counter <= packet_counter + 1;
                        state <= ACK_SENDING;
                    end else if (packet_counter == 63) begin
                        reg_tdata <= {7'd0, c_alternating_bit};
                        reg_tlast <= 1'b1;
                        reg_tvalid <= 1'b1;
                        packet_counter <= packet_counter + 1;
                        state <= ACK_SENDING;
                    end else begin
                        reg_tlast <= 1'b0;
                        reg_tvalid <= 1'b0;
                        reg_busy <= 1'b0;
                        packet_counter <= 32'd0;
                        state <= ACK_TIMEOUT;
                    end
                end
            end
            ACK_TIMEOUT: begin
                if (timeout_counter < TIMEOUT_DURATION) begin
                    if (c_alternating_bit != alternating_bit) begin
                        timeout_counter <= 32'h0000_0000;
                        state <= NEW_DATA;
                    end else begin
                        timeout_counter <= timeout_counter + 1'b1;
                        state <= ACK_TIMEOUT;
                    end
                end else begin
                    timeout_counter <= 32'h0000_0000;
                    state <= ACK_SENDING;
                end
            end
        endcase
    end
end

 endmodule