# Test Coverage Analysis Report
**Date:** 2025-12-24
**Analyst:** Agent-TestQuality-1 (82/96)
**Status:** CRITICAL GAPS IDENTIFIED

---

## Executive Summary

**Overall Coverage:** 22.8% (76 test files / 334 source files)
**Total Test LOC:** 17,426 lines
**Mean Test Size:** 229 lines
**Quality Rating:** ⚠️ MODERATE - Strong in some areas, critical gaps in others

### Key Findings

✅ **STRENGTHS:**
- CLI screens have comprehensive test coverage (TUI integration, component tests)
- Email parsing has excellent edge case coverage
- FatSecret API decoders are well-tested with fixtures
- Constraint solver has thorough unit tests
- Test quality is high where tests exist (good use of fixtures, edge cases, error paths)

🔴 **CRITICAL GAPS:**
- **Storage module:** 0 tests for 9 database-related files
- **Web handlers:** 1 test for 20+ HTTP handlers
- **Automation module:** 1 test for 6 files
- **Cache module:** 0 tests
- **UI module:** 0 tests

---

## Coverage by Module

| Module | Source Files | Test Files | Coverage % | Status |
|--------|--------------|------------|------------|--------|
| **storage** | 9 | 0 | 0% | 🔴 CRITICAL |
| **web/handlers** | 20+ | 1 | 5% | 🔴 CRITICAL |
| **automation** | 6 | 1 | 17% | 🔴 CRITICAL |
| **cache** | 1 | 0 | 0% | 🔴 CRITICAL |
| **ui** | 2 | 0 | 0% | 🔴 CRITICAL |
| **fatsecret** | 69 | 13 | 19% | 🟡 LOW |
| **tandoor** | 57 | 8 | 14% | 🟡 LOW |
| **cli** | 57 | 20+ | 35% | 🟢 MODERATE |
| **email** | 5 | 5 | 100% | 🟢 EXCELLENT |
| **scheduler** | 9 | 3 | 33% | 🟢 MODERATE |
| **generation** | 2 | 3 | 150% | 🟢 EXCELLENT |

---

## Test Quality Assessment

### Positive Indicators

1. **Error Path Testing:** 29 explicit error assertions (`should.be_error`)
2. **Success Path Testing:** 118 success assertions (`should.be_ok`)
3. **Edge Case Coverage:** 649 references to edge cases, boundaries, empty lists, invalid inputs
4. **Fixture Usage:** Extensive use of JSON fixtures for API response testing
5. **TDD Evidence:** Multiple RED-phase comments indicating test-first development

### Quality Metrics

```
Error/Success Ratio: 29:118 (19.5% error coverage)
Edge Case Keywords: 649 occurrences across 78 test files
Panic Usage in Tests: 15 (acceptable for test assertions)
Panic Usage in Source: 4 (low, good defensive coding)
```

### Test File Size Distribution

```
Largest Tests:
  - progress_bar_test.gleam: 991 LOC
  - list_view_test.gleam: 973 LOC
  - date_picker_test.gleam: 535 LOC
  - tui_integration_test.gleam: 518 LOC

Median Test Size: 176 LOC
Mean Test Size: 229 LOC
Smallest Test: 5 LOC (minimal stub)
```

**Assessment:** Test files are generally well-sized. The largest tests (900+ LOC) test complex TUI components, which is reasonable.

---

## Critical Untested Code Paths

### 1. Storage Layer (DATABASE OPERATIONS)
**Risk Level:** 🔴 CRITICAL - NO TESTS

Untested files:
- `storage/audit.gleam` - Audit logging
- `storage/foods.gleam` - Food database operations
- `storage/logs.gleam` - Log persistence
- `storage/mod.gleam` - Storage initialization
- `storage/nutrients.gleam` - Nutrient tracking
- `storage/profile.gleam` - User profile storage
- `storage/scheduler.gleam` - Scheduler state persistence
- `storage/schema.gleam` - Database schema
- `storage/utils.gleam` - Storage utilities

**Impact:** Data corruption, race conditions, SQL injection, data loss

**Recommendation:** IMMEDIATE ACTION REQUIRED
- Create `test/meal_planner/storage/` directory
- Write integration tests using test database
- Test CRUD operations, edge cases (empty results, duplicates, constraints)
- Test transaction rollback and error handling

---

### 2. Web Handlers (HTTP ENDPOINTS)
**Risk Level:** 🔴 CRITICAL - 5% COVERAGE

20+ handlers, only `scheduler_test.gleam` exists.

