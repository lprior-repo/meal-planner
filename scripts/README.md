# Agent Mail Scripts

Enhanced scripts for running and monitoring the MCP Agent Mail server with rich live event display.

## Features

These scripts implement the same "keep-window-open" mechanism used by the official MCP Agent Mail repository:

- **Foreground mode**: Server and monitor run together, window stays open until Ctrl+C
- **Rich event display**: Beautiful formatted boxes showing agent registrations, messages, and file reservations
- **Live statistics**: Real-time counts of projects, agents, messages, and reservations
- **File system monitoring**: Uses `inotifywait` for instant event detection
- **Graceful cleanup**: Server automatically stops when you close the window

## Quick Start

### Background Mode (default)
```bash
./scripts/start-agent-mail.sh
```
- Server runs in background
- Returns immediately
- Monitor separately with `./scripts/monitor-agent-mail.sh`

### Foreground Mode (stays open)
```bash
./scripts/start-agent-mail.sh foreground
```
or
```bash
./scripts/start-agent-mail.sh fg
```
- Window stays open showing live events
- Press Ctrl+C to stop both server and monitor
- Server automatically cleaned up on exit

## Scripts

### `start-agent-mail.sh`

Main script that:
1. Checks if server is already running
2. Installs Agent Mail if needed (clones from GitHub)
3. Generates secure configuration
4. Starts the server
5. Launches monitor (in foreground mode)

**Modes:**
- `./scripts/start-agent-mail.sh` - Background mode (default)
- `./scripts/start-agent-mail.sh foreground` - Foreground mode (window stays open)
- `./scripts/start-agent-mail.sh fg` - Foreground mode (shorthand)

**Environment:**
- Install directory: `~/.local/mcp_agent_mail`
- Mailbox directory: `~/.mcp_agent_mail_git_mailbox_repo`
- Default port: 8765

### `monitor-agent-mail.sh`

Standalone monitoring script that displays:

#### Initial Display
- Header with branding
- Database statistics (projects, agents, messages, reservations)
- Active agents list with program and model info
- Recent 10 messages
- Active file reservations

#### Live Events (Rich Format)
Events are displayed in colored boxes with details:

**Agent Registration** (Green box):
```
┌─────────────────────────────────────────────────────────────
│ [14:32:15] 🤖 NEW AGENT REGISTERED
├─────────────────────────────────────────────────────────────
│ Agent: BlueLake
│ Program: claude-code
│ Model: claude-sonnet-4-5
│ Task: Implementing feature X
└─────────────────────────────────────────────────────────────
```

**New Message** (Blue or Red box):
```
┌─────────────────────────────────────────────────────────────
│ [14:33:20] 📧 NEW MESSAGE
├─────────────────────────────────────────────────────────────
│ Subject: [bd-123] Starting work
│ From: BlueLake → To: coordinator
│ Thread: bd-123
│ File: 2025-12-04_143320_msg_001.md
└─────────────────────────────────────────────────────────────
```
- Red box with 🚨 for high/urgent importance
- Blue box with 📧 for normal messages

**File Reservation** (Yellow box):
```
┌─────────────────────────────────────────────────────────────
│ [14:34:05] 🔐 FILE RESERVATION (EXCLUSIVE)
├─────────────────────────────────────────────────────────────
│ Agent: BlueLake
│ Path: gleam/src/**/*.gleam
│ Reason: bd-123
└─────────────────────────────────────────────────────────────
```
- 🔐 for exclusive locks
- 🔒 for shared locks

**File Release** (Green box):
```
┌─────────────────────────────────────────────────────────────
│ [14:45:12] 🔓 FILE RELEASED
├─────────────────────────────────────────────────────────────
│ Agent: BlueLake
│ Path: gleam/src/**/*.gleam
└─────────────────────────────────────────────────────────────
```

## How It Works

The "keep-window-open" mechanism uses three key techniques from the MCP Agent Mail repository:

### 1. Process Control with `exec`
```bash
# In foreground mode, exec replaces the shell process
exec "$SCRIPT_DIR/monitor-agent-mail.sh"
```
This prevents the script from returning, keeping the window open.

### 2. Trap for Cleanup
```bash
cleanup() {
    echo "Shutting down server (PID: $SERVER_PID)..."
    kill $SERVER_PID 2>/dev/null || true
    wait $SERVER_PID 2>/dev/null || true
    exit 0
}
trap cleanup INT TERM EXIT
```
When you press Ctrl+C, the trap kills the server process gracefully.

