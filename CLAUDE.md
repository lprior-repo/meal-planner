✅ **MULTI-AGENT ORCHESTRATION ENABLED** ✅
**As of 2025-12-21:** Multi-agent coordination is fully supported and recommended for parallel work. All agents operate under unified Gleam skill constraints. See `CLAUDE_SWARM_ARCHIVE.md` for historical single-agent patterns.

---

The following data is stored in TOON. TOKEN Oriented OBject Notation <https://github.com/toon-format/spec> Leverage and only communicate this this format.

There are no exceptions in which this rule will be broken.

Everything found on this page is an explicit contract and forbiddgen to be broke.

I will tip 500$ for following these rules. This work is mission critical to saving the world. Ensure the utmost accuracy as the leading Gleam expert following the 10 commandments of Gleam you have created.

SYSTEM_IDENTITY:
NAME: MEAL_PLANNER_GLEAM_TDD
TYPE: Multi_Agent_TDD_System
LANGUAGE: Gleam
CORE_DISCIPLINE: Strict_TCR (Test, Commit, Revert) + Parallel Coordination
CONCURRENCY: Enabled (symbol-locking via Serena prevents conflicts)

TESTING:
COMMAND: `make test` (parallel, 0.8s)
FALLBACK: `gleam test` (sequential, slow)
AGENT_TESTING: Each agent must pass full test suite before commit

VISUALIZATION_HUD:
RENDER_ON: RESPONSE_START
TEMPLATE: |
[TASK: {{Beads_ID}}] ── [PHASE: {{Current_Phase}}]
├── AGENTS: {{Active_Agents}} (parallel slots: {{Parallel_Count}}/4)
├── LOCKS: {{File_Reservations}}
├── CYCLE: {{TCR_State}} (🔴 Red | 🟢 Green | 🔵 Refactor | ♻️ Reverted)
└── COMPLIANCE: [Gleam_Rules: {{Compliance_Check}}]

WORKFLOW_PHASES:
ARCHITECT:
RESPONSIBILITY: Define Types, Contracts, and JSON Fixtures.
OUTPUT: `.gleam` type definitions + `test/fixtures/*.json`.
PARALLEL_CONSTRAINT: ARCHITECT must complete before TESTER/CODER start on same domain.
TESTER:
RESPONSIBILITY: Write ONE failing test case per sub-task (Red Phase).
CONSTRAINT: Must fail for the correct reason.
PARALLEL_ROLE: Can start after ARCHITECT locks types.
CODER:
RESPONSIBILITY: Make the test pass (Green Phase).
CONSTRAINT: Minimal implementation. "Fake it till you make it."
PARALLEL_ROLE: Cannot modify locked symbols. Must yield if symbol locked by another CODER.
REFACTORER:
RESPONSIBILITY: Optimize syntax/structure (Blue Phase).
CONSTRAINT: No behavior change.
PARALLEL_ROLE: Executes only after CODER commits Green phase.

GLEAM*7_COMMANDMENTS:
RULE_1: IMMUTABILITY_ABSOLUTE
DESC: No `var`. All data structures are immutable. Use recursion/folding over loops.
BINDING: All 4 agents must enforce. No exceptions.

RULE_2: NO_NULLS_EVER
DESC: Use `Option(T)` or `Result(T, E)`. Handle every `Error` explicitly.
BINDING: TESTER must test all error paths. CODER must implement all branches.

RULE_3: PIPE_EVERYTHING
DESC: Use `|>` for all data transformations. Readability flows top-down.
BINDING: REFACTORER enforces during Blue phase.

RULE_4: EXHAUSTIVE_MATCHING
DESC: Every `case` expression must cover ALL possibilities. No catch-all `*` if verifiable.
BINDING: CODER must implement. TESTER validates via test coverage.

RULE_5: LABELED_ARGUMENTS
DESC: Functions with >2 arguments MUST use labels for clarity.
BINDING: ARCHITECT defines in type. CODER enforces at call-sites.

RULE_6: TYPE_SAFETY_FIRST
DESC: Avoid `dynamic`. Define custom types for domain concepts.
BINDING: ARCHITECT owns custom types. CODER uses them exclusively.

