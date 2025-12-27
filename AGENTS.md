# Agent Instructions

This project uses an integrated workflow with **three core systems**:
1. **bd** (beads) - Issue tracking and work management
2. **graphiti** (graphdb) - Knowledge graph for storing project context, relationships, and learned information
3. **mem0** - Long-term memory system for persistent information across conversations

All three systems must be kept in sync throughout work sessions.

## Quick Reference

```bash
# Issue Tracking (bd/beads)
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git

# Knowledge Graph (graphiti/graphdb)
# Used via MCP tools - automatically syncs with bead IDs as group_id

# Long-term Memory (mem0)
# Used via MCP tools - stores user preferences, technical decisions, bug solutions

# Issue Visualization (bv)
bv                    # Launch TUI viewer for beads
```

## System Integration

### Beads (Issue Tracking)
- Primary source of truth for work items
- Use `bd` CLI or `bv` TUI for issue management
- Each issue has a unique ID that serves as coordination point

### Graphiti (Knowledge Graph)
- Stores structured project knowledge as episodes
- Uses bead IDs as `group_id` to link knowledge to issues
- Searchable via semantic queries to find relevant context

### Mem0 (Long-term Memory)
- Stores user preferences, technical decisions, and solutions
- Persists across conversations for continuity
- Captures "why" behind decisions, not just "what"

**Sync Rule:** When working on bead `bd-123`:
- Use `group_id: "bd-123"` in all graphiti episodes
- Tag mem0 memories with "bd-123" for linking
- Close bead only after all relevant knowledge/memory is persisted

## Session Start Workflow

**Before starting ANY task:**

1. **Claim work** (if not already assigned):
   ```bash
   bd show <id>           # Review issue details
   bd update <id> --status in_progress
   ```

2. **Search for context** (CRITICAL - must do this first):
   ```bash
   # In your agent tools, run these searches:
   search_memory_facts("project:meal-planner")          # General project context
   search_memory_facts("bd-<id>")                      # Issue-specific context
   search_memory_facts("user preferences coding")     # User preferences
   ```

3. **Search knowledge graph** (for related work):
   ```bash
   # In your agent tools:
   graphiti_search_memory_facts(query: "bd-<id>", max_facts: 10)
   graphiti_search_nodes(query: "related to bd-<id>", max_nodes: 5)
   ```

4. **Review bead status**:
   ```bash
   bv --bead-history <id>  # View bead history
   ```

## During Work - Memory & Knowledge Tracking

**Save information IMMEDIATELY when:**

### User Preferences (mem0)
- "User prefers X over Y because Z"
- Coding style, frameworks, tools, workflows
- Example: "User prefers Gleam's pipe operator |> over nested function calls"

### Technical Decisions (graphiti + mem0)
- Architecture choices WITH rationale
- Example (graphiti): "Decision: Use Wisp framework for HTTP. Rationale: lightweight, idiomatic Gleam"
- Example (mem0): "meal-planner: Chose Wisp framework because it's lightweight and idiomatic Gleam"

### Bug Solutions (graphiti + mem0)
- Problem → Root cause → Solution → Prevention
- Tag with bead ID for tracking
- Example (graphiti): "Bug: Tandoor API 404 on missing recipes. Root cause: API doesn't distinguish 'not found' from 'error'. Solution: Check response body"
- Example (mem0): "Bug: Tandoor 404 error. Solution: Check response body, not just status code"

### Project Patterns (graphiti + mem0)
- Reusable patterns and when to use them
- Example (graphiti): "Pattern: CrudHandler abstraction. When to use: API endpoint implementations"
- Example (mem0): "meal-planner pattern: All external API calls wrapped in Result with custom error type"

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

### Automated Script (Recommended)

Run the automated landing script that handles all sync operations:

```bash
./scripts/land-the-plane.sh
```

This script automatically:
1. Checks for uncommitted changes
2. Runs quality gates (tests, build)
3. Updates bead statuses
4. Syncs graphiti knowledge graph
5. Syncs mem0 long-term memory
6. Syncs beads with git
7. Pushes to remote
8. Verifies successful push
9. Provides hand-off summary

### Manual Workflow

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create beads for anything that needs follow-up
   ```bash
   bd create "Issue title" --description "Description..."
   ```

2. **Run quality gates** (if code changed):
   ```bash
   gleam test              # Run tests
   gleam build             # Verify build
   gleam fmt               # Format code
   ```

3. **Consolidate learnings** (CRITICAL - do this before closing):
   - Save key insights to graphiti (use bead ID as group_id)
   - Update mem0 with important patterns and decisions
   - Link related memories together

4. **Update bead status**:
   ```bash
   bd close <id>           # Mark completed work
   bd update <id> --status pending  # Update in-progress items
   ```

