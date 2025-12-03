# Test Coverage Analysis Report
**Generated**: 2025-12-03
**Agent**: BlueLake
**Project**: meal-planner

## Executive Summary
- **Current Coverage**: 61.4% (27/44 files)
- **Target Coverage**: 90% (40/44 files)
- **Gap**: 13 additional files need tests
- **Status**: ⚠️ Tests have compilation errors

## Detailed Breakdown

### Current Status
| Metric | Count | Percentage |
|--------|-------|------------|
| Total source files | 44 | 100% |
| Files with tests | 27 | 61.4% |
| Files without tests | 17 | 38.6% |
| Tests needed for 90% | 13 | - |

### Files WITH Test Coverage (27)
✓ Core Application
- `src/meal_planner.gleam`
- `src/meal_planner/application.gleam`
- `src/meal_planner/supervisor.gleam`
- `src/meal_planner/state.gleam`

✓ Business Logic
- `src/meal_planner/auto_planner.gleam`
- `src/meal_planner/diet_validator.gleam`
- `src/meal_planner/meal_plan.gleam`
- `src/meal_planner/meal_selection.gleam`
- `src/meal_planner/recipe_loader.gleam`
- `src/meal_planner/shopping_list.gleam`
- `src/meal_planner/user_profile.gleam`
- `src/meal_planner/weekly_plan.gleam`
- `src/meal_planner/validation.gleam`

✓ Data Processing
- `src/meal_planner/ncp.gleam`
- `src/meal_planner/nutrient_parser.gleam`
- `src/meal_planner/portion.gleam`
- `src/meal_planner/quantity.gleam`
- `src/meal_planner/fodmap.gleam`

✓ Infrastructure
- `src/meal_planner/email.gleam`
- `src/meal_planner/env.gleam`
- `src/meal_planner/logger.gleam`
- `src/meal_planner/output.gleam`
- `src/meal_planner/food_search.gleam`
- `src/meal_planner/web.gleam`

✓ Types
- `src/meal_planner/types.gleam`
- `src/meal_planner/auto_planner/types.gleam`
- `src/meal_planner/ui/pages/food_search.gleam`

### Files WITHOUT Test Coverage (17)

#### 🔴 Priority 1: Storage & Business Logic (3 files)
Critical components that need immediate test coverage:
- `src/meal_planner/auto_planner/storage.gleam` - Auto planner data persistence
- `src/meal_planner/storage.gleam` - Main storage layer
- `src/meal_planner/web_helpers.gleam` - Web request helpers

#### 🟡 Priority 2: UI Components (9 files)
UI rendering components (can use snapshot/property tests):
- `src/meal_planner/ui/components/button.gleam`
- `src/meal_planner/ui/components/card.gleam`
- `src/meal_planner/ui/components/daily_log.gleam`
- `src/meal_planner/ui/components/forms.gleam`
- `src/meal_planner/ui/components/layout.gleam`
- `src/meal_planner/ui/components/progress.gleam`
- `src/meal_planner/ui/components/typography.gleam`
- `src/meal_planner/ui/pages/dashboard.gleam`
- `src/meal_planner/ui/recipe_form.gleam`

#### 🟢 Priority 3: Utility & Scripts (5 files)
Lower priority unless they contain business logic:
- `src/meal_planner/ui/types/ui_types.gleam` - Type definitions
- `src/meal_planner/vertical_diet_recipes.gleam` - Recipe data
- `src/scripts/import_recipes.gleam` - Data import script
- `src/scripts/init_pg.gleam` - Database initialization
- `src/scripts/restore_db.gleam` - Database restore

## Known Issues

### Compilation Errors
The test suite has compilation errors in `micronutrients_test.gleam`:
- **Issue**: Type annotations missing for decoder results
- **Impact**: Tests cannot run until fixed
- **Location**: Lines 826-835
- **Required Action**: Add type annotations for decoded record fields

Example error:
```
error: Type hole
    ┌─ test/meal_planner/micronutrients_test.gleam:826:16
    │
826 │   let decoded = _
    │                 ^ I don't know what to put here
```

## Recommendations

### Immediate Actions
1. **Fix compilation errors** in `micronutrients_test.gleam` to unblock test suite
2. **Prioritize storage modules** - These are critical for data persistence
3. **Add web_helpers tests** - Important for request handling

### Path to 90% Coverage
To reach 90% coverage (40/44 files), we need tests for **13 additional files**.

**Recommended approach:**
1. Fix broken tests (1 file) ✅
2. Test storage modules (2 files) - **Priority 1**
3. Test web_helpers (1 file) - **Priority 1**
4. Test 9 UI components (9 files) - **Priority 2**

This would give us **40 files with tests = 90.9% coverage**

### Test Strategy by Module Type

**Storage Modules:**
- Unit tests for CRUD operations
- Property tests for data consistency
- Integration tests with test database

**UI Components:**
- Snapshot tests for rendering
- Property tests for prop validation
- Integration tests for user interactions

**Scripts:**
- Integration tests with test database
- Validation tests for data imports
- Error handling tests

## Next Steps

1. ✅ **Fixed**: Create this coverage report
2. 🔄 **In Progress**: Fix micronutrients_test.gleam compilation errors
3. ⏭️ **Next**: Create tests for storage modules
4. ⏭️ **Then**: Create tests for web_helpers
5. ⏭️ **Finally**: Add UI component tests

## Test Tooling

The project uses:
- **gleeunit** - Main testing framework
- **qcheck** - Property-based testing
- **qcheck_gleeunit_utils** - Property test integration

## Estimated Effort

Based on average test complexity:
- **Storage modules**: ~2-3 hours (complex business logic)
- **Web helpers**: ~1 hour (HTTP request handling)
- **UI components**: ~3-4 hours (snapshot + interaction tests)
- **Scripts**: ~1-2 hours (integration tests)

**Total estimated effort**: 7-10 hours to reach 90% coverage

---

**Report generated by**: BlueLake (Claude Code Agent)
**Registered via**: Agent Mail MCP
**Project**: /home/lewis/src/meal-planner
