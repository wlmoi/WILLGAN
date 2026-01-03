`timescale 1ns / 1ps

`include "generator.v"

module generator_tb;
    localparam N_NOISE = 64;
    localparam N_OUTPUT = 784;

    reg clk = 0;
    reg rst = 1;
    reg start = 0;
    reg signed [16*N_NOISE-1:0] noise_input;
    wire signed [16*N_OUTPUT-1:0] image_output;
    wire done;
    
    integer i;
    integer clk_count;
    integer memfile;
    integer min_val, max_val, sum, val;
    reg signed [15:0] noise_vec [0:N_NOISE-1];
    reg signed [15:0] output_vec [0:N_OUTPUT-1];

    // Instantiate generator
    generator dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .noise_input(noise_input),
        .image_output(image_output),
        .done(done)
    );

    // Clock generation: 10ns period (100MHz)
    always #5 clk = ~clk;

    // Task to pack noise into flat input
    task flatten_noise;
    begin
        noise_input = {16*N_NOISE{1'b0}};
        for (i = 0; i < N_NOISE; i = i + 1) begin
            noise_input[(N_NOISE-1-i)*16 +: 16] = noise_vec[i];
        end
    end
    endtask

    // Task to unpack output
    task unflatten_output;
    begin
        for (i = 0; i < N_OUTPUT; i = i + 1) begin
            output_vec[i] = image_output[(N_OUTPUT-1-i)*16 +: 16];
        end
    end
    endtask

    initial begin
        $dumpfile("generator_tb.vcd");
        $dumpvars(0, generator_tb);
        
        $display("========================================");
        $display("   WGAN Generator Full Pipeline Test   ");
        $display("========================================");
        $display("Architecture:");
        $display("  Layer1: 64 → 256 (sequential MAC)");
        $display("  ReLU1:  256 activations");
        $display("  Layer2: 256 → 256 (sequential MAC)");
        $display("  ReLU2:  256 activations");
        $display("  Layer3: 256 → 784 (8 parallel MACs)");
        $display("========================================");
        $display("");
        
        // Load noise input (using layer1 input as test vector)
        // If file doesn't exist, generate random noise
        if ($fopen("d:/WILLGAN/hardware/layers/mem/layer1_input.mem", "r") == 0) begin
            $display("Generating random noise vector (64 values)...");
            for (i = 0; i < N_NOISE; i = i + 1) begin
                // Generate random Q5.10 values between -1.0 and 1.0
                noise_vec[i] = $random % 1024; // Random value -1023 to 1023
            end
        end else begin
            $readmemh("d:/WILLGAN/hardware/layers/mem/layer1_input.mem", noise_vec);
        end
        
        $display("Loaded test noise vector (first 8 values):");
        for (i = 0; i < 8; i = i + 1) begin
            $display("  noise[%0d] = %h (%.3f)", i, noise_vec[i], $signed(noise_vec[i]) / 1024.0);
        end
        $display("");
        
        // Reset sequence
        rst = 1; start = 0; noise_input = 0;
        #50;
        rst = 0;
        #20;
        
        // Prepare input
        flatten_noise();
        
        // Start generation
        $display("Starting image generation at t=%0t", $time);
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;
        
        // Wait for completion
        clk_count = 0;
        while (!done) begin
            @(negedge clk);
            clk_count = clk_count + 1;
            
            // Progress indicator every 10000 cycles
            if (clk_count % 10000 == 0) begin
                $display("  ... %0d cycles elapsed", clk_count);
            end
        end
        
        $display("");
        $display("========================================");
        $display("   Generation Complete!                ");
        $display("========================================");
        $display("Total clock cycles: %0d", clk_count);
        $display("Time: %.2f ms (at 100MHz)", clk_count * 0.00001);
        $display("");
        
        // Extract outputs
        @(negedge clk);
        unflatten_output();
        
        // Display statistics
        min_val = 32767;
        max_val = -32768;
        sum = 0;
        
        $display("Output Statistics:");
        $display("  First pixel:  %0d (%.4f)", $signed(output_vec[0]), $signed(output_vec[0]) / 1024.0);
        $display("  Last pixel:   %0d (%.4f)", $signed(output_vec[N_OUTPUT-1]), $signed(output_vec[N_OUTPUT-1]) / 1024.0);
        
        // Find min/max
        for (i = 0; i < N_OUTPUT; i = i + 1) begin
            val = $signed(output_vec[i]);
            if (val < min_val) min_val = val;
            if (val > max_val) max_val = val;
            sum = sum + val;
        end
        $display("  Min value:    %0d (%.4f)", min_val, min_val / 1024.0);
        $display("  Max value:    %0d (%.4f)", max_val, max_val / 1024.0);
        $display("  Mean value:   %0d (%.4f)", sum/N_OUTPUT, (sum/N_OUTPUT) / 1024.0);
        $display("");
        
        // Display first 28 pixels (first row of 28x28 image)
        $display("First row of generated 28×28 image:");
        $write("  ");
        for (i = 0; i < 28; i = i + 1) begin
            $write("%4d ", $signed(output_vec[i]));
        end
        $write("\n\n");
        
        // Save output to file
        memfile = $fopen("d:/WILLGAN/hardware/layers/generator_output.mem", "w");
        if (memfile == 0) begin
            $display("ERROR: Could not open generator_output.mem for writing!");
        end else begin
            for (i = 0; i < N_OUTPUT; i = i + 1) begin
                $fdisplay(memfile, "%h", output_vec[i]);
            end
            $fclose(memfile);
            $display("Output saved to: generator_output.mem");
        end
        
        // Generate Python array for comparison
        $display("");
        $display("Python numpy array (first 56 values shown):");
        $write("generated_image = np.array([");
        for (i = 0; i < 56; i = i + 1) begin
            $write("%0d", $signed(output_vec[i]));
            if (i != 55) $write(", ");
            if ((i+1) % 14 == 0 && i != 55) $write("\n    ");
        end
        $write(", ...], dtype=np.int16).reshape(28, 28)\n");
        
        $display("");
        $display("========================================");
        $display("   Test Complete                       ");
        $display("========================================");
        $finish;
    end
    
    // Timeout watchdog (100ms)
    initial begin
        #100000000;
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule
