import numpy as np
import csv
import os

def read_mem_file(filepath, count=None):
    """Read a .mem file as int16 array (hex lines)."""
    with open(filepath, 'r') as f:
        lines = [l.strip() for l in f if l.strip()]
    arr = np.array([int(line, 16) for line in lines], dtype=np.uint16)
    arr = arr.view(np.int16)
    if count is not None:
        arr = arr[:count]
    return arr


def layer3_generator_hw(in_q5_10, weight_file, bias_file, output_q6=False):
    """
    Hardware-oriented Layer 3 generator simulation.
    in_q5_10: (256,) int16 numpy array (Q5.10)
    weight_file: .mem file for weights (784x256, Q5.10, int16)
    bias_file: .mem file for biases (784, Q5.10, int16)
    If output_q6=True, outputs are returned in Q6.10 (left-shift 1).
    Returns: (784,) int16 numpy array
    """
    N_IN = 256
    N_OUT = 784
    assert in_q5_10.shape == (N_IN,)
    W = read_mem_file(weight_file, N_OUT * N_IN).reshape(N_OUT, N_IN)
    B = read_mem_file(bias_file, N_OUT)
    out = np.zeros(N_OUT, dtype=np.int16)
    for n in range(N_OUT):
        acc = np.int32(B[n])
        for k in range(N_IN):
            prod = np.int32(in_q5_10[k]) * np.int32(W[n, k])  # Q5.10 * Q5.10 = Q10.20
            prod_shift = prod >> 10  # back to Q5.10
            acc += prod_shift
        # Saturate to int16 range
        if acc > 32767:
            acc = 32767
        elif acc < -32768:
            acc = -32768
        if output_q6:
            acc_q6 = int(acc) << 1
            if acc_q6 > 32767:
                acc_q6 = 32767
            elif acc_q6 < -32768:
                acc_q6 = -32768
            out[n] = np.int16(acc_q6)
        else:
            out[n] = np.int16(acc)
    return out


def compare_with_reference(out_q6, ref_csv_path, nrows=10):
    """Compare first `nrows` outputs with reference CSV (expects Q6.10_value column)."""
    mismatches = []
    with open(ref_csv_path, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        for i, row in enumerate(reader):
            if i >= nrows:
                break
            ref_val = int(row['Q6.10_value'])
            sim_val = int(out_q6[i])
            if ref_val != sim_val:
                mismatches.append((i, ref_val, sim_val, float(row['float'])))
    return mismatches


if __name__ == '__main__':
    # Paths (relative to repo root)
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    input_mem = os.path.join(repo_root, 'hardware', 'layers', 'mem', 'layer2_relu_output.mem')
    weight_file = os.path.join(repo_root, 'hardware', 'layers', 'mem', 'epoch300_G_l3_W.mem')
    bias_file = os.path.join(repo_root, 'hardware', 'layers', 'mem', 'epoch300_G_l3_B.mem')
    ref_csv = os.path.join(repo_root, 'hardware', 'layers', 'reference', 'G_layer3_output.csv')

    in_q5 = read_mem_file(input_mem, 256)
    out_q5 = layer3_generator_hw(in_q5, weight_file, bias_file, output_q6=False)
    out_q6 = layer3_generator_hw(in_q5, weight_file, bias_file, output_q6=True)

    print('First 10 outputs (Q6.10) from simulator:')
    for i in range(10):
        print(i, int(out_q6[i]), float(out_q6[i]) / 1024.0)

    mism = compare_with_reference(out_q6, ref_csv, nrows=10)
    if not mism:
        print('\nValidation: first 10 entries match reference CSV exactly.')
    else:
        print('\nValidation: mismatches found (index, ref, sim, ref_float):')
        for m in mism:
            print(m)
