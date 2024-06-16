/* Alternating bit protocol. Receiver Side.
 * Sahas Munamala - 6/3/2024
 */
module abp_receiver (
    input  logic       aclk,
    input  logic       aresetn,

    input  logic       s_axis_tvalid,
    output logic       s_axis_tready,
    input  logic       s_axis_tlast,
    input  logic [7:0] s_axis_tdata,

    output logic       m_axis_tvalid,
    input  logic       m_axis_tready,
    output logic       m_axis_tlast,
    output logic [7:0] m_axis_tdata
);

reg alternating_bit = 1'b0;
reg [63:0] sender_value = 64'h0000_0000_0000_0000;
logic f_ack_received;

always @ (posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        alternating_bit <= 1'b0;
        sender_value <= 1'b0;
    end
    else begin
        alternating_bit <= ~alternating_bit;
        sender_value <= sender_value + 1'b1;
    end
end

abp_receiver_transmitter #(
    .TIMEOUT_DURATION(10)
) abp_receiver_transmitter_inst (
    .aclk      (aclk),
    .aresetn   (aresetn),

    .m_axis_tvalid (m_axis_tvalid),
    .m_axis_tready (m_axis_tready),
    .m_axis_tlast  (m_axis_tlast),
    .m_axis_tdata  (m_axis_tdata),

    .alternating_bit (alternating_bit),
    .sender_value    (sender_value)
);

abp_receiver_receiver abp_receiver_receiver_inst (
    .clk,
    .aresetn,
    
    .s_axis_tvalid,
    .s_axis_tready,
    .s_axis_tlast,
    .s_axis_tdata,

    .busy            (),
    .expected_bit    (alternating_bit),
    .ack_received    (f_ack_received),
    .recv_flag       ()
);


endmodule