# Changes to Agent Mail Scripts

## Summary

Enhanced the Agent Mail monitoring scripts to implement the same "keep-window-open" mechanism used by the official MCP Agent Mail repository, with rich event displays similar to their Rich library-based UI.

## Key Changes

### 1. `start-agent-mail.sh` - Added Foreground Mode

**Before:**
- Only background mode
- Server started with `nohup`, script exited
- Window closed immediately

**After:**
- Two modes: `background` (default) and `foreground`
- Foreground mode uses `exec` to keep window open
- Trap-based cleanup kills server on Ctrl+C
- Usage:
  ```bash
  ./scripts/start-agent-mail.sh foreground  # Stays open
  ./scripts/start-agent-mail.sh             # Background (default)
  ```

**Key mechanism:**
```bash
# Start server in background
"$INSTALL_DIR/scripts/run_server_with_token.sh" > "$MAILBOX_DIR/server.log" 2>&1 &
SERVER_PID=$!

# Trap to cleanup on exit
cleanup() {
    kill $SERVER_PID 2>/dev/null || true
}
trap cleanup INT TERM EXIT

# Replace this process with monitor (keeps window open)
exec "$SCRIPT_DIR/monitor-agent-mail.sh"
```

### 2. `monitor-agent-mail.sh` - Rich Event Display

**Before:**
- Simple one-line event messages
- No visual hierarchy
- Minimal information

**After:**
- Boxed event displays with borders
- Color-coded by event type
- Detailed information extraction
- Visual hierarchy with icons

**Example transformation:**

**Old:**
```
[14:32:15] 📧 New message: [bd-123] Starting work
   From: BlueLake → To: coordinator
```

**New:**
```
┌─────────────────────────────────────────────────────────────
│ [14:32:15] 📧 NEW MESSAGE
├─────────────────────────────────────────────────────────────
│ Subject: [bd-123] Starting work
│ From: BlueLake → To: coordinator
│ Thread: bd-123
│ File: 2025-12-04_143215_msg_001.md
└─────────────────────────────────────────────────────────────
```

### 3. Database Statistics Display

Added `show_stats()` function that displays real-time counts:
```
═══ 📊 Database Statistics ═══
  Projects: 1 │ Agents: 3 │ Messages: 47 │ Reservations: 2
```

### 4. Enhanced Event Details

#### Agent Registration (Green Box)
- Shows program name (claude-code, cursor, etc.)
- Shows model (claude-sonnet-4-5, gpt-4, etc.)
- Shows current task description
- Parses profile.json for full details

#### Message Events (Blue/Red Box)
- Blue for normal importance
- Red with 🚨 for high/urgent importance
- Shows subject, from, to, thread, file
- Parses markdown headers

#### File Reservations (Yellow Box)
- Shows agent name
- Shows path pattern
- Shows reason (e.g., "bd-123")
- Distinguishes exclusive (🔐) vs shared (🔒) locks

#### File Releases (Green Box)
- Shows which agent released
- Shows what path was freed
- Makes it clear resources are available

## Technical Implementation

### How the Window Stays Open

Three key mechanisms (same as official MCP Agent Mail):

1. **`exec` Command** - Replaces current shell process
   ```bash
   exec "$SCRIPT_DIR/monitor-agent-mail.sh"
   ```
   This is critical! Without `exec`, the script would return and close the window.

2. **Trap-Based Cleanup** - Ensures server stops on exit
   ```bash
   trap cleanup INT TERM EXIT
   ```
   Catches Ctrl+C, terminal close, or script exit.

3. **Blocking Monitor Loop** - Runs forever until killed
   ```bash
   inotifywait -m -r ... | while read ...; do
       # Process events infinitely
   done
   ```
   The `-m` (monitor) flag makes inotifywait run continuously.

### Color Coding

- **Green** - Positive actions (new agent, file released)
- **Blue** - Normal messages
- **Red** - Urgent messages, errors
- **Yellow** - File reservations (locks)
- **Cyan** - Informational elements (paths, URLs)
- **Dim** - Secondary information

### Box Drawing

Uses Unicode box-drawing characters:
- `┌─` Top left corner + horizontal line
- `│` Vertical line
- `├─` Left T-junction + horizontal line
- `└─` Bottom left corner + horizontal line

## File Structure

```
scripts/
├── start-agent-mail.sh      # Main launcher (enhanced with fg mode)
├── monitor-agent-mail.sh    # Standalone monitor (enhanced display)
├── README.md                # Comprehensive documentation
└── CHANGES.md               # This file
```

## Usage Examples

### Foreground Mode (Window Stays Open)
```bash
./scripts/start-agent-mail.sh foreground
```
Output:
```
Starting Agent Mail server in FOREGROUND mode...
Press Ctrl+C to stop both server and monitor

✓ Server is ready and responding

Web UI: http://127.0.0.1:8765/mail
Server PID: 12345
Logs: ~/.mcp_agent_mail_git_mailbox_repo/server.log

╔════════════════════════════════════════════════════════════════╗
║    📬 Agent Mail Live Monitor - Press Ctrl+C to exit 📬       ║
╚════════════════════════════════════════════════════════════════╝

📁 Monitoring: ~/.mcp_agent_mail_git_mailbox_repo
🌐 Web UI: http://127.0.0.1:8765/mail
👁  Watching for changes in real-time...

═══ 📊 Database Statistics ═══
  Projects: 1 │ Agents: 2 │ Messages: 35 │ Reservations: 1

[... live events appear here ...]
```

Press Ctrl+C → Server stops automatically, window closes.

### Background Mode (Original Behavior)
```bash
./scripts/start-agent-mail.sh
```
Output:
```
✓ Server is ready and responding

Web UI: http://127.0.0.1:8765/mail
Logs: ~/.mcp_agent_mail_git_mailbox_repo/server.log

To watch live activity:
  ./scripts/monitor-agent-mail.sh

To start in foreground mode next time:
  ./scripts/start-agent-mail.sh foreground
```

## Benefits

1. **Persistent Visibility** - Window stays open showing live activity
2. **Better Debugging** - See exactly when events occur
3. **Rich Context** - Full event details in structured format
4. **Graceful Cleanup** - Server automatically stops on exit
5. **Flexible Modes** - Choose foreground or background as needed

## Compatibility

- Works on Linux (tested on Arch)
- Requires bash 4.0+
- Uses standard ANSI color codes (works in most terminals)
- Falls back to polling if inotify-tools not installed

## Inspired By

Official MCP Agent Mail repository mechanisms:
- `/scripts/automatically_detect_all_installed_coding_agents_and_install_mcp_agent_mail_in_all.sh` (lines 183-202)
- `/scripts/run_server_with_token.sh`
- `/src/mcp_agent_mail/cli.py` (lines 550-574) - `uvicorn.run()` blocking
- `/src/mcp_agent_mail/rich_logger.py` (lines 709-858) - startup banner

Our implementation adapts these concepts for bash scripts while maintaining the same user experience.