5. **Sync all systems** (IN ORDER):
   ```bash
   # Sync graphiti (knowledge graph)
   # No CLI needed - MCP tools auto-sync

   # Sync mem0 (long-term memory)
   # No CLI needed - MCP tools auto-sync

   # Sync beads with git
   bd sync

   # Push to remote
   git pull --rebase
   git push
   ```

6. **Verify completion**:
   ```bash
   git status              # MUST show "up to date with origin"
   bv                      # Verify bead statuses in TUI
   ```

7. **Clean up**:
   ```bash
   git stash clear         # Clear stashes
   git remote prune origin # Prune remote branches
   ```

8. **Hand off** - Provide context for next session:
   - What was completed
   - What's in progress
   - What was learned
   - Bead IDs for reference

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
- Knowledge (graphiti) and memory (mem0) must be synced before closing beads
- All three systems must be consistent before session end

## Memory & Knowledge Best Practices

### What to Store (Priority Order)

**mem0 (Long-term Memory):**
1. User preferences (coding style, frameworks, workflows)
2. Technical decisions WITH rationale (the "why")
3. Bug solutions (problem → root cause → solution → prevention)
4. Project context (structure, conventions, constraints, patterns)
5. Workflow patterns (how user prefers to approach problems)

**graphiti (Knowledge Graph):**
1. Architecture decisions with full context
2. Bug solutions with implementation details
3. Design patterns with usage examples
4. Code relationships and dependencies
5. Work history linked to bead IDs

### What NOT to Store

**Both systems:**
- Generic questions ("Can you help me?")
- Temporary debugging steps
- Common programming knowledge
- Sensitive data (credentials, API keys)
- One-off requests unlikely to recur

### Memory Format Examples

**BE Specific and Actionable:**
```
BAD:  "User likes Gleam"
GOOD: "User prefers Gleam's pipe operator |> over nested function calls for readability"
```

**Include Context:**
```
BAD:  "Use Result types"
GOOD: "meal-planner: Use Result(T, E) instead of Option for API calls - need error details"
```

**Capture the WHY:**
```
BAD:  "Architecture uses Wisp framework"
GOOD: "meal-planner uses Wisp framework because it's lightweight and idiomatic Gleam with good middleware support"
```

## Search Queries

Use these search patterns to find relevant information:

### mem0 (Long-term Memory)
```bash
# Session start - always search first
search_memory_facts("project:meal-planner")
search_memory_facts("user preferences coding")

# During work
search_memory_facts("tandoor handlers")
search_memory_facts("pagination bug")
search_memory_facts("test pattern mocking")
search_memory_facts("gleam idiom result")
```

### graphiti (Knowledge Graph)
```bash
# Issue-specific searches
graphiti_search_memory_facts(query: "bd-123", group_ids: ["bd-123"], max_facts: 10)
graphiti_search_nodes(query: "related architecture", group_ids: ["bd-123"], max_nodes: 5)

# General searches
graphiti_search_memory_facts(query: "tandoor architecture", max_facts: 10)
graphiti_search_nodes(query: "CrudHandler pattern", max_nodes: 5)
```

### bv (Beads Viewer)
```bash
# View issue history
bv --bead-history 123

# View at specific point in time
bv --as-of "2024-12-25"

# Export agent brief
bv -agent-brief ./brief-export
```

## Troubleshooting

### Push Failures
```bash
# If push fails with conflict
git pull --rebase
# Resolve conflicts
git push
bd sync  # Re-sync beads after rebase
```

### Sync Conflicts
```bash
# If bd sync fails
bd sync --force  # Force sync from git
# Or
bd sync --local  # Use local beads as source
```

### Memory/Search Issues
- If mem0 searches return nothing: Check MCP server is running
- If graphiti searches return nothing: Verify group_id matches bead ID
- Use bv to verify bead IDs are correct

## Tool Integration

| System | Primary CLI | MCP Tools | Purpose |
|--------|------------|-----------|---------|
| beads | `bd` | - | Issue tracking |
| beads | `bv` | - | Issue visualization (TUI) |
| graphiti | - | `graphiti_*` | Knowledge graph |
| mem0 | - | `graphiti_*` (via local-graph MCP) | Long-term memory |

## Verification Checklist

Before considering session complete, verify:

- [ ] All code changes committed
- [ ] All tests passing
- [ ] Build succeeds
- [ ] Bead statuses updated (closed/in-progress)
- [ ] Key decisions saved to graphiti (with bead ID as group_id)
- [] Important patterns saved to mem0
- [ ] `bd sync` completed successfully
- [ ] `git push` completed successfully
- [ ] `git status` shows "up to date with origin"
- [ ] Hand-off summary provided

