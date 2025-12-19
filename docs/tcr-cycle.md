# TCR Cycle: Test/Commit/Revert

## Philosophy

TCR (Test/Commit/Revert) is a strict development discipline that eliminates broken states from version control. Unlike traditional TDD (Test-Driven Development), TCR enforces an unforgiving rule:

**If tests fail, code is DELETED, not debugged.**

This forces:
- **Smaller steps** (less code to lose)
- **Better thinking** (plan before typing)
- **Faster feedback** (tests run every few minutes)
- **Clean history** (every commit is green)

## The Cycle

```
┌─────────────────────────────────────────────────┐
│                 TCR CYCLE                       │
└─────────────────────────────────────────────────┘

1. RED Phase (TESTER)
   ├── Write failing test
   ├── Run test (MUST fail)
   └── Verify failure reason is correct
         ↓
2. GREEN Phase (CODER)
   ├── Write minimal implementation
   ├── Run test
   ├─→ PASS? → Go to step 3
   └─→ FAIL? → REVERT (git reset --hard)
         ↓
3. COMMIT Phase
   ├── Run quality checks (format, build)
   ├─→ PASS? → git commit
   └─→ FAIL? → REVERT (git reset --hard)
         ↓
4. BLUE Phase (REFACTORER) [Optional]
   ├── Improve code structure
   ├── Run ALL tests
   ├─→ PASS? → git commit
   └─→ FAIL? → REVERT (git reset --hard)
         ↓
5. Repeat for next behavior
```

## Phase Breakdown

### Phase 1: RED (Write Failing Test)

**Actor:** TESTER agent

**Goal:** Establish a concrete, verifiable expectation for new behavior.

**Steps:**
1. Create test file (if new module): `test/MODULE_test.gleam`
2. Write ONE test case for ONE behavior
3. Run test: `gleam test`
4. Verify test FAILS for the CORRECT reason

**Example:**

```gleam
// test/meal_planner_test.gleam
import gleeunit/should
import meal_planner/planner

pub fn calculate_daily_calories_test() {
  let meals = [
    planner.Meal(name: "Breakfast", calories: 400),
    planner.Meal(name: "Lunch", calories: 600),
    planner.Meal(name: "Dinner", calories: 800),
  ]

  planner.calculate_daily_calories(meals)
  |> should.equal(1800)
}
```

**Run test:**
```bash
$ gleam test
Compiling meal_planner
  error: Unknown variable calculate_daily_calories

✗ Test failed (correct failure reason)
```

