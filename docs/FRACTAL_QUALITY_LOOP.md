# Fractal Quality Loop Workflow

## Overview

The Fractal Quality Loop is a systematic, multi-layer approach to ensuring code quality through iterative refinement. It combines linting, testing, code review, architecture analysis, and integration verification into a single comprehensive quality assurance process.

This workflow is designed to catch issues at multiple levels of abstraction—from syntax errors to architectural concerns—ensuring that code is not just syntactically correct, but also semantically sound and architecturally aligned.

## Core Philosophy

Quality emerges from **systematic validation at multiple scales**:

1. **Start broad** - Check overall structure and dependencies
2. **Zoom in** - Validate individual implementations
3. **Test thoroughly** - Verify correctness across layers
4. **Integrate** - Ensure components work together
5. **Re-loop** - Changes can introduce new issues

## The Five Quality Layers

### Layer 1: Foundation (Lint & Format)

**Goal**: Eliminate syntax errors and style issues before deeper analysis.

```bash
cd gleam
gleam format --check .
gleam build
```

**What to check:**
- Code formatting consistency
- Type safety (Gleam compiler warnings)
- Dead code and unused imports
- Style violations

**Filing issues:**
```bash
bd create "Lint: unused import in module_name" -t bug -p 1
```

**When Layer 1 is PASS:**
- No compiler warnings
- All files are properly formatted
- No unused code
- Ready for Layer 2

### Layer 2: Correctness (Tests)

**Goal**: Verify functional correctness through comprehensive testing.

```bash
cd gleam
gleam test
```

**What to check:**
- Unit test pass rate (target: 100%)
- Code coverage (target: >80%)
- Edge case handling
- Error path coverage

**Checking coverage:**
```bash
gleam test --verbose  # Shows test execution details
```

**Filing issues:**
```bash
bd create "Test failure: should_handle_empty_list" -t bug -p 0
bd create "Low coverage: storage.gleam at 65%" -t task -p 1
```

**When Layer 2 is PASS:**
- All tests pass with no failures
- Coverage is at target levels
- Edge cases are tested
- Error handling is validated

### Layer 3: Code Review (Recent Changes)

**Goal**: Ensure implementation quality, clarity, and consistency.

**Identify changed files:**
```bash
git diff --name-only HEAD~5
git log --oneline -10
```

**Review Criteria:**

#### 1. Clarity
- Is the code self-documenting?
- Are function and variable names meaningful?
- Are complex algorithms explained in comments?

```gleam
// Good: Clear intent
pub fn calculate_daily_macros(foods: List(Food)) -> Macros {
  // Group foods by meal type and sum nutrients
  foods
    |> list.group_by(fn(f) { f.meal_type })
    |> dict.map(sum_nutrients)
}

// Avoid: Cryptic names and logic
pub fn calc(f: List(Food)) -> Macros {
  f |> list.group_by(fn(a) { a.t }) |> dict.map(sum)
}
```

#### 2. Correctness
- Are edge cases handled?
- Is error handling comprehensive?
- Are nil/empty list cases covered?

```gleam
// Good: Handles all cases
pub fn get_food_by_id(id: Int) -> Result(Food, Error) {
  case fetch_from_db(id) {
    Ok(food) -> Ok(food)
    Error(NotFound) -> Error(FoodNotFound)
    Error(DBError(msg)) -> Error(DatabaseError(msg))
  }
}

// Avoid: Silent failures
pub fn get_food_by_id(id: Int) -> Food {
  fetch_from_db(id) |> option.unwrap(default_food)
}
```

#### 3. Consistency
- Does code follow project patterns from DEVELOPMENT.md?
- Are naming conventions consistent?
- Is error handling approach uniform?

```gleam
// Consistent with project: Always use Result types for operations that might fail
pub fn save_food_log(log: FoodLog) -> Result(Nil, Error) {
  use _ <- result.try(validate_log(log))
  use _ <- result.try(insert_into_database(log))
  Ok(Nil)
}
```

#### 4. Simplicity
- Is there unnecessary complexity?
- Could the logic be clearer?
- Are there opportunities to use library functions?

```gleam
// Simple: Use built-in list functions
let total = foods |> list.map(fn(f) { f.calories }) |> list.fold(0, int.add)

// Avoid: Manual recursion when not needed
let total = calculate_total_calories_recursive(foods, 0)
```

**Filing issues:**
```bash
bd create "Code Review: unclear variable names in food_search.gleam" -t task -p 2
bd create "Code Review: missing error handling in storage.gleam" -t bug -p 1
```

**Example review output:**

