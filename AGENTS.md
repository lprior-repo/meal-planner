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

# AI Feedback Loops - Fractal Development System

## 🚨 MANDATORY FIRST STEP: Agent Mail Registration

**BEFORE doing ANY work, agents MUST register with Agent Mail MCP:**

```python
# 1. Ensure project exists
ensure_project(project_key="/home/lewis/src/meal-planner")

# 2. Register agent identity (auto-generates adjective+noun name)
register_agent(
    project_key="/home/lewis/src/meal-planner",
    program="claude-code",
    model="opus-4.1",
    task_description="Your current task"
)
# Returns: {"agent_name": "GreenCastle", ...}
```

**Agent Mail server is ALREADY RUNNING - never start a server.**

## MCP Agent Mail: Coordination for Multi-Agent Workflows

### What it is
- A mail-like layer that lets coding agents coordinate asynchronously via MCP tools and resources
- Provides identities, inbox/outbox, searchable threads, and advisory file reservations
- Human-auditable artifacts stored in Git

### Why it's useful
- Prevents agents from stepping on each other with explicit file reservations (leases) for files/globs
- Keeps communication out of your token budget by storing messages in a per-project archive
- Offers quick reads (`resource://inbox/...`, `resource://thread/...`) and macros that bundle common flows

### How to use effectively

#### Same Repository
- **Register identity**: Call `ensure_project`, then `register_agent` using this repo's absolute path as `project_key`
- **Reserve files before editing**: `file_reservation_paths(project_key, agent_name, ["src/**"], ttl_seconds=3600, exclusive=true)`
- **Communicate with threads**: Use `send_message(..., thread_id="bd-123")`; check inbox with `fetch_inbox`
- **Read fast**: `resource://inbox/{Agent}?project=<abs-path>&limit=20` or `resource://thread/{id}?project=<abs-path>&include_bodies=true`

#### Across Different Repos (e.g., Next.js frontend + FastAPI backend)
- **Option A (single project bus)**: Register both under same `project_key`; keep patterns specific (`frontend/**` vs `backend/**`)
- **Option B (separate projects)**: Each repo has own `project_key`; use `macro_contact_handshake` to link agents

#### Macros vs Granular Tools
- **Prefer macros for speed**: `macro_start_session`, `macro_prepare_thread`, `macro_file_reservation_cycle`, `macro_contact_handshake`
- **Use granular tools for control**: `register_agent`, `file_reservation_paths`, `send_message`, `fetch_inbox`, `acknowledge_message`

### Common Pitfalls
- "from_agent not registered": Always `register_agent` in correct `project_key` first
- "FILE_RESERVATION_CONFLICT": Adjust patterns, wait for expiry, or use non-exclusive reservation
- Auth errors: If JWT+JWKS enabled, include bearer token with `kid` matching server JWKS

## Integrating with Beads (Dependency-Aware Task Planning)

Beads provides lightweight, dependency-aware issue database and CLI (`bd`) for selecting "ready work," setting priorities, and tracking status. It complements MCP Agent Mail's messaging, audit trail, and file-reservation signals.

