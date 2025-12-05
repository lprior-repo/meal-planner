# Gleam Compilation Warnings Report
**Generated**: 2025-12-05
**Total Warnings**: 137 (109 distinct warnings)
**Build Status**: FAILING (4 type errors in daily_log.gleam)

---

## 🔴 CRITICAL ISSUES (Build Failures)

### 1. Type Errors in `ui/components/daily_log.gleam`

**Status**: BUILD BREAKING - Must fix immediately

```gleam
Line 36: Incorrect arity - MealEntryData pattern
  Expected: 8 arguments
  Got: 9 arguments
  Missing: macros, micronutrients labels

Line 48: Type mismatch - protein field
  Expected: Float
  Found: types.Macros

Line 50: Type mismatch - carbs field
  Expected: Float
  Found: String

Line 51: Type mismatch - calories field
  Expected: Float
  Found: option.Option(types.Micronutrients)
```

**Impact**: Breaks the build completely. UI cannot display daily log entries.

**Root Cause**: Type structure mismatch between `ui_types.MealEntryData` and the data being destructured. The type definition has changed but the pattern matching hasn't been updated.

**Recommended Fix**: Update the pattern match to align with the current MealEntryData type definition and correct field access.

---

## 📊 Warning Summary by Category

| Category | Count | Severity |
|----------|-------|----------|
| Shadowed Import | 28 | Medium |
| Unused imported value | 30 | Low |
| Unused imported item | 27 | Low |
| Unused imported module | 9 | Low |
| Unused imported type | 8 | Low |
| Unused private function | 3 | Low |
| Unused private constant | 2 | Low |
| Duplicate import | 1 | Medium |
| Unreachable pattern | 1 | Medium |

---

## 📁 Files by Warning Density

### High Priority (10+ warnings)

| File | Warnings | Primary Issues |
|------|----------|----------------|
| `storage.gleam` | 66 | Shadowed imports (28), Unused imports (37), Duplicate import (1) |
| `storage/recipes.gleam` | 24 | Unused imports (19), Unused private code (3) |

### Medium Priority (5-9 warnings)

| File | Warnings | Primary Issues |
|------|----------|----------------|
| `storage/logs.gleam` | 9 | Unused imports (7), Unused private code (2) |
| `storage/foods.gleam` | 3 | Unused imported modules |

### Low Priority (1-4 warnings)

| File | Warnings |
|------|----------|
| `storage/profile.gleam` | 2 |
| `storage/migrations.gleam` | 1 |
| `ui/types/ui_types.gleam` | 2 |
| `ui/components/micronutrient_summary.gleam` | 1 |
| `ui/pages/dashboard.gleam` | 1 |
| `web/handlers/food_log.gleam` | 2 |
| `web/handlers/search.gleam` | 1 |

---

## 🎯 Prioritized Fix List

### Priority 1: Critical (Fix Immediately)

1. **Fix type errors in `daily_log.gleam`** ⚠️ BUILD BREAKING
   - Update MealEntryData pattern matching
   - Fix field type access (protein, carbs, calories)
   - Ensure macros/micronutrients are handled correctly
   - **Estimated effort**: 30 minutes

### Priority 2: High (Fix This Sprint)

2. **Clean up `storage.gleam` shadowed imports** (28 warnings)
   - Remove unnecessary re-imports of functions
   - Keep only the module-level imports
   - The pattern is: importing functions from submodules, then re-defining wrapper functions with the same name
   - **Root cause**: Re-export pattern causing shadowing
   - **Estimated effort**: 2 hours
   - **Potential bug risk**: Medium - may hide actual import issues

3. **Remove unused imports from `storage.gleam`** (37 warnings)
   - ProfileStorageError type alias
   - DatabaseError, InvalidInput, NotFound, Unauthorized constructors
   - Recipe functions: delete_recipe, filter_recipes, get_all_recipes, etc.
   - Food functions: create_custom_food, delete_custom_food, etc.
   - **Estimated effort**: 1 hour
   - **Potential bug risk**: Low - clearly unused

4. **Fix duplicate import in `storage.gleam`** (1 warning)
   - Line 10-14: `storage/profile` imported twice
   - Once as `profile_module`, once with explicit items
   - **Estimated effort**: 5 minutes
   - **Potential bug risk**: Low

### Priority 3: Medium (Tech Debt)

5. **Clean up `storage/recipes.gleam`** (24 warnings)
   - 19 unused imports (various types and constructors)
   - 3 unused private functions/constants
   - `valid_food_categories` constant (line 23)
   - `validate_category` function (line 52)
   - **Estimated effort**: 1 hour
   - **Potential bug risk**: Medium - validate_category might be needed

6. **Clean up `storage/logs.gleam`** (9 warnings)
   - 7 unused imports (InvalidInput, NotFound, Unauthorized, Active, Gain, Lose, Sedentary)
   - 2 unused private: `valid_food_categories`, `validate_category`
   - **Estimated effort**: 30 minutes
   - **Potential bug risk**: Low

### Priority 4: Low (Code Hygiene)

7. **Remove unused module imports** (9 warnings)
   - `storage/foods.gleam`: gleam/int, gleam/list, gleam/string
   - `storage/migrations.gleam`: pog
   - **Estimated effort**: 15 minutes
   - **Potential bug risk**: None

