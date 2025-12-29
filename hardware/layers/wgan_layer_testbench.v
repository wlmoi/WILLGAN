`timescale 1ns / 1ps

module wgan_layer_testbench;
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
        wait(done);
        unflatten_output();
        relu_layer();

        $display("Layer 1 output (pre-activation):");
        for (i = 0; i < 10; i = i + 1) $display("%0d: %0d", i, output_vec[i]);
        $display("...");
        $display("Layer 1 output (after ReLU):");
        for (i = 0; i < 10; i = i + 1) $display("%0d: %0d", i, relu_vec[i]);
        $display("...");
        $display("Layer 1 test completed.");
        $finish;
    end
endmodule
