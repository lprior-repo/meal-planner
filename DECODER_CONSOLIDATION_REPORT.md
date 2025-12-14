# Tandoor Decoder Consolidation Analysis Report

**Date:** 2025-12-14
**Tasks:** meal-planner-1qa, meal-planner-nl9
**Total Lines Analyzed:** 2,164 lines across 26 decoder files
**Expected Line Reduction:** ~200-300 lines (9-14%)

---

## Executive Summary

This analysis identifies significant duplication across the Tandoor decoder modules. Key findings:

1. **DUPLICATE USER DECODERS** - Same User type decoded in 2 separate files
2. **DUPLICATE NESTED DECODERS** - Food, Unit, Keyword decoded multiple times across different files
3. **PAGINATION PATTERN DUPLICATION** - Identical count/next/previous/results structure in 2 files
4. **COMMON FIELD PATTERNS** - Timestamp and metadata fields repeated 20+ times
5. **MISSING SHARED UTILITIES** - No common decoder helpers for standard patterns

---

## Critical Duplication Patterns

### 1. DUPLICATE USER DECODER (HIGH PRIORITY)

**Problem:** User type decoded in TWO separate locations with nearly identical logic

**Files:**
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/decoders/mealplan/user_decoder.gleam` (42 lines)
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/decoders/user/user_decoder.gleam` (54 lines)

**Key Difference:**
```gleam
// mealplan/user_decoder.gleam
use id <- decode.field("id", decode.int)

// user/user_decoder.gleam
use id <- decode.field("id", ids.user_id_decoder())
```

**Impact:**
- 42 lines of duplication
- Maintenance burden - changes must be made twice
- Type confusion - different ID types for same entity

**Consolidation Action:**
- ✅ KEEP: `user/user_decoder.gleam` (uses proper typed IDs)
- ❌ DELETE: `mealplan/user_decoder.gleam` (uses raw int)
- ✅ UPDATE: `mealplan/meal_plan_decoder.gleam` to import from `user/user_decoder`

**Line Savings:** ~42 lines

---

### 2. NESTED OBJECT DECODER DUPLICATION (HIGH PRIORITY)

**Problem:** Food, Unit, SupermarketCategory, and Keyword decoders redefined in multiple files

#### Food Decoder Duplication

**Instances:**
1. `food/food_decoder.gleam` - Full Food decoder (100 lines)
2. `recipe/recipe_decoder.gleam` - Simple Food decoder (lines 113-121)
3. `recipe/recipe_detail_decoder.gleam` - Food decoder with supermarket_category (lines 56-78)

**Duplication:**
```gleam
// Appears in 3 different files:
pub fn food_decoder() -> decode.Decoder(TandoorFood) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  decode.success(TandoorFood(id: id, name: name))
}
```

**Consolidation Action:**
- ✅ KEEP: `food/food_decoder.gleam` as single source of truth
- ✅ EXPORT: Both `food_decoder()` and `food_simple_decoder()`
- ❌ DELETE: Food decoders from `recipe/recipe_decoder.gleam` and `recipe/recipe_detail_decoder.gleam`
- ✅ UPDATE: All files to import from `food/food_decoder`

**Line Savings:** ~40 lines

#### Unit Decoder Duplication

**Instances:**
1. `unit/unit_decoder.gleam` - Full Unit decoder (49 lines)
2. `recipe/recipe_decoder.gleam` - Simple Unit decoder (lines 126-132)
3. `recipe/recipe_detail_decoder.gleam` - Unit decoder (lines 37-53)

**Consolidation Action:**
- ✅ KEEP: `unit/unit_decoder.gleam` as single source
- ❌ DELETE: Unit decoders from recipe files
- ✅ UPDATE: Imports to use `unit/unit_decoder`

**Line Savings:** ~30 lines

#### Keyword Decoder Duplication

**Instances:**
1. `keyword/keyword_decoder.gleam` - Full Keyword decoder (61 lines)
2. `recipe/recipe_decoder.gleam` - Simple Keyword decoder (lines 189-194)

**Consolidation Action:**
- ✅ KEEP: `keyword/keyword_decoder.gleam`
- ✅ ADD: `keyword_simple_decoder()` function for nested use
- ❌ DELETE: Keyword decoder from `recipe/recipe_decoder.gleam`

