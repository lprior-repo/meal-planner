# Storage Module Consistency Audit Report

**Date:** 2025-12-14
**Auditor:** Claude Code
**Scope:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/storage/`

## Executive Summary

Audit of 11 storage module files revealed **good overall consistency** with several areas for standardization. All modules follow similar patterns but have inconsistencies in error handling, decoder structure, and helper function usage.

**Key Findings:**
- ✅ All modules use `pog` for database queries
- ✅ Consistent use of `StorageError` type from `profile.gleam`
- ⚠️ Inconsistent error handling patterns (3 different approaches found)
- ⚠️ Mixed use of helper functions (`result_to_storage_error` vs manual error handling)
- ⚠️ Decoder patterns vary between modules
- ✅ Good module organization with facade pattern in `logs.gleam`

---

## 1. Error Handling Patterns

### 1.1 Pattern Analysis

**Three distinct error handling patterns found:**

#### Pattern A: Manual Error Handling (Most Common)
**Location:** `foods.gleam`, `profile.gleam`, `audit.gleam`, `logs/entries.gleam`, `logs/queries.gleam`

```gleam
case
  pog.query(sql)
  |> pog.parameter(pog.text(date))
  |> pog.returning(decoder)
  |> pog.execute(conn)
{
  Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
  Ok(pog.Returned(0, _)) -> Error(NotFound)
  Ok(pog.Returned(_, [])) -> Error(NotFound)
  Ok(pog.Returned(_, [row, ..])) -> Ok(row)
}
```

#### Pattern B: Helper Function (Inconsistent Usage)
**Location:** `foods.gleam` (lines 90, 249, 340), `profile.gleam` (lines 82, 159), `logs/summaries.gleam`

```gleam
pog.query(sql)
|> pog.parameter(pog.int(limit))
|> pog.returning(decoder)
|> pog.execute(conn)
|> result_to_storage_error
|> result.map(fn(ret) {
  let pog.Returned(_, rows) = ret
  rows
})
```

#### Pattern C: Simplified (For operations not returning data)
**Location:** `profile.gleam` (save operations), `logs/entries.gleam`

```gleam
pog.query(sql)
|> pog.parameter(pog.text(log.id))
|> pog.execute(conn)
|> result_to_storage_error
|> result.map(fn(_) { Nil })
```

### 1.2 Inconsistency Issue

**Problem:** `result_to_storage_error` helper exists but is used inconsistently:
- ✅ Used in: 6 functions in `profile.gleam`, 4 functions in `foods.gleam`, 1 in `logs/summaries.gleam`
- ❌ NOT used in: 11 functions in `foods.gleam`, 5 in `logs/entries.gleam`, 8 in `logs/queries.gleam`, all of `audit.gleam`

**Impact:**
- Code duplication (manual `Error(DatabaseError(utils.format_pog_error(e)))` repeated ~30 times)
- Harder to maintain error handling logic
- Inconsistent error transformation

### 1.3 Recommendations

**HIGH PRIORITY:**

1. **Standardize on helper function for all queries:**
   ```gleam
   // Create expanded helper set in utils.gleam

   /// Convert query result to StorageError (for list results)
   pub fn query_to_list(
     result: Result(pog.Returned(a), pog.QueryError)
   ) -> Result(List(a), StorageError) {
     case result {
       Error(e) -> Error(DatabaseError(format_pog_error(e)))
       Ok(pog.Returned(_, rows)) -> Ok(rows)
     }
   }

   /// Convert query result to StorageError (for single result)
   pub fn query_to_single(
     result: Result(pog.Returned(a), pog.QueryError)
   ) -> Result(a, StorageError) {
     case result {
       Error(e) -> Error(DatabaseError(format_pog_error(e)))
       Ok(pog.Returned(0, _)) -> Error(NotFound)
       Ok(pog.Returned(_, [])) -> Error(NotFound)
       Ok(pog.Returned(_, [row, ..])) -> Ok(row)
     }
   }

   /// Convert query result to StorageError (for void operations)
   pub fn query_to_void(
     result: Result(pog.Returned(a), pog.QueryError)
   ) -> Result(Nil, StorageError) {
     case result {
       Error(e) -> Error(DatabaseError(format_pog_error(e)))
       Ok(_) -> Ok(Nil)
     }
   }
   ```

2. **Refactor all modules to use helpers:**
   - Replace all manual error handling with appropriate helper
   - Reduces ~30 instances of duplicate error handling code
   - Centralizes error transformation logic

---

## 2. Query Execution Patterns

### 2.1 Consistent Query Building

✅ **GOOD:** All modules follow same query building pattern:

```gleam
pog.query(sql)
|> pog.parameter(pog.text(value))
|> pog.parameter(pog.int(count))
|> pog.returning(decoder)
|> pog.execute(conn)
```

### 2.2 Parameter Handling

✅ **GOOD:** Consistent use of typed parameters:
- `pog.text()` for strings
- `pog.int()` for integers
- `pog.float()` for floats
- `pog.nullable()` for optional values

### 2.3 Recommendations

✅ **NO ACTION NEEDED** - Query patterns are consistent across all modules.

---

## 3. Decoder Patterns

### 3.1 Decoder Structure

**Two decoder patterns found:**

#### Pattern A: Inline Decoders (Most Common)
**Location:** `foods.gleam`, `profile.gleam`, `logs/queries.gleam`, `logs/summaries.gleam`

```gleam
let decoder = {
  use fdc_id_int <- decode.field(0, decode.int)
  use description <- decode.field(1, decode.string)
  decode.success(UsdaFood(fdc_id: id.fdc_id(fdc_id_int), ...))
}

