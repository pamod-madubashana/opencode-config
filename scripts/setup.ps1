# Master setup script for OpenCode tools (Windows PowerShell)
# Installs: RTK, Graphify, Cotrex
# Usage: .\setup.ps1 [-RTK] [-Graphify] [-Cotrex] [-All]

param(
    [switch]$RTK,
    [switch]$Graphify,
    [switch]$Cotrex,
    [switch]$All
)

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$TOOLS = @()

# Parse arguments
if ($All -or (-not $RTK -and -not $Graphify -and -not $Cotrex)) {
    $TOOLS = @("rtk", "graphify", "cotrex")
} else {
    if ($RTK)      { $TOOLS += "rtk" }
    if ($Graphify) { $TOOLS += "graphify" }
    if ($Cotrex)   { $TOOLS += "cotrex" }
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  OpenCode Tools Setup (Windows)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($tool in $TOOLS) {
    Write-Host "--- Installing $tool ---" -ForegroundColor Yellow
    switch ($tool) {
        "rtk" {
            if (Get-Command rtk -ErrorAction SilentlyContinue) {
                Write-Host "RTK already installed: $(rtk --version)" -ForegroundColor Green
            } else {
                & "$SCRIPT_DIR\install-rtk.ps1"
            }
        }
        "graphify" {
            if (Get-Command graphify -ErrorAction SilentlyContinue) {
                Write-Host "Graphify already installed: $(graphify --version)" -ForegroundColor Green
            } else {
                & "$SCRIPT_DIR\install-graphify.ps1"
            }
        }
        "cotrex" {
            if (Get-Command cotrex -ErrorAction SilentlyContinue) {
                Write-Host "Cotrex already installed: $(cotrex --version)" -ForegroundColor Green
            } else {
                & "$SCRIPT_DIR\install-cotrex.ps1"
            }
        }
    }
    Write-Host ""
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Setup complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installed tools:" -ForegroundColor Cyan
if (Get-Command rtk -ErrorAction SilentlyContinue) {
    Write-Host "  rtk:      $(rtk --version)" -ForegroundColor Green
}
if (Get-Command graphify -ErrorAction SilentlyContinue) {
    Write-Host "  graphify: $(graphify --version)" -ForegroundColor Green
}
if (Get-Command cotrex -ErrorAction SilentlyContinue) {
    Write-Host "  cotrex:   $(cotrex --version)" -ForegroundColor Green
}
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. RTK:      rtk init -g --opencode    (enable auto-rewrite hook)"
Write-Host "  2. Graphify: graphify install           (register skill with AI assistant)"
Write-Host "  3. Cotrex:   cotrex init                (download model and configure)"
