# Auto-Install Required Tools

Before running any command, verify the required tool is installed. If missing, install it automatically using the scripts in `~/.config/opencode/scripts/`.

## Tool Check and Install

| Tool | Check Command | Install Script |
|------|--------------|----------------|
| **RTK** | `rtk --version` | `bash ~/.config/opencode/scripts/install-rtk.sh` |
| **Graphify** | `graphify --version` | `bash ~/.config/opencode/scripts/install-graphify.sh` |
| **Cotrex** | `cotrex --version` | `bash ~/.config/opencode/scripts/install-cotrex.sh` |

## Rules

1. **Always check first** — run `tool --version` before using a tool
2. **Install automatically** — if missing, run the install script without asking
3. **Verify after install** — confirm the tool works before proceeding
4. **Never block** — if install fails, fall back to direct shell commands
5. **Report briefly** — one line: "Installed tool vX.Y.Z" or "Tool unavailable, using fallback"

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
