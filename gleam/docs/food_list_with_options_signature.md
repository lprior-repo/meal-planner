# Function Signature Design: list_foods_with_options

## Analysis Date
2025-12-14

## Overview
Design for the `list_foods_with_options` function to provide flexible food listing with search, filtering, and pagination capabilities for the Tandoor API.

---

## Proposed Function Signature

```gleam
pub fn list_foods_with_options(
  config: ClientConfig,
  query query: Option(String),
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(Food), TandoorError)
```

---

## Parameter Details

### 1. `config: ClientConfig`
- **Type**: `ClientConfig`
- **Required**: Yes
- **Purpose**: Client configuration with authentication credentials
- **Pattern**: Standard across all API functions

### 2. `query: Option(String)`
- **Type**: `Option(String)`
- **Required**: No
- **Purpose**: Search/filter query string for finding foods by name or other attributes
- **Default**: `None` (no filtering)
- **Examples**:
  - `Some("chicken")` - Search for foods containing "chicken"
  - `Some("tom")` - Search for "tomato", "tomatoes", etc.
  - `None` - List all foods

### 3. `limit: Option(Int)`
- **Type**: `Option(Int)`
- **Required**: No
- **Purpose**: Number of results per page (maps to `page_size` query parameter)
- **Default**: `None` (API default, typically 25-100)
- **Pattern**: Consistent with `food/list.gleam`, `ingredient/list.gleam`, `supermarket/list.gleam`
- **Examples**:
  - `Some(50)` - Get 50 results per page
  - `None` - Use API default

### 4. `page: Option(Int)`
- **Type**: `Option(Int)`
- **Required**: No
- **Purpose**: Page number for pagination (1-indexed)
- **Default**: `None` (first page)
- **Pattern**: Consistent with `food/list.gleam`, `ingredient/list.gleam`, `supermarket/list.gleam`
- **Examples**:
  - `Some(1)` - First page
  - `Some(2)` - Second page
  - `None` - First page

---

## Return Type

### `Result(PaginatedResponse(Food), TandoorError)`

**Success Case**: `Ok(PaginatedResponse(Food))`
```gleam
PaginatedResponse(
  count: Int,           // Total number of matching foods
  next: Option(String), // URL to next page (if any)
  previous: Option(String), // URL to previous page (if any)
  results: List(Food),  // List of Food objects for this page
)
```

**Error Case**: `Error(TandoorError)`
- Network errors
- Authentication failures
- JSON parsing errors
- Invalid query parameters

---

## Naming Convention Analysis

### Codebase Patterns

1. **Page-based Pagination** (Most Common):
   - `food/list.gleam`: Uses `page` + `page_size`
   - `ingredient/list.gleam`: Uses `page` + `page_size`
   - `supermarket/list.gleam`: Uses `page` + `page_size`
   - `unit/list.gleam`: Uses `page` + `page_size`

2. **Offset-based Pagination** (Less Common):
   - `recipe/list.gleam`: Uses `offset` + `limit`
   - `shopping_list.gleam`: Uses `offset` + `page_size`

3. **Function Naming**:
   - Simple list: `list_foods`, `list_recipes`, `list_ingredients`
   - With filtering: `list_meal_plans` (date filters), `list_cuisines_by_parent`
   - **Proposed**: `list_foods_with_options` - explicit about additional capabilities

### Decision Rationale

**Use Page-Based Pagination**:
- Matches existing `list_foods` function in `food/list.gleam`
- More user-friendly (page 1, 2, 3 vs offset calculations)
- Consistent with majority of food-related endpoints
- Parameter names: `page` and `limit` (internally maps to `page_size`)

---

## Query Parameter Mapping

### Internal to API Translation

| Function Parameter | API Query Parameter | Notes |
|-------------------|---------------------|-------|
| `query: Option(String)` | `query=<value>` | Search filter string |
| `limit: Option(Int)` | `page_size=<value>` | Results per page |
| `page: Option(Int)` | `page=<value>` | Page number (1-indexed) |

### Example HTTP Requests

```
GET /api/food/?query=chicken&page_size=25&page=1
GET /api/food/?query=tom&page_size=50
GET /api/food/?page_size=100&page=2
GET /api/food/?query=dairy
GET /api/food/
```

---

## Usage Examples

### Example 1: Basic Search
```gleam
import meal_planner/tandoor/client
import meal_planner/tandoor/api/food/list
import gleam/option.{Some, None}

let config = client.bearer_config("http://localhost:8000", "my-token")

// Search for chicken, default pagination
let result = list.list_foods_with_options(
  config,
  query: Some("chicken"),
  limit: None,
  page: None,
)
```

### Example 2: Paginated Search
```gleam
// Search for tomatoes, 50 per page, second page
let result = list.list_foods_with_options(
  config,
  query: Some("tom"),
  limit: Some(50),
  page: Some(2),
)
```

### Example 3: List All with Pagination
```gleam
// Get all foods, 100 per page, first page
let result = list.list_foods_with_options(
  config,
  query: None,
  limit: Some(100),
  page: Some(1),
)
```

### Example 4: Simple Search
```gleam
// Just search, use defaults for pagination
let result = list.list_foods_with_options(
  config,
  query: Some("dairy"),
  limit: None,
  page: None,
)
```

