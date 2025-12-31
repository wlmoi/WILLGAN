`timescale 1ns / 1ps

// Modul Serial Register Output
// Mengeluarkan 784 data 16 bit secara serial (1 data/clock)
// Vivado compatible, hardware sharing
module serialregisterOut #(
    parameter DATA_WIDTH = 16,
    parameter DEPTH = 784
) (
    input wire clk,
    input wire rst,
    input wire en, // enable output
    input wire wr_en,
    input wire [$clog2(DEPTH)-1:0] wr_addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    output reg done
);
    reg [$clog2(DEPTH):0] count;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write logic (for testbench or upstream logic)
    always @(posedge clk) begin
        if (wr_en)
            mem[wr_addr] <= din;
    end

    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            dout <= 0;
            done <= 0;
        end else if (en) begin
            if (count < DEPTH) begin
                dout <= mem[count];
                count <= count + 1;
                done <= 0;
            end else begin
                done <= 1;
            end
        end
    end
endmodule
