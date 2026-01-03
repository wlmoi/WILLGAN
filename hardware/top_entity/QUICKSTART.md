# Quick Start - Build WGAN Generator FPGA

## ⚠️ PENTING: Jalankan dari PowerShell, BUKAN dari Vivado GUI!

## 🚀 Cara Benar (PowerShell Terminal)

### Option 1: PowerShell Script (Paling Mudah)

```powershell
# 1. Buka PowerShell di VS Code atau Windows Terminal
# 2. Navigate ke folder ini
cd D:\WILLGAN\hardware\top_entity

# 3. Run build script
.\build.ps1 zcu104
```

### Option 2: Langsung Vivado Command

```powershell
# 1. Buka PowerShell
cd D:\WILLGAN\hardware\top_entity

# 2. Run Vivado dengan TCL script
& "C:\AMDDesignTools\2025.2\bin\vivado.exe" -mode batch -source build_project.tcl -tclargs zcu104
```

## ❌ JANGAN Lakukan Ini:

### ❌ Jangan jalankan dari Vivado Tcl Console
```tcl
# INI SALAH - Akan error "no such file or directory"
vivado -mode batch -source build_project.tcl -tclargs zcu104
```

### ❌ Jangan buat project manual di GUI lalu run TCL
```tcl
# INI SALAH - Project conflict
start_gui
create_project top_entity ...
source build_project.tcl
```

## ✅ Jika Project Sudah Ada

TCL script sekarang otomatis cleanup, tapi jika masih error:

```powershell
# Cleanup manual
cd D:\WILLGAN\hardware\top_entity
Remove-Item -Recurse -Force top_entity.cache, top_entity.hw, top_entity.sim, top_entity.ip_user_files, .Xil -ErrorAction SilentlyContinue
Remove-Item -Force top_entity.xpr -ErrorAction SilentlyContinue

# Lalu run build
.\build.ps1 zcu104
```

## 📋 Board Options

```powershell
.\build.ps1 zcu104    # ✅ ZCU104 (Recommended - cukup resource)
.\build.ps1 kria      # ✅ Kria KV260 (OK - cukup resource)
.\build.ps1 pynq_z1   # ⚠️ PYNQ-Z1 (Warning - mungkin tidak cukup)
.\build.ps1 zybo      # ⚠️ Zybo Z7 (Warning - mungkin tidak cukup)
```

## 🔍 Troubleshooting

### Error: "Project already exists"
**Solusi**: Script sekarang sudah auto-cleanup dengan `-force`

### Error: "couldn't read file build_project.tcl"
**Penyebab**: Salah working directory  
**Solusi**: 
```powershell
cd D:\WILLGAN\hardware\top_entity  # PASTIKAN di folder ini!
.\build.ps1 zcu104
```

### Error: "Vivado not found"
**Solusi**: Update path di build.ps1
```powershell
.\build.ps1 zcu104 "C:\Path\To\Your\Vivado\bin\vivado.exe"
```

## 📊 Output Files

Setelah build selesai:
- `top_entity.bit` - Bitstream untuk FPGA
- `utilization_report.txt` - Resource usage
- `timing_summary.txt` - Timing analysis
- `power_report.txt` - Power estimation
- `build_zcu104.log` - Build log

## ⏱️ Build Time

- **Synthesis**: ~10-20 menit
- **Implementation**: ~15-30 menit  
- **Total**: ~30-50 menit (tergantung PC)

## 💡 Tips

1. **Tutup Vivado GUI** sebelum run batch build
2. **Pastikan path** ke vivado.exe benar
3. **Cek log file** jika ada error: `Get-Content build_zcu104.log -Tail 100`
4. **Gunakan board besar** (ZCU104/Kria) untuk hasil optimal

---

**Need Help?** Cek [README.md](README.md) untuk dokumentasi lengkap
