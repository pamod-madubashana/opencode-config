#!/bin/bash
# Install RTK (Rust Token Killer) - CLI proxy that cuts 60-90% of bash output
# https://github.com/rtk-ai/rtk

set -e

echo "Installing RTK..."

if command -v rtk &>/dev/null; then
    echo "RTK already installed: $(rtk --version)"
    echo "Updating..."
    if command -v brew &>/dev/null; then
        brew upgrade rtk
    elif command -v cargo &>/dev/null; then
        cargo install --git https://github.com/rtk-ai/rtk
    fi
    exit 0
fi

# Try Homebrew first (macOS/Linux)
if command -v brew &>/dev/null; then
    echo "Installing via Homebrew..."
    brew install rtk
# Try cargo
elif command -v cargo &>/dev/null; then
    echo "Installing via cargo..."
    cargo install --git https://github.com/rtk-ai/rtk
# Try quick install script (Linux/macOS)
elif [[ "$OSTYPE" != "msys"* ]] && [[ "$OSTYPE" != "cygwin"* ]]; then
    echo "Installing via quick install script..."
    curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
    echo ""
    echo "Add ~/.local/bin to PATH if needed:"
    echo '  echo '\''export PATH="$HOME/.local/bin:$PATH'\'' >> ~/.bashrc'
else
    echo "Windows detected. Download from:"
    echo "  https://github.com/rtk-ai/rtk/releases"
    echo "  Extract rtk-x86_64-pc-windows-msvc.zip and add to PATH"
    exit 1
fi

# Verify
if command -v rtk &>/dev/null; then
    echo "RTK installed: $(rtk --version)"
    echo ""
    echo "Setup auto-rewrite hook:"
    echo "  rtk init -g                 # Claude Code"
    echo "  rtk init -g --opencode      # OpenCode"
    echo "  rtk init -g --gemini        # Gemini CLI"
    echo "  rtk init -g --agent cursor  # Cursor"
else
    echo "Installation may require PATH update. Check ~/.local/bin"
fi
