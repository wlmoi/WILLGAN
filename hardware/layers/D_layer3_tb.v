`timescale 1ns / 1ps

module D_layer3_tb;
        integer clk_count;
    // Inputs: 256 elements (from previous layer)
    reg signed [15:0] inputs [0:255];
    reg signed [16*256-1:0] flat_input;
    reg clk;
    reg rst;
    reg start;

    // Outputs: 1 element (score)
    wire signed [15:0] output_score;
    wire done;

    // Instantiate Unit Under Test (UUT)
    layer3_discriminator_v2 uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .flat_input(flat_input),
        .output_score(output_score),
        .done(done)
    );

    integer i_pack;
    always @(*) begin
        for (i_pack = 0; i_pack < 256; i_pack = i_pack + 1) begin
            flat_input[(i_pack+1)*16-1 -: 16] = inputs[i_pack];
        end
    end

    // Helper to convert Q6.10 to real
    function real q6_10_to_real;
        input signed [15:0] val;
        begin
            q6_10_to_real = val / 1024.0;
        end
    endfunction

    integer k;

    // Clock generator: 10ns period (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $display("--------------------------------------------------");
        $display("   TESTING DISCRIMINATOR LAYER 3");
        $display("   256 inputs -> 1 neuron (score)");
        $display("--------------------------------------------------");

        // Reset
        rst = 1;
        start = 0;
        clk_count = 0;
        #20;
        rst = 0;

        // Initialize inputs to zero
        for (k = 0; k < 256; k = k + 1) begin
            inputs[k] = 16'sd0;
        end

        // Test Case 1: Zero inputs (output should be bias only)
        $display("\nTest Case 1: Zero Inputs");
        for (k = 0; k < 256; k = k + 1) begin
            inputs[k] = 16'sd0;
        end

        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // Count clock cycles until done
        clk_count = 0;
        while (!done) begin
            @(posedge clk);
            clk_count = clk_count + 1;
        end
        #1;

        $display("Layer 3 Output (zero input): %f (hex: %h)", q6_10_to_real($signed(output_score)), output_score);
        $display("Clock cycles: %0d", clk_count);

        // Test Case 2: Small random inputs
        $display("\nTest Case 2: Random Inputs");
        for (k = 0; k < 256; k = k + 1) begin
            inputs[k] = $random % 256;
        end

        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // Count clock cycles until done
        clk_count = 0;
        while (!done) begin
            @(posedge clk);
            clk_count = clk_count + 1;
        end
        #1;

        $display("Layer 3 Output (random input): %f (hex: %h)", q6_10_to_real($signed(output_score)), output_score);
        $display("Clock cycles: %0d", clk_count);

        $display("--------------------------------------------------");
        $display("Layer 3 Test Complete");
        $display("--------------------------------------------------");

        $finish;
    end

endmodule
