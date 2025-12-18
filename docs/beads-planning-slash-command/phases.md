# Development Phases

Detailed breakdown of the TDD/TCR workflow phases.

## Phase Overview

```
Phase 0: Context Loading
    │
    ▼
Phase 1: ARCHITECT (Spec)
    │
    ▼
Phase 2: TESTER (Red)
    │
    ▼
Phase 3: CODER (Green)
    │         │
    │    [FAIL] → git reset --hard → retry
    │         │
    ▼    [PASS]
Phase 4: REFACTORER (Blue)
    │
    ▼
Phase 5: Iteration Decision
    │         │
    │    [MORE TESTS] → Phase 2
    │         │
    ▼    [COMPLETE]
Phase 6: Completion
```

## Phase 0: Context Loading

**Purpose**: Load all relevant context before starting work.

**Memory Queries**:
- Project-specific patterns and decisions
- Recent architectural changes
- Related bug fixes and solutions
- Gleam idioms and preferences

**Beads Operations**:
1. `mcp__beads__ready` - Find unblocked tasks
2. `mcp__beads__show` - Get task details, acceptance criteria
3. `mcp__beads__update --status in_progress` - Claim task

## Phase 1: ARCHITECT

**Purpose**: Define types, contracts, and test fixtures.

**HUD State**: `CYCLE: Red (Spec Phase)`

**Deliverables**:
- Custom type definitions in domain module
- Test fixtures in `test/fixtures/`
- Architectural decision saved to memory

**Gleam Rules Applied**:
- Rule 2: No nulls - `Option(T)` or `Result(T, E)`
- Rule 5: Labeled arguments for >2 params
- Rule 6: Type safety - custom types over primitives

## Phase 2: TESTER

**Purpose**: Write ONE failing test that defines the expected behavior.

**HUD State**: `CYCLE: Red (Must FAIL)`

**Critical**: The test MUST fail for the CORRECT reason.

**Quality Gates**:
- Single atomic assertion
- Behavior-focused, not implementation-focused
- Uses fixture data from Phase 1
- No dependencies on other tests

**Commands**:
```bash
make test        # Parallel execution (faster)
gleam test       # Sequential (debugging)
```

## Phase 3: CODER

**Purpose**: Write minimal implementation to make the test pass.

**HUD State**: `CYCLE: Green (Minimal Pass)`

**TCR Decision Tree**:
```
tests pass?
├── YES → git commit -m "GREEN: {behavior}"
│         → GOTO Phase 4
└── NO  → git reset --hard HEAD
          → Save failure to memory
          → Try DIFFERENT strategy
```

**Gleam Rules Applied**:
- Rule 1: Immutability - no `var`
- Rule 3: Pipe everything - `|>`
- Rule 4: Exhaustive matching
- Rule 7: Format or death

## Phase 4: REFACTORER

**Purpose**: Improve code structure without changing behavior.

**HUD State**: `CYCLE: Blue (No Behavior Change)`

**Common Refactorings**:
- Extract pure functions
- Improve naming
- Reduce nesting with `use`
- Consolidate error handling
- Apply Gleam idioms

**Validation**: Tests must still pass after refactoring.

## Phase 5: Iteration Decision

**Purpose**: Decide whether to continue or complete.

**Inner Loop** (within current task):
- More test cases needed? → Phase 2
- Edge cases uncovered? → Phase 2
- All behaviors covered? → Continue

**Outer Loop** (task completion):
- Acceptance criteria satisfied? → Phase 6
- New sub-tasks discovered? → `bd create --deps {current}`
- Blocked? → `bd update --status blocked`

## Phase 6: Completion

**Purpose**: Finalize and sync all work.

**Checklist**:
1. `make test` - All green
2. `gleam format --check` - Passes
3. Save learnings to memory
4. `mcp__beads__close` - Close task
5. `git push` - Sync code
6. `bd sync` - Sync beads

## Impasse Protocol

**Trigger**: 3 consecutive reverts on same behavior.

**Recovery Steps**:
1. STOP coding immediately
2. Search memory for similar problems
3. Deep-dive with `find_referencing_symbols`
4. Create "Strategy Change Proposal"
5. Get approval before retry
6. Document resolution in memory
