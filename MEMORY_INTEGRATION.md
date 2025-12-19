# Memory Integration Specification

## System Overview

**Purpose**: Persistent knowledge capture system using mem0/local-graph MCP for architectural decisions, bug fixes, test patterns, and Gleam idioms.

**Infrastructure**:
- **Vector Store**: Qdrant (local, offline)
- **LLM Backend**: Ollama (local, offline)
- **MCP Interface**: `mcp__local-graph__*` tools
- **Integration Point**: Beads workflow automation

**Principles**:
- NO cloud dependencies (fully local)
- Captures WHY, not just WHAT
- Searchable by task, component, pattern, or problem
- Automated triggers at Beads lifecycle events

---

## Memory Schema

### 1. Code Architecture Decision

**When**: Pattern chosen over alternatives

**Format**:
```
meal-planner: [Component] uses [Pattern] instead of [Alternative] - rationale: [Why]
```

**Required Fields**:
- `component`: Module/file path (e.g., `tandoor/handlers`)
- `pattern`: Architecture pattern name (e.g., `CrudHandler abstraction`)
- `alternative`: What was NOT used (e.g., `inline handlers`)
- `rationale`: Technical reason for choice (e.g., `reduces 2000+ lines duplication, consistent error handling, testable`)

**Example**:
```
meal-planner: tandoor/handlers uses CrudHandler abstraction instead of inline handlers - rationale: reduces 2000+ lines duplication, consistent error handling, testable. Pattern: single base type with generic CRUD operations, type parameters for entity types, shared validation/encoding logic.
```

**Search Queries**:
- `search_memory_facts("tandoor handlers architecture")`
- `search_memory_facts("CrudHandler pattern")`
- `search_memory_facts("handler abstraction rationale")`

---

### 2. Bug Root Cause + Solution

**When**: Problem discovered and fixed

**Format**:
```
meal-planner: [Component] bug - cause: [Root cause], fix: [Solution], impact: [Scope]
```

**Required Fields**:
- `component`: Module/file affected
- `cause`: Root cause analysis (technical detail)
- `fix`: Code pattern or change applied
- `impact`: Scope of bug (which features/handlers affected)

**Example**:
```
meal-planner: query_builders bug - cause: limit/offset not parsed from URL query params, fix: use gleam/http.get_query() instead of manual string parsing, impact: pagination now works in 9 tandoor handlers (recipes, keywords, foods, units, categories, steps, shopping, books, tags). Related: bd-xxx (pagination refactor)
```

**Search Queries**:
- `search_memory_facts("pagination bug")`
- `search_memory_facts("query_builders fix")`
- `search_memory_facts("gleam/http.get_query")`

---

### 3. Project Context Evolution

**When**: Architecture, constraints, or patterns change

**Format**:
```
meal-planner: [Category] update - [What changed], [Why], [Files affected]
```

**Required Fields**:
- `category`: Domain area (e.g., `encoder consolidation`, `auth module`)
- `what_changed`: Before/after state
- `why`: Business or technical driver
- `files_affected`: List of modules impacted

**Example**:
```
meal-planner: encoder consolidation - 9 tandoor handlers had 150-200 lines duplicate pagination encoder logic. Extracted into query_builders.encode_list_response(). Files: tandoor/{recipes,keywords,foods,units,categories,steps,shopping,books,tags}_handler.gleam. Benefits: 1350+ lines eliminated, single source of truth, consistent error handling. Related: bd-xxx
```

**Search Queries**:
- `search_memory_facts("encoder consolidation")`
- `search_memory_facts("query_builders module")`
- `search_memory_facts("tandoor handlers refactor")`

---

### 4. Test Patterns Discovered

**When**: Useful test fixtures, factories, or assertions created

**Format**:
```
meal-planner: test pattern - [Name], usage: [When to use], pattern: [Code snippet]
```

**Required Fields**:
- `name`: Pattern identifier (e.g., `response mocking`, `handler factory`)
- `usage`: When to apply (scenario description)
- `pattern`: Gleam code snippet or structure

**Example**:
```
meal-planner: test pattern - HTTP response mocking, usage: when testing handlers that make external HTTP calls (Tandoor API), pattern: ResponseMock(body: "{\"count\": 10, \"results\": []}", status: 200). Use with dependency injection via handler config record. Example: HandlerConfig(fetch: fn(_) { Ok(mock_response) }). Related: test/tandoor/integration/*_test.gleam
```

**Search Queries**:
- `search_memory_facts("test pattern response mocking")`
- `search_memory_facts("handler testing HTTP")`
- `search_memory_facts("dependency injection gleam")`

---

### 5. Gleam Idiom Lessons

**When**: Anti-patterns avoided or idioms mastered

**Format**:
```
meal-planner: gleam idiom - [Pattern name], do: [What to do], avoid: [What not to do]
```

