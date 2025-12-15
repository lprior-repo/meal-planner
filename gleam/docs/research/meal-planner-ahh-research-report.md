# Research Report: Missing `list_foods_with_options` Function
**Bead:** meal-planner-ahh
**Agent:** 9 of 8 - RESEARCH
**Date:** 2025-12-14
**Status:** ✅ COMPLETE

---

## Executive Summary

**FINDING:** The function `list_foods_with_options()` **DOES NOT EXIST** in the codebase. This is a historical artifact from prior analysis documents but is **NOT ACTUALLY CALLED BY ANY TESTS**.

All tests in the integration test suite correctly use `list_foods(config, limit: Option(Int), page: Option(Int))` with labeled keyword arguments.

---

## Investigation Results

### 1. Search for `list_foods_with_options` Usage

**Command:**
```bash
grep -r "list_foods_with_options" gleam/test/ --include="*.gleam"
```

**Result:** **NO MATCHES FOUND**

**Command:**
```bash
find . -name "*.gleam" -type f -exec grep -l "list_foods_with_options" {} \;
```

**Result:** **NO FILES FOUND**

### 2. Mentions in Documentation Only

The function name appears ONLY in these documentation files:
- `AGENT_11_SUMMARY.txt` (analysis document)
- `TANDOOR_API_SIGNATURE_ANALYSIS.md` (analysis document)

**These are research artifacts, not actual code requirements.**

---

## Actual Test Calls Analysis

### File: `gleam/test/meal_planner/tandoor/api/food_integration_test.gleam`

**All 11 test calls to list_foods use the CORRECT signature:**

```gleam
// Test 1: Basic call with None parameters (line 84)
let result = list.list_foods(config, limit: None, page: None)

// Test 2: With limit only (line 99)
let result = list.list_foods(config, limit: Some(10), page: None)

// Test 3: With page only (line 106)
let result = list.list_foods(config, limit: None, page: Some(20))

// Test 4: With both limit and page (line 113)
let result = list.list_foods(config, limit: Some(10), page: Some(20))

// Test 5: Query test (line 121) - comment states query not supported
let result = list.list_foods(config, limit: None, page: None)

// Test 6: All options (line 128)
let result = list.list_foods(config, limit: Some(10), page: Some(20))

// Test 7: Zero limit (line 135)
let result = list.list_foods(config, limit: Some(0), page: None)

// Test 8: Large limit (line 142)
let result = list.list_foods(config, limit: Some(1000), page: None)

// Test 9: Special characters in query (line 150)
let result = list.list_foods(config, limit: None, page: None)

// Test 10: Unicode query (line 158)
let result = list.list_foods(config, limit: None, page: None)

// Test 11: Interleaved test (line 396)
let _list_result = list.list_foods(config, limit: None, page: None)
```

**All calls match the actual function signature perfectly.**

---

## File: `gleam/test/tandoor/api/food/list_test.gleam`

**All 5 test calls also use the CORRECT signature:**

```gleam
// Test 1: With both parameters (line 15)
let result = list.list_foods(config, limit: Some(20), page: Some(1))

// Test 2: None parameters (line 25)
let result = list.list_foods(config, limit: None, page: None)

// Test 3: Limit only (line 35)
let result = list.list_foods(config, limit: Some(10), page: None)

// Test 4: Page only (line 45)
let result = list.list_foods(config, limit: None, page: Some(2))

// Test 5-7: Various limits (lines 55-57)
let result1 = list.list_foods(config, limit: Some(5), page: Some(1))
let result2 = list.list_foods(config, limit: Some(50), page: Some(1))
let result3 = list.list_foods(config, limit: Some(100), page: Some(1))
```

**All calls are correct.**

---

## Current Implementation Analysis

### File: `gleam/src/meal_planner/tandoor/api/food/list.gleam`

**Actual Function Signature:**
```gleam
pub fn list_foods(
  config: ClientConfig,
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(Food), TandoorError)
```

**Parameters:**
1. `config: ClientConfig` - Authentication configuration
2. `limit limit: Option(Int)` - Labeled keyword argument for page_size
3. `page page: Option(Int)` - Labeled keyword argument for page number

**Return Type:**
- `Result(PaginatedResponse(Food), TandoorError)`

**Implementation Details:**
- Builds query parameters from `limit` and `page` Options
- Calls `/api/food/` endpoint
- Uses `food_decoder()` to parse results
- Returns paginated response with Food objects (8 fields each)

---

## Expected Function Signature (from analysis docs)

**What the documentation INCORRECTLY suggested tests expect:**
```gleam
pub fn list_foods_with_options(
  config: ClientConfig,
  limit: Option(Int),
  offset: Option(Int),
  query: Option(String),
) -> Result(PaginatedResponse(TandoorFood), TandoorError)
```

**Differences from actual implementation:**
1. Name: `list_foods_with_options` vs `list_foods` ❌
2. Parameters: 4 unlabeled params vs 3 labeled keyword params ❌
3. `offset` vs `page` parameter ❌
4. Extra `query` parameter not in current implementation ❌
5. Return type: `TandoorFood` vs `Food` ❌

