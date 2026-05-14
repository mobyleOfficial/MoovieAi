# Plugins

Claude Code plugins and MCP (Model Context Protocol) servers to extend Claude's capabilities.

Register plugins in `.claude/settings.json`:
```json
{
  "mcpServers": {
    "plugin-name": {
      "command": "node",
      "args": ["path/to/plugin.js"]
    }
  }
}
```

See Claude Code docs: https://claude.ai/code
