# Analysis: list_foods() Implementation

## Current Implementation Details

### Function Signature
```gleam
pub fn list_foods(
  config: ClientConfig,
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(Food), TandoorError)
```

### Location
`gleam/src/meal_planner/tandoor/api/food/list.gleam`

## HTTP Request Details

### Endpoint
- **Path**: `/api/food/`
- **Method**: GET (via `crud_helpers.execute_get`)

### Query Parameters (Current)
The function currently supports **2 query parameters**:

1. **`page_size`** - Number of results per page (from `limit` parameter)
2. **`page`** - Page number for pagination (from `page` parameter)

### Parameter Building Pattern
```gleam
let params = case limit, page {
  option.Some(l), option.Some(p) -> [
    #("page_size", int.to_string(l)),
    #("page", int.to_string(p)),
  ]
  option.Some(l), option.None -> [#("page_size", int.to_string(l))]
  option.None, option.Some(p) -> [#("page", int.to_string(p))]
  option.None, option.None -> []
}
```

### Response Handling
- Uses `crud_helpers.execute_get()` for HTTP execution
- Uses `crud_helpers.parse_json_single()` with `http.paginated_decoder()`
- Returns `PaginatedResponse(Food)` containing:
  - `count: Int` - Total number of foods
  - `next: Option(String)` - URL to next page
  - `previous: Option(String)` - URL to previous page
  - `results: List(Food)` - Food items for current page

## Common Patterns in Codebase

### Pattern 1: Case-Based Parameters (Current in list_foods)
Used in: `list_foods`, `list_supermarkets`, `list_steps`, `list_ingredients`
```gleam
let params = case limit, page {
  option.Some(l), option.Some(p) -> [#("page_size", ...), #("page", ...)]
  option.Some(l), option.None -> [#("page_size", ...)]
  option.None, option.Some(p) -> [#("page", ...)]
  option.None, option.None -> []
}
```

### Pattern 2: Pipe-Based Parameters (More Extensible)
Used in: `list_recipes`, `list_meal_plans`, `shopping_list`
```gleam
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
  |> list.reverse
```

### Pattern 3: Helper Function
Used in: `unit/list.gleam`, `shopping_list.gleam`
```gleam
fn build_query_params(
  limit: Option(Int),
  page: Option(Int),
) -> List(#(String, String)) {
  let limit_params = case limit {
    option.Some(l) -> [#("page_size", int.to_string(l))]
    option.None -> []
  }
  let page_params = case page {
    option.Some(p) -> [#("page", int.to_string(p))]
    option.None -> []
  }
  list.append(limit_params, page_params)
}
```

## What list_foods_with_options() Needs to Add

### Likely Additional Query Parameters
Based on Tandoor API documentation and similar endpoints, the Food API likely supports:

1. **Search/Filter Parameters**:
   - `query` or `search` - Text search in food names
   - `name` - Exact or partial name match
   - `parent_food` - Filter by parent food ID
   - `inherit_fields` - Filter by inherit fields setting

2. **Sorting Parameters**:
   - `ordering` - Field to sort by (e.g., "name", "-name", "id")

3. **Filtering Parameters**:
   - `food_onhand` - Filter by on-hand status (boolean)
   - `supermarket` - Filter by supermarket ID
   - `category` - Filter by category ID

### Implementation Approach

#### Option A: Full Options Record Type (Recommended)
```gleam
pub type FoodListOptions {
  FoodListOptions(
    // Pagination
    page_size: Option(Int),
    page: Option(Int),

    // Filtering
    query: Option(String),
    parent_food: Option(Int),
    food_onhand: Option(Bool),
    supermarket: Option(Int),
    category: Option(Int),

    // Sorting
    ordering: Option(String),
  )
}

pub fn list_foods_with_options(
  config: ClientConfig,
  options: FoodListOptions,
) -> Result(PaginatedResponse(Food), TandoorError) {
  let params = build_food_query_params(options)
  use resp <- result.try(crud_helpers.execute_get(config, "/api/food/", params))
  crud_helpers.parse_json_single(resp, http.paginated_decoder(food_decoder.food_decoder()))
}

fn build_food_query_params(options: FoodListOptions) -> List(#(String, String)) {
  []
  |> add_int_param("page_size", options.page_size)
  |> add_int_param("page", options.page)
  |> add_string_param("query", options.query)
  |> add_int_param("parent_food", options.parent_food)
  |> add_bool_param("food_onhand", options.food_onhand)
  |> add_int_param("supermarket", options.supermarket)
  |> add_int_param("category", options.category)
  |> add_string_param("ordering", options.ordering)
}
```

#### Option B: Multiple Named Parameters (Less Scalable)
```gleam
pub fn list_foods_with_options(
  config: ClientConfig,
  page_size page_size: Option(Int),
  page page: Option(Int),
  query query: Option(String),
  parent_food parent_food: Option(Int),
  ordering ordering: Option(String),
) -> Result(PaginatedResponse(Food), TandoorError) {
  // Build params using pipe pattern
  let params =
    []
    |> fn(p) { case page_size { Some(v) -> [#("page_size", int.to_string(v)), ..p], None -> p } }
    |> fn(p) { case page { Some(v) -> [#("page", int.to_string(v)), ..p], None -> p } }
    |> fn(p) { case query { Some(v) -> [#("query", v), ..p], None -> p } }
    |> fn(p) { case parent_food { Some(v) -> [#("parent_food", int.to_string(v)), ..p], None -> p } }
    |> fn(p) { case ordering { Some(v) -> [#("ordering", v), ..p], None -> p } }
    |> list.reverse

  use resp <- result.try(crud_helpers.execute_get(config, "/api/food/", params))
  crud_helpers.parse_json_single(resp, http.paginated_decoder(food_decoder.food_decoder()))
}
```

