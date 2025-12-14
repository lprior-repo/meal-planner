# Decoder Consolidation Implementation Checklist

**Tasks:** meal-planner-1qa, meal-planner-nl9
**Branch:** `consolidate-decoders`
**Estimated Time:** 1-2 hours

---

## Pre-Implementation

- [ ] Review DECODER_CONSOLIDATION_REPORT.md
- [ ] Review DECODER_CONSOLIDATION_SUMMARY.md
- [ ] Ensure all tests passing: `gleam test`
- [ ] Create feature branch: `git checkout -b consolidate-decoders`
- [ ] Backup current state: `git commit -m "Checkpoint before consolidation"`

---

## Phase 1: Critical Duplicates (High Priority)

### Step 1.1: Consolidate User Decoder (Est: 5 min)

- [ ] Verify `user/user_decoder.gleam` is canonical (uses typed IDs)
- [ ] Open `mealplan/meal_plan_decoder.gleam`
- [ ] Update import:
  ```gleam
  // OLD:
  import meal_planner/tandoor/decoders/mealplan/user_decoder

  // NEW:
  import meal_planner/tandoor/decoders/user/user_decoder
  ```
- [ ] Save file
- [ ] Delete `mealplan/user_decoder.gleam`
- [ ] Run tests: `gleam test`
- [ ] Verify passing
- [ ] Commit: `git commit -m "[meal-planner-1qa] Consolidate User decoder - remove duplicate"`
- [ ] **Line reduction: 42 lines ✓**

### Step 1.2: Consolidate Nested Decoders (Est: 15 min)

#### Part A: Update recipe_decoder.gleam

- [ ] Open `recipe/recipe_decoder.gleam`
- [ ] Delete lines 113-121 (food_decoder function)
- [ ] Delete lines 126-132 (unit_decoder function)
- [ ] Delete lines 189-194 (keyword_decoder function)
- [ ] Add imports at top:
  ```gleam
  import meal_planner/tandoor/decoders/food/food_decoder
  import meal_planner/tandoor/decoders/unit/unit_decoder
  import meal_planner/tandoor/decoders/keyword/keyword_decoder
  ```
- [ ] Update decoder references:
  - `food_decoder()` → `food_decoder.food_decoder()`
  - `unit_decoder()` → `unit_decoder.decode_unit()`
  - `keyword_decoder()` → `keyword_decoder.keyword_decoder()`
- [ ] Save file
- [ ] Run tests: `gleam test`

#### Part B: Update recipe_detail_decoder.gleam

- [ ] Open `recipe/recipe_detail_decoder.gleam`
- [ ] Delete lines 24-34 (supermarket_category_decoder)
- [ ] Delete lines 37-53 (unit_decoder)
- [ ] Delete lines 56-78 (food_decoder)
- [ ] Add imports:
  ```gleam
  import meal_planner/tandoor/decoders/food/food_decoder
  import meal_planner/tandoor/decoders/unit/unit_decoder
  import meal_planner/tandoor/decoders/supermarket/supermarket_category_decoder
  ```
- [ ] Update decoder references accordingly
- [ ] Save file
- [ ] Run tests: `gleam test`
- [ ] Verify passing
- [ ] Commit: `git commit -m "[meal-planner-1qa] Remove nested decoders - use canonical versions"`
- [ ] **Line reduction: 85 lines ✓**

---

## Phase 2: Shared Utilities (Medium Priority)

### Step 2.1: Create Paginated List Helper (Est: 20 min)

- [ ] Create directory: `mkdir -p gleam/src/meal_planner/tandoor/decoders/common`
- [ ] Create file: `gleam/src/meal_planner/tandoor/decoders/common/paginated_list_decoder.gleam`
- [ ] Add content:
  ```gleam
  /// Paginated list decoder for Tandoor API
  ///
  /// Provides a generic decoder for paginated API responses that follow
  /// the standard Django REST Framework pagination format.
  import gleam/dynamic/decode
  import gleam/option.{type Option}

  /// Generic paginated list type
  pub type PaginatedList(a) {
    PaginatedList(
      count: Int,
      next: Option(String),
      previous: Option(String),
      results: List(a)
    )
  }

  /// Decode a paginated list response
  ///
  /// Takes an item decoder and returns a decoder for paginated lists.
  /// Works with any item type that has a decoder.
  ///
  /// Example:
  /// ```gleam
  /// import meal_planner/tandoor/decoders/common/paginated_list_decoder as pld
  /// import meal_planner/tandoor/decoders/import_export/import_log_decoder
  ///
  /// let decoder = pld.paginated_list(import_log_decoder.import_log_decoder())
  /// ```
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
- [ ] Save file

#### Update import_log_list_decoder.gleam

- [ ] Open `import_export/import_log_list_decoder.gleam`
- [ ] Replace entire decoder function with:
  ```gleam
  import meal_planner/tandoor/decoders/common/paginated_list_decoder as pld
  import meal_planner/tandoor/decoders/import_export/import_log_decoder

  pub type ImportLogList = pld.PaginatedList(import_log.ImportLog)

  pub fn import_log_list_decoder() -> decode.Decoder(ImportLogList) {
    pld.paginated_list(import_log_decoder.import_log_decoder())
  }
  ```
- [ ] Save file

#### Update export_log_list_decoder.gleam

- [ ] Open `import_export/export_log_list_decoder.gleam`
- [ ] Replace similarly with pagination helper
- [ ] Save file
- [ ] Run tests: `gleam test`
- [ ] Verify passing
- [ ] Commit: `git commit -m "[meal-planner-nl9] Add paginated list helper - DRY pagination"`
- [ ] **Line reduction: 50 lines ✓**

---

## Verification & Testing

- [ ] Run full test suite: `gleam test`
- [ ] Check test coverage is maintained
- [ ] Build project: `gleam build`
- [ ] Verify no compiler warnings
- [ ] Test against live Tandoor API (if available)
- [ ] Review git diff: `git diff main..consolidate-decoders`
- [ ] Verify ~260 line reduction: `git diff --stat main..consolidate-decoders`

---

## Cleanup & Documentation

- [ ] Update any relevant documentation
- [ ] Check for any remaining TODOs
- [ ] Verify import statements are clean
- [ ] Run formatter: `gleam format`

---

## Final Steps

- [ ] Push branch: `git push -u origin consolidate-decoders`
- [ ] Create pull request
- [ ] Add PR description with summary of changes
- [ ] Link to this consolidation report in PR
- [ ] Request review
- [ ] Mark tasks as complete:
  - [ ] `bd close meal-planner-1qa --reason "Consolidated duplicate decoders"`
  - [ ] `bd close meal-planner-nl9 --reason "Created shared decoder utilities"`
- [ ] Sync beads: `bd sync`

---

## Rollback Plan (If Needed)

If issues arise:
1. Checkout main: `git checkout main`
2. Delete branch: `git branch -D consolidate-decoders`
3. Review issues and adjust plan
4. Start over with lessons learned

---

## Success Metrics

✅ All tests passing
✅ ~260 lines removed (12% reduction)
✅ 1 file deleted (mealplan/user_decoder.gleam)
✅ 1 file created (common/paginated_list_decoder.gleam)
✅ 6 files updated with better imports
✅ Zero duplicate decoder code
✅ Single source of truth established
✅ Reusable pagination helper created
✅ Tasks closed and synced
