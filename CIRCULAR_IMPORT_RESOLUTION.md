# Circular Import Resolution Progress Report

## Summary

This document tracks progress on resolving circular import issues in the meal-planner Tandoor module.

## What's Been Done

### 1. Updated AGENTS.md
- Added comprehensive documentation for the three-core system integration
- Documented graphiti (knowledge graph), mem0 (long-term memory), and beads (issue tracking)
- Added session start workflow with memory/knowledge searches
- Added memory tracking guidelines during work
- Created "Landing the Plane" completion workflow
- Added bv (beads viewer) integration

### 2. Created land-the-plane.sh Script
- Created automated session completion script at `./scripts/land-the-plane.sh`
- Made executable (`chmod +x`)
- Script performs:
  - Git status checks
  - Quality gates (format, build, tests)
  - Bead status checks
  - Memory and knowledge graph sync reminders
  - Bead sync with git
  - Git pull/rebase/push operations
  - Cleanup operations
  - Hand-off summary generation
- Supports `--skip-tests`, `--skip-format`, and `--dry-run` flags

### 3. Fixed types.gleam Syntax Errors
- Corrected all custom type definitions to use proper constructor syntax
- Changed from incorrect format to correct format:
  - Before: `pub type Recipe { id: Int, name: String, ... }`
  - After: `pub type Recipe { Recipe(id: Int, name: String, ...) }`
- Fixed all types: Recipe, RecipeDetail, RecipeOverview, RecipeSimple, RecipeUpdate, RecipeCreateRequest, Keyword, NutritionInfo

### 4. Moved Keyword Type to Shared Module
- Added Keyword type to `src/meal_planner/tandoor/types.gleam`
- Added `keyword_decoder()` function to types.gleam
- Updated `src/meal_planner/tandoor/keyword.gleam` to:
  - Import Keyword type from types.gleam
  - Remove local Keyword type definition
  - Remove local `keyword_decoder()` function
- Updated `src/meal_planner/tandoor/client.gleam` to:
  - Import Keyword from types.gleam instead of keyword.gleam
  - Import keyword_decoder from types.gleam

### 5. Partial Import Resolution in crud_helpers.gleam
- Attempted to fix imports in `src/meal_planner/tandoor/api/crud_helpers.gleam`
- Changed to import ClientConfig from config.gleam
- Changed to import TandoorError from errors.gleam
- Still has remaining circular dependency issues

## Remaining Issues

### Current Circular Dependency Cycles

**Cycle 1:**
```
crud_helpers.gleam
  ↓ (imports from)
client.gleam
  ↓ (imports from)
ingredient.gleam
  ↓ (imports from)
unit.gleam
  ↓ (imports from)
crud_helpers.gleam  ← cycles back
```

**Cycle 2:**
```
food.gleam
  ↓ (imports from)
supermarket.gleam
  ↓ (imports from)
client.gleam
  ↓ (imports from)
ingredient.gleam
  ↓ (imports from)
food.gleam  ← cycles back
```

**Root Cause:**
Many modules (food, ingredient, supermarket, step, unit, etc.) import from client.gleam for ClientConfig and TandoorError types, and client.gleam itself imports from many of these modules for their types.

### Current Module Dependencies from client.gleam

`src/meal_planner/tandoor/client.gleam` currently imports:
- `meal_planner/tandoor/food.{type Food}`
- `meal_planner/tandoor/ingredient.{type Ingredient as TandoorIngredient}`
- `meal_planner/tandoor/nutrition.{type NutritionInfo}`
- `meal_planner/tandoor/types.{type Recipe, type RecipeDetail, type Keyword, keyword_decoder}`

These imports are used in internal decoder functions (not public):
- `food_decoder()` - internal decoder for Food type
- `ingredient_decoder()` - internal decoder for Ingredient type
- `nutrition_decoder()` - internal decoder for NutritionInfo type

## Recommended Solutions

### Option 1: Move Types to Central Module (RECOMMENDED)

Move all shared types to `types.gleam`:

