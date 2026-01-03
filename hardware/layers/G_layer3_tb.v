`timescale 1ns / 1ps

`include "layer3_generator_v2.v"

module G_layer3_tb;
    localparam N_IN = 256;
    localparam N_OUT = 784;

    reg clk = 0;
    reg rst = 1;
    reg start = 0;
    reg signed [16*N_IN-1:0] flat_input;
    wire signed [16*N_OUT-1:0] flat_output;
    wire done;
    
    integer clk_count;
    integer i;
    reg signed [15:0] input_vec [0:N_IN-1];
    reg signed [15:0] output_vec [0:N_OUT-1];

    // Instantiate DUT
    layer3_generator_v2 dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .flat_input(flat_input),
        .flat_output(flat_output),
        .done(done)
    );

    // Clock generation: 10ns period (100MHz)
    always #5 clk = ~clk;

    // Task to pack inputs into flat_input
    task flatten_input;
    begin
        flat_input = {16*N_IN{1'b0}};
        for (i = 0; i < N_IN; i = i + 1) begin
            flat_input[(N_IN-1-i)*16 +: 16] = input_vec[i];
        end
    end
    endtask

    // Task to unpack flat_output into output_vec
    task unflatten_output;
    begin
        for (i = 0; i < N_OUT; i = i + 1) begin
            output_vec[i] = flat_output[(N_OUT-1-i)*16 +: 16];
        end
    end
    endtask

    initial begin
        $dumpfile("G_layer3_tb.vcd");
        $dumpvars(0, G_layer3_tb);
        
        // Load test input from layer2 ReLU output
        $readmemh("d:/WILLGAN/hardware/layers/mem/layer2_relu_output.mem", input_vec);
        
        $display("=== Layer 3 Generator Testbench ===");
        $display("Architecture: 8 parallel MAC units");
        $display("Input: 256 neurons (Q5.10)");
        $display("Output: 784 neurons (Q5.10)");
        $display("");
        
        // Reset sequence
        rst = 1; start = 0; flat_input = 0;
        #20;
        rst = 0;
        #20;
        
        // Prepare input
        flatten_input();
        $display("Input prepared. First 4 values: %h %h %h %h", 
                 input_vec[0], input_vec[1], input_vec[2], input_vec[3]);
        
        // Start computation
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;
        
        $display("Computation started at t=%0t", $time);
        
        // Wait for done signal
        clk_count = 0;
        while (!done) begin
            @(negedge clk);
            clk_count = clk_count + 1;
        end
        
        $display("Computation complete at t=%0t", $time);
        $display("Total clock cycles: %0d", clk_count);
        $display("Throughput: %.2f cycles/neuron", clk_count / 784.0);
        $display("");
        
        // Extract outputs
        @(negedge clk);
        unflatten_output();
        
        // Display first 10 outputs and compare with reference
        $display("First 10 outputs (Q5.10 format):");
        $display("Index | HW Output | Expected | Float Value");
        $display("------|-----------|----------|------------");
        $display("  0   |   %6d  |   -456   |  %f", $signed(output_vec[0]), $signed(output_vec[0]) / 1024.0);
        $display("  1   |   %6d  |   -472   |  %f", $signed(output_vec[1]), $signed(output_vec[1]) / 1024.0);
        $display("  2   |   %6d  |   -527   |  %f", $signed(output_vec[2]), $signed(output_vec[2]) / 1024.0);
        $display("  3   |   %6d  |   -448   |  %f", $signed(output_vec[3]), $signed(output_vec[3]) / 1024.0);
        $display("  4   |   %6d  |   -400   |  %f", $signed(output_vec[4]), $signed(output_vec[4]) / 1024.0);
        $display("  5   |   %6d  |   -530   |  %f", $signed(output_vec[5]), $signed(output_vec[5]) / 1024.0);
        $display("  6   |   %6d  |   -422   |  %f", $signed(output_vec[6]), $signed(output_vec[6]) / 1024.0);
        $display("  7   |   %6d  |   -425   |  %f", $signed(output_vec[7]), $signed(output_vec[7]) / 1024.0);
        $display("  8   |   %6d  |   -481   |  %f", $signed(output_vec[8]), $signed(output_vec[8]) / 1024.0);
        $display("  9   |   %6d  |   -446   |  %f", $signed(output_vec[9]), $signed(output_vec[9]) / 1024.0);
        $display("");
        
        // Generate Python-compatible output array
        $display("Python array for comparison:");
        $write("hw_out3 = np.array([");
        for (i = 0; i < N_OUT; i = i + 1) begin
            $write("%0d", $signed(output_vec[i]));
            if (i != N_OUT-1) $write(", ");
        end
        $write("], dtype=np.int16)\n");
        
        $display("");
        $display("=== Test Complete ===");
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #10000000; // 10ms timeout
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule
