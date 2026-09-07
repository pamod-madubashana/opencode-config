# OpenCode Config

OpenCode multi-agent architecture, MCP servers, tools, and skills.

## Structure

```
agents/          Multi-agent system (orchestrator, specialists, reviewers)
tools/           Custom TypeScript tools (code navigation, wiki search)
scripts/         Install scripts and tool implementations
rules/           Session rules (git workflow, token efficiency, auto-install, graphify-rtk)
skills/          Reusable skills (graphify, tokex, updater, wiki)
mcp/             MCP server configurations
```

## Quick Start

```bash
# 1. Install all tools (RTK, Graphify)
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

# 4. Restart OpenCode
```

Windows (PowerShell):

```powershell
# 1. Install all tools (RTK, Graphify)
powershell -ExecutionPolicy Bypass -File scripts/setup.ps1 -All

# 2. Copy config files
Copy-Item opencode.example.json ~/.config/opencode/opencode.json
Copy-Item -Recurse agents/, tools/, scripts/, rules/, skills/ ~/.config/opencode/

# 3. Setup hooks
rtk init -g --opencode      # RTK auto-rewrite
graphify install --platform opencode  # Graphify skill

# 4. Restart OpenCode
```

## Required Tools

Agents auto-install these tools if missing. Install manually or let the `auto-install-tools` rule handle it.

| Tool | Version | Install | Purpose |
|------|---------|---------|---------|
| **RTK** | 0.42+ | `bash scripts/install-rtk.sh` | CLI proxy, cuts 60-90% of bash output |
| **Graphify** | 0.9+ | `bash scripts/install-graphify.sh` | Turn codebases into queryable knowledge graphs |

### Install scripts

```bash
bash scripts/setup.sh --all       # Install everything
bash scripts/setup.sh --rtk       # Install RTK only
bash scripts/setup.sh --graphify  # Install Graphify only
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
| **graphify** | Knowledge graph from codebases |
| **updater** | Self-update apps via GitHub Releases |
| **wiki-ingest** | Add PRs to the project wiki |
| **wiki-lint** | Check wiki health and conformance |

## Rules

| Rule | Purpose |
|------|---------|
| `git-workflow` | Run check after edits, imperative commits |
| `token-efficiency` | Use skeleton/impact/which_test, prefer native tools |
| `auto-install-tools` | Auto-install missing tools (RTK, Graphify) |
| `graphify-rtk` | Use graphify query before manual reads, prefer rtk for shell |

## MCP Servers

| Server | Type | Description | Prerequisites |
|--------|------|-------------|---------------|
| **Playwright** | local | Browser automation | None (auto-installed via npx) |
| **GitHub** | remote | GitHub API integration | `GITHUB_TOKEN` env |
| **WSL** | local | WSL command execution | Windows + WSL2 |
| **Snyk** | local | Security scanning (SAST + deps) | `npx -y snyk@^1.1296.2 auth` (OAuth once) |
| **Postman** | local | Postman API access | `POSTMAN_API_KEY` env |
| **Burp** | remote | Burp Suite integration | Burp Suite + PortSwigger MCP extension on `:9876` |

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
```