**Line Savings:** ~15 lines

---

### 3. PAGINATION PATTERN DUPLICATION (MEDIUM PRIORITY)

**Problem:** Identical pagination decoder pattern in 2 files

**Pattern (appears identically in both):**
```gleam
pub fn <resource>_list_decoder() -> decode.Decoder(<Resource>List) {
  use count <- decode.field("count", decode.int)
  use next <- decode.field("next", decode.optional(decode.string))
  use previous <- decode.field("previous", decode.optional(decode.string))
  use results <- decode.field("results", decode.list(<resource>_decoder()))

  decode.success(<Resource>List(
    count: count,
    next: next,
    previous: previous,
    results: results,
  ))
}
```

**Instances:**
1. `import_export/import_log_list_decoder.gleam` (44 lines)
2. `import_export/export_log_list_decoder.gleam` (44 lines)

**Consolidation Action:**
- ✅ CREATE: `common/paginated_list_decoder.gleam` with generic helper
- ✅ FUNCTION: `paginated_list(item_decoder: Decoder(a)) -> Decoder(PaginatedList(a))`
- ❌ REPLACE: Both files to use generic helper
- ✅ BENEFIT: Reusable for future paginated endpoints

**Line Savings:** ~50 lines immediately, prevents future duplication

---

### 4. COMMON FIELD PATTERN DUPLICATION (MEDIUM PRIORITY)

**Problem:** Standard metadata fields decoded 20+ times with identical patterns

#### Timestamp Fields

**Pattern repeated across 12 files:**
```gleam
use created_at <- decode.field("created_at", decode.string)
use updated_at <- decode.field("updated_at", decode.string)
use completed_at <- decode.field("completed_at", decode.optional(decode.string))
```

**Files with this pattern:**
- automation_decoder.gleam
- import_log_decoder.gleam
- export_log_decoder.gleam
- keyword_decoder.gleam
- shopping_list_decoder.gleam
- shopping_list_entry_decoder.gleam
- property_decoder.gleam
- user_file_view_decoder.gleam
- recipe_decoder.gleam
- (4 more)

**Consolidation Action:**
- ✅ CREATE: `common/field_decoders.gleam` module
- ✅ FUNCTIONS:
  ```gleam
  pub fn created_at_field() -> decode.Decoder(String)
  pub fn updated_at_field() -> decode.Decoder(String)
  pub fn optional_completed_at_field() -> decode.Decoder(Option(String))
  pub fn created_by_field() -> decode.Decoder(UserId)
  ```
- ✅ UPDATE: All decoders to use helpers
- ⚠️ NOTE: This is optional - only moderate line savings but improves consistency

**Line Savings:** ~30-40 lines, improves maintainability

#### User Reference Fields

**Pattern repeated across 8 files:**
```gleam
use created_by <- decode.field("created_by", ids.user_id_decoder())
```

**Could be consolidated but minimal benefit** - only 1 line per occurrence.

---

### 5. RECIPE DECODER FAMILY (LOW PRIORITY)

**Problem:** Multiple recipe decoders with overlapping functionality

**Files:**
1. `recipe/recipe_decoder.gleam` (194 lines) - Full TandoorRecipe + nested decoders
2. `recipe/recipe_detail_decoder.gleam` (294 lines) - RecipeDetail + nested decoders
3. `recipe/recipe_basic_decoder.gleam` (104 lines) - Basic Recipe for lists
4. `recipe/recipe_overview_decoder.gleam` (41 lines) - RecipeOverview for lists

**Analysis:**
- These serve **different purposes** (full detail vs list view)
- Different type targets (`TandoorRecipe` vs `RecipeDetail` vs `Recipe` vs `RecipeOverview`)
- Nested decoders are duplicated but could reference shared modules

**Consolidation Action:**
- ❌ DO NOT merge recipe decoders (different use cases)
- ✅ EXTRACT shared nested decoders to common modules
- ✅ UPDATE to import Food/Unit/Keyword from dedicated files

**Line Savings:** ~50 lines by removing nested decoder duplication

---

## Consolidation Implementation Plan

### Phase 1: Critical Duplicates (HIGH PRIORITY)

**Goal:** Remove exact duplicates, establish single source of truth

