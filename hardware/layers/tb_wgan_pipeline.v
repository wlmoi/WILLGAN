`timescale 1ns / 1ps

module tb_wgan_pipeline;
    // Parameters
    localparam L1_IN = 64;
    localparam L2_IN = 256;
    localparam L3_IN = 256;
    localparam L3_OUT = 784;

    // Clock
    reg clk = 0;
    always #5 clk = ~clk; // 100MHz

    // Layer 1
    reg rst1 = 0, start1 = 0;
    reg signed [16*L1_IN-1:0] flat_input1;
    wire signed [16*L2_IN-1:0] flat_output1;
    wire done1;

    // Layer 2
    reg rst2 = 0, start2 = 0;
    reg signed [16*L2_IN-1:0] flat_input2;
    wire signed [16*L2_IN-1:0] flat_output2;
    wire done2;

    // Layer 3
    reg rst3 = 0, start3 = 0;
    reg signed [16*L3_IN-1:0] flat_input3;
    wire signed [16*L3_OUT-1:0] flat_output3;
    wire done3;

    // Instantiate Layer 1
    layer1_generator_v2 l1 (
        .clk(clk), .rst(rst1), .start(start1),
        .flat_input(flat_input1), .flat_output(flat_output1), .done(done1)
    );
    // Instantiate Layer 2
    layer2_generator_v2 l2 (
        .clk(clk), .rst(rst2), .start(start2),
        .flat_input(flat_input2), .flat_output(flat_output2), .done(done2)
    );
    // Instantiate Layer 3
    layer3_generator_v2 l3 (
        .clk(clk), .rst(rst3), .start(start3),
        .flat_input(flat_input3), .flat_output(flat_output3), .done(done3)
    );

    integer i;
    reg signed [15:0] input_vec1 [0:L1_IN-1];
    reg signed [15:0] output_vec1 [0:L2_IN-1];
    reg signed [15:0] relu_vec1 [0:L2_IN-1];
    reg signed [15:0] output_vec2 [0:L2_IN-1];
    reg signed [15:0] relu_vec2 [0:L2_IN-1];
    reg signed [15:0] output_vec3 [0:L3_OUT-1];

    // Helper: flatten input for Layer 1
    task flatten_input1;
        begin
            flat_input1 = 0;
            for (i = 0; i < L1_IN; i = i + 1)
                flat_input1[(L1_IN-1-i)*16 +: 16] = input_vec1[i];
        end
    endtask
    // Helper: unflatten output for Layer 1
    task unflatten_output1;
        begin
            for (i = 0; i < L2_IN; i = i + 1)
                output_vec1[i] = flat_output1[i*16 +: 16];
        end
    endtask
    // ReLU for Layer 1
    task relu_layer1;
        begin
            for (i = 0; i < L2_IN; i = i + 1)
                relu_vec1[i] = (output_vec1[i][15] == 1'b1) ? 16'sd0 : output_vec1[i];
        end
    endtask
    // Helper: flatten input for Layer 2
    task flatten_input2;
        begin
            flat_input2 = 0;
            for (i = 0; i < L2_IN; i = i + 1)
                flat_input2[(L2_IN-1-i)*16 +: 16] = relu_vec1[i];
        end
    endtask
    // Helper: unflatten output for Layer 2
    task unflatten_output2;
        begin
            for (i = 0; i < L2_IN; i = i + 1)
                output_vec2[i] = flat_output2[i*16 +: 16];
        end
    endtask
    // ReLU for Layer 2
    task relu_layer2;
        begin
            for (i = 0; i < L2_IN; i = i + 1)
                relu_vec2[i] = (output_vec2[i][15] == 1'b1) ? 16'sd0 : output_vec2[i];
        end
    endtask
    // Helper: flatten input for Layer 3
    task flatten_input3;
        begin
            flat_input3 = 0;
            for (i = 0; i < L3_IN; i = i + 1)
                flat_input3[(L3_IN-1-i)*16 +: 16] = relu_vec2[i];
        end
    endtask
    // Helper: unflatten output for Layer 3
    task unflatten_output3;
        begin
            for (i = 0; i < L3_OUT; i = i + 1)
                output_vec3[i] = flat_output3[i*16 +: 16];
        end
    endtask

    initial begin
        // 1. Init input noise (zero vector)
        for (i = 0; i < L1_IN; i = i + 1) input_vec1[i] = 0;
        flatten_input1();
        // 2. Layer 1
        rst1 = 1; #20; rst1 = 0; #20;
        start1 = 1; @(negedge clk); start1 = 0;
        wait(done1);
        unflatten_output1();
        relu_layer1();
        $display("Layer 1 output (first 5):");
        for (i = 0; i < 5; i = i + 1) $display("%0d: HEX=%h, REAL=%f", i, output_vec1[i], $itor($signed(output_vec1[i]))/1024.0);
        $display("Layer 1 output after ReLU (first 5):");
        for (i = 0; i < 5; i = i + 1) $display("%0d: HEX=%h, REAL=%f", i, relu_vec1[i], $itor($signed(relu_vec1[i]))/1024.0);
        // 3. Layer 2
        flatten_input2();
        rst2 = 1; #20; rst2 = 0; #20;
        start2 = 1; @(negedge clk); start2 = 0;
        wait(done2);
        unflatten_output2();
        relu_layer2();
        $display("Layer 2 output (first 5):");
        for (i = 0; i < 5; i = i + 1) $display("%0d: HEX=%h, REAL=%f", i, output_vec2[i], $itor($signed(output_vec2[i]))/1024.0);
        $display("Layer 2 output after ReLU (first 5):");
        for (i = 0; i < 5; i = i + 1) $display("%0d: HEX=%h, REAL=%f", i, relu_vec2[i], $itor($signed(relu_vec2[i]))/1024.0);
        // 4. Layer 3
        flatten_input3();
        rst3 = 1; #20; rst3 = 0; #20;
        start3 = 1; @(negedge clk); start3 = 0;
        wait(done3);
        unflatten_output3();
        $display("Layer 3 output (first 5):");
        for (i = 0; i < 5; i = i + 1) $display("%0d: HEX=%h, REAL=%f", i, output_vec3[i], $itor($signed(output_vec3[i]))/1024.0);
        $display("Pipeline test completed.");
        $finish;
    end
endmodule
