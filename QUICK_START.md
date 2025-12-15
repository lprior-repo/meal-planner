# Quick Start: Parallel Multi-Agent Development

## TL;DR - Get Running in 5 Minutes

### Terminal 1: Start Agent Mail
```bash
am server start
```

### Terminal 2: Prepare Tasks (if needed)
```bash
# Check if you have ready tasks
bd ready

# If not, create some
bd create "Feature A" -t task -p 2
bd create "Feature B" -t task -p 2
# ... up to 12 tasks
```

### Terminal 3: Launch Everything
```bash
# Check system status
./scripts/setup-parallel-dev.sh status

# Start the environment (creates worktrees, registers agents)
./scripts/setup-parallel-dev.sh start

# It will print the zellij command, something like:
# zellij -s meal-planner-agents --layout .zellij-agents.kdl
```

### Terminal 3: Launch Zellij (copy command from above)
```bash
zellij -s meal-planner-agents --layout .zellij-agents.kdl
```

**That's it!** You now have 12 Claude Code agents running in parallel.

---

## Monitor Agent Activity

### In Another Terminal:

**Watch Agent Logs:**
```bash
tail -f .agent-logs/*.log
```

**Monitor Beads Status:**
```bash
watch bd status
```

**Check Agent Mail:**
```bash
am inbox
```

---

## Commands Reference

| Command | What It Does |
|---------|-----------|
| `./scripts/setup-parallel-dev.sh start` | Create worktrees, register agents, prep environment |
| `./scripts/setup-parallel-dev.sh stop` | Kill Zellij session (preserves worktrees) |
| `./scripts/setup-parallel-dev.sh cleanup` | Remove all worktrees, logs, clean up fully |
| `./scripts/setup-parallel-dev.sh status` | Show system health (Agent Mail, Beads, Git, Zellij) |
| `zellij -s meal-planner-agents --layout .zellij-agents.kdl` | Launch agents in Zellij |
| `am inbox` | Monitor agent mail messages |
| `bd ready` | See tasks ready to work on |
| `bd status` | See task status (running, completed, etc.) |
| `git worktree list` | See all active worktrees |

---

## In Zellij Session

**Navigate panes:** `Ctrl+b` + arrow keys (or use Zellij's default keybinds)

**Each pane:** Claude Code running in a git worktree for that task

**When done:** `exit` from a pane, or `Ctrl+d`

---

## Agent Mail - What to Look For

Agents automatically:
- Reserve files before editing (prevents conflicts)
- Send updates in threads (organized by task ID)
- Report progress and blocks

**Check messages:**
```bash
am inbox
am inbox --thread bd-001  # See messages for task 001
```

---

## Beads - Track Progress

**See all tasks:**
```bash
bd status
```

**Mark task complete (from agent's worktree):**
```bash
bd close bd-001 --reason "All tests pass"
```

**Unblock downstream tasks:**
```bash
bd update bd-002 --status ready
```

---

## File Reservations - How They Work

Agent Mail automatically prevents conflicts:

1. Agent 1 reserves `src/retry.gleam`
2. Agent 2 tries to edit `src/retry.gleam` → Blocked
3. Agent 1 releases the file when done
4. Agent 2 can now edit it

**This happens automatically.** You don't manage reservations—Agent Mail does.

---

## Troubleshooting

### Agent Mail down?
```bash
am server start
```

### No ready tasks?
```bash
bd create "New Task" -t task -p 2
```

### Zellij session stuck?
```bash
zellij kill-session -s meal-planner-agents
```

### Worktree issue?
```bash
git worktree list
git worktree remove .worktrees/bd-001 --force
```

---

## Architecture in 30 Seconds

```
Beads (task queue)
  ↓
Worktrees (one per task)
  ↓
Claude Code (agents)
  ↓
Zellij (12 panes)
  ↓
Agent Mail (coordination & file locks)
```

Each agent works independently in its own git worktree. Agent Mail prevents conflicts. Beads tracks progress.

---

## What's Happening Behind the Scenes?

1. **Setup Phase** (`setup-parallel-dev.sh start`):
   - Creates git worktree for each ready Beads task
   - Registers each agent with Agent Mail
   - Updates Beads task status to "in_progress"
   - Generates Zellij layout with 12 panes

2. **Running Phase** (Zellij session):
   - Each pane runs Claude Code in its worktree
   - Each agent independently works on its task
   - Agent Mail monitors file edits and enforces reservations
   - Agents can message each other via threads

3. **Monitoring Phase** (Separate terminals):
   - `tail -f .agent-logs/` shows real-time progress
   - `am inbox` shows inter-agent messages
   - `bd status` shows task completion
   - `git worktree list` shows active branches

4. **Cleanup Phase** (`setup-parallel-dev.sh cleanup`):
   - Kills Zellij session
   - Removes all worktrees
   - Cleans up logs
   - Ensures git is clean

---

## Expected Workflow

```bash
# Day 1: Setup
./scripts/setup-parallel-dev.sh start
zellij -s meal-planner-agents --layout .zellij-agents.kdl
# Let agents work while you monitor

# Day 2: Monitor
tail -f .agent-logs/*.log
am inbox
bd status

# Day N: Wrap Up
./scripts/setup-parallel-dev.sh cleanup
git status  # Should be clean
```

---

## Advanced: Parallel Track Execution

Tasks with dependencies execute in parallel:

```
bd-001: Spec          (Agent 1)  ✓ done
  ├─ bd-002: Contract (Agent 2)  → running
  │   └─ bd-003: Code (Agent 3)  → ready to start
  ├─ bd-004: Tests    (Agent 4)  → running
  └─ bd-005: Docs     (Agent 5)  → running
```

Agents automatically pick up unblocked tasks. No manual coordination needed.

---

## Pro Tips

1. **Dedicate one terminal to logs:** `tail -f .agent-logs/*.log` (always visible)
2. **Check messages regularly:** `am inbox` (catch coordination issues early)
3. **Set Beads priorities:** Higher priority = picked up by agents first
4. **Use meaningful task titles:** Agents see these in their Claude Code workspace
5. **Commit frequently:** Each agent should commit after each behavior pass (TDD)

---

## Questions?

Read the full guide: `PARALLEL_AGENTS_GUIDE.md`

Key sections:
- **Architecture Overview** - See the full system design
- **Coordination Flow** - How agents talk to each other
- **Troubleshooting** - Common issues & fixes
- **Advanced** - Customizing Zellij, using more agents

---

**Ready? Run this:**

```bash
am server start  # Terminal 1
./scripts/setup-parallel-dev.sh start  # Terminal 2
zellij -s meal-planner-agents --layout .zellij-agents.kdl  # Terminal 2 (after setup)
tail -f .agent-logs/*.log  # Terminal 3
```

Good luck! 🚀
