# Install RTK (Rust Token Killer) - CLI proxy that cuts 60-90% of bash output
# https://github.com/rtk-ai/rtk

$ErrorActionPreference = "Stop"

Write-Host "Installing RTK..." -ForegroundColor Cyan

# Check if already installed
if (Get-Command rtk -ErrorAction SilentlyContinue) {
    Write-Host "RTK already installed: $(rtk --version)" -ForegroundColor Green
    Write-Host "Updating..." -ForegroundColor Yellow
    if (Get-Command cargo -ErrorAction SilentlyContinue) {
        cargo install --git https://github.com/rtk-ai/rtk
    } elseif (Get-Command winget -ErrorAction SilentlyContinue) {
        winget upgrade rtk-ai.rtk
    }
    exit 0
}

# Try cargo
if (Get-Command cargo -ErrorAction SilentlyContinue) {
    Write-Host "Installing via cargo..." -ForegroundColor Yellow
    cargo install --git https://github.com/rtk-ai/rtk
}
# Try winget
elseif (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Installing via winget..." -ForegroundColor Yellow
    winget install rtk-ai.rtk
}
# Download pre-built binary
else {
    Write-Host "Downloading pre-built binary..." -ForegroundColor Yellow

    $VERSION = (Invoke-RestMethod "https://api.github.com/repos/rtk-ai/rtk/releases/latest").tag_name -replace "^v", ""
    $ZIP = "rtk-x86_64-pc-windows-msvc.zip"
    $URL = "https://github.com/rtk-ai/rtk/releases/latest/download/$ZIP"

    $TMPDIR = Join-Path $env:TEMP "rtk-install"
    New-Item -ItemType Directory -Force -Path $TMPDIR | Out-Null

    Write-Host "  Downloading RTK v$VERSION..."
    Invoke-WebRequest -Uri $URL -OutFile "$TMPDIR\$ZIP"

    Write-Host "  Extracting..."
    Expand-Archive -Path "$TMPDIR\$ZIP" -DestinationPath $TMPDIR -Force

    # Install to ~/.local/bin
    $INSTALL_DIR = "$env:USERPROFILE\.local\bin"
    New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
    Copy-Item "$TMPDIR\rtk.exe" "$INSTALL_DIR\rtk.exe" -Force

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
if (Get-Command rtk -ErrorAction SilentlyContinue) {
    Write-Host "RTK installed: $(rtk --version)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Setup auto-rewrite hook:" -ForegroundColor Cyan
    Write-Host "  rtk init -g                 # Claude Code"
    Write-Host "  rtk init -g --opencode      # OpenCode"
    Write-Host "  rtk init -g --gemini        # Gemini CLI"
    Write-Host "  rtk init -g --agent cursor  # Cursor"
} else {
    Write-Host "Installation may require PATH update. Check ~/.local/bin" -ForegroundColor Yellow
}
