# PowerShell script to build WGAN design for different boards
# Usage: .\build.ps1 [board_name] [vivado_path]
# Boards: pynq_z1, zybo, kria, zcu104

param(
    [string]$Board = "zcu104",
    [string]$VivadoPath = ""
)

# Valid board options
$ValidBoards = @("pynq_z1", "zybo", "kria", "zcu104")

if ($ValidBoards -notcontains $Board) {
    Write-Host "ERROR: Invalid board '$Board'" -ForegroundColor Red
    Write-Host "Valid options: $($ValidBoards -join ', ')" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Usage examples:" -ForegroundColor Cyan
    Write-Host "  .\build.ps1 zcu104                                     # Auto-detect Vivado"
    Write-Host "  .\build.ps1 zcu104 'C:\AMDDesignTools\2025.2\bin\vivado.exe'  # Specify path"
    exit 1
}

# Auto-detect Vivado path if not provided
if ([string]::IsNullOrEmpty($VivadoPath)) {
    Write-Host "Searching for Vivado installation..." -ForegroundColor Cyan
    
    # Common Vivado install paths (in order of preference)
    $CommonPaths = @(
        "C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat",
        "C:\AMDDesignTools\2025.2\bin\vivado.bat",
        "C:\Xilinx\Vivado\2025.2\bin\vivado.bat",
        "C:\AMDDesignTools\2025.1\Vivado\bin\vivado.bat",
        "C:\AMDDesignTools\2024.2\Vivado\bin\vivado.bat",
        "C:\Xilinx\Vivado\2024.2\bin\vivado.bat",
        "C:\Program Files\Xilinx\Vivado\2025.2\bin\vivado.bat",
        "C:\Program Files\AMD\Vivado\2025.2\bin\vivado.bat"
    )
    
    $Found = $false
    foreach ($Path in $CommonPaths) {
        if (Test-Path $Path) {
            $VivadoPath = $Path
            Write-Host "  ✓ Found: $Path" -ForegroundColor Green
            $Found = $true
            break
        }
    }
    
    # If not found in common paths, search C:\ drive (slow but thorough)
    if (-not $Found) {
        Write-Host "  Not found in common paths, searching C:\ drive (this may take a moment)..." -ForegroundColor Yellow
        $VivadoExe = Get-ChildItem -Path "C:\" -Recurse -Filter "vivado.bat" -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($VivadoExe) {
            $VivadoPath = $VivadoExe.FullName
            Write-Host "  ✓ Found: $VivadoPath" -ForegroundColor Green
            $Found = $true
        }
    }
    
    if (-not $Found) {
        Write-Host "ERROR: Vivado not found!" -ForegroundColor Red
        Write-Host ""
        Write-Host "How to find Vivado path:" -ForegroundColor Yellow
        Write-Host "  1. Open Vivado"
        Write-Host "  2. Help → About Vivado"
        Write-Host "  3. Look for 'Installation directory'"
        Write-Host "  4. Copy path to vivado.exe"
        Write-Host ""
        Write-Host "Then run:" -ForegroundColor Cyan
        Write-Host "  .\build.ps1 $Board 'C:\Your\Vivado\Path\bin\vivado.exe'" -ForegroundColor White
        Write-Host ""
        Write-Host "Or manually check these paths:" -ForegroundColor Yellow
        Write-Host "  - C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat"
        Write-Host "  - C:\Xilinx\Vivado\2025.2\bin\vivado.bat"
        Write-Host "  - C:\Program Files\Xilinx\Vivado\2025.2\bin\vivado.bat"
        exit 1
    }
}

# Verify Vivado exists at specified path
if (-not (Test-Path $VivadoPath)) {
    Write-Host "ERROR: Vivado not found at: $VivadoPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check the path and try again:" -ForegroundColor Yellow
        Write-Host "  .\build.ps1 $Board 'C:\Your\Vivado\Path\bin\vivado.bat'" -ForegroundColor Cyan
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WGAN Generator FPGA Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Board: $Board" -ForegroundColor Green
Write-Host "Vivado: $VivadoPath" -ForegroundColor Green
Write-Host ""

# Navigate to project directory
$ProjectDir = "D:\WILLGAN\hardware\top_entity"
Set-Location $ProjectDir

# Clean old files
Write-Host "Cleaning old project files..." -ForegroundColor Yellow
Remove-Item -Recurse -Force "top_entity.cache", "top_entity.hw", "top_entity.sim", "top_entity.ip_user_files", ".Xil", ".runs" -ErrorAction SilentlyContinue
Remove-Item -Force "top_entity.xpr", "top_entity.xpr.backup*" -ErrorAction SilentlyContinue

# Wait untuk pastikan file sudah didelete
Start-Sleep -Milliseconds 1000

Write-Host "Clean complete" -ForegroundColor Green
Write-Host ""

# Build timestamp
$StartTime = Get-Date
Write-Host "Build started at: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
Write-Host ""

# Run Vivado build
Write-Host "Launching Vivado synthesis and implementation..." -ForegroundColor Yellow
Write-Host "Command: vivado -mode batch -source build_project.tcl -tclargs $Board" -ForegroundColor Gray
Write-Host ""

& $VivadoPath -mode batch -source build_project.tcl -tclargs $Board -log "build_${Board}.log" -journal "build_${Board}.jou"

$ExitCode = $LASTEXITCODE
$EndTime = Get-Date
$Duration = $EndTime - $StartTime

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Build Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Board: $Board" -ForegroundColor Green
Write-Host "Duration: $($Duration.ToString('hh\:mm\:ss'))" -ForegroundColor Green

if ($ExitCode -eq 0) {
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host ""
    Write-Host "Output files:" -ForegroundColor Cyan
    if (Test-Path "top_entity.bit") {
        Write-Host "  - Bitstream: top_entity.bit" -ForegroundColor Green
    }
    Write-Host "  - Log file: build_${Board}.log" -ForegroundColor Gray
    Write-Host "  - Journal: build_${Board}.jou" -ForegroundColor Gray
} else {
    Write-Host "Status: FAILED (Exit code: $ExitCode)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check log file for errors:" -ForegroundColor Yellow
    Write-Host "  Get-Content build_${Board}.log -Tail 100" -ForegroundColor Gray
}

Write-Host "========================================" -ForegroundColor Cyan
exit $ExitCode
