import numpy as np

def read_mem_file(filename, count):
    """Read a .mem file as signed 16-bit integers."""
    with open(filename, 'r') as f:
        lines = f.readlines()
    arr = np.array([int(line.strip(), 16).astype(np.int16) for line in lines[:count]], dtype=np.int16)
    return arr

def read_weights_mem(filename, n_neurons=256, n_inputs=256):
    """Read weights .mem file and reshape to (n_neurons, n_inputs)."""
    arr = read_mem_file(filename, n_neurons * n_inputs)
    return arr.reshape((n_neurons, n_inputs))

if __name__ == "__main__":
    from layer2_generator_sw import layer2_generator_sw
    # Read mem files
    weights = read_weights_mem("../hardware/layers/mem/epoch300_G_l2_W.mem")
    biases = read_mem_file("../hardware/layers/mem/epoch300_G_l2_B.mem", 256)
    # Test all input 0
    input_vec = np.zeros(256, dtype=np.int16)
    out = layer2_generator_sw(input_vec, weights, biases)
    print("Output (all input 0):", out[:10])
    print("Biases (should match):", biases[:10])
    print("Equal?", np.all(out == biases))
