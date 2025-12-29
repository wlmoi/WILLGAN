import numpy as np
from layer2_generator_hw import read_mem_file

input_mem = "d:/WILLGAN/hardware/layers/mem/layer1_relu_output.mem"
weight_file = "d:/WILLGAN/software/generated_from_hubert/epoch300_G_l2_W.mem"
bias_file = "d:/WILLGAN/software/generated_from_hubert/epoch300_G_l2_B.mem"

in_q5_10 = read_mem_file(input_mem, 256).astype(np.int32)
W = read_mem_file(weight_file, 256*256).astype(np.int32).reshape(256, 256)
B = read_mem_file(bias_file, 256).astype(np.int32)

# Diagnostic for neurons 0..9
for n in range(10):
    acc = np.int32(B[n])
    print(f"Neuron {n}: bias={B[n]}")
    # compute contributions in chunks to avoid huge output; show first 16 contributions
    contributions = []
    for k in range(256):
        prod = np.int32(in_q5_10[k]) * np.int32(W[n, k])
        prod_shift = prod >> 10
        contributions.append(prod_shift)
    total = acc + int(np.sum(contributions, dtype=np.int64))
    total_sat = max(min(total, 32767), -32768)
    total_relu = max(total_sat, 0)
    print(f"  sum(prod>>10) (first16): {contributions[:16]}")
    print(f"  sum(prod>>10) total: {int(np.sum(contributions, dtype=np.int64))}")
    print(f"  acc after bias: {acc + int(np.sum(contributions, dtype=np.int64))}")
    print(f"  saturated: {total_sat}, relu: {total_relu}\n")

# Print final outputs for neurons 0..9
out = np.zeros(256, dtype=np.int16)
for n in range(256):
    acc = np.int32(B[n])
    for k in range(256):
        prod = np.int32(in_q5_10[k]) * np.int32(W[n, k])
        acc += prod >> 10
    acc = max(min(acc, 32767), -32768)
    acc = max(acc, 0)
    out[n] = np.int16(acc)

print('Computed outputs 0..9:', out[:10].tolist())
