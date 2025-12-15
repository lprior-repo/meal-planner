# Agent 10 Deliverable: list_foods() Analysis

**Bead**: meal-planner-ahh
**Agent**: Agent 10 of 8 - ANALYZE EXISTING list_foods
**Status**: ✅ COMPLETE

---

## Executive Summary

The existing `list_foods()` function is a **simple paginated list endpoint** with minimal query parameters. The new `list_foods_with_options()` function should extend this with **comprehensive filtering, searching, and sorting capabilities** using an **options record pattern**.

---

## Current Implementation

### Function Details
- **Location**: `gleam/src/meal_planner/tandoor/api/food/list.gleam`
- **Endpoint**: `GET /api/food/`
- **Query Parameters**: `page_size`, `page` (only 2 parameters)
- **Response**: `PaginatedResponse(Food)` with count, next, previous, results
- **Pattern**: Case-based parameter building (less extensible)

### Signature
```gleam
pub fn list_foods(
  config: ClientConfig,
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(Food), TandoorError)
```

### HTTP Request Flow
1. Build query params using case expressions
2. Execute GET via `crud_helpers.execute_get(config, "/api/food/", params)`
3. Parse response via `crud_helpers.parse_json_single()` with `paginated_decoder()`

---

## What list_foods_with_options() Needs

### Additional Query Parameters (6-8 new parameters)
1. **`query`** (String) - Search food names
2. **`parent_food`** (Int) - Filter by parent food ID
3. **`food_onhand`** (Bool) - Filter by on-hand status
4. **`supermarket`** (Int) - Filter by supermarket ID
5. **`category`** (Int) - Filter by category ID
6. **`ordering`** (String) - Sort order (e.g., "name", "-name")

### Recommended Implementation Pattern

**✅ Use Options Record Type** (not multiple named parameters)

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

pub fn list_foods_with_options(
  config: ClientConfig,
  options: FoodListOptions,
) -> Result(PaginatedResponse(Food), TandoorError)
```

---

## Implementation Strategy

### Phase 1: Create Reusable Helpers
**File**: `meal_planner/tandoor/api/query_builder.gleam`

Three helper functions:
- `add_int_param()` - Add integer query parameter
- `add_string_param()` - Add string query parameter
- `add_bool_param()` - Add boolean query parameter

### Phase 2: Define Options Type
**File**: `meal_planner/tandoor/types/food/food_list_options.gleam`

- Define `FoodListOptions` record
- Implement `default()` constructor
- Document all fields

### Phase 3: Implement Main Function
**File**: `meal_planner/tandoor/api/food/list.gleam`

Use **pipe-based parameter building**:
```gleam
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
```

---

## Codebase Patterns Found

### Pattern 1: Case-Based (Current - Less Extensible)
Used in: `list_foods`, `list_supermarkets`, `list_steps`
```gleam
let params = case limit, page {
  option.Some(l), option.Some(p) -> [...]
  option.Some(l), option.None -> [...]
  ...
}
```

### Pattern 2: Pipe-Based (Recommended - More Extensible)
Used in: `list_recipes`, `list_meal_plans`, `shopping_list`
```gleam
let params =
  []
  |> fn(p) { case limit { Some(v) -> [..., ..p], None -> p } }
  |> fn(p) { case offset { Some(v) -> [..., ..p], None -> p } }
  |> list.reverse
```

### Pattern 3: Helper Function (Most Reusable)
Used in: `unit/list.gleam`, `shopping_list.gleam`
```gleam
fn build_query_params(...) -> List(#(String, String)) {
  // Separate function for param building
}
```

---

## Key Decisions

1. ✅ **Options Record** over multiple named parameters (extensibility)
2. ✅ **Pipe-based building** over case expressions (readability)
3. ✅ **Reusable helpers** for all API modules (DRY)
4. ✅ **Backward compatible** - keep existing `list_foods()` unchanged
5. ✅ **Standard patterns** - follow `list_recipes` and `shopping_list` examples

---

## Dependencies

### Existing Modules (No Changes Needed)
- ✅ `crud_helpers` - Already has `execute_get()` and `parse_json_single()`
- ✅ `http` - Already has `PaginatedResponse` and `paginated_decoder()`
- ✅ `food_decoder` - Already has `food_decoder()`
- ✅ Standard library: `option`, `int`, `list`, `result`

### New Modules Required
- 📝 `meal_planner/tandoor/api/query_builder.gleam` - Helper functions
- 📝 `meal_planner/tandoor/types/food/food_list_options.gleam` - Options type

---

## Testing Strategy

### Unit Tests
- Test query parameter building with all options
- Test with no options (empty list)
- Test with partial options (mixed Some/None)
- Test boolean conversion ("true"/"false")

### Integration Tests
- Test actual API calls with pagination
- Test search query filtering
- Test parent_food filtering
- Test ordering

---

## Migration Path

1. **Keep** existing `list_foods()` for backward compatibility
2. **Add** new `list_foods_with_options()` alongside it
3. **Document** migration in changelog
4. **Eventually** deprecate old function in favor of new one

---

## Documentation Created

✅ **Detailed Analysis**: `/home/lewis/src/meal-planner/gleam/docs/list_foods_analysis.md`
✅ **Implementation Guide**: `/home/lewis/src/meal-planner/gleam/docs/list_foods_implementation_guide.md`
✅ **This Summary**: `/home/lewis/src/meal-planner/gleam/docs/AGENT_10_DELIVERABLE.md`

---

## Next Steps for Implementation Team

1. Review this analysis and implementation guide
2. Create `query_builder.gleam` with helper functions
3. Create `food_list_options.gleam` with options type
4. Implement `list_foods_with_options()` in `api/food/list.gleam`
5. Write comprehensive tests
6. Update documentation

---

## Code Templates

All code templates are provided in the **Implementation Guide**:
- Complete `query_builder.gleam` module
- Complete `food_list_options.gleam` module
- Complete `list_foods_with_options()` function
- Usage examples
- Test examples

**Ready for implementation!** 🚀
