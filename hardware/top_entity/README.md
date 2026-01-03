# WGAN Generator - FPGA Build Files

## 📁 Struktur Folder

```
top_entity/
├── build_project.tcl       # TCL script untuk Vivado synthesis
├── build.ps1               # PowerShell wrapper untuk build
├── top_entity.xdc          # ⭐ FILE CONSTRAINT PENTING
├── BUILD_GUIDE.md          # Panduan build detail
├── OPTIMIZATION_GUIDE.md   # Tips optimisasi
├── QUICKSTART.md           # ⭐ Quick start guide (Iverilog + Vivado)
└── README.md               # File ini
```

## 🎯 Dua Mode Operasi

### 1. 🔬 Simulation Mode (Iverilog) - FAST Testing
- **Purpose**: Functional verification, debugging
- **Time**: ~10 seconds
- **Tool**: Icarus Verilog
- **Output**: Waveform (VCD), timing statistics

### 2. 🏭 Synthesis Mode (Vivado) - FPGA Deployment  
- **Purpose**: FPGA bitstream generation
- **Time**: ~30-50 minutes
- **Tool**: Xilinx Vivado
- **Output**: Bitstream (.bit), reports

---

## 🔬 Simulation dengan Iverilog

### Quick Start:

```powershell
cd D:\WILLGAN\hardware
iverilog -g2012 -o tb_top_entity.vvp -I layers tb_top_entity.v
vvp tb_top_entity.vvp
```

### Hasil Expected:

```
=========================================
   Top Entity Testbench
=========================================
Testing serial interface to generator

Timing Summary:
  Input cycles:      64
  Generation cycles: 109610
  Output cycles:     783
  Total cycles:      110457

Output Statistics:
  Min:  -547 (-0.5342)
  Max:  -95 (-0.0928)

First row of 28x28 output:
   -429  -463  -381  -307  -436  -352  -362  -398  ...
=========================================
```

**Performance**: 110,457 cycles = ~1.1ms @ 100MHz = ~909 images/sec

---

## 🏭 Synthesis dengan Vivado

### Quick Start:

```powershell
cd D:\WILLGAN\hardware\top_entity
.\build.ps1 zcu104
```

### Board Options:

| Board | Part | Resource Status |
|-------|------|-----------------|
| **zcu104** | xczu7ev-ffvc1156-2-e | ✅ Recommended |
| **kria** | xck26-sfvc784-2LV-c | ✅ OK |
| **pynq_z1** | xc7z020clg400-1 | ⚠️ May not fit |
| **zybo** | xc7z020clg400-1 | ⚠️ May not fit |

---

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

---

## 📊 Design Summary

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

---

## 📋 Output Files

### After Iverilog Simulation:
```
tb_top_entity.vvp       # Compiled simulation
tb_top_entity.vcd       # Waveform (open with GTKWave)
```

### After Vivado Build:
```
build_XXXXX/            # Unique build directory
├── wgan_build.xpr      # Vivado project
└── wgan_build.runs/    # Build outputs

top_entity.bit          # ⭐ Bitstream for FPGA
utilization_report.txt  # Resource usage
timing_summary.txt      # Timing analysis
power_report.txt        # Power estimation
build_zcu104.log        # Build log
```

---

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

---

## 🐛 Troubleshooting

### Iverilog Issues:

**Error: Unknown module type: generator**
```powershell
# Solusi: Compile dari hardware directory dengan -I flag
cd D:\WILLGAN\hardware
iverilog -g2012 -o tb_top_entity.vvp -I layers tb_top_entity.v
```

**Error: module already declared**
```powershell
# Solusi: Jangan compile layer files manual - let includes handle it
iverilog -g2012 -o tb_top_entity.vvp -I layers tb_top_entity.v
# JANGAN: iverilog ... layer1.v layer2.v layer3.v ...
```

### Vivado Issues:

**Error: Constraint file not found**
```
✗ ERROR: Constraint file not found: D:/WILLGAN/hardware/top_entity/top_entity.xdc
```
**Solusi**: Pastikan file `top_entity.xdc` ada di folder ini!

**Error: Resource over-utilization**
```
ERROR: [Place 30-494] The design requires more F7 Muxes than available
```
**Solusi**: Gunakan board yang lebih besar (ZCU104 atau Kria)

**Warning: Timing not met**
```
WARNING: [Timing 38-282] Setup slack -0.5ns
```
**Solusi**: Turunkan clock frequency atau enable aggressive optimization

**Error: Variable too large**
```
ERROR: [Synth 8-4556] size of variable 'weights' is too large
```
**Status**: ⚠️ Known issue - Layer3 weights (3.2MB) melebihi limit Vivado (1MB)
**Workaround**: Perlu split weights atau gunakan external memory

---

## 📚 Referensi

- [QUICKSTART.md](QUICKSTART.md) - ⭐ Start here! Simulation + Synthesis guide
- [BUILD_GUIDE.md](BUILD_GUIDE.md) - Panduan build lengkap
- [OPTIMIZATION_GUIDE.md](OPTIMIZATION_GUIDE.md) - Tips optimisasi
- [Vivado Design Suite User Guide](https://www.xilinx.com/support/documentation/)

---

## 📝 Notes

- **PENTING**: File `top_entity.xdc` HARUS ada sebelum run build!
- **Iverilog**: Fast testing (~10 sec), gunakan untuk debug functional
- **Vivado**: Slow synthesis (~30-50 min), gunakan untuk FPGA deployment
- Design ini membutuhkan BRAM untuk weight/bias storage
- Pastikan clock constraint sesuai dengan board
- Untuk production, tambahkan CDC constraint jika ada multiple clock domain

---

## 🎯 Status Saat Ini

| Component | Status |
|-----------|--------|
| Iverilog Simulation | ✅ **WORKING** |
| Testbench | ✅ Validated (110,457 cycles) |
| Top Entity RTL | ✅ Complete |
| Generator Pipeline | ✅ Functional |
| Vivado Build System | ✅ Scripts ready |
| Vivado Synthesis | ⚠️ Weight memory issue |
| Constraint File | ✅ Complete (PYNQ-Z1) |
| Documentation | ✅ Complete |

---

**Last Updated**: January 3, 2026  
**Design**: WGAN Generator with serial I/O interface  
**Target**: Xilinx Zynq/UltraScale+ FPGAs  
**Performance**: 110,457 cycles/image (~1.1ms @ 100MHz)
