#!/bin/bash
# Master setup script for OpenCode tools
# Installs: RTK, Graphify, Cotrex
# Usage: bash setup.sh [--rtk] [--graphify] [--cotrex] [--all]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS=()

# Parse arguments
if [ $# -eq 0 ] || [ "$1" = "--all" ]; then
    TOOLS=("rtk" "graphify" "cotrex")
else
    while [ $# -gt 0 ]; do
        case "$1" in
            --rtk)      TOOLS+=("rtk") ;;
            --graphify) TOOLS+=("graphify") ;;
            --cotrex)   TOOLS+=("cotrex") ;;
            *)          echo "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done
fi

echo "========================================="
echo "  OpenCode Tools Setup"
echo "========================================="
echo ""

for tool in "${TOOLS[@]}"; do
    echo "--- Installing $tool ---"
    case "$tool" in
        rtk)
            if command -v rtk &>/dev/null; then
                echo "RTK already installed: $(rtk --version)"
            else
                bash "$SCRIPT_DIR/install-rtk.sh"
            fi
            ;;
        graphify)
            if command -v graphify &>/dev/null; then
                echo "Graphify already installed: $(graphify --version)"
            else
                bash "$SCRIPT_DIR/install-graphify.sh"
            fi
            ;;
        cotrex)
            if command -v cotrex &>/dev/null; then
                echo "Cotrex already installed: $(cotrex --version)"
            else
                bash "$SCRIPT_DIR/install-cotrex.sh"
            fi
            ;;
    esac
    echo ""
done

echo "========================================="
echo "  Setup complete!"
echo "========================================="
echo ""
echo "Installed tools:"
command -v rtk      &>/dev/null && echo "  rtk:      $(rtk --version)"
command -v graphify &>/dev/null && echo "  graphify: $(graphify --version)"
command -v cotrex   &>/dev/null && echo "  cotrex:   $(cotrex --version)"
echo ""
echo "Next steps:"
echo "  1. RTK:      rtk init -g --opencode    (enable auto-rewrite hook)"
echo "  2. Graphify: graphify install           (register skill with AI assistant)"
echo "  3. Cotrex:   cotrex init                (download model and configure)"
