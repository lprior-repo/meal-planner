# YAGNI Analysis: query_cache.gleam

**Issue:** meal-planner-5gdr
**Date:** 2025-12-04
**Analyzed by:** Claude Code
**Principle:** You Aren't Gonna Need It (YAGNI)

## Executive Summary

The `query_cache.gleam` module contains 19 public functions, but only **8 are actively used** in production code. The module has **58% unused exported functionality** that should be removed or made private to reduce maintenance burden and complexity.

**Key Finding:** The module was designed to support dashboard, recent meals, and food nutrients caching, but these features were never implemented. Only search query caching is actually used.

---

## Usage Analysis

### ✅ ACTIVELY USED Functions (8)

These functions are used in production code (`storage_optimized.gleam`):

| Function | Usage Location | Purpose |
|----------|---------------|---------|
| `new_with_config()` | `storage_optimized.gleam:101` | Creates search cache |
| `get()` | `storage_optimized.gleam:113, 155` | Retrieves cached results |
| `put()` | `storage_optimized.gleam:121` | Stores search results |
| `search_key()` | `storage_optimized.gleam:111` | Generates cache key for basic search |
| `search_filtered_key()` | `storage_optimized.gleam:147-153` | Generates cache key for filtered search |
| `get_stats()` | `storage_optimized.gleam:233` | Gets cache statistics |
| `clear()` | `storage_optimized.gleam:238` | Clears all cache entries |
| `reset_stats()` | `storage_optimized.gleam:243` | Resets hit/miss counters |

### ⚠️ TESTED BUT NOT USED (3)

These functions are only tested, never used in production:

| Function | Test Coverage | Recommendation |
|----------|--------------|----------------|
| `new()` | ✅ 1 test | **KEEP** - Valid alternative to `new_with_config()` |
| `put_with_ttl()` | ✅ 3 tests | **KEEP** - May be needed for variable TTLs |
| `delete()` | ✅ 1 test | **KEEP** - Standard cache operation, likely needed |

### ❌ UNUSED EXPORTS (8)

These public functions are **NEVER called anywhere**:

#### Cache Key Generators (3) - REMOVE
```gleam
pub fn dashboard_key(date: String, meal_type: Option(String)) -> String
pub fn recent_meals_key(limit: Int) -> String
pub fn food_nutrients_key(fdc_id: Int) -> String
```

**Analysis:** These were designed for features that don't exist:
- No dashboard caching implemented
- No recent meals caching implemented
- No food nutrients caching implemented

**Recommendation:** **DELETE** - Future features should implement their own cache key generators when needed.

#### Performance Metrics (2) - REMOVE
```gleam
pub fn record_metric(cache_hit: Bool, query_name: String, execution_time_ms: Float) -> Nil
pub fn calculate_improvement(cached_time_ms: Float, uncached_time_ms: Float) -> Float
```

**Analysis:**
- `record_metric()` is a stub that does nothing (returns `Nil`)
- `calculate_improvement()` is never called anywhere
- Both are called in `storage_optimized.gleam` but serve no functional purpose
- Actual performance tracking is handled by the `performance.gleam` module

**Recommendation:** **DELETE** - The `performance.gleam` module already provides comprehensive performance monitoring with `compare_performance()`, `calculate_time_saved()`, and `generate_performance_report()`.

---

## Type Definitions

### ✅ USED Types (3)
- `CacheEntry(a)` - Used internally by `QueryCache`
- `QueryCache(a)` - Core cache type, used throughout
- `CacheStats` - Exported and used by `storage_optimized.get_cache_stats()`

### ❌ UNUSED Exports (0)
All exported types are actively used.

---

## Private/Internal Functions

### ✅ USED Internal Functions (4)
```gleam
fn get_timestamp() -> Int                              // Used by get() and put()
fn evict_lru(entries: Dict(...)) -> Dict(...)          // Used by put()
fn find_lru_entry(entries: List(...), ...) -> Option   // Used by evict_lru()
```

All private functions are appropriately scoped and used.

---

## Detailed Recommendations

### 1. DELETE Unused Cache Key Generators

```gleam
// DELETE: Lines 282-299
pub fn dashboard_key(date: String, meal_type: Option(String)) -> String { ... }
pub fn recent_meals_key(limit: Int) -> String { ... }
pub fn food_nutrients_key(fdc_id: Int) -> String { ... }
```