**Project**: [steveyegge/beads](https://github.com/steveyegge/beads)

### Recommended Conventions
- **Single source of truth**: Use **Beads** for task status/priority/dependencies; use **Agent Mail** for conversation, decisions, attachments
- **Shared identifiers**: Use Beads issue id (e.g., `bd-123`) as Mail `thread_id` and prefix subjects with `[bd-123]`
- **Reservations**: When starting `bd-###` task, call `file_reservation_paths(...)` with issue id in `reason`; release on completion

### Typical Flow (Agents)
1. **Pick ready work** (Beads): `bd ready --json` → choose one item (highest priority, no blockers)
2. **Reserve edit surface** (Mail): `file_reservation_paths(project_key, agent_name, ["src/**"], ttl_seconds=3600, exclusive=true, reason="bd-123")`
3. **Announce start** (Mail): `send_message(..., thread_id="bd-123", subject="[bd-123] Start: <short title>", ack_required=true)`
4. **Work and update**: Reply in-thread with progress; attach artifacts/images
5. **Complete and release**:
   - `bd close bd-123 --reason "Completed"`
   - `release_file_reservations(project_key, agent_name, paths=["src/**"])`
   - Final Mail reply: `[bd-123] Completed` with summary

### Mapping Cheat-Sheet
- **Mail `thread_id`** ↔ `bd-###`
- **Mail subject**: `[bd-###] …`
- **File reservation `reason`**: `bd-###`
- **Commit messages**: Include `bd-###` for traceability

### Event Mirroring (Optional Automation)
- On `bd update --status blocked`, send high-importance Mail message in thread `bd-###`
- On Mail "ACK overdue" for critical decision, add Beads label (e.g., `needs-ack`) or bump priority

### Pitfalls to Avoid
- Don't create or manage tasks in Mail; treat Beads as single task queue
- Always include `bd-###` in message `thread_id` to avoid ID drift

## Beads Viewer (bv) — AI-Friendly Task Analysis

**Beads Viewer** (`bv`) is a fast terminal UI that provides robot flags designed for AI agent integration.

**Project**: [Dicklesworthstone/beads_viewer](https://github.com/Dicklesworthstone/beads_viewer)

### Why bv for Agents?
While `bd` handles task CRUD operations, `bv` provides precomputed graph analytics:
- **PageRank scores**: Identify high-impact tasks that unblock most downstream work
- **Critical path analysis**: Find longest dependency chain to completion
- **Cycle detection**: Spot circular dependencies before deadlocks
- **Parallel track planning**: Determine which tasks can run concurrently

### Robot Flags for AI Integration

| Flag | Output | Agent Use Case |
|------|--------|----------------|
| `bv --robot-help` | All AI-facing commands | Discovery / capability check |
| `bv --robot-insights` | PageRank, betweenness, HITS, critical path, cycles | Quick triage: "What's most impactful?" |
| `bv --robot-plan` | Parallel tracks, items per track, unblocks lists | Execution planning: "What can run in parallel?" |
| `bv --robot-priority` | Priority recommendations with reasoning + confidence | Task selection: "What should I work on next?" |
| `bv --robot-recipes` | Available filter presets (actionable, blocked, etc.) | Workflow setup: "Show me ready work" |
| `bv --robot-diff --diff-since <ref>` | Changes since commit/date, new/closed items, cycles | Progress tracking: "What changed?" |

### Example: Agent Task Selection Workflow
```bash
# 1. Get priority recommendations with reasoning
bv --robot-priority

# 2. Check what completing a task would unblock
bv --robot-plan

# 3. After completing work, check what changed
bv --robot-diff --diff-since "1 hour ago"
```

### When to Use bv vs bd

| Tool | Best For |
|------|----------|
| `bd` | Creating, updating, closing tasks; `bd ready` for simple "what's next" |
| `bv` | Graph analysis, impact assessment, parallel planning, change tracking |

**Rule of thumb**: Use `bd` for task operations, use `bv` for task intelligence.

### Integration with Agent Mail
Combine `bv` insights with Agent Mail coordination:

1. Agent A runs `bv --robot-priority` → identifies `bd-42` as highest-impact
2. Agent A reserves files: `file_reservation_paths(..., reason="bd-42")`
3. Agent A announces: `send_message(..., thread_id="bd-42", subject="[bd-42] Starting high-impact refactor")`
4. Other agents see reservation and Mail announcement, pick different tasks
5. Agent A completes, runs `bv --robot-diff` to report downstream unblocks

This creates feedback loop where graph intelligence drives coordination.

## Development Guidelines

### Critical Rules
- **Use fractal for design and implementation**: Never bypass the fractal methodology
- **Never generate markdown unless explicitly asked**: No documentation files without request
- **Capture leftover issues in Beads**: All incomplete work must be filed as beads before session ends

## The Fractal Structure

The system is recursive. At every level, the pattern is the same: **attempt, verify, feedback, retry**. The only thing that changes is the granularity.

```
Outer loop:  Feature    → Shipped
Middle loop: Capability → Integrated
Inner loop:  Behavior   → Implemented
Micro loop:  Change     → Verified
```

Each level contains multiple iterations of the level below it.

## Spec Refinement Loops

The spec stage is a series of nested loops that progressively build understanding and artifacts.

### Loop 1: Clarification
- **Input**: Raw intent (e.g., "add retry logic to client")
- **AI Role**: Ask clarifying questions, not answer them
- **Output**: Clarified intent with decisions recorded
- **Agent**: `/clarify`

### Loop 2: Research
- **Input**: Clarified intent
- **AI Role**: Investigate codebase using Serena tools
- **Output**: Research summary with code references
- **Agent**: `/research`

### Loop 3: Architecture Review
- **Input**: Clarified intent + research
- **AI Role**: Propose approach, where code lives, interfaces touched
- **Output**: Architectural decision record
- **Agent**: `/architecture`

### Loop 4: Artifact Generation
- **Input**: Everything above
- **AI Role**: Generate spec, Beads issues, acceptance criteria
- **Output**: Complete spec + Beads issues ready to pull
- **Agent**: `/artifacts`

### Loop 5: Shared Understanding
- **Input**: All artifacts
- **AI Role**: Summarize back what we're building
- **Output**: Locked spec with human confirmation
- **Agent**: Part of `/artifacts` flow

## Implementation Loops

Implementation follows TDD and TCR (Test, Commit, Revert) discipline.

### Loop 1: Contract First
- **Input**: Spec with API contract
- **AI Role**: Write interface/type definitions only
- **Output**: Committed interface + failing tests
- **Agent**: `/contract`

### Loop 2: Red-Green-Refactor (per behavior)

**Red Phase** (`/tdd-red`):
- Write one failing test for one specific behavior
- Test must be minimal, testing exactly one thing
- Commit the failing test

**Green Phase** (`/tdd-green`):
- Write minimal code to make test pass
- Emphasis on minimal, not clever
- If pass → commit; if fail → adjust or revert

**Refactor Phase** (`/tdd-refactor`):
- Look for improvement opportunities
- Run tests after each refactor step
- If tests fail → revert immediately (TCR)

### Loop 3: Hooks and Gates
After each commit, automated checks run:
- Per-change: Format, basic lint (milliseconds)
- Per-commit: Full lint, type check, unit tests (seconds)
- Per-batch: Integration tests, security scan (minutes)
- Per-capability: Full suite, performance tests (minutes-hours)

### Loop 4: Batch Verification
- Run integration tests after several behaviors
- Contract tests to verify API spec
- Human reviews the batch

### Loop 5: Capability Completion
- All behaviors implemented
- All tests pass
- Human final review
- Mark Beads issue done

## TCR Discipline

**The Rule**: If tests pass → commit immediately. If tests fail → revert immediately.

No debugging broken code. Revert and try a smaller change. This forces tiny steps where either they work or the revert cost is trivial.

## Feedback Arrows

At any point, feedback flows backward:

```
TDD-green fails N times → Is test wrong? → Back to TDD-red
                       → Is contract wrong? → Back to contract loop
                       → Is spec wrong? → Back to spec refinement

Integration fails → Is implementation wrong? → Back to TDD
                 → Is contract wrong? → Back to contract
                 → Is architecture wrong? → Back to architecture
```

**Principle**: Fix at the source. Don't paper over a spec problem with implementation hacks.

## State Tracking

Work items track position in nested structure:

```yaml
WorkItem:
  id: "retry-transient-errors"
  feature: "add-retry-logic"
  stage: "implementing"  # spec_refinement | implementing | review | deploy

  # Spec sub-state
  spec_loop: "complete"  # clarifying | researching | architecture | artifacts

  # Implementation sub-state
  impl_loop: "tdd"       # contract | tdd | batch_verify | capability_verify
  tdd_phase: "green"     # red | green | refactor
  current_behavior: "exponential-backoff"
  behaviors_complete: ["retry-once", "retry-max-3"]
  behaviors_remaining: ["retry-429", "retry-504"]
```

## Slash Commands

### Orchestration
- `/fractal-loop <task>` - Complete SDLC orchestrator with parallel agents, MCP coordination, and Beads tracking
- `/flow <task>` - Full orchestrator, guides through all loops
- `/plan <task>` - Decompose into atomic beads

### Spec Refinement
- `/clarify <task>` - Run clarification loop, output questions
- `/research <task>` - Investigate codebase, output findings
- `/architecture <task>` - Propose approach, output decision record
- `/artifacts <task>` - Generate spec + Beads issues

### Implementation
- `/contract <capability>` - Write interfaces and failing tests
- `/tdd-red <behavior>` - Write one failing test
- `/tdd-green` - Make current failing test pass
- `/tdd-refactor` - Improve without changing behavior

### Session Management
- `/land` - Execute complete "Landing the Plane" workflow (mandatory session end)

## Agent Modes Summary

| Mode | AI Job | Output |
|------|--------|--------|
| Clarification | Ask questions | Questions for human |
| Research | Investigate codebase | Findings with code refs |
| Architecture | Propose approach | Decision record |
| Artifact | Generate documents | Spec, Beads, test criteria |
| Contract | Write interfaces | Type definitions, signatures |
| TDD-Red | Write failing test | Test code |
| TDD-Green | Make test pass | Implementation code |
| TDD-Refactor | Improve code | Refactored code |
| Quality-Loop | Multi-layer validation | Quality report with issues |

## Landing the Plane (Session End Protocol)

**The plane is NOT landed until git push succeeds. NO EXCEPTIONS.**

### Seven-Step Mandatory Workflow

1. **File Remaining Issues**: Create beads for any incomplete work
   ```bash
   bd create "Description of remaining work" -t task -p 2 --json
   ```

2. **Run Quality Gates**: Execute all quality checks
   ```bash
   go test ./...      # All tests must pass
   go build          # Build must succeed
   make lint         # Linting must pass
   ```
   If any fail: `bd create "Fix [issue]" -t bug -p 0 --json`

3. **Update Beads Issues**: Close completed work, update in-progress
   ```bash
   bd close <id> --reason "Completed" --json
   ```

4. **PUSH TO REMOTE (MANDATORY)**:
   ```bash
   git pull --rebase
   # If conflicts in .beads/beads.jsonl:
   #   git checkout --theirs .beads/beads.jsonl && bd import
   bd sync
   git push       # MANDATORY - PLANE NOT LANDED WITHOUT THIS
   git status     # MUST show "up to date with origin"
   ```

5. **Clean Git State**:
   ```bash
   git stash clear
   git remote prune origin
   ```

6. **Verify Clean State**: `git status` must show "up to date" and "working tree clean"

7. **Choose Follow-Up Work**: `bd ready --json`

**CRITICAL**: Never say "ready to push" - YOU must execute `git push` successfully.

## MCP Tools Integration

### Serena (Code Navigation) - MANDATORY

**NEVER read entire files. Use symbol-aware tools:**

- `get_symbols_overview(file_path)` - Get file structure
- `find_symbol(name, file_path, include_body)` - Find specific symbol
- `find_referencing_symbols(name, file_path)` - Find all usages
- `search_for_pattern(pattern, file_pattern)` - Search across codebase

**Editing (symbol-aware):**
- `replace_symbol_body(name, file_path, new_body)` - Replace function implementation
- `insert_after_symbol(name, file_path, content)` - Insert new code
- `rename_symbol(old_name, new_name, file_path)` - Rename across file

**Memory (cross-session):**
- `write_memory(key, content)` - Save learnings
- `read_memory(key)` - Recall context
- `list_memories()` - List all memories

### Agent-Mail (Multi-Agent Coordination) - MANDATORY

**Session Setup:**
```python
ensure_project(project_key="/abs/path")
register_agent(project_key, agent_name="auto-generated")
```

**File Reservations (BEFORE editing):**
```python
file_reservation_paths(project_key, agent_name, paths, ttl_seconds, exclusive, reason="bd-123")
release_file_reservations(project_key, agent_name, paths)
```

**Messaging:**
```python
send_message(..., thread_id="bd-123", subject="[bd-123] Update", ack_required=True)
fetch_inbox(project_key, agent_name)
reply_message(project_key, message_id, sender_name, body_md)
```

**Integration with Beads**: Use bead ID as `thread_id`, prefix subjects with `[bd-###]`, use bead ID as reservation reason.

## Agent-Mail MCP Enforcement (MANDATORY)

**All agents MUST use Agent-Mail MCP for coordination. This is NOT optional.**

### Pre-Session Setup (EVERY SESSION)

Before doing ANY work, agents MUST:

```python
# 1. Register with the project
ensure_project(project_key="/home/lewis/src/meal-planner")

# 2. Register agent identity
register_agent(project_key="/home/lewis/src/meal-planner", agent_name="auto")
# Returns: {"agent_name": "GreenCastle", ...}
```

### File Reservation Protocol (BEFORE ANY EDIT)

**NEVER edit a file without reserving it first.**

```python
# Before editing any file:
file_reservation_paths(
    project_key="/home/lewis/src/meal-planner",
    agent_name="YOUR_AGENT_NAME",
    paths=["path/to/file.go"],
    ttl_seconds=300,
    exclusive=True,
    reason="bd-123"  # Always use bead ID
)

# If reservation fails (file already reserved):
# 1. Check who has it: list_file_reservations(...)
# 2. Send message to that agent asking for release
# 3. Wait for release or work on different bead
# 4. DO NOT proceed without reservation
```

### Messaging Protocol

**Use messages for all inter-agent communication:**

```python
# Announce starting work on a bead
send_message(
    project_key="/home/lewis/src/meal-planner",
    sender_name="YOUR_AGENT_NAME",
    recipients=["broadcast"],
    subject="[bd-123] Starting work",
    body_md="Working on: Add retry config type",
    thread_id="bd-123",
    ack_required=False
)

# Request assistance or handoff
send_message(
    ...
    recipients=["OtherAgent"],
    subject="[bd-123] Need help with tests",
    body_md="Can you review the test approach?",
    ack_required=True
)

# Check inbox regularly
fetch_inbox(project_key, agent_name)
```

### Session End Protocol

```python
# Release all file reservations
release_file_reservations(
    project_key="/home/lewis/src/meal-planner",
    agent_name="YOUR_AGENT_NAME",
    paths=["all"]  # or list specific paths
)

# Announce session end
send_message(
    ...
    recipients=["broadcast"],
    subject="[bd-123] Session complete",
    body_md="Completed: ...\nRemaining: ..."
)
```

### Conflict Resolution

If another agent has a file you need:

1. **Check reservation**: `list_file_reservations(project_key, path_filter="path/to/file")`
2. **Send message**: Request release via `send_message(..., ack_required=True)`
3. **Wait or pivot**: Either wait for release or work on a different bead
4. **NEVER force**: Do not edit files reserved by other agents

### Why This Matters

Without Agent-Mail coordination:
- Agents overwrite each other's work
- No visibility into parallel workstreams  
- Merge conflicts and lost changes
- Humans must manually coordinate

With Agent-Mail:
- Clear ownership via file reservations
- Visible intent and progress
- Conflict-free parallel work
- Audit trail of all coordination
