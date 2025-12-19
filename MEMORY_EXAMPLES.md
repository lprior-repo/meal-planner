# Memory Integration Examples

## Overview

This document provides concrete examples of memory entries following the schemas defined in MEMORY_INTEGRATION.md. Use these as templates when capturing knowledge.

---

## 1. Code Architecture Decisions

### Example 1: CrudHandler Abstraction

```
meal-planner: tandoor/handlers uses CrudHandler abstraction instead of inline handlers - rationale: reduces 2000+ lines duplication across 9 handlers (recipes, keywords, foods, units, categories, steps, shopping, books, tags), consistent error handling, testable via dependency injection. Pattern: single base type CrudHandler(config, list_fn, get_fn, create_fn, update_fn, delete_fn) with generic CRUD operations, type parameters for entity types (Recipe, Keyword, Food, etc.), shared validation/encoding logic via query_builders module. Files: src/meal_planner/tandoor/crud_handler.gleam, src/meal_planner/tandoor/*_handler.gleam (9 files). Benefits: DRY principle, single source of truth for HTTP status codes, consistent response envelopes, easier testing (inject mock functions). Related: bd-xxx (handler consolidation)
```

**Search Queries**:
- `search_memory_facts("tandoor handlers architecture")`
- `search_memory_facts("CrudHandler abstraction")`
- `search_memory_facts("handler duplication")`

---

### Example 2: Auth Module Extraction

```
meal-planner: auth module uses session_config/bearer_config pattern instead of inline auth logic - rationale: separates concerns (config vs execution), testable via dependency injection, reusable across handlers, supports multiple auth strategies. Pattern: AuthConfig(session: SessionConfig, bearer: BearerConfig) record holds credentials, add_auth_headers(request, config) → Request applies auth to HTTP requests, supports both cookie-based sessions and bearer tokens. Files: src/meal_planner/auth/session_config.gleam, src/meal_planner/auth/bearer_config.gleam, src/meal_planner/auth.gleam. Benefits: no hardcoded credentials, testable (inject mock configs), extensible (add OAuth/JWT later). Related: bd-8dcf1edd (auth extraction)
```

**Search Queries**:
- `search_memory_facts("auth module design")`
- `search_memory_facts("session_config pattern")`
- `search_memory_facts("authentication architecture")`

---

### Example 3: Query Builders Module

```
meal-planner: query_builders module consolidates pagination/encoding logic instead of duplicating across handlers - rationale: 9 handlers had 150-200 lines of duplicate encoder logic for list responses, single source of truth reduces bugs, consistent API response format. Pattern: build_pagination_params(limit, offset) → json.Object creates pagination metadata, encode_list_response(items, count, next, prev) → String encodes ListResponse envelope with results/count/pagination. Files: src/meal_planner/tandoor/query_builders.gleam, used by all tandoor/*_handler.gleam files. Benefits: 1350+ lines eliminated, consistent error handling, easier to modify response format globally. Related: bd-xxx (encoder consolidation)
```

**Search Queries**:
- `search_memory_facts("query_builders consolidation")`
- `search_memory_facts("pagination encoding")`
- `search_memory_facts("encoder duplication")`

---

## 2. Bug Root Cause + Solution

### Example 1: Pagination Parameters Bug

```
meal-planner: tandoor/query_builders bug - cause: limit/offset not parsed from URL query params, handlers defaulted to hardcoded values (limit=25, offset=0), fix: use gleam/http.get_query(request) → List(Tuple(String, String)) then parse "limit" and "offset" keys with int.parse(), default to 25/0 on parse failure, impact: pagination now works correctly in all 9 list handlers (recipes, keywords, foods, units, categories, steps, shopping, books, tags), users can navigate pages via ?limit=50&offset=100. Files: src/meal_planner/tandoor/query_builders.gleam. Pattern: http.get_query(req) |> list.key_find("limit") |> result.try(int.parse) |> result.unwrap(25). Related: bd-xxx (pagination refactor)
```

**Search Queries**:
- `search_memory_facts("pagination bug fix")`
- `search_memory_facts("query parameters parsing")`
- `search_memory_facts("gleam/http.get_query")`

---