## Recommended Implementation Strategy

### Step 1: Create Helper Functions
Create reusable parameter builders in `crud_helpers.gleam` or a new `query_builder.gleam`:

```gleam
// Helper functions for building query parameters
pub fn add_int_param(
  params: List(#(String, String)),
  name: String,
  value: Option(Int),
) -> List(#(String, String)) {
  case value {
    option.Some(v) -> [#(name, int.to_string(v)), ..params]
    option.None -> params
  }
}

pub fn add_string_param(
  params: List(#(String, String)),
  name: String,
  value: Option(String),
) -> List(#(String, String)) {
  case value {
    option.Some(v) -> [#(name, v), ..params]
    option.None -> params
  }
}

pub fn add_bool_param(
  params: List(#(String, String)),
  name: String,
  value: Option(Bool),
) -> List(#(String, String)) {
  case value {
    option.Some(True) -> [#(name, "true"), ..params]
    option.Some(False) -> [#(name, "false"), ..params]
    option.None -> params
  }
}
```

### Step 2: Define FoodListOptions Type
In `meal_planner/tandoor/types/food/food_list_options.gleam`:

```gleam
pub type FoodListOptions {
  FoodListOptions(
    page_size: Option(Int),
    page: Option(Int),
    query: Option(String),
    parent_food: Option(Int),
    food_onhand: Option(Bool),
    supermarket: Option(Int),
    category: Option(Int),
    ordering: Option(String),
  )
}

pub fn default() -> FoodListOptions {
  FoodListOptions(
    page_size: option.None,
    page: option.None,
    query: option.None,
    parent_food: option.None,
    food_onhand: option.None,
    supermarket: option.None,
    category: option.None,
    ordering: option.None,
  )
}
```

### Step 3: Implement list_foods_with_options
In `meal_planner/tandoor/api/food/list.gleam`, add:

```gleam
pub fn list_foods_with_options(
  config: ClientConfig,
  options: FoodListOptions,
) -> Result(PaginatedResponse(Food), TandoorError) {
  let params =
    []
    |> query_builder.add_int_param("page_size", options.page_size)
    |> query_builder.add_int_param("page", options.page)
    |> query_builder.add_string_param("query", options.query)
    |> query_builder.add_int_param("parent_food", options.parent_food)
    |> query_builder.add_bool_param("food_onhand", options.food_onhand)
    |> query_builder.add_int_param("supermarket", options.supermarket)
    |> query_builder.add_int_param("category", options.category)
    |> query_builder.add_string_param("ordering", options.ordering)
    |> list.reverse

  use resp <- result.try(crud_helpers.execute_get(config, "/api/food/", params))
  crud_helpers.parse_json_single(
    resp,
    http.paginated_decoder(food_decoder.food_decoder()),
  )
}
```

## Testing Strategy

### Unit Tests
Test query parameter building with various option combinations:
```gleam
// Test with all options
// Test with no options
// Test with partial options
// Test pagination only
// Test filtering only
```

### Integration Tests
Test actual API calls (if Tandoor test instance available):
```gleam
// Test pagination
// Test search query
// Test filtering by parent_food
// Test ordering
```

## Migration Path

1. **Keep existing `list_foods()` unchanged** for backward compatibility
2. **Add `list_foods_with_options()` as new function**
3. **Eventually deprecate `list_foods()` in favor of options-based approach**
4. **Document migration in changelog**

## Dependencies

### Existing Modules Used
- `meal_planner/tandoor/api/crud_helpers` - HTTP execution and parsing
- `meal_planner/tandoor/client` - Config and error types
- `meal_planner/tandoor/core/http` - PaginatedResponse type
- `meal_planner/tandoor/decoders/food/food_decoder` - JSON decoding
- `gleam/option` - Option type handling
- `gleam/int` - Integer to string conversion
- `gleam/list` - List operations
- `gleam/result` - Result type handling

### New Modules Needed
- `meal_planner/tandoor/types/food/food_list_options.gleam` - Options type
- `meal_planner/tandoor/api/query_builder.gleam` (optional) - Reusable param builders

## Summary

The `list_foods()` function is a simple paginated list endpoint that currently supports:
- **2 query parameters**: `page_size` and `page`
- **Case-based parameter building** (less extensible)
- **Standard CRUD helpers** for HTTP and JSON handling

The `list_foods_with_options()` function should:
- **Use an options record type** for better extensibility
- **Support 6-8 additional query parameters** (search, filtering, sorting)
- **Use pipe-based parameter building** for cleaner code
- **Reuse existing helper functions** for consistency
- **Maintain backward compatibility** with existing `list_foods()`

**Recommended approach**: Option A (Full Options Record Type) for maximum flexibility and maintainability.
