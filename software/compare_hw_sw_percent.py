import numpy as np
import os

def q6_10_to_float(arr):
    return arr.astype(np.int16) / 1024.0

def compare_layer(hw_file, sw_file, name):
    # Read hardware output (hex, Q6.10)
    hw = np.array([int(x, 16) for x in open(hw_file) if x.strip()], dtype=np.int16)
    # Read software output (float or Q6.10 int)
    sw = np.loadtxt(sw_file)
    if np.all(np.abs(sw) > 50):  # If all values are large, treat as Q6.10 int
        sw = q6_10_to_float(sw)
    hw_f = q6_10_to_float(hw)
    print(f"\n{name} Comparison:")
    print(f"{'Idx':>4} {'HW':>10} {'SW':>10} {'AbsErr':>10} {'%Err':>10}")
    for i, (h, s) in enumerate(zip(hw_f, sw)):
        abserr = abs(h - s)
        percent = 100 * abserr / (abs(s) + 1e-8)
        print(f"{i:4d} {h:10.5f} {s:10.5f} {abserr:10.5f} {percent:10.2f}")
    mae = np.mean(np.abs(hw_f - sw))
    mape = np.mean(100 * np.abs(hw_f - sw) / (np.abs(sw) + 1e-8))
    print(f"\n{name} MAE: {mae:.5f}")
    print(f"{name} MAPE: {mape:.2f}%")
    return mae, mape

# --- CONFIG ---
layers = [
    {'name': 'G1', 'hw': 'mem/G1_hw.mem', 'sw': 'mem/G1_sw.txt'},
    {'name': 'G2', 'hw': 'mem/G2_hw.mem', 'sw': 'mem/G2_sw.txt'},
    {'name': 'G3', 'hw': 'mem/G3_hw.mem', 'sw': 'mem/G3_sw.txt'},
    {'name': 'D1', 'hw': 'mem/D1_hw.mem', 'sw': 'mem/D1_sw.txt'},
    {'name': 'D2', 'hw': 'mem/D2_hw.mem', 'sw': 'mem/D2_sw.txt'},
    {'name': 'D3', 'hw': 'mem/D3_hw.mem', 'sw': 'mem/D3_sw.txt'},
    {'name': 'ReLU', 'hw': 'mem/relu_hw.mem', 'sw': 'mem/relu_sw.txt'},
    {'name': 'Tanh', 'hw': 'mem/tanh_hw.mem', 'sw': 'mem/tanh_sw.txt'},
]

summary = []
for l in layers:
    if not (os.path.exists(l['hw']) and os.path.exists(l['sw'])):
        print(f"Warning: missing file for {l['name']}")
        continue
    mae, mape = compare_layer(l['hw'], l['sw'], l['name'])
    summary.append({'name': l['name'], 'mae': mae, 'mape': mape})

if summary:
    print("\nSummary Table:")
    print(f"{'Layer':>8} | {'MAE':>10} | {'MAPE (%)':>10}")
    print("-"*34)
    for s in summary:
        print(f"{s['name']:>8} | {s['mae']:10.5f} | {s['mape']:10.2f}")