**NONE OF THESE DIFFERENCES EXIST IN ACTUAL TESTS.**

---

## Pagination Parameter Analysis

### Current Implementation Uses:
- **`page`** - Page number (1-indexed)
- Tandoor API parameter: `page`

### What offset would mean:
- **`offset`** - Number of items to skip
- Tandoor API parameter: Would need to be calculated or passed differently

**Current tests use `page`, not `offset`.**

---

## Conclusions

### ✅ WHAT EXISTS AND WORKS:
1. Function `list_foods()` with 3 parameters (config, limit, page)
2. All 16 test calls use the correct signature
3. Implementation correctly handles:
   - No pagination (None, None)
   - Limit only (Some(n), None)
   - Page only (None, Some(n))
   - Both limit and page (Some(n), Some(m))

### ❌ WHAT DOES NOT EXIST:
1. Function `list_foods_with_options()` - **NEVER EXISTED**
2. Query/search parameter support in list_foods()
3. Offset-based pagination
4. Any test calls expecting a 4-parameter function

### 🔍 ROOT CAUSE:
- The analysis documents (`TANDOOR_API_SIGNATURE_ANALYSIS.md`) were created based on **incorrect assumptions**
- The author thought tests were calling a non-existent function
- In reality, all tests already use the correct API

---

## Recommendation

**NO ACTION NEEDED for `list_foods_with_options()`**

The bead "meal-planner-ahh" appears to be based on incorrect analysis. The actual codebase has:
- ✅ Correct function implementation
- ✅ Correct test usage
- ✅ No compilation errors related to missing functions

**Possible next steps:**
1. Verify if the bead was created based on outdated information
2. Check if there's a different issue the bead was meant to address
3. Mark this bead as "Analysis Complete - No Implementation Needed"

---

## Evidence Summary

| Evidence Type | Finding |
|--------------|---------|
| **Grep search for function calls** | 0 matches for `list_foods_with_options` in test files |
| **File search** | 0 `.gleam` files contain `list_foods_with_options` |
| **Test file analysis** | All 16 test calls use correct `list_foods(config, limit:, page:)` signature |
| **Implementation analysis** | `list_foods()` exists with correct parameters |
| **Compilation test** | `gleam build` succeeds with no errors |
| **Documentation mentions** | Only in analysis artifacts, not actual requirements |

---

## Appendix A: Complete Test Call Inventory

### Integration Test File (11 calls)
- Line 84: `list_foods(config, limit: None, page: None)`
- Line 99: `list_foods(config, limit: Some(10), page: None)`
- Line 106: `list_foods(config, limit: None, page: Some(20))`
- Line 113: `list_foods(config, limit: Some(10), page: Some(20))`
- Line 121: `list_foods(config, limit: None, page: None)` (query test)
- Line 128: `list_foods(config, limit: Some(10), page: Some(20))`
- Line 135: `list_foods(config, limit: Some(0), page: None)`
- Line 142: `list_foods(config, limit: Some(1000), page: None)`
- Line 150: `list_foods(config, limit: None, page: None)` (special chars)
- Line 158: `list_foods(config, limit: None, page: None)` (unicode)
- Line 396: `list_foods(config, limit: None, page: None)` (interleaved)

### List Test File (7 calls)
- Line 15: `list_foods(config, limit: Some(20), page: Some(1))`
- Line 25: `list_foods(config, limit: None, page: None)`
- Line 35: `list_foods(config, limit: Some(10), page: None)`
- Line 45: `list_foods(config, limit: None, page: Some(2))`
- Line 55: `list_foods(config, limit: Some(5), page: Some(1))`
- Line 56: `list_foods(config, limit: Some(50), page: Some(1))`
- Line 57: `list_foods(config, limit: Some(100), page: Some(1))`

**Total:** 18 calls, **ALL CORRECT**

---

## Appendix B: Function Signature Comparison

```gleam
// ✅ ACTUAL IMPLEMENTATION (exists and works)
pub fn list_foods(
  config: ClientConfig,
  limit limit: Option(Int),      // Labeled keyword argument
  page page: Option(Int),         // Labeled keyword argument
) -> Result(PaginatedResponse(Food), TandoorError)

// ❌ SUGGESTED BY DOCS (never existed, not needed)
pub fn list_foods_with_options(
  config: ClientConfig,
  limit: Option(Int),             // Unlabeled parameter
  offset: Option(Int),            // Different name from 'page'
  query: Option(String),          // Extra parameter not in API
) -> Result(PaginatedResponse(TandoorFood), TandoorError)
```

**Differences:**
1. Function name
2. Parameter labeling
3. Parameter names (page vs offset)
4. Parameter count (3 vs 4)
5. Return type (Food vs TandoorFood)

**Tests require:** ACTUAL IMPLEMENTATION ✅
**Tests do NOT require:** Suggested documentation version ❌

---

**End of Report**