### Example 2: Connectivity Module Compilation

```
meal-planner: connectivity module compilation bug - cause: circular dependency between connectivity.gleam and wisp_utils.gleam (wisp_utils imported connectivity, connectivity imported wisp_utils), Gleam compiler rejected circular imports, fix: removed wisp dependency from connectivity module, simplified to standalone health check logic with direct HTTP client calls, impact: project compiles successfully, health checks still functional. Files: src/meal_planner/connectivity.gleam (simplified), src/meal_planner/wisp_utils.gleam (unchanged). Pattern: break circular deps by moving shared logic to third module OR simplify one module to remove dependency. Related: bd-0606fb59 (compilation fix)
```

**Search Queries**:
- `search_memory_facts("circular dependency bug")`
- `search_memory_facts("connectivity module fix")`
- `search_memory_facts("Gleam compilation error")`

---

### Example 3: Mapper Type Errors

```
meal-planner: tandoor/mappers type errors - cause: dynamic.field() decoder expected exact field names but JSON used snake_case (e.g., "created_at") while Gleam types used PascalCase (e.g., CreatedAt), fix: update dynamic.field() calls to match JSON field names exactly, use snake_case strings in decoders, impact: all tandoor API responses now decode correctly (recipes, keywords, foods, etc.). Files: src/meal_planner/tandoor/mappers.gleam. Pattern: dynamic.field("created_at", dynamic.string) for JSON "created_at", not dynamic.field("CreatedAt", ...). Related: bd-0606fb59 (mapper fixes)
```

**Search Queries**:
- `search_memory_facts("mapper type errors")`
- `search_memory_facts("dynamic.field decoder")`
- `search_memory_facts("JSON field naming")`

---

## 3. Project Context Evolution

### Example 1: Scheduler CLI Enhancement

```
meal-planner: scheduler CLI enhancement - added execution history table and duration formatting. Changes: new --history flag shows last 10 execution runs with timestamp/duration/status columns, duration formatting uses birl.difference() → calculate milliseconds → format as human-readable (e.g., "2m 34s", "15s"), history stored in scheduler_execution_history table (schema: id, job_name, started_at, completed_at, duration_ms, status, error_message). Files: cli/scheduler.gleam (new --history command), src/meal_planner/scheduler/history.gleam (new module), schema/scheduler_execution_history.sql (migration). Benefits: visibility into job execution patterns, debugging failed runs, performance tracking over time. Related: bd-9ca881b8 (scheduler improvements)
```

**Search Queries**:
- `search_memory_facts("scheduler CLI history")`
- `search_memory_facts("execution tracking")`
- `search_memory_facts("duration formatting")`

---

### Example 2: MP Command Wrapper

```
meal-planner: development tooling - added mp command wrapper for simplified execution. Changes: new ./mp script in project root acts as wrapper around ./gleam/mp CLI binary, supports all subcommands (run, tandoor, scheduler, regenerate, --help), automatically builds CLI if not present, provides shorter command syntax. Files: mp (shell script), cli/meal_planner.gleam (CLI implementation). Benefits: developers use "./mp run" instead of "cd gleam && gleam run -m meal_planner/cli", consistent interface across team, auto-builds on first run. Related: bd-9eb9e9b5 (mp wrapper)
```

**Search Queries**:
- `search_memory_facts("mp command wrapper")`
- `search_memory_facts("development tooling")`
- `search_memory_facts("CLI wrapper script")`

---

### Example 3: Regenerate Command Implementation

```
meal-planner: regenerate command - implemented meal-planner-jobg regenerate subcommand for re-running failed jobs. Changes: new cli regenerate <job_id> command reads job from database, validates status (only regenerates failed jobs), re-executes with same parameters, updates status/timestamp on completion. Files: cli/scheduler.gleam (new regenerate subcommand), src/meal_planner/scheduler/regenerate.gleam (logic). Pattern: load job → validate failed → execute → update status. Benefits: recover from transient failures, no manual database manipulation, audit trail preserved. Related: bd-bde0e57d (regenerate feature)
```

**Search Queries**:
- `search_memory_facts("regenerate command")`
- `search_memory_facts("failed job recovery")`
- `search_memory_facts("scheduler job management")`

