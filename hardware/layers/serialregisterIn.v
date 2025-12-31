`timescale 1ns / 1ps

// Modul Serial Register Input
// Menyimpan 784 data 16 bit secara serial (1 data/clock)
// Vivado compatible, hardware sharing
module serialregisterIn #(
    parameter DATA_WIDTH = 16,
    parameter DEPTH = 784
) (
    input wire clk,
    input wire rst,
    input wire en, // enable input
    input wire [DATA_WIDTH-1:0] din,
    output reg done,
    // Optional: output for reading memory content
    input wire [$clog2(DEPTH)-1:0] rd_addr,
    output reg [DATA_WIDTH-1:0] dout
);
    reg [$clog2(DEPTH):0] count;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            done <= 0;
        end else if (en) begin
            if (count < DEPTH) begin
                mem[count] <= din;
                count <= count + 1;
                done <= 0;
            end else begin
                done <= 1;
            end
        end
    end
    // Output memory content for testbench/monitor
    always @(*) begin
        dout = mem[rd_addr];
    end
endmodule
