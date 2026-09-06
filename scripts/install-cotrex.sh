#!/bin/bash
# Install Cotrex - Deterministic execution orchestration for AI agents
# https://github.com/pamod-madubashana/Cotrex

set -e

echo "Installing Cotrex..."

if command -v cotrex &>/dev/null; then
    echo "Cotrex already installed: $(cotrex --version)"
    exit 0
fi

# Detect platform
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Darwin)
        if [ "$ARCH" = "arm64" ]; then
            PLATFORM="aarch64-apple-darwin"
        else
            PLATFORM="x86_64-apple-darwin"
        fi
        ;;
    Linux)
        if [ "$ARCH" = "aarch64" ]; then
            PLATFORM="aarch64-unknown-linux-gnu"
        else
            PLATFORM="x86_64-unknown-linux-gnu"
        fi
        ;;
    MINGW*|MSYS*|CYGWIN*)
        PLATFORM="x86_64-pc-windows-msvc"
        ;;
    *)
        echo "Unsupported OS: $OS"
        echo "Download manually from: https://github.com/pamod-madubashana/Cotrex/releases"
        exit 1
        ;;
esac

# Try cargo if available
if command -v cargo &>/dev/null; then
    echo "Installing via cargo..."
    cargo install --git https://github.com/pamod-madubashana/Cotrex
else
    # Download pre-built binary
    VERSION="3.0.0"
    echo "Downloading Cotrex v${VERSION} for ${PLATFORM}..."
    TARBALL="cotrex-${PLATFORM}.tar.gz"
    URL="https://github.com/pamod-madubashana/Cotrex/releases/latest/download/${TARBALL}"

    TMPDIR=$(mktemp -d)
    trap "rm -rf $TMPDIR" EXIT

    if command -v curl &>/dev/null; then
        curl -sL "$URL" -o "${TMPDIR}/${TARBALL}"
    elif command -v wget &>/dev/null; then
        wget -q "$URL" -O "${TMPDIR}/${TARBALL}"
    else
        echo "No curl or wget found. Download manually from:"
        echo "  https://github.com/pamod-madubashana/Cotrex/releases"
        exit 1
    fi

    # Extract
    tar -xzf "${TMPDIR}/${TARBALL}" -C "$TMPDIR"

    # Install to ~/.local/bin
    mkdir -p "$HOME/.local/bin"
    mv "$TMPDIR/cotrex" "$HOME/.local/bin/"
    chmod +x "$HOME/.local/bin/cotrex"

    echo "Cotrex installed to ~/.local/bin/cotrex"
    echo "Add ~/.local/bin to PATH if needed:"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
fi

# Verify
if command -v cotrex &>/dev/null; then
    echo "Cotrex installed: $(cotrex --version)"
    echo ""
    echo "First-time setup:"
    echo "  cotrex init           # auto-download model and configure"
    echo "  cotrex doctor         # check system health"
    echo "  cotrex setup          # configure API provider"
else
    echo "Installation may require PATH update."
fi
