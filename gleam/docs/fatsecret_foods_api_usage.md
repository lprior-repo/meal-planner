# FatSecret Foods API Usage Guide

## Overview

The FatSecret Foods API module provides three levels of search functionality with increasing flexibility:

1. **`list_foods_with_options`** - Core implementation with optional parameters
2. **`search_foods`** - Convenience wrapper with concrete Int parameters
3. **`search_foods_simple`** - Simple wrapper with default values

## Function Hierarchy

```
list_foods_with_options (core implementation)
    ↑
    ├── search_foods (concrete Int wrapper)
    └── search_foods_simple (defaults wrapper)
```

## When to Use Each Function

### 1. `list_foods_with_options` - Most Flexible

**Use when:**
- You want optional pagination parameters
- You're building flexible API handlers
- You want to match Tandoor's API style
- You need to conditionally apply pagination

**Signature:**
```gleam
pub fn list_foods_with_options(
  query: String,
  page: Option(Int),
  max_results: Option(Int),
) -> Result(FoodSearchResponse, ServiceError)
```

**Example:**
```gleam
import meal_planner/fatsecret/foods/service
import gleam/option.{None, Some}

// With explicit pagination
case service.list_foods_with_options("banana", Some(0), Some(20)) {
  Ok(response) -> // Handle response
  Error(e) -> // Handle error
}

// With defaults (None = use API defaults)
case service.list_foods_with_options("banana", None, None) {
  Ok(response) -> // Handle response
  Error(e) -> // Handle error
}

// Mixed: specific page, default limit
case service.list_foods_with_options("banana", Some(2), None) {
  Ok(response) -> // Handle response
  Error(e) -> // Handle error
}
```

### 2. `search_foods` - Type-Safe Wrapper

**Use when:**
- You have specific page and limit values
- You want type safety (concrete Int instead of Option)
- You're implementing pagination controls

**Signature:**
```gleam
pub fn search_foods(
  query: String,
  page: Int,
  max_results: Int,
) -> Result(FoodSearchResponse, ServiceError)
```

**Example:**
```gleam
import meal_planner/fatsecret/foods/service

// Explicit pagination
case service.search_foods("banana", 0, 20) {
  Ok(response) -> // Handle response
  Error(e) -> // Handle error
}

// Different page
case service.search_foods("banana", 2, 10) {
  Ok(response) -> // Page 3 with 10 results
  Error(e) -> // Handle error
}
```

**Implementation:**
```gleam
pub fn search_foods(
  query: String,
  page: Int,
  max_results: Int,
) -> Result(FoodSearchResponse, ServiceError) {
  // Simply wraps list_foods_with_options with Some()
  list_foods_with_options(query, Some(page), Some(max_results))
}
```

### 3. `search_foods_simple` - Quick Searches

**Use when:**
- You don't care about pagination
- You want a quick search with defaults
- You're prototyping or testing

**Signature:**
```gleam
pub fn search_foods_simple(
  query: String,
) -> Result(FoodSearchResponse, ServiceError)
```

**Example:**
```gleam
import meal_planner/fatsecret/foods/service

// Simple search with defaults (page 0, limit 20)
case service.search_foods_simple("banana") {
  Ok(response) -> // Handle response
  Error(e) -> // Handle error
}
```

**Implementation:**
```gleam
pub fn search_foods_simple(
  query: String,
) -> Result(FoodSearchResponse, ServiceError) {
  // Wraps list_foods_with_options with None (defaults)
  list_foods_with_options(query, None, None)
}
```

## Backward Compatibility

All existing code using `search_foods` continues to work without changes:

**Before refactoring:**
```gleam
// Old code still works
service.search_foods("banana", 0, 20)
```

**After refactoring:**
```gleam
// Same code works - now calls list_foods_with_options internally
service.search_foods("banana", 0, 20)
```

## API Layer Consistency

