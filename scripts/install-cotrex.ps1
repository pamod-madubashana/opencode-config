# Install Cotrex - Deterministic execution orchestration for AI agents
# https://github.com/pamod-madubashana/Cotrex

$ErrorActionPreference = "Stop"

Write-Host "Installing Cotrex..." -ForegroundColor Cyan

# Check if already installed
if (Get-Command cotrex -ErrorAction SilentlyContinue) {
    Write-Host "Cotrex already installed: $(cotrex --version)" -ForegroundColor Green
    exit 0
}

# Try cargo
if (Get-Command cargo -ErrorAction SilentlyContinue) {
    Write-Host "Installing via cargo..." -ForegroundColor Yellow
    cargo install --git https://github.com/pamod-madubashana/Cotrex
}
# Try winget
elseif (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Installing via winget..." -ForegroundColor Yellow
    winget install pamod-madubashana.Cotrex
}
# Download pre-built binary
else {
    Write-Host "Downloading pre-built binary..." -ForegroundColor Yellow

    $VERSION = "3.0.0"
    $ZIP = "cotrex-x86_64-pc-windows-msvc.zip"
    $URL = "https://github.com/pamod-madubashana/Cotrex/releases/latest/download/$ZIP"

    $TMPDIR = Join-Path $env:TEMP "cotrex-install"
    New-Item -ItemType Directory -Force -Path $TMPDIR | Out-Null

    Write-Host "  Downloading Cotrex v$VERSION..."
    try {
        Invoke-WebRequest -Uri $URL -OutFile "$TMPDIR\$ZIP"
    } catch {
        Write-Host "  Download failed. Please download manually from:" -ForegroundColor Red
        Write-Host "  https://github.com/pamod-madubashana/Cotrex/releases"
        exit 1
    }

    Write-Host "  Extracting..."
    Expand-Archive -Path "$TMPDIR\$ZIP" -DestinationPath $TMPDIR -Force

    # Install to ~/.local/bin
    $INSTALL_DIR = "$env:USERPROFILE\.local\bin"
    New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
    Copy-Item "$TMPDIR\cotrex.exe" "$INSTALL_DIR\cotrex.exe" -Force

    # Add to PATH if not already there
    $PATH_DIRS = $env:PATH -split ";"
    if ($PATH_DIRS -notcontains $INSTALL_DIR) {
        $env:PATH = "$INSTALL_DIR;$env:PATH"
        [Environment]::SetEnvironmentVariable("PATH", "$INSTALL_DIR;$env:PATH", "User")
        Write-Host "  Added $INSTALL_DIR to PATH" -ForegroundColor Green
    }

    Remove-Item -Recurse -Force $TMPDIR -ErrorAction SilentlyContinue
}

# Verify
if (Get-Command cotrex -ErrorAction SilentlyContinue) {
    Write-Host "Cotrex installed: $(cotrex --version)" -ForegroundColor Green
    Write-Host ""
    Write-Host "First-time setup:" -ForegroundColor Cyan
    Write-Host "  cotrex init           # auto-download model and configure"
    Write-Host "  cotrex doctor         # check system health"
    Write-Host "  cotrex setup          # configure API provider"
} else {
    Write-Host "Installation may require terminal restart or PATH update." -ForegroundColor Yellow
}
