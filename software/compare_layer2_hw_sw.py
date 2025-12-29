import numpy as np
from layer2_generator_sw import layer2_generator_sw

def compare_hw_sw_outputs(hw_output, sw_output, n=10):
    print("Index | HW Output | SW Output | Match")
    for i in range(n):
        print(f"{i:5d} | {hw_output[i]:9} | {sw_output[i]:9} | {'OK' if hw_output[i]==sw_output[i] else 'FAIL'}")
    print("All match:", np.all(hw_output == sw_output))

if __name__ == "__main__":
    # Load software output
    from test_layer2_sw import read_mem_file, read_weights_mem
    weights = read_weights_mem("../hardware/layers/mem/epoch300_G_l2_W.mem")
    biases = read_mem_file("../hardware/layers/mem/epoch300_G_l2_B.mem", 256)
    input_vec = np.zeros(256, dtype=np.int16)
    sw_out = layer2_generator_sw(input_vec, weights, biases)

    # Load hardware output (from testbench, e.g. dump to file or copy-paste)
    # Example: replace this with actual hardware output
    hw_out = np.array([
        # Paste 256 output values here, e.g. from $display in testbench
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, # ...
    ], dtype=np.int16)

    compare_hw_sw_outputs(hw_out, sw_out, n=10)
