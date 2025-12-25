/// FatSecret Ingredients Command
///
/// Handles ingredient-related commands:
/// - Search for ingredients by name
/// - List recipe ingredients with nutrition
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/string
import meal_planner/cli/domains/fatsecret/formatters
import meal_planner/config.{type Config}
import meal_planner/env
import meal_planner/fatsecret/foods/client as foods_client
import meal_planner/fatsecret/foods/types as food_types
import meal_planner/fatsecret/recipes/client as recipes_client
import meal_planner/fatsecret/recipes/types as recipe_types

// ============================================================================
// Search Handler
// ============================================================================

/// Handler for `mp fatsecret ingredients <QUERY>` command
///
/// Searches for foods/ingredients and displays:
/// - Food name and brand
/// - Food ID for detailed lookup
/// - Basic nutrition description
pub fn ingredients_search_handler(
  config: Config,
  query: String,
) -> Result(Nil, String) {
  // Validate query is not empty
  case string.trim(query) {
    "" ->
      Error("Search query is required. Usage: mp fatsecret ingredients <QUERY>")
    trimmed_query -> {
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

          // Call FatSecret API to search for foods
          case foods_client.search_foods_simple(env_config, trimmed_query) {
            Ok(response) -> {
              display_ingredient_search_results(response, trimmed_query)
              Ok(Nil)
            }
            Error(error) -> {
              let error_msg = foods_client.error_to_string(error)
              Error("Failed to search foods: " <> error_msg)
            }
          }
        }
      }
    }
  }
}

// ============================================================================
// Recipe Ingredients Handler
// ============================================================================

/// Handler for listing recipe ingredients with nutrition info
///
/// Fetches recipe details from FatSecret API and displays:
/// - Recipe name and details
/// - List of ingredients with quantities
/// - Nutrition information per ingredient
/// - Total aggregated nutrition for the recipe
pub fn list_recipe_ingredients(
  config: Config,
  recipe_id recipe_id: Int,
) -> Result(Nil, String) {
  // Validate recipe ID
  case recipe_id <= 0 {
    True ->
      Error(
        "Recipe ID must be positive. Usage: mp fatsecret ingredients --id <RECIPE_ID>",
      )
    False -> {
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

          // Create RecipeId from int
          let recipe_id_type = recipe_types.recipe_id(int.to_string(recipe_id))

          // Call FatSecret API to get recipe details
          case recipes_client.get_recipe_parsed(env_config, recipe_id_type) {
            Ok(recipe) -> {
              formatters.display_recipe_ingredients(recipe)
              Ok(Nil)
            }
            Error(error) -> {
              let error_msg = foods_client.error_to_string(error)
              Error("Failed to fetch recipe details: " <> error_msg)
            }
          }
        }
      }
    }
  }
}

// ============================================================================
// Display Functions
// ============================================================================

/// Display ingredient search results
fn display_ingredient_search_results(
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
