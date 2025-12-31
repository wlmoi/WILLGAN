`timescale 1ns / 1ps
// tb_top_entity.v
// Testbench for top_entity (WGAN Generator Top Level)
`include "top_entity.v"

module tb_top_entity();
    reg clk;
    reg rst_n;
    reg start;
    reg [15:0] data_in;
    wire [15:0] data_out;
    wire valid;
    wire busy;

    // Instantiate DUT
    top_entity dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .data_in(data_in),
        .data_out(data_out),
        .valid(valid),
        .busy(busy)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    // Test stimulus
    integer i;
    initial begin
        // Inisialisasi
        rst_n = 0;
        start = 0;
        data_in = 0;
        #20;
        rst_n = 1;
        #20;
        // Simulasi tombol start (pulse)
        start = 1;
        #10;
        start = 0;
        // Kirim 64 data input (serial)
        for (i = 0; i < 64; i = i + 1) begin
            data_in = i;
            #10;
        end
        // Tunggu busy low (output siap)
        wait (busy == 0);
        // Baca output (serial)
        for (i = 0; i < 784; i = i + 1) begin
            if (valid) $display("Output[%0d] = %h", i, data_out);
            #10;
        end
        $finish;
    end
endmodule
