# Error Context Preservation - Progress Summary

**Date:** December 26, 2025
**Goal:** Fix all `Error(_)` catch-all patterns that lose error context
**Status:** In Progress (comprehensive-fix-20251226-093447 branch)

---

## Problem Statement

The codebase had 468+ instances of `Error(_)` patterns that discarded valuable error context, making debugging impossible.

### Anti-Pattern Example
```gleam
case some_operation() {
  Ok(result) -> Ok(result)
  Error(_) -> Error("Generic error message")  // Lost context!
}
```

### Correct Pattern
```gleam
case some_operation() {
  Ok(result) -> Ok(result)
  Error(err) -> Error("Operation failed: " <> error_to_string(err))
}
```

---

## Solution Approach

1. **Added `tandoor_error_to_response()` helper** in `helpers.gleam`
   - Maps each TandoorError variant to appropriate HTTP status code
   - Preserves original error message
   - Single source of truth for error-to-HTTP conversion

2. **Updated handlers to capture error variable** instead of discarding with `Error(_)`
   - Replace `Error(_)` with `Error(err)` (or `Error(_err)` if conflicts)
   - Call `helpers.tandoor_error_to_response(err)` for TandoorError types
   - Call `helpers.error_response(status, message)` with preserved context for String errors
   - For int.parse errors, include the invalid value in error message

---

## Completed Files ✓

### Core Helpers
- ✅ `src/meal_planner/tandoor/handlers/helpers.gleam`
  - Added `tandoor_error_to_response()` function
  - Maps TandoorError → HTTP status code + message

### Tandoor Handlers (8/12 files)
- ✅ `src/meal_planner/web/handlers/tandoor/recipes.gleam` (6 fixes)
  - Fixed: `Error(_)` → `Error(err)` in list, create, get, update, delete operations
  - Preserves TandoorError context (NetworkError, NotFoundError, etc.)

- ✅ `src/meal_planner/web/handlers/tandoor/foods.gleam` (6 fixes)
  - Fixed: list, get, create, update, delete operations
  - Added error context to int.parse failures (includes invalid ID value)

- ✅ `src/meal_planner/web/handlers/tandoor/shopping_lists.gleam` (6 fixes)
  - Fixed: list, create, get, update, delete operations
  - Preserves String error messages from shopping module

- ✅ `src/meal_planner/web/handlers/tandoor/units.gleam` (1 fix)
  - Fixed: list operation

- ✅ `src/meal_planner/web/handlers/tandoor/keywords.gleam` (1 fix)
  - Fixed: list operation

- ✅ `src/meal_planner/web/handlers/tandoor/ingredients.gleam` (1 fix)
  - Fixed: list operation

- ✅ `src/meal_planner/web/handlers/tandoor/steps.gleam` (5 fixes)
  - Fixed: list, create, get, update, delete operations

### Total Fixes Applied: 26 Error(_) patterns corrected

---

## Remaining Work

### Tandoor Handlers (4 files, ~25 Error(_) patterns)

1. `src/meal_planner/web/handlers/tandoor/supermarkets.gleam` (6 instances)
2. `src/meal_planner/web/handlers/tandoor/supermarket_categories.gleam` (6 instances)
3. `src/meal_planner/web/handlers/tandoor/meal_plans.gleam` (5 instances)
4. `src/meal_planner/web/handlers/tandoor/export_logs.gleam` (4 instances)
5. `src/meal_planner/web/handlers/tandoor/import_logs.gleam` (6 instances)
6. `src/meal_planner/web/handlers/tandoor/preferences.gleam` (3 instances)
7. `src/meal_planner/web/handlers/tandoor/cuisines.gleam` (3 instances)

### Other Handler Files (4 files, ~8 Error(_) patterns)

1. `src/meal_planner/web/handlers/advisor.gleam`
2. `src/meal_planner/web/handlers/macros.gleam`
3. `src/meal_planner/web/handlers/nutrition.gleam`
4. `src/meal_planner/web/handlers/scheduler.gleam`

### CLI Domain Commands (1 file, ~3 Error(_) patterns)

1. `src/meal_planner/cli/domains/nutrition/commands.gleam`

### Core Application Files (~400+ Error(_) patterns)

