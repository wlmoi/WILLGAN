import numpy as np
from layer2_generator_hw import read_mem_file

# top indices (from previous run)
TOP_IDX = [8,9,7,5,3,1,6,2]

input_mem = "d:/WILLGAN/hardware/layers/mem/layer1_relu_output.mem"
weight_file = "d:/WILLGAN/software/generated_from_hubert/epoch300_G_l2_W.mem"
bias_file = "d:/WILLGAN/software/generated_from_hubert/epoch300_G_l2_B.mem"

# load
in_raw = read_mem_file(input_mem, 256).astype(np.int32)
W_raw = read_mem_file(weight_file, 256*256).astype(np.int32).reshape(256,256)
B_raw = read_mem_file(bias_file, 256).astype(np.int32)

OUT_DIR = "d:/WILLGAN/software/neuron_diagnostics"
import os
os.makedirs(OUT_DIR, exist_ok=True)

for n in TOP_IDX:
    wvec = W_raw[n, :]
    b = int(B_raw[n])
    # contributions: (input * weight) >> 10 per HW implementation
    prods = in_raw * wvec  # int32 * int32 -> int32 (safe)
    contribs = prods >> 10
    total = b + int(np.sum(contribs, dtype=np.int64))
    sat = max(min(total, 32767), -32768)
    relu = max(sat, 0)

    # stats
    w_min, w_max = int(np.min(wvec)), int(np.max(wvec))
    w_mean = float(np.mean(wvec))
    large_w = np.sum(np.abs(wvec) > 1000)
    contrib_abs_sorted_idx = np.argsort(-np.abs(contribs))

    print(f"\nNeuron {n}: bias={b}, total_before_sat={total}, sat={sat}, relu={relu}")
    print(f"  weight stats: min={w_min}, max={w_max}, mean={w_mean:.2f}, |w|>1000 count={int(large_w)}")
    topk = 16
    print(f"  Top {topk} absolute contributions (value, inp_idx, input_val, weight):")
    for rank in range(topk):
        idx = int(contrib_abs_sorted_idx[rank])
        print(f"    {rank+1:2d}. {int(contribs[idx]):7d}  idx={idx:3d} in={int(in_raw[idx]):6d} w={int(wvec[idx]):6d}")

    # save full contributions to CSV for offline inspection
    out_csv = os.path.join(OUT_DIR, f"neuron_{n}_contribs.csv")
    with open(out_csv, 'w') as f:
        f.write('input_idx,input_val,weight,prod,contrib\n')
        for i in range(256):
            f.write(f"{i},{int(in_raw[i])},{int(wvec[i])},{int(prods[i])},{int(contribs[i])}\n")
    print(f"  Saved full contributions to {out_csv}")

print('\nDiagnostics complete.')