Untested handlers:
- `web/handlers/advisor.gleam` - Nutrition advisor endpoint
- `web/handlers/diet.gleam` - Diet management
- `web/handlers/fatsecret/brands.gleam` - Brand search
- `web/handlers/health.gleam` - Health checks
- `web/handlers/macros.gleam` - Macro tracking
- `web/handlers/meal_planning.gleam` - Meal plan CRUD
- `web/handlers/nutrition.gleam` - Nutrition tracking
- `web/handlers/recipes.gleam` - Recipe endpoints
- `web/handlers/shopping_list.gleam` - Shopping list management
- `web/handlers/tandoor/*` - 10+ Tandoor proxy handlers

**Impact:** Unvalidated inputs, unauthorized access, API contract violations, runtime crashes

**Recommendation:** IMMEDIATE ACTION REQUIRED
- Create handler tests for each HTTP endpoint
- Test request validation (malformed JSON, missing fields, type errors)
- Test authorization (authenticated vs unauthenticated requests)
- Test error responses (404, 500, 400, 401, 403)
- Test pagination, filtering, sorting
- Use Wisp test utilities for request/response mocking

---

### 3. Automation Module
**Risk Level:** 🔴 CRITICAL - 17% COVERAGE

Only `plan_generator_test.gleam` exists.

Untested files:
- `automation/fatsecret_sync.gleam` - FatSecret data synchronization
- `automation/macro_optimizer.gleam` - Macro optimization algorithms
- `automation/preferences.gleam` - User preference management
- `automation/rotation.gleam` - Recipe rotation logic
- `automation/shopping_consolidator.gleam` - Shopping list consolidation

**Impact:** Incorrect sync, data loss, preference conflicts, poor meal variety

**Recommendation:** HIGH PRIORITY
- Test sync logic with mock API responses
- Test optimization edge cases (impossible constraints, empty recipes)
- Test preference conflict resolution
- Test rotation fairness and variety

---

### 4. Cache Module
**Risk Level:** 🟡 MEDIUM - 0% COVERAGE

Only 1 file (`cache.gleam`), but caching bugs can cause stale data issues.

**Recommendation:** MEDIUM PRIORITY
- Test cache invalidation logic
- Test cache expiration
- Test cache miss/hit scenarios
- Test concurrent access (if applicable)

---

### 5. CLI Domain Commands
**Risk Level:** 🟡 MEDIUM - PARTIAL COVERAGE

Many CLI command files untested:
- `cli/domains/diary/commands/*.gleam` (add, delete, sync, view)
- `cli/domains/nutrition/commands.gleam`
- `cli/domains/advisor.gleam`
- `cli/domains/plan.gleam`

**Recommendation:** MEDIUM PRIORITY
- Test command argument parsing
- Test error messages for invalid inputs
- Test command output formatting

---

## Test Quality Deep Dive

### Example: High-Quality Test (email/command_edge_cases_test.gleam)

✅ **Strengths:**
- Tests case-insensitive input
- Tests malformed commands
- Tests missing required fields
- Tests multiple variations of same command
- Clear RED-phase TDD comments
- Descriptive test names
- Good use of helper functions

```gleam
pub fn email_parser_handles_case_insensitive_commands_test() {
  // Tests @claude, @CLAUDE, @Claude variations
  // RED PHASE: This will FAIL - parser checks for "@Claude" with capital C
  // ...
}

pub fn email_parser_rejects_malformed_commands_test() {
  // Tests missing @Claude mention
  // Tests unrecognized command
  // Tests incomplete commands
  // ...
}
```

### Example: High-Quality Test (advisor/weekly_trends_test.gleam)

✅ **Strengths:**
- Comprehensive test fixtures (balanced week, low protein week)
- Tests edge cases (empty list)
- Tests pattern detection logic
- Tests recommendation generation
- Tests both positive and negative scenarios

```gleam
pub fn calculate_averages_handles_empty_list_test() {
  let summaries = []
  let result = calculate_macro_averages(summaries)
  should.equal(result, #(0.0, 0.0, 0.0, 0.0))
}
```

### Example: High-Quality Test (constraint_solver_test.gleam)

✅ **Strengths:**
- Tests satisfied and violated constraints
- Tests soft vs hard constraints
- Tests multiple constraint types (budget, nutrition, repetition, must-include, must-exclude)
- Tests conflict detection
- Tests optimization logic
- Comprehensive test helpers for creating test data

---

## Recommendations (Priority Order)

### 🔴 IMMEDIATE (P0)

1. **Storage Module Tests**
   - **Why:** Database operations are critical, untested SQL can corrupt data
   - **What:** Create integration tests for all storage operations
   - **How:** Use test database, test CRUD, constraints, transactions
   - **Effort:** 40-60 hours
   - **Beads Task:** Create `MP-TEST-1: Storage module test coverage`