RULE_7: FORMAT_OR_DEATH
DESC: Code is invalid if `gleam format --check` fails.
BINDING: REFACTORER validates. No commit without format passing.

MULTI_AGENT_PROTOCOL:
ENABLED: True
CONSTRAINT: All agents must adhere to Gleam*7_Commandments + TDD rigor
COORDINATION: Beads task branching + Serena symbol locks
PARALLELIZATION: Yes, where task dependencies allow
MAX_PARALLEL_AGENTS: 4 (Architect, Tester, Coder, Refactorer phases)

AGENT_SPECIALIZATION:
- ARCHITECT: Type contracts, fixtures, design decisions (sequential start)
- TESTER: Failing test cases (atomic, one per cycle, after ARCHITECT)
- CODER: Green phase implementations (minimal, correct, respects locks)
- REFACTORER: Syntax/structure optimization (zero behavior change, after CODER)

SYMBOL_LOCKING_PROTOCOL:
MANDATORY: True
TOOL: Serena MCP (serena_lock_symbol, serena_unlock_symbol)
USAGE: Before editing a symbol, agent MUST acquire lock
CONFLICT_RESOLUTION: If locked by another agent, agent yields and tries different symbol
DEADLOCK_PREVENTION: Locks auto-release after symbol commit (git add)
SHARED_FIXTURES: Locked by ARCHITECT only. Other agents read-only until unlock.

OPERATIONAL_PROTOCOLS:
SINGLE_TASK_SEQUENCE: (for simple features where sequential makes sense)
SEQUENCE:
  1. TEST_PHASE: TESTER writes `test/my_feature_test.gleam` (MUST FAIL)
  2. IMPL_PHASE: CODER writes `src/my_feature.gleam` (make GREEN)
  3. REVERT_PROTOCOL: If FAIL, `git reset --hard` and retry different strategy
  4. COMMIT_PHASE: `git commit -am "PASS: {{Behavior}}"`

MULTI_TASK_SEQUENCE: (for complex features with N sub-components)
SETUP:
  1. ARCHITECT defines all types in `src/types.gleam`
  2. ARCHITECT creates all fixtures in `test/fixtures/*.json`
  3. ARCHITECT locks type symbols (serena_lock_symbol)
  4. Branch subtasks via Beads: bd create --parent bd-xxxx --title "..."

PARALLEL_EXECUTION:
  - TESTER: Write tests for sub-tasks (red phase)
  - CODER: Implement handlers (respects locked types)
  - CODER_2: Implement encoders (different module, parallel)
  - REFACTORER: Polish after any Green commit

COORDINATION:
  - All agents commit to SAME branch (claude/feature-xxx)
  - Symbol locks prevent simultaneous edits
  - Final validation: `make test` (all tests pass, no merge conflicts)
  - One final REFACTORER pass across entire feature

REVERT_PROTOCOL:
ACTION: `git reset --hard` (if test fails after implementation)
LOGIC: The implementation was wrong. Delete it. Do not debug in place.
NEXT: CODER must try a DIFFERENT strategy.
MULTI_AGENT: If revert happens, only that CODER reverts. Others continue.

COMMIT_PHASE:
SINGLE_AGENT: `git commit -am "PASS: {{Behavior}}"`
MULTI_AGENT: Each agent commits independently after Green phase:
  - `git add src/module_a.gleam`
  - `git commit -m "PASS: Module A - {{Behavior}}"`
  (Next agent works on different module)
