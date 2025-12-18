# Tandoor SDK Pagination Helpers

Comprehensive pagination utilities for handling Tandoor API paginated responses.

## Overview

The Tandoor API returns paginated responses with `count`, `next`, `previous`, and `results` fields. This module provides helper functions to:

1. Check if more pages are available
2. Extract pagination parameters from URLs
3. Build query strings for requests
4. Work with pagination parameters in a type-safe way

## Types

### PaginatedResponse(a)

Generic type representing a paginated API response:

```gleam
pub type PaginatedResponse(a) {
  PaginatedResponse(
    count: Int,           // Total number of items
    next: Option(String), // URL to next page (if available)
    previous: Option(String), // URL to previous page (if available)
    results: List(a),     // Items for this page
  )
}
```

### PaginationParams

Type for building pagination requests:

```gleam
pub type PaginationParams {
  PaginationParams(
    limit: Option(Int),   // Number of items per page
    offset: Option(Int),  // Starting position (0-indexed)
  )
}
```

## Helper Functions

### 1. has_next_page

Check if there is a next page available.

```gleam
pub fn has_next_page(response: PaginatedResponse(a)) -> Bool
```

**Example:**
```gleam
let response = fetch_foods(limit: 10, offset: 0)
case has_next_page(response) {
  True -> fetch_next_page()
  False -> done_paginating()
}
```

### 2. has_previous_page

Check if there is a previous page available.

```gleam
pub fn has_previous_page(response: PaginatedResponse(a)) -> Bool
```

**Example:**
```gleam
case has_previous_page(response) {
  True -> show_previous_button()
  False -> hide_previous_button()
}
```

### 3. next_page_params

Extract limit and offset from the next page URL.

```gleam
pub fn next_page_params(response: PaginatedResponse(a)) -> Option(#(Int, Int))
```

**Returns:** `Some(#(limit, offset))` or `None`

**Example:**
```gleam
case next_page_params(response) {
  Some(#(limit, offset)) -> {
    // Fetch next page with extracted params
    fetch_foods(limit: limit, offset: offset)
  }
  None -> {
    // No more pages
    finish_loading()
  }
}
```

### 4. previous_page_params

Extract limit and offset from the previous page URL.

```gleam
pub fn previous_page_params(response: PaginatedResponse(a)) -> Option(#(Int, Int))
```

**Example:**
```gleam
case previous_page_params(response) {
  Some(#(limit, offset)) -> fetch_foods(limit: limit, offset: offset)
  None -> // Already at first page
}
```

### 5. build_query_string

Build a query string from key-value pairs, filtering out None values.

```gleam
pub fn build_query_string(params: List(#(String, Option(String)))) -> String
```

**Example:**
```gleam
let query = build_query_string([
  #("limit", Some("10")),
  #("offset", Some("20")),
  #("filter", None),  // This will be excluded
])
// Returns: "limit=10&offset=20"
```

### 6. pagination_params_to_query

Convert PaginationParams to a query string.

```gleam
pub fn pagination_params_to_query(params: PaginationParams) -> String
```

**Example:**
```gleam
let params = PaginationParams(limit: Some(25), offset: Some(50))
let query = pagination_params_to_query(params)
// Returns: "limit=25&offset=50"

let url = base_url <> "?" <> query
```

## Common Usage Patterns

### Pattern 1: Fetch All Pages

```gleam
import gleam/list
import meal_planner/tandoor/core/pagination

pub fn fetch_all_foods(config: ClientConfig) -> Result(List(TandoorFood), Error) {
  fetch_all_pages(config, limit: 50, offset: 0, accumulator: [])
}

fn fetch_all_pages(
  config: ClientConfig,
  limit: Int,
  offset: Int,
  accumulator: List(TandoorFood),
) -> Result(List(TandoorFood), Error) {
  use response <- result.try(
    list_foods(config, limit: Some(limit), offset: Some(offset))
  )

  let all_items = list.append(accumulator, response.results)

  case pagination.next_page_params(response) {
    Some(#(next_limit, next_offset)) -> {
      // Fetch next page recursively
      fetch_all_pages(config, next_limit, next_offset, all_items)
    }
    None -> {
      // No more pages, return all items
      Ok(all_items)
    }
  }
}
```

### Pattern 2: Manual Pagination with User Control

