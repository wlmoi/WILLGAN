function out_q5_10 = layer2_generator_hw(in_q5_10, weight_file, bias_file)
% Hardware-oriented Layer 2 generator (Q5.10 fixed-point)
% in_q5_10: 256x1 int16 input vector (Q5.10)
% weight_file: .hex file for weights (256x256, Q6.10, int16)
% bias_file: .hex file for biases (256x1, Q6.10, int16)
% out_q5_10: 256x1 int16 output vector (Q5.10)

N = 256;
assert(numel(in_q5_10) == N, 'Input must be 256x1');

% Load weights and biases (Q6.10, int16)
W = int16(hex2dec(readlines(weight_file)));
B = int16(hex2dec(readlines(bias_file)));
W = reshape(W, N, N); % Each row: neuron, each col: input

out_q5_10 = zeros(N,1,'int16');
for n = 1:N
    acc = int32(B(n));
    for k = 1:N
        % MAC: (Q5.10 * Q6.10) >> 10 = Q5.10
        prod = int32(in_q5_10(k)) * int32(W(n,k)); % Q5.10 * Q6.10 = Q11.20
        prod = bitshift(prod, -10); % Q5.10
        acc = acc + prod;
    end
    % Saturate to int16 range
    acc = min(max(acc, -32768), 32767);
    % ReLU
    acc = max(acc, 0);
    out_q5_10(n) = int16(acc);
end
end
