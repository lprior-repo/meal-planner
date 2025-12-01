# Test Coverage Analysis - Gleam Meal Planner

**Date**: 2025-12-01
**Current Test Count**: 358 tests (all passing)
**Target Coverage**: 90%

## Executive Summary

The codebase has **excellent test coverage** for most core modules. The 358 tests cover:
- Core business logic (macros, recipes, meal planning)
- Data persistence (storage, migrations)
- NCP reconciliation and scoring
- User profile management
- Property-based testing

## Coverage by Module

### ✅ **EXCELLENT Coverage (80-100%)**

| Module | Test File | Coverage Est. | Notes |
|--------|-----------|---------------|-------|
| `ncp.gleam` | `ncp_test.gleam` | 95% | 1476 lines of tests! Comprehensive |
| `storage.gleam` | `storage_test.gleam` | 90% | All CRUD operations tested |
| `types.gleam` | `types_test.gleam` | 85% | Core types and calculations covered |
| `meal_plan.gleam` | `meal_plan_test.gleam` | 85% | Algorithm thoroughly tested |
| `recipe_loader.gleam` | `recipe_loader_test.gleam` | 80% | File I/O tested |
| `validation.gleam` | `validation_test.gleam` | 90% | Edge cases covered |
| `quantity.gleam` | `quantity_test.gleam` | 95% | Parsing heavily tested |

### ⚠️ **GOOD Coverage (60-80%)**

| Module | Test File | Coverage Est. | Gaps |
|--------|-----------|---------------|------|
| `meal_selection.gleam` | `meal_selection_test.gleam` | 70% | Missing edge cases for constraints |
| `shopping_list.gleam` | `shopping_list_test.gleam` | 75% | Aggregation tested, formatting untested |
| `usda_import.gleam` | `usda_import_test.gleam` | 65% | Happy path tested, error paths need work |
| `user_profile.gleam` | `user_profile_test.gleam` | 70% | Calculation tested, validation gaps |

### ❌ **NEEDS IMPROVEMENT (< 60%)**

| Module | Test File | Coverage Est. | Priority | Missing Tests |
|--------|-----------|---------------|----------|---------------|
| `web.gleam` | ❌ None | **0%** | 🔴 HIGH | All web routes, SSR, JSON encoding |
| `migrate.gleam` | `migrate_test.gleam` | 40% | 🔴 HIGH | Error handling, rollback scenarios |
| `application.gleam` | `application_test.gleam` | 30% | 🟡 MED | Startup/shutdown, OTP supervision |
| `state.gleam` | `state_test.gleam` | 50% | 🟡 MED | Concurrent access, race conditions |
| `supervisor.gleam` | `supervisor_test.gleam` | 35% | 🟡 MED | Crash recovery, restart strategies |
| `logger.gleam` | `logger_test.gleam` | 60% | 🟢 LOW | Log formatting variations |
| `env.gleam` | `env_test.gleam` | 50% | 🟢 LOW | Missing env var handling |

### 📋 **NO TEST FILE YET**

These source files have **no corresponding test file**:
- ❌ `web.gleam` - **634 lines** - CRITICAL GAP
- ✅ `portion.gleam` - Has `portion_test.gleam`
- ✅ `fodmap.gleam` - Has `fodmap_test.gleam`
- ✅ `email.gleam` - Has `email_test.gleam`
- ✅ `weekly_plan.gleam` - Has `weekly_plan_test.gleam`
- ✅ `output.gleam` - Has `output_test.gleam`

## Detailed Gap Analysis

### 🔴 CRITICAL: web.gleam (634 lines, 0% coverage)

