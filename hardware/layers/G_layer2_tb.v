`timescale 1ns / 1ps

module G_layer2_tb;
    // Parameters
    localparam TOTAL_INPUTS = 256;
    localparam TOTAL_NEURONS = 256;

    // DUT signals
    reg clk;
    reg rst;
    reg start;
    reg signed [16*TOTAL_INPUTS-1:0] flat_input;
    wire signed [16*TOTAL_NEURONS-1:0] flat_output;
    wire done;

    // Instantiate Layer 2 Generator
    layer2_generator_v2 dut (
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
        // Reference values for Layer 2 output after ReLU (Q6.10)
        reg signed [15:0] ref_layer2 [0:9];
    // Reference values from CSV for comparison
    reg signed [15:0] ref_csv [0:9];

    // Helper to flatten input vector
    task flatten_input;
        begin
            flat_input = 0;
            for (i = 0; i < TOTAL_INPUTS; i = i + 1) begin
                flat_input[(TOTAL_INPUTS-1-i)*16 +: 16] = input_vec[i];
            end
        end
    endtask

    // Helper to unflatten output vector (fix order to match MATLAB/CSV)
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
        // Load input vector for Layer 2 from mem/epoch300_G_l1_W.mem (output of Layer 1 generator)
        $readmemh("mem/layer1_relu_output.mem", input_vec);
        $readmemh("D:/WILLGAN/hardware/layers/mem/layer1_relu_output.mem", input_vec);

        // Set reference values for Layer 2 output after ReLU (dari CSV referensi)
        ref_layer2[0] = 131;
        ref_layer2[1] = 177;
        ref_layer2[2] = 162;
        ref_layer2[3] = 180;
        ref_layer2[4] = 149;
        ref_layer2[5] = 118;
        ref_layer2[6] = 156;
        ref_layer2[7] = 167;
        ref_layer2[8] = 246;
        ref_layer2[9] = 192;

        // Set reference values from CSV
        ref_csv[0] = 131;
        ref_csv[1] = 177;
        ref_csv[2] = 162;
        ref_csv[3] = 180;
        ref_csv[4] = 149;
        ref_csv[5] = 118;
        ref_csv[6] = 156;
        ref_csv[7] = 167;
        ref_csv[8] = 246;
        ref_csv[9] = 192;

        $display("Input vector to DUT (from CSV):");
        for (i = 0; i < 10; i = i + 1) $display("input_vec[%0d] = %0d", i, input_vec[i]);

        // Initialize
        rst = 1;
        start = 0;
        flat_input = 0;
        #20;
        rst = 0;
        #20;

        flatten_input();
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;
        wait(done);
        @(negedge clk); // Tambah delay 1 siklus agar output valid
        unflatten_output();
        relu_layer();

        $display("Layer 2 output (pre-activation):");
        for (i = 0; i < 10; i = i + 1) $display("%0d: %0d", i, output_vec[i]);
        $display("...");
        // Dump all outputs for Python comparison
        $write("hw_out = np.array([");
        for (i = 0; i < TOTAL_NEURONS; i = i + 1) begin
            $write("%0d", output_vec[i]);
            if (i != TOTAL_NEURONS-1) $write(", ");
        end
        $write("], dtype=np.int16)\n");
        $display("Layer 2 output (after ReLU):");
        for (i = 0; i < 10; i = i + 1) $display("%0d: %0d", i, relu_vec[i]);
        $display("...");
        $display("Layer 2 test completed.");

        // Compare relu_vec[0:9] to ref_layer2[0:9]
        $display("\nComparison to Layer 2 ReLU reference:");
        for (i = 0; i < 10; i = i + 1) begin
            if (relu_vec[i] === ref_layer2[i])
                $display("Index %0d: DUT=%0d, REF=%0d [PASS]", i, relu_vec[i], ref_layer2[i]);
            else
                $display("Index %0d: DUT=%0d, REF=%0d [FAIL]", i, relu_vec[i], ref_layer2[i]);
        end

        // Compare output_vec[0:9] to ref_csv[0:9]
        $display("\nComparison to CSV reference:");
        for (i = 0; i < 10; i = i + 1) begin
            if (output_vec[i] === ref_csv[i])
                $display("Index %0d: DUT=%0d, CSV=%0d [PASS]", i, output_vec[i], ref_csv[i]);
            else
                $display("Index %0d: DUT=%0d, CSV=%0d [FAIL]", i, output_vec[i], ref_csv[i]);
        end
        $finish;
    end
endmodule
