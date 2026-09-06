# Auto-Install Required Tools

Before running any command, verify the required tool is installed. If missing, install it automatically using the scripts in `~/.config/opencode/scripts/`.

## Tool Check and Install

| Tool | Check Command | Linux/macOS | Windows (PowerShell) |
|------|--------------|-------------|---------------------|
| **RTK** | `rtk --version` | `bash ~/.config/opencode/scripts/install-rtk.sh` | `powershell ~/.config/opencode/scripts/install-rtk.ps1` |
| **Graphify** | `graphify --version` | `bash ~/.config/opencode/scripts/install-graphify.sh` | `powershell ~/.config/opencode/scripts/install-graphify.ps1` |
| **Cotrex** | `cotrex --version` | `bash ~/.config/opencode/scripts/install-cotrex.sh` | `powershell ~/.config/opencode/scripts/install-cotrex.ps1` |

## Detect Platform

```bash
# Linux/macOS
bash ~/.config/opencode/scripts/install-rtk.sh

# Windows (PowerShell)
powershell -ExecutionPolicy Bypass -File ~/.config/opencode/scripts/install-rtk.ps1
```

## Rules

1. **Always check first** — run `tool --version` before using a tool
2. **Install automatically** — if missing, run the install script without asking
3. **Detect platform** — use `.sh` on Linux/macOS, `.ps1` on Windows
4. **Verify after install** — confirm the tool works before proceeding
5. **Never block** — if install fails, fall back to direct shell commands
6. **Report briefly** — one line: "Installed tool vX.Y.Z" or "Tool unavailable, using fallback"

## Fallback Chain

If a tool is unavailable and install fails:

- **RTK**: Run shell commands directly (no token compression)
- **Graphify**: Use `read`, `grep`, `glob` for code exploration
- **Cotrex**: Run shell commands directly via `bash` tool

## RTK Hook Setup

After installing RTK, enable the auto-rewrite hook:

```bash
rtk init -g --opencode    # For OpenCode
rtk init -g               # For Claude Code
```

## Graphify Skill Setup

After installing Graphify, register the skill:

```bash
graphify install                    # Claude Code
graphify install --platform opencode  # OpenCode
```

## Windows Notes

- PowerShell scripts auto-detect platform and download correct binaries
- Scripts install to `~/.local/bin` and add to PATH automatically
- Use `winget` as fallback if cargo is not available
- Run `rtk init -g` after install to setup the native binary hook