pog.query(sql)
|> pog.returning(decoder)
|> pog.execute(conn)
```

#### Pattern B: Named Helper Functions
**Location:** `foods.gleam` (`custom_food_decoder`), `logs/queries.gleam` (`food_log_entry_decoder`), `audit.gleam` (`audit_entry_decoder`, `audit_summary_decoder`)

```gleam
fn custom_food_decoder() -> decode.Decoder(types.CustomFood) {
  use custom_food_id_str <- decode.field(0, decode.string)
  use user_id_str <- decode.field(1, decode.string)
  // ... 30 more fields
  decode.success(types.CustomFood(...))
}

pog.query(sql)
|> pog.returning(custom_food_decoder())
|> pog.execute(conn)
```

### 3.2 Analysis

✅ **ACCEPTABLE:** Mix of patterns is appropriate:
- **Inline decoders:** Good for simple queries (< 10 fields)
- **Named functions:** Essential for complex decoders (20+ fields) that are reused

**Reuse Statistics:**
- `custom_food_decoder()`: Used 5 times in `foods.gleam` ✅
- `food_log_entry_decoder()`: Used 4 times in `logs/queries.gleam` ✅
- `audit_entry_decoder()`: Used 3 times in `audit.gleam` ✅

### 3.3 Recommendations

✅ **CURRENT PATTERN IS GOOD** - Continue using:
- Named decoder functions for complex types reused multiple times
- Inline decoders for simple, one-off queries

---

## 4. Common Helper Usage

### 4.1 Helper Function Inventory

**From `storage/utils.gleam`:**
- `format_pog_error(err: pog.QueryError) -> String` - Converts DB errors to readable strings

**From `storage/profile.gleam`:**
- `result_to_storage_error(Result(a, pog.QueryError)) -> Result(a, StorageError)` - Wraps DB errors

### 4.2 Usage Analysis

| Module | `format_pog_error` | `result_to_storage_error` |
|--------|-------------------|--------------------------|
| `profile.gleam` | ✅ Consistent (via helper) | ✅ Used 6/12 functions |
| `foods.gleam` | ✅ Consistent (via helper) | ⚠️ Used 4/15 functions |
| `logs.gleam` | N/A (facade) | N/A (facade) |
| `logs/entries.gleam` | ✅ Direct | ❌ Never used |
| `logs/queries.gleam` | ✅ Direct | ❌ Never used |
| `logs/summaries.gleam` | ✅ Consistent (via helper) | ✅ Used 1/1 function |
| `audit.gleam` | ✅ Direct | ❌ Never used |

### 4.3 Recommendations

**MEDIUM PRIORITY:**

1. **Promote `result_to_storage_error` to `utils.gleam`**
   - Currently in `profile.gleam` (domain-specific location)
   - Should be in `utils.gleam` (common utilities)
   - Makes it more discoverable and encourages usage

2. **Create additional helpers in `utils.gleam`** (see Section 1.3)

---

## 5. Storage Error Type Consistency

### 5.1 Error Type Definition

✅ **EXCELLENT:** Single source of truth in `profile.gleam`:

```gleam
pub type StorageError {
  NotFound
  DatabaseError(String)
  InvalidInput(String)
  Unauthorized(String)
}
```

### 5.2 Import Consistency

✅ **GOOD:** All modules import from `meal_planner/storage/profile`:
- `foods.gleam`: ✅ Imports and re-exports
- `logs.gleam`: ✅ Imports and re-exports
- `logs/entries.gleam`: ✅ Imports
- `logs/queries.gleam`: ✅ Imports
- `logs/summaries.gleam`: ✅ Imports
- `audit.gleam`: ❌ **Defines own `AuditError` type**

### 5.3 Issue: `audit.gleam` Custom Error Type

**Problem:**
```gleam
// audit.gleam defines:
pub type AuditError {
  DatabaseError(String)
  NotFound
}
```

This duplicates error variants from `StorageError` and breaks consistency.

### 5.4 Recommendations

**MEDIUM PRIORITY:**

1. **Refactor `audit.gleam` to use `StorageError`:**
   ```gleam
   // Remove:
   pub type AuditError {
     DatabaseError(String)
     NotFound
   }

   // Replace all function signatures:
   // Before:
   pub fn get_audit_history(...) -> Result(List(...), AuditError)

   // After:
   pub fn get_audit_history(...) -> Result(List(...), StorageError)
   ```

2. **Alternative (if audit-specific errors needed):**
   ```gleam
   // Keep AuditError but make it wrap StorageError
   pub type AuditError {
     StorageError(profile.StorageError)
     AuditSpecificError(String)
   }
   ```

---

## 6. Module Organization

### 6.1 Current Structure

```
storage/
├── mod.gleam           # Documentation hub (no code)
├── utils.gleam         # Common error formatting
├── profile.gleam       # User profiles + StorageError type
├── foods.gleam         # USDA + custom foods
├── logs.gleam          # Facade for logs/* submodules
├── logs/
│   ├── entries.gleam   # CRUD operations
│   ├── queries.gleam   # Complex queries
│   └── summaries.gleam # Aggregations
├── audit.gleam         # Audit trail queries
├── nutrients.gleam     # Empty (placeholder)
└── migrations.gleam    # Stub
```

### 6.2 Analysis

✅ **EXCELLENT:** Facade pattern in `logs.gleam`:
- Public API maintained at `meal_planner/storage/logs`
- Internal split: `entries`, `queries`, `summaries`
- Re-exports all public functions
- Clear separation of concerns

⚠️ **OPPORTUNITY:** Other large modules could benefit:
- `foods.gleam` (632 lines) could split:
  - `foods/usda.gleam` - USDA food queries
  - `foods/custom.gleam` - Custom food CRUD
  - `foods/unified.gleam` - Unified search
  - `foods/nutrients.gleam` - Nutrient queries

### 6.3 Recommendations

**LOW PRIORITY (Nice to Have):**

1. **Split `foods.gleam` using facade pattern:**
   ```gleam
   // foods.gleam (facade)
   pub type UsdaFood = usda.UsdaFood
   pub fn search_foods(conn, query, limit) {
     usda.search_foods(conn, query, limit)
   }
   // ... re-export all functions

   // foods/usda.gleam
   pub fn search_foods(...) { ... }
   pub fn get_food_by_id(...) { ... }

   // foods/custom.gleam
   pub fn create_custom_food(...) { ... }
   pub fn get_custom_food_by_id(...) { ... }
   ```

2. **Benefits:**
   - Easier testing (smaller, focused modules)
   - Better code navigation
   - Maintains backward compatibility via facade
   - Follows pattern established by `logs.gleam`

---

## 7. Specific Issues Found

### 7.1 Duplicate Micronutrient Handling

**Location:** `foods.gleam` (lines 548-617), `logs/entries.gleam` (lines 204-274, 362-432), `logs/queries.gleam` (lines 291-361)

**Issue:** Same micronutrient Option checking pattern repeated 4 times:

```gleam
let micronutrients = case
  fiber, sugar, sodium, cholesterol,
  vitamin_a, vitamin_c, vitamin_d, vitamin_e, vitamin_k,
  vitamin_b6, vitamin_b12, folate, thiamin, riboflavin, niacin,
  calcium, iron, magnesium, phosphorus, potassium, zinc
{
  None, None, None, None, None, None, None, None, None,
  None, None, None, None, None, None, None, None, None,
  None, None, None -> None

  _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ ->
    Some(types.Micronutrients(...))
}
```

**Recommendation:**

Extract to shared helper in `types.gleam` or `storage/utils.gleam`:

```gleam
/// Construct Micronutrients if any field is Some
pub fn make_micronutrients(
  fiber: Option(Float),
  sugar: Option(Float),
  // ... all 21 fields
) -> Option(types.Micronutrients) {
  case all_none([fiber, sugar, ...]) {
    True -> None
    False -> Some(types.Micronutrients(
      fiber: fiber,
      sugar: sugar,
      // ...
    ))
  }
}

