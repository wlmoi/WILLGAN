% Test script for layer2_generator_hw using mem from generated_from_hubert

% Load input vector (layer1 ReLU output, Q5.10, int16)
input_mem = 'd:/WILLGAN/hardware/layers/mem/layer1_relu_output.mem';
input_lines = readlines(input_mem);
in_q5_10 = int16(hex2dec(input_lines));

% Load weights and biases from generated_from_hubert (Q5.10, int16)
weight_file = 'd:/WILLGAN/software/generated_from_hubert/epoch300_G_l2_W.mem';
bias_file   = 'd:/WILLGAN/software/generated_from_hubert/epoch300_G_l2_B.mem';

% Run hardware-oriented layer 2 generator
out_q5_10 = layer2_generator_hw(in_q5_10, weight_file, bias_file);

disp('Layer 2 output (Q5.10, int16):');
disp(out_q5_10');
