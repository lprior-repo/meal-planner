# MCP Agent Mail Server Launcher

A simple script to install and run the [MCP Agent Mail](https://github.com/Dicklesworthstone/mcp_agent_mail) server with minimal hassle.

## Quick Start

```bash
# Start with defaults (127.0.0.1:8765)
./scripts/start-agent-mail.sh

# Custom port
./scripts/start-agent-mail.sh --port 9000

# View help
./scripts/start-agent-mail.sh --help
```

## Features

- **Auto-installation**: Automatically clones and sets up the MCP Agent Mail repository if not found
- **Configurable**: Override host, port, and installation directory via CLI or environment variables
- **Python 3.14 support**: Uses `uv` for fast dependency management
- **Web interface**: Access the mail interface at `http://127.0.0.1:8765/mail`

## Options

```
--port PORT         Server port (default: 8765)
--host HOST         Server host (default: 127.0.0.1)
--install-dir DIR   Installation directory (default: ~/.local/mcp_agent_mail)
--no-install        Skip auto-installation if not found
--help, -h          Show help message
```

## Environment Variables

- `AGENT_MAIL_PORT` - Override default port
- `AGENT_MAIL_HOST` - Override default host
- `AGENT_MAIL_INSTALL_DIR` - Override installation directory
- `AGENT_MAIL_AUTO_INSTALL` - Auto-install if not found (default: true)
- `AGENT_NAME` - Set agent name for file reservations

## Examples

```bash
# Use environment variables
AGENT_MAIL_PORT=9000 AGENT_NAME=my-agent ./scripts/start-agent-mail.sh

# Custom installation location
./scripts/start-agent-mail.sh --install-dir /opt/mcp_agent_mail

# Skip auto-installation (requires manual setup first)
./scripts/start-agent-mail.sh --no-install
```

## What is MCP Agent Mail?

MCP Agent Mail provides a mail-like coordination layer for multi-agent workflows via MCP (Model Context Protocol). It enables:

- **Agent coordination**: Asynchronous message passing between coding agents
- **File reservations**: Advisory locks to prevent agents from conflicting
- **Searchable threads**: Organized communication history
- **Git integration**: Human-auditable artifacts stored in version control

## Using with Claude Code

To use this MCP server with Claude Code, add it to your MCP configuration:

```bash
# Option 1: Start the server manually first, then add to Claude
./scripts/start-agent-mail.sh
claude mcp add agent-mail http://127.0.0.1:8765/mcp/v1

# Option 2: Configure Claude to start it automatically
# Edit ~/.config/claude/mcp.json and add:
{
  "mcpServers": {
    "agent-mail": {
      "command": "/path/to/meal-planner/scripts/start-agent-mail.sh"
    }
  }
}
```

## Requirements

- **uv**: Python package manager (auto-installed if not found)
- **Python 3.12+**: Required for the agent mail server
- **Git**: For cloning the repository

## Troubleshooting

**Server won't start:**
- Check if port 8765 is already in use: `lsof -i :8765`
- Try a different port: `./scripts/start-agent-mail.sh --port 9000`

**Installation fails:**
- Ensure you have Git installed: `git --version`
- Check uv installation: `uv --version`
- Manually install: `curl -LsSf https://astral.sh/uv/install.sh | sh`

**Permission errors:**
- Ensure the script is executable: `chmod +x scripts/start-agent-mail.sh`
- Check write permissions for install directory

## Web Interface

Once started, access the web interface at:
- **Default**: http://127.0.0.1:8765/mail
- View inbox, threads, and manage agent coordination
- Human-readable message browsing and thread navigation

## MCP Tools Available

The agent mail server provides MCP tools for:
- `ensure_project` - Initialize project context
- `register_agent` - Register agent identity
- `send_message` - Send messages to agents
- `fetch_inbox` - Check inbox
- `file_reservation_paths` - Reserve files for exclusive editing
- And more...

Refer to the [official documentation](https://github.com/Dicklesworthstone/mcp_agent_mail) for complete tool reference.
