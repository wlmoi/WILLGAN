`timescale 1ns / 1ps

`ifndef LAYER3_GENERATOR_V2_V
`define LAYER3_GENERATOR_V2_V

// Layer 3 Generator (v2 - New Architecture)
// Input: 256 neurons (Q5.10 from ReLU stage)
// Output: 784 neurons (Q5.10 pre-activation, 28×28 image)
// Weight matrix: 784×256
// No activation function (goes to external tanh stage)
//
module layer3_generator_v2 (
    input wire clk,
    input wire rst,
    input wire start,
    // Flattened input: 256 elements × 16 bits = 4096 bits
    input wire signed [16*256-1:0] flat_input,
    // Flattened output: 784 elements × 16 bits = 12544 bits
    output reg signed [16*784-1:0] flat_output,
    output reg done
);

    // Memory for weights and biases (Q5.10 format)
    (* rom_style = "block" *) reg signed [15:0] weights [0:200703]; // 784×256
    (* rom_style = "block" *) reg signed [15:0] biases [0:783];

    localparam TOTAL_NEURONS = 784;
    localparam TOTAL_INPUTS = 256;
    
    initial begin
        $readmemh("mem/epoch300_G_l3_W.mem", weights);
        $readmemh("mem/epoch300_G_l3_B.mem", biases);
    end

    // Sequential MAC computation
    reg [9:0] neuron_idx;  // 0..783
    reg [8:0] input_idx;   // 0..255
    reg busy;
    reg signed [47:0] accumulator;  // Q15.32 accumulator for higher precision
    
    reg signed [15:0] current_input;
    reg signed [15:0] current_weight;
    reg signed [15:0] current_bias;
    wire signed [31:0] product;
    
    // MAC: accumulator += input * weight
    assign product = current_input * current_weight;
    
    // Output pipeline registers
    reg signed [15:0] acc_out_reg;
    reg [9:0] neuron_idx_out_reg;
    reg write_output_reg;
    integer memfile;
    reg output_written;
    reg pipeline_valid;

    always @(posedge clk) begin
        if (rst) begin
            neuron_idx <= 10'd0;
            input_idx <= 9'd0;
            busy <= 1'b0;
            done <= 1'b0;
            accumulator <= 48'sd0;
            flat_output <= {(16*784){1'b0}};
            acc_out_reg <= 16'sd0;
            neuron_idx_out_reg <= 10'd0;
            write_output_reg <= 1'b0;
            output_written <= 1'b0;
            pipeline_valid <= 1'b0;
        end else begin
            if (start && !busy) begin
                // Start computation
                busy <= 1'b1;
                done <= 1'b0;
                neuron_idx <= 10'd0;
                input_idx <= 9'd0;
                // Load first bias (Q5.10, sign-extended, no shift)
                current_bias <= biases[0];
                accumulator <= { {32{biases[0][15]}}, biases[0] };
            end else if (busy) begin
                if (input_idx < TOTAL_INPUTS) begin
                    // Load current input and weight
                    current_input <= flat_input[(TOTAL_INPUTS - 1 - input_idx) * 16 +: 16];
                    current_weight <= weights[neuron_idx * TOTAL_INPUTS + input_idx];
                    // Accumulate product (Q5.10 * Q5.10 >> 10 = Q5.10)
                    accumulator <= accumulator + (product >>> 10);
                    input_idx <= input_idx + 9'd1;
                end else begin
                    // Prepare output pipeline
                    if (accumulator > 32767)
                        acc_out_reg <= 16'sh7FFF;
                    else if (accumulator < -32768)
                        acc_out_reg <= -16'sh8000;
                    else
                        acc_out_reg <= accumulator[15:0];
                    neuron_idx_out_reg <= neuron_idx;
                    write_output_reg <= pipeline_valid; // Only write if pipeline is valid
                    pipeline_valid <= 1'b1; // Set valid after first MAC
                    if (neuron_idx < TOTAL_NEURONS - 1) begin
                        // Move to next neuron
                        neuron_idx <= neuron_idx + 10'd1;
                        input_idx <= 9'd0;
                        current_bias <= biases[neuron_idx + 10'd1];
                        accumulator <= { {32{biases[neuron_idx + 10'd1][15]}}, biases[neuron_idx + 10'd1] };
                    end else begin
                        // All neurons complete
                        busy <= 1'b0;
                        done <= 1'b1;
                    end
                end
            end else if (done) begin
                done <= 1'b0;  // Clear done after 1 cycle
            end
            // Output pipeline: write to flat_output
            if (write_output_reg) begin
                flat_output[(TOTAL_NEURONS - 1 - neuron_idx_out_reg) * 16 +: 16] <= acc_out_reg;
                if (neuron_idx_out_reg == 0) begin
                    $display("DEBUG: neuron0 out=%0d", acc_out_reg);
                end
                write_output_reg <= 1'b0;
            end
            // Write output.mem after all outputs are ready and pipeline is valid
            if (done && !output_written && pipeline_valid) begin
                memfile = $fopen("D:/WILLGAN/hardware/layers/output.mem", "w");
                if (memfile == 0) begin
                    $display("ERROR: Could not open output.mem for writing!");
                end else begin
                    for (integer j = 0; j < TOTAL_NEURONS; j = j + 1) begin
                        $fdisplay(memfile, "%h", flat_output[(TOTAL_NEURONS-1-j)*16 +: 16]);
                    end
                    $fclose(memfile);
                    $display("Layer3 output written to output.mem");
                end
                output_written <= 1'b1;
            end
        end
    end

endmodule

`endif // LAYER3_GENERATOR_V2_V
