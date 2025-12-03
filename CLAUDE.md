---
name: claude-code-session
description: "Claude Code configuration for automatic Agent Mail registration, Beads integration, and SPARC methodology"
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
- `/gleam/migrations` - SQL migrations
- **NEVER** save to root folder

### Concurrent Execution
```javascript
// ✅ CORRECT: Batch all operations
[Single Message]:
  Task("agent1", "...", "coder")
  Task("agent2", "...", "tester")
  TodoWrite({ todos: [5-10 todos] })
  Write("file1.gleam")
  Write("file2.gleam")
  Bash("command1 && command2")

// ❌ WRONG: Multiple messages
Message 1: Task(...)
Message 2: TodoWrite(...)
Message 3: Write(...)
```

### SPARC Methodology
```bash
# TDD workflow
npx claude-flow sparc tdd "feature"

# Individual phases
npx claude-flow sparc run spec-pseudocode "task"
npx claude-flow sparc run architect "task"
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

### Thread Communication
- Use `thread_id="bd-###"` for all messages
- Subject format: `[bd-###] Brief description`
- Set `ack_required=true` for decisions

### Inbox Checking
```javascript
// Check for new messages
const messages = await mcp__mcp_agent_mail__fetch_inbox({
  project_key: "/home/lewis/src/meal-planner",
  agent_name: session.agent.name,
  since_ts: "2025-12-03T00:00:00Z",
  urgent_only: false
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
- Use SPARC for complex features
- Keep files under 500 lines
- Never hardcode secrets

## 🔧 MCP Servers

**Required:**
```bash
claude mcp add mcp-agent-mail npx mcp-agent-mail mcp start
```

**Optional:**
```bash
claude mcp add claude-flow npx claude-flow@alpha mcp start
claude mcp add ruv-swarm npx ruv-swarm mcp start
```

---

**Remember:** Agent Mail coordinates, Beads tracks, Claude Code creates!