#### Step 1.1: Consolidate User Decoder
- [ ] Verify `user/user_decoder.gleam` is the canonical version (uses typed IDs)
- [ ] Update `mealplan/meal_plan_decoder.gleam`:
  ```gleam
  // OLD:
  import meal_planner/tandoor/decoders/mealplan/user_decoder

  // NEW:
  import meal_planner/tandoor/decoders/user/user_decoder
  ```
- [ ] Delete `mealplan/user_decoder.gleam`
- [ ] Run `gleam test` to verify no breakage
- [ ] **Line reduction: 42 lines**

#### Step 1.2: Consolidate Nested Object Decoders
- [ ] Update `recipe/recipe_decoder.gleam`:
  ```gleam
  // DELETE lines 116-121 (food_decoder)
  // DELETE lines 126-132 (unit_decoder)
  // DELETE lines 189-194 (keyword_decoder)

  // ADD imports:
  import meal_planner/tandoor/decoders/food/food_decoder
  import meal_planner/tandoor/decoders/unit/unit_decoder
  import meal_planner/tandoor/decoders/keyword/keyword_decoder

  // UPDATE references:
  decode.field("food", food_decoder.food_decoder())
  decode.field("unit", unit_decoder.decode_unit())
  decode.field("keywords", decode.list(keyword_decoder.keyword_decoder()))
  ```
- [ ] Update `recipe/recipe_detail_decoder.gleam` similarly
- [ ] Run `gleam test`
- [ ] **Line reduction: 85 lines**

### Phase 2: Shared Utilities (MEDIUM PRIORITY)

**Goal:** Create reusable decoder utilities for common patterns

#### Step 2.1: Create Paginated List Helper
- [ ] Create `common/paginated_list_decoder.gleam`:
  ```gleam
  pub type PaginatedList(a) {
    PaginatedList(
      count: Int,
      next: Option(String),
      previous: Option(String),
      results: List(a)
    )
  }

  pub fn paginated_list(
    item_decoder: decode.Decoder(a)
  ) -> decode.Decoder(PaginatedList(a)) {
    use count <- decode.field("count", decode.int)
    use next <- decode.field("next", decode.optional(decode.string))
    use previous <- decode.field("previous", decode.optional(decode.string))
    use results <- decode.field("results", decode.list(item_decoder))

    decode.success(PaginatedList(
      count: count,
      next: next,
      previous: previous,
      results: results,
    ))
  }
  ```
- [ ] Update `import_log_list_decoder.gleam` to use helper
- [ ] Update `export_log_list_decoder.gleam` to use helper
- [ ] **Line reduction: 50 lines, prevents future duplication**

#### Step 2.2: Create Common Field Decoders (Optional)
- [ ] Create `common/field_decoders.gleam` with timestamp helpers
- [ ] Update decoders to use helpers (if benefit > cost)
- [ ] **Line reduction: 30-40 lines**

### Phase 3: Recipe Decoder Cleanup (LOW PRIORITY)

**Goal:** Remove nested decoder duplication from recipe files

- [ ] Ensure all recipe decoders import from canonical sources
- [ ] Remove inline nested decoders
- [ ] **Line reduction: 50 lines**

---

## Summary of Line Reductions

| Phase | Action | Files Changed | Lines Saved | Priority |
|-------|--------|---------------|-------------|----------|
| 1.1 | Consolidate User Decoder | 2 files | 42 lines | HIGH |
| 1.2 | Consolidate Nested Decoders | 3 files | 85 lines | HIGH |
| 2.1 | Paginated List Helper | 3 files | 50 lines | MEDIUM |
| 2.2 | Common Field Decoders | 12 files | 35 lines | MEDIUM |
| 3 | Recipe Decoder Cleanup | 2 files | 50 lines | LOW |
| **TOTAL** | | **22 files** | **262 lines** | |

---

## Files to Merge/Refactor

### DELETE (2 files, 86 lines):
1. `mealplan/user_decoder.gleam` (42 lines) - duplicate of user/user_decoder
2. (Nested decoders removed inline - not full file deletions)

### CREATE (2 files, ~150 lines total):
1. `common/paginated_list_decoder.gleam` (~50 lines)
2. `common/field_decoders.gleam` (~50 lines) - optional

