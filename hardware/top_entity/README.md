# WGAN Generator - FPGA Build Files

## 📁 Struktur Folder

```
top_entity/
├── build_project.tcl       # TCL script untuk Vivado synthesis
├── build.ps1               # PowerShell wrapper untuk build
├── top_entity.xdc          # ⭐ FILE CONSTRAINT PENTING
├── BUILD_GUIDE.md          # Panduan build detail
├── OPTIMIZATION_GUIDE.md   # Tips optimisasi
└── README.md               # File ini
```

## 🔧 File Constraint (XDC)

**File**: `top_entity.xdc`

File ini berisi semua pin assignment dan timing constraints untuk FPGA:

### Pin Mapping (PYNQ-Z1):
- **Clock**: H16 (125 MHz)
- **Reset**: D19 (Button 0, active low)
- **Start**: D20 (Button 1)
- **Data Input**: Y18-W19 (Pmod JA, 8 pins untuk 16-bit serial)
- **Data Output**: W14-W13 (Pmod JB, 8 pins untuk 16-bit serial)
- **Status LEDs**:
  - LED 0: valid signal
  - LED 1: busy signal
  - LED 2-3: FSM state bits

### Timing Constraints:
```tcl
# Input delay: 0-3ns
set_input_delay -clock [get_clocks sys_clk_pin] -max 3.000 [get_ports {...}]

# Output delay: 0.5-3ns
set_output_delay -clock [get_clocks sys_clk_pin] -max 3.000 [get_ports {...}]
```

## 🚀 Cara Menggunakan

### Metode 1: PowerShell Script (Recommended)

```powershell
# Build untuk ZCU104 (punya resource cukup)
.\build.ps1 zcu104

# Build untuk Kria KV260 (punya resource cukup)
.\build.ps1 kria

# Build untuk PYNQ-Z1 (WARNING: mungkin tidak cukup resource!)
.\build.ps1 pynq_z1
```

### Metode 2: Langsung dengan Vivado

```bash
vivado -mode batch -source build_project.tcl -tclargs zcu104
```

### Metode 3: GUI Vivado

1. Buka Vivado GUI
2. Tools → Run Tcl Script
3. Pilih `build_project.tcl`
4. Masukkan board name saat diminta (zcu104/kria/pynq_z1)

## 📋 Board Options

| Board | Part Number | Status |
|-------|-------------|--------|
| **zcu104** | xczu7ev-ffvc1156-2-e | ✅ Recommended (cukup resource) |
| **kria** | xck26-sfvc784-2LV-c | ✅ OK (cukup resource) |
| **pynq_z1** | xc7z020clg400-1 | ⚠️ Warning (26.6K F7, butuh ~30K) |
| **zybo** | xc7z020clg400-1 | ⚠️ Warning (26.6K F7, butuh ~30K) |

## 📊 Output Files

Setelah build berhasil:

```
top_entity/
├── top_entity.bit              # Bitstream untuk FPGA
├── utilization_report.txt      # Laporan penggunaan resource
├── timing_summary.txt          # Laporan timing analysis
├── power_report.txt            # Estimasi konsumsi daya
└── build_[board].log           # Log file build
```

## 🔍 Design Summary

**Generator Architecture**:
- **Layer 1**: 64 → 256 neurons (16,649 cycles)
- **ReLU 1**: 257 cycles
- **Layer 2**: 256 → 256 neurons (65,794 cycles)
- **ReLU 2**: 257 cycles
- **Layer 3**: 256 → 784 neurons (26,656 cycles)
- **Total**: 109,608 cycles (~1.1ms @ 100MHz)

**Top Entity Interface**:
- Input: 64 noise samples × 16-bit (serial, 64 cycles)
- Generation: 109,610 cycles
- Output: 784 pixels × 16-bit (serial, 783 cycles)
- **Total**: 110,457 cycles per image

**Clock**: 100 MHz target (8ns period)

## ⚙️ Modifikasi XDC

Untuk board lain, edit `top_entity.xdc`:

1. **Ubah PACKAGE_PIN** sesuai pinout board
2. **Sesuaikan IOSTANDARD** (LVCMOS33/LVCMOS25/dll)
3. **Update clock period** jika beda dari 125MHz

Contoh untuk clock 100MHz:
```tcl
set_property -dict { PACKAGE_PIN xxx IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }]
```

## 🐛 Troubleshooting

### Error: Constraint file not found
```
✗ ERROR: Constraint file not found: D:/WILLGAN/hardware/top_entity/top_entity.xdc
```
**Solusi**: Pastikan file `top_entity.xdc` ada di folder ini!

### Error: Resource over-utilization
```
ERROR: [Place 30-494] The design requires more F7 Muxes than available
```
**Solusi**: Gunakan board yang lebih besar (ZCU104 atau Kria)

### Warning: Timing not met
```
WARNING: [Timing 38-282] Setup slack -0.5ns
```
**Solusi**: Turunkan clock frequency atau enable aggressive optimization

## 📚 Referensi

- [BUILD_GUIDE.md](BUILD_GUIDE.md) - Panduan build lengkap
- [OPTIMIZATION_GUIDE.md](OPTIMIZATION_GUIDE.md) - Tips optimisasi
- [Vivado Design Suite User Guide](https://www.xilinx.com/support/documentation/)

## 📝 Notes

- **PENTING**: File `top_entity.xdc` HARUS ada sebelum run build!
- Design ini membutuhkan BRAM untuk weight/bias storage
- Pastikan clock constraint sesuai dengan board
- Untuk production, tambahkan CDC constraint jika ada multiple clock domain

---

**Last Updated**: January 2026  
**Design**: WGAN Generator with serial I/O interface  
**Target**: Xilinx Zynq/UltraScale+ FPGAs
