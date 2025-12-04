---
name: claude-code-session
description: "Claude Code configuration for automatic Agent Mail registration and Beads integration"
color: blue
---

# Claude Code - Agent Mail + Beads Integration

## 🚀 Automatic Session Start

**Every session AUTOMATICALLY executes:**

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

## 🛠️ Development Rules

### File Organization
- `/gleam/src` - Gleam source
- `/gleam/test` - Tests
- `/gleam/migrations_pg` - PostgreSQL migrations
- **NEVER** save to root folder

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

## 📊 Best Practices

### Task Selection
1. Run `bv --robot-priority` for recommendations
2. Check `bd ready` for available work
3. Review dependencies with `bd show bd-###`
4. Select highest-impact unblocked task

### Coordination
1. Register at session start (automatic)
2. Reserve files before editing
3. Use thread IDs matching Beads issues
4. Check inbox between tasks
5. Release reservations when done

### Quality
- Write tests first (TDD)
- Keep files under 500 lines
- Never hardcode secrets
- Use descriptive commit messages

## 🔧 MCP Server Setup

**Required:**
```bash
claude mcp add mcp-agent-mail npx mcp-agent-mail mcp start
```

### Verify Installation
```bash
# Check MCP server is running
claude mcp list

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

---

**Remember:** Agent Mail coordinates, Beads tracks, Claude Code creates!
