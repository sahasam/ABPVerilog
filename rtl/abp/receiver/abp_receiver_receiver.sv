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

reg          r_busy = 1'b0;
reg [63:0]   r_sender_value = 64'd0;
reg          r_recv_flag = 1'd0;
logic        r_tready = 1'b0;
logic        r_tlast = 1'b0;
logic        r_tvalid = 1'b0;
logic [31:0] byte_count = 32'd0;
logic [5:0]  bram_addr = 6'd0;

reg          write_enable = 1'b0;
wire  [7:0]  l_dout;
logic [7:0]  bram_data_in;
wire  [7:0]  bram_data_out;
logic        alternating_bit = 1'd0;
logic        checked_bit_flag = 1'd0;
bit          new_value_flag = 1'd0;
logic        cb_start;

assign busy = r_busy;
assign sender_value = r_sender_value;
assign recv_flag = r_recv_flag;
assign s_axis_tready = r_tready;

typedef enum logic [3:0] {
    RESET_STATE,
    IDLE,
    RECEIVING,
    CHECK_BIT,
    READ_DATA,
    DONE
} transmitter_state_t;
transmitter_state_t state, next_state;

typedef enum logic [3:0] {
    CB_IDLE,
    READ,
    CHECK
} cbstate_t;
cbstate_t cbstate;

//64x8 bram
bram #(
    .ADDRESS_WIDTH(6),
    .DATA_WIDTH(8)
) bram_inst (
    .clk     (aclk),
    .we      (write_enable),
    .en      (1'b1),
    .addr    (bram_addr),
    .data_in     (bram_data_in),
    .data_out    (bram_data_out)
);

always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        state <= RESET_STATE;
        cbstate <= CB_IDLE;
        cb_start <= 1'b0;
    end else begin
        state <= next_state;
        r_tlast <= s_axis_tlast;
        r_tvalid <= s_axis_tvalid;

        case (state)
            RESET_STATE: begin
                r_busy <= 1'b0;
                r_sender_value <= 64'd0;
                r_recv_flag <= 1'b0;
                bram_addr <= 6'd0;
                write_enable <= 1'd0;
            end

            IDLE: begin
                r_tready <= 1'b1;
                bram_addr <= 6'd0;
                if (s_axis_tready) begin
                    write_enable <= 1'b1;
                    bram_data_in <= s_axis_tdata;
                    byte_count <= 32'd1;
                end
            end

            RECEIVING: begin
                r_tready <= 1'b1;
                byte_count <= byte_count + 1;
                if (r_tvalid & r_tlast) begin
                    write_enable <= 1'b0;
                    cb_start     <= 1'b1;
                    bram_addr    <= 6'h3F;
                end else if (r_tvalid) begin
                    write_enable <= 1'b1;
                    bram_data_in <= s_axis_tdata;
                    bram_addr <= bram_addr + 1;
                end
            end

            CHECK_BIT: begin
                write_enable <= 1'b0;
                r_tready <= 1'b0;
            end

            default: begin end
        endcase
    end
end

always_comb begin
    case (state)
        RESET_STATE: begin
            next_state = IDLE;
        end

        IDLE: begin
            if (s_axis_tvalid) begin
                bram_addr = 6'd0;
                write_enable   = 1'b1;
                next_state = RECEIVING;
            end else begin
                r_tready = 1'b1;
                bram_addr = 6'd0;
                write_enable   = 1'b0;
            end
        end

        RECEIVING: begin
            if (s_axis_tvalid & r_tlast) begin
                if (byte_count < 64) begin
                    next_state = IDLE;
                end else if (byte_count > 64) begin
                    next_state = IDLE;
                end else begin
                    next_state = CHECK_BIT;
                end
            end
        end

        CHECK_BIT: begin
            if (checked_bit_flag) begin
                next_state = new_value_flag ? READ_DATA : IDLE;
            end
        end

        READ_DATA: begin
            next_state = IDLE;
        end

        default: begin end
    endcase
end

always_ff @ (posedge aclk or negedge aresetn) begin
    if (state == CHECK_BIT) begin
        case (cbstate)
            CB_IDLE: begin
                if (cb_start & 1'b1) begin
                    cbstate <= READ;
                    cb_start <= 1'b0;
                    write_enable <= 1'b0;
                end
            end

            READ: begin
                cbstate <= CHECK;
            end

            CHECK: begin
                checked_bit_flag <= 1'b1;
                new_value_flag <= ~(expected_bit ^ bram_data_out[0]);
                cbstate <= CB_IDLE;
            end

            default: begin end
        endcase
    end else begin
        cbstate <= CB_IDLE;
    end
end

endmodule
