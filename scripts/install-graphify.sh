#!/bin/bash
# Install Graphify - Turn codebases into queryable knowledge graphs
# https://github.com/Graphify-Labs/graphify

set -e

echo "Installing Graphify..."

if command -v graphify &>/dev/null; then
    echo "Graphify already installed: $(graphify --version)"
    echo "Updating..."
    if command -v uv &>/dev/null; then
        uv tool upgrade graphifyy
    elif command -v pipx &>/dev/null; then
        pipx upgrade graphifyy
    fi
    exit 0
fi

# Try uv first (recommended)
if command -v uv &>/dev/null; then
    echo "Installing via uv..."
    uv tool install graphifyy
# Try pipx
elif command -v pipx &>/dev/null; then
    echo "Installing via pipx..."
    pipx install graphifyy
# Try pip as fallback
elif command -v pip3 &>/dev/null; then
    echo "Installing via pip..."
    pip3 install graphifyy
elif command -v pip &>/dev/null; then
    echo "Installing via pip..."
    pip install graphifyy
else
    echo "No package manager found. Install one of:"
    echo "  uv:    curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo "  pipx:  pip install pipx"
    exit 1
fi

# Verify
if command -v graphify &>/dev/null; then
    echo "Graphify installed: $(graphify --version)"
    echo ""
    echo "Register skill with your AI assistant:"
    echo "  graphify install               # Claude Code"
    echo "  graphify install --platform opencode  # OpenCode"
    echo "  graphify install --platform codex     # Codex"
    echo "  graphify install --platform cursor    # Cursor"
    echo ""
    echo "Optional extras:"
    echo "  uv tool install 'graphifyy[gemini]'   # Gemini semantic extraction"
    echo "  uv tool install 'graphifyy[pdf]'      # PDF support"
    echo "  uv tool install 'graphifyy[video]'    # Video/audio transcription"
    echo "  uv tool install 'graphifyy[all]'      # Everything"
else
    echo "Installation may require PATH update."
    echo "  uv: run 'uv tool update-shell'"
    echo "  pipx: run 'pipx ensurepath'"
fi