**Missing Tests**:
```gleam
// Page rendering
- home_page() → should return 200 with HTML
- recipes_page() → should render recipe grid
- recipe_detail_page() → should handle valid/invalid IDs
- dashboard_page() → should load profile and calculate macros
- profile_page() → should display user stats
- not_found_page() → should return 404

// API routes
- api_recipes() → should return JSON array
- api_recipe() → should return single recipe JSON
- api_profile() → should return profile with targets

// Static files
- serve_static() → should serve CSS, images

// Data loading
- load_recipes() → fallback to samples when DB empty
- load_recipe_by_id() → NotFound vs sample vs DB
- load_profile() → fallback to default profile

// JSON encoding
- recipe_to_json() → all fields serialized correctly
- profile_to_json() → includes daily_targets
- macros_to_json() → includes calculated calories

// Helpers
- float_to_string() → rounding behavior
- activity_level_to_string() → all enum variants
- goal_to_string() → all enum variants
```

**Recommended Priority Tests** (to get to 50% coverage):
1. Test all page routes return 200 OK with valid HTML
2. Test API endpoints return valid JSON
3. Test 404 for invalid recipe IDs
4. Test fallback to sample data when DB is empty
5. Test profile calculations integrate correctly

### 🔴 HIGH PRIORITY: storage.gleam USDA functions

**Current**: Recipe storage is well-tested (56 tests)
**Missing**: USDA food search functions (lines 642-787)

```gleam
// Untested USDA functions:
- search_foods() → empty results, pagination, wildcards
- get_food_nutrients() → nutrient ordering, missing data
- get_food_by_id() → NotFound case
- get_foods_count() → zero vs non-zero
```

### 🟡 MEDIUM PRIORITY: ncp.gleam edge cases

**Current**: 1476 lines of tests - exceptional!
**Missing**: Only minor edge cases

```gleam
// Additional edge cases to test:
- score_recipe_for_deviation() with extreme values (>1000g protein)
- format_status_output() with very long recipe names
- calculate_nutrition_variability() with outliers
- analyze_nutrition_trends() with gaps in dates
```

### 🟡 MEDIUM PRIORITY: migrate.gleam error handling

**Current**: Basic migration tested
**Missing**: Failure scenarios

```gleam
// Untested error paths:
- Migration file with syntax errors
- Migration fails mid-execution (rollback)
- Duplicate migration numbers
- Missing migration files in sequence
- Concurrent migration attempts
```

### 🟢 LOW PRIORITY: Helper modules

Most helper modules have good coverage. Minor gaps:

```gleam
// env.gleam - missing env var scenarios
- get_env() when var is empty string
- get_env() with special characters
- get_bool() with invalid values ("yes", "true", "1")

// logger.gleam - formatting edge cases
- Log messages with newlines
- Very long log messages (>1000 chars)
- Unicode in log messages
```

## Source Files Without Tests

**Total**: 23 source files
**With tests**: 21 test files
**Mapping**:

| Source File | Test File | Status |
|-------------|-----------|--------|
| logger.gleam | logger_test.gleam | ✅ |
| env.gleam | env_test.gleam | ✅ |
| portion.gleam | portion_test.gleam | ✅ |
| fodmap.gleam | fodmap_test.gleam | ✅ |
| quantity.gleam | quantity_test.gleam | ✅ |
| email.gleam | email_test.gleam | ✅ |
| meal_selection.gleam | meal_selection_test.gleam | ✅ |
| validation.gleam | validation_test.gleam | ✅ |
| shopping_list.gleam | shopping_list_test.gleam | ✅ |
| output.gleam | output_test.gleam | ✅ |
| weekly_plan.gleam | weekly_plan_test.gleam | ✅ |
| migrate.gleam | migrate_test.gleam | ✅ |
| meal_plan.gleam | meal_plan_test.gleam | ✅ |
| recipe_loader.gleam | recipe_loader_test.gleam | ✅ |
| types.gleam | types_test.gleam | ✅ |
| application.gleam | application_test.gleam | ✅ |
| state.gleam | state_test.gleam | ✅ |
| supervisor.gleam | supervisor_test.gleam | ✅ |
| user_profile.gleam | user_profile_test.gleam | ✅ |
| ncp.gleam | ncp_test.gleam | ✅ |
| **web.gleam** | ❌ **MISSING** | 🔴 |
| storage.gleam | storage_test.gleam | ✅ |
| usda_import.gleam | usda_import_test.gleam | ✅ |

