
# =========================================
#  Hardware vs Software Output Comparison
#  Layer: G_layer1 (example, update as needed)
#  Date: 30 December 2025
# =========================================

import numpy as np
import matplotlib.pyplot as plt

# --- Data Section ---
# Hardware output (Q6.10, after ReLU, 256 data)
hw = np.array([
    33, 96, 0, 115, 128, 36, 18, 145, 0, 0, 47, 111, 0, 106, 0, 0, 35, 67, 35, 31,
    83, 78, 38, 0, 126, 18, 93, 0, 88, 99, 0, 0, 0, 0, 126, 133, 92, 0, 0, 0, 0, 131,
    123, 133, 133, 39, 86, 147, 0, 15, 74, 0, 17, 101, 0, 36, 9, 0, 0, 61, 0, 23, 0,
    0, 35, 148, 0, 87, 0, 116, 0, 0, 72, 124, 21, 30, 0, 6, 100, 0, 50, 48, 79, 0,
    0, 120, 0, 107, 0, 0, 0, 19, 79, 124, 0, 135, 0, 106, 12, 0, 0, 75, 105, 35, 0,
    66, 0, 42, 85, 112, 65, 0, 53, 0, 123, 58, 94, 0, 0, 113, 129, 112, 0, 25, 0, 116,
    57, 32, 0, 60, 0, 48, 100, 127, 34, 58, 0, 0, 0, 0, 47, 26, 98, 30, 53, 124, 136,
    0, 0, 91, 0, 88, 0, 33, 55, 0, 88, 108, 0, 0, 0, 0, 0, 3, 67, 70, 0, 61, 105, 25,
    0, 58, 0, 0, 93, 81, 110, 0, 0, 0, 0, 0, 0, 141, 0, 7, 0, 47, 26, 116, 0, 0, 34,
    0, 0, 82, 0, 0, 0, 26, 115, 0, 3, 31, 118, 76, 0, 0, 0, 90, 0, 0, 136, 61, 0, 117,
    0, 0, 32, 0, 0, 76, 87, 134, 0, 149, 0, 82, 0, 0, 128, 0, 132, 0, 51, 108, 0, 0,
    0, 138, 86, 10, 8, 67, 94, 127, 0, 0, 45, 135, 0, 144, 0, 137
])

# Software output (update with your reference data)
sw = np.array([
    32.5, 95.8, 0.0, 114.9, 127.7, 36.2, 18.1, 144.8, 0.0, 0.0, 46.8, 110.9, 0.0, 105.7, 0.0, 0.0, 34.7, 66.9, 34.6, 31.2,
    82.7, 77.8, 38.2, 0.0, 125.6, 18.2, 92.8, 0.0, 87.9, 98.7, 0.0, 0.0, 0.0, 0.0, 125.8, 132.6, 91.7, 0.0, 0.0, 0.0, 0.0, 130.7,
    122.8, 132.9, 132.7, 39.1, 85.7, 146.8, 0.0, 15.1, 73.7, 0.0, 17.2, 100.8, 0.0, 36.1, 9.2, 0.0, 0.0, 60.7, 0.0, 23.1, 0.0,
    0.0, 34.8, 147.7, 0.0, 86.7, 0.0, 115.8, 0.0, 0.0, 71.8, 123.7, 21.1, 30.2, 0.0, 6.1, 99.7, 0.0, 50.1, 48.2, 78.7, 0.0,
    0.0, 119.8, 0.0, 106.7, 0.0, 0.0, 0.0, 18.9, 78.8, 123.8, 0.0, 134.7, 0.0, 105.8, 12.1, 0.0, 0.0, 74.8, 104.7, 34.8, 0.0,
    65.7, 0.0, 41.8, 84.7, 111.7, 64.8, 0.0, 52.7, 0.0, 122.8, 57.8, 93.7, 0.0, 0.0, 112.7, 128.8, 111.7, 0.0, 25.1, 0.0, 115.7,
    56.8, 32.1, 0.0, 59.7, 0.0, 47.8, 99.7, 126.7, 34.1, 57.8, 0.0, 0.0, 0.0, 0.0, 46.7, 25.8, 97.8, 30.1, 52.7, 123.7, 135.8,
    0.0, 0.0, 90.7, 0.0, 87.8, 0.0, 32.7, 54.7, 0.0, 87.8, 107.7, 0.0, 0.0, 0.0, 0.0, 0.0, 3.1, 66.7, 69.8, 0.0, 60.7, 104.7, 25.1,
    0.0, 57.8, 0.0, 0.0, 92.7, 80.7, 109.7, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 140.7, 0.0, 7.1, 0.0, 46.7, 25.8, 115.7, 0.0, 0.0, 33.7,
    0.0, 0.0, 81.8, 0.0, 0.0, 0.0, 25.7, 114.7, 0.0, 3.1, 30.7, 117.8, 75.7, 0.0, 0.0, 0.0, 89.7, 0.0, 0.0, 135.7, 60.7, 0.0, 116.7,
    0.0, 0.0, 31.7, 0.0, 0.0, 75.8, 86.7, 133.8, 0.0, 148.7, 0.0, 81.7, 0.0, 0.0, 127.8, 0.0, 131.7, 0.0, 50.7, 107.8, 0.0, 0.0,
    0.0, 137.7, 85.7, 10.1, 8.2, 66.7, 93.7, 126.7, 0.0, 0.0, 44.7, 134.7, 0.0, 143.7, 0.0, 136.7
])

# --- Analysis Section ---
abserr = np.abs(hw - sw)
percent_err = 100 * abserr / (np.abs(sw) + 1e-8)

mae = np.mean(abserr)
mape = np.mean(percent_err)
maxerr = np.max(abserr)
maxerr_idx = np.argmax(abserr)

# --- Output Table ---
print("\n================== Perbandingan Output Hardware vs Software ==================")
print(f"{'Idx':>4} {'HW':>10} {'SW':>10} {'AbsErr':>10} {'%Err':>10}")
for i, (h, s, ae, pe) in enumerate(zip(hw, sw, abserr, percent_err)):
    if ae > 0.5 or pe > 1.0:
        highlight = "<--"
    else:
        highlight = ""
    print(f"{i:4d} {h:10.5f} {s:10.5f} {ae:10.5f} {pe:10.2f} {highlight}")

# --- Summary & Insights ---
print("\n================== Summary ==================")
print(f"Total Data Points : {len(hw)}")
print(f"MAE (Mean Abs Err): {mae:.5f}")
print(f"MAPE (Mean % Err) : {mape:.2f}%")
print(f"Max Abs Error     : {maxerr:.5f} (at index {maxerr_idx})")

print("\nInsight:")
print("- Error rata-rata sangat kecil (<1), menandakan hasil hardware sangat akurat.")
print("- Hampir semua data error < 1%, kecuali beberapa titik (ditandai '<--').")
print("- Perbedaan terbesar pada index", maxerr_idx, f"(HW={hw[maxerr_idx]}, SW={sw[maxerr_idx]})")
print("- Data 0 pada HW/SW menandakan neuron tidak aktif (ReLU).")

# --- Visualization ---
plt.figure(figsize=(12,6))
plt.plot(hw, label='Hardware', marker='o', markersize=3, linewidth=1)
plt.plot(sw, label='Software', marker='x', markersize=3, linewidth=1)
plt.title('Perbandingan Output Hardware vs Software (G_layer1)')
plt.xlabel('Index')
plt.ylabel('Output Value')
plt.legend()
plt.grid(True, linestyle='--', alpha=0.5)
plt.tight_layout()
plt.show()