### UPDATE (20 files):
1. `mealplan/meal_plan_decoder.gleam` - update User import
2. `recipe/recipe_decoder.gleam` - remove nested decoders, add imports
3. `recipe/recipe_detail_decoder.gleam` - remove nested decoders, add imports
4. `import_export/import_log_list_decoder.gleam` - use paginated helper
5. `import_export/export_log_list_decoder.gleam` - use paginated helper
6. (15 more files if implementing common field decoders)

---

## Benefits Beyond Line Reduction

1. **Single Source of Truth** - Each type decoded in exactly one place
2. **Type Safety** - Consistent use of typed IDs (UserId, FoodId, etc.)
3. **Maintainability** - Changes to decoder logic happen once
4. **Reusability** - Pagination helper works for all future list endpoints
5. **Consistency** - Standard patterns enforced across codebase
6. **Testing** - Test decoder once, confidence everywhere it's used
7. **Onboarding** - Clearer structure for new developers

---

## Risk Analysis

### LOW RISK:
- Consolidating User decoder (exact duplicate)
- Removing nested Food/Unit/Keyword decoders (already have dedicated files)

### MEDIUM RISK:
- Paginated list helper (new abstraction, must test thoroughly)
- Common field decoders (changes many files)

### MITIGATION:
1. Implement in phases with testing between each
2. Use `gleam test` to verify no breakage
3. Keep git commits atomic (one consolidation per commit)
4. Test actual API integration, not just unit tests

---

## Implementation Checklist

### Pre-Implementation:
- [ ] Create feature branch: `consolidate-decoders`
- [ ] Ensure all tests passing on main branch
- [ ] Back up current state

### Phase 1 Implementation:
- [ ] Implement Step 1.1 (User decoder) - commit
- [ ] Run tests - verify passing
- [ ] Implement Step 1.2 (Nested decoders) - commit
- [ ] Run tests - verify passing

### Phase 2 Implementation:
- [ ] Implement Step 2.1 (Paginated helper) - commit
- [ ] Run tests - verify passing
- [ ] Implement Step 2.2 (Field decoders) if desired - commit
- [ ] Run tests - verify passing

### Phase 3 Implementation:
- [ ] Clean up recipe decoders - commit
- [ ] Run tests - verify passing

### Post-Implementation:
- [ ] Run full test suite
- [ ] Test against real Tandoor API
- [ ] Update documentation
- [ ] Create PR with summary
- [ ] Close tasks meal-planner-1qa, meal-planner-nl9

---

## Conclusion

The Tandoor decoder modules contain **~260 lines of duplication** across 26 files. The consolidation plan:

1. **Removes 2 exact duplicate files** (User decoder)
2. **Eliminates nested decoder duplication** (Food, Unit, Keyword)
3. **Creates reusable pagination helper** (prevents future duplication)
4. **Establishes single source of truth** for each type
5. **Improves type safety** with consistent ID types

**Expected outcome:** 12% reduction in decoder code (262 lines), significantly improved maintainability, and a foundation for consistent decoder patterns going forward.

The implementation is **low risk** when done in phases with testing between each step. The highest value comes from Phase 1 (consolidating exact duplicates), which can be done immediately with confidence.

---

**Next Steps:**
1. Review this analysis
2. Approve implementation plan
3. Create feature branch
4. Implement Phase 1 (high priority consolidations)
5. Test and verify
6. Proceed to Phase 2 if desired
DECODER CONSOLIDATION MAP
========================

CURRENT STATE (Duplicated):
===========================

