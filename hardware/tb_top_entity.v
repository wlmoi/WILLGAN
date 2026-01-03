`timescale 1ns / 1ps

`include "top_entity.v"

module tb_top_entity;
    reg clk = 0;
    reg rst_n = 0;
    reg start = 0;
    reg [15:0] data_in = 0;
    wire [15:0] data_out;
    wire valid;
    wire busy;
    wire [2:0] state;
    wire [6:0] input_count;
    wire [9:0] output_count;

    // Clock: 100MHz (10ns period)
    always #5 clk = ~clk;

    // Instantiate top entity
    top_entity dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .data_in(data_in),
        .data_out(data_out),
        .valid(valid),
        .busy(busy),
        .state(state),
        .input_count(input_count),
        .output_count(output_count)
    );

    // Test data
    reg signed [15:0] noise_samples [0:63];
    reg signed [15:0] output_pixels [0:783];
    integer i, j;
    integer cycle_count;
    integer input_cycles, gen_cycles, output_cycles;
    integer min_val, max_val, sum, val;

    initial begin
        $dumpfile("tb_top_entity.vcd");
        $dumpvars(0, tb_top_entity);

        $display("=========================================");
        $display("   Top Entity Testbench                ");
        $display("=========================================");
        $display("Testing serial interface to generator");
        $display("");

        // Generate random noise
        $display("Generating 64 random noise samples...");
        for (i = 0; i < 64; i = i + 1) begin
            noise_samples[i] = $random % 1024; // Q5.10: -1 to +1
        end
        
        // Reset sequence
        rst_n = 0;
        #100;
        rst_n = 1;
        #50;

        $display("Starting generation at t=%0t", $time);
        $display("");

        // Send start pulse
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;

        // Monitor state transitions
        cycle_count = 0;
        
        // Wait for INPUT_LOAD state (state=1)
        while (state != 3'd1) @(negedge clk);
        $display("[t=%0t] State 1: INPUT_LOAD started", $time);
        input_cycles = 0;
        
        // Feed input data serially
        for (i = 0; i < 64; i = i + 1) begin
            @(negedge clk);
            data_in = noise_samples[i];
            input_cycles = input_cycles + 1;
            if (i < 8 || i >= 60) begin
                $display("  Sending noise[%0d] = %h (%.3f)", i, noise_samples[i], 
                         $signed(noise_samples[i]) / 1024.0);
            end else if (i == 8) begin
                $display("  ... (samples 8-59) ...");
            end
        end
        $display("[t=%0t] Input loading complete (%0d cycles)", $time, input_cycles);
        $display("");

        // Wait for GENERATE state (state=2)
        while (state != 3'd2) @(negedge clk);
        $display("[t=%0t] State 2: GENERATE started", $time);
        gen_cycles = 0;
        
        // Wait for generation to complete
        while (state == 3'd2) begin
            @(negedge clk);
            gen_cycles = gen_cycles + 1;
            if (gen_cycles % 10000 == 0) begin
                $display("  ... %0d cycles elapsed", gen_cycles);
            end
        end
        $display("[t=%0t] Generation complete (%0d cycles)", $time, gen_cycles);
        $display("");

        // Wait for OUTPUT_READ state (state=3)
        while (state != 3'd3) @(negedge clk);
        $display("[t=%0t] State 3: OUTPUT_READ started", $time);
        output_cycles = 0;
        
        // Collect output data
        for (i = 0; i < 784; i = i + 1) begin
            @(negedge clk);
            if (valid) begin
                output_pixels[i] = data_out;
                output_cycles = output_cycles + 1;
                if (i < 8 || i >= 776) begin
                    $display("  Received pixel[%0d] = %h (%.4f)", i, data_out, 
                             $signed(data_out) / 1024.0);
                end else if (i == 8) begin
                    $display("  ... (pixels 8-775) ...");
                end
            end
        end
        $display("[t=%0t] Output reading complete (%0d cycles)", $time, output_cycles);
        $display("");

        // Wait for DONE/IDLE
        while (busy) @(negedge clk);
        
        $display("=========================================");
        $display("   Test Complete                       ");
        $display("=========================================");
        $display("Timing Summary:");
        $display("  Input cycles:      %0d", input_cycles);
        $display("  Generation cycles: %0d", gen_cycles);
        $display("  Output cycles:     %0d", output_cycles);
        $display("  Total cycles:      %0d", input_cycles + gen_cycles + output_cycles);
        $display("");
        
        // Statistics
        min_val = 32767;
        max_val = -32768;
        sum = 0;
        
        for (i = 0; i < 784; i = i + 1) begin
            val = $signed(output_pixels[i]);
            if (val < min_val) min_val = val;
            if (val > max_val) max_val = val;
            sum = sum + val;
        end
        
        $display("Output Statistics:");
        $display("  Min:  %0d (%.4f)", min_val, min_val / 1024.0);
        $display("  Max:  %0d (%.4f)", max_val, max_val / 1024.0);
        $display("  Mean: %0d (%.4f)", sum/784, (sum/784) / 1024.0);
        
        $display("");
        $display("First row of 28x28 output:");
        $write("  ");
        for (i = 0; i < 28; i = i + 1) begin
            $write("%5d ", $signed(output_pixels[i]));
        end
        $write("\n");
        
        $display("");
        $display("=========================================");
        $finish;
    end

    // Timeout
    initial begin
        #200000000; // 200ms
        $display("ERROR: Timeout!");
        $finish;
    end

endmodule