---

## 4. Test Patterns Discovered

### Example 1: HTTP Response Mocking

```
meal-planner: test pattern - HTTP response mocking for handler tests, usage: when testing handlers that make external HTTP calls (Tandoor API, Mealie API), avoid hitting real servers in tests, pattern: create ResponseMock(body: String, status: Int) type, use dependency injection via handler config record HandlerConfig(fetch: fn(Request) -> Result(Response, Error)), inject mock function in tests HandlerConfig(fetch: fn(_) { Ok(ResponseMock(body: "{\"count\": 10, \"results\": []}", status: 200)) }). Files: test/tandoor/integration/*_handler_test.gleam. Benefits: fast tests (no network), deterministic (no flaky API calls), testable error paths (inject 500 responses). Example: test_recipes_list() uses mock to return empty recipe list. Related: test/tandoor/integration/README.md
```

**Search Queries**:
- `search_memory_facts("test pattern HTTP mocking")`
- `search_memory_facts("handler dependency injection")`
- `search_memory_facts("ResponseMock pattern")`

---

### Example 2: Birdie Snapshot Testing

```
meal-planner: test pattern - Birdie snapshot testing for JSON responses, usage: when testing JSON HTTP responses from handlers, eliminates manual assertion boilerplate, automatically compares output to saved snapshot, pattern: import birdie → birdie.snap(response_body, title: "recipe list response") generates test/birdie_snapshots/*.accepted files on first run, subsequent runs compare to snapshot, update snapshots with birdie.review() command. Files: test/tandoor/*_handler_test.gleam (uses birdie). Benefits: catch unintended response format changes, visual diff on failures, less test code (no manual JSON assertions). Example: test_recipe_list_response() uses birdie.snap() instead of 50+ lines of assertion code. Related: birdie package docs
```

**Search Queries**:
- `search_memory_facts("test pattern snapshot testing")`
- `search_memory_facts("Birdie usage")`
- `search_memory_facts("JSON response testing")`

---

### Example 3: QCheck Property-Based Testing

```
meal-planner: test pattern - QCheck property-based testing for validation logic, usage: when testing functions with many input combinations (validators, parsers, encoders), generate random inputs to find edge cases, pattern: import qcheck → qcheck.test("property name", qcheck.int(), fn(random_int) { /* assertion */ }) generates 100 random test cases by default. Files: test/*_test.gleam (validation tests). Benefits: finds edge cases developers miss (negative numbers, empty strings, large values), higher confidence in correctness, less manual test case writing. Example: test_pagination_params() uses qcheck.int() to test limit/offset validation with random values. Related: qcheck package docs
```

**Search Queries**:
- `search_memory_facts("test pattern property based")`
- `search_memory_facts("QCheck usage")`
- `search_memory_facts("validation testing")`

---

## 5. Gleam Idiom Lessons

### Example 1: Result Chaining

```
meal-planner: gleam idiom - result chaining with result.try(), do: use result.try() for railway-oriented pipelines when handling multiple Result-returning functions, chains errors automatically without manual case statements, avoid: nested case statements for multiple Results (causes rightward drift, hard to read, error-prone). Example: parse_input(raw) |> result.try(validate) |> result.try(transform) |> result.map(encode) propagates errors from any step, only executes next step if Ok. Alternative: use expression for same pattern: use validated <- result.try(validate(input)). Files: most handler/business logic modules use this pattern. Related: gleam/result module docs, railway-oriented programming pattern
```

**Search Queries**:
- `search_memory_facts("gleam idiom result")`
- `search_memory_facts("railway oriented programming")`
- `search_memory_facts("result.try pipeline")`

---

### Example 2: Use Expression for Resources

```
meal-planner: gleam idiom - use expression for resource cleanup, do: use file <- simplifile.open("data.txt") ensures file closes after block even on error, automatic resource management, avoid: manual open → defer → close pattern (error-prone, easy to forget cleanup). Example: use conn <- pog.get_connection(pool) ensures database connection returns to pool after block, even if query fails. Files: storage.gleam (DB connections), any file I/O code. Pattern: use resource <- acquire_fn() → resource available in block → auto-cleanup. Related: gleam stdlib use expression docs, RAII pattern
```