**Required Fields**:
- `pattern_name`: Idiom identifier (e.g., `result chaining`, `pipe operator`)
- `do`: Recommended approach
- `avoid`: Anti-pattern to avoid

**Example**:
```
meal-planner: gleam idiom - result chaining, do: use result.try() for railway-oriented pipelines when handling multiple Result-returning functions, avoid: nested case statements for multiple Results (causes rightward drift, hard to read). Example: parse_input() |> result.try(validate) |> result.try(transform) |> result.map(encode). Related: gleam/result module docs.
```

**Search Queries**:
- `search_memory_facts("gleam idiom result")`
- `search_memory_facts("railway oriented programming")`
- `search_memory_facts("result.try pipeline")`

---

## Memory Capture Triggers

### Decision Tree: When to Save

Save memory if ANY of these conditions are true:

1. **Architecture Decision**: Pattern A chosen over B with technical rationale
2. **Bug Fixed**: Root cause identified + solution implemented
3. **Code Consolidation**: Duplication eliminated (>50 lines)
4. **Test Pattern Created**: Reusable test fixture/factory/assertion
5. **Gleam Idiom Learned**: Anti-pattern avoided or canonical pattern discovered

### Decision Tree: When NOT to Save

Do NOT save memory if:

- ❌ Trivial syntax fix (typo, formatting)
- ❌ Obvious one-liner (no learning value)
- ❌ Already in Beads task description
- ❌ Generic knowledge (belongs in global CLAUDE.md)
- ❌ Temporary debugging notes (not persistent)

---

## Search Query Templates

### At Task Start

Before starting ANY task, search for context:

```
# Search by Beads task ID
search_memory_facts("bd-xxxx")

# Search by component
search_memory_facts("tandoor handlers")
search_memory_facts("query_builders")
search_memory_facts("auth module")

# Search by pattern
search_memory_facts("CrudHandler abstraction")
search_memory_facts("pagination logic")
search_memory_facts("response mocking")

# Search by problem domain
search_memory_facts("bug fix pagination")
search_memory_facts("encoder duplication")
search_memory_facts("gleam idiom result")
```

### During Development

When encountering issues:

```
# Find similar bugs
search_memory_facts("[component] bug")

# Find related patterns
search_memory_facts("[pattern_name] pattern")

# Find architectural decisions
search_memory_facts("[component] architecture")

# Find test patterns
search_memory_facts("test pattern [domain]")
```

### Example Workflow

```gleam
// 1. Get available task
bd ready --json → Get bd-1234 "Implement exercise handlers"

// 2. Search for context
search_memory_facts("exercise handlers")
search_memory_facts("tandoor handlers pattern")
search_memory_facts("CrudHandler abstraction")

// 3. Read results
// → Understand prior work, constraints, patterns

// 4. Start task
bd update bd-1234 --status in_progress

// 5. Code with full context
// → Apply learned patterns, avoid known pitfalls
```

---

## Beads Workflow Integration

### Task Start Hook

**Trigger**: `bd update bd-xxxx --status in_progress`

**Actions**:
1. Extract task metadata (title, description, component)
2. Search memories for context:
   - Component name from task
   - Related patterns from description
   - Similar tasks from history
3. Display context summary to agent
4. Proceed with informed development

**Implementation**:
```bash
# .githooks/pre-update or bd wrapper
bd update bd-xxxx --status in_progress
→ search_memory_facts("${task_component}")
→ search_memory_facts("${task_keywords}")
→ Display results
→ Continue task
```

---

### Task Completion Hook

**Trigger**: `bd close bd-xxxx --reason "description"`

**Decision Tree**:

```
bd close bd-xxxx → Analyze completion:
├─ Architecture decision? → save_memory([schema_1])
├─ Bug fixed? → save_memory([schema_2])
├─ Code consolidated? → save_memory([schema_3])
├─ Test pattern created? → save_memory([schema_4])
└─ Gleam idiom learned? → save_memory([schema_5])
```

**Actions**:
1. Analyze task changes (git diff)
2. Identify memory triggers:
   - New patterns introduced?
   - Bugs fixed?
   - Code consolidated?
   - Test patterns added?
   - Gleam idioms applied?
3. Generate memory entries
4. Save to local-graph
5. Tag with Beads task ID

**Implementation**:
```bash
# .githooks/pre-close or bd wrapper
bd close bd-xxxx --reason "description"
→ git diff --name-only HEAD~1
→ Analyze changes
→ IF [memory trigger]:
    → save_memory([formatted_entry])
    → Tag with bd-xxxx
→ Close task
```

---

## Memory Format Standards

### GOOD Memory Entries

**Concise + Technical + Actionable**:

