import numpy as np
import csv
from layer2_generator_hw import read_mem_file, layer2_generator_hw
import layer2_generator_sw as sw

# paths
input_mem = "d:/WILLGAN/hardware/layers/mem/layer1_relu_output.mem"
weight_file = "d:/WILLGAN/software/generated_from_hubert/epoch300_G_l2_W.mem"
bias_file = "d:/WILLGAN/software/generated_from_hubert/epoch300_G_l2_B.mem"
ref_csv = "d:/WILLGAN/hardware/layers/reference/G_layer2_output.csv"

# load raw mems (Q5.10 format for hardware mems)
in_raw = read_mem_file(input_mem, 256).astype(np.int16)
W_raw = read_mem_file(weight_file, 256*256).astype(np.int16).reshape(256,256)
B_raw = read_mem_file(bias_file, 256).astype(np.int16)

# HW output and scaled-to-Q6.10 HW
out_hw_q5 = layer2_generator_hw(in_raw, weight_file, bias_file).astype(np.int16)
out_hw_q6 = (out_hw_q5.astype(np.int32) << 1).astype(np.int16)

# load CSV ref (Q6.10)
ref = []
with open(ref_csv,'r') as f:
    r = csv.reader(f)
    next(r)
    for row in r:
        if len(row) >= 2:
            try:
                ref.append(int(row[1].strip()))
            except ValueError:
                continue
ref = np.array(ref, dtype=np.int16)

n = min(256, len(ref))
print(f"CSV entries available: {len(ref)}, comparing first {n} entries")

# Conversion variants to test (apply left shift to convert from Q5.10->Q6.10)
variants = {
    'none': (False, False, False),
    'inputs': (True, False, False),
    'weights': (False, True, False),
    'biases': (False, False, True),
    'inputs_weights': (True, True, False),
    'inputs_biases': (True, False, True),
    'weights_biases': (False, True, True),
    'all_shift': (True, True, True),
}

results = []
for name, (shift_in, shift_w, shift_b) in variants.items():
    # create copies
    in_v = in_raw.astype(np.int32)
    W_v = W_raw.astype(np.int32)
    B_v = B_raw.astype(np.int32)
    if shift_in:
        in_v = (in_v << 1).astype(np.int32)
    if shift_w:
        W_v = (W_v << 1).astype(np.int32)
    if shift_b:
        B_v = (B_v << 1).astype(np.int32)
    # cast back to int16 for SW func
    in_v16 = in_v.astype(np.int16)
    W_v16 = W_v.astype(np.int16)
    B_v16 = B_v.astype(np.int16)

    # run SW (expects Q6.10 format inputs/weights/biases)
    out_sw_q6 = sw.layer2_generator_sw(in_v16, W_v16, B_v16).astype(np.int16)

    # compare SW to CSV (both Q6.10) for first n
    abs_diff = np.abs(out_sw_q6[:n].astype(np.int32) - ref[:n].astype(np.int32))
    mean_abs = float(np.mean(abs_diff))
    max_abs = int(np.max(abs_diff))
    rmse = float(np.sqrt(np.mean((out_sw_q6[:n].astype(np.int32)-ref[:n].astype(np.int32))**2)))
    results.append((name, mean_abs, max_abs, rmse))
    print(f"Variant {name}: mean_abs={mean_abs:.3f}, max={max_abs}, rmse={rmse:.3f}")

# Sort results by mean_abs
results_sorted = sorted(results, key=lambda x: x[1])
print('\nSorted by mean abs diff:')
for r in results_sorted:
    print(r)

# Also compare HW(scaled) vs CSV and find top-diff neurons
abs_diff_hw_csv = np.abs(out_hw_q6[:n].astype(np.int32) - ref[:n].astype(np.int32))
idx_desc = np.argsort(-abs_diff_hw_csv)  # descending
K = 8
top_idx = idx_desc[:K]
print(f"\nTop {K} indices with largest |HW-Q6 - CSV|:")
for idx in top_idx:
    print(f"idx={int(idx)}, HW(Q6)={int(out_hw_q6[int(idx)])}, CSV={int(ref[int(idx)])}, absdiff={int(abs_diff_hw_csv[int(idx)])}")
    # dump weight vector to file
    wvec = W_raw[int(idx), :]
    out_path = f"d:/WILLGAN/software/weights_neuron_{int(idx)}.txt"
    with open(out_path, 'w') as of:
        of.write('# weight index, dec(Q5.10), hex16\n')
        for i, w in enumerate(wvec):
            of.write(f"{i},{int(w)},{int(w) & 0xFFFF:04X}\n")
    print(f"  dumped weights to {out_path}")

print('\nDone.')
