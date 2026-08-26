# SSH MCP Server

SSH MCP server for remote host management via [0FL01/SeSSHion](https://github.com/0FL01/SeSSHion).

## Installation

### Download Binary

Download the latest release for your OS from [GitHub Releases](https://github.com/0FL01/SeSSHion/releases):

| OS | File |
|----|------|
| Windows | `ssh-mcp-windows-x86_64.exe` |
| Linux | `ssh-mcp-linux-x86_64` |
| macOS | `ssh-mcp-macos-x86_64` |

Rename to `ssh-mcp.exe` (Windows) or `ssh-mcp` (Linux/macOS) and place in a directory in your PATH.

### Build from Source

```bash
git clone https://github.com/0FL01/SeSSHion
cd SeSSHion
go build .
```

## Configuration

Add to your `opencode.json`:

```json
{
  "mcp": {
    "ssh": {
      "type": "local",
      "command": ["C:\\Users\\<you>\\ssh-mcp.exe"],
      "enabled": true
    }
  }
}
```

## Usage

### Add Hosts

Use the `add_host` tool to add servers:

```
add host to production group connecting with root@192.168.1.100
add host named web01 to webservers group connecting with user@10.0.0.5 port 2222
```

### Execute Commands

```
perform command on production group: uptime
perform command on web01: systemctl status nginx
```

### Manage Hosts

```
get groups
get hosts in production group
remove host web01 from webservers group
```

## Tools

| Tool | Description |
|------|-------------|
| `add_host` | Add a host to a group |
| `remove_host` | Remove a host |
| `get_groups` | List all groups |
| `get_hosts` | List hosts (optional group filter) |
| `get_os_info` | Get cached OS info |
| `update_os_info` | Refresh OS info |
| `perform_command` | Execute command on host(s) |
| `get_command_status` | Check background command |
| `list_commands` | List all background commands |
| `cancel_command` | Cancel a running command |

## Authentication

- **Password**: Include in connection string (`user:password@host`)
- **SSH Key**: Uses `~/.ssh/id_rsa` or `~/.ssh/id_ed25519` automatically
- **SSH Agent**: Supported on Unix (SSH_AUTH_SOCK)

## Notes

- Commands running >30 seconds auto-background
- Supports Linux and Windows remote hosts
- Group-based organization for batch operations
