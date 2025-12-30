`timescale 1ns / 1ps

`ifndef LAYER3_DISCRIMINATOR_V2_V
`define LAYER3_DISCRIMINATOR_V2_V

// Layer 3 Discriminator (v2 - New Architecture)
// Input: 256 neurons (from LeakyReLU stage)
// Output: 1 neuron (discriminator score)
// Weight matrix: 1×256
// No activation function (output goes to sigmoid)
//
module layer3_discriminator_v2 (
    input wire clk,
    input wire rst,
    input wire start,
    // Flattened input: 256 elements × 16 bits = 4096 bits
    input wire signed [16*256-1:0] flat_input,
    // Single output: 16-bit Q5.10
    output reg signed [15:0] output_score,
    output reg done
);

    // Memory for weights and biases (Q5.10 format)
    (* rom_style = "block" *) reg signed [15:0] weights [0:255]; // 1×256
    (* rom_style = "block" *) reg signed [15:0] bias;
    (* rom_style = "block" *) reg signed [15:0] bias_mem [0:0]; // For $readmemh compatibility

    localparam TOTAL_INPUTS = 256;
    
    // For simulation only. Remove or guard for synthesis.
    `ifndef SYNTHESIS
    initial begin
        $readmemh("mem/epoch300_C_l3_W.mem", weights);
        // Read single bias value into memory, lalu copy ke scalar
        $readmemh("mem/epoch300_C_l3_B.mem", bias_mem);
        bias = bias_mem[0];
    end
    `endif

    // Sequential MAC computation
    reg [8:0] input_idx;   // 0..255
    reg busy;
    reg signed [35:0] accumulator;  // Q10.20 accumulator
    
    reg signed [15:0] current_input;
    reg signed [15:0] current_weight;
    wire signed [31:0] product;
    
    // MAC: accumulator += input * weight
    assign product = current_input * current_weight;
    
    always @(posedge clk) begin
        if (rst) begin
            input_idx <= 9'd0;
            busy <= 1'b0;
            done <= 1'b0;
            accumulator <= 36'sd0;
            output_score <= 16'sd0;
        end else begin
            if (start && !busy) begin
                // Start computation
                busy <= 1'b1;
                done <= 1'b0;
                input_idx <= 9'd0;
                // Initialize accumulator with bias
                accumulator <= { {10{bias[15]}}, bias, 10'b0 };
            end else if (busy) begin
                if (input_idx < TOTAL_INPUTS) begin
                    // Load current input and weight
                    current_input <= flat_input[(TOTAL_INPUTS - 1 - input_idx) * 16 +: 16];
                    current_weight <= weights[input_idx];
                    
                    if (input_idx > 0) begin
                        // Accumulate previous product
                        accumulator <= accumulator + {{4{product[31]}}, product};
                    end
                    
                    input_idx <= input_idx + 9'd1;
                end else begin
                    // Accumulate last product and write result
                    accumulator <= accumulator + {{4{product[31]}}, product};
                    
                    // Extract Q5.10 from Q10.20 accumulator
                    output_score <= accumulator[28:13];
                    
                    // Computation complete
                    busy <= 1'b0;
                    done <= 1'b1;
                end
            end else if (done) begin
                done <= 1'b0;  // Clear done after 1 cycle
            end
        end
    end

endmodule

`endif // LAYER3_DISCRIMINATOR_V2_V