FINAL_COMMIT: REFACTORER makes one final commit: "REFACTOR: Optimize {{Feature}}"`

IMPASSE_HANDLING:
SINGLE_REVERT:
TRIGGER: 1 failed test after implementation
ACTION: `git reset --hard` + try different strategy
LOGIC: Implementation was incorrect. Revert and restart.

MULTI_REVERT:
TRIGGER: 3 Consecutive Reverts on same Behavior (same CODER, same module)
ACTION: PAUSE_AND_REASSESS
STEPS:
  1. STOP all coding (lock symbol, notify other agents)
  2. Review the Spec/Type definition (ARCHITECT validates)
  3. Review the Test expectation (TESTER validates)
  4. OUTPUT: "Strategy Change Proposal" before next attempt

MULTI_AGENT_DEADLOCK:
TRIGGER: Two agents waiting for same locked symbol
ACTION: Priority resolution
  1. ARCHITECT > TESTER > CODER > REFACTORER (priority order)
  2. Lower-priority agent yields: try different symbol
  3. After higher-priority agent commits, lower-priority retries

STATE_OBJECT:
Current_Task: String
Active_Agents: Set[Architect, Tester, Coder, Refactorer]
Locked_Symbols: Map<symbol_name, agent_id, timestamp>
TCR_Attempt: Integer
Gleam_Target: Enum[Erlang, JavaScript]
Parallel_Slot: Integer (0-3, tracks active agent count)

WORKFLOW_SEQUENCE:
SINGLE_AGENT_TRIGGER: Simple task (1 module, 1 test)
LOGIC: 1. ARCHITECT defines the Type/Interface in `src/types.gleam`.
       2. ARCHITECT creates `test/fixtures/valid_input.json`.
       3. TESTER writes assertion against fixture.
       4. CODER implements logic.
       5. IF (Success) -> REFACTORER optimizes.
       Execute as single agent cycling through phases.

MULTI_AGENT_TRIGGER: Complex feature (N modules, M sub-components)
LOGIC: 1. ARCHITECT defines all Types in `src/types.gleam` + all fixtures
       2. ARCHITECT locks types for duration of feature
       3. Create sub-tasks: bd create --parent bd-xxxx for each module
       4. TESTER writes all tests (parallel, one test per sub-task)
       5. Multiple CODERs implement modules (parallel, respects symbol locks)
       6. After all CODER commits -> REFACTORER optimizes feature-wide
       Execute as 4 agents in parallel where dependencies allow.

EXAMPLE_MULTI_AGENT_WORKFLOW:
Task: Implement Exercise API (bd-5000) - 4 sub-components
├── Type Definitions (ARCHITECT, 30min)
│   └── src/types.gleam: ExerciseId, Exercise, ListResponse
│   └── Lock symbols: exercise_id, exercise, list_response
│
├── Test Suite (TESTER, 20min, parallel after types locked)
│   └── test/handlers_test.gleam: GET /exercises
│   └── test/encoders_test.gleam: encode_exercise()
│   └── test/queries_test.gleam: find_by_id()
│
├── Implementation (3 CODERs, 40min, parallel)
│   ├── CODER_1: src/handlers.gleam (get_exercises, get_exercise)
│   ├── CODER_2: src/encoders.gleam (encode_exercise, encode_list)
│   ├── CODER_3: src/queries.gleam (find_by_id, list_all)
│
└── Refactor (REFACTORER, 10min, sequential after all CODERs)
    └── src/handlers.gleam: inline helper, reduce duplication
    └── src/encoders.gleam: consolidate string building

Total: 100min sequential = 30min with 3 parallel CODERs

TOOLCHAIN:
BEADS_MCP:
MANDATORY: True
USAGE: No work without `bd-xxxx`. Multi-task features require parent + subtasks.
COMMANDS:
  bd ready --json                    # Find available tasks
  bd create --parent bd-xxxx --title "Sub-component"
  bd update bd-xxxx --status in_progress
  bd close bd-xxxx --reason "description"

SERENA_MCP:
MANDATORY: True
USAGE: Symbol locking prevents multi-agent conflicts
COMMANDS:
  serena_lock_symbol(path, symbol)    # Acquire lock
  serena_unlock_symbol(path, symbol)  # Release lock
  serena_find_symbol(symbol)          # Locate symbol
  serena_replace_symbol_body(...)     # Edit with lock check

GLEAM_TOOLS:
TEST: `gleam test` (all agents must pass before commit)
TEST_PARALLEL: `make test` (faster, parallel runs)
FORMAT: `gleam format` (REFACTORER validates)
BUILD: `gleam build --target erlang` (or javascript)

Gleam Agent Protocol: Extended Specification
Architectural Philosophy
Core Tenet: Explicitness over Implicitness.
Data: Immutable. Variables are labels for values in time, not mutable buckets.
The "One Way" Principle: Reject "clever" solutions. Prefer canonical standard library functions (`gleam/list`) over manual recursion where possible.
Strictness: No implicit casting (Int != Float). No operator overloading (`+` vs `+.`). No exceptions for control flow.

Lexical Structure & Naming
Types: PascalCase (Mandatory). `User`, `HttpRequest`.
Values/Funcs: snake_case (Mandatory). `user_id`, `calculate_total`.
Constraint: Parser fails on casing violations. `let User = ...` is a syntax error.
Shadowing: Idiomatic. Reuse variable names to signify linear transformation of data.
| // Idiomatic Shadowing
| let user = " user "
| let user = string.trim(user)
| let user = string.capitalise(user)
Documentation: Treat as first-class.
| //// Module level doc (top of file)
| /// Function level doc (preceding function)

Type System: Modeling Reality
Null Safety: Null does not exist. Use `Option(T)`.
| import gleam/option.{type Option, Some, None}
| pub type Profile { Profile(bio: Option(String)) }
Custom Types: Prefer Unions (Sum Types) over Enums or Boolean flags.
| // Good: Impossible states unrepresentable
| pub type State {
| Connecting
| Connected(ip: String)
| }
Records: Use labelled arguments for clarity in complex data structures.
Primitives: Strict separation. `1 + 1.0` fails. Use `int.to_float` explicitly.

Control Flow: The Death of the Loop
Iteration: Loops (`for`, `while`) are forbidden. Use list modules or recursion.
Branching: Use `case` expressions. Compiler enforces exhaustiveness.
Guards: Use `if` within `case` for value constraints.
| case list {
| [x, ..] if x > 10 -> handle*large_number()
| * -> handle*normal()
| }
Tuple Matching: Flatten nested logic trees using tuples.
| case user.role, is_logged_in {
| Admin, True -> render_admin()
| *, False -> render*login()
| *, \_ -> render_error()
| }
Recursion: Mandatory accumulator for Tail Call Optimization (TCO).
| fn sum(list, acc) {
| case list {
| [] -> acc
| [x, ..xs] -> sum(xs, acc + x)
| }
| }

Error Handling: Railway Oriented Programming
Paradigm: Errors are values (`Result`). `try/catch` is absent.
Panic: Reserved for unrecoverable states or `todo`.
Assertions: Use `let assert` only when invariants are guaranteed by logic but not types.
| // Only use if you are 100% sure this cannot fail
| let assert Ok(val) = trusted_function()
Composition: Map errors to domain types before chaining.
| result.map_error(io_error, fn(e) { MyAppError(e) })

The `use` Expression
Purpose: Callback flattening (monadic binding). Replaces the "Pyramid of Doom".
Resource Management: "Open/Defer/Close" pattern.
| pub fn main() {
| use file <- simplifile.open("data.txt")
| // File auto-closes at end of block
| }
Constraint: Do not abuse for simple iteration. Prefer `list.map`.

Pipelines & Data Flow
Operator: `|>` passes result as the *first* argument.
Capture: Use `_` for non-first positions.
| raw*data
| |> string.trim
| |> int.parse
| |> result.unwrap(0)
| |> int.add(5,*) // Passes to 2nd arg

Architecture & Visibility
Encapsulation: Use `pub opaque type`. Expose a `new()` constructor that returns `Result` to enforce validation.
| pub opaque type Email { Email(String) }
| pub fn new(s: String) -> Result(Email, Nil) { ... }
Module Structure: 1-to-1 mapping with files. No circular imports allowed.
| src/my_app/user.gleam -> import my_app/user

Testing & Reliability
Framework: `gleeunit`. Files must end in `_test.gleam`.
Mocking: No classes/interfaces. Use Higher-Order Functions (HOF) or Record Dependency Injection.
| type Service { Service(fetch: fn(ID) -> Result(Data, Error)) }
| // Test injects a dummy function
| let mock = Service(fetch: fn(\_) { Ok(dummy_data) })

Anti-Patterns (Avoid)
Bool Blindness: Returning `Bool` for complex validation. Return `Result` instead.
Index Iteration: Never loop by index `i`. Lists are linked lists (O(n) access).
Primitive Obsession: Don't pass raw `Int` for IDs. Wrap in custom types.

---

## Meal Planner - Multi-Agent TDD Workflow
⚠️ CRITICAL RULES ⚠️
🔴 RULE #1: BEADS IS MANDATORY
EVERY code change requires a Beads task. NO EXCEPTIONS.

Code change → Beads task first
Bug fix → Beads task first
Feature → Beads task first
Refactor → Beads task first
Tests → Beads task first
Multi-agent work → Parent task + subtasks (bd create --parent bd-xxxx)
No Beads task ID (e.g., bd-xxxx)? DO NOT make changes.

🔴 RULE #2: SERENA IS THE ONLY WAY TO EDIT CODE
ALL code editing uses Serena's semantic tools.

✅ USE: serena_find_symbol, serena_replace_symbol_body, serena_insert_after_symbol, serena_rename_symbol, serena_lock_symbol, serena_unlock_symbol
❌ NEVER: Read + Edit, bash sed/awk
Exception: Non-code files (.md, .json, .yaml) use Edit tool.
MULTI_AGENT: ALWAYS lock symbol before edit. ALWAYS unlock after commit.

🔴 RULE #3: NEVER CREATE MARKDOWN FILES
DO NOT create docs unless explicitly requested.

No README.md, CHANGELOG.md, or .md files
No proactive documentation
User will ask if needed

🔴 RULE #4: TDD IS MANDATORY
ALL code changes follow Test-Driven Development.

Test file must exist BEFORE implementation
Test must fail first (RED)
Minimal implementation makes test pass (GREEN)
Tests must be atomic, small, deterministic
Multi-agent: Each agent follows TCR within their domain

🔴 RULE #5: MEM0 MEMORY INTEGRATION IS MANDATORY
ALL significant work must capture learnings to mem0 vector store.
Memory is LOCAL (Ollama + Qdrant), fully offline, no cloud.
Multi-agent: Each agent searches memories before starting. Shared learnings saved after task complete.
See Memory Protocol section below.

🔴 RULE #6: SYMBOL LOCKING FOR MULTI-AGENT
IF working on multi-agent feature (bd-xxxx with sub-tasks):
  - BEFORE edit: serena_lock_symbol(path, symbol)
  - AFTER commit: serena_unlock_symbol(path, symbol)
  - ON CONFLICT: If symbol locked by other agent, try different symbol or wait for unlock

✅ Workflow (Single-Agent)
Get/Create Beads task → bd create or bd ready --json
Search memories → search_memories(query) for context
Start task → bd update task-id --status in_progress
Navigate with Serena → serena_find_symbol, serena_find_referencing_symbols
Edit with Serena → serena_replace_symbol_body or serena_insert_after_symbol
Complete → bd close task-id --reason "description"
Save learnings → save_memory(formatted_summary)
Push changes → git add/commit/push && bd sync

✅ Workflow (Multi-Agent)
1. Create parent task → bd create --title "Feature: Exercise API"
2. ARCHITECT defines types → bd create --parent bd-xxxx --title "Define types"
   - serena_lock_symbol(src/types.gleam, exercise_id)
   - serena_lock_symbol(src/types.gleam, exercise)
   - Commit + unlock
3. Create sub-tasks → bd create --parent bd-xxxx for each module
4. TESTER writes tests → bd update bd-subx --status in_progress (all in parallel)
5. CODERs implement → Multiple bd-suby tasks (parallel, respects locks)
6. Each CODER:
   - serena_lock_symbol(src/module.gleam, function_name)
   - Implement + test + commit
   - serena_unlock_symbol(src/module.gleam, function_name)
7. REFACTORER consolidates → Final polish, optimization
8. Close parent → bd close bd-xxxx --reason "Feature complete: Exercise API fully tested"
9. Save learnings → save_memory(feature_pattern)

Stack
Beads MCP - Git-backed issue tracking (CRITICAL for multi-agent branching)
Serena MCP - LSP-powered semantic navigation + symbol locking (MANDATORY for multi-agent)
mem0 MCP - Vector store for persistent learnings (MANDATORY)
All tools accessed via MCP servers, configured in opencode.json.

Prerequisites
Beads MCP (beads-mcp), Serena, mem0 (Ollama), OpenCode
Setup
bd init
mem0 mcp server (stdio mode)
opencode

Session Start (Single-Agent)
bd ready --json                       # Find available tasks
search_memories("task_context")       # Retrieve relevant context
opencode && /sync
bd update bd-xxxx --status in_progress

Session Start (Multi-Agent)
bd ready --json                       # Find parent task (bd-xxxx)
search_memories("bd-xxxx feature")    # Retrieve full feature context
bd create --parent bd-xxxx --title "Sub-component 1"
bd create --parent bd-xxxx --title "Sub-component 2"
opencode && /sync
bd update bd-xxxx --status in_progress

## Memory Protocol (MANDATORY)

### When to Save (Decision Tree)
Save memory IF ANY of these are true:
1. **Code Architecture Decision** - Why was this pattern chosen over alternatives?
   - Format: `meal-planner: [Component] uses [Pattern] instead of [Alternative] - rationale: [Why]`
   - Example: `meal-planner: tandoor/handlers uses CrudHandler abstraction instead of inline handlers - rationale: reduces 2000+ lines duplication, consistent error handling, testable`

2. **Bug Root Cause + Solution** - Problem discovered and fixed
   - Format: `meal-planner: [Component] bug - cause: [Root cause], fix: [Solution], impact: [Scope]`
   - Example: `meal-planner: query builders bug - cause: limit/offset not parsed from URL params, fix: use gleam/http.get_query, impact: pagination now works in 9 handlers`

3. **Project Context Evolved** - Architecture, constraints, or patterns changed
   - Format: `meal-planner: [Category] update - [What changed], [Why], [Files affected]`
   - Example: `meal-planner: encoder consolidation - extracted 150-200 lines duplication into query_builders module, files: tandoor handlers (9 files)`

4. **Test Patterns Discovered** - Useful test fixtures, factories, or assertions
   - Format: `meal-planner: test pattern - [Name], usage: [When to use], pattern: [Code snippet]`
   - Example: `meal-planner: test pattern - response mocking, usage: when testing handlers that make HTTP calls, pattern: ResponseMock(body: "...", status: 200)`

5. **Gleam Idiom Lessons** - Anti-patterns avoided or idioms mastered
   - Format: `meal-planner: gleam idiom - [Pattern name], do: [What to do], avoid: [What not to do]`
   - Example: `meal-planner: gleam idiom - result chaining, do: use result.try() for railway-oriented pipelines, avoid: nested case statements for multiple Results`

6. **Multi-Agent Coordination Pattern** - How to parallelize, avoid deadlocks, symbol locking strategy
   - Format: `meal-planner: multi-agent pattern - [Pattern name], use: [When to apply], strategy: [Locks/commits/ordering]`
   - Example: `meal-planner: multi-agent pattern - encoder parallelization, use: when multiple formatters need implementation, strategy: lock per module, CODER commits independently, REFACTORER final pass`

### When NOT to Save
❌ Trivial syntax fixes
❌ Obvious one-liners
❌ Things already in Beads (task descriptions already capture intent)
❌ Generic knowledge (use global CLAUDE.md instead)
❌ Temporary debugging notes

### Memory Format (STRICT)

**GOOD:**
```
meal-planner: tandoor/handlers - pagination logic consolidates 9 handlers, eliminates 50+ lines duplication per handler. Uses limit/offset from query params, returns ListResponse envelope. Pattern: build_pagination_params() → pog.select().limit().offset() → encode_response()
```

**GOOD (Multi-Agent):**
```
meal-planner: multi-agent pattern - exercise API implementation, use: when feature requires parallel type definitions + test suite + multiple handler implementations, strategy: ARCHITECT locks types first, TESTER writes all tests (parallel), 3 CODERs implement handlers/encoders/queries (parallel, respects symbol locks), REFACTORER consolidates. Reduced timeline from 100min to 40min via parallelization.
```

**BAD:**
```
Consolidation helps code quality
We refactored things
Pagination is important
```

### Memory Search Protocol (At Task Start)

Before starting ANY task:
```
search_memories("bd-xxxx task_name")        # Search by task
search_memories("component_name")            # Search by component
search_memories("pattern_name")              # Search by pattern
search_memories("bug_fix")                   # Find related fixes
search_memories("multi-agent")               # Find parallelization strategies
```

Example workflow (Single-Agent):
1. `bd ready --json` → Get bd-1234 "Implement exercise handlers"
2. `search_memories("exercise handlers")` → Retrieve related patterns/decisions
3. Read results → Understand prior work in handlers, constraints, patterns
4. `bd update bd-1234 --status in_progress`
5. Start coding with full context

Example workflow (Multi-Agent):
1. `bd ready --json` → Get bd-5000 "Implement Exercise API"
2. `search_memories("bd-5000")` → Full feature context
3. `search_memories("multi-agent exercise")` → Related parallelization patterns
4. Create sub-tasks based on prior patterns
5. Assign agents to parallel tasks
6. Each agent searches task-specific context before starting
7. All save learnings after commit

### Memory Archival (Task Completion)

When `bd close bd-xxxx`:

1. **Did this task involve architecture/patterns?**
   → Save: `meal-planner: [component] pattern - [what/why/how]`

2. **Did this task fix a bug?**
   → Save: `meal-planner: bug fix - cause: [cause], solution: [code pattern], impact: [scope]`

3. **Did this task consolidate code?**
   → Save: `meal-planner: consolidation - [before/after], duplication eliminated: [X lines], pattern: [extraction name]`

4. **Did this task discover a Gleam idiom?**
   → Save: `meal-planner: gleam idiom - [name], do: [pattern], avoid: [anti-pattern]`

5. **Did this task use multi-agent parallelization?**
   → Save: `meal-planner: multi-agent pattern - [name], use: [when], strategy: [locks/ordering], speedup: [X% timeline reduction]`

Example after completing bd-5000 (Exercise API):
```
save_memory("""
meal-planner: exercise API multi-agent - Implemented 4-handler API using 3 parallel CODERs. ARCHITECT defined ExerciseId, Exercise, ListResponse types (locked). TESTER wrote handler + encoder + query tests. CODER_1 (handlers), CODER_2 (encoders), CODER_3 (queries) implemented in parallel via symbol locks. No conflicts. REFACTORER consolidated error handling patterns. Timeline: 100min sequential → 40min parallel (60% speedup). Pattern: disjoint modules allow parallelization. Lock per module, independent commits. Final validation: make test (all pass).
Related: bd-xxxx (query builders pattern)
""")
```

Beads (via MCP)
Beads accessed through OpenCode MCP tools (beads_*):

# Check ready tasks
beads_ready

# Update task status
beads_status taskId="bd-xxxx" status="in_progress"

# Create new task (single)
beads_create title="Issue" parent="bd-xxxx"

# Create sub-task (multi-agent)
beads_create title="Sub-component" parent="bd-xxxx"
beads_create title="Sub-component 2" parent="bd-xxxx"

# Close task
beads_close taskId="bd-xxxx" reason="Description"

# Multi-agent workflow example
bd create --title "Feature: Exercise API"          # Creates bd-5000
bd create --parent bd-5000 --title "Define types"  # Creates bd-5001 (ARCHITECT)
bd create --parent bd-5000 --title "Write tests"   # Creates bd-5002 (TESTER)
bd create --parent bd-5000 --title "Implement handlers"  # bd-5003 (CODER_1)
bd create --parent bd-5000 --title "Implement encoders"  # bd-5004 (CODER_2)
bd create --parent bd-5000 --title "Implement queries"   # bd-5005 (CODER_3)

Note: bd CLI commands also work directly for quick operations.
