/// Example: Listing Shopping List Entries
///
/// This example demonstrates how to use the shopping list entry list API
/// to retrieve and filter shopping list entries with pagination.
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import meal_planner/tandoor/api/shopping/list as shopping_list
import meal_planner/tandoor/client

pub fn main() {
  io.println("=== Shopping List Entry List API Example ===\n")

  // 1. Configure the client
  let config =
    client.ClientConfig(
      base_url: "http://localhost:8000",
      auth: client.BearerAuth("your-api-token-here"),
      timeout_ms: 10_000,
      retry_on_transient: True,
      max_retries: 3,
    )

  // 2. List all shopping list entries (first page, default page size)
  io.println("Fetching all shopping list entries...")
  case
    shopping_list.list_shopping_entries(
      config,
      checked: None,
      limit: None,
      offset: None,
    )
  {
    Ok(response) -> {
      io.println(
        "\n✓ Found " <> int.to_string(response.count) <> " total entries",
      )
      io.println("Retrieved " <> int.to_string(list.length(response.results)) <> " entries on this page\n")

      // Display each entry
      list.each(response.results, fn(entry) {
        let food_name = case entry.food {
          Some(food) -> food.name
          None -> "(no food)"
        }
        let unit_name = case entry.unit {
          Some(unit) -> unit.name
          None -> ""
        }
        let checked_str = case entry.checked {
          True -> "✓"
          False -> "○"
        }

        io.println(
          checked_str
          <> " Entry #"
          <> int.to_string(entry.id)
          <> ": "
          <> float_to_string(entry.amount)
          <> " "
          <> unit_name
          <> " "
          <> food_name,
        )
      })

      // Show pagination info
      case response.next {
        Some(_) -> io.println("\n→ More entries available (use offset to paginate)")
        None -> io.println("\n(End of list)")
      }
    }

    Error(client.NetworkError(msg)) -> {
      io.println("✗ Network error: " <> msg)
      io.println("  Make sure Tandoor is running at http://localhost:8000")
    }

    Error(client.AuthenticationError(msg)) -> {
      io.println("✗ Authentication error: " <> msg)
      io.println("  Check your API token")
    }

    Error(_other) -> {
      io.println("✗ Unexpected error occurred")
    }
  }

  // 3. List only unchecked items with pagination
  io.println("\n--- Fetching unchecked items only (limit 10) ---")
  case
    shopping_list.list_shopping_entries(
      config,
      checked: Some(False),
      limit: Some(10),
      offset: Some(0),
    )
  {
    Ok(response) -> {
      io.println(
        "\n✓ Found "
        <> int.to_string(list.length(response.results))
        <> " unchecked items",
      )

      list.each(response.results, fn(entry) {
        let food_name = case entry.food {
          Some(food) -> food.name
          None -> "(no food)"
        }
        io.println("  ○ " <> food_name)
      })
    }

    Error(_) -> io.println("✗ Failed to fetch unchecked items")
  }

  io.println("\n=== Example Complete ===")
}

// Helper function to format floats
fn float_to_string(f: Float) -> String {
  // Simple float formatting (Gleam doesn't have built-in float->string)
  // In production, use a proper formatting library
  case f {
    0.0 -> "0"
    1.0 -> "1"
    2.0 -> "2"
    3.0 -> "3"
    _ -> int.to_string(float_round(f))
  }
}

// Simple rounding helper
fn float_round(f: Float) -> Int {
  case f >=. 0.0 {
    True -> float_truncate(f +. 0.5)
    False -> float_truncate(f -. 0.5)
  }
}

@external(erlang, "erlang", "trunc")
fn float_truncate(f: Float) -> Int
