`timescale 1ns / 1ps

`ifndef LAYER3_GENERATOR_V2_V
`define LAYER3_GENERATOR_V2_V

// Layer 3 Generator (v2 - Shared Hardware with 8 Parallel MACs)
// Input: 256 neurons (Q5.10 from ReLU stage)
// Output: 784 neurons (Q5.10 pre-activation, 28×28 image)
// Weight matrix: 784×256
// Architecture: 8 parallel MAC units, processes 8 inputs per cycle
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
    localparam MAC_UNITS = 8;  // Number of parallel MAC units
    
    initial begin
        $readmemh("d:/WILLGAN/hardware/layers/mem/epoch300_G_l3_W.mem", weights);
        $readmemh("d:/WILLGAN/hardware/layers/mem/epoch300_G_l3_B.mem", biases);
    end

    // State machine
    localparam STATE_IDLE = 2'd0;
    localparam STATE_COMPUTE = 2'd1;
    localparam STATE_WRITE = 2'd2;
    
    reg [1:0] state;
    reg [9:0] neuron_idx;      // Current neuron: 0..783
    reg [8:0] input_idx;       // Current input offset: 0, 8, 16, ..., 248
    reg signed [47:0] accumulator;  // Q15.32 accumulator
    
    // MAC units: 8 parallel multipliers
    reg signed [15:0] w0, w1, w2, w3, w4, w5, w6, w7;
    wire signed [15:0] in0, in1, in2, in3, in4, in5, in6, in7;
    wire signed [31:0] prod0, prod1, prod2, prod3, prod4, prod5, prod6, prod7;
    
    // Extract 8 inputs from flat_input (MSB first indexing)
    assign in0 = flat_input[(TOTAL_INPUTS - 1 - (input_idx + 0)) * 16 +: 16];
    assign in1 = flat_input[(TOTAL_INPUTS - 1 - (input_idx + 1)) * 16 +: 16];
    assign in2 = flat_input[(TOTAL_INPUTS - 1 - (input_idx + 2)) * 16 +: 16];
    assign in3 = flat_input[(TOTAL_INPUTS - 1 - (input_idx + 3)) * 16 +: 16];
    assign in4 = flat_input[(TOTAL_INPUTS - 1 - (input_idx + 4)) * 16 +: 16];
    assign in5 = flat_input[(TOTAL_INPUTS - 1 - (input_idx + 5)) * 16 +: 16];
    assign in6 = flat_input[(TOTAL_INPUTS - 1 - (input_idx + 6)) * 16 +: 16];
    assign in7 = flat_input[(TOTAL_INPUTS - 1 - (input_idx + 7)) * 16 +: 16];
    
    // 8 parallel multipliers
    assign prod0 = in0 * w0;
    assign prod1 = in1 * w1;
    assign prod2 = in2 * w2;
    assign prod3 = in3 * w3;
    assign prod4 = in4 * w4;
    assign prod5 = in5 * w5;
    assign prod6 = in6 * w6;
    assign prod7 = in7 * w7;
    
    // Sum of 8 products (Q10.20 >> 10 = Q10.10, then extended to Q15.32)
    wire signed [47:0] mac_sum;
    assign mac_sum = $signed({{16{prod0[31]}}, prod0[31:10]}) +
                     $signed({{16{prod1[31]}}, prod1[31:10]}) +
                     $signed({{16{prod2[31]}}, prod2[31:10]}) +
                     $signed({{16{prod3[31]}}, prod3[31:10]}) +
                     $signed({{16{prod4[31]}}, prod4[31:10]}) +
                     $signed({{16{prod5[31]}}, prod5[31:10]}) +
                     $signed({{16{prod6[31]}}, prod6[31:10]}) +
                     $signed({{16{prod7[31]}}, prod7[31:10]});

    always @(posedge clk) begin
        if (rst) begin
            state <= STATE_IDLE;
            neuron_idx <= 10'd0;
            input_idx <= 9'd0;
            accumulator <= 48'sd0;
            done <= 1'b0;
            flat_output <= {(16*TOTAL_NEURONS){1'b0}};
            w0 <= 16'sd0; w1 <= 16'sd0; w2 <= 16'sd0; w3 <= 16'sd0;
            w4 <= 16'sd0; w5 <= 16'sd0; w6 <= 16'sd0; w7 <= 16'sd0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        state <= STATE_COMPUTE;
                        neuron_idx <= 10'd0;
                        input_idx <= 9'd0;
                        // Initialize accumulator with first bias (Q5.10 extended to Q15.32)
                        accumulator <= $signed({{32{biases[0][15]}}, biases[0]});
                        // Load first 8 weights
                        w0 <= weights[0 * TOTAL_INPUTS + 0];
                        w1 <= weights[0 * TOTAL_INPUTS + 1];
                        w2 <= weights[0 * TOTAL_INPUTS + 2];
                        w3 <= weights[0 * TOTAL_INPUTS + 3];
                        w4 <= weights[0 * TOTAL_INPUTS + 4];
                        w5 <= weights[0 * TOTAL_INPUTS + 5];
                        w6 <= weights[0 * TOTAL_INPUTS + 6];
                        w7 <= weights[0 * TOTAL_INPUTS + 7];
                    end
                end
                
                STATE_COMPUTE: begin
                    if (input_idx < TOTAL_INPUTS) begin
                        // Accumulate 8 MACs
                        accumulator <= accumulator + mac_sum;
                        
                        // Move to next 8 inputs
                        input_idx <= input_idx + 9'd8;
                        
                        // Prefetch next 8 weights
                        if (input_idx + 8 < TOTAL_INPUTS) begin
                            w0 <= weights[neuron_idx * TOTAL_INPUTS + input_idx + 9'd8];
                            w1 <= weights[neuron_idx * TOTAL_INPUTS + input_idx + 9'd9];
                            w2 <= weights[neuron_idx * TOTAL_INPUTS + input_idx + 9'd10];
                            w3 <= weights[neuron_idx * TOTAL_INPUTS + input_idx + 9'd11];
                            w4 <= weights[neuron_idx * TOTAL_INPUTS + input_idx + 9'd12];
                            w5 <= weights[neuron_idx * TOTAL_INPUTS + input_idx + 9'd13];
                            w6 <= weights[neuron_idx * TOTAL_INPUTS + input_idx + 9'd14];
                            w7 <= weights[neuron_idx * TOTAL_INPUTS + input_idx + 9'd15];
                        end
                    end else begin
                        // Finished all inputs for this neuron
                        state <= STATE_WRITE;
                    end
                end
                
                STATE_WRITE: begin
                    // Write accumulated result to output (with saturation)
                    if (accumulator > 48'sd32767)
                        flat_output[(TOTAL_NEURONS - 1 - neuron_idx) * 16 +: 16] <= 16'sh7FFF;
                    else if (accumulator < -48'sd32768)
                        flat_output[(TOTAL_NEURONS - 1 - neuron_idx) * 16 +: 16] <= 16'sh8000;
                    else
                        flat_output[(TOTAL_NEURONS - 1 - neuron_idx) * 16 +: 16] <= accumulator[15:0];
                    
                    if (neuron_idx < TOTAL_NEURONS - 1) begin
                        // Move to next neuron
                        neuron_idx <= neuron_idx + 10'd1;
                        input_idx <= 9'd0;
                        // Initialize accumulator with next bias
                        accumulator <= $signed({{32{biases[neuron_idx + 10'd1][15]}}, biases[neuron_idx + 10'd1]});
                        // Load first 8 weights for next neuron
                        w0 <= weights[(neuron_idx + 10'd1) * TOTAL_INPUTS + 0];
                        w1 <= weights[(neuron_idx + 10'd1) * TOTAL_INPUTS + 1];
                        w2 <= weights[(neuron_idx + 10'd1) * TOTAL_INPUTS + 2];
                        w3 <= weights[(neuron_idx + 10'd1) * TOTAL_INPUTS + 3];
                        w4 <= weights[(neuron_idx + 10'd1) * TOTAL_INPUTS + 4];
                        w5 <= weights[(neuron_idx + 10'd1) * TOTAL_INPUTS + 5];
                        w6 <= weights[(neuron_idx + 10'd1) * TOTAL_INPUTS + 6];
                        w7 <= weights[(neuron_idx + 10'd1) * TOTAL_INPUTS + 7];
                        state <= STATE_COMPUTE;
                    end else begin
                        // All neurons complete
                        state <= STATE_IDLE;
                        done <= 1'b1;
                    end
                end
                
                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule

`endif // LAYER3_GENERATOR_V2_V