### Example 5: Response Handling
```gleam
case list.list_foods_with_options(config, query: Some("rice"), limit: Some(25), page: Some(1)) {
  Ok(response) -> {
    // response.count = total matching foods
    // response.results = List(Food) for this page
    // response.next = Some("...") if more pages
    // response.previous = Some("...") if not first page
    io.println("Found " <> int.to_string(response.count) <> " foods")
    response.results
  }
  Error(client.NetworkError(msg)) -> {
    io.println("Network error: " <> msg)
    []
  }
  Error(client.AuthenticationError(msg)) -> {
    io.println("Auth error: " <> msg)
    []
  }
  Error(client.ParseError(msg)) -> {
    io.println("Parse error: " <> msg)
    []
  }
}
```

---

## Comparison with Similar Functions

### 1. Existing `list_foods` (food/list.gleam)
```gleam
pub fn list_foods(
  config: ClientConfig,
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(Food), TandoorError)
```
**Differences**:
- `list_foods_with_options` adds `query` parameter
- Same pagination approach (page-based)
- Same return type

### 2. `list_ingredients` (ingredient/list.gleam)
```gleam
pub fn list_ingredients(
  config: ClientConfig,
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(Ingredient), TandoorError)
```
**Pattern Match**: ✅ Identical structure, different entity type

### 3. `list_recipes` (recipe/list.gleam)
```gleam
pub fn list_recipes(
  config: ClientConfig,
  limit limit: Option(Int),
  offset offset: Option(Int),
) -> Result(PaginatedResponse(TandoorRecipe), TandoorError)
```
**Differences**:
- Uses `offset` instead of `page`
- No query parameter
- Different pagination style

### 4. `list_meal_plans` (mealplan/list.gleam)
```gleam
pub fn list_meal_plans(
  config: ClientConfig,
  from_date from_date: Option(String),
  to_date to_date: Option(String),
) -> Result(MealPlanListResponse, TandoorError)
```
**Differences**:
- Domain-specific filters (dates)
- No pagination parameters
- Different response type

### 5. Shopping List with Filtering (shopping_list.gleam)
```gleam
pub fn list(
  config: ClientConfig,
  checked: Option(Bool),
  limit: Option(Int),
  offset: Option(Int),
) -> Result(PaginatedResponse(ShoppingListEntryResponse), TandoorError)
```
**Similar Pattern**: Boolean filter + pagination (but offset-based)

---

## Design Rationale

### Why This Signature?

1. **Consistency**: Matches existing `list_foods` pagination style
2. **Flexibility**: Optional query parameter for search/filter
3. **Extensibility**: Easy to add more filters in future (e.g., `category`, `recipe_id`)
4. **User-Friendly**: Page-based pagination is more intuitive than offset-based
5. **Type Safety**: Uses Gleam's `Option` type for optional parameters
6. **Error Handling**: Leverages existing `TandoorError` type for comprehensive error cases

### Alternative Considered: Offset-Based

```gleam
// NOT RECOMMENDED (inconsistent with food/list.gleam)
pub fn list_foods_with_options(
  config: ClientConfig,
  query query: Option(String),
  limit limit: Option(Int),
  offset offset: Option(Int),
) -> Result(PaginatedResponse(Food), TandoorError)
```
**Rejected**: Would be inconsistent with existing `list_foods` function

### Future Extensions

If additional filtering is needed, parameters can be added:
```gleam
pub fn list_foods_with_options(
  config: ClientConfig,
  query query: Option(String),
  limit limit: Option(Int),
  page page: Option(Int),
  category category: Option(Int),        // Future: Filter by category ID
  recipe recipe: Option(Int),            // Future: Foods used in recipe
  ignore_shopping ignore: Option(Bool),  // Future: Exclude from shopping list
) -> Result(PaginatedResponse(Food), TandoorError)
```

---

## Implementation Notes

### Query Parameter Construction

Following the pattern from `shopping_list.gleam`:

```gleam
fn build_query_params(
  query: Option(String),
  limit: Option(Int),
  page: Option(Int),
) -> List(#(String, String)) {
  let query_param = case query {
    option.Some(q) -> [#("query", q)]
    option.None -> []
  }

  let limit_param = case limit {
    option.Some(l) -> [#("page_size", int.to_string(l))]
    option.None -> []
  }

  let page_param = case page {
    option.Some(p) -> [#("page", int.to_string(p))]
    option.None -> []
  }

  // Flatten all parameter lists
  list.flatten([query_param, limit_param, page_param])
}
```

### File Location

**Target File**: `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/list.gleam`

**Placement**: Add as new function alongside existing `list_foods`

---

## Validation

### Type Safety
- ✅ All parameters properly typed
- ✅ Uses existing types from codebase
- ✅ Return type matches pagination pattern

### Consistency
- ✅ Follows page-based pagination like `food/list.gleam`
- ✅ Uses same parameter naming (`limit` + `page`)
- ✅ Same return type as `list_foods`

### Flexibility
- ✅ All parameters optional (backwards compatible)
- ✅ Can be called with any combination of parameters
- ✅ Extensible for future filters

### Documentation
- ✅ Clear parameter descriptions
- ✅ Multiple usage examples
- ✅ Error handling examples

---

## Conclusion

The proposed signature provides:
1. **Search capability** via `query` parameter
2. **Pagination control** via `limit` and `page`
3. **Consistency** with existing food API patterns
4. **Flexibility** for various use cases
5. **Type safety** with Gleam's type system

This design is ready for implementation in the next phase.
