# CLAUDE_MEMORY.md - Memory Protocol (MANDATORY)

## OVERVIEW

**Storage:** LOCAL vector store (Ollama + Qdrant), fully offline, no cloud
**Purpose:** Capture learnings, patterns, bug fixes, architecture decisions
**Scope:** Project-specific (meal-planner namespace)
**Lifecycle:** Searched at task start, saved at task completion

---

## DECISION TREE: When to Save

Save memory IF ANY of these are true:

### 1. Code Architecture Decision
**Why was this pattern chosen over alternatives?**

```
Format: meal-planner: [Component] uses [Pattern] instead of [Alternative] - rationale: [Why]

Example:
meal-planner: tandoor/handlers - uses CrudHandler abstraction instead of inline handlers.
Rationale: reduces 2000+ lines duplication, consistent error handling across 9 handlers, testable via dependency injection.
```

**Save After:**
- Choosing handler abstraction vs inline
- Selecting encoder consolidation strategy
- Deciding on opaque type wrapping
- Picking custom type vs primitives

### 2. Bug Root Cause + Solution
**Problem discovered and fixed.**

```
Format: meal-planner: [Component] bug - cause: [Root cause], fix: [Solution], impact: [Scope]

Example:
meal-planner: query builders bug - cause: limit/offset not parsed from URL query params,
fix: use gleam/http.get_query to extract URL params before building pog.select(),
impact: pagination now works in 9 handlers, +150 lines saved via consolidation.
```

**Save After:**
- Fixing pagination issues
- Correcting type constraint bugs
- Discovering edge case handling
- Resolving error handling gaps

### 3. Project Context Evolved
**Architecture, constraints, or patterns changed.**

```
Format: meal-planner: [Category] update - [What changed], [Why], [Files affected]

Example:
meal-planner: encoder consolidation - extracted 150-200 lines duplicate pagination encoder logic
from 9 tandoor handlers into query_builders.encode_list_response().
Why: single source of truth, consistent error codes, reduced maintenance surface.
Files: src/tandoor/handlers/*.gleam (9 files), src/query_builders.gleam (1 new file).
```

**Save After:**
- Refactoring duplication into shared module
- Changing error handling strategy
- Shifting type system (primitives → custom types)
- Consolidating similar functions

### 4. Test Patterns Discovered
**Useful test fixtures, factories, or assertions.**

```
Format: meal-planner: test pattern - [Name], usage: [When to use], pattern: [Code snippet]

Example:
meal-planner: test pattern - response mocking.
Usage: when testing handlers that make HTTP calls.
Pattern: ResponseMock(body: "...", status: 200, headers: [...])
Used in: src/handlers_test.gleam, src/encoding_test.gleam
```

**Save After:**
- Creating reusable test fixtures
- Building test factories
- Finding useful assertion patterns
- Discovering helper functions that speed up tests

### 5. Gleam Idiom Lessons
**Anti-patterns avoided or idioms mastered.**

```
Format: meal-planner: gleam idiom - [Pattern name], do: [What to do], avoid: [Anti-pattern]

Example:
meal-planner: gleam idiom - result chaining.
Do: use result.try() for railway-oriented pipelines, map errors explicitly before chaining.
Avoid: nested case statements for multiple Results, catching with dynamic types.
Reference: CLAUDE_GLEAM_SKILL.md Rule 3 (Pipe Everything)
```

**Save After:**
- Discovering idioms that solve common problems
- Learning what NOT to do in Gleam
- Mastering pattern matching improvements
- Finding performance optimizations

### 6. Multi-Agent Coordination Pattern
**How to parallelize, avoid deadlocks, symbol locking strategy.**

```
Format: meal-planner: multi-agent pattern - [Pattern name], use: [When to apply], strategy: [Locks/commits/ordering]

Example:
meal-planner: multi-agent pattern - encoder parallelization.
Use: when multiple formatters need implementation (5+ handlers).
Strategy: lock encoder module per CODER, each CODER commits independently,
REFACTORER consolidates in final pass. Result: 180min sequential → 60min parallel (67% speedup).
Reference: bd-5000 (Exercise API implementation)
```

**Save After:**
- Completing multi-agent features
- Discovering parallelization opportunities
- Overcoming deadlock scenarios
- Optimizing agent coordination

---

## WHEN NOT TO SAVE

❌ Trivial syntax fixes ("add semicolon")
❌ Obvious one-liners ("rename variable")
❌ Things already in Beads (task descriptions capture intent)
❌ Generic knowledge (use CLAUDE.md / CLAUDE_GLEAM_SKILL.md instead)
❌ Temporary debugging notes
❌ Things you just Googled (not project-specific learning)

