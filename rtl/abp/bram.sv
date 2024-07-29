`timescale 1ns / 1ns

module bram #(
    parameter integer ADDRESS_WIDTH = 6,
    parameter integer DATA_WIDTH = 8
)(
    input        clk,
    input        we,
    input        en,

    input        [DATA_WIDTH-1:0] data_in,
    output reg   [DATA_WIDTH-1:0] data_out,
    input        [ADDRESS_WIDTH-1:0] addr
);

logic [DATA_WIDTH-1:0] mem [2**ADDRESS_WIDTH];
logic [ADDRESS_WIDTH-1:0] addr_reg;

always_ff @ (posedge clk) begin
    if (en) begin
        if (we) begin
            mem[addr] <= data_in;
        end else begin
            data_out <= mem[addr];
        end
    end
end

endmodule
