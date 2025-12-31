`timescale 1ns / 1ps

`include "layer1_generator_v2.v"

module G_layer1_tb;
        integer clk_count;
    // Parameters
    localparam TOTAL_INPUTS = 64;
    localparam TOTAL_NEURONS = 256;

    // DUT signals
    reg clk;
    reg rst;
    reg start;
    reg signed [16*TOTAL_INPUTS-1:0] flat_input;
    wire signed [16*TOTAL_NEURONS-1:0] flat_output;
    wire done;

    // Instantiate Layer 1 Generator
    layer1_generator_v2 dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .flat_input(flat_input),
        .flat_output(flat_output),
        .done(done)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    integer i;
    integer f;
    reg signed [15:0] input_vec [0:TOTAL_INPUTS-1];
    reg signed [15:0] output_vec [0:TOTAL_NEURONS-1];
    reg signed [15:0] relu_vec [0:TOTAL_NEURONS-1];

    // Helper to flatten input vector
    task flatten_input;
        begin
            flat_input = 0;
            for (i = 0; i < TOTAL_INPUTS; i = i + 1) begin
                flat_input[i*16 +: 16] = input_vec[i];
            end
        end
    endtask

    // Helper to unflatten output vector
    task unflatten_output;
        begin
            for (i = 0; i < TOTAL_NEURONS; i = i + 1) begin
                output_vec[i] = flat_output[(TOTAL_NEURONS-1-i)*16 +: 16];
            end
        end
    endtask

    // ReLU activation
    task relu_layer;
        begin
            for (i = 0; i < TOTAL_NEURONS; i = i + 1) begin
                relu_vec[i] = (output_vec[i][15] == 1'b1) ? 16'sd0 : output_vec[i];
            end
        end
    endtask

    initial begin
        // Initialize
        rst = 1;
        start = 0;
        flat_input = 0;
        clk_count = 0;
        #20;
        rst = 0;
        #20;

        // Test: All zeros
        for (i = 0; i < TOTAL_INPUTS; i = i + 1) input_vec[i] = 16'sd0;
        flatten_input();
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;
        clk_count = 0;
        while (!done) begin @(negedge clk); clk_count = clk_count + 1; end
        unflatten_output();
        relu_layer();

        $display("Layer 1 output (pre-activation):");
        for (i = 0; i < 10; i = i + 1) $display("%0d: %0d", i, output_vec[i]);
        $display("...");
        $display("Layer 1 output (after ReLU, all 256):");
        for (i = 0; i < TOTAL_NEURONS; i = i + 1) $display("%0d: %0d", i, relu_vec[i]);


        // Save ReLU output to .mem file for Layer 2 input
        f = $fopen("mem/layer1_relu_output.mem", "w");
        for (i = 0; i < TOTAL_NEURONS; i = i + 1) begin
            $fdisplay(f, "%04h", relu_vec[i][15:0]);
        end
        $fclose(f);
        $display("Layer 1 ReLU output saved to mem/layer1_relu_output.mem");

        $display("Clock cycles: %0d", clk_count);
        $display("Layer 1 test completed.");
        $finish;
    end
endmodule
