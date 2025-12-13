<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# Claude Code - Agent Mail + Beads + Worktree Coordination

## 🚀 CRITICAL: Application Startup

**BEFORE ANY WORK - ALWAYS USE THE AUTOMATED STARTUP:**

```bash
# ONE COMMAND TO RULE THEM ALL
./run.sh start

# OR with go-task (preferred - install: sudo pacman -S go-task)
task start
```

This automated startup process:
1. ✅ Checks all dependencies (Gleam, PostgreSQL, Docker)
2. ✅ Verifies PostgreSQL is running
3. ✅ Creates databases (`meal_planner` for app, `tandoor` for Tandoor - separate DBs)
4. ✅ Starts Tandoor container (port 8000)
5. ✅ Builds and starts API server (port 8080)
6. ✅ Verifies all services are healthy

**Access Points:**
- **API Server:** http://localhost:8080/health
- **Tandoor UI:** http://localhost:8000

**Other useful commands:**
```bash
./run.sh status    # Check what's running
./run.sh stop      # Stop everything
./run.sh restart   # Restart all services
./run.sh logs      # View API logs

# Or with go-task:
task status
task stop
task restart
task api:logs
task tandoor:logs
```

**NEVER manually start services** - always use the automated startup!

**Database Separation:**
- `meal_planner` database = Gleam app data (2M+ USDA foods)
- `tandoor` database = Tandoor recipes and users (completely separate)

## 🔄 Automatic Session Start

**After services are running, every session AUTOMATICALLY executes:**

```javascript
// 1. Register with Agent Mail
const session = await mcp__mcp_agent_mail__macro_start_session({
  human_key: "/home/lewis/src/meal-planner",
  program: "claude-code",
  model: "claude-sonnet-4-5",
  task_description: "Session work",
  inbox_limit: 20
});
// Returns: { agent: { name: "BlueLake" }, inbox: [...] }

// 2. Load Beads context
bd ready --json          // Available work (no blockers)
bv --robot-insights     // High-impact tasks
```

## 🎯 WORKTREE COORDINATION - CRITICAL!

**Multiple AI agents can now work in parallel without conflicts!**

See `WORKTREE_COORDINATION.md` for full details.

### Quick Start: Spawn Multiple Agents

```bash
# Initialize the coordination system (one time)
./scripts/agent-coordinator.sh init

# Spawn 4 agents to work on independent tracks in parallel
./scripts/agent-coordinator.sh spawn 4 independent

# Monitor all agents
./scripts/agent-coordinator.sh monitor

# Cleanup when done
./scripts/agent-coordinator.sh cleanup
```

### How It Works

1. **Worktree Pool**: 3-10 isolated git worktrees
2. **File Filtering**: Each worktree sees only relevant files (sparse-checkout)
3. **Agent Mail**: Coordination via file reservations & messaging
4. **Resource Monitor**: Prevents exhaustion (DB connections, disk, FDs)
5. **Beads Integration**: Automatic track analysis & assignment

### File Filtering - The Key to No Conflicts!

Each worktree gets **sparse-checkout** based on its task:

```bash
# Agent 1 → web handlers only
.agent-worktrees/pool-wt-1/
  gleam/src/meal_planner/web/**/*.gleam  ✓ visible
  gleam/src/meal_planner/storage.gleam   ✗ hidden

# Agent 2 → storage only
.agent-worktrees/pool-wt-2/
  gleam/src/meal_planner/storage*.gleam  ✓ visible
  gleam/src/meal_planner/web/**/*.gleam  ✗ hidden
```

**Result**: Agents can ONLY modify files relevant to their task. No trampling!

### Manual Agent Workflow

If you need to manually work in a worktree:

```bash
# 1. Assign yourself to a track
./scripts/agent-coordinator.sh assign MyAgent meal-planner-abc123

# 2. Enter the worktree (files already filtered!)
cd .agent-worktrees/pool-wt-1

# 3. Work normally
bd update meal-planner-abc123 --status=in_progress
vim gleam/src/meal_planner/web/handlers/home.gleam  # Only visible files!
gleam test

# 4. Commit and close
git add .
git commit -m "[meal-planner-abc123] Add home handler"
bd close meal-planner-abc123
bd sync
git push
```

## 📋 Standard Work Flow (Single Agent)

