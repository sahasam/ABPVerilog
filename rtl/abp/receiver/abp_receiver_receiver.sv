/* Alternating Bit Protocol: Receiver Side: Packet Receiver
 * Sahas Munamala 06/09/2024
 */

`timescale 1 ps/1 ps

module abp_receiver_receiver (
    input  logic        aclk,
    input  logic        aresetn,

    input  logic        s_axis_tvalid,
    output logic        s_axis_tready,
    input  logic        s_axis_tlast,
    input  logic [7:0]  s_axis_tdata,

    output logic        busy,
    output logic [63:0] sender_value,
    input  logic        expected_bit,
    output logic        recv_flag
);

reg        r_busy = 1'b0;
reg [63:0] r_sender_value = 64'd0;
reg        r_recv_flag = 1'd0;
reg        r_tready = 1'd0;

reg   [5:0]  r_addr = 6'd0;
reg          r_we = 1'b0;
logic [7:0]  l_dout;
reg   [7:0]  r_din = 8'd0;

assign busy = r_busy;
assign sender_value = r_sender_value;
assign recv_flag = r_recv_flag;
assign s_axis_tready = r_tready;

typedef enum logic [3:0] {
    RESET_STATE,
    WAITING,
    RECEIVING,
    CHECK_BIT,
    ANALYSIS,
    DONE
} transmitter_state_t;
transmitter_state_t state;

//64x8 bram
bram #(
    .ADDRESS_WIDTH(6),
    .DATA_WIDTH(8)
) bram_inst (
    .clk      (aclk),
    .we       (r_we),
    .addr     (r_addr),
    .data_in  (r_din),
    .data_out (l_dout)
);


always_ff @ (posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        state <= RESET_STATE;
    end else begin
        case (state)
            RESET_STATE: begin
                r_busy <= 1'b0;
                r_sender_value <= 64'd0;
                r_recv_flag <= 1'b0;
                r_addr <= 6'd0;
                r_we <= 1'd0;
                r_din <= 8'h00;
                state <= WAITING;
            end

            WAITING: begin
                r_tready <= 1'b1;
                if (!s_axis_tvalid) begin
                    r_busy <= 1'b0;
                    r_addr <= 6'd0;
                    r_we   <= 1'b0;
                    state  <= WAITING;
                end else begin
                    r_busy <= 1'b1;
                    r_addr <= 6'd0;
                    r_din  <= s_axis_tdata;
                    r_we   <= 1'b1;
                    state  <= RECEIVING;
                end
            end

            RECEIVING: begin
                if (s_axis_tvalid) begin
                    if (r_addr < 6'd63) begin
                        r_din  <= s_axis_tdata;
                        r_we   <= 1'b1;
                        if (s_axis_tlast) begin
                            r_tready <= 1'b0;
                            state    <= ANALYSIS;
                        end else begin
                            r_addr <= r_addr + 1;
                            r_tready <= 1'b1;
                            state  <= RECEIVING;
                        end
                    end else begin
                        // If the packet is too long, stop writing, but read until tlast.
                        if (s_axis_tlast) begin
                            r_we <= 1'b0;
                            r_tready <= 1'b0;
                            state <= CHECK_BIT;
                        end
                        r_we <= 1'b0;
                        r_tready <= 1'b0;
                    end
                end else begin
                    if (l_dout[0] == expected_bit) begin
                        state <= ANALYSIS;
                    end
                end
            end

            CHECK_BIT: begin
            end

            ANALYSIS: begin
                // Perform Sequential Reads
                r_we <= 1'b0;
                r_tready <= 1'b0;
                case (r_addr)
                    6'd0: r_sender_value[7:0] <= l_dout;
                    6'd1: r_sender_value[15:8] <= l_dout;
                    6'd2: r_sender_value[23:16] <= l_dout;
                    6'd3: r_sender_value[31:24] <= l_dout;
                    6'd4: r_sender_value[39:32] <= l_dout;
                    6'd5: r_sender_value[47:40] <= l_dout;
                    6'd6: r_sender_value[55:48] <= l_dout;
                    6'd7: r_sender_value[63:56] <= l_dout;
                    default: r_sender_value[7:0] <= l_dout;
                endcase
                if (r_addr == 6'd7) begin
                    state <= DONE;
                end else begin
                    r_addr <= r_addr + 1;
                end
            end

            DONE: begin
                r_tready <= 1'b0;
            end

            default: begin
            end
        endcase
    end
end

endmodule