**Search Queries**:
- `search_memory_facts("gleam idiom use expression")`
- `search_memory_facts("resource management")`
- `search_memory_facts("automatic cleanup")`

---

### Example 3: Pipe Operator Ordering

```
meal-planner: gleam idiom - pipe operator argument position, do: |> passes result to FIRST argument of next function by default, use function capture with _ for non-first positions, avoid: breaking pipelines with intermediate let bindings when capture syntax works. Example: data |> string.trim |> int.parse |> result.unwrap(0) |> int.add(5, _) where add(5, _) puts piped value as second arg. Alternative: data |> string.trim |> int.parse |> result.unwrap(0) |> fn(x) { int.add(5, x) } for clarity. Files: all modules use pipe extensively. Related: Gleam pipe operator docs, function capture syntax
```

**Search Queries**:
- `search_memory_facts("gleam idiom pipe operator")`
- `search_memory_facts("function capture syntax")`
- `search_memory_facts("pipeline readability")`

---

### Example 4: Pattern Matching Exhaustiveness

```
meal-planner: gleam idiom - exhaustive pattern matching, do: match ALL cases explicitly in case expressions, compiler enforces exhaustiveness for type safety, avoid: catch-all _ patterns when cases are knowable (hides bugs if new variants added). Example: case response_status { 200 -> Ok(data); 404 -> Error(NotFound); 500 -> Error(ServerError); _ -> Error(UnknownError) } is acceptable for unbounded Int, but case option { Some(val) -> use_val(val); None -> default() } should NOT use _ because Option only has 2 variants. Files: handlers, mappers use exhaustive matching. Related: Gleam compiler exhaustiveness checking
```

**Search Queries**:
- `search_memory_facts("gleam idiom pattern matching")`
- `search_memory_facts("exhaustive case expressions")`
- `search_memory_facts("type safety patterns")`

---

### Example 5: Labeled Arguments

```
meal-planner: gleam idiom - labeled arguments for clarity, do: use labeled arguments for functions with >2 parameters OR when parameter meaning is ambiguous, improves call-site readability, avoid: positional arguments for complex functions (hard to read, easy to swap arguments). Example: build_pagination_params(limit: 25, offset: 0) is clear, build_pagination_params(25, 0) requires checking function signature to understand. Pattern: define function with labels pub fn build(limit lim: Int, offset off: Int), call with labels build(limit: 25, offset: 0). Files: query_builders.gleam, handlers use labeled args extensively. Related: Gleam function syntax docs
```

**Search Queries**:
- `search_memory_facts("gleam idiom labeled arguments")`
- `search_memory_facts("function readability")`
- `search_memory_facts("parameter naming")`

---

## Search Query Cheat Sheet

### By Category

```
# Architecture decisions
search_memory_facts("architecture")
search_memory_facts("pattern")
search_memory_facts("abstraction")

# Bug fixes
search_memory_facts("bug")
search_memory_facts("fix")
search_memory_facts("error")

# Project context
search_memory_facts("consolidation")
search_memory_facts("enhancement")
search_memory_facts("refactor")

# Test patterns
search_memory_facts("test pattern")
search_memory_facts("mocking")
search_memory_facts("snapshot")

# Gleam idioms
search_memory_facts("gleam idiom")
search_memory_facts("result")
search_memory_facts("pipe")
```

---

### By Component

```
# Tandoor integration
search_memory_facts("tandoor")
search_memory_facts("handlers")
search_memory_facts("mappers")

# Authentication
search_memory_facts("auth")
search_memory_facts("session")
search_memory_facts("bearer")

# Database
search_memory_facts("query")
search_memory_facts("pagination")
search_memory_facts("storage")

# CLI tools
search_memory_facts("scheduler")
search_memory_facts("regenerate")
search_memory_facts("mp command")
```

---

### By Task

```
# Search by Beads ID
search_memory_facts("bd-8dcf1edd")
search_memory_facts("bd-9eb9e9b5")
search_memory_facts("bd-bde0e57d")

# Search by task name
search_memory_facts("auth extraction")
search_memory_facts("pagination refactor")
search_memory_facts("scheduler improvements")
```

