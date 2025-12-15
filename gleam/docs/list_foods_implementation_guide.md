# Implementation Guide: list_foods_with_options()

## Quick Reference

### Current Function
```gleam
pub fn list_foods(
  config: ClientConfig,
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(Food), TandoorError)
```

**Supports**: `page_size`, `page` query parameters only

### Target Function
```gleam
pub fn list_foods_with_options(
  config: ClientConfig,
  options: FoodListOptions,
) -> Result(PaginatedResponse(Food), TandoorError)
```

**Should Support**: Full query parameter set for Food API

## Implementation Checklist

### Phase 1: Setup Helper Functions
- [ ] Create `meal_planner/tandoor/api/query_builder.gleam`
- [ ] Implement `add_int_param()`
- [ ] Implement `add_string_param()`
- [ ] Implement `add_bool_param()`
- [ ] Add tests for helper functions

### Phase 2: Define Options Type
- [ ] Create `meal_planner/tandoor/types/food/food_list_options.gleam`
- [ ] Define `FoodListOptions` record type with all fields
- [ ] Implement `default()` constructor
- [ ] Document all option fields

### Phase 3: Implement Main Function
- [ ] Add `list_foods_with_options()` to `api/food/list.gleam`
- [ ] Build query parameters using pipe pattern
- [ ] Use existing `crud_helpers.execute_get()`
- [ ] Use existing `crud_helpers.parse_json_single()`
- [ ] Add comprehensive documentation

### Phase 4: Testing
- [ ] Write unit tests for query parameter building
- [ ] Test with various option combinations
- [ ] Test edge cases (all None, all Some, mixed)
- [ ] Integration tests (if Tandoor instance available)

### Phase 5: Documentation
- [ ] Update module documentation
- [ ] Add usage examples
- [ ] Document migration from `list_foods()`
- [ ] Update API reference

## Code Templates

### 1. query_builder.gleam
```gleam
import gleam/int
import gleam/list
import gleam/option.{type Option}

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

### 2. food_list_options.gleam
```gleam
import gleam/option.{type Option}

/// Options for listing foods from the Tandoor API
///
/// All fields are optional to allow flexible querying.
pub type FoodListOptions {
  FoodListOptions(
    /// Number of results per page
    page_size: Option(Int),
    /// Page number (1-indexed)
    page: Option(Int),
    /// Search query for food names
    query: Option(String),
    /// Filter by parent food ID
    parent_food: Option(Int),
    /// Filter by on-hand status
    food_onhand: Option(Bool),
    /// Filter by supermarket ID
    supermarket: Option(Int),
    /// Filter by category ID
    category: Option(Int),
    /// Sort order (e.g., "name", "-name", "id", "-id")
    ordering: Option(String),
  )
}

/// Create default options with all fields set to None
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

### 3. Updated list.gleam (add this function)
```gleam
import meal_planner/tandoor/api/query_builder
import meal_planner/tandoor/types/food/food_list_options.{type FoodListOptions}

/// List foods from Tandoor API with advanced filtering options
///
/// This function provides full access to the Food API's query parameters
/// for pagination, searching, filtering, and sorting.
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `options` - FoodListOptions record with query parameters
///
/// # Returns
/// Result with paginated food list or error
///
/// # Example
/// ```gleam
/// import meal_planner/tandoor/types/food/food_list_options
///
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let options = food_list_options.default()
///   |> food_list_options.FoodListOptions(
///     page_size: Some(20),
///     page: Some(1),
///     query: Some("chicken"),
///     ordering: Some("name"),
///     ..
///   )
/// let result = list_foods_with_options(config, options)
/// ```
pub fn list_foods_with_options(
  config: ClientConfig,
  options: FoodListOptions,
) -> Result(PaginatedResponse(Food), TandoorError) {
  // Build query parameters using pipe pattern
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

  // Execute GET request using CRUD helper
  use resp <- result.try(crud_helpers.execute_get(config, "/api/food/", params))

  // Parse JSON response using paginated helper
  crud_helpers.parse_json_single(
    resp,
    http.paginated_decoder(food_decoder.food_decoder()),
  )
}
```

## Usage Examples

### Basic Pagination
```gleam
let options = food_list_options.default()
  |> food_list_options.FoodListOptions(page_size: Some(20), page: Some(1), ..)
let result = list_foods_with_options(config, options)
```

### Search with Filtering
```gleam
let options = food_list_options.default()
  |> food_list_options.FoodListOptions(
    query: Some("chicken"),
    food_onhand: Some(True),
    ordering: Some("name"),
    ..
  )
let result = list_foods_with_options(config, options)
```

### Filter by Category and Supermarket
```gleam
let options = food_list_options.default()
  |> food_list_options.FoodListOptions(
    supermarket: Some(1),
    category: Some(5),
    page_size: Some(50),
    ..
  )
let result = list_foods_with_options(config, options)
```

## Testing Examples

### Test Query Parameter Building
```gleam
import gleeunit/should
import meal_planner/tandoor/types/food/food_list_options

pub fn test_all_options() {
  let options = FoodListOptions(
    page_size: Some(20),
    page: Some(1),
    query: Some("test"),
    parent_food: Some(5),
    food_onhand: Some(True),
    supermarket: Some(10),
    category: Some(3),
    ordering: Some("name"),
  )

  // Build params and verify
  let params = build_params(options)
  
  params
  |> list.find(fn(p) { p.0 == "page_size" })
  |> should.equal(Ok(#("page_size", "20")))
  
  params
  |> list.find(fn(p) { p.0 == "query" })
  |> should.equal(Ok(#("query", "test")))
  
  params
  |> list.find(fn(p) { p.0 == "food_onhand" })
  |> should.equal(Ok(#("food_onhand", "true")))
}
```

## Migration Notes

### Backward Compatibility
The existing `list_foods()` function should remain unchanged:
```gleam
// Old function - still works
pub fn list_foods(
  config: ClientConfig,
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(Food), TandoorError)

// New function - additional features
pub fn list_foods_with_options(
  config: ClientConfig,
  options: FoodListOptions,
) -> Result(PaginatedResponse(Food), TandoorError)
```

### Converting Existing Code
```gleam
// Before
list_foods(config, limit: Some(20), page: Some(1))

// After
let options = food_list_options.default()
  |> food_list_options.FoodListOptions(page_size: Some(20), page: Some(1), ..)
list_foods_with_options(config, options)
```

## Key Decisions

1. **Use Options Record**: More extensible than multiple named parameters
2. **Pipe-Based Building**: Cleaner than case expressions for many parameters
3. **Helper Functions**: Reusable across all API modules
4. **Backward Compatible**: Keep existing function, add new one
5. **Standard Patterns**: Follow existing codebase conventions

## Next Steps

After implementing `list_foods_with_options()`:
1. Consider applying same pattern to other list functions
2. Update other API modules to use query_builder helpers
3. Document pattern as standard for new list functions
4. Consider creating generic `ListOptions` type for common parameters
