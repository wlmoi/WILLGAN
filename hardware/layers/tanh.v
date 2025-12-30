
// tanh_lut.v
// Piecewise linear tanh approximation for Q6.10 input/output
// out = x/2 for |x| < 1.5, saturate to +/-1 for large |x|
module tanh #(parameter W = 16) (
    input  signed [W-1:0] in,
    output reg signed [W-1:0] out
);
    // Q6.10: 1.0 = 1024, 1.5 = 1536, max = 2047
    localparam signed [W-1:0] POS_THRESH = 11'sd1536; // +1.5
    localparam signed [W-1:0] NEG_THRESH = -11'sd1536; // -1.5
    localparam signed [W-1:0] MAX = 11'sd1024; // +1.0
    localparam signed [W-1:0] MIN = -11'sd1024; // -1.0

    always @* begin
        if (in >= POS_THRESH)
            out = MAX;
        else if (in <= NEG_THRESH)
            out = MIN;
        else
            out = in >>> 1; // x/2
    end
endmodule