---

## Usage Examples

### Starting New Task: Exercise Handlers

```bash
# 1. Get task
bd ready --json
# → bd-new-123 "Implement exercise handlers"

# 2. Search for context
search_memory_facts("exercise handlers")
# → No results (new feature)

search_memory_facts("tandoor handlers")
# → Returns CrudHandler abstraction pattern

search_memory_facts("handler architecture")
# → Returns consolidation examples

# 3. Start task with context
bd update bd-new-123 --status in_progress

# 4. Apply learned patterns
# → Use CrudHandler abstraction
# → Follow pagination pattern
# → Add tests with Birdie snapshots
```

---

### Completing Task: Auth Module Extraction

```bash
# 1. Finish implementation
git status
# M src/meal_planner/auth.gleam
# M src/meal_planner/auth/session_config.gleam
# M src/meal_planner/auth/bearer_config.gleam

# 2. Analyze changes
git diff --stat
# 3 files changed, 150 insertions(+), 75 deletions(-)

# 3. Check memory triggers
# ✓ Architecture decision (session_config/bearer_config pattern)
# ✓ Code consolidation (extracted auth logic)

# 4. Save memory
save_memory("""
meal-planner: auth module uses session_config/bearer_config pattern instead of inline auth logic - rationale: separates concerns (config vs execution), testable via dependency injection, reusable across handlers, supports multiple auth strategies. Pattern: AuthConfig(session: SessionConfig, bearer: BearerConfig) record holds credentials, add_auth_headers(request, config) → Request applies auth to HTTP requests, supports both cookie-based sessions and bearer tokens. Files: src/meal_planner/auth/session_config.gleam, src/meal_planner/auth/bearer_config.gleam, src/meal_planner/auth.gleam. Benefits: no hardcoded credentials, testable (inject mock configs), extensible (add OAuth/JWT later). Related: bd-8dcf1edd (auth extraction)
""")

# 5. Close task
bd close bd-8dcf1edd --reason "Auth module extracted, session/bearer configs separated"
```

---

## Anti-Examples: DO NOT Save These

### Example 1: Trivial Syntax Fix

```
# BAD - too trivial
meal-planner: fixed typo in function name

# Instead: don't save, commit directly
git commit -m "Fix typo in function name"
```

---

### Example 2: Obvious One-Liner

```
# BAD - no learning value
meal-planner: changed import from gleam/list to gleam/list.{map, filter}

# Instead: don't save, this is standard Gleam syntax
```

---

### Example 3: Already in Beads

```
# BAD - duplicates task description
meal-planner: implemented exercise handlers with CRUD operations

# Instead: Beads task already captures this intent
bd show bd-xxx
# Title: Implement exercise handlers
# Description: Add CRUD handlers for exercise entity
```

---

### Example 4: Generic Knowledge

```
# BAD - belongs in global CLAUDE.md
meal-planner: Gleam uses immutable data structures

# Instead: add to ~/.claude/CLAUDE.md or project CLAUDE.md
```

---

### Example 5: Temporary Debug Notes

```
# BAD - not persistent knowledge
meal-planner: debugging pagination, added io.debug() statements

# Instead: don't save, remove debug statements before commit
```

---

## Template: New Memory Entry

```
meal-planner: [COMPONENT] [DECISION/BUG/CHANGE] - [DETAILS]

Required sections:
- Component: [module/file path]
- What: [concise description]
- Why: [rationale/root cause]
- How: [pattern/solution]
- Impact: [scope/benefits]
- Files: [affected files]
- Related: [beads task ID]

Example:
meal-planner: [component] uses [pattern] instead of [alternative] - rationale: [why]. Pattern: [code pattern]. Files: [list]. Benefits: [quantified impact]. Related: [bd-xxx]
```

---

## Conclusion

These examples demonstrate:

1. **Specificity**: Concrete file paths, line counts, technical details
2. **Actionability**: Patterns that can be reapplied in future tasks
3. **Context**: Enough information to understand WHY decisions were made
4. **Searchability**: Keywords that make memories discoverable later

Use these templates when capturing your own learnings. Prioritize technical precision over prose style.
