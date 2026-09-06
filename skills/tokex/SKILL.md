---
name: tokex
description: "Tokex RTK orchestration skills for MVP. Run commands, inspect projects, and get normalized output."
---

# Tokex Skills

**IMPORTANT:** You are an AI agent. Always use tokex via MCP (preferred) or CLI fallback.

## 1. MCP (preferred)

Connect to tokex as an MCP server. This gives you tools: `run`, `delegate`, `plan`, `list_roles`, `set_agent`.

**Setup** — Add to your agent config:
```json
{
  "mcpServers": {
    "tokex": { "command": "tokex", "args": ["mcp"] }
  }
}
```

Once connected, use the `run` tool:
```
run(command="cargo test")
run(command="git status")
run(command="npm install")
```

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

If tokex is not running as an MCP server, use CLI commands directly.

### Commands (no quotes)
Known CLI commands like `cargo`, `git`, `npm`, `ls`. Pass them **without quotes**:
```bash
tokex -m cargo test
tokex -m git status
tokex -m npm install
tokex -m cargo build --release
```

### Prompts (quoted)
Natural language instructions. Pass them **inside double quotes**:
```bash
tokex -m "show the project tree"
tokex -m "list all rust projects"
tokex -m "explain the architecture"
```

## Rules

1. **MCP first.** Only use CLI when MCP is not configured.
2. Commands = no quotes. Prompts = quoted. Never mix.
3. One command at a time. Feed the result back before running the next.
4. Skip vendor/, target/, .git/ — they're noise.

## Installed for: MVP
