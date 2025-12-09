# Code Cleanup Consolidation Roadmap

## Overview
Consolidated 13 unused code cleanup tasks under epic **meal-planner-xwxc**.

## Summary by Category

### 1. Unused Imports (5 tasks)
- **meal-planner-i4fh**: Remove unused imports in test fixtures (gleam/result, gleeunit/should)
- **meal-planner-cjh8**: Remove unused gleam/list from query_cache.gleam (line 6)
- **meal-planner-yw5a**: Remove unused gleam/dynamic/decode from micronutrients_test.gleam (line 1)
- **meal-planner-92q6**: Fix 5 unused import warnings in performance.gleam (storage, storage_optimized)
- **meal-planner-img3**: Fix 14 unused import warnings in food_logging_e2e_test.gleam (lines 19-23)

### 2. Unused Functions (4 tasks)
- **meal-planner-3lcz**: Remove unused handle_storage_error function in web.gleam (line 2642)
- **meal-planner-njig**: Fix 6 unused function warnings in web.gleam (multiple functions)
- **meal-planner-jxp7**: Remove unused private functions in test_helper.gleam (run_migration, run_all_migrations)
- **meal-planner-xccj**: Fix 5 unused warnings in test_helper.gleam and test_db.gleam

### 3. Unused Variables/Arguments (4 tasks)
- **meal-planner-efe8**: Fix 7 unused value warnings in storage_optimized.gleam (lines 51, 65)
- **meal-planner-je9v**: Fix unused values in test setup calls (meal_planner_test.gleam, recipe_creation_test.gleam)
- **meal-planner-n4lu**: Fix unused function argument in fractal_quality_harness_test.gleam (line 72)
- **meal-planner-zz6b**: Fix unused function arguments in query_cache.gleam (lines 305-306)

## Execution Strategy

### Approach: File-based Consolidation
Execute cleanup in parallel by file module to avoid conflicts:

**Batch 1: Core modules**
- meal-planner-3lcz + meal-planner-njig (web.gleam)
- meal-planner-92q6 (performance.gleam)
- meal-planner-cjh8 + meal-planner-zz6b (query_cache.gleam)
- meal-planner-efe8 (storage_optimized.gleam)

**Batch 2: Test files**
- meal-planner-i4fh (test_db.gleam)
- meal-planner-yw5a (micronutrients_test.gleam)
- meal-planner-img3 (food_logging_e2e_test.gleam)
- meal-planner-je9v (meal_planner_test.gleam, recipe_creation_test.gleam)

**Batch 3: Test infrastructure**
- meal-planner-jxp7 (test_helper.gleam)
- meal-planner-n4lu (fractal_quality_harness_test.gleam)
- meal-planner-xccj (test files cleanup)

## Impact Analysis

### File Count: 12 files affected
- **Core modules**: web.gleam, performance.gleam, query_cache.gleam, storage_optimized.gleam
- **Test files**: 8 test files

### Build Impact
- All changes verified with `gleam build`
- No functional changes
- Improves code cleanliness for CI/CD pipelines

### Rollback Strategy
Each task includes git checkout instruction for safety.

## Consolidation Summary

| Metric | Value |
|--------|-------|
| Total Tasks | 13 |
| Categories | 3 (Imports, Functions, Variables) |
| Files Affected | 12 |
| Estimated Effort | 2-3 hours (parallel execution) |
| Risk Level | Low (deletions/renames only, safe changes) |
| All Categorized | Yes |

## Next Steps

1. **Execute batches in priority order**
   - Batch 1: Core modules (highest priority for build health)
   - Batch 2: Test files (coverage for test infrastructure)
   - Batch 3: Remaining test infrastructure

2. **Verify after each batch**
   - Run `gleam build` to confirm no warnings
   - Check compilation succeeds

3. **Group commits by module**
   - One commit per file with `[bd-###]` reference
   - Multiple related tasks can share commit if same file

4. **Close parent epic**
   - After all 13 subtasks complete
   - Close `meal-planner-xwxc` with final cleanup

## Task Dependencies
All 13 tasks are independent and can be executed in parallel:
- No shared file conflicts within execution batches
- No functional dependencies
- Safe to work on multiple files simultaneously

## Priority Ranking for Parallel Execution

**High Priority (Core functionality)**
1. meal-planner-njig (6 unused functions in web.gleam)
2. meal-planner-efe8 (7 unused values in storage_optimized.gleam)
3. meal-planner-92q6 (5 unused imports in performance.gleam)

**Medium Priority (Query/caching)**
4. meal-planner-cjh8 (unused import in query_cache.gleam)
5. meal-planner-zz6b (unused args in query_cache.gleam)

**Lower Priority (Tests)**
6. meal-planner-img3 (14 warnings in food_logging_e2e_test.gleam)
7. meal-planner-yw5a (1 unused import in micronutrients_test.gleam)
8. meal-planner-i4fh (imports in test_db.gleam)
9. meal-planner-je9v (test setup values)
10. meal-planner-jxp7 (unused test functions)
11. meal-planner-n4lu (unused test parameter)
12. meal-planner-xccj (test file cleanup)
13. meal-planner-3lcz (unused function in web.gleam)

---

**Created**: 2025-12-04
**Epic**: meal-planner-xwxc
**Status**: Analysis Complete - Ready for Execution