```gleam
pub type PaginationState {
  PaginationState(
    current_page: Int,
    limit: Int,
    total_count: Int,
    has_next: Bool,
    has_prev: Bool,
  )
}

pub fn get_pagination_state(
  response: PaginatedResponse(a),
  current_page: Int,
  limit: Int,
) -> PaginationState {
  PaginationState(
    current_page: current_page,
    limit: limit,
    total_count: response.count,
    has_next: pagination.has_next_page(response),
    has_prev: pagination.has_previous_page(response),
  )
}
```

### Pattern 3: Build Dynamic Requests

```gleam
pub fn build_food_request_url(
  base_url: String,
  params: PaginationParams,
  search: Option(String),
  filter: Option(String),
) -> String {
  let query_params = [
    #("limit", option.map(params.limit, int.to_string)),
    #("offset", option.map(params.offset, int.to_string)),
    #("search", search),
    #("filter", filter),
  ]

  let query = pagination.build_query_string(query_params)

  case query {
    "" -> base_url
    _ -> base_url <> "?" <> query
  }
}
```

### Pattern 4: Infinite Scroll

```gleam
pub fn load_more_items(
  current_response: PaginatedResponse(a),
  current_items: List(a),
) -> Result(#(List(a), Bool), Error) {
  case pagination.next_page_params(current_response) {
    None -> {
      // No more items to load
      Ok(#(current_items, False))
    }
    Some(#(limit, offset)) -> {
      use next_response <- result.try(fetch_items(limit, offset))
      let all_items = list.append(current_items, next_response.results)
      let has_more = pagination.has_next_page(next_response)
      Ok(#(all_items, has_more))
    }
  }
}
```

## Error Handling

All URL parsing functions return `Option` types rather than `Result` types:

- `next_page_params` returns `None` if:
  - No next URL exists
  - URL is malformed
  - Parameters are missing or invalid
  - Parameters cannot be parsed as integers

- `previous_page_params` follows the same behavior

**Recommended approach:**

```gleam
case next_page_params(response) {
  Some(#(limit, offset)) -> {
    // Valid params - proceed with fetch
    fetch_next_page(limit, offset)
  }
  None -> {
    // Either no next page or invalid URL
    // Check has_next_page to distinguish
    case has_next_page(response) {
      True -> {
        // URL exists but is malformed - log error
        log_error("Invalid pagination URL")
        Ok([])
      }
      False -> {
        // Normal end of pagination
        Ok([])
      }
    }
  }
}
```

## Testing

Comprehensive tests are available in `test/meal_planner/tandoor/core/pagination_test.gleam`:

- ✓ has_next_page with/without next URL
- ✓ has_previous_page with/without previous URL
- ✓ next_page_params URL parsing
- ✓ previous_page_params URL parsing
- ✓ build_query_string with various inputs
- ✓ pagination_params_to_query conversion
- ✓ Edge cases (malformed URLs, missing params, etc.)

Run tests:
```bash
gleam test --target erlang -- --module meal_planner/tandoor/core/pagination_test
```

## Performance Considerations

1. **URL Parsing**: Uses `gleam/uri` parser which is efficient for standard URLs
2. **Query String Building**: Uses functional pipelines - O(n) where n is parameter count
3. **Parameter Extraction**: Scans query string once - O(n) where n is query length

For high-throughput scenarios, consider:
- Caching parsed pagination parameters
- Batch processing multiple pages in parallel
- Using cursor-based pagination if API supports it

## API Compatibility

These helpers work with Tandoor API's standard pagination format:

```json
{
  "count": 100,
  "next": "http://api/endpoint?limit=10&offset=10",
  "previous": "http://api/endpoint?limit=10&offset=0",
  "results": [...]
}
```

The helpers support:
- ✓ Limit/offset pagination
- ✓ Reordered query parameters
- ✓ Extra query parameters (ignored)
- ✓ Absolute and relative URLs
- ✓ HTTP and HTTPS schemes

## Migration Guide

If you're currently handling pagination manually:

**Before:**
```gleam
case response.next {
  Some(url) -> {
    // Manual URL parsing...
    let parts = string.split(url, "?")
    let query = list.last(parts)
    // ... complex parameter extraction
  }
  None -> // done
}
```

**After:**
```gleam
case pagination.next_page_params(response) {
  Some(#(limit, offset)) -> fetch_next_page(limit, offset)
  None -> done()
}
```

## See Also

- `meal_planner/tandoor/core/http.gleam` - HTTP transport layer
- `meal_planner/tandoor/api/food/list.gleam` - Example usage with Food API
- `examples/pagination_helpers_example.gleam` - Working examples
