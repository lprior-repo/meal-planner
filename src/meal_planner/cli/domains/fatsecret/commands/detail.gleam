/// FatSecret Detail Command
///
/// Handles the `mp fatsecret detail <FOOD_ID>` command to display
/// complete food details including all serving sizes and nutrition.
import gleam/option
import gleam/string
import meal_planner/cli/domains/fatsecret/formatters
import meal_planner/config.{type Config}
import meal_planner/env
import meal_planner/fatsecret/foods/client as foods_client
import meal_planner/fatsecret/foods/types as food_types

// ============================================================================
// Handler Function
// ============================================================================

/// Handler for `mp fatsecret detail <FOOD_ID>` command
///
/// Fetches complete food details from FatSecret API and displays:
/// - Food name and brand
/// - All available serving sizes
/// - Complete nutrition information per serving
pub fn detail_handler(
  config: Config,
  food_id_str: String,
) -> Result(Nil, String) {
  // Validate food ID is not empty
  case string.trim(food_id_str) {
    "" -> Error("Food ID is required. Usage: mp fatsecret detail <FOOD_ID>")
    trimmed_id -> {
      // Get FatSecret config from main config
      case config.external_services.fatsecret {
        option.None ->
          Error(
            "FatSecret API not configured. Please set credentials in config.",
          )
        option.Some(fs_config) -> {
          // Convert config.FatSecretConfig to env.FatSecretConfig format
          let env_config =
            env.FatSecretConfig(
              consumer_key: fs_config.consumer_key,
              consumer_secret: fs_config.consumer_secret,
            )

          // Create FoodId from string
          let food_id = food_types.food_id(trimmed_id)

          // Call FatSecret API
          case foods_client.get_food(env_config, food_id) {
            Ok(food) -> {
              formatters.display_food_details(food)
              Ok(Nil)
            }
            Error(error) -> {
              let error_msg = foods_client.error_to_string(error)
              Error("Failed to fetch food details: " <> error_msg)
            }
          }
        }
      }
    }
  }
}
