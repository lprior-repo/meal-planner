# Pick Up New Beads Task

Orchestrate superhuman AI-assisted development through strict TDD/TCR, semantic code navigation, persistent memory, and fractal iteration.

## Phase 0: Context Loading

**Memory Search** - Before ANY work:
```
Search memories for:
- "project:meal-planner" - project context
- "gleam patterns" - language idioms
- "recent decisions" - architectural context
- "{task_keywords}" - related past work
```

**Beads Discovery**:
```
1. mcp__beads__ready - Find unblocked tasks
2. mcp__beads__show {task_id} - Get full context (design, acceptance criteria)
3. mcp__beads__update {task_id} --status in_progress - Claim the work
```

## Phase 1: ARCHITECT (Specification)

**Render HUD**:
```
[TASK: {{Beads_ID}}] ── [ROLE: ARCHITECT]
├── LOCKS: (none yet)
├── CYCLE: Red (Spec Phase)
├── SWARM: [Spec: IN_PROGRESS] -> [Test: PENDING] -> [Impl: PENDING]
└── COMPLIANCE: [Gleam_Rules: CHECKING]
```

**Actions**:
1. **Serena Overview** - `mcp__serena__get_symbols_overview` on relevant modules
2. **Define Types** - Design custom types in `src/types.gleam` or domain module
3. **Create Fixture** - Add `test/fixtures/{feature}.json` for test data
4. **Memory Save** - Store architectural decision with rationale

**Gleam Type Checklist**:
- [ ] Custom types over primitives (no raw `Int` for IDs)
- [ ] `Result(T, E)` for fallible operations
- [ ] `Option(T)` for optional values
- [ ] Labeled arguments for >2 params
- [ ] `pub opaque type` with `new()` constructor for validation

## Phase 2: TESTER (Red Phase)

**Render HUD**:
```
[TASK: {{Beads_ID}}] ── [ROLE: TESTER]
├── LOCKS: test/{feature}_test.gleam
├── CYCLE: Red (Must FAIL)
├── SWARM: [Spec: DONE] -> [Test: IN_PROGRESS] -> [Impl: PENDING]
└── COMPLIANCE: [Gleam_Rules: ✓]
```

**Actions**:
1. **Find Test Location** - `mcp__serena__find_symbol` for existing test module
2. **Write ONE Test** - Single atomic assertion
3. **Run Test** - `make test` (parallel) or `gleam test`
4. **Verify FAILURE** - Must fail for the CORRECT reason

**Test Quality Gates**:
- [ ] Tests the behavior, not implementation
- [ ] Uses fixture data from Phase 1
- [ ] Descriptive test name: `{module}_{behavior}_test`
- [ ] Single assertion per test
- [ ] No test interdependencies

**If test passes unexpectedly**: STOP. Either:
- Behavior already exists (search with Serena)
- Test is wrong (rewrite)

## Phase 3: CODER (Green Phase)

**Render HUD**:
```
[TASK: {{Beads_ID}}] ── [ROLE: CODER]
├── LOCKS: src/{module}.gleam
├── CYCLE: Green (Minimal Pass)
├── SWARM: [Spec: DONE] -> [Test: DONE] -> [Impl: IN_PROGRESS]
└── COMPLIANCE: [Gleam_Rules: CHECKING]
```

**Actions**:
1. **Serena Navigate** - `mcp__serena__find_symbol` to locate insertion point
2. **Minimal Implementation** - "Fake it till you make it"
3. **Serena Edit** - `mcp__serena__insert_after_symbol` or `replace_symbol_body`
4. **Run Test** - `make test`

**TCR Decision Point**:
```
IF tests pass:
  → git add -A && git commit -m "GREEN: {behavior} (TCR Cycle N)"
  → GOTO Phase 4 (Refactor)

IF tests fail:
  → git reset --hard HEAD
  → Memory: Save what didn't work
  → GOTO Phase 3 with DIFFERENT strategy
```

**Gleam Implementation Checklist**:
- [ ] Pipe operator `|>` for transformations
- [ ] Exhaustive `case` matching (no catch-all `_` if avoidable)
- [ ] Tail-recursive with accumulator
- [ ] `gleam format --check` passes

## Phase 4: REFACTORER (Blue Phase)

**Render HUD**:
```
[TASK: {{Beads_ID}}] ── [ROLE: REFACTORER]
├── LOCKS: src/{module}.gleam
├── CYCLE: Blue (No Behavior Change)
├── SWARM: [Spec: DONE] -> [Test: DONE] -> [Impl: REFACTORING]
└── COMPLIANCE: [Gleam_Rules: ✓]
```

**Actions**:
1. **Serena Analyze** - `find_referencing_symbols` for impact analysis
2. **Apply Gleam Idioms**:
   - Extract pure functions
   - Improve naming
   - Reduce nesting with `use`
   - Consolidate error handling
3. **Run Tests** - Must still pass
4. **Commit** - `git commit -m "BLUE: Refactor {description} (TCR Cycle N)"`

## Phase 5: Iteration Decision

**Fractal Loop Check**:
```
INNER LOOP (within task):
- More test cases needed? → GOTO Phase 2
- Edge cases uncovered? → GOTO Phase 2
- Acceptance criteria met? → Continue

OUTER LOOP (task completion):
- All acceptance criteria satisfied? → GOTO Phase 6
- New sub-tasks discovered? → bd create --deps {current_task}
- Blocked by dependency? → bd update --status blocked
```

## Phase 6: Completion

**Actions**:
1. **Final Test Run** - `make test` - all green
2. **Format Check** - `gleam format --check`
3. **Memory Save**:
   - Pattern learned
   - Decision rationale
   - Solution approach
4. **Beads Close** - `mcp__beads__close {task_id} --reason "description"`
5. **Git Sync** - `git push`
6. **Beads Sync** - `bd sync`

## Impasse Protocol

**Trigger**: 3 consecutive reverts on same behavior

**Actions**:
1. STOP all coding
2. **Memory Search** - Similar past problems
3. **Serena Deep Dive** - `find_referencing_symbols` for broader context
4. **Strategy Pivot**:
   - ARCHITECT: Review type design
   - TESTER: Review test expectation
   - Output: "Strategy Change Proposal" before retry
5. **Memory Save** - Document the impasse and resolution

## Quick Reference

| Phase | Agent | Serena Tool | Beads Action |
|-------|-------|-------------|--------------|
| Spec | ARCHITECT | `get_symbols_overview` | `show` |
| Red | TESTER | `find_symbol` | - |
| Green | CODER | `insert_after_symbol` | - |
| Blue | REFACTORER | `find_referencing_symbols` | - |
| Done | - | - | `close` |

## Invocation

When user says "pick up task" or this skill is invoked:

1. Call `mcp__beads__ready` to find available work
2. Present options to user with priorities
3. On selection, begin Phase 0 with full context loading
4. Render HUD at each phase transition
5. Follow TCR strictly - revert on failure, commit on success
6. Save learnings to memory throughout
