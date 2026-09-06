# Install Graphify - Turn codebases into queryable knowledge graphs
# https://github.com/Graphify-Labs/graphify

$ErrorActionPreference = "Stop"

Write-Host "Installing Graphify..." -ForegroundColor Cyan

# Check if already installed
if (Get-Command graphify -ErrorAction SilentlyContinue) {
    Write-Host "Graphify already installed: $(graphify --version)" -ForegroundColor Green
    Write-Host "Updating..." -ForegroundColor Yellow
    if (Get-Command uv -ErrorAction SilentlyContinue) {
        uv tool upgrade graphifyy
    } elseif (Get-Command pipx -ErrorAction SilentlyContinue) {
        pipx upgrade graphifyy
    }
    exit 0
}

# Try uv first (recommended)
if (Get-Command uv -ErrorAction SilentlyContinue) {
    Write-Host "Installing via uv..." -ForegroundColor Yellow
    uv tool install graphifyy
}
# Try pipx
elseif (Get-Command pipx -ErrorAction SilentlyContinue) {
    Write-Host "Installing via pipx..." -ForegroundColor Yellow
    pipx install graphifyy
}
# Try winget
elseif (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Installing via winget..." -ForegroundColor Yellow
    winget install astral-sh.uv
    Write-Host "Installing graphify via uv..." -ForegroundColor Yellow
    uv tool install graphifyy
}
# Try pip as fallback
elseif (Get-Command pip -ErrorAction SilentlyContinue) {
    Write-Host "Installing via pip..." -ForegroundColor Yellow
    pip install graphifyy
} elseif (Get-Command pip3 -ErrorAction SilentlyContinue) {
    Write-Host "Installing via pip3..." -ForegroundColor Yellow
    pip3 install graphifyy
} else {
    Write-Host "No package manager found. Install one of:" -ForegroundColor Red
    Write-Host "  uv:    winget install astral-sh.uv"
    Write-Host "  pip:   python -m ensurepip --upgrade"
    exit 1
}

# Verify
if (Get-Command graphify -ErrorAction SilentlyContinue) {
    Write-Host "Graphify installed: $(graphify --version)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Register skill with your AI assistant:" -ForegroundColor Cyan
    Write-Host "  graphify install                     # Claude Code"
    Write-Host "  graphify install --platform opencode  # OpenCode"
    Write-Host "  graphify install --platform codex     # Codex"
    Write-Host "  graphify install --platform cursor    # Cursor"
    Write-Host ""
    Write-Host "Optional extras:" -ForegroundColor Cyan
    Write-Host "  uv tool install 'graphifyy[gemini]'   # Gemini semantic extraction"
    Write-Host "  uv tool install 'graphifyy[pdf]'      # PDF support"
    Write-Host "  uv tool install 'graphifyy[video]'    # Video/audio transcription"
    Write-Host "  uv tool install 'graphifyy[all]'      # Everything"
} else {
    Write-Host "Installation may require terminal restart or PATH update." -ForegroundColor Yellow
}
