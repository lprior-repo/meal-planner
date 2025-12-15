# Parallel Multi-Agent Development Guide

This guide walks you through setting up and running 12 parallel Claude Code agents using git worktrees, Zellij, Beads, and Agent Mail MCP.

## Architecture Overview

```
┌─ Main Repository ─────────────────────────────────────┐
│                                                        │
│  ┌─ Beads (Task Queue) ──────────────────────┐        │
│  │  bd-001: Feature A                        │        │
│  │  bd-002: Feature B                        │        │
│  │  ... (up to 12 ready tasks)               │        │
│  └───────────────────────────────────────────┘        │
│                                                        │
│  ┌─ Git Worktrees ───────────────────────────┐        │
│  │  .worktrees/bd-001/  (claude-code)        │        │
│  │  .worktrees/bd-002/  (claude-code)        │        │
│  │  ...                                      │        │
│  └───────────────────────────────────────────┘        │
│                                                        │
│  ┌─ Zellij Session (12 Panes) ───────────────┐        │
│  │  [Agent 1] [Agent 2] [Agent 3]            │        │
│  │  [Agent 4] [Agent 5] [Agent 6]            │        │
│  │  [Agent 7] [Agent 8] [Agent 9]            │        │
│  │  [Agent 10] [Agent 11] [Agent 12]         │        │
│  └───────────────────────────────────────────┘        │
│                                                        │
│  ┌─ Agent Mail MCP (Coordination) ───────────┐        │
│  │  Reservations: agent-bd-001 → src/**     │        │
│  │  Messages: [bd-001] Starting work...     │        │
│  │  Threads: Each task has a thread         │        │
│  └───────────────────────────────────────────┘        │
│                                                        │
└────────────────────────────────────────────────────────┘
```

## Prerequisites

### Required Tools

1. **Git** (with worktree support)
   ```bash
   git --version  # Should be 2.7.0+
   ```

2. **Beads** (issue tracking)
   ```bash
   cargo install --git https://github.com/steveyegge/beads
   bd --version
   ```

3. **Zellij** (terminal multiplexer)
   ```bash
   cargo install zellij
   zellij --version
   ```

4. **Agent Mail MCP** (coordination)
   ```bash
   am --version
   ```

5. **jq** (JSON processing)
   ```bash
   jq --version
   ```

6. **Claude Code** or **VS Code** (editor for agents)
   ```bash
   code --version  # Or: which claude-code
   ```

### Installation

```bash
# Install all prerequisites at once
cargo install beads zellij

# macOS
brew install jq

# Linux (Ubuntu/Debian)
sudo apt-get install jq

# VS Code
# Download from https://code.visualstudio.com/
```

## Step 1: Verify Agent Mail is Running

Agent Mail coordinates file reservations and messaging between agents.

**Terminal 1 (Agent Mail Server):**
```bash
# Start the agent-mail MCP server
am server start
```

You should see:
```
[agent-mail] Server listening on http://127.0.0.1:8765
```

**Terminal 2 (Agent Mail Monitor):**
```bash
# In a separate terminal, monitor incoming/outgoing messages
am inbox

# You can also watch for specific agent:
am inbox --agent agent-bd-001
```

**Verify it's working:**
```bash
curl http://127.0.0.1:8765/health
# Should return: 200 OK
```

## Step 2: Prepare Beads Tasks

Create or ensure you have ready tasks in Beads:

```bash
# See current tasks
bd status

# Get tasks that are ready to work on
bd ready

# Create a new task if needed
bd create "Feature: Add retry logic" -t task -p 2

# View as JSON (what the launcher uses)
bd ready --json
```

Example output:
```json
[
  {
    "id": "bd-001",
    "title": "Feature: Add retry logic",
    "status": "ready",
    "priority": 2
  },
  {
    "id": "bd-002",
    "title": "Fix: Handle 429 responses",
    "status": "ready",
    "priority": 2
  }
  ...
]
```

**You need at least 1 ready task, up to 12.**

## Step 3: Start the Parallel Environment

**Terminal 3 (Main orchestrator):**

```bash
# Check the current status
./scripts/setup-parallel-dev.sh status

# Expected output:
# ✓ Agent Mail:       Running
# ✓ Beads:            Ready (8 tasks)
# ✓ Git:              Clean
# ✓ Zellij:           Installed
#   Active Worktrees: 1
#   Ready Tasks:      8
```