2. **Web Handler Tests**
   - **Why:** HTTP endpoints are attack surface, untested = vulnerabilities
   - **What:** Test all 20+ handlers for validation, auth, error handling
   - **How:** Use Wisp test utilities, mock external APIs
   - **Effort:** 60-80 hours
   - **Beads Task:** Create `MP-TEST-2: Web handler test coverage`

### 🟡 HIGH PRIORITY (P1)

3. **Automation Module Tests**
   - **Why:** Sync and optimization bugs cause poor UX
   - **What:** Test sync, optimizer, rotation, consolidator
   - **How:** Mock external APIs, test edge cases
   - **Effort:** 20-30 hours
   - **Beads Task:** Create `MP-TEST-3: Automation module test coverage`

4. **FatSecret API Integration Tests**
   - **Why:** 19% coverage leaves many API paths untested
   - **What:** Increase coverage to 50%+
   - **How:** Add tests for remaining decoders and client methods
   - **Effort:** 15-20 hours
   - **Beads Task:** Create `MP-TEST-4: FatSecret integration test coverage`

### 🟢 MEDIUM PRIORITY (P2)

5. **Tandoor API Integration Tests**
   - **Why:** 14% coverage, proxy handlers need validation
   - **What:** Test all Tandoor proxy handlers
   - **How:** Mock Tandoor API responses, test error scenarios
   - **Effort:** 15-20 hours
   - **Beads Task:** Create `MP-TEST-5: Tandoor integration test coverage`

6. **Cache Module Tests**
   - **Why:** Cache bugs cause stale data
   - **What:** Test invalidation, expiration, concurrent access
   - **Effort:** 5-10 hours
   - **Beads Task:** Create `MP-TEST-6: Cache module test coverage`

### 🔵 LOW PRIORITY (P3)

7. **UI Module Tests**
   - **Why:** 0% coverage, but UI rendering is lower risk
   - **What:** Test UI component rendering logic
   - **Effort:** 5-10 hours

8. **Increase Edge Case Coverage**
   - **Why:** 649 edge case keywords is good, but can always improve
   - **What:** Review existing tests for missing edge cases
   - **Effort:** Ongoing

---

## Test Coverage Goals

### Short-Term (1-2 weeks)
- [ ] Storage: 0% → 60% (all CRUD operations tested)
- [ ] Web handlers: 5% → 40% (critical endpoints tested)
- [ ] Automation: 17% → 50% (sync and optimizer tested)

### Medium-Term (1 month)
- [ ] Overall: 22.8% → 45%
- [ ] All critical modules: 50%+
- [ ] FatSecret: 19% → 50%
- [ ] Tandoor: 14% → 40%

### Long-Term (3 months)
- [ ] Overall: 45% → 70%
- [ ] All modules: 50%+
- [ ] Storage: 80%+
- [ ] Web handlers: 70%+

---

## Code Smells & Anti-Patterns

### ✅ Good Practices Observed

1. **Minimal panic usage in source:** Only 4 panics in 334 files (excellent)
2. **TDD discipline:** RED-phase comments indicate test-first development
3. **Fixture-driven testing:** JSON fixtures for API responses
4. **Helper functions:** Test helpers reduce duplication
5. **Descriptive names:** Test names clearly state what is being tested

### ⚠️ Areas for Improvement

1. **Some tests use `panic as`:** 15 occurrences in tests (acceptable but verbose)
   - Consider using `should.be_some`, `should.be_ok` instead of `let assert`

2. **Test file size variance:** 991 LOC max vs 5 LOC min
   - Consider splitting large test files by feature area

3. **Missing property-based tests:** qcheck is a dependency but rarely used
   - Add property tests for parsers, encoders, decoders

---

## Conclusion

The meal-planner codebase has **strong test quality where tests exist**, but **critical coverage gaps** in storage, web handlers, and automation modules.

**Key Strengths:**
- Excellent email parsing tests with edge cases
- Strong CLI screen test coverage
- Good use of fixtures and test helpers
- Evidence of TDD discipline

**Critical Risks:**
- **Storage layer (0% coverage):** Database operations untested → data corruption risk
- **Web handlers (5% coverage):** HTTP endpoints untested → security vulnerabilities
- **Automation (17% coverage):** Sync and optimization logic untested → poor UX

**Recommendation:** IMMEDIATE ACTION on storage and web handler tests. This is a P0 priority that blocks production readiness.

---

**Report Generated:** 2025-12-24
**Next Review:** After storage and web handler test implementation
**Tool:** Claude Code Test Quality Analysis