## Functions Needing Tests

### High Priority Functions (Used by Web Server)

**storage.gleam** - USDA Search:
- `search_foods(conn, query, limit)` - Line 656
- `get_food_nutrients(conn, fdc_id)` - Line 704
- `get_food_by_id(conn, fdc_id)` - Line 744
- `get_foods_count(conn)` - Line 773

**web.gleam** - ALL ROUTES:
- `home_page()` - Line 96
- `recipes_page(ctx)` - Line 137
- `recipe_detail_page(id, ctx)` - Line 185
- `dashboard_page(ctx)` - Line 258
- `profile_page(ctx)` - Line 340
- `api_recipes(req, ctx)` - Line 430
- `api_recipe(req, id, ctx)` - Line 437
- `api_profile(req, ctx)` - Line 447

**ncp.gleam** - Scoring Edge Cases:
- `score_recipe_for_deviation()` with extreme macros - Line 655
- `generate_reason()` with edge deviations - Line 820

### Medium Priority Functions

**migrate.gleam** - Error Handling:
- `run_migration(conn, number, sql)` error paths
- `get_schema_version(conn)` when table doesn't exist
- `read_migration_file(number)` with invalid files

**application.gleam** - OTP Lifecycle:
- `start()` startup sequence
- Shutdown and cleanup
- Database initialization failures

**state.gleam** - Concurrent Access:
- Race conditions in state updates
- Multiple readers/writers

### Low Priority Functions

**validation.gleam** - Edge Cases:
- Extreme input values
- Unicode handling
- Null/empty variations

**output.gleam** - Formatting:
- Very long text wrapping
- Special characters in output
- Color code handling

## Recommendations

### To Reach 90% Coverage

**Phase 1: Critical Gaps (Week 1)**
1. ✅ Create `web_test.gleam` - 20 basic tests for routes
2. Add USDA search tests to `storage_test.gleam` - 10 tests
3. Add error path tests to `migrate_test.gleam` - 5 tests

**Phase 2: Fill Medium Gaps (Week 2)**
4. Expand `application_test.gleam` - 10 tests for startup/shutdown
5. Add concurrent tests to `state_test.gleam` - 8 tests
6. Add edge cases to `ncp_test.gleam` - 5 tests

**Phase 3: Polish (Week 3)**
7. Add helper edge cases to `env_test.gleam` - 5 tests
8. Add formatting tests to `logger_test.gleam` - 5 tests
9. Property tests for numeric edge cases - 10 tests

**Total New Tests Needed**: ~78 tests
**Estimated New Coverage**: 358 + 78 = **436 tests** → **90%+ coverage**

## Test Quality Assessment

**Strengths**:
- ✅ Comprehensive business logic coverage
- ✅ Good use of property-based testing
- ✅ Edge cases well documented
- ✅ Clear test organization
- ✅ Consistent naming conventions

**Improvement Opportunities**:
- ⚠️ Web layer completely untested
- ⚠️ Integration tests missing for HTTP routes
- ⚠️ Error path coverage gaps in I/O operations
- ⚠️ Concurrent access patterns not tested
- ⚠️ Database failure scenarios undertested

## Next Steps

1. **Start with web_test.gleam** - highest impact
2. **Add 10-15 basic route tests** - get to 60% web coverage
3. **Test USDA search functions** - complete storage coverage
4. **Add error handling tests** - improve robustness
5. **Run coverage report** - verify 90% achieved

---

**Analysis Complete**
Current: 358 tests ✅
Target: ~436 tests for 90% coverage
Gap: 78 tests to write
Priority: web.gleam → storage.gleam USDA → migrate.gleam errors
