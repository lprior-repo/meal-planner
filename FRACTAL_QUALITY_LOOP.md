# Fractal Quality Loop Workflow

## Overview

The Fractal Quality Loop is a systematic, multi-pass quality assurance workflow that ensures code quality through layered validation. It operates on a "fractal" principle: starting broad, drilling deep, and zooming out to verify holistic integrity. Each pass builds on the previous one, creating increasingly refined quality gates.

## Philosophy

Excellence emerges from systematic, recursive validation. The fractal approach means:
- Each layer validates different quality dimensions
- Issues found trigger a complete re-check (the "loop")
- Quality improves iteratively until all gates pass
- No issue escapes undetected or unfiled

## The 4-Pass Workflow

### Pass 1: Unit Tests (Foundation)

**Purpose**: Verify individual components work correctly in isolation.

**Execution**:
```bash
gleam test
gleam test --target erlang
```

**Validation Criteria**:
- All unit tests pass (100% pass rate)
- No test flakiness or race conditions
- Property-based tests (qcheck) validate edge cases
- Individual functions behave correctly

**On Failure**:
- File bead: `bd create "Unit test failure: <test_name>" -t bug -p 0`
- Fix immediately (TDD: fix code, verify test passes)
- Re-run entire loop from Pass 1

**Truth Score Component**: `unit_pass_rate = passing_tests / total_tests`

---

### Pass 2: Integration Tests (Interaction)

**Purpose**: Verify components work together correctly.

**Execution**:
```bash
gleam test --module postgres_test
gleam test --module food_log_api_test
gleam test --module tandoor_sync_test
```

**Validation Criteria**:
- Database operations succeed
- API endpoints return expected responses
- External service integrations work (Tandoor, PostgreSQL)
- Multi-step workflows complete successfully

**On Failure**:
- File bead: `bd create "Integration test failure: <workflow>" -t bug -p 0`
- Investigate component interactions
- Fix integration issues
- Re-run entire loop from Pass 1

**Truth Score Component**: `integration_pass_rate = passing_integration_tests / total_integration_tests`

---

### Pass 3: End-to-End Tests (User Flows)

**Purpose**: Verify complete user workflows function correctly.

**Execution**:
```bash
gleam test --module e2e_food_logging_test
gleam test --module e2e_recipe_creation_test
gleam test --module e2e_meal_planning_test
```

**Validation Criteria**:
- Complete user workflows execute successfully
- Web handlers return correct HTML/JSON
- Database state changes persist correctly
- Error handling provides good UX
- HTMX interactions work as expected

**On Failure**:
- File bead: `bd create "E2E test failure: <user_flow>" -t bug -p 0`
- Trace the complete flow
- Fix workflow issues
- Re-run entire loop from Pass 1

**Truth Score Component**: `e2e_pass_rate = passing_e2e_tests / total_e2e_tests`

---

### Pass 4: Manual Review (Quality & Architecture)

**Purpose**: Human review of code quality, architecture, and best practices.

**Review Checklist**:

1. **Code Quality**:
   - [ ] Functions are small and focused (< 50 lines)
   - [ ] Meaningful variable and function names
   - [ ] No code duplication (DRY principle)
   - [ ] Error handling is comprehensive
   - [ ] Pattern matching used appropriately

2. **Architecture**:
   - [ ] Separation of concerns maintained
   - [ ] Storage layer properly isolated
   - [ ] Web handlers don't contain business logic
   - [ ] Types are well-defined and composable
   - [ ] Dependencies flow correctly

3. **Gleam Best Practices**:
   - [ ] Pure functions where possible
   - [ ] Result types used instead of exceptions
   - [ ] Immutable data structures
   - [ ] No JavaScript files (HTMX only)
   - [ ] Server-side rendering with Lustre

4. **Documentation**:
   - [ ] Public functions have doc comments
   - [ ] Complex algorithms explained
   - [ ] README updated if needed
   - [ ] CLAUDE.md reflects new patterns

**Execution**:
```bash
# Review recent changes
git diff --name-only HEAD~5

# Check for recent commits
git log --oneline -10

# Read modified files
cat gleam/src/meal_planner/web/handlers/recipes.gleam
```

**On Issues Found**:
- File bead: `bd create "Code quality: <specific_issue>" -t task -p 2`
- Document architectural concerns
- If critical, fix immediately and re-loop
- If minor, file for later improvement

**Truth Score Component**: `review_score = 1.0 - (critical_issues_found / total_checks)`

---

## Truth Score Calculation

The overall quality "truth score" aggregates all four passes:

```
truth_score = (unit_pass_rate + integration_pass_rate + e2e_pass_rate + review_score) / 4.0
```

**Interpretation**:
- `>= 0.95` - Excellent quality, ready to ship
- `0.90 - 0.94` - Good quality, minor improvements needed
- `0.80 - 0.89` - Acceptable, but has notable issues
- `< 0.80` - Poor quality, significant work required

**Auto-Rollback Trigger**: If `truth_score < 0.95` after all fixes attempted, consider rolling back the change and filing beads for proper implementation.

---

## Example: Good Score (>= 0.95)