### Starting New Work
```javascript
// 1. Check available work
bd ready --json
bv --robot-priority

// 2. Select and claim task
bd update bd-123 --status=in_progress

// 3. Reserve files
await mcp__mcp_agent_mail__file_reservation_paths({
  project_key: "/home/lewis/src/meal-planner",
  agent_name: session.agent.name,
  paths: ["gleam/src/**/*.gleam"],
  ttl_seconds: 3600,
  exclusive: true,
  reason: "bd-123"
});

// 4. Announce start
await mcp__mcp_agent_mail__send_message({
  project_key: "/home/lewis/src/meal-planner",
  sender_name: session.agent.name,
  to: ["coordinator"],
  thread_id: "bd-123",
  subject: "[bd-123] Starting work",
  body_md: "Working on task..."
});
```

### Completing Work
```bash
# 1. Close task
bd close bd-123 --reason "Completed"

# 2. Release files
mcp__mcp_agent_mail__release_file_reservations(...)

# 3. Final message
send_message(..., thread_id: "bd-123", body: "Completed")

# 4. Sync and push
bd sync
git add .
git commit -m "[bd-123] Implementation"
git push
```

## 🎯 Key Integrations

### Agent Mail
- **Registration**: Auto-register at session start
- **Coordination**: Thread-based messaging with `thread_id=bd-###`
- **File Safety**: Reserve files before editing with `reason=bd-###`
- **Resources**: `resource://inbox/{Agent}?project=...`

### Beads
- **Task Selection**: `bd ready --json` for available work
- **Graph Analysis**: `bv --robot-insights` for impact
- **Status Updates**: `bd update bd-### --status=...`
- **Dependencies**: `bd dep add bd-### bd-###`

### Beads Viewer Robot Flags
```bash
bv --robot-help        # AI commands
bv --robot-insights    # PageRank + critical path
bv --robot-plan        # Parallel execution tracks
bv --robot-priority    # Task recommendations
bv --robot-diff        # Progress tracking
```

### Worktree Coordination Scripts

| Script | Purpose |
|--------|---------|
| `agent-coordinator.sh` | Main orchestrator - spawn/monitor agents |
| `worktree-pool-manager.sh` | Manage 3-10 worktree pool |
| `beads-track-analyzer.sh` | Analyze parallel execution tracks |
| `agent-mail-wrapper.sh` | Agent Mail MCP integration |
| `resource-monitor.sh` | Monitor DB/disk/FD limits |
| `setup-worktree-filters.sh` | Configure sparse-checkout per worktree |

## 🛠️ Development Rules

### JavaScript Prohibition - CRITICAL RULE
**NO JAVASCRIPT FILES ALLOWED IN THIS PROJECT**

- ❌ **NEVER** create `.js` files
- ❌ **NEVER** write custom JavaScript code
- ✅ **ONLY EXCEPTION**: HTMX library (already included in base template)
- ✅ **ALL** interactivity MUST use HTMX attributes:
  - `hx-get` - GET request
  - `hx-post` - POST request
  - `hx-target` - Where to insert response
  - `hx-swap` - How to swap content (innerHTML, outerHTML, etc)
  - `hx-trigger` - What triggers the request (change, click, etc)
  - `hx-push-url` - Update browser URL

**HTMX Usage Examples:**
```html
<!-- Filter chips with server-side updates -->
<button hx-get="/api/foods/search?filter=vegetable"
        hx-target="#results"
        hx-swap="innerHTML">
  Vegetables
</button>

<!-- Dropdown with auto-submit -->
<select hx-get="/api/foods/search"
        hx-trigger="change"
        hx-target="#results"
        hx-push-url="true">
  <option value="dairy">Dairy</option>
</select>

<!-- Form with dynamic updates -->
<form hx-post="/api/logs"
      hx-target="#log-list"
      hx-swap="afterbegin">
  <input name="food_id" />
</form>
```

### File Organization
- `/gleam/src` - Gleam source
- `/gleam/test` - Tests
- `/gleam/migrations_pg` - PostgreSQL migrations
- **NEVER** save to root folder
- **NEVER** create JavaScript files

### Concurrent Execution
```javascript
// ✅ CORRECT: Batch all operations in single message
[Single Message]:
  Task("agent1", "...", "coder")
  Task("agent2", "...", "tester")
  TodoWrite({ todos: [5-10 todos] })
  Read("file1.gleam")
  Read("file2.gleam")
  Edit("file3.gleam", old, new)
  Bash("gleam test && gleam build")

// ❌ WRONG: Multiple messages
Message 1: Task(...)
Message 2: TodoWrite(...)
Message 3: Read(...)
```

## 🚨 Session Close Protocol

**MANDATORY before saying "done":**
```bash
[ ] git status
[ ] git add <files>
[ ] bd sync
[ ] git commit -m "[bd-###] Description"
[ ] bd sync
[ ] git push
```