```
=== CODE REVIEW RESULTS ===

File: gleam/src/meal_planner/web/handlers/food_log.gleam
- ✅ Clear function names and purposes
- ⚠️ Missing nil checks for user_preferences (line 42)
- ⚠️ Inconsistent error return types (some Result, some option)

File: gleam/src/meal_planner/storage/logs.gleam
- ✅ Good separation of concerns
- ✅ Comprehensive error handling
- ✅ Well-documented public API

Issues Found: 2
```

### Layer 4: Architecture Analysis

**Goal**: Verify overall system design and structural integrity.

**Examine project structure:**
```bash
find gleam/src -type f -name "*.gleam" | head -20
```

**Check for:**

#### 1. Separation of Concerns
- Are business logic and I/O properly separated?
- Are handlers separate from storage?
- Is configuration isolated?

```
✅ Good Structure:
  src/meal_planner/
    web/          # HTTP handlers only
      handlers/
    storage/      # Database access only
      logs.gleam
      foods.gleam
    business/     # Pure business logic
      nutrition.gleam
      planner.gleam
    types.gleam   # Shared types

❌ Avoid:
  src/meal_planner/
    utils.gleam         # Unclear purpose
    handler_and_db.gleam  # Mixed concerns
```

#### 2. Dependency Flow
- Do dependencies flow in correct direction?
- Are circular dependencies avoided?
- Is the dependency graph acyclic?

```
✅ Good dependency flow:
  web/handlers → business → types ← storage
  (No cycles, clear direction)

❌ Avoid:
  web/handlers ←→ storage  (circular dependency)
  business → web/handlers  (business depends on presentation layer)
```

#### 3. Error Propagation
- Do errors bubble up correctly?
- Is error context preserved?
- Are errors handled at appropriate levels?

```gleam
// ✅ Good: Errors propagate upward with context
pub fn create_meal_plan(user_id: Int) -> Result(MealPlan, Error) {
  use preferences <- result.try(load_user_preferences(user_id))
  use foods <- result.try(search_foods_for_preferences(preferences))
  create_plan_from_foods(foods)
}

// ❌ Avoid: Swallowing errors
pub fn create_meal_plan(user_id: Int) -> MealPlan {
  let preferences = load_user_preferences(user_id) |> option.unwrap(defaults)
  let foods = search_foods_for_preferences(preferences) |> option.unwrap([])
  create_plan_from_foods(foods)
}
```

#### 4. Module Organization
- Are modules properly scoped?
- Is the public API clearly defined?
- Are internal implementation details hidden?

```gleam
// In storage/logs.gleam:
pub fn save_food_log(log: FoodLog) -> Result(Nil, Error) {
  // Public: called from handlers
}

// Internal: not in public API
fn validate_log_nutrients(log: FoodLog) -> Result(Nil, Error) {
  // Implementation detail
}
```

**Filing issues:**
```bash
bd create "Architecture: circular dependency between web and storage" -t bug -p 1
bd create "Architecture: business logic leaking into handlers" -t task -p 1
```

**Checklist:**
- [ ] No circular dependencies
- [ ] Clear separation of concerns
- [ ] Error handling is consistent
- [ ] Module organization is logical
- [ ] Public API is well-defined

### Layer 5: Integration Verification

**Goal**: Ensure all components compile and integrate correctly.

```bash
cd gleam
gleam build
```

**What to verify:**
- Project compiles without warnings
- All modules are accessible
- Type annotations are correct
- Dependencies are properly declared

**For web applications:**
```bash
# Test that server starts
gleam run &
PID=$!
sleep 2
curl http://localhost:8080/health || echo "Server not responding"
kill $PID
```

**Filing issues:**
```bash
bd create "Integration: server fails to start after recent changes" -t bug -p 0
```

**When Layer 5 is PASS:**
- Full project compiles
- No unresolved symbols
- All dependencies are available
- Server starts and responds to requests

## Fractal Re-Loop Logic

After completing all 5 layers:

1. **Count total issues found** across all layers
2. **Assess fixability**:
   - **Fixable now**: Fix issues following TDD, then re-run entire loop
   - **Not fixable**: File in Beads, document reasoning, proceed
3. **Re-loop if needed**: Every fix can introduce new issues
4. **Maximum iterations**: Cap at 5 loops to avoid infinite cycles