8. **Fix unreachable pattern** (1 warning)
   - Location: `web/handlers/search.gleam:499`
   - **Estimated effort**: 10 minutes
   - **Potential bug risk**: High - unreachable code indicates logic issue

9. **Clean up remaining UI/web handler warnings** (6 warnings)
   - `ui/types/ui_types.gleam`: 2 warnings
   - `ui/components/micronutrient_summary.gleam`: 1 warning
   - `ui/pages/dashboard.gleam`: 1 warning
   - `web/handlers/food_log.gleam`: 2 warnings
   - **Estimated effort**: 30 minutes
   - **Potential bug risk**: Low

---

## 🐛 Potential Bug Indicators

### High Risk

1. **Type mismatches in `daily_log.gleam`** - Currently broken, definitely a bug
2. **Unreachable pattern in `search.gleam:499`** - Dead code or logic error
3. **Unused validation functions** - `validate_category` appears in both `recipes.gleam` and `logs.gleam`
   - If validation was supposed to happen but isn't, this could be a security/data quality issue

### Medium Risk

4. **Shadowed imports in `storage.gleam`** - While currently working, this pattern is error-prone
   - Future refactoring could accidentally use the wrong import
   - Makes debugging harder

### Low Risk

5. **Unused imports** - Generally safe to remove, but verify no dynamic/reflection usage
6. **Unused private constants** - Safe to remove after verification

---

## 🔧 Recommended Cleanup Strategy

### Week 1: Critical Fixes
```bash
# Day 1: Fix build-breaking issues
- Fix daily_log.gleam type errors
- Test UI rendering
- Deploy fix

# Day 2-3: storage.gleam cleanup
- Remove duplicate import
- Clean shadowed imports (carefully!)
- Remove unused imports
- Run full test suite
```

### Week 2: Domain Module Cleanup
```bash
# Day 1: storage/recipes.gleam
- Remove unused imports
- Evaluate validate_category function
- Update tests if needed

# Day 2: storage/logs.gleam
- Remove unused imports
- Evaluate validate_category function
- Ensure validation is happening elsewhere

# Day 3: storage/foods.gleam
- Remove unused module imports
- Quick verification
```

### Week 3: UI/Web Cleanup
```bash
# Day 1: Investigate unreachable pattern
- Fix logic issue in search.gleam
- Add test coverage

# Day 2: UI component warnings
- Clean up unused imports
- Verify functionality
```

---

## 📈 Expected Impact

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Total Warnings | 137 | 0 | 100% |
| Build Status | FAILING | PASSING | Critical |
| Code Maintainability | Medium | High | Significant |
| Import Clarity | Low | High | Significant |
| Risk of Hidden Bugs | Medium | Low | Important |

---

## 🎓 Lessons Learned

### Anti-patterns Identified

1. **Re-export with shadowing**: `storage.gleam` imports functions then defines wrappers with identical names
   - Better: Use module prefixes or rename wrappers

2. **Duplicate validation code**: `validate_category` appears in multiple files
   - Better: Centralize in shared module

3. **Unused imports accumulation**: Suggests incomplete refactoring
   - Better: Regular cleanup, use linter in CI

### Recommended Practices

1. **Enable Gleam's strict warnings in CI/CD**
2. **Regular import cleanup** as part of code review
3. **Avoid re-export shadowing** - use explicit prefixes
4. **Centralize validation logic** in dedicated module
5. **Add tests for validation paths** to catch unused validators

---

## 🚀 Quick Win Actions

These can be done in < 1 hour with zero risk:

```bash
# 1. Remove unused module imports (9 warnings, 15 min)
storage/foods.gleam: Remove gleam/int, gleam/list, gleam/string
storage/migrations.gleam: Remove pog

# 2. Fix duplicate import (1 warning, 5 min)
storage.gleam: Consolidate profile imports

# 3. Remove obviously unused type constructors (10 warnings, 20 min)
storage.gleam: Remove ProfileStorageError alias
storage/logs.gleam: Remove Active, Gain, Lose, Sedentary

# 4. Remove unused private constants (2 warnings, 10 min)
storage/recipes.gleam: Remove valid_food_categories (line 23)
storage/logs.gleam: Remove valid_food_categories (line 22)
```

**Total quick wins**: 22 warnings removed in ~50 minutes

---

## 📋 Tracking Progress

Create beads tasks:

```bash
bd create "Fix daily_log type errors (BUILD BREAKING)" \
  --priority critical \
  --track ui

bd create "Clean storage.gleam shadowed imports (28 warnings)" \
  --priority high \
  --track storage-cleanup

bd create "Remove unused imports from storage modules (50+ warnings)" \
  --priority medium \
  --track storage-cleanup

bd create "Fix unreachable pattern in search.gleam" \
  --priority medium \
  --track web-handlers

bd create "Quick wins: Remove trivial unused imports (22 warnings)" \
  --priority low \
  --track tech-debt
```

---

## ✅ Success Criteria

- [ ] Build passes without errors
- [ ] Zero compilation warnings
- [ ] All tests pass
- [ ] No functionality regression
- [ ] Code review approved
- [ ] Documentation updated (if validation removed)

---

**Next Steps**: Fix the critical build error in `daily_log.gleam` immediately, then tackle quick wins for momentum.