## 🎯 Agent Coordination

### File Reservations
- Reserve **before** editing
- Use `reason="bd-###"` for traceability
- Release when done or use `ttl_seconds` for auto-expiry
- Check conflicts with other agents

### Thread Communication
- Use `thread_id="bd-###"` for all messages
- Subject format: `[bd-###] Brief description`
- Set `ack_required=true` for decisions
- Reply to threads to maintain context

### Inbox Checking
```javascript
// Check for new messages
const messages = await mcp__mcp_agent_mail__fetch_inbox({
  project_key: "/home/lewis/src/meal-planner",
  agent_name: session.agent.name,
  since_ts: "2025-12-03T00:00:00Z",
  urgent_only: false
});

// Acknowledge important messages
await mcp__mcp_agent_mail__acknowledge_message({
  project_key: "/home/lewis/src/meal-planner",
  agent_name: session.agent.name,
  message_id: 123
});
```

## 📊 Worktree Pool Workflow

### Acquiring a Worktree

**Option 1: Automatic Assignment (Recommended)**
```bash
# Let the coordinator assign you to a track
./scripts/agent-coordinator.sh spawn 1 independent

# The coordinator will:
# 1. Analyze available beads with `bd ready --json`
# 2. Find independent tracks with `bv --robot-plan`
# 3. Assign you to a worktree with appropriate file filters
# 4. Set sparse-checkout to show only relevant files
```

**Option 2: Manual Assignment**
```bash
# Check available worktrees
./scripts/worktree-pool-manager.sh status

# Acquire a specific worktree
./scripts/worktree-pool-manager.sh acquire pool-wt-1

# Configure file filters for your task
./scripts/setup-worktree-filters.sh pool-wt-1 "gleam/src/meal_planner/web/**/*.gleam"

# Enter the worktree
cd .agent-worktrees/pool-wt-1
```

### Working in Isolation

**Setup Your Environment**:
```bash
# 1. Verify sparse-checkout is active
git sparse-checkout list

# 2. Claim your task
bd update meal-planner-xyz --status=in_progress

# 3. Reserve files (optional but recommended)
# Use agent-mail to reserve files and prevent conflicts
source scripts/agent-mail-wrapper.sh
agent_mail_reserve_files "gleam/src/meal_planner/web/handlers/*.gleam" "meal-planner-xyz" 3600
```

**Development Workflow**:
```bash
# 4. Make your changes (only visible files can be edited)
vim gleam/src/meal_planner/web/handlers/recipes.gleam

# 5. Run tests in worktree
gleam test

# 6. Format and check
gleam format
gleam build

# 7. Commit in worktree
git add .
git commit -m "[meal-planner-xyz] Add recipe filtering"

# 8. Push from worktree
git push origin main  # or your branch
```

### Releasing the Worktree

**Option 1: Automatic Cleanup**
```bash
# Let coordinator handle cleanup
./scripts/agent-coordinator.sh cleanup

# This automatically:
# - Syncs any uncommitted work
# - Releases file reservations
# - Returns worktree to pool
# - Closes database connections
```

**Option 2: Manual Release**
```bash
# 1. Sync your changes back to main
cd /home/lewis/src/meal-planner  # Return to main checkout
git pull origin main

# 2. Release file reservations
source scripts/agent-mail-wrapper.sh
agent_mail_release_files "meal-planner-xyz"

# 3. Release worktree
./scripts/worktree-pool-manager.sh release pool-wt-1

# 4. Close your task
bd close meal-planner-xyz --reason "Completed in worktree pool-wt-1"
bd sync
```

### Scaling the Pool

**Monitor Pool Capacity**:
```bash
# Check pool status
./scripts/worktree-pool-manager.sh status

# Expected output:
# Worktree Pool Status:
# - Total worktrees: 5
# - Available: 2
# - In use: 3
# - Disk usage: 850MB / 3GB
```

**Scale Up (Add Worktrees)**:
```bash
# Add 2 more worktrees to pool
./scripts/worktree-pool-manager.sh scale-up 2

# Max pool size: 10 worktrees
```

**Scale Down (Remove Worktrees)**:
```bash
# Remove 1 worktree from pool (only if available)
./scripts/worktree-pool-manager.sh scale-down 1

# Min pool size: 3 worktrees
```

### Troubleshooting

**Problem: No Available Worktrees**
```bash
# Check who's using worktrees
./scripts/worktree-pool-manager.sh status

# Option 1: Wait for release
# Option 2: Scale up
./scripts/worktree-pool-manager.sh scale-up 2

# Option 3: Work in main checkout (last resort)
cd /home/lewis/src/meal-planner
```

