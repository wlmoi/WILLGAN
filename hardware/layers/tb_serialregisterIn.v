`timescale 1ns / 1ps

// Testbench untuk serialregisterIn
module tb_serialregisterIn;
    parameter DATA_WIDTH = 16;
    parameter DEPTH = 784;
    reg clk, rst, en;
    reg [DATA_WIDTH-1:0] din;
    reg [$clog2(DEPTH)-1:0] rd_addr;
    wire [DATA_WIDTH-1:0] dout;
    wire done;

    serialregisterIn #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .din(din),
        .done(done),
        .rd_addr(rd_addr),
        .dout(dout)
    );

    integer i;

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; en = 0; din = 0; rd_addr = 0;
        #20;
        rst = 0; en = 1;
        for (i = 0; i < DEPTH; i = i + 1) begin
            din = i;
            #10;
        end
        en = 0;
        #50;
        // Cek isi mem via dout
        rd_addr = 0; #1;
        $display("Done: %b", done);
        $display("mem[0]=%d", dout);
        rd_addr = DEPTH-1; #1;
        $display("mem[DEPTH-1]=%d", dout);
        $finish;
    end
endmodule
