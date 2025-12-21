# CLAUDE_MULTI_AGENT.md - Multi-Agent Orchestration

## MULTI-AGENT PROTOCOL

**Enabled:** Yes
**Tool:** Serena MCP + Beads (tasks) + Symbol Locking
**Max Parallel Agents:** 4 (Architect, Tester, Coder, Refactorer)
**Constraint:** All agents enforce Gleam*7_Commandments + TDD

---

## AGENT ROLES

| Agent | Phase | Responsibility | Parallel Constraint |
|-------|-------|-----------------|-------------------|
| **ARCHITECT** | Pre-Work | Define types, fixtures, contracts | Must complete FIRST |
| **TESTER** | RED | Write 1 failing test per sub-task | Starts after ARCHITECT locks types |
| **CODER** | GREEN | Minimal implementation, make test pass | Respects locked symbols, multiple CODERs in parallel |
| **REFACTORER** | BLUE | Optimize syntax/structure, no behavior change | Runs after CODER commits |

---

## SYMBOL LOCKING PROTOCOL

### MANDATORY for Multi-Agent Work

```bash
# Before editing any symbol
serena_lock_symbol(path, symbol_name)

# Make your changes
serena_replace_symbol_body(path, symbol, new_body)

# After commit
serena_unlock_symbol(path, symbol_name)
```

### How It Works

1. **Lock Acquire:** Agent calls `serena_lock_symbol(src/module.gleam, function_name)`
2. **Lock Held:** Other agents cannot edit that symbol
3. **Lock Release:** Automatic after `git commit` or manual `serena_unlock_symbol`
4. **Conflict:** If symbol is locked, agent yields and works on different symbol

### Deadlock Resolution

**Priority Order:** ARCHITECT > TESTER > CODER > REFACTORER

If two agents want same symbol:
1. Higher-priority agent proceeds
2. Lower-priority agent yields
3. Lower-priority retries after higher-priority commits and unlocks

---

## WORKFLOW: Single-Agent (Simple Task)

### Sequential Phases
```
1. ARCHITECT defines types
   └─> src/types.gleam: Type definitions
   └─> test/fixtures/valid.json: Test data

2. TESTER writes test (RED)
   └─> test/module_test.gleam
   └─> Must FAIL before CODER starts

3. CODER implements (GREEN)
   └─> src/module.gleam
   └─> Minimal code, make test pass

4. REFACTORER optimizes (BLUE)
   └─> Syntax, structure, readability
   └─> No behavior change

5. COMMIT
   └─> git commit -m "PASS: {{Behavior}}"
```

### Example: Single Feature
```bash
bd ready --json
# Find task: bd-1234 "Add login handler"

search_memories("login")
# Retrieve context from prior login work

bd update bd-1234 --status in_progress

# ARCHITECT phase (not always needed for simple tasks)
# TESTER: Write test/login_test.gleam (RED)
# CODER: Implement src/login.gleam (GREEN)
# REFACTORER: Polish
# Commit

bd close bd-1234 --reason "Login handler implemented and tested"
save_memory("login handler pattern used")
```

---

## WORKFLOW: Multi-Agent (Complex Feature)

### Setup Phase (ARCHITECT)
```bash
# 1. Create parent task
bd create --title "Feature: Exercise API"
# Creates bd-5000

# 2. ARCHITECT defines all types + fixtures
# src/types.gleam:
#   - ExerciseId type
#   - Exercise type
#   - ListResponse type
#
# test/fixtures/exercise.json (sample data)
#
# Lock symbols (protection until feature complete):
serena_lock_symbol(src/types.gleam, exercise_id)
serena_lock_symbol(src/types.gleam, exercise)
serena_lock_symbol(src/types.gleam, list_response)
```

### Sub-Task Creation
```bash
# 3. Create sub-tasks for parallel work
bd create --parent bd-5000 --title "Write handler tests"   # bd-5001 (TESTER)
bd create --parent bd-5000 --title "Implement handlers"    # bd-5002 (CODER_1)
bd create --parent bd-5000 --title "Implement encoders"    # bd-5003 (CODER_2)
bd create --parent bd-5000 --title "Implement queries"     # bd-5004 (CODER_3)
bd create --parent bd-5000 --title "Refactor & optimize"   # bd-5005 (REFACTORER)
```

### Parallel Execution
```bash
# TESTER: Write all tests (RED phase, all in parallel)
bd update bd-5001 --status in_progress
# Write: test/handlers_test.gleam (get_exercises, get_exercise)
# Write: test/encoders_test.gleam (encode_exercise, encode_list)
# Write: test/queries_test.gleam (find_by_id, list_all)
bd close bd-5001 --reason "All tests written and failing"

# CODER_1: Implement handlers (GREEN phase)
bd update bd-5002 --status in_progress
serena_lock_symbol(src/handlers.gleam, get_exercises)
serena_lock_symbol(src/handlers.gleam, get_exercise)
# Implement handlers
make test  # Pass
git commit -m "PASS: Exercise handlers implemented"
serena_unlock_symbol(src/handlers.gleam, get_exercises)
serena_unlock_symbol(src/handlers.gleam, get_exercise)
bd close bd-5002 --reason "Handlers implemented"

# CODER_2: Implement encoders (GREEN phase, in parallel with CODER_1)
bd update bd-5003 --status in_progress
serena_lock_symbol(src/encoders.gleam, encode_exercise)
serena_lock_symbol(src/encoders.gleam, encode_list)
# Implement encoders
make test  # Pass
git commit -m "PASS: Exercise encoders implemented"
serena_unlock_symbol(src/encoders.gleam, encode_exercise)
serena_unlock_symbol(src/encoders.gleam, encode_list)
bd close bd-5003 --reason "Encoders implemented"

# CODER_3: Implement queries (GREEN phase, in parallel)
bd update bd-5004 --status in_progress
serena_lock_symbol(src/queries.gleam, find_by_id)
serena_lock_symbol(src/queries.gleam, list_all)
# Implement queries
make test  # Pass
git commit -m "PASS: Exercise queries implemented"
serena_unlock_symbol(src/queries.gleam, find_by_id)
serena_unlock_symbol(src/queries.gleam, list_all)
bd close bd-5004 --reason "Queries implemented"

# REFACTORER: Final polish (BLUE phase, sequential after CODERs)
bd update bd-5005 --status in_progress
# Review all implementations
# Consolidate patterns, reduce duplication
serena_lock_symbol(src/handlers.gleam, consolidate)
# Refactor
make test  # Still pass
git commit -m "REFACTOR: Consolidate handler patterns"
serena_unlock_symbol(src/handlers.gleam, consolidate)
bd close bd-5005 --reason "Feature optimized"

# Close parent task
bd close bd-5000 --reason "Exercise API complete, all tests passing"
save_memory("multi-agent pattern: parallel handler/encoder/query implementation")
```

