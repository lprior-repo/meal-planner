# FatSecret Recipes Search Parser Fix

## Issue: meal-planner-9jm
**Priority:** P1
**Status:** Fixed ✅

## Problem

The `recipe_search_response_decoder()` in `/gleam/src/meal_planner/fatsecret/recipes/decoders.gleam` was incorrectly handling the nested `Option` type returned by the decoder.

### Root Cause

When using `decode.optional_field()` with `decode.optional()`, the result is a **nested Option**: `Option(Option(List))`, not just `Option(List)`.

The decoder was structured as:
```gleam
use recipes <- decode.optional_field(
  "recipes",
  None,
  decode.optional(decode.one_of(
    // ... decoders for recipe list or single recipe
  )),
)
```

This creates:
- `None` - if the "recipes" field is missing
- `Some(None)` - if the "recipes" field exists but has no "recipe" key (empty results)
- `Some(Some(list))` - if recipes exist

### The Bug

The original unwrapping code was:
```gleam
let recipes_list = case recipes {
  Some(list) -> list  // ❌ Wrong - 'list' is still Option(List), not List
  None -> []
}
```

This caused a type mismatch because `list` was `Option(List)`, not `List`.

## Solution

Properly unwrap the nested `Option(Option(List))`:

```gleam
// recipes is Option(Option(List)) - unwrap nested Options
let recipes_list = case recipes {
  None -> []                    // Field missing
  Some(None) -> []              // Field present but no recipes
  Some(Some(list)) -> list      // Recipes found
}
```

## Test Cases

The fix handles all three FatSecret API response scenarios:

### 1. Multiple Results
```json
{
  "recipes": {
    "recipe": [
      {"recipe_id": "1", ...},
      {"recipe_id": "2", ...}
    ]
  },
  "total_results": 2
}
```
Returns: `Some(Some([recipe1, recipe2]))`

### 2. Single Result
```json
{
  "recipes": {
    "recipe": {"recipe_id": "1", ...}
  },
  "total_results": 1
}
```
Returns: `Some(Some([recipe1]))`

### 3. No Results
```json
{
  "recipes": {},
  "total_results": 0
}
```
Returns: `Some(None)` - the field exists but is empty

## Files Modified

- `/gleam/src/meal_planner/fatsecret/recipes/decoders.gleam` - Lines 286-291

## Verification

The fix aligns with the pattern already used in the codebase for handling optional nested structures. Similar patterns can be found in other FatSecret decoders.

### Code Comparison

**Before (Broken):**
```gleam
// recipes is Option(List) - unwrap it
let recipes_list = case recipes {
  Some(list) -> list  // ❌ Type error: list is Option(List), not List
  None -> []
}
```

**After (Fixed):**
```gleam
// recipes is Option(Option(List)) - unwrap nested Options
let recipes_list = case recipes {
  None -> []              // ✅ Field missing
  Some(None) -> []        // ✅ Field present but no recipes
  Some(Some(list)) -> list // ✅ Recipes found
}
```

The fix now correctly matches commit bd3f8f5.

## Related

- Original commit: bd3f8f5
- This fix restores the correct nested Option handling that was in that commit

## Hooks Executed

```bash
npx claude-flow@alpha hooks pre-task --description "Fix Recipes parser"
npx claude-flow@alpha hooks post-edit --file "gleam/src/meal_planner/fatsecret/recipes/decoders.gleam" --memory-key "swarm/recipes-parser/fixed"
```

## Impact

- ✅ Fixes parser errors when FatSecret returns empty recipe search results
- ✅ Maintains compatibility with single and multiple result responses
- ✅ No breaking changes to the API
