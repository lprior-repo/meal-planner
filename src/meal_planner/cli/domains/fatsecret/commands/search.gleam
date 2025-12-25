/// FatSecret Search Command
///
/// Handles the `mp fatsecret search --query "<QUERY>"` command to search
/// for foods by name and display results.
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import meal_planner/config.{type Config}
import meal_planner/env
import meal_planner/fatsecret/foods/client as foods_client
import meal_planner/fatsecret/foods/types as food_types

// ============================================================================
// Handler Function
// ============================================================================

/// Handler for food search via --query flag
pub fn search_handler(config: Config, search_query: String) -> Result(Nil, Nil) {
  // Check if FatSecret is configured
  case config.external_services.fatsecret {
    option.Some(fs_config) -> {
      // Convert config.FatSecretConfig to env.FatSecretConfig
      let fatsecret_config =
        env.FatSecretConfig(
          consumer_key: fs_config.consumer_key,
          consumer_secret: fs_config.consumer_secret,
        )

      // Call FatSecret API to search for foods
      case foods_client.search_foods_simple(fatsecret_config, search_query) {
        Ok(response) -> {
          display_search_results(response, search_query)
          Ok(Nil)
        }
        Error(err) -> {
          io.println(
            "Error searching FatSecret: " <> foods_client.error_to_string(err),
          )
          Error(Nil)
        }
      }
    }
    option.None -> {
      io.println(
        "Error: FatSecret API not configured. Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET",
      )
      Error(Nil)
    }
  }
}

// ============================================================================
// Display Functions
// ============================================================================

/// Display search results
fn display_search_results(
  response: food_types.FoodSearchResponse,
  query: String,
) -> Nil {
  // Display results header
  io.println(
    "Found "
    <> int.to_string(response.total_results)
    <> " results for: "
    <> query,
  )
  io.println("")

  // Display each food result
  list.each(response.foods, fn(food) {
    io.println("• " <> food.food_name)
    case food.brand_name {
      option.Some(brand) -> io.println("  Brand: " <> brand)
      option.None -> Nil
    }
    io.println("  ID: " <> food_types.food_id_to_string(food.food_id))
    io.println("  " <> food.food_description)
    io.println("")
  })
}
