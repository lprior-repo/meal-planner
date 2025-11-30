# AI Feedback Loops - Fractal Development System

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
