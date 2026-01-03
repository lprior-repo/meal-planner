---
doc_id: ops/moonrepo/mcp-2
chunk_id: ops/moonrepo/mcp-2#chunk-2
heading_path: ["MCP integration", "Setup"]
chunk_type: code
tokens: 423
summary: "Setup"
---

## Setup

### Claude Code

To use [MCP servers in Claude Code](https://docs.anthropic.com/en/docs/claude-code/mcp), run the following command in your terminal:

```shell
claude mcp add moon -s project -e MOON_WORKSPACE_ROOT=/absolute/path/to/your/moon/workspace -- moon mcp
```

Or create an `.mcp.json` file in your project directory.

```json
{
  "mcpServers": {
    "moon": {
      "command": "moon",
      "args": ["mcp"],
      "env": {
        "MOON_WORKSPACE_ROOT": "/absolute/path/to/your/moon/workspace"
      }
    }
  }
}
```

### Cursor

To use [MCP servers in Cursor](https://docs.cursor.com/context/model-context-protocol), create a `.cursor/mcp.json` file in your project directory, or `~/.cursor/mcp.json` globally, with the following content:

.cursor/mcp.json

```json
{
  "mcpServers": {
    "moon": {
      "command": "moon",
      "args": ["mcp"],
      "env": {
        "MOON_WORKSPACE_ROOT": "/absolute/path/to/your/moon/workspace"
      }
    }
  }
}
```

Once configured, the moon MCP server should appear in the "Available Tools" section on the MCP settings page in Cursor.

### VS Code

To use MCP servers in VS Code, you must have the [Copilot Chat](https://code.visualstudio.com/docs/copilot/chat/copilot-chat) extension installed. Once installed, create a `.vscode/mcp.json` file with the following content:

.vscode/mcp.json

```json
{
  "servers": {
    "moon": {
      "type": "stdio",
      "command": "moon",
      "args": ["mcp"],
      // >= 1.102 (June 2025)
      "cwd": "${workspaceFolder}",
      // Older versions
      "env": {
        "MOON_WORKSPACE_ROOT": "${workspaceFolder}"
      }
    }
  }
}
```

Once your MCP server is configured, you can use it with [GitHub Copilot's agent mode](https://code.visualstudio.com/docs/copilot/chat/chat-agent-mode):

- Open the Copilot Chat view in VS Code
- Enable agent mode using the mode select dropdown
- Toggle on moon's MCP tools using the "Tools" button

### Zed

To use [MCP servers in Zed](https://zed.dev/docs/ai/mcp), create a `.zed/settings.json` file in your project directory, or `~/.config/zed/settings.json` globally, with the following content:

.zed/settings.json

```json
{
  "context_servers": {
    "moon": {
      "command": {
        "path": "moon",
        "args": ["mcp"],
        "env": {
          "MOON_WORKSPACE_ROOT": "/absolute/path/to/your/moon/workspace"
        }
      }
    }
  }
}
```

Once your MCP server is configured, you'll need to enable the tools using the following steps:

- Open the Agent panel in Zed
- Click the Write/Ask toggle button and go to "Configure Profiles"
- Click "Customize" in the Ask section
- Click "Configure MCP Tools"
- Enable each tool under the "moon" section
