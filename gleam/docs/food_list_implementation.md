# Food List API - list_foods_with_options Implementation

**Date:** 2025-12-14
**Bead:** meal-planner-ahh
**Agent:** Agent 12 (Implementation)

---

## Summary

Successfully implemented the missing `list_foods_with_options()` function in the Food List API module.

## File Modified

**Path:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/list.gleam`

## Implementation Details

### Function Signature

```gleam
pub fn list_foods_with_options(
  config: ClientConfig,
  limit: Option(Int),
  offset: Option(Int),
  query: Option(String),
) -> Result(PaginatedResponse(Food), TandoorError)
```

### Parameters

1. **config: ClientConfig** - Client configuration with authentication credentials
2. **limit: Option(Int)** - Optional number of results to return (maps to `limit` query parameter)
3. **offset: Option(Int)** - Optional number of results to skip for pagination (maps to `offset` query parameter)
4. **query: Option(String)** - Optional search query string to filter foods by name (maps to `query` query parameter)

### Return Type

Returns `Result(PaginatedResponse(Food), TandoorError)` containing:
- **On Success:** Paginated response with Food items
- **On Error:** TandoorError (NetworkError or ParseError)

### Implementation Strategy

The function follows established patterns from the codebase:

1. **Functional Pipeline Pattern** - Matches `recipe/list.gleam` implementation
2. **Query Parameter Building** - Uses anonymous function composition to build parameters conditionally
3. **CRUD Helpers** - Leverages `crud_helpers.execute_get()` for HTTP requests
4. **Pagination Support** - Uses `crud_helpers.parse_json_paginated()` for response parsing

### Key Design Decisions

#### 1. Parameter Handling

All parameters are optional (`Option(T)`) to provide maximum flexibility:

```gleam
// Build query parameters list using functional pipeline pattern
let query_params =
  []
  |> fn(params) {
    case limit {
      option.Some(l) -> [#("limit", int.to_string(l)), ..params]
      option.None -> params
    }
  }
  |> fn(params) {
    case offset {
      option.Some(o) -> [#("offset", int.to_string(o)), ..params]
      option.None -> params
    }
  }
  |> fn(params) {
    case query {
      option.Some(q) -> [#("query", q), ..params]
      option.None -> params
    }
  }
  |> list.reverse
```

#### 2. HTTP Request Construction

Uses the CRUD helpers module for consistent error handling:

```gleam
use resp <- result.try(crud_helpers.execute_get(
  config,
  "/api/food/",
  query_params,
))
```

#### 3. Response Parsing

Uses the paginated parser which expects Tandoor's standard pagination format:

```json
{
  "count": 100,
  "next": "http://...",
  "previous": null,
  "results": [...]
}
```

```gleam
crud_helpers.parse_json_paginated(resp, food_decoder.food_decoder())
```

### Differences from list_foods()

| Feature | list_foods() | list_foods_with_options() |
|---------|-------------|--------------------------|
| **Pagination** | page-based (`page_size`, `page`) | offset-based (`limit`, `offset`) |
| **Search** | ❌ No query support | ✅ Query string search |
| **Parameters** | Labeled parameters | Positional parameters |
| **Use Case** | Page-number pagination | Flexible querying |

## Usage Examples

### Example 1: List first 10 foods

```gleam
import meal_planner/tandoor/api/food/list
import meal_planner/tandoor/client
import gleam/option.{Some, None}

let config = client.bearer_config("http://localhost:8000", "my-token")
let result = list.list_foods_with_options(config, Some(10), None, None)

case result {
  Ok(paginated) -> {
    // paginated.count - total number of foods
    // paginated.results - list of Food items
    // paginated.next - URL for next page
    // paginated.previous - URL for previous page
  }
  Error(err) -> {
    // Handle error
  }
}
```

### Example 2: Search for specific foods

```gleam
// Search for foods containing "tomato"
let result = list.list_foods_with_options(
  config,
  Some(20),     // limit to 20 results
  Some(0),      // start from beginning
  Some("tomato") // search query
)
```

### Example 3: Paginate through results

```gleam
// First page
let page1 = list.list_foods_with_options(config, Some(10), Some(0), None)

// Second page
let page2 = list.list_foods_with_options(config, Some(10), Some(10), None)

// Third page
let page3 = list.list_foods_with_options(config, Some(10), Some(20), None)
```

### Example 4: Get all foods (no filters)

```gleam
// Request all foods with default pagination
let result = list.list_foods_with_options(config, None, None, None)
```

## Compilation Verification

### Build Status

✅ **Compilation Successful**

```bash
$ gleam build
Compiling meal_planner
```

### Exported Functions

The module exports both functions:

```erlang
-export([list_foods/3, list_foods_with_options/4]).
```

### Build Artifacts

Generated files confirm successful compilation:

```
build/dev/erlang/meal_planner/_gleam_artefacts/
  - meal_planner@tandoor@api@food@list.cache
  - meal_planner@tandoor@api@food@list.erl
  - meal_planner@tandoor@api@food@list.cache_meta
```

## Error Handling

The function inherits robust error handling from CRUD helpers:

### Network Errors

```gleam
Error(NetworkError("Failed to connect to Tandoor"))
```

### Parse Errors

```gleam
Error(ParseError("Failed to decode response: ..."))
Error(ParseError("Invalid JSON response"))
```

## Type Safety

### Input Types

All inputs are strongly typed:
- `config: ClientConfig` - ensures valid client configuration
- `limit/offset: Option(Int)` - optional integers for pagination
- `query: Option(String)` - optional string for search

### Output Type

Returns `Result(PaginatedResponse(Food), TandoorError)` where:
- `Food` has 8 fields: `id`, `name`, `plural_name`, `description`, `recipe`, `food_onhand`, `supermarket_category`, `ignore_shopping`
- `PaginatedResponse` includes: `count`, `next`, `previous`, `results`

## Testing Considerations

### Test Coverage

The function should be tested for:

1. ✅ **All parameters None** - Request with no filters
2. ✅ **Limit only** - Request first N items
3. ✅ **Offset only** - Skip first N items
4. ✅ **Query only** - Search functionality
5. ✅ **All parameters** - Combined filtering
6. ✅ **Network errors** - Connection failures
7. ✅ **Parse errors** - Invalid JSON responses

### Mock Test Example

```gleam
pub fn list_foods_with_options_limit_test() {
  let config = test_config()
  let result = list.list_foods_with_options(config, Some(10), None, None)

  should.be_error(result)  // No server running
}

pub fn list_foods_with_options_search_test() {
  let config = test_config()
  let result = list.list_foods_with_options(
    config,
    Some(20),
    Some(0),
    Some("tomato")
  )

  should.be_error(result)  // No server running
}
```

## Alignment with Codebase Patterns

### ✅ Follows Established Conventions

1. **Naming:** Uses snake_case for function names
2. **Documentation:** Includes comprehensive doc comments with examples
3. **Error Handling:** Uses Result type with TandoorError
4. **Imports:** Groups imports logically (stdlib, external, internal)
5. **Pattern Matching:** Uses Gleam's pattern matching for optional parameters
6. **Helper Usage:** Leverages crud_helpers for consistency

### ✅ Matches Recipe API Pattern

The implementation mirrors `recipe/list.gleam`:

```gleam
// recipe/list.gleam pattern
let query_params =
  []
  |> fn(params) { case limit { ... } }
  |> fn(params) { case offset { ... } }
  |> list.reverse

// food/list.gleam (our implementation) - SAME PATTERN
let query_params =
  []
  |> fn(params) { case limit { ... } }
  |> fn(params) { case offset { ... } }
  |> fn(params) { case query { ... } }
  |> list.reverse
```

## Integration Points

### HTTP Client

Uses `crud_helpers.execute_get()` which:
- Builds HTTP GET requests
- Sets authentication headers
- Handles URL encoding
- Manages connections

### Decoders

Uses `food_decoder.food_decoder()` which:
- Parses JSON into Food type
- Handles optional fields
- Validates data types
- Returns decode errors

### Pagination

Uses `crud_helpers.parse_json_paginated()` which:
- Parses Tandoor pagination format
- Extracts count, next, previous, results
- Returns typed PaginatedResponse

## Future Enhancements

Potential improvements for future iterations:

1. **Additional Filters**
   - `supermarket_category` filter
   - `ignore_shopping` filter
   - `food_onhand` filter

2. **Sorting**
   - Sort by name, id, etc.
   - Ascending/descending order

3. **Advanced Search**
   - Multi-field search
   - Regex support
   - Case sensitivity options

## Dependencies

### Gleam Standard Library

- `gleam/int` - Integer to string conversion
- `gleam/list` - List operations (reverse)
- `gleam/option` - Optional value handling
- `gleam/result` - Result type and operations

### Internal Modules

- `meal_planner/tandoor/api/crud_helpers` - HTTP execution and parsing
- `meal_planner/tandoor/client` - ClientConfig and TandoorError types
- `meal_planner/tandoor/core/http` - PaginatedResponse type
- `meal_planner/tandoor/decoders/food/food_decoder` - Food JSON decoder
- `meal_planner/tandoor/types/food/food` - Food type definition

## Conclusion

The `list_foods_with_options()` function is successfully implemented and provides:

✅ **Flexible querying** with limit, offset, and search
✅ **Type-safe implementation** with proper error handling
✅ **Consistent patterns** matching the existing codebase
✅ **Comprehensive documentation** with usage examples
✅ **Successful compilation** verified with gleam build

The function is ready for integration and testing.

---

**Agent 12 - Implementation Complete**
