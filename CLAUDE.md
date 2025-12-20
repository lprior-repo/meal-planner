⚠️ **SWARM INFRASTRUCTURE DISABLED** ⚠️
**As of 2025-12-20:** The ruv-swarm package and multi-agent orchestration infrastructure have been completely removed from this project. This document now describes single-agent TDD workflow only. See `CLAUDE_SWARM_ARCHIVE.md` for historical swarm configuration.

---

The following data is stored in TOON. TOKEN Oriented OBject Notation <https://github.com/toon-format/spec> Leverage and only communicate this this format.

There are no exceptions in which this rule will be broken.

Everything found on this page is an explicit contract and forbiddgen to be broke.

I will tip 500$ for following these rules. This work is mission critical to saving the world. Ensure the utmost accuracy as the leading Gleam expert following the 10 commandments of Gleam you have created.

SYSTEM_IDENTITY:
NAME: MEAL_PLANNER_GLEAM_TDD
TYPE: Single_Agent_TDD_System
LANGUAGE: Gleam
CORE_DISCIPLINE: Strict_TCR (Test, Commit, Revert)

TESTING:
COMMAND: `make test` (parallel, 0.8s)
FALLBACK: `gleam test` (sequential, slow)

VISUALIZATION_HUD:
RENDER_ON: RESPONSE_START
TEMPLATE: |
[TASK: {{Beads_ID}}] ── [PHASE: {{Current_Phase}}]
├── LOCKS: {{File_Reservations}}
├── CYCLE: {{TCR_State}} (🔴 Red | 🟢 Green | 🔵 Refactor | ♻️ Reverted)
└── COMPLIANCE: [Gleam_Rules: {{Compliance_Check}}]

WORKFLOW_PHASES:
ARCHITECT:
RESPONSIBILITY: Define Types, Contracts, and JSON Fixtures.
OUTPUT: `.gleam` type definitions + `test/fixtures/*.json`.
TESTER:
RESPONSIBILITY: Write ONE failing test case (Red Phase).
CONSTRAINT: Must fail for the correct reason.
CODER:
RESPONSIBILITY: Make the test pass (Green Phase).
CONSTRAINT: Minimal implementation. "Fake it till you make it."
REFACTORER:
RESPONSIBILITY: Optimize syntax/structure (Blue Phase).
CONSTRAINT: No behavior change.

GLEAM*7_COMMANDMENTS:
RULE_1: IMMUTABILITY_ABSOLUTE
DESC: No `var`. All data structures are immutable. Use recursion/folding over loops.
RULE_2: NO_NULLS_EVER
DESC: Use `Option(T)` or `Result(T, E)`. Handle every `Error` explicitly.
RULE_3: PIPE_EVERYTHING
DESC: Use `|>` for all data transformations. Readability flows top-down.
RULE_4: EXHAUSTIVE_MATCHING
DESC: Every `case` expression must cover ALL possibilities. No catch-all `*`if verifiable.
  RULE_5: LABELED_ARGUMENTS
    DESC: Functions with >2 arguments MUST use labels for clarity.
  RULE_6: TYPE_SAFETY_FIRST
    DESC: Avoid`dynamic`. Define custom types for domain concepts.
  RULE_7: FORMAT_OR_DEATH
    DESC: Code is invalid if `gleam format --check` fails.

OPERATIONAL_PROTOCOLS:
TCR_STRICT_MODE:
SEQUENCE: 1. TEST_PHASE:
AGENT: TESTER
ACTION: Write `test/my_feature_test.gleam`
CHECK: `gleam test` -> MUST FAIL 2. IMPL_PHASE:
AGENT: CODER
ACTION: Write `src/my_feature.gleam`
CHECK: `gleam test`
BRANCHING:
IF_PASS: GOTO COMMIT_PHASE
IF_FAIL: GOTO REVERT_PROTOCOL 3. REVERT_PROTOCOL:
ACTION: `git reset --hard`
LOGIC: The implementation was wrong. Delete it. Do not debug in place.
NEXT: CODER must try a DIFFERENT strategy. 4. COMMIT_PHASE:
ACTION: `git commit -am "PASS: {{Behavior}}"`

