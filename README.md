# OpenCode Config

OpenCode multi-agent architecture, MCP servers, tools, and skills.

## Structure

```
agents/          Multi-agent system (orchestrator, specialists, reviewers)
tools/           Custom TypeScript tools (code navigation, wiki search)
scripts/         Python/shell implementations for tools
rules/           Session rules (git workflow, token efficiency)
skills/          Reusable skills (updater, wiki-ingest, wiki-lint)
mcp/             MCP server configurations
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
| **ops-specialist** | Linux systems, systemd, deployment |
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
| **updater** | Self-update apps via GitHub Releases |
| **wiki-ingest** | Add PRs to the project wiki |
| **wiki-lint** | Check wiki health and conformance |

## MCP Servers

| Server | Description | Guide |
|--------|-------------|-------|
| GitHub | GitHub API integration | [mcp/github/github.md](mcp/github/github.md) |
| Playwright | Browser automation | [mcp/playwright/playwright.md](mcp/playwright/playwright.md) |
| SSH | Remote host management | [mcp/ssh/ssh.md](mcp/ssh/ssh.md) |
| WSL | WSL command execution | [mcp/wsl/wsl.md](mcp/wsl/wsl.md) |

## Quick Start

1. Copy `opencode.example.json` to `~/.config/opencode/opencode.json`
2. Merge with your existing config (don't overwrite MCP/LSP/plugin settings)
3. Copy `agents/`, `tools/`, `scripts/`, `rules/` to `~/.config/opencode/`
4. Copy `skills/` to `~/.config/opencode/skills/`
5. Replace `YOUR_FAST_MODEL` in `opencode.json` with your model ID
6. Restart OpenCode

## Verify

```bash
opencode models    # Confirm model IDs resolve
opencode mcp list  # Confirm MCP servers
```
