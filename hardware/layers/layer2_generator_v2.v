`timescale 1ns / 1ps

`ifndef LAYER2_GENERATOR_V2_V
`define LAYER2_GENERATOR_V2_V

// Layer 2 Generator (v2 - New Architecture)
// Input: 256 neurons (Q5.10 from ReLU stage)
// Output: 256 neurons (Q5.10 pre-activation)
// Weight matrix: 256×256
// No activation function (goes to external ReLU stage)
//
module layer2_generator_v2 (
    input wire clk,
    input wire rst,
    input wire start,
    // Flattened input: 256 elements × 16 bits = 4096 bits
    input wire signed [16*256-1:0] flat_input,
    // Flattened output: 256 elements × 16 bits = 4096 bits
    output reg signed [16*256-1:0] flat_output,
    output reg done
);

    // Temporary variables for output saturation
    reg signed [31:0] acc_final;
    reg signed [15:0] out_val;

    // Memory for weights and biases (Q5.10 format)
    (* rom_style = "block" *) reg signed [15:0] weights [0:65535]; // 256×256
    (* rom_style = "block" *) reg signed [15:0] biases [0:255];

    localparam TOTAL_NEURONS = 256;
    localparam TOTAL_INPUTS = 256;
    
    reg [15:0] epoch;
    initial begin
        $readmemh("mem/epoch300_G_l2_W.mem", weights);
        $readmemh("D:/WILLGAN/hardware/layers/mem/epoch300_G_l2_W.mem", weights);
        $readmemh("mem/epoch300_G_l2_B.mem", biases);
        $readmemh("D:/WILLGAN/hardware/layers/mem/epoch300_G_l2_B.mem", biases);
        epoch = 16'd0;
    end

    // Sequential MAC computation
    reg [8:0] neuron_idx;  // 0..255
    reg [8:0] input_idx;   // 0..255
    reg busy;
    reg write_output; // state untuk menulis output setelah akumulasi
    reg signed [47:0] accumulator;  // Q15.32 accumulator for higher precision
    
    reg signed [15:0] current_input;
    reg signed [15:0] current_weight;
    reg signed [15:0] current_bias;
    wire signed [31:0] product_q20;
    wire signed [15:0] product_q10;
    assign product_q20 = current_input * current_weight;
    assign product_q10 = product_q20 >>> 10; // Q12.20 -> Q6.10
    
    always @(posedge clk) begin
        if (rst) begin
            neuron_idx <= 9'd0;
            input_idx <= 9'd0;
            busy <= 1'b0;
            write_output <= 1'b0;
            done <= 1'b0;
            accumulator <= 48'sd0;
            flat_output <= {(16*256){1'b0}};
        end else begin
            if (start && !busy) begin
                // Start computation
                busy <= 1'b1;
                write_output <= 1'b0;
                done <= 1'b0;
                neuron_idx <= 9'd0;
                input_idx <= 9'd0;
                // Load first bias (Q6.10, extend to accumulator)
                current_bias <= biases[0];
                accumulator <= { {32{biases[0][15]}}, biases[0] };
            end else if (busy) begin
                if (!write_output) begin
                    if (input_idx < TOTAL_INPUTS) begin
                        // Load current input and weight
                        current_input <= flat_input[(TOTAL_INPUTS - 1 - input_idx) * 16 +: 16];
                        current_weight <= weights[neuron_idx * TOTAL_INPUTS + input_idx];

                        // Akumulasi product_q10 setiap siklus
                        accumulator <= accumulator + product_q10;
                        input_idx <= input_idx + 9'd1;
                    end else begin
                        // Selesai akumulasi, next cycle write output
                        write_output <= 1'b1;
                    end
                end else begin
                    // Write output for current neuron
                    acc_final = accumulator;
                    if (acc_final > 32'sh7FFF)
                        out_val = 16'sh7FFF;
                    else if (acc_final < -32'sh8000)
                        out_val = -16'sh8000;
                    else
                        out_val = acc_final[15:0];

                    flat_output[(TOTAL_NEURONS - 1 - neuron_idx) * 16 +: 16] = out_val;

                    if (neuron_idx < TOTAL_NEURONS - 1) begin
                        // Move to next neuron
                        neuron_idx <= neuron_idx + 9'd1;
                        input_idx <= 9'd0;
                        current_bias <= biases[neuron_idx + 9'd1];
                        accumulator <= { {32{biases[neuron_idx + 9'd1][15]}}, biases[neuron_idx + 9'd1] };
                        write_output <= 1'b0;
                    end else begin
                        // All neurons complete
                        busy <= 1'b0;
                        done <= 1'b1;
                        write_output <= 1'b0;
                    end
                end
            end else if (done) begin
                done <= 1'b0;  // Clear done after 1 cycle
            end
        end
    end

endmodule

`endif // LAYER2_GENERATOR_V2_V
