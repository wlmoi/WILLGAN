import numpy as np
import csv
from layer2_generator_hw import read_mem_file, layer2_generator_hw

# File paths
input_mem = "d:/WILLGAN/hardware/layers/mem/layer1_relu_output.mem"
weight_file = "d:/WILLGAN/software/generated_from_hubert/epoch300_G_l2_W.mem"
bias_file = "d:/WILLGAN/software/generated_from_hubert/epoch300_G_l2_B.mem"
ref_csv = "d:/WILLGAN/hardware/layers/reference/G_layer2_output.csv"

# Run hardware-oriented layer 2 generator
in_q5_10 = read_mem_file(input_mem, 256)
out_q5_10 = layer2_generator_hw(in_q5_10, weight_file, bias_file)

# Load reference CSV (use only Q6.10_value column, skip header)
ref = []
with open(ref_csv, 'r') as f:
    reader = csv.reader(f)
    header = next(reader)  # skip header
    for row in reader:
        if len(row) >= 2:
            try:
                ref.append(int(row[1].strip()))
            except ValueError:
                continue
ref = np.array(ref, dtype=np.int16)

# Compare

print("Index | HW Out | Ref | Ref/2 | Diff | Diff/2 | Match | Match/2")
print("---------------------------------------------------------------")
n_match = 0
n_match2 = 0

# Compare up to the minimum available entries between HW output and reference
n = min(len(out_q5_10), len(ref))
if n == 0:
    print("No data to compare (empty output or reference).")
    exit(1)

for i in range(n):
    hw = int(out_q5_10[i])
    ref_val = int(ref[i])
    # Q6.10 to Q5.10 scaling: use rounding to nearest integer
    ref2 = int(round(ref_val / 2.0))
    diff = hw - ref_val
    diff2 = hw - ref2
    match = hw == ref_val
    match2 = hw == ref2
    if match:
        n_match += 1
    if match2:
        n_match2 += 1
    print(f"{i:3d} | {hw:7d} | {ref_val:7d} | {ref2:6d} | {diff:5d} | {diff2:7d} | {'OK' if match else 'FAIL '} | {'OK' if match2 else 'FAIL '}")

print(f"\nCompared entries: {n}")
print(f"Matched (raw): {n_match}/{n}")
print(f"Matched (Q5.10 scaling, ref/2): {n_match2}/{n}")

# Summary statistics between HW output and rounded reference (Q5.10)
hw_arr = np.array([int(x) for x in out_q5_10[:n]], dtype=np.int32)
ref_q5_arr = np.array([int(round(v / 2.0)) for v in ref[:n]], dtype=np.int32)
abs_diff = np.abs(hw_arr - ref_q5_arr)
print(f"Mean abs diff (vs ref Q5.10): {np.mean(abs_diff):.3f}")
print(f"Max abs diff  (vs ref Q5.10): {np.max(abs_diff)}")
rmse = np.sqrt(np.mean((hw_arr - ref_q5_arr) ** 2))
print(f"RMSE (vs ref Q5.10): {rmse:.3f}")