### 3. Blocking Monitor Loop
```bash
inotifywait -m -r -e create,modify,delete,moved_to \
    agents/ messages/ file_reservations/ | \
while IFS='|' read -r timestamp event dir file; do
    # Process events forever
done
```
The `inotifywait -m` (monitor mode) runs indefinitely, keeping the script alive.

## Dependencies

### Required
- `bash` - Shell interpreter
- `curl` - For health checks
- `jq` - For JSON parsing
- `uv` - Python package manager (auto-installed if missing)

### Optional (but recommended)
- `inotify-tools` - For real-time file system monitoring
  ```bash
  # Arch Linux
  sudo pacman -S inotify-tools

  # Debian/Ubuntu
  sudo apt install inotify-tools
  ```
  Without this, monitor falls back to 30-second polling.

## Configuration

Configuration is stored in `~/.mcp_agent_mail_git_mailbox_repo/.env`:

```bash
HTTP_PORT=8765
HTTP_HOST=127.0.0.1
HTTP_BEARER_TOKEN=<auto-generated-64-char-hex>
```

**Security**: The bearer token is automatically generated using Python's `secrets` module and stored with `chmod 600`.

## Web UI

Access the web interface at: **http://127.0.0.1:8765/mail**

Features:
- Browse all messages
- View agent profiles
- Check file reservations
- Search message history

## Stopping the Server

### Foreground Mode
Press **Ctrl+C** - automatically stops both monitor and server.

### Background Mode
```bash
pkill -f mcp_agent_mail
```

## Troubleshooting

### Server won't start
```bash
# Check logs
tail -f ~/.mcp_agent_mail_git_mailbox_repo/server.log

# Verify port is free
sudo netstat -tulpn | grep 8765
```

### Monitor not showing events
```bash
# Check if inotify-tools is installed
command -v inotifywait

# Install it
sudo pacman -S inotify-tools  # Arch
sudo apt install inotify-tools  # Debian/Ubuntu

# Check mailbox directory exists
ls -la ~/.mcp_agent_mail_git_mailbox_repo/
```

### Can't parse JSON
```bash
# Verify jq is installed
command -v jq

# Install it
sudo pacman -S jq  # Arch
sudo apt install jq  # Debian/Ubuntu
```

## Comparison with Official Scripts

Our scripts implement the same core mechanisms as the official MCP Agent Mail repository:

| Feature | Official Repo | Our Scripts |
|---------|--------------|-------------|
| `exec` for window-open | ✅ Yes | ✅ Yes (foreground mode) |
| Process cleanup traps | ✅ Yes | ✅ Yes |
| Blocking server call | ✅ `uvicorn.run()` | ✅ `inotifywait -m` |
| Rich event display | ✅ Python Rich library | ✅ ANSI color codes |
| Background mode | ✅ Yes | ✅ Yes (default) |
| Foreground mode | ✅ Yes | ✅ Yes (with flag) |

The key difference: they use Python's Rich library for formatting, we use native bash with ANSI color codes for portability.

## Examples

### Start and watch in one command
```bash
./scripts/start-agent-mail.sh foreground
```

### Start in background, monitor later
```bash
# Terminal 1
./scripts/start-agent-mail.sh

# Terminal 2 (later)
./scripts/monitor-agent-mail.sh
```

### Check if server is healthy
```bash
curl http://127.0.0.1:8765/health/liveness
# Should return: {"status":"ok"}
```

## Integration with Claude Code

These scripts are designed to work with the Claude Code + Agent Mail + Beads workflow documented in `/CLAUDE.md`.

**Session start (automatic):**
```javascript
const session = await mcp__mcp_agent_mail__macro_start_session({
  human_key: "/home/lewis/src/meal-planner",
  program: "claude-code",
  model: "claude-sonnet-4-5"
});
```

**Monitor shows:**
```
┌─────────────────────────────────────────────────────────────
│ [14:32:15] 🤖 NEW AGENT REGISTERED
├─────────────────────────────────────────────────────────────
│ Agent: BlueLake
│ Program: claude-code
│ Model: claude-sonnet-4-5
└─────────────────────────────────────────────────────────────
```

## License

These scripts are part of the meal-planner project and follow the same license as the main repository.

## Credits

Inspired by and compatible with [MCP Agent Mail](https://github.com/Dicklesworthstone/mcp_agent_mail) by @Dicklesworthstone.
