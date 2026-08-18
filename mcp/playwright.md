# Playwright MCP Server

Browser automation capabilities for web testing and scraping.

## Prerequisites

- [Node.js](https://nodejs.org/) installed

## Setup

### Configure opencode.json

```json
{
  "mcp": {
    "playwright": {
      "type": "local",
      "command": ["npx", "-y", "@playwright/mcp"],
      "enabled": true,
      "env": {
        "BROWSER": "chromium"
      }
    }
  }
}
```

## Verify

```bash
opencode mcp list
```

## Troubleshooting

| Error | Solution |
|-------|----------|
| Connection error | Ensure Node.js and npm are installed |
| Browser not found | Run `npx playwright install chromium` |