**Incorrect failure reasons (must fix test):**
- Test passes (you're not testing new behavior)
- Import error (wrong module path)
- Syntax error (fix test code)

**Commit:**
```bash
git add test/meal_planner_test.gleam
git commit -m "RED: Add test for daily calorie calculation - meal-planner-abc"
```

### Phase 2: GREEN (Make Test Pass)

**Actor:** CODER agent

**Goal:** Write the MINIMAL code to make the test pass. No gold-plating.

**Rules:**
- Implement ONLY what the test requires
- Prefer "fake it till you make it" (hardcode if test allows)
- No refactoring yet (that's Phase 4)
- No additional features

**Example:**

```gleam
// src/meal_planner/planner.gleam
import gleam/list
import gleam/int

pub type Meal {
  Meal(name: String, calories: Int)
}

pub fn calculate_daily_calories(meals: List(Meal)) -> Int {
  meals
  |> list.map(fn(meal) { meal.calories })
  |> list.fold(0, int.add)
}
```

**Run test:**
```bash
$ gleam test
Compiling meal_planner
Running meal_planner_test.gleam

✓ calculate_daily_calories_test
```

**If test PASSES:**
```bash
# Run quality checks
gleam format --check
gleam build

# If all pass, commit
git add src/meal_planner/planner.gleam
git commit -m "GREEN: Implement daily calorie calculation - meal-planner-abc"
```

**If test FAILS:**
```bash
# DELETE the implementation
git reset --hard

# Think about why it failed
# Try a DIFFERENT approach
# Repeat Phase 2
```

### Phase 3: COMMIT (Lock in Green State)

**Actor:** Automated (or CODER agent)

**Goal:** Ensure code is production-quality before committing.

**Checks:**
```bash
# 1. Format check
gleam format --check
# FAIL? → git reset --hard (formatter found structural issues)

# 2. Build check
gleam build
# FAIL? → git reset --hard (type errors, missing imports)

# 3. Test check (all tests, not just new one)
gleam test
# FAIL? → git reset --hard (broke existing functionality)
```

**Commit message format:**
```
GREEN: <Behavior description> - <Beads task ID>

Examples:
GREEN: Implement daily calorie calculation - meal-planner-abc
GREEN: Add pagination to recipe list - meal-planner-xyz
GREEN: Fix division by zero in macro calculator - meal-planner-bug-123
```

**If ANY check fails:**
```bash
git reset --hard
# Code is deleted
# Return to Phase 2 with a new approach
```

### Phase 4: BLUE (Refactor)

**Actor:** REFACTORER agent

**Goal:** Improve code structure WITHOUT changing behavior.

**Rules:**
- Tests must pass BEFORE refactoring
- Tests must pass AFTER refactoring
- No new features
- No new tests (behavior unchanged)

**Example refactorings:**
```gleam
// Before (works but verbose)
pub fn calculate_daily_calories(meals: List(Meal)) -> Int {
  meals
  |> list.map(fn(meal) { meal.calories })
  |> list.fold(0, int.add)
}

// After (more idiomatic Gleam)
pub fn calculate_daily_calories(meals: List(Meal)) -> Int {
  list.fold(meals, 0, fn(acc, meal) { acc + meal.calories })
}
```

**Run ALL tests:**
```bash
$ gleam test
Running meal_planner_test.gleam

✓ calculate_daily_calories_test
✓ calculate_weekly_average_test
✓ filter_high_calorie_meals_test

All tests passed
```

**Commit:**
```bash
git add src/meal_planner/planner.gleam
git commit -m "BLUE: Simplify calorie calculation with direct fold - meal-planner-abc"
```

**If ANY test fails:**
```bash
git reset --hard
# Refactoring broke something
# Revert to last green commit
# Try a safer refactoring
```

## TCR vs TDD Comparison

| Aspect | TDD | TCR |
|--------|-----|-----|
| Test fails | Debug implementation | **Delete implementation** |
| Commit frequency | When feature complete | **Every green test** |
| Broken commits | Possible (WIP commits) | **Impossible** (always green) |
| Debugging time | Variable (can be hours) | **Zero** (code deleted instead) |
| Step size | Variable | **Forced small** (fear of revert) |
| History quality | Mixed | **Always clean** |

## Revert Protocol

### When to Revert

**IMMEDIATE revert if ANY of these occur:**
1. Test fails after implementation
2. `gleam format --check` fails
3. `gleam build` fails
4. Any existing test breaks
5. Refactoring changes behavior

### How to Revert

```bash
# Nuclear option (deletes ALL uncommitted changes)
git reset --hard

# Verify clean state
git status
# Should show: "nothing to commit, working tree clean"

# Verify tests still pass
gleam test
# Should show all green (last committed state)
```

### After Revert

1. **Reflect:** Why did the implementation fail?
2. **Simplify:** Can you test/implement a smaller piece?
3. **Rewrite:** Try a DIFFERENT approach (not debugging old code)

**Example revert scenarios:**

**Scenario 1: Test fails**
```bash
$ gleam test
✗ calculate_daily_calories_test
  Expected: 1800
  Got: 1801

# Don't debug! Revert.
$ git reset --hard
$ git status
# Clean

# Rethink: Maybe I added calories wrong? Try a simpler fold approach.
```

**Scenario 2: Format fails**
```bash
$ gleam format --check
error: src/planner.gleam needs formatting

# Don't format! Code structure is wrong.
$ git reset --hard

# Rethink: Formatter struggled because function is too complex.
# Simplify or break into smaller functions.
```

## Impasse Handling

**Trigger:** 3 consecutive reverts on the same test.

**Protocol:**
1. **STOP coding immediately**
2. **Convene swarm:** ARCHITECT, TESTER, CODER review together
3. **ARCHITECT reviews:** Is the type definition correct?
4. **TESTER reviews:** Is the test expectation correct?
5. **CODER reviews:** Is the approach fundamentally flawed?
6. **Output:** "Strategy Change Proposal" document
7. **Reset:** Start RED phase again with new strategy

**Example impasse:**

```
Attempt 1: REVERT (forgot to handle empty list)
Attempt 2: REVERT (used wrong fold direction)
Attempt 3: REVERT (type mismatch in accumulator)

→ IMPASSE

ARCHITECT: "Should calculate_daily_calories return Result instead of Int?"
TESTER: "Should we test empty list case separately first?"
CODER: "Should we use list.map + list.fold instead of single fold?"

DECISION: Separate test for empty list, then test for normal case.
```

## Integration with Beads

Every TCR cycle maps to a Beads task:

```bash
# Start task
bd update meal-planner-abc --status in_progress

# RED phase
vim test/planner_test.gleam
gleam test  # Fails correctly
git add test/planner_test.gleam
git commit -m "RED: Add test for calorie calculation - meal-planner-abc"

# GREEN phase
vim src/planner.gleam
gleam test  # Passes
gleam format --check && gleam build  # All pass
git add src/planner.gleam
git commit -m "GREEN: Implement calorie calculation - meal-planner-abc"

# BLUE phase (optional)
vim src/planner.gleam  # Refactor
gleam test  # Still passes
git add src/planner.gleam
git commit -m "BLUE: Simplify calorie fold - meal-planner-abc"

# Complete task
bd close meal-planner-abc --reason "Implemented daily calorie calculation with tests"
```

## Metrics and Health

Track TCR discipline:

```bash
# Revert rate (should be LOW but not zero)
# Zero = steps too small (inefficient)
# >50% = steps too large (chaotic)
git log --oneline --grep="REVERT" | wc -l
git log --oneline --grep="GREEN\|BLUE" | wc -l

# Commit frequency (should be HIGH)
# Every 5-15 minutes in active development
git log --since="1 day ago" --oneline | wc -l

# Test coverage (should be 100% of public functions)
grep -r "pub fn" src/ | wc -l
grep -r "_test() {" test/ | wc -l
```

## Anti-Patterns

### ❌ "Let me just debug this quickly"
**Problem:** Defeats TCR purpose. Debugging broken code = time spent on wrong solution.

**Fix:** Revert immediately. Think before next attempt.

### ❌ Writing multiple tests before implementation
**Problem:** If implementation fails, which test is wrong?

**Fix:** ONE test, ONE implementation, ONE commit. Repeat.

### ❌ Committing "WIP" or "almost working"
**Problem:** Broken commits accumulate, history is polluted.

**Fix:** Only commit when ALL checks pass. Use stash or reverts.

### ❌ Skipping quality checks
**Problem:** Broken code enters history, fractal loop broken.

**Fix:** Automate checks (pre-commit hook) or use `make test` wrapper.

### ❌ Large implementations
**Problem:** High revert cost (lose hours of work).

**Fix:** Smaller steps. If scared to revert, implementation is too big.

## Automation

### Pre-commit hook
```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running TCR quality checks..."

gleam format --check
if [ $? -ne 0 ]; then
  echo "❌ Format check failed. Run 'gleam format' or revert."
  exit 1
fi

gleam build
if [ $? -ne 0 ]; then
  echo "❌ Build failed. Fix errors or revert."
  exit 1
fi

gleam test
if [ $? -ne 0 ]; then
  echo "❌ Tests failed. Fix implementation or revert."
  exit 1
fi

echo "✅ All checks passed. Committing..."
```

### Makefile wrapper
```makefile
# Makefile
.PHONY: tcr-check
tcr-check:
	@gleam format --check && \
	gleam build && \
	gleam test && \
	echo "✅ TCR: Ready to commit" || \
	echo "❌ TCR: Must revert (git reset --hard)"
```

Usage:
```bash
make tcr-check && git commit -m "GREEN: feature" || git reset --hard
```

## Related Documentation

- [fractal-quality-loop.md](./fractal-quality-loop.md) - Quality validation at all scales
- [gleam-7-commandments.md](./gleam-7-commandments.md) - Language rules enforced by TCR
- [multi-agent-workflow.md](./multi-agent-workflow.md) - Agent roles in TCR cycle
- [quality-gates.md](./quality-gates.md) - Automated validation gates

## References

- CLAUDE.md section: `TCR_STRICT_MODE`
- CLAUDE.md section: `OPERATIONAL_PROTOCOLS`
- Kent Beck's "Test-Driven Development: By Example"
- TCR (test && commit || revert) original concept by Kent Beck and Oddmund Strømme