fn all_none(opts: List(Option(a))) -> Bool {
  list.all(opts, fn(opt) { opt == None })
}
```

### 7.2 Inconsistent NULL Handling in SQL

**Location:** `foods.gleam` (multiple locations)

**Issue:** Mixed use of `COALESCE` vs nullable parameters:

```gleam
// Pattern A: COALESCE in SQL
"SELECT fdc_id, description, data_type, COALESCE(food_category, '') FROM foods"

// Pattern B: Optional decoder
use category <- decode.field(3, decode.optional(decode.string))
```

**Recommendation:**

Choose one approach for consistency:
- **Option 1:** Always use `COALESCE` in SQL + non-optional decoders (current most common)
- **Option 2:** Allow NULLs + optional decoders (more flexible)

**Preferred:** Option 1 (COALESCE) - simpler decoders, explicit defaults

---

## 8. Priority Summary

### HIGH Priority (Address Soon)

1. **Standardize Error Handling**
   - Add `query_to_list`, `query_to_single`, `query_to_void` helpers to `utils.gleam`
   - Refactor all modules to use helpers
   - **Estimated effort:** 2-3 hours
   - **Impact:** Removes ~30 instances of duplicate code

### MEDIUM Priority (Next Sprint)

2. **Move `result_to_storage_error` to `utils.gleam`**
   - Better location for cross-module helper
   - **Estimated effort:** 15 minutes
   - **Impact:** Improved discoverability

3. **Fix `audit.gleam` Error Type**
   - Use `StorageError` instead of custom `AuditError`
   - **Estimated effort:** 30 minutes
   - **Impact:** Consistency across storage layer

4. **Extract Micronutrient Helper**
   - Create `make_micronutrients` helper function
   - **Estimated effort:** 1 hour
   - **Impact:** Removes 4 instances of 70-line code blocks

### LOW Priority (Technical Debt)

5. **Split `foods.gleam` into Submodules**
   - Apply facade pattern like `logs.gleam`
   - **Estimated effort:** 3-4 hours
   - **Impact:** Better maintainability, not critical

---

## 9. Positive Findings

### What's Working Well

✅ **Excellent:**
- Single `StorageError` type used across all modules (except `audit.gleam`)
- Consistent `pog` query building patterns
- Good use of facade pattern in `logs.gleam`
- Proper use of decoders (inline for simple, named for complex)
- All modules have clear documentation comments

✅ **Good:**
- Error formatting centralized in `utils.format_pog_error`
- Consistent parameter typing (`pog.text`, `pog.int`, etc.)
- Proper use of `decode.optional` for nullable fields
- ID type safety (using `id.FdcId`, `id.UserId`, etc.)

---

## 10. Recommended Action Plan

### Week 1: Error Handling Standardization
1. Create new helper functions in `utils.gleam`
2. Refactor `profile.gleam` (already partially using helpers)
3. Refactor `foods.gleam`
4. Run full test suite

### Week 2: Consistency Fixes
1. Move `result_to_storage_error` to `utils.gleam`
2. Fix `audit.gleam` error type
3. Extract micronutrient helper
4. Refactor `logs/*` modules
5. Run full test suite

### Future: Module Organization (Optional)
1. Split `foods.gleam` into submodules
2. Update imports in calling code
3. Run full test suite

---

## 11. Test Coverage Recommendations

After implementing fixes, ensure tests cover:

1. **Error Handling Tests:**
   - Each query type returns correct `StorageError` variants
   - `DatabaseError` wraps `pog.QueryError` correctly
   - `NotFound` returned for empty result sets

2. **Decoder Tests:**
   - All decoders handle NULL values correctly
   - Optional fields decode to `None` when NULL
   - Required fields fail gracefully when NULL

3. **Integration Tests:**
   - Full CRUD cycles for each entity type
   - Cross-module operations (e.g., logs referencing foods)

---

## Conclusion

The storage layer is **well-structured and mostly consistent**, with clear patterns and good separation of concerns. The main issues are:

1. **Inconsistent error handling** - easily fixed with new helper functions
2. **Some code duplication** - micronutrient handling, error transformation
3. **Minor inconsistencies** - `audit.gleam` error type, helper function location

All issues are **non-critical** and can be addressed incrementally without breaking changes. The facade pattern in `logs.gleam` is excellent and could serve as a model for splitting larger modules.

**Overall Grade: B+ (Good, with room for improvement)**

---

## Appendix A: File Statistics

| File | Lines | Functions | Decoders | Error Handling |
|------|-------|-----------|----------|----------------|
| `utils.gleam` | 47 | 1 | 0 | N/A |
| `mod.gleam` | 26 | 0 | 0 | N/A |
| `profile.gleam` | 339 | 8 | 2 inline | Mixed |
| `foods.gleam` | 632 | 15 | 2 inline + 1 named | Mixed |
| `logs.gleam` | 193 | 15 (re-exports) | 0 | N/A (facade) |
| `logs/entries.gleam` | 452 | 6 | 0 | Manual |
| `logs/queries.gleam` | 405 | 6 | 2 inline + 1 named | Manual |
| `logs/summaries.gleam` | 245 | 6 | 1 inline | Helper |
| `audit.gleam` | 357 | 11 | 2 named | Manual |
| `nutrients.gleam` | 3 | 0 | 0 | N/A |
| `migrations.gleam` | 6 | 1 | 0 | N/A |

**Total:** 2,705 lines across 11 files
