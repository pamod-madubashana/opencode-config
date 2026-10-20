# GitHub MCP Server

Tools to interact with GitHub platform - repositories, issues, pull requests, and more.

## Prerequisites

- [GitHub Personal Access Token](https://github.com/settings/tokens) with scopes:
  - `repo` - Full repository access
  - `read:org` - Read organization data
  - `read:user` - Read user profile data

## Setup

### 1. Set Environment Variable

**Windows (PowerShell):**
```powershell
[System.Environment]::SetEnvironmentVariable("GITHUB_TOKEN", "ghp_yourtokenhere", "User")
```

### 2. Configure opencode.json

```json
{
  "mcp": {
    "github": {
      "type": "remote",
      "url": "https://api.githubcopilot.com/mcp/",
      "enabled": true,
      "oauth": false,
      "headers": {
        "Authorization": "Bearer {env:GITHUB_TOKEN}"
      }
    }
  }
}
```

## Verify

```bash
opencode mcp list
opencode mcp debug github
```

## Troubleshooting

| Error | Solution |
|-------|----------|
| 401 Unauthorized | Check PAT is valid and not expired |
| SSE Error | Ensure `oauth: false` is set |
| Tools missing | Verify `enabled: true` |
