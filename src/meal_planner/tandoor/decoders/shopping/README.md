# Shopping List Decoders

Decoders for Tandoor Shopping List API responses.

## Usage

### Decode a Single Shopping List Entry

```gleam
import gleam/json
import meal_planner/tandoor/decoders/shopping/shopping_list_entry_decoder

let json_str = "{
  \"id\": 1,
  \"list_recipe\": 5,
  \"food\": {
    \"id\": 10,
    \"name\": \"Tomato\",
    \"plural_name\": \"Tomatoes\",
    \"description\": \"Fresh red tomatoes\",
    \"recipe\": null,
    \"food_onhand\": true,
    \"supermarket_category\": null,
    \"ignore_shopping\": false
  },
  \"unit\": {
    \"id\": 2,
    \"name\": \"piece\",
    \"plural_name\": \"pieces\",
    \"description\": null,
    \"base_unit\": null,
    \"open_data_slug\": null
  },
  \"amount\": 3.0,
  \"order\": 0,
  \"checked\": false,
  \"created_at\": \"2025-12-14T12:00:00Z\",
  \"completed_at\": null
}"

case json.decode(from: json_str, using: shopping_list_entry_decoder.decode_entry()) {
  Ok(entry) -> {
    // Access entry fields
    entry.id        // 1
    entry.amount    // 3.0
    entry.checked   // false

    // Access nested food
    case entry.food {
      Some(food) -> food.name  // "Tomato"
      None -> "No food"
    }
  }
  Error(_) -> // Handle error
}
```

### Decode a List of Entries (Paginated Response)

```gleam
import gleam/json
import meal_planner/tandoor/decoders/shopping/shopping_list_entry_decoder

let json_str = "{
  \"results\": [
    { \"id\": 1, \"amount\": 2.0, ... },
    { \"id\": 2, \"amount\": 1.0, ... }
  ]
}"

case json.decode(from: json_str, using: shopping_list_entry_decoder.decode_entry_list()) {
  Ok(entries) -> {
    // Process list of entries
    list.length(entries)  // 2
  }
  Error(_) -> // Handle error
}
```

## Response Type

The decoder returns `ShoppingListEntryResponse` which differs from the internal `ShoppingListEntry` type:

- **ShoppingListEntryResponse**: Contains nested `Food` and `Unit` objects (matches API)
- **ShoppingListEntry**: Uses `FoodId` and `UnitId` (for internal storage)

This separation allows proper handling of the API response format while maintaining clean internal types.

## Fields

### Required Fields
- `id: Int` - Entry ID
- `amount: Float` - Quantity
- `order: Int` - Display order
- `checked: Bool` - Completion status
- `created_at: String` - ISO 8601 timestamp

### Optional Fields
- `list_recipe: Option(Int)` - Associated shopping list recipe ID
- `food: Option(Food)` - Nested food object
- `unit: Option(Unit)` - Nested unit object
- `completed_at: Option(String)` - Completion timestamp

## See Also

- `src/meal_planner/tandoor/decoders/food/food_decoder.gleam` - Food decoder
- `src/meal_planner/tandoor/decoders/unit/unit_decoder.gleam` - Unit decoder
- `test/tandoor/decoders/shopping/shopping_list_entry_decoder_test.gleam` - Test examples
