# Quick Start - Build WGAN Generator FPGA

## ⚠️ PENTING: Ada 2 Cara - Simulation (Iverilog) dan Synthesis (Vivado)

---

## 🔬 Option 1: Simulation dengan Iverilog (RECOMMENDED untuk Testing)

### Konfigurasi:
- **Tool**: Icarus Verilog (iverilog)
- **Working Directory**: `D:\WILLGAN\hardware`
- **Testbench**: `tb_top_entity.v`
- **Top Module**: `top_entity.v` (with `generator.v`)

### Cara Run Simulation:

```powershell
# Navigate ke hardware directory
cd D:\WILLGAN\hardware

# Compile testbench (include semua dependencies via header)
iverilog -g2012 -o tb_top_entity.vvp -I layers tb_top_entity.v

# Run simulation
vvp tb_top_entity.vvp
```

### Expected Output:

```
=========================================
   Top Entity Testbench
=========================================
Testing serial interface to generator

Generating 64 random noise samples...
Starting generation at t=150000

[t=160000] State 1: INPUT_LOAD started
  Sending noise[0] = 0124 (0.285)
  Sending noise[1] = fe81 (-0.374)
  ... (64 noise samples) ...
[t=800000] Input loading complete (64 cycles)

[t=800000] State 2: GENERATE started
[Generator] Starting pipeline at t=805000
[Generator] Layer1 complete at t=167225000
[Generator] ReLU1 complete at t=169795000
[Generator] Layer2 complete at t=827735000
[Generator] ReLU2 complete at t=830305000
[Generator] Layer3 complete at t=1096885000
[t=1096900000] Generation complete (109610 cycles)

[t=1096900000] State 3: OUTPUT_READ started
  Received pixel[0] = fe53 (-0.4189)
  Received pixel[1] = fe31 (-0.4521)
  ... (784 pixels total) ...
[t=1104740000] Output reading complete (783 cycles)

=========================================
   Test Complete
=========================================
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

### Performance:
- **Total Cycles**: 110,457 cycles
- **Latency**: ~1.1 ms @ 100MHz clock
- **Throughput**: ~909 images/second

### Output Files:
- `tb_top_entity.vvp` - Compiled simulation binary
- `tb_top_entity.vcd` - Waveform file (open with GTKWave)

---

## 🏭 Option 2: Synthesis dengan Vivado (untuk FPGA Deployment)

### Konfigurasi:
- **Tool**: Xilinx Vivado 2025.2
- **Working Directory**: `D:\WILLGAN\hardware\top_entity`
- **Build Script**: `build.ps1` atau `build_project.tcl`
- **Board Options**: 
  - **zcu104** ✅ Recommended (cukup resource)
  - **kria** ✅ OK (cukup resource)
  - **pynq_z1** ⚠️ Warning (mungkin tidak cukup)
  - **zybo** ⚠️ Warning (mungkin tidak cukup)

### Cara Run Vivado Build:

#### Method 1: PowerShell Script (RECOMMENDED)

```powershell
# Navigate ke top_entity directory
cd D:\WILLGAN\hardware\top_entity

# Run build untuk ZCU104 (recommended)
.\build.ps1 zcu104

# Atau untuk board lain:
.\build.ps1 kria
.\build.ps1 pynq_z1
```

#### Method 2: Direct Vivado Command

```powershell
cd D:\WILLGAN\hardware\top_entity

# Jalankan Vivado dengan TCL script
& "C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat" -mode batch -source build_project.tcl -tclargs zcu104
```

#### Method 3: Vivado GUI

1. Open Vivado GUI
2. Tools → Run Tcl Script
3. Select `build_project.tcl`
4. Enter board name: `zcu104`

### Expected Build Process:

```
========================================
WGAN Generator FPGA Build Script
========================================
Board: zcu104
Vivado: C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat

Cleaning old project files...
Clean complete

Build started at: 2026-01-03 22:34:21

Using ZCU104 - sufficient resources (RECOMMENDED)
Board: zcu104
Part: xczu7ev-ffvc1156-2-e

Project: D:/WILLGAN/hardware/top_entity/build_XXXXX
Sources: D:/WILLGAN/hardware
Constraints: D:/WILLGAN/hardware/top_entity/top_entity.xdc

Setting up project...
  Creating project in fresh directory...
  Board part: xilinx.com:zcu104:part0:1.1

Adding source files...
  Source files added
Adding constraint file...
  Constraint file added

Setting top module to: top_entity

========================================
Starting Synthesis...
========================================

