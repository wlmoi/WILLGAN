// tanh_lut.v
// Simple Tanh using lookup table for Q6.10 input, Q6.10 output
// For demonstration, LUT size is small. For real use, expand LUT size.
module tanh_lut #(parameter W = 16, parameter ADDR_BITS = 8) (
    input  signed [W-1:0] in,
    output signed [W-1:0] out
);
    reg signed [W-1:0] lut [0:(1<<ADDR_BITS)-1];
    wire [ADDR_BITS-1:0] addr = in[ADDR_BITS-1:0];
    initial begin
        // Example LUT: fill with tanh values scaled to Q6.10
        // For real use, generate with Python/Matlab
        lut[0] = 0; lut[1] = 13; lut[2] = 26; // ... dst
        // ... isi seluruh LUT sesuai kebutuhan ...
    end
    assign out = lut[addr];
endmodule