### Timeline Comparison
```
Sequential (1 agent):
  ARCHITECT: 30min
  TESTER:    20min
  CODER_1:   40min
  CODER_2:   40min
  CODER_3:   40min
  REFACTORER: 10min
  ─────────────────
  TOTAL:    180min

Parallel (4 agents):
  ARCHITECT: 30min (blocker)
  ↓
  TESTER, CODER_1, CODER_2, CODER_3: 40min (parallel)
  ↓
  REFACTORER: 10min
  ─────────────────
  TOTAL:     80min  (55% faster)
```

---

## COORDINATION RULES

### All Agents, Single Branch
```bash
# All agents work on SAME branch
# All commits go to claude/feature-xxx

# Example commits:
git commit -m "PASS: Handlers - GET /exercises"
git commit -m "PASS: Encoders - encode_exercise"
git commit -m "PASS: Queries - find_by_id"
git commit -m "REFACTOR: Consolidate error handling"

# Final validation
make test  # ALL tests must pass
```

### No Merge Conflicts
- Symbol locking prevents edit conflicts
- Different modules = no file conflicts
- All commits go to same branch linearly

### Final Validation
```bash
# After all agents commit
make test  # Parallel, 0.8s
# All tests pass?
#   → Feature is ready
#   → Push to remote
# Any failures?
#   → Identify which agent's work broke
#   → Revert that agent's last commit
#   → Agent reverts and tries different approach (see CLAUDE_TCR.md)
```

---

## REVERT PROTOCOL (Multi-Agent)

### Single Revert (Normal)
```
IF test fails after CODER commits:
  → Only that CODER reverts: git reset --hard
  → Try different implementation strategy
  → Other CODERs continue
```

### Multi-Revert (3+ failures on same task)
```
IF same CODER reverts 3 times:
  → STOP all agents
  → Lock the symbol
  → ARCHITECT validates type definition
  → TESTER validates test expectation
  → CODER re-plans implementation
  → Try new strategy
```

### Deadlock on Locked Symbol
```
IF CODER_A needs symbol that CODER_B locked:
  → Check CODER_B's progress
  → IF CODER_B done: wait for unlock
  → IF CODER_B stuck: priority-resolve (see DEADLOCK_RESOLUTION above)
```

---

## COMMIT STRATEGY

### Single-Agent
```bash
git commit -am "PASS: {{Behavior}}"
```

### Multi-Agent
```bash
# Each agent commits independently after GREEN
git add src/module_x.gleam
git commit -m "PASS: Module X - {{Behavior}}"

# Next agent works on module_y
git add src/module_y.gleam
git commit -m "PASS: Module Y - {{Behavior}}"

# REFACTORER final commit
git add src/*
git commit -m "REFACTOR: {{Feature}} - consolidated patterns"
```

---

## COMMAND REFERENCE

### Serena Commands
```bash
# Navigation
serena_find_symbol(symbol_name)
serena_find_referencing_symbols(symbol_name)

# Locking (MANDATORY for multi-agent)
serena_lock_symbol(path, symbol)
serena_unlock_symbol(path, symbol)

# Editing (respects locks)
serena_replace_symbol_body(path, symbol, new_body)
serena_insert_after_symbol(path, symbol, new_code)
serena_rename_symbol(path, old_name, new_name)
```

### Beads Commands
```bash
# Parent task
bd create --title "Feature: Exercise API"

# Sub-tasks
bd create --parent bd-5000 --title "Write tests"
bd create --parent bd-5000 --title "Implement handlers"

# Status
bd update bd-5001 --status in_progress
bd close bd-5001 --reason "Tests passing"

# Sync
bd sync
```

---

## CHECKLIST: Multi-Agent Feature

- [ ] ARCHITECT defines all types (src/types.gleam)
- [ ] ARCHITECT creates all fixtures (test/fixtures/*.json)
- [ ] ARCHITECT locks type symbols
- [ ] Sub-tasks created in Beads for each module
- [ ] TESTER writes all tests (RED phase)
- [ ] Each CODER locks symbol before edit
- [ ] Each CODER implements (GREEN phase)
- [ ] Each CODER unlocks symbol after commit
- [ ] All tests pass: `make test`
- [ ] REFACTORER optimizes (BLUE phase)
- [ ] Final commit: "REFACTOR: ..."
- [ ] Parent task closed: `bd close bd-xxxx`
- [ ] Memory saved: multi-agent pattern

---

**Multi-agent work is safe when symbol locking is strict and commits are atomic.**
