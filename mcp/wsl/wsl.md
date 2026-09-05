# WSL MCP Server

Interact with Windows Subsystem for Linux from OpenCode — system info, process monitoring, directory browsing, and command execution.

**Package:** [spences10/mcp-wsl-exec](https://github.com/spences10/mcp-wsl-exec)

## Prerequisites

- [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/install) installed with a distro
- [Node.js](https://nodejs.org/) (v22+)

## Installation

### Option 1: npx (No Install)

No installation required — runs directly via npx.

### Option 2: Global Install

```bash
npm install -g mcp-wsl-exec
```

### Option 3: Download Binary

Download the latest release from [GitHub Releases](https://github.com/spences10/mcp-wsl-exec/releases).

## Configuration

### Using npx (Recommended)

```json
{
  "mcp": {
    "wsl": {
      "type": "local",
      "command": ["npx", "-y", "mcp-wsl-exec"],
      "enabled": true
    }
  }
}
```

### Using Global Install

```json
{
  "mcp": {
    "wsl": {
      "type": "local",
      "command": ["mcp-wsl-exec"],
      "enabled": true
    }
  }
}
```

### Using Direct Path

```json
{
  "mcp": {
    "wsl": {
      "type": "local",
      "command": ["node", "C:\\Users\\<you>\\AppData\\Roaming\\npm\\node_modules\\mcp-wsl-exec\\dist\\index.js"],
      "enabled": true
    }
  }
}
```

## Verify

```bash
opencode mcp list
```

## Tools

### Read-Only

| Tool | Description |
|------|-------------|
| `get_system_info` | OS version, kernel, hostname |
| `get_directory_info` | Browse directory contents (optional `path`, `details` params) |
| `get_disk_usage` | Check disk space (optional `path` param) |
| `get_environment` | List environment variables (optional `filter` param) |
| `list_processes` | List running processes (optional `filter` param) |

### Command Execution

| Tool | Description |
|------|-------------|
| `execute_command` | Run a command in WSL (params: `command`, `working_dir?`, `timeout?`) |
| `confirm_command` | Confirm a flagged dangerous command (params: `confirmation_id`, `confirm`) |

## Safety

Dangerous commands (`rm`, `sudo`, `chmod`, `apt`, `kill`, etc.) require explicit confirmation via `confirm_command` before execution.

## Troubleshooting

| Error | Solution |
|-------|----------|
| `wsl.exe` not found | Install WSL: `wsl --install` |
| Node not found | Ensure Node.js v22+ is installed: `node --version` |
| Module not found | Run `npm install -g mcp-wsl-exec` or use `npx` config |