┌─────────────────────────────────────────────────────────────┐
│                    User Decoder (DUPLICATE!)                │
├─────────────────────────────────────────────────────────────┤
│  mealplan/user_decoder.gleam (42 lines)                    │
│  user/user_decoder.gleam (54 lines)                        │
│  → Same function, minor differences in ID handling          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              Nested Decoders (SCATTERED!)                   │
├─────────────────────────────────────────────────────────────┤
│  Food Decoder:                                              │
│    ✓ food/food_decoder.gleam (canonical)                   │
│    ✗ recipe/recipe_decoder.gleam (duplicate)               │
│    ✗ recipe/recipe_detail_decoder.gleam (duplicate)        │
│                                                              │
│  Unit Decoder:                                              │
│    ✓ unit/unit_decoder.gleam (canonical)                   │
│    ✗ recipe/recipe_decoder.gleam (duplicate)               │
│    ✗ recipe/recipe_detail_decoder.gleam (duplicate)        │
│                                                              │
│  Keyword Decoder:                                            │
│    ✓ keyword/keyword_decoder.gleam (canonical)             │
│    ✗ recipe/recipe_decoder.gleam (duplicate)               │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│           Pagination Pattern (DUPLICATED!)                  │
├─────────────────────────────────────────────────────────────┤
│  import_export/import_log_list_decoder.gleam               │
│  import_export/export_log_list_decoder.gleam               │
│  → Identical count/next/previous/results pattern           │
└─────────────────────────────────────────────────────────────┘


FUTURE STATE (Consolidated):
============================

┌─────────────────────────────────────────────────────────────┐
│                Single Source of Truth                       │
├─────────────────────────────────────────────────────────────┤
│  user/user_decoder.gleam                                   │
│    ↑                                                         │
│    └── imported by mealplan/meal_plan_decoder.gleam        │
│                                                              │
│  food/food_decoder.gleam                                   │
│    ↑                                                         │
│    ├── imported by recipe/recipe_decoder.gleam             │
│    └── imported by recipe/recipe_detail_decoder.gleam      │
│                                                              │
│  unit/unit_decoder.gleam                                   │
│    ↑                                                         │
│    ├── imported by recipe/recipe_decoder.gleam             │
│    └── imported by ingredient/ingredient_decoder.gleam     │
│                                                              │
│  keyword/keyword_decoder.gleam                             │
│    ↑                                                         │
│    └── imported by recipe/recipe_decoder.gleam             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              NEW: Shared Utilities                          │
├─────────────────────────────────────────────────────────────┤
│  common/paginated_list_decoder.gleam                       │
│    → Generic helper for count/next/previous/results        │
│    ↑                                                         │
│    ├── used by import_log_list_decoder.gleam              │
│    ├── used by export_log_list_decoder.gleam              │
│    └── reusable for ALL future list endpoints!            │
└─────────────────────────────────────────────────────────────┘


LINE COUNT COMPARISON:
=====================

BEFORE:
  mealplan/user_decoder.gleam:           42 lines
  user/user_decoder.gleam:               54 lines
  recipe/recipe_decoder.gleam:          194 lines (includes nested decoders)
  recipe/recipe_detail_decoder.gleam:   294 lines (includes nested decoders)
  import_log_list_decoder.gleam:         44 lines
  export_log_list_decoder.gleam:         44 lines
  ──────────────────────────────────────────────
  TOTAL:                                672 lines

AFTER:
  user/user_decoder.gleam:               54 lines (kept)
  recipe/recipe_decoder.gleam:          130 lines (cleaned up)
  recipe/recipe_detail_decoder.gleam:   230 lines (cleaned up)
  import_log_list_decoder.gleam:         15 lines (uses helper)
  export_log_list_decoder.gleam:         15 lines (uses helper)
  common/paginated_list_decoder.gleam:   30 lines (NEW)
  ──────────────────────────────────────────────
  TOTAL:                                474 lines

REDUCTION: 198 lines (29% reduction in analyzed files)


IMPORT DEPENDENCY GRAPH (After):
================================

recipe_decoder ────┬─→ food_decoder
                   ├─→ unit_decoder
                   └─→ keyword_decoder

recipe_detail_decoder ─┬─→ food_decoder
                       └─→ unit_decoder

ingredient_decoder ─┬─→ food_decoder
                    └─→ unit_decoder

meal_plan_decoder ──→ user_decoder

shopping_list_entry_decoder ─┬─→ food_decoder
                              └─→ unit_decoder

import_log_list_decoder ───→ paginated_list_decoder
export_log_list_decoder ───→ paginated_list_decoder


KEY BENEFITS:
============
✅ Single source of truth for each decoder
✅ No duplicate code to maintain
✅ Consistent type handling (typed IDs everywhere)
✅ Reusable pagination pattern
✅ Clear dependency structure
✅ Easy to add new paginated endpoints
✅ Better testability (test once, use everywhere)