```
Decision Tree:

Issues Found?
├─ No → COMPLETE (all quality gates passed)
├─ Yes, fixable now?
│  ├─ Yes → FIX using TDD
│  │   ├─ Write test for the issue
│  │   ├─ Implement fix
│  │   ├─ Run tests → passes?
│  │   │  ├─ Yes → RE-LOOP from Layer 1
│  │   │  └─ No → REVERT fix
│  │   └─ Try different approach
│  └─ No → FILE to Beads
│      └─ COMPLETE (with documented issues)
└─ Iterations >= 5?
   ├─ Yes → STOP (file remaining, alert)
   └─ No → continue
```

## Beads Integration

### Starting a Quality Loop

```bash
# Mark task as in progress
bd update meal-planner-mf2k --status=in_progress

# Or create a new quality task if needed
bd create "Fractal quality loop: food_search module" -t task -p 1 --json
# Returns: meal-planner-xxxx (use this ID in messages)
```

### Filing Discovered Issues

```bash
# For each issue found:
bd create "Layer 2 test failure: should_filter_by_calories" -t bug -p 0
bd create "Layer 3 review: missing error handling" -t task -p 1
bd create "Layer 4 architecture: module X depends on module Y" -t task -p 2

# Link as discovered-from the quality loop:
# bd dep add <issue-id> <loop-task-id> --type discovered-from
```

### Completing the Loop

```bash
# When loop is complete:
bd close meal-planner-mf2k --reason "Quality loop complete: 3 issues found, 2 fixed, 1 filed for later"
bd sync
```

## Standard Quality Loop Session

### Pre-Work Checklist

```bash
# 1. Ensure you're on the right branch
git status

# 2. Mark task in progress
bd update meal-planner-mf2k --status=in_progress

# 3. Pull latest changes
git pull

# 4. Check for blocked dependencies
bd ready --json
```

### Execution Checklist

```bash
# LAYER 1: Lint & Format
cd gleam
gleam format --check .  # Identify formatting issues
gleam build             # Check for compiler warnings

# LAYER 2: Tests
gleam test              # Run all tests

# LAYER 3: Code Review
git diff --name-only HEAD~5  # Identify recent changes
# Manually review each changed file

# LAYER 4: Architecture
# Examine project structure visually
# Check for separation of concerns

# LAYER 5: Integration
gleam build             # Final compile check
# Start server and smoke test
```

### Post-Work Checklist

```bash
# 1. Summarize findings
# Create a report of issues found and fixed

# 2. File any remaining issues
bd create "<Issue description>" -t bug -p <0-2>

# 3. Close the task
bd close meal-planner-mf2k --reason "Quality loop complete"

# 4. Sync and push
bd sync
git add .
git commit -m "[meal-planner-mf2k] Fractal quality loop execution"
git push
```

## Example: Complete Quality Loop Session

### Starting

```bash
# Mark work in progress
cd /home/lewis/src/meal-planner
bd update meal-planner-mf2k --status=in_progress
```

### Layer 1: Lint

```bash
cd gleam
gleam format --check .

# Output:
# error: code/formatter/src/gleam/web/handlers/food_log.gleam is not formatted
# Run `gleam format . to format all files

gleam format .

# Issue found and fixed
```

### Layer 2: Tests

```bash
gleam test

# Output:
# compiling gleam/src...
# Collected 45 tests
# running
# ✓ meal_planner/storage_test ... (50.3ms)
# ✗ meal_planner/web_test ... (12.5ms)
#   Expected: Ok(food)
#   Got: Error(NotFound)
#
# 44 tests passed, 1 test failed

# Issue found: test failure in web_test.gleam
bd create "Layer 2 test failure: web_test - search_food_not_found" -t bug -p 0

# Check the test
# Found: missing test data setup
# Fix: Add food data to test database
# Re-run tests
gleam test  # ✓ all pass

# Re-loop from Layer 1
```

### Layer 3: Code Review

```bash
git diff --name-only HEAD~5
# gleam/src/meal_planner/web/handlers/food_log.gleam
# gleam/src/meal_planner/storage/logs.gleam

# Review food_log.gleam
# - Names are clear
# - Error handling uses Result consistently
# - No edge cases missed
# ✓ PASS

# Review logs.gleam
# - Function signatures are clear
# - Missing documentation comments on public functions
# ⚠️ Issue: add JSDoc-style comments

bd create "Layer 3 review: add doc comments to logs.gleam" -t task -p 2
# Fix: Add comments
# Re-run Layer 2 (tests still pass) → continue
```

### Layer 4: Architecture

```bash
# Check project structure
find gleam/src -type f -name "*.gleam" | sort

# Examine dependencies
# ✓ web/ only imports from business/ and types/
# ✓ storage/ only imports from types/
# ✓ No circular dependencies
# ✓ Error handling is consistent

