// relu.v
// Simple ReLU module for Q6.10 fixed-point
module relu #(parameter N = 16) (
    input  signed [N-1:0] in,
    output signed [N-1:0] out
);
    assign out = (in[N-1] == 1'b1) ? {N{1'b0}} : in;
endmodule

