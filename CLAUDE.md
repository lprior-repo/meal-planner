# Claude Code - Agent Mail + Beads

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

## 📋 Standard Work Flow

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



## 📦 Version Control & Archiving

### Using Git History Instead of Archive Directories

The ARCHIVE/ directory was removed in favor of using git's built-in history. All archived code remains fully accessible through git:

```bash
# View files that were in ARCHIVE/
git log --all --full-history -- ARCHIVE/

# Restore a specific archived file
git show <commit>:ARCHIVE/path/to/file.gleam

# View the full history of a specific file
git log -p -- ARCHIVE/path/to/file.gleam

# Search archived code
git log --all -S "function_name" -- ARCHIVE/
```

**Benefits:**
- No duplicate code cluttering the working directory
- Full commit history and blame information preserved
- Search and restore capabilities via git
- Cleaner file structure

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



## 🔧 MCP Server Setup

**Agent Mail is configured globally** - no local setup required.

### Verify Connection
```bash
# Test Agent Mail connection
mcp__mcp_agent_mail__health_check
```

## 🔍 Common Workflows

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
| Disk Usage | 2.8GB | 3GB | Block new work |
| File Descriptors | 80% | 95% | Alert & cleanup |

## 🐛 Troubleshooting

### Database Issues

```bash
psql -d meal_planner -c "SELECT count(*) FROM pg_stat_activity WHERE datname='meal_planner';"
```

---

**Remember:** Agent Mail coordinates, Beads tracks!
