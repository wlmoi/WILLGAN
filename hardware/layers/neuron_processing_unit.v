`timescale 1ns / 1ps
// neuron_processing_unit.v
// 8x parallel Q6.10 MACs with saturation
// Each MAC: acc = acc + (a * b) >>> 10 (Q6.10)

module neuron_processing_unit #(
    parameter DATA_WIDTH = 16
) (
    input  wire signed [DATA_WIDTH-1:0] a0, input wire signed [DATA_WIDTH-1:0] a1, input wire signed [DATA_WIDTH-1:0] a2, input wire signed [DATA_WIDTH-1:0] a3,
    input  wire signed [DATA_WIDTH-1:0] a4, input wire signed [DATA_WIDTH-1:0] a5, input wire signed [DATA_WIDTH-1:0] a6, input wire signed [DATA_WIDTH-1:0] a7,
    input  wire signed [DATA_WIDTH-1:0] b0, input wire signed [DATA_WIDTH-1:0] b1, input wire signed [DATA_WIDTH-1:0] b2, input wire signed [DATA_WIDTH-1:0] b3,
    input  wire signed [DATA_WIDTH-1:0] b4, input wire signed [DATA_WIDTH-1:0] b5, input wire signed [DATA_WIDTH-1:0] b6, input wire signed [DATA_WIDTH-1:0] b7,
    input  wire signed [DATA_WIDTH-1:0] acc0, input wire signed [DATA_WIDTH-1:0] acc1, input wire signed [DATA_WIDTH-1:0] acc2, input wire signed [DATA_WIDTH-1:0] acc3,
    input  wire signed [DATA_WIDTH-1:0] acc4, input wire signed [DATA_WIDTH-1:0] acc5, input wire signed [DATA_WIDTH-1:0] acc6, input wire signed [DATA_WIDTH-1:0] acc7,
    output wire signed [DATA_WIDTH-1:0] y0, output wire signed [DATA_WIDTH-1:0] y1, output wire signed [DATA_WIDTH-1:0] y2, output wire signed [DATA_WIDTH-1:0] y3,
    output wire signed [DATA_WIDTH-1:0] y4, output wire signed [DATA_WIDTH-1:0] y5, output wire signed [DATA_WIDTH-1:0] y6, output wire signed [DATA_WIDTH-1:0] y7
);
    // Manual instantiation for 8 MACs (Verilog-2001 compatible)
    wire signed [15:0] mul_out0, mul_out1, mul_out2, mul_out3, mul_out4, mul_out5, mul_out6, mul_out7;
    fixed_point_alu alu0 (.a(a0), .b(b0), .y(mul_out0));
    fixed_point_alu alu1 (.a(a1), .b(b1), .y(mul_out1));
    fixed_point_alu alu2 (.a(a2), .b(b2), .y(mul_out2));
    fixed_point_alu alu3 (.a(a3), .b(b3), .y(mul_out3));
    fixed_point_alu alu4 (.a(a4), .b(b4), .y(mul_out4));
    fixed_point_alu alu5 (.a(a5), .b(b5), .y(mul_out5));
    fixed_point_alu alu6 (.a(a6), .b(b6), .y(mul_out6));
    fixed_point_alu alu7 (.a(a7), .b(b7), .y(mul_out7));
    assign y0 = acc0 + mul_out0;
    assign y1 = acc1 + mul_out1;
    assign y2 = acc2 + mul_out2;
    assign y3 = acc3 + mul_out3;
    assign y4 = acc4 + mul_out4;
    assign y5 = acc5 + mul_out5;
    assign y6 = acc6 + mul_out6;
    assign y7 = acc7 + mul_out7;
endmodule