Starting synth_design
Attempting to get a license for feature 'Synthesis'
INFO: Got license for feature 'Synthesis'
INFO: Loading part xczu7ev-ffvc1156-2-e
INFO: Multithreading enabled for synth_design

Starting RTL Elaboration...
```

### Build Time:
- **Synthesis**: ~10-20 minutes
- **Implementation**: ~15-30 minutes
- **Total**: ~30-50 minutes (depending on PC)

### Output Files:
- `build_XXXXX/wgan_build.xpr` - Vivado project file
- `top_entity.bit` - Bitstream for FPGA programming
- `utilization_report.txt` - Resource usage report
- `timing_summary.txt` - Timing analysis
- `power_report.txt` - Power estimation
- `build_zcu104.log` - Build log file

### Known Issues:

⚠️ **Current Limitation**: 
```
ERROR: [Synth 8-4556] size of variable 'weights' is too large to handle; 
the size is 3211264, the limit is 1000000
```

**Penyebab**: Layer3 memiliki 784×256 = 200,704 weights (32-bit each), total ~3.2MB - melebihi limit Vivado untuk single memory variable.

**Solusi yang Perlu Diimplementasi**:
1. Split weights menjadi multiple BRAM blocks
2. Use external memory interface
3. Implement weight streaming from DRAM

---

## 📊 Design Summary

### Architecture:
```
Noise Input (64 samples, 16-bit each, serial)
    ↓
[INPUT_LOAD State] - 64 cycles
    ↓
Generator Pipeline:
  - Layer1: 64 → 256 neurons (16,649 cycles)
  - ReLU1: 257 cycles  
  - Layer2: 256 → 256 neurons (65,794 cycles)
  - ReLU2: 257 cycles
  - Layer3: 256 → 784 neurons (26,656 cycles)
[GENERATE State] - 109,610 cycles total
    ↓
[OUTPUT_READ State] - 783 cycles (serial output)
    ↓
Image Output (784 pixels, 16-bit Q5.10, 28×28 image)
```

### Performance Metrics:
| Metric | Value |
|--------|-------|
| Input Cycles | 64 |
| Generation Cycles | 109,610 |
| Output Cycles | 783 |
| **Total Cycles** | **110,457** |
| Latency @ 100MHz | ~1.1 ms |
| Throughput | ~909 images/sec |

### Interface Pins (PYNQ-Z1):
- **Clock**: H16 (125 MHz input, 100 MHz internal)
- **Reset**: D19 (Button 0, active low)
- **Start**: D20 (Button 1)
- **Data Input [7:0]**: Y18-W19 (Pmod JA, lower 8 bits of 16-bit serial)
- **Data Output [7:0]**: W14-W13 (Pmod JB, lower 8 bits of 16-bit serial)
- **Status LEDs**: R14 (valid), P14 (busy), N16/M14/N15 (state bits)

---

## 🐛 Troubleshooting

### Iverilog Simulation Issues:

**Error**: `Unknown module type: generator`
```powershell
# Pastikan compile dari hardware directory dengan -I layers flag
cd D:\WILLGAN\hardware
iverilog -g2012 -o tb_top_entity.vvp -I layers tb_top_entity.v
```

**Error**: `module XXX already declared`
```powershell
# Jangan compile layer files secara manual - biarkan include handle it
# WRONG: iverilog ... layer1.v layer2.v layer3.v ...
# RIGHT: iverilog -I layers tb_top_entity.v
```

### Vivado Build Issues:

**Error**: `Project already exists`
```powershell
# Script sekarang otomatis membuat unique directory
# Jika masih error, manual cleanup:
cd D:\WILLGAN\hardware\top_entity
Remove-Item -Recurse -Force build_* -ErrorAction SilentlyContinue
```

**Error**: `run named 'synth_1' already exists`
```powershell
# Build script sudah handle ini - gunakan unique project directory
# Jika masih terjadi, hapus manual:
Remove-Item -Recurse -Force .runs -ErrorAction SilentlyContinue
.\build.ps1 zcu104
```

---

## 📝 Notes

- **Simulation (Iverilog)**: Fast, untuk testing functional correctness
- **Synthesis (Vivado)**: Slow, untuk FPGA deployment dan timing analysis
- **Weight Memory Issue**: Perlu solusi untuk handle 3.2MB weights di Vivado
- **Waveform Analysis**: Open `tb_top_entity.vcd` dengan GTKWave untuk debug

---

**Last Updated**: Jan 3, 2026  
**Status**: ✅ Iverilog simulation WORKING | ⚠️ Vivado synthesis needs weight memory fix