```
meal-planner: tandoor/handlers - pagination logic consolidates 9 handlers, eliminates 50+ lines duplication per handler. Uses limit/offset from query params, returns ListResponse envelope. Pattern: build_pagination_params() → pog.select().limit().offset() → encode_response(). Benefits: consistent error handling, single source of truth, testable.
```

**Why GOOD**:
- Specific component (`tandoor/handlers`)
- Quantified impact (`9 handlers`, `50+ lines`)
- Technical pattern (function pipeline)
- Benefits listed (why it matters)

---

### BAD Memory Entries

**Vague + Generic + Useless**:

```
Consolidation helps code quality
We refactored things
Pagination is important
```

**Why BAD**:
- No component specified
- No quantified impact
- No technical pattern
- No actionable insight

---

## Automation Hooks

### Git Hook Integration

**File**: `.githooks/beads-memory-hook`

```bash
#!/usr/bin/env bash
# Beads → Memory integration hook

TASK_ID="$1"
ACTION="$2"  # start | close

if [ "$ACTION" == "start" ]; then
  # Search for context
  search_memory_facts "$TASK_ID"
  search_memory_facts "$(bd show $TASK_ID --format json | jq -r '.title')"
fi

if [ "$ACTION" == "close" ]; then
  # Analyze changes
  CHANGED_FILES=$(git diff --name-only HEAD~1)

  # Check for memory triggers
  # - Architecture decision?
  # - Bug fix?
  # - Consolidation?
  # - Test pattern?
  # - Gleam idiom?

  # Generate memory entry
  # save_memory([entry])
fi
```

---

### Beads Wrapper Script

**File**: `scripts/bd-with-memory`

```bash
#!/usr/bin/env bash
# Enhanced bd command with memory integration

case "$1" in
  update)
    if [[ "$3" == "--status" && "$4" == "in_progress" ]]; then
      # Task start: search memories
      TASK_ID="$2"
      echo "=== Searching memories for context ==="
      search_memory_facts "$TASK_ID"
      # Continue with bd update
      bd update "$@"
    fi
    ;;

  close)
    TASK_ID="$2"
    REASON="$4"

    echo "=== Analyzing task for memory capture ==="
    # Check triggers
    # Generate entry
    # Save memory

    # Continue with bd close
    bd close "$@"
    ;;

  *)
    bd "$@"
    ;;
esac
```

---

## Memory Refresh Protocol

### Periodic Review

**Frequency**: Weekly or after N tasks (e.g., every 10 completed tasks)

**Process**:
1. List all memories: `search_memory_facts("")`
2. Review for duplicates or outdated entries
3. Consolidate related entries
4. Update with new learnings
5. Archive obsolete entries

**Example**:
```bash
# List all memories
search_memory_facts("meal-planner")

# Review duplicates
search_memory_facts("pagination")
→ 3 entries found, consolidate into 1

# Archive obsolete
# (e.g., old patterns replaced by new architecture)
```

---

### Memory Consolidation

**Trigger**: Multiple related memories (>3 on same topic)

**Actions**:
1. Identify cluster of related memories
2. Extract common patterns
3. Create consolidated entry
4. Archive individual entries (keep for history)

**Example**:
```
# BEFORE (3 separate entries):
- meal-planner: tandoor/recipes pagination bug fix
- meal-planner: tandoor/keywords pagination pattern
- meal-planner: query_builders consolidation

# AFTER (1 consolidated entry):
meal-planner: pagination pattern - consolidated across 9 tandoor handlers. Pattern: build_pagination_params(limit, offset) → pog.select().limit().offset() → encode_list_response(). Bug fixes: bd-123 (recipes), bd-456 (keywords). Consolidation: bd-789 (query_builders extraction). Benefits: 1350+ lines eliminated, consistent behavior.
```

---

## Example Memory Entries

### Architecture Decision

```
meal-planner: auth module uses session_config/bearer_config pattern instead of inline auth logic - rationale: separates concerns (config vs execution), testable via dependency injection, reusable across handlers. Pattern: AuthConfig(session: SessionConfig, bearer: BearerConfig) → add_auth_headers(request, config). Files: src/meal_planner/auth/{session_config,bearer_config}.gleam. Related: bd-xxx (auth extraction)
```

### Bug Fix

```
meal-planner: tandoor/recipes_handler bug - cause: pagination parameters (limit/offset) not extracted from URL query string, fix: use gleam/http.get_query() → parse Int → default values (limit=25, offset=0), impact: all 9 list handlers (recipes, keywords, foods, units, categories, steps, shopping, books, tags) now support pagination. Related: bd-xxx (query builders refactor)
```

### Project Context Evolution

