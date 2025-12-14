/// Example: Creating Shopping List Entries
///
/// This example demonstrates how to use the shopping list entry create API
/// to add individual items to your shopping list.
import gleam/io
import gleam/option.{None, Some}
import meal_planner/tandoor/api/shopping/create
import meal_planner/tandoor/client
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types/shopping/shopping_list_entry.{
  ShoppingListEntryCreate,
}

pub fn main() {
  io.println("=== Shopping List Entry Create API Example ===\n")

  // 1. Configure the client
  let config =
    client.ClientConfig(
      base_url: "http://localhost:8000",
      auth: client.BearerAuth("your-api-token-here"),
      timeout_ms: 10_000,
      retry_on_transient: True,
      max_retries: 3,
    )

  // 2. Create a shopping list entry
  io.println("Creating new shopping list entry...")

  let entry_data =
    ShoppingListEntryCreate(
      list_recipe: Some(ids.shopping_list_id(1)),
      food: Some(ids.food_id(42)),
      unit: None,
      amount: 2.5,
      order: 0,
      checked: False,
      ingredient: None,
      completed_at: None,
      delay_until: None,
      mealplan_id: Some(10),
    )

  case create.create_shopping_list_entry(config, entry_data) {
    Ok(entry) -> {
      io.println("\n✓ Successfully created shopping list entry!")
      io.println("Entry details:")
      io.println("  - Amount: " <> float_to_string(entry.amount))
      io.println("  - Order: " <> int_to_string(entry.order))
      io.println("  - Checked: " <> bool_to_string(entry.checked))
      io.println("  - Created at: " <> entry.created_at)
    }

    Error(client.NetworkError(msg)) -> {
      io.println("✗ Network error: " <> msg)
      io.println("  Make sure Tandoor is running at http://localhost:8000")
    }

    Error(client.AuthenticationError(msg)) -> {
      io.println("✗ Authentication error: " <> msg)
      io.println("  Check your API token")
    }

    Error(client.BadRequestError(msg)) -> {
      io.println("✗ Bad request: " <> msg)
      io.println("  Check that all fields are valid")
    }

    Error(_other) -> {
      io.println("✗ Unexpected error occurred")
    }
  }

  io.println("\n=== Example Complete ===")
}

// Helper functions for display (simplified for example)
fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    _ -> "many"
  }
}

fn float_to_string(_f: Float) -> String {
  "?.??"
}

fn bool_to_string(b: Bool) -> String {
  case b {
    True -> "yes"
    False -> "no"
  }
}