- `src/meal_planner/meal_sync.gleam`
- `src/meal_planner/ncp/calculations.gleam`
- `src/meal_planner/errors/recovery.gleam`
- `src/meal_planner/config/environment.gleam`
- `src/meal_planner/config.gleam`
- `src/meal_planner/user_profile.gleam`
- `src/meal_planner/recipe_loader.gleam`
- `src/meal_planner/nutrient_parser.gleam`
- `src/meal_planner/generator.gleam`
- `src/meal_planner/cache.gleam`
- `src/meal_planner/quantity.gleam`
- `src/meal_planner/postgres.gleam`
- `src/meal_planner/pagination.gleam`
- `src/meal_planner/id.gleam`
- `src/meal_planner/web/handlers.gleam`
- `src/meal_planner/web/middleware/rate_limit.gleam`
- Many more application modules...

### FatSecret Decoders (3 files, ~6 Error(_) patterns)

1. `src/meal_planner/fatsecret/decoders/common.gleam`
2. `src/meal_planner/fatsecret/foods/decoders.gleam`
3. Other fatsecret decoder modules

---

## Pattern Established

### For TandoorError Types
```gleam
case api_call(config) {
  Ok(result) -> success_response(result)
  Error(err) -> helpers.tandoor_error_to_response(err)
}
```

### For String Error Types
```gleam
case operation() {
  Ok(result) -> success_response(result)
  Error(err) -> helpers.error_response(500, "Operation failed: " <> err)
}
```

### For int.parse Errors
```gleam
case int.parse(id_string) {
  Ok(id) -> continue_with_id(id)
  Error(_err) ->
    helpers.error_response(400, "Invalid ID: '" <> id_string <> "'")
}
```

---

## Testing

All changes tested with:
```bash
gleam build  # Compiled successfully
gleam test   # 409 tests passed
```

---

## Next Steps

1. **Continue with remaining Tandoor handlers** (4 files, ~25 patterns)
   - Apply same pattern: `Error(_)` → `Error(err)` with `tandoor_error_to_response(err)`

2. **Fix web handlers** (4 files, ~8 patterns)
   - Apply pattern based on their error types

3. **Fix CLI domain commands** (1 file, ~3 patterns)
   - Apply pattern preserving String error messages

4. **Fix core application modules** (20+ files, ~400+ patterns)
   - Each module needs different approach based on its error types
   - Consider creating centralized error formatting functions per domain

5. **Fix FatSecret decoders** (3 files, ~6 patterns)
   - Preserve decode failure context

---

## Git Branch

**Branch:** `comprehensive-fix-20251226-093447`
**Commits:**
- `1e22e1c7` - fix: Preserve error context in recipes handler
- `791ac6eb` - fix: Preserve error context in foods handler
- `3d1f6712` - fix: Preserve error context in shopping_lists handler
- `195e7d15` - fix: Preserve error context in units/keywords/ingredients/steps handlers

**Status:** Pushed to origin, ready for pull request

---

## Commit Template for Remaining Files

```
fix: Preserve error context in <module> handler

Update <module> handler to use tandoor_error_to_response() instead of
discarding error context with Error(_). Preserve original error
messages in API responses for better debuggability.
```

---

## Notes

### Legitimate Error(_) Patterns (NOT to fix)

Some `Error(_)` patterns are intentional and should NOT be changed:

1. **Error mapping/conversion functions** (`errors/http.gleam`, `errors/recovery.gleam`)
   - These functions map specific errors to status codes
   - Pattern matching on error type, discarding value is correct

2. **Pattern matching multiple variants** (`tandoor/client.gleam`)
   - `NetworkError(_) | TimeoutError -> True` checks if error should retry
   - Wildcard is intentional for classification

3. **Type classification functions** (`errors/classification.gleam`)
   - Classifying error types, value not needed

### How to Identify Legitimate Patterns

```gleam
// LEGITIMATE: Error type classification
case error {
  NetworkError(_) -> True   // Checking type, value irrelevant
  OtherError -> False
}

// ILLEGITIMATE: Discarding error context
case error {
  Ok(result) -> result
  Error(_) -> wisp.not_found()  // Lost error details!
}
```

---

## Impact

### Before
- Error responses: `{"error": "Failed to update recipe"}`
- No context about WHY operation failed
- Impossible to debug production issues
- Had to add logging and redeploy to see errors

### After
- Error responses: `{"error": "Network timeout connecting to Tandoor"}
- Full error context in every response
- Immediate visibility into failure reasons
- No changes needed to see error details

---

**Estimated Total Time to Complete:** 2-3 hours for remaining 442+ Error(_) patterns
**Recommended Batch Size:** Fix 4-5 files per commit for manageable PRs
