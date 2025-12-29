`timescale 1ns / 1ps

module layer3_generator_tb;

    // Inputs (Array 256 x 16-bit)
    reg signed [15:0] inputs [0:255];

    // Layer 3 outputs
    reg signed [15:0] layer3_linear_outputs [0:127];
    reg signed [15:0] layer3_relu_outputs [0:127];

    // Clock, reset, start, done signals
    reg clk;
    reg rst;
    reg start_layer3;
    wire done_layer3;

    // Flattened buses for sequential MAC generators
    reg signed [16*256-1:0] flat_input;
    wire signed [16*784-1:0] flat_output;

    // Pack input: always @(*) block to write inputs into flat_input_flat
    integer p;
    always @(*) begin
        for (p = 0; p < 256; p = p + 1) begin
            flat_input[(p+1)*16-1 -: 16] = inputs[p];
        end
    end

    // Unpack layer3 output and apply ReLU
    always @(*) begin
        for (p = 0; p < 128; p = p + 1) begin
            layer3_linear_outputs[p] = flat_output[(p+1)*16-1 -: 16];
            // Apply ReLU: max(0, x)
            layer3_relu_outputs[p] = (layer3_linear_outputs[p] > 0) ? layer3_linear_outputs[p] : 16'd0;
        end
    end

    // Instantiate Layer 3 Generator (v2)
    layer3_generator_v2 layer3_gen (
        .clk(clk),
        .rst(rst),
        .start(start_layer3),
        .flat_input(flat_input),
        .flat_output(flat_output),
        .done(done_layer3)
    );

    integer k;

    // Clock generator: 10 ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Fungsi Helper untuk menampilkan Fixed Point
    function real q8_8_to_real;
        input signed [15:0] val;
        begin
            q8_8_to_real = val / 1024.0;
        end
    endfunction

    initial begin
        // Initialize inputs with some variation
        for (k = 0; k < 256; k = k + 1) begin
            inputs[k] = $random % 1024; // Random values between 0 and 1023
        end

        // Reset
        rst = 1;
        start_layer3 = 0;
        #10;
        rst = 0;
        #10;

        // Start layer 3 computation
        start_layer3 = 1;
        #10;
        start_layer3 = 0;

        // Wait for done
        wait(done_layer3);

        // Display actual computed results
        for (k = 0; k < 20; k = k + 1) begin
            $display("[%2d] = %d (%f)", k, layer3_linear_outputs[k], q8_8_to_real(layer3_linear_outputs[k]));
        end
        $display("...");
        $finish;
    end

endmodule