**Problem: File Not Visible in Worktree**
```bash
# Check current sparse-checkout
git sparse-checkout list

# Add more patterns if needed
git sparse-checkout add "gleam/src/meal_planner/storage/*.gleam"

# Or reconfigure filters
./scripts/setup-worktree-filters.sh pool-wt-1 "gleam/src/**/*.gleam"
```

**Problem: Disk Space Warning**
```bash
# Check resource usage
./scripts/resource-monitor.sh status

# Clean up old build artifacts
cd .agent-worktrees/pool-wt-1
gleam clean

# If critical, scale down pool
./scripts/worktree-pool-manager.sh scale-down 2
```

**Problem: Database Connection Leaks**
```bash
# Detect leaks
./scripts/resource-monitor.sh detect-leaks

# Cleanup leaked connections
./scripts/resource-monitor.sh cleanup-leaks

# Check current connection count
psql -d meal_planner -c "SELECT count(*) FROM pg_stat_activity WHERE datname='meal_planner';"
```

### Best Practices

1. **Always Use Coordinator for Multi-Agent**: Let automation handle complexity
2. **Trust the File Filter**: If you can't see a file, you shouldn't edit it
3. **Monitor Resources**: Check pool status before long-running tasks
4. **Clean Up Properly**: Release worktrees when done (enables reuse)
5. **Commit Often in Worktree**: Don't lose work if pool gets recycled
6. **Use File Reservations**: Prevent conflicts with other agents
7. **Test in Worktree**: Run `gleam test` before pushing
8. **Watch Disk Space**: Each worktree uses ~170MB

## 🔧 MCP Server Setup

**Agent Mail is configured globally** - no local setup required.

### Verify Connection
```bash
# Test Agent Mail connection
mcp__mcp_agent_mail__health_check
```

## 🔍 Common Workflows

### Parallel Multi-Agent Work

```bash
# 1. Initialize (once)
./scripts/agent-coordinator.sh init

# 2. Analyze available tracks
./scripts/beads-track-analyzer.sh full

# 3. Spawn agents for independent tracks
./scripts/agent-coordinator.sh spawn 6 independent

# 4. Monitor progress
./scripts/agent-coordinator.sh monitor

# 5. Cleanup when complete
./scripts/agent-coordinator.sh cleanup
```

### Continue Existing Work
```javascript
// Resume work on bd-123
const thread = await mcp__mcp_agent_mail__macro_prepare_thread({
  project_key: "/home/lewis/src/meal-planner",
  thread_id: "bd-123",
  program: "claude-code",
  model: "claude-sonnet-4-5",
  llm_mode: true,
  include_inbox_bodies: true
});
// Returns: thread summary, participants, action items
```

### Coordinate with Other Agents
```javascript
// Request contact with another agent
await mcp__mcp_agent_mail__macro_contact_handshake({
  project_key: "/home/lewis/src/meal-planner",
  requester: session.agent.name,
  target: "OtherAgent",
  reason: "Need to coordinate on bd-123",
  auto_accept: false
});
```

### Handle File Conflicts
```javascript
// Check who has file reserved
const conflicts = await mcp__mcp_agent_mail__file_reservation_paths({
  project_key: "/home/lewis/src/meal-planner",
  agent_name: session.agent.name,
  paths: ["gleam/src/meal_planner/web.gleam"],
  exclusive: true,
  reason: "bd-123"
});

if (conflicts.conflicts.length > 0) {
  // Wait or coordinate with holder
  console.log("File reserved by:", conflicts.conflicts[0].holders);
}
```

## 📈 System Limits & Safety

| Resource | Warning | Critical | Action |
|----------|---------|----------|---------|
| DB Connections | 40 | 50 | Queue agents |
| Disk Usage | 2.8GB | 3GB | Block new worktrees |
| File Descriptors | 80% | 95% | Alert & cleanup |
| Worktree Pool | 3 min | 10 max | Auto-scale |

## 🐛 Troubleshooting

### No Available Worktrees

```bash
./scripts/worktree-pool-manager.sh status
./scripts/worktree-pool-manager.sh scale-up
```

### File Conflicts

```bash
source scripts/agent-mail-wrapper.sh
agent_mail_show_reservations
```

### Database Issues

```bash
./scripts/resource-monitor.sh detect-leaks
./scripts/resource-monitor.sh cleanup-leaks
```

---

**Remember:** Agent Mail coordinates, Beads tracks, Worktrees isolate, Filters protect!