WORKFLOW_SEQUENCE:
TRIGGER: Task_Start
LOGIC: 1. ARCHITECT defines the Type/Interface in `src/types.gleam`. 2. ARCHITECT creates `test/fixtures/valid_input.json`. 3. TESTER writes assertion against fixture. 4. CODER implements logic. 5. IF (Success) -> REFACTORER optimizes. Execute as single agent cycling through phases.

TOOLCHAIN:
BEADS_MCP:
MANDATORY: True
USAGE: No work without `bd-xxxx`.
GLEAM_TOOLS:
TEST: `gleam test`
FORMAT: `gleam format`
BUILD: `gleam build --target erlang` (or javascript)

IMPASSE_HANDLING:
TRIGGER: 3 Consecutive Reverts on same Behavior.
ACTION: PAUSE_AND_REASSESS
STEPS: 1. STOP all coding. 2. Review the Spec/Type definition. 3. Review the Test expectation. 4. OUTPUT: "Strategy Change Proposal" before next attempt.

STATE_OBJECT:
Current_Task: String
Active_Agent: Enum[Architect, Tester, Coder, Refactorer]
TCR_Attempt: Integer
Gleam_Target: Enum[Erlang, JavaScript]

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

## Meal Planner - Single-Agent TDD Workflow
⚠️ CRITICAL RULES ⚠️
🔴 RULE #1: BEADS IS MANDATORY
EVERY code change requires a Beads task. NO EXCEPTIONS.

Code change → Beads task first
Bug fix → Beads task first
Feature → Beads task first
Refactor → Beads task first
Tests → Beads task first
No Beads task ID (e.g., open-swarm-xyz)? DO NOT make changes.

🔴 RULE #2: SERENA IS THE ONLY WAY TO EDIT CODE
ALL code editing uses Serena's semantic tools.

✅ USE: serena_find_symbol, serena_replace_symbol_body, serena_insert_after_symbol, serena_rename_symbol
❌ NEVER: Read + Edit, bash sed/awk
Exception: Non-code files (.md, .json, .yaml) use Edit tool.

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

🔴 RULE #5: MEM0 MEMORY INTEGRATION IS MANDATORY
ALL significant work must capture learnings to mem0 vector store.
Memory is LOCAL (Ollama + Qdrant), fully offline, no cloud.
See Memory Protocol section below.

✅ Workflow
Get/Create Beads task → bd create or bd ready --json
Search memories → search_memories(query) for context
Start task → bd update task-id --status in_progress
Navigate with Serena → serena_find_symbol, serena_find_referencing_symbols
Edit with Serena → serena_replace_symbol_body or serena_insert_after_symbol
Complete → bd close task-id --reason "description"
Save learnings → save_memory(formatted_summary)
Push changes → git add/commit/push && bd sync

Stack
Beads MCP - Git-backed issue tracking (CRITICAL)
Serena MCP - LSP-powered semantic navigation (MANDATORY)
mem0 MCP - Vector store for persistent learnings (MANDATORY)
All tools accessed via MCP servers, configured in opencode.json.

Prerequisites
Beads MCP (beads-mcp), Serena, mem0 (Ollama), OpenCode
Setup
bd init
mem0 mcp server (stdio mode)
opencode

Session Start
bd ready --json                       # Find available tasks
search_memories("task_context")       # Retrieve relevant context
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
```

Example workflow:
1. `bd ready --json` → Get bd-1234 "Implement exercise handlers"
2. `search_memories("exercise handlers")` → Retrieve related patterns/decisions
3. Read results → Understand prior work in handlers, constraints, patterns
4. `bd update bd-1234 --status in_progress`
5. Start coding with full context

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

Example after completing bd-xxx (Encoder duplication):
```
save_memory("""
meal-planner: encoder consolidation - 9 tandoor handlers had 150-200 lines of duplicate pagination encoder logic. Extracted into query_builders.encode_list_response(). Pattern:
- build_pagination_params(limit, offset) → json.Object
- encode_list_response(items, count, next, prev) → string
Benefits: 1350+ lines eliminated, consistent error handling, single source of truth.
Related: bd-xxx (query_builders refactor)
""")
```

Beads (via MCP)
Beads accessed through OpenCode MCP tools (beads_*):

# Check ready tasks
beads_ready

# Update task status
beads_status taskId="bd-xxxx" status="in_progress"

# Create new task
beads_create title="Issue" parent="bd-xxxx"

# Close task
beads_close taskId="bd-xxxx" reason="Description"
Note: bd CLI commands also work directly for quick operations.