# No architecture issues found
# ✓ PASS
```

### Layer 5: Integration

```bash
gleam build
# Compiling main ...
# Compiling meal_planner ...
# Successfully compiled meal_planner.

# ✓ PASS
```

### Summary & Completion

```
=== FRACTAL QUALITY LOOP - COMPLETE ===

Layer 1 (Lint):       ✓ PASS (1 issue found and fixed)
Layer 2 (Tests):      ✓ PASS (1 test failure found and fixed)
Layer 3 (Review):     ✓ PASS (1 doc issue filed)
Layer 4 (Architecture): ✓ PASS
Layer 5 (Integration):  ✓ PASS

Total Issues: 3
- Fixed in session: 2 (formatting, test failure)
- Filed to Beads: 1 (doc comments)
- Remaining: 0

Status: COMPLETE ✓
```

```bash
# Close the task
bd close meal-planner-mf2k --reason "Quality loop complete: 3 issues found, 2 fixed, 1 filed"
bd sync
git add .
git commit -m "[meal-planner-mf2k] Document fractal quality loop workflow"
git push
```

## Best Practices

### 1. Be Systematic

Never skip layers. Each layer builds on the previous:
- Lint catches syntax errors Layer 1 must pass before Layer 2
- Tests verify correctness Layer 2 must pass before Layer 3
- Code review happens after format is correct
- Architecture analysis informs refactoring
- Integration verification ensures nothing is broken

### 2. Use TDD for Fixes

When fixing issues found in the quality loop:

```bash
# 1. Write a test that demonstrates the issue
# In gleam/test/meal_planner/storage_test.gleam:
pub fn should_handle_null_description_test() {
  let food = Food(name: "Apple", description: option.None)
  assert Ok(_) = storage.save_food(food)
}

# 2. Run test (should fail)
gleam test  # ✗ fails

# 3. Implement fix
# In gleam/src/meal_planner/storage.gleam:
pub fn save_food(food: Food) -> Result(Nil, Error) {
  let description = option.unwrap(food.description, "")
  // ... save to database
}

# 4. Run tests (should pass)
gleam test  # ✓ passes

# 5. Commit fix
git add .
git commit -m "[meal-planner-mf2k] Fix: handle null description in food storage"

# 6. Re-loop from Layer 1
```

### 3. Document Your Process

After each layer, record findings:

```
=== LAYER 1 (Lint) ===
✓ All files properly formatted
✓ No compiler warnings
Status: PASS

=== LAYER 2 (Tests) ===
⚠️ 1 test failure: test_empty_food_list
   Fixed by: adding edge case handling
✓ Coverage: 87%
Status: PASS (after fix)

=== LAYER 3 (Code Review) ===
Files reviewed: food_search.gleam, logs.gleam
⚠️ 1 issue filed: add doc comments
Status: PASS (issues filed)
```

### 4. Set Reasonable Expectations

Quality loops typically find:
- **5-15 minor issues** in a typical session
- **1-3 significant issues** per module
- **0-2 architectural concerns** per component

If finding more:
- You may be over-critical (focus on correctness)
- Your codebase may have accumulated debt (file for future work)
- Project standards may be unclear (clarify in CLAUDE.md)

### 5. Know When to Stop

Stop looping when:
- All 5 layers pass with no new issues
- You've done 5 iterations (set a time limit)
- Remaining issues are properly filed and prioritized
- The code is ready for review/merge

## Common Issues & Solutions

### Issue: Formatter keeps changing code

**Problem**: `gleam format` changes code after you fix something

**Solution**: Run formatter as part of Layer 1, commit, then continue

```bash
gleam format .
git add .
git commit -m "format"
# Then continue from layer 2
```

### Issue: Test passes locally but fails in CI

**Problem**: Environment differences between local and CI

**Solution**: Check Layer 5 (Integration) more carefully

```bash
# Simulate CI environment
export LOG_LEVEL=debug
export DB_DEBUG=true
gleam test

# Compare with CI logs
# Fix any environment-specific issues
```

### Issue: Can't find where the issue is

**Problem**: Symptom is clear but root cause is hidden

**Solution**: Use git blame and check recent changes

```bash
git blame gleam/src/meal_planner/storage.gleam | grep "issue line"
git log -p -- gleam/src/meal_planner/storage.gleam | head -50

# Find when the bug was introduced
git bisect start
```

### Issue: Too many issues to fix in one session

**Problem**: Quality loop uncovers too much work

**Solution**: File aggressively to Beads

```bash
# Don't try to fix everything
bd create "Refactor: storage module has low cohesion" -t task -p 1
bd create "Docs: add comments to public API" -t task -p 2

