`timescale 1ns / 1ps

// Testbench untuk serialregisterOut
module tb_serialregisterOut;
    parameter DATA_WIDTH = 16;
    parameter DEPTH = 784;
    reg clk, rst, en;
    reg wr_en;
    reg [$clog2(DEPTH)-1:0] wr_addr;
    reg [DATA_WIDTH-1:0] din;
    wire [DATA_WIDTH-1:0] dout;
    wire done;

    serialregisterOut #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .din(din),
        .dout(dout),
        .done(done)
    );

    integer i;

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; en = 0; wr_en = 0; wr_addr = 0; din = 0;
        // Inisialisasi mem internal
        for (i = 0; i < DEPTH; i = i + 1) begin
            wr_en = 1; wr_addr = i; din = i + 1000;
            #10;
        end
        wr_en = 0;
        #20;
        rst = 0; en = 1;
        for (i = 0; i < DEPTH; i = i + 1) begin
            #10;
            $display("dout[%0d]=%d", i, dout);
        end
        en = 0;
        #50;
        $display("Done: %b", done);
        $finish;
    end
endmodule
