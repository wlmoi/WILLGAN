import numpy as np
from layer2_generator_hw import read_mem_file, layer2_generator_hw
import layer2_generator_sw as sw
import csv

# paths
input_mem = "d:/WILLGAN/hardware/layers/mem/layer1_relu_output.mem"
weight_file = "d:/WILLGAN/software/generated_from_hubert/epoch300_G_l2_W.mem"
bias_file = "d:/WILLGAN/software/generated_from_hubert/epoch300_G_l2_B.mem"
ref_csv = "d:/WILLGAN/hardware/layers/reference/G_layer2_output.csv"

# load mems as int16 (Q5.10 for HW files)
in_q5_10 = read_mem_file(input_mem, 256).astype(np.int16)
W_q5 = read_mem_file(weight_file, 256*256).astype(np.int16).reshape(256,256)
B_q5 = read_mem_file(bias_file, 256).astype(np.int16)

# HW output (Q5.10)
out_hw_q5 = layer2_generator_hw(in_q5_10, weight_file, bias_file).astype(np.int16)

# Convert mems to Q6.10 for SW by left-shifting 1 (multiply by 2)
# Keep within int16 range
in_q6 = (in_q5_10.astype(np.int32) << 1).astype(np.int16)
W_q6 = (W_q5.astype(np.int32) << 1).astype(np.int16)
B_q6 = (B_q5.astype(np.int32) << 1).astype(np.int16)

# SW output (Q6.10)
out_sw_q6 = sw.layer2_generator_sw(in_q6, W_q6, B_q6).astype(np.int16)

# HW scaled to Q6.10
out_hw_q6 = (out_hw_q5.astype(np.int32) << 1).astype(np.int16)

# Compare HW vs SW (full 256)
abs_diff = np.abs(out_hw_q6.astype(np.int32) - out_sw_q6.astype(np.int32))
print(f"HW vs SW (Q6.10 scaled): mean abs diff={np.mean(abs_diff):.3f}, max={np.max(abs_diff)}, rmse={np.sqrt(np.mean((out_hw_q6.astype(np.int32)-out_sw_q6.astype(np.int32))**2)):.3f}")

# Compare to reference CSV where available
ref = []
with open(ref_csv,'r') as f:
    reader = csv.reader(f)
    header = next(reader)
    for row in reader:
        if len(row)>=2:
            try:
                ref.append(int(row[1].strip()))
            except ValueError:
                continue
ref = np.array(ref, dtype=np.int16)

n = min(len(ref), 256)
if n>0:
    # Compare SW vs CSV (both Q6.10)
    abs_diff_sw_ref = np.abs(out_sw_q6[:n].astype(np.int32) - ref[:n].astype(np.int32))
    print(f"SW vs CSV first {n} entries: mean abs diff={np.mean(abs_diff_sw_ref):.3f}, max={np.max(abs_diff_sw_ref)}, rmse={np.sqrt(np.mean((out_sw_q6[:n].astype(np.int32)-ref[:n].astype(np.int32))**2)):.3f}")
    # Compare HW (scaled) vs CSV
    abs_diff_hw_ref = np.abs(out_hw_q6[:n].astype(np.int32) - ref[:n].astype(np.int32))
    print(f"HW(scaled) vs CSV first {n} entries: mean abs diff={np.mean(abs_diff_hw_ref):.3f}, max={np.max(abs_diff_hw_ref)}, rmse={np.sqrt(np.mean((out_hw_q6[:n].astype(np.int32)-ref[:n].astype(np.int32))**2)):.3f}")

# Print counts where exact match (unlikely)
matches_hw_sw = np.sum(out_hw_q6==out_sw_q6)
print(f"Exact matches HW(scaled)==SW: {matches_hw_sw}/256")

# Show first 16 comparisons
print('\nIndex | HW(Q6) | SW(Q6) | CSV(Q6) | HW-SW | HW-CSV | SW-CSV')
for i in range(min(16,256)):
    csvv = ref[i] if i < len(ref) else None
    hwv = int(out_hw_q6[i])
    swv = int(out_sw_q6[i])
    print(f"{i:3d} | {hwv:7d} | {swv:7d} | {str(csvv):7s} | {hwv-swv:6d} | {hwv-(csvv if csvv is not None else 0):7d} | {swv-(csvv if csvv is not None else 0):7d}")