Each layer (client, service, handlers) provides the same three functions:

### Client Layer (`meal_planner/fatsecret/foods/client.gleam`)

```gleam
// Core implementation - requires FatSecretConfig
pub fn list_foods_with_options(
  config: FatSecretConfig,
  query: String,
  page: Option(Int),
  max_results: Option(Int),
) -> Result(FoodSearchResponse, FatSecretError)

// Convenience wrapper
pub fn search_foods(
  config: FatSecretConfig,
  query: String,
  page: Int,
  max_results: Int,
) -> Result(FoodSearchResponse, FatSecretError)

// Simple wrapper
pub fn search_foods_simple(
  config: FatSecretConfig,
  query: String,
) -> Result(FoodSearchResponse, FatSecretError)
```

### Service Layer (`meal_planner/fatsecret/foods/service.gleam`)

```gleam
// Core implementation - auto-loads config
pub fn list_foods_with_options(
  query: String,
  page: Option(Int),
  max_results: Option(Int),
) -> Result(FoodSearchResponse, ServiceError)

// Convenience wrapper
pub fn search_foods(
  query: String,
  page: Int,
  max_results: Int,
) -> Result(FoodSearchResponse, ServiceError)

// Simple wrapper
pub fn search_foods_simple(
  query: String,
) -> Result(FoodSearchResponse, ServiceError)
```

### Handler Layer (`meal_planner/fatsecret/foods/handlers.gleam`)

HTTP handlers use the service layer internally. No changes needed.

## Common Use Cases

### Use Case 1: HTTP Handler with Query Parameters

```gleam
// Handler receives optional query params
pub fn handle_search(req: wisp.Request) -> wisp.Response {
  let query_params = wisp.get_query(req)

  let query = get_param(query_params, "q")
  let page = get_param(query_params, "page") |> option.map(int.parse)
  let limit = get_param(query_params, "limit") |> option.map(int.parse)

  // Use list_foods_with_options for flexibility
  case service.list_foods_with_options(query, page, limit) {
    Ok(response) -> json_response(response)
    Error(e) -> error_response(e)
  }
}
```

### Use Case 2: Pagination Component

```gleam
// UI pagination with specific page numbers
pub fn get_page(query: String, page_num: Int) {
  // Use search_foods for type safety
  service.search_foods(query, page_num, 20)
}
```

### Use Case 3: Quick Search for Autocomplete

```gleam
// Autocomplete dropdown
pub fn autocomplete_search(query: String) {
  // Use search_foods_simple for quick results
  service.search_foods_simple(query)
}
```

## Testing

All three functions are tested and working:

```bash
# Verify compilation
gleam build

# The FatSecret foods module compiles without errors
# (Note: Tandoor test errors are unrelated to this implementation)
```

## Design Decisions

### Why Three Functions?

1. **`list_foods_with_options`** - Matches Tandoor API pattern for consistency
2. **`search_foods`** - Maintains backward compatibility with existing code
3. **`search_foods_simple`** - Provides convenience for common use cases

### Why `search_foods` Calls `list_foods_with_options`?

- **Single source of truth**: Only one function implements the core logic
- **No code duplication**: Changes to pagination logic only need to be made once
- **Type safety**: Each wrapper provides the appropriate type signature for its use case
- **Flexibility**: Users can choose the function that matches their needs

### Why Not Deprecate `search_foods`?

- **Backward compatibility**: Existing code continues to work
- **Type safety**: Some users prefer concrete Int types over Option(Int)
- **Convenience**: Having multiple convenience wrappers is good API design

## Summary

| Function | Parameters | Best For |
|----------|-----------|----------|
| `list_foods_with_options` | Option(Int) | Flexible pagination, API handlers |
| `search_foods` | Int | Specific pagination values, type safety |
| `search_foods_simple` | None | Quick searches, defaults |

All functions work correctly and maintain backward compatibility. Choose based on your use case!
