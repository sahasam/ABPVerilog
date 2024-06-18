`timescale 1ns / 1ps

module bram #(
    parameter integer ADDRESS_WIDTH = 6,
    parameter integer DATA_WIDTH = 8
)(
    input  logic clk,
    input  logic we,

    input  logic [DATA_WIDTH-1:0] data_in,
    input  logic [ADDRESS_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] data_out
);

reg [DATA_WIDTH-1:0] mem [2**ADDRESS_WIDTH-1];

always_ff @ (posedge clk) begin
    if (we) begin
        mem[addr] <= data_in;
    end
end

assign data_out = mem[addr];


endmodule
