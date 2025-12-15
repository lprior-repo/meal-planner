# Semantic Analysis: update_food Parameter Name

**Bead:** meal-planner-6zj
**Agent:** SEMANTIC ANALYSIS (Agent 20)
**Date:** 2025-12-14

## Parameter Name Analysis

### Current Implementation
```gleam
pub fn update_food(
  config: ClientConfig,
  food_id food_id: Int,
  food_data food_data: TandoorFoodCreateRequest,  // ← Current parameter name
) -> Result(Food, TandoorError)
```

### Two Candidates

1. **`food:`** - Suggests a complete Food object
2. **`food_data:`** - Suggests data payload for an operation

## Semantic Meaning Analysis

### `food:` Semantics
- **Suggests:** A complete Food entity/object
- **Typical usage:** Passing existing domain objects
- **Mental model:** "Here's a food item to work with"
- **Problem:** Creates ambiguity - is this the food being updated, or the update payload?

### `food_data:` Semantics
- **Suggests:** Data/payload for an operation
- **Typical usage:** Create/update request payloads
- **Mental model:** "Here's the data to use for this operation"
- **Clarity:** Explicitly indicates this is input data, not an entity

## Codebase Convention Analysis

### Pattern 1: Create Operations
All create operations use `*_data` suffix:

```gleam
// food/create.gleam
pub fn create_food(
  config: ClientConfig,
  food_data: TandoorFoodCreateRequest,  // ✓ Uses *_data
)

// ingredient/update.gleam
pub fn update_ingredient(
  config: ClientConfig,
  ingredient_id ingredient_id: Int,
  ingredient_data ingredient_data: IngredientCreateRequest,  // ✓ Uses *_data
)
```

### Pattern 2: Update Operations with Partial Updates
Operations with dedicated update types vary:

```gleam
// recipe/update.gleam
pub fn update_recipe(
  config: ClientConfig,
  recipe_id recipe_id: Int,
  update_data update_data: RecipeUpdate,  // Uses "update_data"
)

// cuisine/update.gleam
pub fn update_cuisine(
  config: ClientConfig,
  cuisine_id cuisine_id: Int,
  data update_data: CuisineUpdateRequest,  // Uses "data" label, "update_data" param
)

// step/update.gleam
pub fn update_step(
  config: ClientConfig,
  step_id step_id: Int,
  request request: StepUpdateRequest,  // Uses "request"
)
```

### Pattern 3: Update Operations Reusing Create Types
Food and Ingredient both reuse create types for updates:

```gleam
// food/update.gleam (CURRENT)
pub fn update_food(
  config: ClientConfig,
  food_id food_id: Int,
  food_data food_data: TandoorFoodCreateRequest,  // ✓ Matches create pattern
)

// ingredient/update.gleam
pub fn update_ingredient(
  config: ClientConfig,
  ingredient_id ingredient_id: Int,
  ingredient_data ingredient_data: IngredientCreateRequest,  // ✓ Matches create pattern
)
```

## Naming Pattern Summary

| Operation Type | Type Used | Parameter Name | Files |
|---------------|-----------|----------------|-------|
| Create | `*CreateRequest` | `*_data` | food/create.gleam, all creates |
| Update (create type) | `*CreateRequest` | `*_data` | food/update.gleam, ingredient/update.gleam |
| Update (update type) | `*Update` | `update_data` | recipe/update.gleam |
| Update (update type) | `*UpdateRequest` | `update_data` or `request` | cuisine/update.gleam, step/update.gleam |

## Convention Finding

**STRONG PATTERN:** When an update operation reuses a create type (`TandoorFoodCreateRequest`), the parameter is named `{entity}_data`, matching the create operation pattern.

**Examples:**
- `create_food(config, food_data)` + `update_food(config, food_id, food_data)` ✓
- `create_ingredient(config, ingredient_data)` + `update_ingredient(config, ingredient_id, ingredient_data)` ✓

This maintains consistency between create and update operations that share the same request type.

## Clarity Analysis for API Users

### Scenario: Developer calling update_food

**Using `food_data:`**
```gleam
let food_data = TandoorFoodCreateRequest(name: "Cherry Tomato")
let result = update_food(config, food_id: 42, food_data: food_data)
```
✓ Clear: "I'm providing food data to update the food with ID 42"
✓ Consistent with create_food pattern
✓ Explicit about providing data payload

**Using `food:`**
```gleam
let food = TandoorFoodCreateRequest(name: "Cherry Tomato")
let result = update_food(config, food_id: 42, food: food)
```
✗ Ambiguous: "Am I providing a food object? Which food?"
✗ Contradicts the fact this is a request type, not an entity
✗ Creates confusion with the returned `Food` entity

## Recommendation

**KEEP `food_data`** - It is the correct parameter name because:

1. **Semantic Accuracy:** The parameter is of type `TandoorFoodCreateRequest`, which is data/payload, not a `Food` entity
2. **Codebase Convention:** Matches the established pattern where update operations reusing create types use `{entity}_data`
3. **Create/Update Consistency:** Maintains naming consistency with `create_food(config, food_data)`
4. **Clarity:** Explicitly communicates this is input data, not an entity
5. **Existing Pattern:** Already matches `ingredient_data` in ingredient/update.gleam

## Conclusion

The current implementation using `food_data` is **semantically correct** and follows **established codebase conventions**. No change needed.

**Pattern Rule:**
```
When update operation uses create type → use {entity}_data
When update operation uses update type → use update_data or request
```

The food update operation uses `TandoorFoodCreateRequest` (create type), therefore `food_data` is the correct choice.