If all systems are green, start the environment:

```bash
./scripts/setup-parallel-dev.sh start

# This will:
# 1. Create git worktrees for each task
# 2. Register agents with Agent Mail
# 3. Update Beads task status to "in_progress"
# 4. Generate a Zellij layout
# 5. Show you next steps
```

## Step 4: Launch Zellij Session with All Agents

The startup script will tell you the exact command. Typically:

```bash
zellij -s meal-planner-agents --layout .zellij-agents.kdl
```

This launches a single Zellij session with 12 panes, each running an agent in its own worktree.

**In the Zellij session:**
- Use `Ctrl+b` (or configured prefix) to navigate panes
- Each pane shows Claude Code running in a separate git worktree
- Claude Code will be positioned to the ready task via Beads ID

## Step 5: Monitor Agent Activity

### Check Agent Mail Messages

```bash
# See all inbox messages
am inbox

# See messages in specific thread (task ID)
am inbox --thread bd-001

# Send a message from one agent to broadcast
am send "All agents: Sync up!" --recipients broadcast --thread bd-001
```

### Check Beads Task Status

```bash
# Real-time status updates
bd status

# Focus on in-progress tasks
bd ready --filter 'status:in_progress'

# See which agent is working on what
bd ready --json | jq '.[] | select(.status == "in_progress")'
```

### Monitor Agent Logs

```bash
# Watch all agent logs in real-time
tail -f .agent-logs/*.log

# Follow a specific agent
tail -f .agent-logs/bd-001.log

# Or use your favorite log monitor
watch 'ls -la .agent-logs/'
```

### Check Worktree Status

```bash
# See all active worktrees
git worktree list

# View which files are reserved per worktree
ls -la .worktrees/

# Check git status in a worktree
cd .worktrees/bd-001 && git status
```

## Step 6: Agent Coordination Flow

### How Agents Coordinate

1. **File Reservations (Agent Mail)**
   - Agent reserves files before editing
   - Example: `agent-bd-001` reserves `src/retry.gleam`
   - Other agents see the reservation and avoid editing the same file

2. **Task Status Updates (Beads)**
   - Agent marks task as "in_progress"
   - As agent completes, updates to "completed"
   - Blocks downstream tasks if dependencies exist

3. **Messaging (Agent Mail)**
   - Agents send updates in thread `bd-001`
   - Example: `[bd-001] Completed retry logic, ready for testing`
   - Other agents see the message and can pick related tasks

4. **Sync Points (Git)**
   - Each agent commits in their worktree
   - Commits automatically sync back to main branch
   - No merge conflicts due to file reservations

### Example: Multi-Agent Workflow

```
bd-001: Architecture (Coder)
  ↓ commits interface
  └→ [bd-002] Contracts (Tests)
      ↓ commits tests
      └→ [bd-003] Implementation (Dev)
          ↓ commits code
          └→ [bd-004] Refactor (Quality)
              ↓ commits improvements
              └→ [bd-005] Review (Reviewer)
```

Agents work in parallel on independent tasks, handoff via message threads.

## Step 7: Completing Work

### When an Agent Finishes a Task

In Claude Code (or terminal in pane):

```bash
# 1. Commit the work
git add .
git commit -m "PASS: [bd-001] Added retry logic"

# 2. Mark task as complete in Beads
bd close bd-001 --reason "Completed: All tests passing"

# 3. Send completion message
am send "Completed retry logic, ready for integration" --thread bd-001
```

### Monitor Downstream Tasks

```bash
# Check if any tasks became unblocked
bd ready --json

# Update status for newly-ready tasks
bd update bd-002 --status ready
```

## Step 8: Shutdown and Cleanup

### When All Agents Are Done

**Terminal 3:**

```bash
# Stop the Zellij session and clean up worktrees
./scripts/setup-parallel-dev.sh stop

# Or, to fully clean (remove logs, worktrees, etc.)
./scripts/setup-parallel-dev.sh cleanup

# Verify git is clean
git status
git worktree list  # Should show only main branch
```

### Manual Cleanup (if needed)

```bash
# Kill a specific Zellij session
zellij kill-session -s meal-planner-agents

# Remove a worktree manually
git worktree remove .worktrees/bd-001 --force

# Clear all agent logs
rm -rf .agent-logs/
```

## Configuration

