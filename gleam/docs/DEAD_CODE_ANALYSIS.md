# Dead Code Analysis Report

**Date:** 2025-12-04
**Task:** meal-planner-vju3
**Analysis Tool:** `gleam check`

## Executive Summary

Found **23 warnings** across **8 files**, plus **2 compilation errors** that need fixing first.

### Warning Breakdown by Type

| Warning Type | Count | Severity |
|-------------|-------|----------|
| Unused imported module | 7 | Low |
| Unused imported type | 5 | Low |
| Unused value | 4 | Medium |
| Unused function argument | 4 | Low-Medium |
| Unused imported item | 2 | Low |
| Deprecated value | 1 | Medium |
| **TOTAL WARNINGS** | **23** | |

### Compilation Errors (MUST FIX FIRST)

| File | Line | Error |
|------|------|-------|
| `web/handlers/generate.gleam` | 168 | Type mismatch: trying to concatenate Element with String |
| `web/handlers/generate.gleam` | 185 | Type mismatch: trying to concatenate Element with String |

**These compilation errors block the build and must be resolved before dead code cleanup.**

## Files with Most Issues

| File | Warnings | Priority |
|------|----------|----------|
| `src/meal_planner/storage_optimized.gleam` | 7 | HIGH |
| `src/meal_planner/web/handlers/generate.gleam` | 4 (+ 2 errors) | CRITICAL |
| `src/meal_planner/web/handlers/food_log.gleam` | 4 | MEDIUM |
| `src/meal_planner/query_cache.gleam` | 4 | MEDIUM |
| `test/fixtures/test_db.gleam` | 2 | LOW |
| `src/meal_planner/generator.gleam` | 2 | MEDIUM |
| `test/fractal_quality_harness_test.gleam` | 1 | LOW |
| `src/meal_planner/ui/components/meal_card.gleam` | 1 | LOW |

## Detailed Analysis by File

### 1. CRITICAL: `src/meal_planner/web/handlers/generate.gleam` (4 warnings + 2 errors)

**Compilation Errors:**
```
Line 168: |> list.fold("", fn(acc, card) { acc <> card })
Line 185: |> list.fold("", fn(acc, card) { acc <> card })
```
- Trying to use `<>` operator on `element.Element(a)` instead of `String`
- Likely need to use `element.to_string()` or similar conversion

**Warnings:**
1. Line 9: Unused imported module `gleam/result`
2. Line 11: Unused imported type `type Meal`

**Recommendation:** Fix compilation errors FIRST, then remove unused imports.

---

### 2. HIGH PRIORITY: `src/meal_planner/storage_optimized.gleam` (7 warnings)

**Unused Imports:**
1. Line 4: `import gleam/dict` - never used
2. Line 6: `import gleam/int` - never used
3. Line 7: `type Option` from `gleam/option` - never used (but `None` and `Some` are used)

**Unused Values (record_metric calls):**
```gleam
Line 50:  query_cache.record_metric(True, "search_foods", 0.5)
Line 64:  query_cache.record_metric(False, "search_foods", 5.0)
Line 155: query_cache.record_metric(True, "search_foods_filtered", 0.5)
Line 167: query_cache.record_metric(False, "search_foods_filtered", 8.0)
```

These calls compute values but don't use the results. Either:
- Assign to `_` if side effects are intended: `let _ = query_cache.record_metric(...)`
- Remove entirely if not needed
- Use the return value

**Recommendation:**
1. Remove unused imports: `gleam/dict`, `gleam/int`
2. Fix import: Change `import gleam/option.{type Option, None, Some}` to `import gleam/option.{None, Some}`
3. Fix `record_metric` calls - either capture with `let _ =` or remove

---

### 3. MEDIUM PRIORITY: `src/meal_planner/web/handlers/food_log.gleam` (4 warnings)

**Unused Imports:**
1. Line 4: `import gleam/int` - never used
2. Line 7: `Some` from `gleam/option.{None, Some}` - never used
3. Line 11: `type FoodLogEntry` - never used
4. Line 11: `Macros` constructor - never used

**Recommendation:**
1. Remove: `import gleam/int`
2. Change: `import gleam/option.{None, Some}` → `import gleam/option.{None}`
3. Change: `import meal_planner/types.{type FoodLogEntry, FoodLogEntry, Macros}` → `import meal_planner/types.{FoodLogEntry}`

---

### 4. MEDIUM PRIORITY: `src/meal_planner/query_cache.gleam` (4 warnings)

**Unused Import:**
1. Line 6: `import gleam/list` - never used

**Unused Function Arguments (in record_metric):**
```gleam
Lines 305-307:
  cache_hit: Bool,        // unused
  query_name: String,     // unused
  execution_time_ms: Float, // unused
```

