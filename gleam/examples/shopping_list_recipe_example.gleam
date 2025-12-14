/// Example: Adding Recipes to Shopping List
///
/// This example demonstrates how to use the shopping list recipe API
/// to add recipe ingredients to your shopping list.
import gleam/io
import gleam/list
import meal_planner/tandoor/api/shopping/recipe
import meal_planner/tandoor/client

pub fn main() {
  io.println("=== Shopping List Recipe API Example ===\n")

  // 1. Configure the client
  let config =
    client.ClientConfig(
      base_url: "http://localhost:8000",
      auth: client.BearerAuth("your-api-token-here"),
      timeout_ms: 10_000,
      retry_on_transient: True,
      max_retries: 3,
    )

  // 2. Add a recipe to the shopping list
  io.println("Adding recipe #123 with 4 servings to shopping list...")

  case recipe.add_recipe_to_shopping_list(config, recipe_id: 123, servings: 4) {
    Ok(entries) -> {
      io.println("\n✓ Successfully added recipe to shopping list!")
      io.println(
        "Created "
        <> list.length(entries) |> fn(n) { n } |> int_to_string
        <> " shopping list entries:",
      )

      // Display each entry
      list.each(entries, fn(entry) {
        io.println(
          "  - Entry #"
          <> entry.id |> fn(_) { "???" }
          <> " | Amount: "
          <> entry.amount |> float_to_string
          <> " | Checked: "
          <> entry.checked |> bool_to_string,
        )
      })
    }

    Error(client.NetworkError(msg)) -> {
      io.println("✗ Network error: " <> msg)
      io.println("  Make sure Tandoor is running at http://localhost:8000")
    }

    Error(client.AuthenticationError(msg)) -> {
      io.println("✗ Authentication error: " <> msg)
      io.println("  Check your API token")
    }

    Error(client.NotFoundError(resource)) -> {
      io.println("✗ Not found: " <> resource)
      io.println("  Recipe #123 may not exist")
    }

    Error(client.BadRequestError(msg)) -> {
      io.println("✗ Bad request: " <> msg)
      io.println("  Check that recipe_id and servings are valid")
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