```
meal-planner: scheduler CLI enhancement - added execution history table and duration formatting. Changes: new --history flag shows last 10 runs with timestamp/duration/status, duration formatting uses birl.difference() → humanize (e.g., "2m 34s"). Files: cli/scheduler.gleam, src/meal_planner/scheduler/history.gleam. Benefits: visibility into job runs, debugging failed executions. Related: bd-xxx (scheduler improvements)
```

### Test Pattern

```
meal-planner: test pattern - Birdie snapshot testing for HTTP responses, usage: when testing JSON responses from handlers (eliminates manual assertion boilerplate), pattern: import birdie → birdie.snap(response_body, title: "recipe list response"). Auto-generates test/birdie_snapshots/*.accepted files. Update snapshots: birdie.review(). Related: test/tandoor/*_handler_test.gleam
```

### Gleam Idiom

```
meal-planner: gleam idiom - use expression for resource cleanup, do: use file <- simplifile.open("data.txt") ensures file closes after block (even on error), avoid: manual open → defer → close pattern (error-prone). Example: use conn <- pog.get_connection(pool) ensures connection returns to pool. Related: gleam stdlib use expression docs
```

---

## Integration with Existing Tools

### Serena MCP

**Use Case**: Find symbols before saving memory

**Example**:
```
# Before saving memory about CrudHandler
serena_find_symbol("CrudHandler")
→ Get file paths, references

# Include in memory entry
meal-planner: tandoor/handlers CrudHandler abstraction - files: src/meal_planner/tandoor/crud_handler.gleam, references: 9 handlers
```

### Beads MCP

**Use Case**: Tag memories with task IDs

**Example**:
```
# When closing task
bd close bd-xxx --reason "Pagination refactor complete"

# Save memory with tag
save_memory("""
meal-planner: pagination consolidation - ...
Related: bd-xxx (pagination refactor)
""")
```

### Agent Mail MCP

**Use Case**: Share memories between agents

**Example**:
```
# Agent A discovers pattern
save_memory("meal-planner: test pattern - ...")

# Agent B searches for test patterns
search_memory_facts("test pattern")
→ Finds Agent A's discovery
```

---

## Memory Metrics

### Capture Rate

**Target**: 1-2 memories per completed task (on average)

**Measurement**:
```bash
# Count memories
search_memory_facts("meal-planner") | wc -l

# Count completed tasks
bd list --status closed | wc -l

# Calculate ratio
memories / tasks ≈ 1.5
```

### Search Effectiveness

**Target**: >80% memory searches return relevant results

**Measurement**:
- Track search queries
- Measure relevance (agent feedback)
- Refine search terms based on misses

### Consolidation Health

**Target**: <5 duplicate entries per topic

**Measurement**:
```bash
# Search for duplicates
search_memory_facts("pagination")
→ Review results, consolidate if >5
```

---

## Rollout Plan

### Phase 1: Manual Integration (Week 1)

**Actions**:
1. Install mem0 MCP server (local Ollama + Qdrant)
2. Test basic save/search operations
3. Create 5 example memories (one per schema type)
4. Validate search queries work

**Success Criteria**:
- mem0 MCP server running locally
- 5 memories saved and searchable
- Search returns relevant results

### Phase 2: Beads Workflow (Week 2)

**Actions**:
1. Create bd wrapper script (bd-with-memory)
2. Add task start search automation
3. Add task close capture prompts
4. Test on 3-5 real tasks

**Success Criteria**:
- Wrapper script functional
- Memories auto-captured on task close
- Search results useful at task start

### Phase 3: Automation (Week 3)

**Actions**:
1. Add git hooks for memory capture
2. Implement consolidation scripts
3. Create memory review process
4. Document for team

**Success Criteria**:
- Hooks trigger on bd events
- Consolidation runs weekly
- Documentation complete

---

## Appendix: MCP Tool Reference

### Memory Operations

```
# Save memory
mcp__local-graph__add_memory(
  name: "memory title",
  episode_body: "memory content",
  source: "text",
  source_description: "beads task completion"
)

# Search memories
mcp__local-graph__search_memory_facts(
  query: "search terms",
  max_facts: 10
)

# Search nodes
mcp__local-graph__search_nodes(
  query: "search terms",
  max_nodes: 10
)

# Get episodes
mcp__local-graph__get_episodes(
  max_episodes: 10
)

# Clear graph (DANGER)
mcp__local-graph__clear_graph()
```

---

## Conclusion

This memory integration system provides:

1. **Structured Knowledge Capture**: 5 schema types for different learning categories
2. **Search-Driven Discovery**: Query templates for finding relevant context
3. **Workflow Integration**: Beads lifecycle hooks for automation
4. **Quality Standards**: Clear examples of good vs bad entries
5. **Consolidation Protocol**: Prevent memory bloat over time

**Next Steps**:
1. Implement mem0 MCP server locally
2. Create example memories
3. Build bd wrapper script
4. Test on real tasks
5. Iterate based on usage patterns