# Prioritize and schedule
bd update <id> --priority 1  # Fix soon
bd update <id> --priority 2  # Nice to have

# Mark quality loop complete with remaining issues filed
```

## Reporting Results

### Format for Team Communication

```markdown
## Quality Loop Results: meal-planner-mf2k

### Executive Summary
- **Status**: COMPLETE ✓
- **Duration**: 45 minutes
- **Issues Found**: 5
- **Issues Fixed**: 3
- **Issues Filed**: 2

### By Layer
| Layer | Status | Issues | Notes |
|-------|--------|--------|-------|
| 1. Lint | ✓ | 1 fixed | Formatting |
| 2. Tests | ✓ | 1 fixed | Test failure |
| 3. Review | ✓ | 0 | Code quality good |
| 4. Architecture | ⚠️ | 2 filed | Tech debt items |
| 5. Integration | ✓ | 0 | Builds cleanly |

### Details

**Fixed in this session:**
- [x] meal-planner-abc: Format code (gleam format)
- [x] meal-planner-def: Fix test_empty_list failure

**Filed for later:**
- [ ] meal-planner-ghi: Add doc comments to storage.gleam
- [ ] meal-planner-jkl: Refactor food search module

### Recommendations
1. Prioritize doc comments (meal-planner-ghi) for next session
2. Consider architecture refactor for food search module
3. Consider adding type aliases for clarity

### Commit
```
[meal-planner-mf2k] Fractal quality loop: 3 issues fixed, 2 filed
```
```

## Integration with CI/CD

### Running quality loop in CI

```yaml
# .github/workflows/quality.yml
name: Quality Loop

on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Gleam
        uses: gleam-lang/setup-gleam@v1

      - name: Layer 1: Format check
        run: cd gleam && gleam format --check .

      - name: Layer 2: Tests
        run: cd gleam && gleam test

      - name: Layer 5: Build
        run: cd gleam && gleam build
```

## Checklist

Use this checklist before declaring a quality loop complete:

```
QUALITY LOOP COMPLETION CHECKLIST
==================================

PRE-WORK
[ ] Task marked in_progress: bd update <id> --status=in_progress
[ ] Latest changes pulled: git pull
[ ] No uncommitted changes: git status shows clean
[ ] Beads system accessible: bd ready --json works

LAYER 1: LINT
[ ] Code is formatted: gleam format --check . passes
[ ] No compiler warnings: gleam build succeeds
[ ] No dead code: unused imports removed
[ ] All linting issues filed or fixed

LAYER 2: TESTS
[ ] All tests pass: gleam test succeeds
[ ] Coverage adequate: >80% coverage
[ ] Edge cases tested: tested null, empty, boundary conditions
[ ] Error paths tested: tested error cases and recovery

LAYER 3: CODE REVIEW
[ ] Recent files reviewed: git diff --name-only HEAD~5
[ ] Names are clear: functions and variables are self-documenting
[ ] Error handling consistent: all Result/Option patterns match project style
[ ] No obvious bugs: edge cases, nil checks, bounds

LAYER 4: ARCHITECTURE
[ ] No circular dependencies: modules form a DAG
[ ] Separation of concerns: clear responsibility boundaries
[ ] Error propagation: errors bubble up correctly
[ ] Module organization: logical grouping

LAYER 5: INTEGRATION
[ ] Project builds: gleam build succeeds
[ ] No unresolved symbols: all modules compile
[ ] Server starts: gleam run starts without errors
[ ] Smoke tests pass: basic functionality works

POST-WORK
[ ] Issues summarized: clear record of what was found
[ ] Remaining issues filed: bd create for unfixed issues
[ ] Task closed: bd close meal-planner-mf2k --reason "..."
[ ] Changes committed: git commit -m "[meal-planner-mf2k] ..."
[ ] Changes pushed: git push

FINAL VERIFICATION
[ ] git status shows everything pushed
[ ] bd sync completed
[ ] No loose ends or files left open
```

## References

- [DEVELOPMENT.md](./DEVELOPMENT.md) - Development environment setup
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Project architecture
- [CLAUDE.md](../CLAUDE.md) - Claude Code agent workflow
- Gleam documentation: https://gleam.run

## Summary

The Fractal Quality Loop is a complete, systematic approach to code quality that:

1. **Eliminates surface errors** (Lint)
2. **Verifies correctness** (Tests)
3. **Ensures clarity** (Code Review)
4. **Maintains architecture** (Architecture)
5. **Guarantees integration** (Integration)

By following this workflow, you ensure that every line of code meets the project's quality standards and is ready for production.
