// LeakyReLU activation module (parameterizable slope)
// Input: signed [15:0] in_val (Q6.10)
// Output: signed [15:0] out_val (Q6.10)
// Slope: parameter SLOPE_NUM/SLOPE_DEN (e.g. 1/8)

module leaky_relu #(parameter SLOPE_NUM = 1, parameter SLOPE_DEN = 8) (
    input  signed [15:0] in_val,
    output signed [15:0] out_val
);
    wire sign = in_val[15];
    wire signed [15:0] neg_val = (in_val * SLOPE_NUM) / SLOPE_DEN;
    assign out_val = sign ? neg_val : in_val;
endmodule
