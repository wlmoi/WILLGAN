import numpy as np
from layer2_generator_hw import read_mem_file, layer2_generator_hw

in_mem = "d:/WILLGAN/hardware/layers/mem/layer1_relu_output.mem"
w_mem = "d:/WILLGAN/software/generated_from_hubert/epoch300_G_l2_W.mem"
b_mem = "d:/WILLGAN/software/generated_from_hubert/epoch300_G_l2_B.mem"
out_mem = "d:/WILLGAN/hardware/layers/mem/layer2_relu_output.mem"

in_q5_10 = read_mem_file(in_mem, 256)
out = layer2_generator_hw(in_q5_10, w_mem, b_mem)

def leaky_relu(x):
    return x if x >= 0 else x >> 3

out_leaky = np.array([leaky_relu(int(v)) for v in out], dtype=np.int16)

with open(out_mem, "w") as f:
    for v in out_leaky:
        # Format as two's complement hex
        hexstr = format((int(v) + (1 << 16)) % (1 << 16), '04x')
        f.write(f"{hexstr}\n")
print(f"Wrote {len(out_leaky)} outputs to {out_mem}")
