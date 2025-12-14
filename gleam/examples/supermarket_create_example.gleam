/// Example usage of the Supermarket Create API
///
/// This demonstrates how to create a new supermarket using the Tandoor SDK.
import gleam/io
import gleam/option
import meal_planner/tandoor/api/supermarket/create
import meal_planner/tandoor/client
import meal_planner/tandoor/types/supermarket/supermarket_create.{
  SupermarketCreateRequest,
}

pub fn main() {
  // 1. Configure the Tandoor client
  let config = client.bearer_config("http://localhost:8000", "your-api-token")

  // 2. Create a supermarket request with name and description
  let request =
    SupermarketCreateRequest(
      name: "Whole Foods Market",
      description: option.Some("Natural and organic grocery store"),
    )

  // 3. Send the create request
  case create.create_supermarket(config, request) {
    Ok(supermarket) -> {
      io.println("Successfully created supermarket!")
      io.println("ID: " <> int.to_string(supermarket.id))
      io.println("Name: " <> supermarket.name)
    }
    Error(error) -> {
      io.println("Failed to create supermarket:")
      io.println(client.error_to_string(error))
    }
  }
}
