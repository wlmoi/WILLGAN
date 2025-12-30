`timescale 1ns / 1ps

module tanh_tb;
    reg signed [15:0] in;
    wire signed [15:0] out;
    integer i;
    tanh uut (.in(in), .out(out));
    initial begin
        $display("Tanh Test (Q6.10):");
        for (i = -2048; i <= 2048; i = i + 256) begin
            in = i;
            #1;
            $display("in=%0d (hex=%h) out=%0d (hex=%h)", in, in, out, out);
        end
        $finish;
    end
endmodule
