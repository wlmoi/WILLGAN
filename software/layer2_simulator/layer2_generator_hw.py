import numpy as np

def read_mem_file(filepath, count=None):
    """Read a .mem file as int16 array."""
    with open(filepath, 'r') as f:
        lines = f.readlines()
    arr = np.array([int(line.strip(), 16) for line in lines], dtype=np.uint16)
    arr = arr.view(np.int16)
    if count is not None:
        arr = arr[:count]
    return arr

def layer2_generator_hw(in_q5_10, weight_file, bias_file, output_q6=False):
    """
    Hardware-oriented Layer 2 generator.
    in_q5_10: (256,) int16 numpy array (Q5.10)
    weight_file: .mem file for weights (256x256, Q5.10, int16)
    bias_file: .mem file for biases (256, Q5.10, int16)
    output_q6: if True, return outputs scaled to Q6.10 by left-shifting 1 (int16)
    Returns: (256,) int16 numpy array (Q5.10 by default, or Q6.10 if output_q6=True)
    """
    N = 256
    assert in_q5_10.shape == (N,)
    W = read_mem_file(weight_file, N*N).reshape(N, N) # (neuron, input)
    B = read_mem_file(bias_file, N)
    out = np.zeros(N, dtype=np.int16)
    for n in range(N):
        acc = np.int32(B[n])
        for k in range(N):
            prod = np.int32(in_q5_10[k]) * np.int32(W[n, k]) # Q5.10 * Q5.10 = Q10.20
            prod = prod >> 10 # Q5.10
            acc += prod
        # Saturate to int16
        acc = max(min(acc, 32767), -32768)
        # ReLU
        acc = max(acc, 0)
        if output_q6:
            # convert from Q5.10 to Q6.10 by left shifting 1, with saturation
            acc_q6 = int(acc) << 1
            acc_q6 = max(min(acc_q6, 32767), -32768)
            out[n] = np.int16(acc_q6)
        else:
            out[n] = np.int16(acc)
    return out

if __name__ == "__main__":
    # Example usage with your mem files
    input_mem = "d:/WILLGAN/hardware/layers/mem/layer1_relu_output.mem"
    weight_file = "d:/WILLGAN/software/generated_from_hubert/epoch300_G_l2_W.mem"
    bias_file = "d:/WILLGAN/software/generated_from_hubert/epoch300_G_l2_B.mem"
    in_q5_10 = read_mem_file(input_mem, 256)
    out_q5_10 = layer2_generator_hw(in_q5_10, weight_file, bias_file)
    print("Layer 2 output (Q5.10, int16):")
    print(out_q5_10)
    out_q6 = layer2_generator_hw(in_q5_10, weight_file, bias_file, output_q6=True)
    print("Layer 2 output (Q6.10 scaled, int16):")
    print(out_q6)
