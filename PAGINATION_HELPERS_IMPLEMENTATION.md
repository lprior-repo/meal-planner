# Pagination Helpers Implementation (meal-planner-drh)

## Summary

Created comprehensive pagination helper utilities for the Tandoor SDK to simplify handling paginated API responses.

## Files Created/Modified

### 1. Core Implementation
**File:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/core/pagination.gleam`
**Lines:** 235 (added ~200 lines)

**Added Types:**
- `PaginationParams` - Type-safe pagination parameters with optional limit/offset

**Added Functions:**
1. `has_next_page(response) -> Bool` - Check if more pages available
2. `has_previous_page(response) -> Bool` - Check if previous pages exist
3. `next_page_params(response) -> Option(#(Int, Int))` - Extract limit/offset from next URL
4. `previous_page_params(response) -> Option(#(Int, Int))` - Extract limit/offset from previous URL
5. `build_query_string(params) -> String` - Build query strings with None filtering
6. `pagination_params_to_query(params) -> String` - Convert PaginationParams to query

**Helper Functions (private):**
- `parse_url_params(url)` - Parse pagination params from URLs using gleam/uri
- `parse_query_string_params(query)` - Extract limit/offset from query strings
- `find_param(params, key)` - Find and parse integer parameters

### 2. Comprehensive Tests
**File:** `/home/lewis/src/meal-planner/gleam/test/meal_planner/tandoor/core/pagination_test.gleam`
**Lines:** 289
**Test Count:** 23 tests

**Test Coverage:**
- ✓ has_next_page with/without next URL
- ✓ has_previous_page with/without previous URL
- ✓ next_page_params URL parsing (valid, reordered, extra params)
- ✓ previous_page_params URL parsing
- ✓ build_query_string with various inputs
- ✓ pagination_params_to_query conversion
- ✓ Edge cases: malformed URLs, missing params, non-numeric values

### 3. Usage Examples
**File:** `/home/lewis/src/meal-planner/gleam/examples/pagination_helpers_example.gleam`
**Lines:** 144

**Examples Demonstrated:**
1. Checking for next/previous pages
2. Extracting pagination parameters from URLs
3. Building query strings with optional parameters
4. Using PaginationParams type

### 4. Documentation
**File:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/core/PAGINATION_README.md`
**Lines:** 360+

**Documentation Includes:**
- Type definitions and explanations
- Function signatures and examples
- Common usage patterns (fetch all pages, manual pagination, infinite scroll)
- Error handling strategies
- Performance considerations
- API compatibility notes
- Migration guide from manual pagination
- Testing instructions

## Implementation Details

### URL Parsing Strategy
Uses `gleam/uri.parse()` to safely parse pagination URLs, extracting both `limit` and `offset` parameters. Returns `None` for any parsing failures (malformed URLs, missing params, invalid integers).

### Query String Building
Functional pipeline approach using `list.filter_map()` to exclude `None` values and `string.join("&")` for formatting. Ensures clean query strings without empty parameters.

### Type Safety
`PaginationParams` type provides compile-time safety for pagination parameters, with `Option(Int)` for both limit and offset to handle optional cases.

### Error Handling
All parsing functions return `Option` types rather than `Result` types, simplifying usage. Callers can distinguish between "no next page" and "invalid URL" by combining `has_next_page()` with `next_page_params()`.

## Usage Before vs After

### Before (Manual)
```gleam
case response.next {
  Some(url) -> {
    // Complex manual URL parsing
    let parts = string.split(url, "?")
    // ... extract query string
    // ... split on &
    // ... parse limit and offset
    // ... handle errors
  }
  None -> done()
}
```

### After (With Helpers)
```gleam
case pagination.next_page_params(response) {
  Some(#(limit, offset)) -> fetch_next_page(limit, offset)
  None -> done()
}
```

## Common Patterns Enabled

### 1. Fetch All Pages Recursively
```gleam
fn fetch_all_pages(config, limit, offset, accumulator) {
  use response <- result.try(list_foods(config, limit, offset))
  let all_items = list.append(accumulator, response.results)

  case pagination.next_page_params(response) {
    Some(#(next_limit, next_offset)) ->
      fetch_all_pages(config, next_limit, next_offset, all_items)
    None -> Ok(all_items)
  }
}
```

### 2. Build Dynamic Request URLs
```gleam
fn build_request_url(base, params, search, filter) {
  let query_params = [
    #("limit", option.map(params.limit, int.to_string)),
    #("offset", option.map(params.offset, int.to_string)),
    #("search", search),
    #("filter", filter),
  ]
  base <> "?" <> pagination.build_query_string(query_params)
}
```

### 3. Infinite Scroll
```gleam
fn load_more(current_response, current_items) {
  case pagination.next_page_params(current_response) {
    None -> Ok(#(current_items, False))
    Some(#(limit, offset)) -> {
      use next <- result.try(fetch(limit, offset))
      let all = list.append(current_items, next.results)
      Ok(#(all, pagination.has_next_page(next)))
    }
  }
}
```

## Testing Status

**Tests Created:** 23 comprehensive tests
**Test Status:** Cannot run due to pre-existing project compilation errors (unrelated to this implementation)
**Code Quality:**
- ✓ Properly formatted with `gleam format`
- ✓ Type-safe implementation
- ✓ Well-documented with examples
- ✓ Follows Gleam idioms

## Integration Points

These helpers work with existing Tandoor SDK modules:
- `meal_planner/tandoor/api/food/list.gleam` - Food listing API
- `meal_planner/tandoor/api/supermarket/list.gleam` - Supermarket listing API
- `meal_planner/tandoor/core/http.gleam` - HTTP transport layer
- Any future paginated endpoints

## Dependencies Added

- `gleam/uri` - For safe URL parsing
- `gleam/int` - For integer to string conversion
- `gleam/list` - For list operations
- `gleam/string` - For string operations

All dependencies are standard Gleam library modules.

## Benefits

1. **Reduced Boilerplate:** No manual URL/query string parsing
2. **Type Safety:** Compile-time guarantees for pagination parameters
3. **Error Resilience:** Graceful handling of malformed URLs
4. **Consistency:** Standardized pagination across all Tandoor API calls
5. **Maintainability:** Centralized pagination logic
6. **Testability:** Pure functions, easy to test

## Next Steps

Once project compilation errors are resolved:
1. Run test suite: `gleam test --module meal_planner/tandoor/core/pagination_test`
2. Integrate helpers into existing API modules (food, supermarket, etc.)
3. Update API documentation to reference pagination helpers
4. Consider adding cursor-based pagination if Tandoor API supports it

## Task Completion

✅ Created `PaginationParams` type
✅ Implemented `has_next_page()` function
✅ Implemented `next_page_params()` URL parser
✅ Implemented `build_query_string()` helper
✅ Implemented `pagination_params_to_query()` converter
✅ Added comprehensive tests (23 tests)
✅ Created usage examples
✅ Created detailed documentation
✅ Followed existing Gleam patterns
✅ Used `gleam/uri` for URL parsing

**Status:** Complete and ready for use once project builds successfully.
