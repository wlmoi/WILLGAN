# WGAN Generator FPGA Build Guide

## Resource Requirements
Design ini membutuhkan sekitar **30,064 F7 Multiplexers**. Perbandingan board yang tersedia:

| Board | FPGA Device | F7 Muxes | Status |
|-------|-------------|----------|--------|
| **Pynq-Z1** | xc7z020clg400-1 | 26,600 | ❌ Tidak cukup |
| **Zybo Z7-20** | xc7z020clg400-1 | 26,600 | ❌ Tidak cukup |
| **Kria KV260** | xck26-sfvc784-2LV-c | ~106,400 | ✅ **Cukup** |
| **ZCU104** | xczu7ev-ffvc1156-2-e | ~177,500 | ✅ **Cukup** |

**Rekomendasi:** Gunakan **Kria KV260** atau **ZCU104** untuk build yang sukses.

## Cara Build

### Metode 1: Menggunakan PowerShell Script (Recommended)

```powershell
# Navigate ke direktori project
cd D:\WILLGAN\hardware\top_entity

# Build untuk ZCU104 (default, recommended)
.\build.ps1

# Build untuk Kria KV260
.\build.ps1 kria

# Build untuk Pynq-Z1 (WARNING: kemungkinan gagal karena resource)
.\build.ps1 pynq_z1

# Build untuk Zybo Z7 (WARNING: kemungkinan gagal karena resource)
.\build.ps1 zybo

# Jika Vivado di lokasi berbeda
.\build.ps1 zcu104 "C:\Xilinx\Vivado\2025.2\bin\vivado.exe"
```

### Metode 2: Menggunakan Vivado TCL Langsung

```powershell
cd D:\WILLGAN\hardware\top_entity

# Untuk ZCU104
C:\AMDDesignTools\2025.2\bin\vivado.exe -mode batch -source build_project.tcl -tclargs zcu104

# Untuk Kria
C:\AMDDesignTools\2025.2\bin\vivado.exe -mode batch -source build_project.tcl -tclargs kria

# Untuk Pynq-Z1
C:\AMDDesignTools\2025.2\bin\vivado.exe -mode batch -source build_project.tcl -tclargs pynq_z1

# Untuk Zybo
C:\AMDDesignTools\2025.2\bin\vivado.exe -mode batch -source build_project.tcl -tclargs zybo
```

### Metode 3: Clean Build (Hapus semua file lama)

```powershell
# Clean dan build ulang
cd D:\WILLGAN\hardware\top_entity
Remove-Item -Recurse -Force *.runs, *.sim, *.ip_user_files, .Xil, *.xpr -ErrorAction SilentlyContinue
.\build.ps1 zcu104
```

## Output Files

Setelah build sukses:
- **top_entity.bit** - Bitstream file untuk programming FPGA
- **build_[board].log** - Log file dari build process
- **build_[board].jou** - Journal file dari Vivado
- **top_entity.xpr** - Vivado project file

## Monitoring Build Progress

Saat build berjalan, Anda bisa monitor log secara real-time:

```powershell
# Monitor log file
Get-Content build_zcu104.log -Wait -Tail 20

# Atau check status terakhir
Get-Content build_zcu104.log -Tail 50
```

## Troubleshooting

### Error: DRC UTLZ-1 Resource utilization
```
F7 Muxes over-utilized... requires 30064... only 26600 available
```
**Solusi:** Gunakan board dengan resource lebih besar (Kria atau ZCU104)

### Error: Board part not found
```
WARNING: Board part ... not found
```
**Tidak masalah:** Script akan tetap menggunakan part number yang sesuai. Board part hanya untuk constraint tambahan.

### Synthesis Failed
```
Synthesis failed - please see the console or run log file
```
**Solusi:** Check log file untuk error detail:
```powershell
Get-Content build_zcu104.log | Select-String -Pattern "error|ERROR" -Context 3
```

## Optimasi untuk Board Kecil (Experimental)

Jika Anda harus menggunakan Pynq-Z1/Zybo, pertimbangkan:
1. Reduce layer size (misal: 128 neurons instead of 256)
2. Share computation resources dengan lebih agresif
3. Use multiplexing untuk weight memory access
4. Implement sequential processing dengan state machines

Namun ini memerlukan modifikasi significant pada design.

## Build Time Estimate

| Stage | Duration (approx) |
|-------|------------------|
| Synthesis | 15-30 minutes |
| Implementation | 20-40 minutes |
| Bitstream Generation | 2-5 minutes |
| **Total** | **~40-75 minutes** |

Build time tergantung pada:
- Kompleksitas design
- CPU cores available
- Target FPGA size
