import numpy as np

def read_mem_file(filepath, count=None):
    with open(filepath, 'r') as f:
        lines = f.readlines()
    arr = np.array([int(line.strip(), 16) for line in lines], dtype=np.uint16)
    arr = arr.view(np.int16)
    if count is not None:
        arr = arr[:count]
    return arr

def tanh_approx_q6_10(x):
    # x: int32 or int16, Q6.10
    x = np.asarray(x, dtype=np.int32)
    pos_thresh = 1536  # +1.5 in Q6.10
    neg_thresh = -1536 # -1.5 in Q6.10
    max_val = 1024     # +1.0 in Q6.10
    min_val = -1024    # -1.0 in Q6.10
    out = np.where(x >= pos_thresh, max_val,
          np.where(x <= neg_thresh, min_val,
          x >> 1))
    return out.astype(np.int16)

def layer3_generator_hw(in_q5_10, weight_file, bias_file, return_mac=False):
    N_OUT = 784
    N_IN = 256
    assert in_q5_10.shape == (N_IN,)
    W = read_mem_file(weight_file, N_OUT*N_IN).reshape(N_OUT, N_IN)
    B = read_mem_file(bias_file, N_OUT)
    out = np.zeros(N_OUT, dtype=np.int16)
    macs = np.zeros(N_OUT, dtype=np.int32)
    for n in range(N_OUT):
        acc = np.int32(B[n])
        for k in range(N_IN):
            prod = np.int32(in_q5_10[k]) * np.int32(W[n, k])
            prod = prod >> 10
            acc += prod
        acc = max(min(acc, 32767), -32768)
        acc_q6_10 = np.int32(acc) << 1
        macs[n] = acc_q6_10
        out[n] = tanh_approx_q6_10(acc_q6_10)
    if return_mac:
        return out, macs
    return out

if __name__ == "__main__":
    input_mem = "d:/WILLGAN/hardware/layers/mem/layer2_relu_output.mem"
    weight_file = "d:/WILLGAN/hardware/layers/mem/epoch300_G_l3_W.mem"
    bias_file = "d:/WILLGAN/hardware/layers/mem/epoch300_G_l3_B.mem"
    in_q5_10 = read_mem_file(input_mem, 256)
    out_q6_10, macs_q6_10 = layer3_generator_hw(in_q5_10, weight_file, bias_file, return_mac=True)
    print("Layer 3 MAC output (Q6.10, before tanh):")
    print(macs_q6_10)
    print("Layer 3 output (Q6.10, after tanh):")
    print(out_q6_10)
    print("Difference (MAC - tanh):")
    print(macs_q6_10 - out_q6_10)
