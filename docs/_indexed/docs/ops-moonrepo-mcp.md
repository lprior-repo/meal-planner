---
id: ops/moonrepo/mcp-2
title: "MCP integration"
category: ops
tags: ["mcp", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>MCP integration</title>
  <description>[Model Context Protocol](https://modelcontextprotocol.io) (MCP) is an open standard that enables AI models to interact with external tools and services through a unified interface. The moon CLI contai</description>
  <created_at>2026-01-02T19:55:27.174211</created_at>
  <updated_at>2026-01-02T19:55:27.174211</updated_at>
  <language>en</language>
  <sections count="6">
    <section name="Setup" level="2"/>
    <section name="Claude Code" level="3"/>
    <section name="Cursor" level="3"/>
    <section name="VS Code" level="3"/>
    <section name="Zed" level="3"/>
    <section name="Available tools" level="2"/>
  </sections>
  <features>
    <feature>available_tools</feature>
    <feature>claude_code</feature>
    <feature>cursor</feature>
    <feature>setup</feature>
    <feature>vs_code</feature>
  </features>
  <examples count="5">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>mcp,operations,moonrepo</tags>
</doc_metadata>
-->

# MCP integration

> **Context**: [Model Context Protocol](https://modelcontextprotocol.io) (MCP) is an open standard that enables AI models to interact with external tools and service

v1.37.0

[Model Context Protocol](https://modelcontextprotocol.io) (MCP) is an open standard that enables AI models to interact with external tools and services through a unified interface. The moon CLI contains an MCP server that you can register with your code editor to allow LLMs to use moon directly.

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

## Available tools

The following tools are available in the moon MCP server and can be executed by LLMs using agent mode.

- `get_project` - Get a project and its tasks by `id`.
- `get_projects` - Get all projects.
- `get_task` - Get a task by `target`.
- `get_tasks` - Get all tasks.
- `get_touched_files` - Gets touched files between base and head revisions. (v1.38.0)
- `sync_projects` - Runs the `SyncProject` action for one or many projects by `id`. (v1.38.0)
- `sync_workspace` - Runs the `SyncWorkspace` action. (v1.38.0)

> **Info:** The [request and response shapes](https://github.com/moonrepo/moon/blob/master/packages/types/src/mcp.ts) for these tools are defined as TypeScript types in the [`@moonrepo/types`](https://www.npmjs.com/package/@moonrepo/types) package.


## See Also

- [Documentation Index](./COMPASS.md)
