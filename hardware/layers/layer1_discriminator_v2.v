`timescale 1ns / 1ps

`ifndef LAYER1_DISCRIMINATOR_V2_V
`define LAYER1_DISCRIMINATOR_V2_V

// Layer 1 Discriminator (v2 - New Architecture)
// Input: 784 neurons (image pixels, Q5.10)
// Output: 256 neurons (Q5.10 pre-activation)
// Weight matrix: 256×784
// No activation function (goes to external LeakyReLU stage)
//
module layer1_discriminator_v2 (
    input wire clk,
    input wire rst,
    input wire start,
    // Flattened input: 784 elements × 16 bits = 12544 bits
    input wire signed [16*784-1:0] flat_input,
    // Flattened output: 256 elements × 16 bits = 4096 bits
    output reg signed [16*256-1:0] flat_output,
    output reg done
);

    // Memory for weights and biases (Q5.10 format)
    (* rom_style = "block" *) reg signed [15:0] weights [0:200703]; // 256×784
    (* rom_style = "block" *) reg signed [15:0] biases [0:255];

    localparam TOTAL_NEURONS = 256;
    localparam TOTAL_INPUTS = 784;
    
    // For simulation only. Remove or guard for synthesis.
    `ifndef SYNTHESIS
    initial begin
        $readmemh("mem/epoch300_C_l1_W.mem", weights);
        $readmemh("mem/epoch300_C_l1_B.mem", biases);
    end
    `endif

    // Sequential MAC computation
    reg [8:0] neuron_idx;   // 0..255
    reg [9:0] input_idx;    // 0..783
    reg busy;
    reg signed [47:0] accumulator;  // Q15.32 accumulator for higher precision
    
    reg signed [15:0] current_input;
    reg signed [15:0] current_weight;
    reg signed [15:0] current_bias;
    wire signed [31:0] product;
    
    // MAC: accumulator += input * weight
    assign product = current_input * current_weight;
    
    always @(posedge clk) begin
        if (rst) begin
            neuron_idx <= 9'd0;
            input_idx <= 10'd0;
            busy <= 1'b0;
            done <= 1'b0;
            accumulator <= 48'sd0;
            flat_output <= {(16*256){1'b0}};
        end else begin
            if (start && !busy) begin
                // Start computation
                busy <= 1'b1;
                done <= 1'b0;
                neuron_idx <= 9'd0;
                input_idx <= 10'd0;
                // Load first bias
                current_bias <= biases[0];
                accumulator <= { {10{biases[0][15]}}, biases[0], 22'b0 };
            end else if (busy) begin
                if (input_idx < TOTAL_INPUTS) begin
                    // Load current input and weight
                    current_input <= flat_input[(TOTAL_INPUTS - 1 - input_idx) * 16 +: 16];
                    current_weight <= weights[neuron_idx * TOTAL_INPUTS + input_idx];
                    
                    if (input_idx > 0) begin
                        // Accumulate previous product
                        accumulator <= accumulator + {{16{product[31]}}, product};
                    end
                    
                    input_idx <= input_idx + 10'd1;
                end else begin
                    // Accumulate last product and write result
                    accumulator <= accumulator + {{4{product[31]}}, product};
                    
                    // Extract Q5.10 from Q10.20 accumulator with scaling
                    // Divide by 8 (right shift 3) to manage accumulation overflow
                    flat_output[(TOTAL_NEURONS - 1 - neuron_idx) * 16 +: 16] <= accumulator[28:13];
                    
                    if (neuron_idx < TOTAL_NEURONS - 1) begin
                        // Move to next neuron
                        neuron_idx <= neuron_idx + 9'd1;
                        input_idx <= 10'd0;
                        current_bias <= biases[neuron_idx + 9'd1];
                        accumulator <= { {10{biases[neuron_idx + 9'd1][15]}}, biases[neuron_idx + 9'd1], 22'b0 };
                    end else begin
                        // All neurons complete
                        busy <= 1'b0;
                        done <= 1'b1;
                    end
                end
            end else if (done) begin
                done <= 1'b0;  // Clear done after 1 cycle
            end
        end
    end

endmodule

`endif // LAYER1_DISCRIMINATOR_V2_V