**Recommendation:**
1. Remove: `import gleam/list`
2. For unused arguments, either:
   - Prefix with underscore: `_cache_hit`, `_query_name`, `_execution_time_ms`
   - Remove if truly not needed (but might break API)
   - This might be a stub function intended for future use

---

### 5. MEDIUM PRIORITY: `src/meal_planner/generator.gleam` (2 warnings)

**Warnings:**
1. Line 5: `type Meal` - unused imported type
2. Line 161: Using deprecated `result.then()` - should use `result.try()` instead

**Recommendation:**
1. Change: `import meal_planner/meal_plan.{type DailyPlan, type Meal, DailyPlan, Meal}` → remove `type Meal`
2. Replace: `result.then(fn(_) {` → `result.try(fn(_) {`

---

### 6. LOW PRIORITY: `test/fixtures/test_db.gleam` (2 warnings)

**Unused Imports:**
1. Line 9: `import gleam/result` - never used
2. Line 11: `import gleeunit/should` - never used

**Recommendation:** Remove both unused imports. Test fixture should only import what it needs.

---

### 7. LOW PRIORITY: `test/fractal_quality_harness_test.gleam` (1 warning)

**Unused Function Argument:**
```gleam
Line 72: pub fn generate_checklist(file: String) -> List(CheckItem)
```
The `file` argument is never used.

**Recommendation:** Rename to `_file` or implement the file-based logic if intended.

---

### 8. LOW PRIORITY: `src/meal_planner/ui/components/meal_card.gleam` (1 warning)

**Unused Import:**
1. Line 19: `type Macros` - never used

**Recommendation:**
Change: `import meal_planner/types.{type Macros, macros_calories}` → `import meal_planner/types.{macros_calories}`

---

## Cleanup Priority Order

### Phase 0: Fix Compilation Errors (BLOCKING)
**File:** `web/handlers/generate.gleam`
- Fix Element to String conversion issues at lines 168 and 185
- Build must pass before proceeding

### Phase 1: Quick Wins - Unused Imports (Low Risk)
These are safe to remove with no logic changes:

1. `storage_optimized.gleam`: Remove `gleam/dict`, `gleam/int`, and `type Option`
2. `food_log.gleam`: Remove `gleam/int`, `Some`, `type FoodLogEntry`, `Macros`
3. `query_cache.gleam`: Remove `gleam/list`
4. `generate.gleam`: Remove `gleam/result` and `type Meal`
5. `generator.gleam`: Remove `type Meal`
6. `meal_card.gleam`: Remove `type Macros`
7. `test_db.gleam`: Remove `gleam/result` and `gleeunit/should`

**Estimated Time:** 15 minutes
**Risk:** Very Low

### Phase 2: Unused Values (Medium Risk)
**File:** `storage_optimized.gleam`

Fix the 4 `record_metric` calls that don't use their return values:
- Decide if these are meant to have side effects (add `let _ =`)
- Or remove if truly unused

**Estimated Time:** 20 minutes
**Risk:** Medium (need to understand intent)

### Phase 3: Unused Function Arguments (Low Risk)
**Files:** `query_cache.gleam`, `fractal_quality_harness_test.gleam`

Prefix with underscore or remove:
- `query_cache.gleam`: `_cache_hit`, `_query_name`, `_execution_time_ms`
- `fractal_quality_harness_test.gleam`: `_file`

**Estimated Time:** 10 minutes
**Risk:** Low

### Phase 4: Deprecated API (Medium Risk)
**File:** `generator.gleam`

Replace `result.then()` with `result.try()` at line 161.

**Estimated Time:** 5 minutes
**Risk:** Low (direct replacement)

---

## Testing Strategy

After each phase:
1. Run `gleam check` to verify no new errors
2. Run `gleam test` to ensure tests pass
3. Run `gleam build` to verify clean build
4. Commit changes with descriptive message

## Metrics

- **Total Warnings:** 23
- **Total Files Affected:** 8
- **Source Files:** 6
- **Test Files:** 2
- **Estimated Cleanup Time:** ~50 minutes
- **Lines to Remove:** ~15-20 import lines

## Next Steps

1. **IMMEDIATE:** Fix compilation errors in `web/handlers/generate.gleam`
2. Create new Beads tasks for each phase:
   - `meal-planner-dead-code-phase0` - Fix compilation errors
   - `meal-planner-dead-code-phase1` - Remove unused imports
   - `meal-planner-dead-code-phase2` - Fix unused values
   - `meal-planner-dead-code-phase3` - Fix unused arguments
   - `meal-planner-dead-code-phase4` - Replace deprecated API

3. Execute phases in order with testing between each

## Notes

- No unused private functions detected (contrary to initial grep output showing many - those might be in dependencies)
- Most issues are low-risk import cleanup
- The `storage_optimized.gleam` file needs more investigation on the `record_metric` pattern
- All warnings are straightforward to fix with clear compiler hints