---

## MEMORY FORMAT (STRICT)

### GOOD Format

```
meal-planner: tandoor/handlers - pagination logic consolidates 9 handlers,
eliminates 50+ lines duplication per handler. Uses limit/offset from query params,
returns ListResponse envelope. Pattern: build_pagination_params() → pog.select().limit().offset()
→ encode_response(). Extracted into query_builders module. Related: bd-xxx (query builders refactor)
```

```
meal-planner: multi-agent pattern - exercise API implementation.
Use: when feature requires parallel type definitions + test suite + multiple handler implementations.
Strategy: ARCHITECT locks types first (30min), TESTER writes all tests (20min, parallel),
3 CODERs implement handlers/encoders/queries (40min, parallel, respects symbol locks),
REFACTORER consolidates (10min). Result: 100min sequential → 30min with parallelization (70% speedup).
```

### BAD Format

```
Consolidation helps code quality
We refactored things
Pagination is important
```

---

## MEMORY SEARCH PROTOCOL (At Task Start)

Before starting ANY task:

```bash
search_memories("bd-xxxx task_name")        # Search by task ID
search_memories("component_name")           # Search by component (handlers, encoders, etc)
search_memories("pattern_name")             # Search by pattern (pagination, multi-agent, etc)
search_memories("bug_fix")                  # Find related bug fixes
search_memories("multi-agent")              # Find parallelization strategies
search_memories("gleam idiom")              # Find idiom lessons
```

### Example: Single-Agent Task
```bash
# Task: bd-1234 "Implement exercise handlers"

# Search 1: By task ID
search_memories("bd-1234")

# Search 2: By component
search_memories("exercise handlers")

# Search 3: By pattern
search_memories("handler implementation")

# Search 4: By Gleam idiom
search_memories("result chaining")

# Read results → Understand:
#   - Prior handler patterns in project
#   - Common error handling approach
#   - Test patterns for handlers
#   - Encoder consolidation opportunities

# bd update bd-1234 --status in_progress
# Start coding with full context
```

### Example: Multi-Agent Task
```bash
# Task: bd-5000 "Implement Exercise API" (complex feature)

# Search 1: By task ID
search_memories("bd-5000")

# Search 2: By component
search_memories("exercise")

# Search 3: By multi-agent pattern
search_memories("multi-agent exercise")
search_memories("parallel implementation")

# Search 4: By architecture
search_memories("encoder consolidation")

# Read results → Understand:
#   - Prior exercise work (if any)
#   - Multi-agent coordination patterns
#   - Encoder strategies that worked
#   - Parallelization speedup estimates

# Create sub-tasks based on prior patterns
# Assign agents to parallel tasks
# Each agent searches task-specific context
```

---

## MEMORY ARCHIVAL (Task Completion)

When `bd close bd-xxxx`, evaluate:

### 1. Architecture/Patterns
```
Question: Did this task involve choosing or refining a pattern?
If Yes: save_memory("meal-planner: [component] pattern - [what/why/how]")
```

### 2. Bug Fix
```
Question: Did this task fix a bug?
If Yes: save_memory("meal-planner: bug fix - cause: [X], solution: [Y], impact: [Z]")
```

### 3. Code Consolidation
```
Question: Did this task consolidate duplicated code?
If Yes: save_memory("meal-planner: consolidation - [before/after],
  duplication eliminated: [X lines], pattern: [extraction name]")
```

### 4. Gleam Idiom
```
Question: Did this task discover or master a Gleam idiom?
If Yes: save_memory("meal-planner: gleam idiom - [name], do: [pattern], avoid: [anti-pattern]")
```

### 5. Multi-Agent Coordination
```
Question: Did this task use multi-agent parallelization?
If Yes: save_memory("meal-planner: multi-agent pattern - [name], use: [when],
  strategy: [locks/ordering], speedup: [X% timeline reduction]")
```

---

## ARCHIVAL EXAMPLES

### Example 1: Bug Fix Completion (bd-100)
Task: "Fix pagination in exercise handlers"

```bash
save_memory("""
meal-planner: pagination bug fix - cause: limit/offset parameters not extracted from URL query string,
fix: use gleam/http.get_query to parse URL params before passing to pog.select().limit().offset(),
impact: pagination now works across 9 tandoor handlers.
Related consolidation: query_builders.build_pagination_params() extracts limit/offset once,
reused by all 9 handlers (+150 lines saved per handler via consolidation).
Gleam idiom used: Result chaining with result.try() for error propagation.
Files: src/tandoor/handlers/*.gleam (9 files), src/query_builders.gleam
Reference: bd-100 (pagination fix), bd-101 (consolidation follow-up)
""")
```