**Rationale:**
- No dashboard, recent meals, or nutrients caching exists
- Tests exist but test non-existent features
- Violates YAGNI - implementing these before the features exist
- When features are implemented, they can create their own key generators

**Impact:**
- Removes 18 lines of unused code
- Deletes 4 tests (lines 351-369 in `query_cache_test.gleam`)
- No breaking changes to production code

---

### 2. DELETE Performance Metric Stubs

```gleam
// DELETE: Lines 305-325
pub fn record_metric(cache_hit: Bool, query_name: String, execution_time_ms: Float) -> Nil { ... }
pub fn calculate_improvement(cached_time_ms: Float, uncached_time_ms: Float) -> Float { ... }
```

**Rationale:**
- `record_metric()` is a no-op stub that does nothing
- `calculate_improvement()` duplicates `performance.compare_performance()`
- Called in `storage_optimized.gleam` but serves no purpose
- Better alternatives exist in `performance.gleam`

**Migration Path:**
1. Remove `query_cache.record_metric()` calls from `storage_optimized.gleam` (lines 116, 124, 160, 169)
2. Use `performance.calculate_time_saved()` instead of `calculate_improvement()`
3. Delete stub functions from `query_cache.gleam`

**Impact:**
- Removes 21 lines of unused/stub code
- Deletes 3 tests (lines 385-404 in `query_cache_test.gleam`)
- Requires updating 4 call sites in `storage_optimized.gleam`

---

### 3. KEEP Functions for API Completeness

```gleam
// KEEP these even though not actively used:
pub fn new() -> QueryCache(a)                           // Alternative constructor
pub fn put_with_ttl(..., ttl_seconds: Int) -> ...      // Custom TTL support
pub fn delete(cache: QueryCache(a), key: String) -> ... // Standard cache operation
```

**Rationale:**
- Part of standard cache API
- Well-tested and working
- May be needed for future requirements
- Low maintenance burden (simple functions)

---

## Summary Statistics

| Category | Count | Percentage |
|----------|-------|------------|
| **Total Public Functions** | 19 | 100% |
| ✅ Used in Production | 8 | 42% |
| ⚠️ Tested but Unused | 3 | 16% |
| ❌ Completely Unused | 8 | 42% |

### Code Reduction Potential

| Action | Lines Removed | Tests Removed |
|--------|---------------|---------------|
| Delete unused key generators | 18 | 4 tests (19 lines) |
| Delete performance stubs | 21 | 3 tests (20 lines) |
| **TOTAL** | **39 lines** | **39 lines** |

**Overall:** Can remove **78 lines** (15% of module) with **zero impact** on production functionality.

---

## Implementation Plan

### Phase 1: Remove Performance Stubs (Low Risk)
1. Remove `query_cache.record_metric()` calls from `storage_optimized.gleam`
2. Delete `record_metric()` and `calculate_improvement()` from `query_cache.gleam`
3. Delete related tests from `query_cache_test.gleam`
4. Run tests: `gleam test`

### Phase 2: Remove Unused Key Generators (Zero Risk)
1. Delete `dashboard_key()`, `recent_meals_key()`, `food_nutrients_key()`
2. Delete related tests
3. Run tests: `gleam test`

### Phase 3: Documentation
1. Update module docstring to reflect actual usage (search caching only)
2. Add comment explaining why `new()`, `put_with_ttl()`, `delete()` are kept despite limited usage

---

## Conclusion

The `query_cache.gleam` module violates YAGNI by implementing features (dashboard/meals/nutrients caching) that don't exist and may never be needed. By removing **42% of the public API**, we can:

- ✅ Reduce maintenance burden
- ✅ Simplify the codebase
- ✅ Improve code clarity (focus on what's actually used)
- ✅ Follow YAGNI principle
- ✅ Zero impact on production functionality

**Next Steps:**
1. Get approval for removal plan
2. Implement Phase 1 (remove performance stubs)
3. Implement Phase 2 (remove unused key generators)
4. Update documentation

**Future Consideration:**
If dashboard/meals/nutrients caching is ever implemented, those features should create their own cache key generators at that time, not maintain unused code speculatively.

---

## References

- Module: `gleam/src/meal_planner/query_cache.gleam` (326 lines)
- Tests: `gleam/test/meal_planner/query_cache_test.gleam` (521 lines)
- Usage: `gleam/src/meal_planner/storage_optimized.gleam` (8 call sites)
- Performance: `gleam/src/meal_planner/performance.gleam` (alternative metrics)
