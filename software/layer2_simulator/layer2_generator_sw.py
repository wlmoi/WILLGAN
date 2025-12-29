import numpy as np

def layer2_generator_sw(input_vec, weights, biases):
    """
    Software reference for Layer 2 generator (Q6.10 fixed-point emulation).
    input_vec: shape (256,) int16, Q6.10
    weights: shape (256,256) int16, Q6.10
    biases: shape (256,) int16, Q6.10
    Returns: output_vec (256,) int16, Q6.10
    """
    # Convert to int32 for accumulation
    input_vec = input_vec.astype(np.int32)
    weights = weights.astype(np.int32)
    biases = biases.astype(np.int32)
    output_vec = np.zeros(256, dtype=np.int32)
    for n in range(256):
        acc = biases[n]
        for i in range(256):
            prod = (input_vec[i] * weights[n, i])
            prod_q10 = prod >> 10  # Q6.10
            acc += prod_q10
        # Saturate to int16
        if acc > 32767:
            acc = 32767
        elif acc < -32768:
            acc = -32768
        output_vec[n] = acc
    return output_vec.astype(np.int16)

if __name__ == "__main__":
    # Example: all input 0, random weights/biases
    input_vec = np.zeros(256, dtype=np.int16)
    weights = np.zeros((256,256), dtype=np.int16)
    biases = np.arange(256, dtype=np.int16)  # Example bias: 0,1,2,...
    out = layer2_generator_sw(input_vec, weights, biases)
    print("Output (should match bias):", out[:10])