### Example 2: Architecture Decision (bd-200)
Task: "Consolidate handler error responses"

```bash
save_memory("""
meal-planner: handler architecture - uses unified error response envelope (HttpError type)
instead of inline error handling in each handler.
Rationale: consistent HTTP status codes, predictable error response format,
single source of truth for error mapping.
Pattern:
  pub type HttpError { BadRequest(msg: String) | NotFound | InternalError }
  pub fn error_to_response(error: HttpError) -> Response { ... }
Consolidation: 150+ lines of duplicate error handling removed from 12 handlers.
Benefits: maintainability, consistency, testability (mock error responses easily).
Related: bd-xxx (query builders consolidation), bd-yyy (encoder consolidation)
Files: src/http_errors.gleam (new), src/tandoor/handlers/*.gleam (12 files)
""")
```

### Example 3: Multi-Agent Completion (bd-5000)
Task: "Implement Exercise API (multi-agent)"

```bash
save_memory("""
meal-planner: exercise API multi-agent - Implemented 4-handler API using 3 parallel CODERs + ARCHITECT + TESTER + REFACTORER.
ARCHITECT: Defined ExerciseId, Exercise, ListResponse types (locked for feature duration).
TESTER: Wrote handler + encoder + query tests (20min, RED phase, all tests failing initially).
CODER_1: Implemented handlers (get_exercises, get_exercise) via symbol locks (40min, GREEN phase).
CODER_2: Implemented encoders (encode_exercise, encode_list) in parallel (40min, GREEN phase).
CODER_3: Implemented queries (find_by_id, list_all, list_paginated) in parallel (40min, GREEN phase).
No conflicts: Symbol locking prevented simultaneous edits to same symbols.
REFACTORER: Consolidated error handling patterns across 3 modules (10min, BLUE phase).
Timeline: 100min sequential (ARCHITECT→TESTER→CODER_1→CODER_2→CODER_3→REFACTORER)
  vs 30min parallel (ARCHITECT, then parallel TESTER+CODER_1+CODER_2+CODER_3, then REFACTORER) = 70% speedup.
Pattern: Disjoint modules (handlers, encoders, queries) allow parallelization.
  Lock per module, independent commits, final validation (make test all pass).
Gleam idioms: Result chaining, exhaustive pattern matching, opaque types.
Files: src/exercises/*.gleam (3 files), test/exercises_*_test.gleam (3 files)
Reference: CLAUDE_MULTI_AGENT.md (full workflow), bd-5000 (Exercise API feature)
""")
```

### Example 4: Gleam Idiom Discovery (bd-150)
Task: "Refactor error handling in 5 handlers"

```bash
save_memory("""
meal-planner: gleam idiom - result railway-oriented programming.
Do: Use result.try() to chain Result-returning operations, mapping errors explicitly at each step.
Enables top-down data flow via pipes (|>). All error branches handled explicitly (no implicit error swallowing).
Avoid: Nested case statements for multiple Results (creates "pyramid of doom").
  Do NOT use 'let assert Ok()' for operations that can fail (pagination, parsing, etc).
Example:
  parse_params(req)
  |> result.try(fn(params) { validate_params(params) })
  |> result.map(fn(params) { build_query(params) })
  |> result.map_error(fn(err) { handle_error(err) })
Performance: No cost vs nested case. Compiler optimizes to same code.
Files: src/tandoor/handlers/*.gleam (5 handlers refactored)
Related: CLAUDE_GLEAM_SKILL.md (RULE_3: Pipe Everything, Error Handling: Railway Oriented Programming)
""")
```

---

## SEARCH COMMANDS

```bash
# Find architecture patterns
search_memories("handler pattern")
search_memories("encoder consolidation")

# Find bugs
search_memories("pagination bug")
search_memories("error handling")

# Find idioms
search_memories("gleam idiom result")
search_memories("pattern matching")

# Find multi-agent workflows
search_memories("multi-agent")
search_memories("symbol locking")

# Find specific features
search_memories("exercise")
search_memories("authentication")
```

---

## NO EXCEPTIONS

- Save memory for architecture decisions
- Save memory for bugs you fix
- Save memory for patterns you discover
- Save memory for Gleam idioms you master
- Save memory for multi-agent coordination wins

**Memory is your future self's best friend.**

---

**Local, offline, persistent learning. Search before starting. Save when done.**
