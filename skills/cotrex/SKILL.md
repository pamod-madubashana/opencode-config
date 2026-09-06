---
name: cotrex
description: "Cotrex RTK orchestration skills for MVP. Run commands, inspect projects, and get normalized output."
---

# Cotrex Skills

## RULE 0: USE COTREX — NO EXCEPTIONS

**Every shell command MUST go through cotrex.** Not sometimes. Not when convenient. Every time.

If you need to run `cargo build`, `git status`, `cargo test`, `git diff`, `gh pr create`, or ANY
other command — use a cotrex MCP tool or the cotrex CLI. Never call the shell directly.

### MCP tools (preferred — available in this session)

| Task | Tool | Example |
|------|------|---------|
| Run any command | `cotrex_run` | `cotrex_run` with `command: "cargo test"` |
| Multi-step work | `cotrex_delegate` | `cotrex_delegate` with `task: "build and test"` |
| Plan a task | `cotrex_plan` | `cotrex_plan` with `task: "add feature X"` |

### CLI fallback (only if MCP tools are unavailable)

```bash
cotrex -c cargo build
cotrex -c cargo test
cotrex -c cargo test -p cotrex
cotrex -c git status
cotrex -c git diff
```

**Fallback chain**: `cotrex_run` → `cotrex -c <cmd>` → `rtk <cmd>` → raw shell (last resort).
Raw shell loses normalization. Only use it when cotrex is completely unavailable.

## RULE 1: GRAPHIFY FIRST

Before reading files or exploring the codebase, read `graphify-out/GRAPH_REPORT.md` first.
For deeper questions, run graphify CLI commands (NOT MCP tools):

```bash
cotrex -m graphify query "architecture overview"    # BFS traversal
cotrex -m graphify explain "Intent"                  # node details
cotrex -m graphify path "Intent" "RTK"              # shortest path
```

Reading >3 files manually without trying graphify first wastes tokens.

**IMPORTANT:** `cotrex_graphify`, `cotrex_graphify_explain`, `cotrex_graphify_path` are for
saving Q&A results back into the graph — NOT for asking questions. Never call them to query.


**IMPORTANT:** You are an AI agent. Every shell command MUST go through cotrex — MCP tools first, CLI fallback if MCP is unavailable. Never call the shell directly.

## 1. MCP (preferred)

Connect to cotrex as an MCP server. This gives you tools: `run`, `delegate`, `plan`, `list_roles`, `set_agent`, `usage`.

**Setup** — Add to your agent config:
```json
{
  "mcpServers": {
    "cotrex": { "command": "cotrex", "args": ["mcp"] }
  }
}
```

Once connected, use the `run` tool:
```
run(command="cargo test")
run(command="git status")
run(command="npm install")
```

Every `run` result includes a `usage` JSON object with token counts:
```json
"usage": {"command": "cargo test", "tokens_in": 12, "tokens_out": 50, "exit_code": 0}
```

**Show token savings to the user.** After each command, briefly mention the token stats:
- "Ran `cargo test` — 12 tokens in, 50 tokens out"
- Use the `usage` tool to show cumulative totals at any time.

Delegation and planning:
```
delegate(task="analyze the project structure", role="planner")
delegate(task="write a function to parse CSV", role="coder")
plan(task="build a music player app")
```

Identify yourself so graphify installs the right code-map skill:
```
set_agent(agent="opencode")
```

## 2. CLI fallback (when MCP is not available)

If cotrex is not running as an MCP server, use CLI commands directly.

### Commands (no quotes)
Known CLI commands like `cargo`, `git`, `npm`, `ls`. Pass them **without quotes**:
```bash
cotrex -c cargo test
cotrex -c git status
cotrex -c npm install
cotrex -c cargo build --release
```

### Prompts (quoted)
Natural language instructions. Pass them **inside double quotes**:
```bash
cotrex -m "show the project tree"
cotrex -m "list all rust projects"
cotrex -m "explain the architecture"
```

## Rules

1. **MCP first.** Only use CLI when MCP is not configured.
2. Commands = no quotes. Prompts = quoted. Never mix.
3. One command at a time. Feed the result back before running the next.
4. Skip vendor/, target/, .git/ — they're noise.

## Installed for: MVP