Edit `scripts/parallel-agents-config.env` to customize:

```bash
# Maximum parallel agents (default: 12)
MAX_AGENTS=12

# Agent Mail server address
AGENT_MAIL_URL=http://127.0.0.1:8765

# Zellij session name
ZELLIJ_SESSION_NAME=meal-planner-agents

# File reservation TTL (seconds)
RESERVATION_TTL_SECONDS=3600

# Log directory
LOG_DIR=.agent-logs
```

## Troubleshooting

### Agent Mail Not Running
```bash
# Check if server is up
curl http://127.0.0.1:8765/health

# Start it
am server start

# Or in background
nohup am server start > ~/.am.log 2>&1 &
```

### No Ready Tasks
```bash
# Create some tasks
bd create "Task 1" -t task -p 2
bd create "Task 2" -t task -p 2

# Or mark existing as ready
bd update <task-id> --status ready
```

### Worktree Creation Fails
```bash
# Check git status
git status

# Ensure main branch is up to date
git fetch origin
git pull --rebase

# Manually create worktree
git worktree add .worktrees/bd-001 origin/main
```

### File Reservation Conflict
```bash
# Check who has the reservation
am inbox --filter 'reservation'

# Wait for TTL to expire (default 1 hour)
# Or send message to release agent
am send "Please release src/retry.gleam" --agent agent-bd-001
```

### Zellij Session Stuck
```bash
# List sessions
zellij list-sessions

# Kill the session
zellij kill-session -s meal-planner-agents

# Restart
zellij -s meal-planner-agents --layout .zellij-agents.kdl
```

## Environment Variables

Set these in your shell or in `parallel-agents-config.env`:

```bash
# Maximum agents (overrides config)
export MAX_AGENTS=12

# Agent Mail URL
export AGENT_MAIL_URL=http://127.0.0.1:8765

# Zellij session name
export ZELLIJ_SESSION_NAME=meal-planner-agents

# Claude Code model
export CLAUDE_CODE_MODEL=claude-opus-4.1

# Debug
export DEBUG_MODE=true
export VERBOSE_LOGGING=true
```

## Advanced: Custom Zellij Layout

Edit `.zellij-agents.kdl` for custom pane arrangement:

```kdl
layout {
    pane split_direction="vertical" {
        pane split_direction="horizontal" {
            pane { command: "agent-runner.sh" "bd-001"; }
            pane { command: "agent-runner.sh" "bd-002"; }
        }
        pane split_direction="horizontal" {
            pane { command: "agent-runner.sh" "bd-003"; }
            pane { command: "agent-runner.sh" "bd-004"; }
        }
    }
}
```

Then launch with:
```bash
zellij -s meal-planner-agents --layout .zellij-agents.kdl
```

## FAQs

**Q: Can I run more than 12 agents?**
A: Yes! Set `MAX_AGENTS=20` in the config. Note: Zellij panes become harder to see with many agents.

**Q: What happens if two agents try to edit the same file?**
A: Agent Mail's file reservation system prevents this. If agent-2 tries to reserve a file already reserved by agent-1, it will be blocked.

**Q: Can agents work on the same task?**
A: No, by design. Each task (Beads ID) maps to one worktree. If you need collaborative work, use file reservations and message coordination.

**Q: Do I need all three terminals (Agent Mail, Monitor, Orchestrator)?**
A: You can run Agent Mail in the background. The monitor is optional. The orchestrator is essential for setup.

**Q: What if an agent crashes?**
A: The worktree and logs are preserved. Run `./scripts/setup-parallel-dev.sh start` again to restart failed agents.

**Q: Can I use this with GitHub Actions/CI?**
A: Yes! The `bd sync` command syncs all state. Use that in your CI to report progress back to Beads.

## Next Steps

1. **Verify Setup**
   ```bash
   ./scripts/setup-parallel-dev.sh status
   ```

2. **Create Test Tasks**
   ```bash
   bd create "Test Agent 1" -t task -p 2
   bd create "Test Agent 2" -t task -p 2
   ```

3. **Launch Environment**
   ```bash
   ./scripts/setup-parallel-dev.sh start
   ```

4. **Monitor Activity**
   ```bash
   tail -f .agent-logs/*.log
   am inbox
   bd status
   ```

5. **Watch Agents Work**
   ```bash
   zellij -s meal-planner-agents
   ```

Good luck! 🚀
