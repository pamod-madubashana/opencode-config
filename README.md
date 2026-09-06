# OpenCode Config

OpenCode multi-agent architecture, MCP servers, tools, and skills.

## Structure

```
agents/          Multi-agent system (orchestrator, specialists, reviewers)
tools/           Custom TypeScript tools (code navigation, wiki search)
scripts/         Install scripts and tool implementations
rules/           Session rules (git workflow, token efficiency, auto-install)
skills/          Reusable skills (cotrex, graphify, tokex, updater, wiki)
mcp/             MCP server configurations
```

## Quick Start

```bash
# 1. Install all tools (RTK, Graphify, Cotrex)
bash scripts/setup.sh --all

# 2. Copy config files
cp opencode.example.json ~/.config/opencode/opencode.json
cp -R agents/ ~/.config/opencode/agents/
cp -R tools/ ~/.config/opencode/tools/
cp -R scripts/ ~/.config/opencode/scripts/
cp -R rules/ ~/.config/opencode/rules/
cp -R skills/ ~/.config/opencode/skills/

# 3. Setup hooks
rtk init -g --opencode      # RTK auto-rewrite
graphify install --platform opencode  # Graphify skill
cotrex init                  # Cotrex model download

# 4. Restart OpenCode
```

Windows (PowerShell):

```powershell
# 1. Install all tools (RTK, Graphify, Cotrex)
powershell -ExecutionPolicy Bypass -File scripts/setup.ps1 -All

# 2. Copy config files
Copy-Item opencode.example.json ~/.config/opencode/opencode.json
Copy-Item -Recurse agents/, tools/, scripts/, rules/, skills/ ~/.config/opencode/

# 3. Setup hooks
rtk init -g --opencode      # RTK auto-rewrite
graphify install --platform opencode  # Graphify skill
cotrex init                  # Cotrex model download

# 4. Restart OpenCode
```

## Required Tools

Agents auto-install these tools if missing. Install manually or let the `auto-install-tools` rule handle it.

| Tool | Version | Install | Purpose |
|------|---------|---------|---------|
| **RTK** | 0.42+ | `bash scripts/install-rtk.sh` | CLI proxy, cuts 60-90% of bash output |
| **Graphify** | 0.9+ | `bash scripts/install-graphify.sh` | Turn codebases into queryable knowledge graphs |
| **Cotrex** | 3.0+ | `bash scripts/install-cotrex.sh` | Deterministic execution orchestration |

### Install scripts

```bash
bash scripts/setup.sh --all       # Install everything
bash scripts/setup.sh --rtk       # Install RTK only
bash scripts/setup.sh --graphify  # Install Graphify only
bash scripts/setup.sh --cotrex    # Install Cotrex only
```

## Agents

### Primary (Tab cycle)

| Agent | Role |
|-------|------|
| **orchestrator** | Routes tasks to specialists. Never implements directly. |
| **plan** | Read-only investigation and structured planning. |

### Specialists

| Agent | Role |
|-------|------|
| **python-pro** | Expert Python 3.12+ developer |
| **go-pro** | Expert Go developer |
| **rust-pro** | Expert Rust 2024 developer (Cargo, Clippy, Tauri) |
| **typescript-pro** | Expert strict TypeScript developer (ESLint, Prettier, Vitest, React) |
| **ops-specialist** | Systems/infra specialist (Linux + Windows), deployment |
| **wiki-curator** | Maintains project wiki (OKF v0.2) |

### Reviewers

| Agent | Role |
|-------|------|
| **python-reviewer** | Read-only Python correctness review |
| **ops-reviewer** | Read-only ops and deployment review |

## Tools

| Tool | Script | Purpose |
|------|--------|---------|
| `skeleton` | `skeleton.py` | Strip method bodies for structural view |
| `impact` | `impact.py` | Find definitions and usages of a symbol |
| `seek` | `seek.py` | Jump to exact definition project-wide |
| `which_test` | `which_test.py` | Find tests referencing a module |
| `ghost` | `ghost.py` | Identify dead-code candidates |
| `check` | `check.sh` | Run lint, format, and tests |
| `wiki_search` | -- | Search wiki pages by content |

## Skills

| Skill | Purpose |
|-------|---------|
| **cotrex** | RTK orchestration (MCP + CLI fallback) |
| **graphify** | Knowledge graph from codebases |
| **tokex** | Alternative RTK orchestration |
| **updater** | Self-update apps via GitHub Releases |
| **wiki-ingest** | Add PRs to the project wiki |
| **wiki-lint** | Check wiki health and conformance |

## Rules

| Rule | Purpose |
|------|---------|
| `git-workflow` | Run check after edits, imperative commits |
| `token-efficiency` | Use skeleton/impact/which_test, prefer native tools |
| `auto-install-tools` | Auto-install missing tools (RTK, Graphify, Cotrex) |

## MCP Servers

| Server | Description | Guide |
|--------|-------------|-------|
| GitHub | GitHub API integration | [mcp/github/github.md](mcp/github/github.md) |
| Playwright | Browser automation | [mcp/playwright/playwright.md](mcp/playwright/playwright.md) |
| SSH | Remote host management | [mcp/ssh/ssh.md](mcp/ssh/ssh.md) |
| WSL | WSL command execution | [mcp/wsl/wsl.md](mcp/wsl/wsl.md) |

## Cross-Platform

Hosts may run Windows (PowerShell), Linux, or macOS. All roles are OS-agnostic:
native commands first, toolchain commands (`cargo`, `npm`, `go`, `uv`) over shell
tricks, and never WSL/alternate shells as a workaround. Committed scripts come in
`.sh` + `.ps1` pairs; repos keep LF line endings.

## Verify

```bash
opencode models    # Confirm model IDs resolve
opencode mcp list  # Confirm MCP servers
rtk --version      # RTK installed
graphify --version # Graphify installed
cotrex --version   # Cotrex installed
```
