import numpy as np
import os

def read_mem_file(path, n=None):
    """Read .mem file as int16 array. n: expected length (optional)"""
    with open(path) as f:
        lines = [line.strip() for line in f if line.strip()]
    arr = np.array([int(x, 16) if 'x' not in x else 0 for x in lines], dtype=np.int16)
    if n is not None and len(arr) != n:
        print(f"Warning: {path} length {len(arr)} != expected {n}")
    return arr

def read_txt_file(path, n=None):
    arr = np.loadtxt(path, dtype=np.int16)
    if n is not None and len(arr) != n:
        print(f"Warning: {path} length {len(arr)} != expected {n}")
    return arr

def compare_outputs(hw, sw, name):
    error = np.abs(hw - sw)
    n_error = np.sum(error != 0)
    mse = np.mean(error**2)
    mae = np.mean(error)
    print(f"{name:20} | Jumlah Error: {n_error:6d} | MSE: {mse:10.4f} | MAE: {mae:8.4f}")
    return n_error, mse, mae

def print_summary_table(results):
    print("\nSummary:")
    print(f"{'Layer':20} | {'Jumlah Error':>12} | {'MSE':>10} | {'MAE':>8} | {'Clock':>8}")
    print("-"*65)
    for r in results:
        print(f"{r['name']:20} | {r['n_error']:12d} | {r['mse']:10.4f} | {r['mae']:8.4f} | {r['clock']:8d}")

def read_clock_from_log(logfile):
    # Expect line: 'Clock cycles: <number>'
    with open(logfile) as f:
        for line in f:
            if 'Clock cycles:' in line:
                return int(line.strip().split(':')[-1])
    return -1

# --- CONFIG ---
layers = [
    {'name': 'D1', 'hw': 'mem/D1_hw.mem', 'sw': 'mem/D1_sw.txt', 'log': 'mem/D1_hw.log', 'n': 256},
    {'name': 'D2', 'hw': 'mem/D2_hw.mem', 'sw': 'mem/D2_sw.txt', 'log': 'mem/D2_hw.log', 'n': 256},
    {'name': 'D3', 'hw': 'mem/D3_hw.mem', 'sw': 'mem/D3_sw.txt', 'log': 'mem/D3_hw.log', 'n': 1},
    {'name': 'G1', 'hw': 'mem/G1_hw.mem', 'sw': 'mem/G1_sw.txt', 'log': 'mem/G1_hw.log', 'n': 256},
    {'name': 'G2', 'hw': 'mem/G2_hw.mem', 'sw': 'mem/G2_sw.txt', 'log': 'mem/G2_hw.log', 'n': 256},
    {'name': 'G3', 'hw': 'mem/G3_hw.mem', 'sw': 'mem/G3_sw.txt', 'log': 'mem/G3_hw.log', 'n': 784},
    {'name': 'ReLU', 'hw': 'mem/relu_hw.mem', 'sw': 'mem/relu_sw.txt', 'log': 'mem/relu_hw.log', 'n': 256},
    {'name': 'Tanh', 'hw': 'mem/tanh_hw.mem', 'sw': 'mem/tanh_sw.txt', 'log': 'mem/tanh_hw.log', 'n': 256},
]

results = []
for l in layers:
    if not (os.path.exists(l['hw']) and os.path.exists(l['sw'])):
        print(f"Warning: missing file for {l['name']}")
        continue
    hw = read_mem_file(l['hw'], l['n'])
    sw = read_txt_file(l['sw'], l['n'])
    n_error, mse, mae = compare_outputs(hw, sw, l['name'])
    clock = read_clock_from_log(l['log']) if os.path.exists(l['log']) else -1
    results.append({'name': l['name'], 'n_error': n_error, 'mse': mse, 'mae': mae, 'clock': clock})

print_summary_table(results)
