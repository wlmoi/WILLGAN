# PowerShell script to switch between optimized layer3 variants
# Usage: .\switch_layer3.ps1 [version]
# Versions: original, opt, serial

param(
    [ValidateSet("original", "opt", "serial")]
    [string]$Version = "original"
)

$LayersDir = "D:\WILLGAN\hardware\layers"
$SourceFile = "$LayersDir\layer3_generator_v2.v"
$OriginalFile = "$LayersDir\layer3_generator_v2_original.v"
$OptFile = "$LayersDir\layer3_generator_opt.v"
$SerialFile = "$LayersDir\layer3_generator_serial.v"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Layer3 Generator Version Switcher" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if source file exists
if (-not (Test-Path $SourceFile)) {
    Write-Host "ERROR: $SourceFile not found!" -ForegroundColor Red
    exit 1
}

# Backup current version if not already backed up
if (-not (Test-Path $OriginalFile)) {
    Write-Host "Backing up original version..." -ForegroundColor Yellow
    Copy-Item $SourceFile $OriginalFile -Force
    Write-Host "Backup saved to: $OriginalFile" -ForegroundColor Green
}

# Switch version
switch ($Version) {
    "original" {
        Write-Host "Switching to: ORIGINAL (full parallelism, ~30K F7 muxes)" -ForegroundColor Yellow
        if (Test-Path $OriginalFile) {
            Copy-Item $OriginalFile $SourceFile -Force
        } else {
            Write-Host "ERROR: Original backup not found!" -ForegroundColor Red
            exit 1
        }
    }
    "opt" {
        Write-Host "Switching to: OPTIMIZED CHUNKED (16-wide, ~15-18K F7 muxes)" -ForegroundColor Yellow
        if (-not (Test-Path $OptFile)) {
            Write-Host "ERROR: $OptFile not found!" -ForegroundColor Red
            Write-Host "Make sure layer3_generator_opt.v exists" -ForegroundColor Red
            exit 1
        }
        Copy-Item $OptFile $SourceFile -Force
    }
    "serial" {
        Write-Host "Switching to: SERIAL I/O (minimal resource, ~1K F7 muxes)" -ForegroundColor Yellow
        if (-not (Test-Path $SerialFile)) {
            Write-Host "ERROR: $SerialFile not found!" -ForegroundColor Red
            Write-Host "Make sure layer3_generator_serial.v exists" -ForegroundColor Red
            exit 1
        }
        Copy-Item $SerialFile $SourceFile -Force
        Write-Host "WARNING: Serial version requires interface adapter!" -ForegroundColor Red
        Write-Host "You'll need to modify top_entity.v to handle serial I/O" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Version switched successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Modified file: $SourceFile" -ForegroundColor Cyan
Write-Host "Current version: $Version" -ForegroundColor Cyan
Write-Host ""

# Show information
switch ($Version) {
    "original" {
        Write-Host "Specifications:" -ForegroundColor Gray
        Write-Host "  F7 Muxes: ~30,064" -ForegroundColor Gray
        Write-Host "  Latency: ~1,000 cycles" -ForegroundColor Gray
        Write-Host "  Works on: Kria, ZCU104 only" -ForegroundColor Gray
    }
    "opt" {
        Write-Host "Specifications:" -ForegroundColor Gray
        Write-Host "  F7 Muxes: ~15-18,000 (50% reduction)" -ForegroundColor Gray
        Write-Host "  Latency: ~12,500 cycles" -ForegroundColor Gray
        Write-Host "  Should work on: Pynq-Z1 (with margin)" -ForegroundColor Gray
        Write-Host "  Performance: 12x slower than original" -ForegroundColor Gray
    }
    "serial" {
        Write-Host "Specifications:" -ForegroundColor Gray
        Write-Host "  F7 Muxes: ~500-1,000 (97% reduction!)" -ForegroundColor Gray
        Write-Host "  Latency: ~200,704 cycles (~2 ms @ 100MHz)" -ForegroundColor Gray
        Write-Host "  Works on: Any board" -ForegroundColor Gray
        Write-Host "  WARNING: Requires significant interface changes" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Clean old build: Remove-Item -Recurse *.runs, .Xil, *.xpr -Force -EA SI" -ForegroundColor Gray
Write-Host "  2. Run synthesis: .\build.ps1 pynq_z1" -ForegroundColor Gray
Write-Host "  3. Check F7 mux count in build_pynq_z1.log" -ForegroundColor Gray
Write-Host ""

exit 0
