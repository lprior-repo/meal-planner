# Shopping List Recipe API

## Overview

The Shopping List Recipe API allows you to add recipes to your shopping list in Tandoor. When you add a recipe, all of its ingredients are automatically added as individual shopping list entries.

## Module

`meal_planner/tandoor/api/shopping/recipe`

## Functions

### `add_recipe_to_shopping_list`

Adds all ingredients from a recipe to the shopping list.

```gleam
pub fn add_recipe_to_shopping_list(
  config: ClientConfig,
  recipe_id recipe_id: Int,
  servings servings: Int,
) -> Result(List(ShoppingListEntry), TandoorError)
```

#### Parameters

- **config** (`ClientConfig`) - Client configuration with authentication
- **recipe_id** (`Int`) - The ID of the recipe to add to shopping list
- **servings** (`Int`) - Number of servings to calculate ingredient quantities

#### Returns

- `Ok(List(ShoppingListEntry))` - List of created shopping list entries
- `Error(TandoorError)` - Error if the operation fails

#### Errors

| Error Type | When It Occurs |
|------------|----------------|
| `NetworkError` | Cannot connect to Tandoor API |
| `AuthenticationError` | Invalid or expired API token |
| `NotFoundError` | Recipe ID does not exist |
| `BadRequestError` | Invalid recipe_id or servings value |
| `ParseError` | Response format is invalid |

## Usage Examples

### Basic Example

```gleam
import meal_planner/tandoor/api/shopping/recipe
import meal_planner/tandoor/client

pub fn add_recipe_to_list() {
  // Configure client
  let config = client.ClientConfig(
    base_url: "http://localhost:8000",
    auth: client.BearerAuth("your-token"),
    timeout_ms: 10_000,
    retry_on_transient: True,
    max_retries: 3,
  )

  // Add recipe with 4 servings
  case recipe.add_recipe_to_shopping_list(config, recipe_id: 123, servings: 4) {
    Ok(entries) -> {
      // Success! entries is a list of ShoppingListEntry
      io.println("Added " <> list.length(entries) <> " items to shopping list")
    }
    Error(err) -> {
      // Handle error
      io.println("Failed to add recipe: " <> error_to_string(err))
    }
  }
}
```

### Error Handling Example

```gleam
pub fn add_recipe_with_error_handling() {
  let config = get_client_config()

  case recipe.add_recipe_to_shopping_list(config, recipe_id: 456, servings: 2) {
    Ok(entries) -> {
      // Process each shopping list entry
      list.each(entries, fn(entry) {
        io.println("Item: " <> get_food_name(entry.food))
        io.println("Amount: " <> float.to_string(entry.amount))
        io.println("Checked: " <> bool.to_string(entry.checked))
      })
    }

    Error(client.NetworkError(msg)) -> {
      io.println("Network error: " <> msg)
      io.println("Check that Tandoor is running")
    }

    Error(client.NotFoundError(_)) -> {
      io.println("Recipe not found - check the recipe ID")
    }

    Error(client.AuthenticationError(_)) -> {
      io.println("Authentication failed - check your API token")
    }

    Error(other) -> {
      io.println("Unexpected error: " <> debug.format(other))
    }
  }
}
```

### Batch Adding Multiple Recipes

```gleam
pub fn add_multiple_recipes_to_shopping_list(
  config: ClientConfig,
  recipes: List(#(Int, Int))  // List of (recipe_id, servings) tuples
) -> Result(Int, TandoorError) {
  use total_items <- result.try(
    list.try_fold(recipes, 0, fn(total, recipe_info) {
      let #(recipe_id, servings) = recipe_info

      use entries <- result.try(
        recipe.add_recipe_to_shopping_list(config, recipe_id: recipe_id, servings: servings)
      )

      Ok(total + list.length(entries))
    })
  )

  Ok(total_items)
}

// Usage:
let recipes_to_add = [
  #(123, 4),  // Recipe 123, 4 servings
  #(456, 2),  // Recipe 456, 2 servings
  #(789, 6),  // Recipe 789, 6 servings
]

case add_multiple_recipes_to_shopping_list(config, recipes_to_add) {
  Ok(total) -> io.println("Added " <> int.to_string(total) <> " items total")
  Error(err) -> io.println("Error: " <> error_to_string(err))
}
```

## API Endpoint

**POST** `/api/shopping-list-recipe/`

### Request Body

```json
{
  "recipe": 123,
  "servings": 4
}
```

### Response

Returns an array of shopping list entries:

```json
[
  {
    "id": 1,
    "list_recipe": null,
    "food": 42,
    "unit": 5,
    "amount": 2.0,
    "order": 0,
    "checked": false,
    "ingredient": 789,
    "created_by": 1,
    "created_at": "2025-12-14T10:30:00Z",
    "updated_at": "2025-12-14T10:30:00Z",
    "completed_at": null,
    "delay_until": null
  },
  {
    "id": 2,
    "list_recipe": null,
    "food": 43,
    "unit": 6,
    "amount": 1.5,
    "order": 1,
    "checked": false,
    "ingredient": 790,
    "created_by": 1,
    "created_at": "2025-12-14T10:30:00Z",
    "updated_at": "2025-12-14T10:30:00Z",
    "completed_at": null,
    "delay_until": null
  }
]
```

## Related Types

### ShoppingListEntry

Defined in `meal_planner/tandoor/types/shopping/shopping_list_entry.gleam`:

```gleam
pub type ShoppingListEntry {
  ShoppingListEntry(
    id: ShoppingListEntryId,
    list_recipe: Option(ShoppingListId),
    food: Option(FoodId),
    unit: Option(UnitId),
    amount: Float,
    order: Int,
    checked: Bool,
    ingredient: Option(IngredientId),
    created_by: UserId,
    created_at: String,
    updated_at: String,
    completed_at: Option(String),
    delay_until: Option(String),
  )
}
```

## See Also

- [Shopping List Entry Types](../types/shopping_list_entry.md)
- [Client Configuration](../client/configuration.md)
- [Error Handling Guide](../guides/error_handling.md)
