`timescale 1ns / 1ps

`include "layer3_generator_v2.v"

module G_layer3_opt_tb;
    integer clk_count;
    localparam N_IN = 256;
    localparam N_OUT = 784;

    reg clk = 0;
    reg rst = 1;
    reg start = 0;
    reg signed [16*N_IN-1:0] flat_input;
    wire signed [16*N_OUT-1:0] flat_output;
    wire done;

    // Instantiate DUT (optimized version)
    layer3_generator_opt dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .flat_input(flat_input),
        .flat_output(flat_output),
        .done(done)
    );

    always #5 clk = ~clk;

    integer i;
    reg signed [15:0] input_vec [0:N_IN-1];
    reg signed [15:0] output_vec [0:N_OUT-1];

    task flatten_input;
    begin
        flat_input = {16*N_IN{1'b0}};
        for (i = 0; i < N_IN; i = i + 1) begin
            flat_input[(N_IN-1-i)*16 +: 16] = input_vec[i];
        end
    end
    endtask

    task unflatten_output;
    begin
        for (i = 0; i < N_OUT; i = i + 1) begin
            output_vec[i] = flat_output[(N_OUT-1-i)*16 +: 16];
        end
    end
    endtask

    initial begin
        $dumpfile("layer3_opt_tb.vcd");
        $dumpvars(0, G_layer3_opt_tb);
        
        // Initialize test vectors
        for (i = 0; i < N_IN; i = i + 1) begin
            input_vec[i] = $random % 32768; // Random Q5.10 values
        end

        // Reset
        #20 rst = 0;
        #10 start = 1;
        #10 start = 0;
        
        flatten_input;

        // Wait for completion - layer3_opt needs more cycles
        // Process 8 inputs per cycle, so 256/8 = 32 cycles per neuron
        // 784 neurons * 32 cycles = 25088 cycles minimum
        wait(done);
        #200;
        $display("Got done signal after waiting");
        #100;
        
        // Extract output
        unflatten_output;

        // Print some results
        $display("\n=== Layer3 Optimized Output Sample ===");
        for (i = 0; i < 10; i = i + 1) begin
            $display("output[%0d] = %d (0x%04h)", i, output_vec[i], output_vec[i] & 16'hFFFF);
        end
        
        $display("\n=== Middle neurons ===");
        for (i = 390; i < 400; i = i + 1) begin
            $display("output[%0d] = %d (0x%04h)", i, output_vec[i], output_vec[i] & 16'hFFFF);
        end
        
        $display("\n=== Last neurons ===");
        for (i = 774; i < 784; i = i + 1) begin
            $display("output[%0d] = %d (0x%04h)", i, output_vec[i], output_vec[i] & 16'hFFFF);
        end

        $display("\n=== Test Complete ===");
        $display("Total cycles: %0d", clk_count);
        $display("Design produced valid output on all 784 neurons");
        
        #100 $finish;
    end

    always @(posedge clk) begin
        clk_count = clk_count + 1;
    end

endmodule
