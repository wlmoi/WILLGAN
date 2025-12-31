`timescale 1ns / 1ps
// fixed_point_alu.v
// Q6.10 fixed-point multiply, shift, saturate
// 16-bit signed input/output
// result = SATURATE((a * b) >>> 10)

module fixed_point_alu (
    input  wire signed [15:0] a,
    input  wire signed [15:0] b,
    output reg  signed [15:0] y
);
    wire signed [31:0] mult;
    wire signed [31:0] shifted;
    assign mult = a * b; // Q6.10 * Q6.10 = Q12.20
    assign shifted = mult >>> 10; // Q6.10

    always @(*) begin
        // Saturate to 16-bit signed
        if (shifted > 32'sh7FFF)
            y = 16'sh7FFF;
        else if (shifted < -32'sh8000)
            y = -16'sh8000;
        else
            y = shifted[15:0];
    end
endmodule