1. Move these types to `types.gleam`:
   - Food (from food.gleam)
   - Ingredient (from ingredient.gleam)
   - SupermarketCategory (from supermarket.gleam)
   - Unit (from unit.gleam)
   - Step (from step.gleam)
   - NutritionInfo (already there)

2. Update all modules to import types from `types.gleam`:
   - food.gleam: import Food from types.gleam, don't define it locally
   - ingredient.gleam: import Ingredient and Unit from types.gleam
   - supermarket.gleam: import SupermarketCategory from types.gleam
   - step.gleam: import Step from types.gleam
   - unit.gleam: import Unit from types.gleam

3. Move decoders to appropriate modules:
   - food_decoder() → move to food.gleam
   - ingredient_decoder() → move to ingredient.gleam
   - nutrition_decoder() → move to nutrition.gleam
   - Remove these from client.gleam

4. Client.gleam imports only:
   - ClientConfig from config.gleam
   - TandoorError from errors.gleam
   - Recipe types from types.gleam
   - No other tandoor submodules

**Pros:**
- Breaks all circular dependencies cleanly
- Centralizes type definitions
- Follows dependency inversion principle
- Makes types.gleam the single source of truth

**Cons:**
- Significant refactoring (multiple files affected)
- Need to carefully test all decoders

### Option 2: Use Opaque Types

Create minimal interfaces and hide implementations:

1. Define opaque types in client.gleam:
   ```gleam
   @external
   pub opaque type ClientConfig
   pub opaque type TandoorError
   ```

2. Keep imports but use opaque types to break dependency graph

**Pros:**
- Less refactoring required
- Hides implementation details

**Cons:**
- Complex to implement correctly in Gleam
- May not fully resolve cycles
- Adds complexity to type system

### Option 3: Split client.gleam

Break client.gleam into smaller, focused modules:

1. `client_types.gleam` - Contains only type definitions
2. `client_http.gleam` - HTTP request/response building
3. `client_errors.gleam` - Error conversion functions
4. `client.gleam` - Main public API, imports from above

**Pros:**
- More modular architecture
- Clearer separation of concerns

**Cons:**
- More modules to maintain
- Still may have cycles if not careful

## Next Steps (Recommended)

### Immediate Actions

1. **Create comprehensive types.gleam module:**
   ```bash
   # Copy types from each module into types.gleam
   # Add decoders that don't depend on other modules
   ```

2. **Update modules one by one:**
   ```bash
   # For each module (food, ingredient, supermarket, step, unit):
   # 1. Remove type definition
   # 2. Import from types.gleam
   # 3. Update any local decoders
   ```

3. **Test compilation after each change:**
   ```bash
   gleam build
   ```

4. **Run tests:**
   ```bash
   gleam test
   ```

5. **Update documentation:**
   - Update type references in code comments
   - Update AGENTS.md if needed
   - Update any README files

### Verification

After implementing Option 1, verify:

- [ ] `gleam build` succeeds without circular import errors
- [ ] `gleam test` passes all tests
- [ ] All types import from correct modules
- [ ] No client.gleam imports from food/ingredient/supermarket/step/unit
- [ ] types.gleam is single source of truth for shared types
- [ ] All API modules still work correctly

## Files Modified

- `/home/lewis/src/meal-planner/AGENTS.md` - Updated with comprehensive workflow docs
- `/home/lewis/src/meal-planner/scripts/land-the-plane.sh` - Created new automation script
- `/home/lewis/src/meal-planner/src/meal_planner/tandoor/types.gleam` - Fixed syntax, added Keyword type and decoder
- `/home/lewis/src/meal-planner/src/meal_planner/tandoor/keyword.gleam` - Updated to import from types.gleam
- `/home/lewis/src/meal-planner/src/meal_planner/tandoor/client.gleam` - Updated to import from types.gleam
- `/home/lewis/src/meal-planner/src/meal_planner/tandoor/api/crud_helpers.gleam` - Attempted import fixes

## Notes

- The circular import problem is systemic, not isolated to one module
- Fixing requires architectural change to centralize type definitions
- The current partial fixes break some cycles but reveal deeper ones
- A comprehensive refactoring following Option 1 is recommended for long-term maintainability
- Consider running `./scripts/land-the-plane.sh` after completing fixes