```
=== FRACTAL QUALITY LOOP - Iteration 2 ===

PASS 1 (Unit Tests): 45/45 passed (1.00)
PASS 2 (Integration): 12/12 passed (1.00)
PASS 3 (E2E): 8/8 passed (1.00)
PASS 4 (Review): 0 critical issues, 1 minor suggestion (0.95)

Truth Score: (1.00 + 1.00 + 1.00 + 0.95) / 4 = 0.9875

STATUS: EXCELLENT - Ready to commit and push
ACTION: Proceeding to git commit
```

**Outcome**: High confidence in code quality, ship it!

---

## Example: Bad Score (< 0.95)

```
=== FRACTAL QUALITY LOOP - Iteration 1 ===

PASS 1 (Unit Tests): 42/45 passed (0.93)
  - FAILED: test_calculate_macros_with_invalid_recipe
  - FAILED: test_portion_size_boundary_conditions
  - FAILED: test_fodmap_analysis_edge_cases

PASS 2 (Integration): 10/12 passed (0.83)
  - FAILED: test_postgres_connection_pool_exhaustion
  - FAILED: test_tandoor_sync_conflict_resolution

PASS 3 (E2E): 6/8 passed (0.75)
  - FAILED: test_complete_meal_logging_workflow
  - FAILED: test_recipe_creation_with_ingredients

PASS 4 (Review): 3 critical issues (0.70)
  - Missing error handling in web/handlers/recipes.gleam
  - Storage layer leaking into UI components
  - No validation for user input

Truth Score: (0.93 + 0.83 + 0.75 + 0.70) / 4 = 0.8025

STATUS: POOR QUALITY - Multiple critical issues
ACTION: Filing beads, fixing critical issues, RE-LOOPING
```

**Filed Beads**:
- `meal-planner-abc123`: Unit test failure: test_calculate_macros_with_invalid_recipe (P0)
- `meal-planner-def456`: Integration test failure: test_postgres_connection_pool_exhaustion (P0)
- `meal-planner-ghi789`: E2E test failure: test_complete_meal_logging_workflow (P0)
- `meal-planner-jkl012`: Code quality: Missing error handling in recipes handler (P0)

**Outcome**: Fix critical issues, then re-run complete loop from Pass 1.

---

## Interpreting Auto-Rollback

If after multiple iterations the truth score remains below 0.95:

1. **Assess Scope**: Is the change too large? Break into smaller beads.
2. **Review Approach**: Is the implementation approach sound?
3. **Consider Rollback**:
   - Revert the changes: `git reset --hard HEAD~1`
   - File detailed beads for proper implementation
   - Plan a better approach with clearer tests

**Auto-rollback criteria**:
- 3+ iterations with score < 0.95
- Critical test failures persist
- Architecture violations found
- Breaking changes to existing functionality

---

## Fractal Re-Loop Logic

After completing all 4 passes:

1. **Calculate truth score**
2. **If score >= 0.95**: Quality loop complete, proceed to commit
3. **If score < 0.95**:
   - Fix all critical issues (P0 beads)
   - Address blocking test failures
   - Re-run ENTIRE loop from Pass 1
4. **After 5 iterations**: If score still < 0.95, rollback and re-plan

**Why re-loop from Pass 1?** Fixes to integration or E2E issues can break unit tests. The fractal nature ensures each layer stays valid.

---

## Integration with Beads

### Session Start
```bash
bd create "Fractal quality loop: <feature_name>" -t task -p 1
bd update <loop-id> --status in_progress
```

### During Execution
```bash
# For each failure found
bd create "Test failure: <specific_test>" -t bug -p 0
bd dep add <failure-id> <loop-id> --type discovered-from

# For review issues
bd create "Code quality: <issue>" -t task -p 2
```

### Session End
```bash
# If all passes succeed
bd close <loop-id> --reason "Quality loop complete: truth_score=0.98"
bd sync

# If rollback needed
bd close <loop-id> --reason "Rolled back: truth_score=0.82 after 3 iterations"
bd sync
git reset --hard HEAD~1
```

---

## Best Practices

1. **Run the full loop**: Never skip passes, each validates different dimensions
2. **Fix immediately**: Don't accumulate technical debt, fix P0 issues now
3. **File everything**: Every issue gets a bead, even if "minor"
4. **Re-loop after fixes**: Changes can introduce new issues
5. **Use truth score**: Objective quality metric, not subjective feelings
6. **Know when to rollback**: Sometimes the best fix is to start over
7. **Maximum 5 iterations**: If not clean by then, re-plan the approach

---

## Truth Score Reporting

Include in commit messages:
```
[meal-planner-xyz] Add recipe FODMAP analysis

Fractal Quality Loop: 4 passes completed
- Unit tests: 52/52 (1.00)
- Integration: 14/14 (1.00)
- E2E: 9/9 (1.00)
- Review: 0 issues (1.00)
Truth score: 1.00

Generated with Claude Code
Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

---

## Summary

The Fractal Quality Loop ensures systematic code quality through:
- **4 layered passes**: Unit → Integration → E2E → Review
- **Objective scoring**: Truth score from 0.0 to 1.0
- **Re-loop on failure**: Fix and re-validate from Pass 1
- **Auto-rollback**: When quality can't be achieved, start fresh
- **Beads integration**: All issues tracked, nothing forgotten

**Goal**: Ship code with truth_score >= 0.95, always.
