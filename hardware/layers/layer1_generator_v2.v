`timescale 1ns / 1ps

`ifndef LAYER1_GENERATOR_V2_V
`define LAYER1_GENERATOR_V2_V

// Layer 1 Generator (v2 - New Architecture)
// Input: 64 neurons (Q5.10 seed vector)
// Output: 256 neurons (Q5.10 pre-activation)
// Weight matrix: 256×64
// No activation function (goes to external ReLU stage)
//
module layer1_generator_v2 (
    input wire clk,
    input wire rst,
    input wire start,
    // Flattened input: 64 elements × 16 bits = 1024 bits
    input wire signed [16*64-1:0] flat_input,
    // Flattened output: 256 elements × 16 bits = 4096 bits
    output reg signed [16*256-1:0] flat_output,
    output reg done
);

    // Memory for weights and biases (Q5.10 format)
    (* rom_style = "block" *) reg signed [15:0] weights [0:16383]; // 256×64
    (* rom_style = "block" *) reg signed [15:0] biases [0:255];

    localparam TOTAL_NEURONS = 256;
    localparam TOTAL_INPUTS = 64;
    
    initial begin
        $readmemh("mem/epoch300_G_l1_W.mem", weights);
        $readmemh("mem/epoch300_G_l1_B.mem", biases);
    end

    // Sequential MAC computation
    reg [8:0] neuron_idx;  // 0..255
    reg [6:0] input_idx;   // 0..63
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
            input_idx <= 7'd0;
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
                input_idx <= 7'd0;
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
                    
                    input_idx <= input_idx + 7'd1;
                end else begin
                    // Accumulate last product and write result
                    accumulator <= accumulator + {{16{product[31]}}, product};
                    
                    // Extract Q5.10 from Q15.32 accumulator
                    flat_output[(TOTAL_NEURONS - 1 - neuron_idx) * 16 +: 16] <= {accumulator[47], accumulator[36:22]};
                    
                    if (neuron_idx < TOTAL_NEURONS - 1) begin
                        // Move to next neuron
                        neuron_idx <= neuron_idx + 9'd1;
                        input_idx <= 7'd0;
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

`endif // LAYER1_GENERATOR_V2_V
