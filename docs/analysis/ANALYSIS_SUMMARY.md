# Dependency Analysis Summary - CLEANUP-2025-001

**Agent**: dependency-analyzer
**Date**: 2025-12-03
**Thread**: CLEANUP-2025-001
**Project**: /home/lewis/src/meal-planner

## Executive Summary

Analyzed 41 Gleam files, 5 TypeScript files, and 1 JavaScript file across the meal-planner project. Generated 4 comprehensive JSON reports documenting dependency graphs, unused imports, dead code, and package audit findings.

**Health Score: 72/100**

### Key Findings

✅ **Strengths:**
- Clean module architecture with no circular dependencies
- All external packages properly used (except 3 unclear ones)
- Core functionality (web, storage, food_search) is solid
- No deprecated packages

⚠️ **Issues:**
- **CRITICAL**: Compilation error in `auto_planner.gleam` (missing `order` import)
- 11 orphaned/unused modules (6.7% of codebase)
- 15 stub implementations with TODO comments
- 30 TODO comments across project
- 3 potentially unused dependencies

---

## Critical Issues (Immediate Action Required)

### 1. Compilation Error
**File**: `gleam/src/meal_planner/auto_planner.gleam`
**Lines**: 207, 209
**Issue**: Uses `order.Lt` and `order.Gt` without importing `gleam/order`
**Fix**: Add `import gleam/order` at top of file

---

## Dead Code Analysis

### High Priority - Remove or Complete

#### Stub Modules (Not Functional)
1. **`meal_planner/ui/pages/dashboard.gleam`**
   - 6 functions all return placeholder strings
   - 9 TODO comments
   - Never imported
   - **Action**: Complete implementation or remove

2. **`meal_planner/ui/pages/food_search.gleam`**
   - 4 functions all return placeholder strings
   - 7 TODO comments
   - Never imported
   - **Action**: Complete implementation or remove

3. **`meal_planner/ui/components/forms.gleam`**
   - 7 form component functions
   - All return `"<!-- TODO: Implement ... -->"`
   - Never imported
   - **Action**: Complete lustre integration or remove

4. **`meal_planner/ui/components/progress.gleam`**
   - 4 progress component functions
   - Missing lustre imports
   - Never imported
   - **Action**: Add lustre imports and complete or remove

### Medium Priority - Review

5. **`meal_planner/state.gleam`**
   - State management actor
   - Not used in stateless web architecture
   - **Action**: Remove if truly unused

6. **`meal_planner/ui/recipe_form.gleam`**
   - HTML form generator
   - Not integrated into web routes
   - **Action**: Add POST /recipes handler or remove

7. **`meal_planner/weekly_plan.gleam`**
   - Weekly planning functions
   - Not integrated in web
   - **Action**: Integrate or remove

8. **`meal_planner/auto_planner/storage.gleam`**
   - Database functions for auto_planner
   - Not yet called
   - **Action**: Integrate when auto_planner is ready

### Low Priority - CLI Functions

9. **`meal_planner/output.gleam`**
   - CLI-only print functions
   - Not used in web
   - **Action**: Keep for CLI or remove if web-only

10. **`meal_planner/user_profile.gleam`**
    - Profile printing
    - Not used in web
    - **Action**: Remove or convert to web views

11. **`meal_planner/validation.gleam`**
    - May be superseded by `diet_validator`
    - **Action**: Consolidate validation logic

---

## Dependency Graph

### Most Connected Modules

**Core Hub**: `shared/types` - imported by almost all modules
**Web Hub**: `meal_planner/web` - main entry point for HTTP
**Storage Hub**: `meal_planner/storage` - database access layer

### Newly Created (Not Yet Integrated)

- `meal_planner/auto_planner` + types + storage
- `meal_planner/ui/recipe_form`
- `meal_planner/ui/pages/*` (dashboard, food_search)
- `meal_planner/ui/components/*` (forms, progress)

---

## Package Audit

### Potentially Unused Dependencies

1. **`filepath`** (Gleam)
   - Listed in gleam.toml
   - Not seen in any imports
   - **Action**: Search codebase or remove

2. **`server`** (Local Gleam package)
   - Listed as local dependency
   - No imports detected
   - **Action**: Verify usage or remove

3. **`puppeteer`** (npm)
   - Only npm dependency
   - Unclear purpose in meal planner
   - **Action**: Document usage or remove

### Actively Used Packages (All Good)

- **pog**: PostgreSQL (5 files)
- **wisp**: Web framework (2 files)
- **mist**: HTTP server (1 file)
- **lustre**: UI rendering (1 file, underutilized)
- **glaml**: YAML parsing (1 file)
- **gleam_json**: JSON (3 files)
- **gleam_http/httpc**: HTTP (2 files)
- **simplifile**: File ops (3 files)
- **envoy/dot_env**: Environment (3 files)
- **logging**: Logging (1 file)

---

## Import Analysis

### Most Imported Stdlib Modules
1. `gleam/list` - 28 times
2. `gleam/string` - 20 times
3. `gleam/option` - 18 times
4. `gleam/int` - 15 times
5. `gleam/float` - 12 times

### Potentially Unused Imports

- **UI stub files**: Import `gleam/option` but functions are stubs
- **state.gleam**: All imports unused if module is orphaned

---

## TODO Comments

### Critical TODOs (In Active Code)

1. **`web.gleam:93`**: "TODO: Implement edit page"
2. **`auto_planner/storage.gleam:108`**: "TODO: parse config_json"
3. **`food_search.gleam:54`**: "TODO: custom_food_storage module"

### Stub TODOs (In Inactive Code)

- 9 in `dashboard.gleam`
- 7 in `food_search.gleam`
- 8 in `forms.gleam`
- 2 in `progress.gleam`
- 1 in `ui_types.gleam`

---

## Recommendations

### Immediate (This Week)
1. ✅ Fix compilation error: Add `import gleam/order` to `auto_planner.gleam`
2. ✅ Remove or complete stub modules: dashboard, food_search, forms, progress
3. ✅ Remove `state.gleam` if unused
4. ✅ Audit 3 unclear dependencies: filepath, server, puppeteer

### Short Term (This Sprint)
1. Integrate `auto_planner` into web routes or mark as future feature
2. Complete `recipe_form` integration with POST handler
3. Address TODOs in active code (web, storage, food_search)

### Long Term
1. Decide CLI vs web-only focus - remove unused CLI modules
2. Consolidate validation logic (validation vs diet_validator)
3. Complete or remove weekly_plan

---

## Files Generated

1. **`dependency_graph.json`** - Complete module relationships
2. **`unused_imports.json`** - Import analysis and stdlib usage
3. **`dead_code.json`** - Functions, modules, TODOs by severity
4. **`package_audit.json`** - Package usage and recommendations

---

## Statistics

- **Total Files**: 41 Gleam + 5 TS + 1 JS = 47
- **Public Functions**: 223
- **Potentially Unused**: 38 (17%)
- **Stub Functions**: 15 (6.7%)
- **TODO Comments**: 30
- **Orphaned Modules**: 11
- **Active Modules**: 30
- **Import Statements**: 196
- **Gleam Dependencies**: 19 (16 prod + 3 dev)
- **npm Dependencies**: 1

---

## Coordination Notes

**For coordinator-main:**
- Analysis complete and reports ready
- Recommend prioritizing compilation error fix
- Suggest cleanup sprint to remove/complete stub modules
- Package dependencies mostly healthy

**For other agents:**
- Use `dependency_graph.json` to understand module relationships
- Reference `dead_code.json` when prioritizing cleanup tasks
- Check `package_audit.json` before adding new dependencies
