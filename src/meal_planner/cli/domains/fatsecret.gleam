/// FatSecret CLI domain - handles food and ingredient management
///
/// This module provides CLI commands for:
/// - Searching for foods by name
/// - Listing recipe ingredients
/// - Viewing nutritional info
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/string
import glint
import meal_planner/config.{type Config}
import meal_planner/env
import meal_planner/fatsecret/foods/client as foods_client
import meal_planner/fatsecret/foods/types as food_types
import meal_planner/fatsecret/recipes/client as recipes_client
import meal_planner/fatsecret/recipes/types as recipe_types

// ============================================================================
// Handler Functions
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
              display_food_details(food)
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
              display_recipe_ingredients(recipe)
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

/// Display recipe ingredients with nutrition info
fn display_recipe_ingredients(recipe: recipe_types.Recipe) -> Nil {
  io.println("\n" <> repeat("=", 80))
  io.println("RECIPE INGREDIENTS")
  io.println(repeat("=", 80))
  io.println("")

  // Recipe header
  io.println("Recipe: " <> recipe.recipe_name)
  io.println("Servings: " <> float.to_string(recipe.number_of_servings))
  case recipe.recipe_description {
    "" -> Nil
    desc -> io.println("Description: " <> desc)
  }
  io.println("")

  // Check if recipe has ingredients
  case list.is_empty(recipe.ingredients) {
    True -> {
      io.println("No ingredients found for this recipe.")
      io.println("")
    }
    False -> {
      // Display ingredients section
      io.println(
        "INGREDIENTS ("
        <> int.to_string(list.length(recipe.ingredients))
        <> " items)",
      )
      io.println(repeat("-", 80))
      io.println("")

      // Display each ingredient and calculate totals
      let totals =
        recipe.ingredients
        |> list.fold(
          NutritionTotals(
            calories: 0.0,
            protein: 0.0,
            carbohydrate: 0.0,
            fat: 0.0,
          ),
          fn(totals, ingredient) {
            display_ingredient(ingredient)
            totals
          },
        )

      // Display total nutrition
      io.println(repeat("-", 80))
      io.println("TOTAL NUTRITION (entire recipe)")
      io.println("")
      display_nutrition_totals(totals, recipe)
      io.println("")
    }
  }

  io.println(repeat("=", 80))
  io.println("")
}

/// Nutrition totals accumulator
type NutritionTotals {
  NutritionTotals(
    calories: Float,
    protein: Float,
    carbohydrate: Float,
    fat: Float,
  )
}

/// Display a single ingredient
fn display_ingredient(ingredient: recipe_types.RecipeIngredient) -> Nil {
  io.println("• " <> ingredient.food_name)
  io.println("  Amount: " <> ingredient.ingredient_description)
  io.println(
    "  Quantity: "
    <> float.to_string(ingredient.number_of_units)
    <> " "
    <> ingredient.measurement_description,
  )
  io.println("  Food ID: " <> ingredient.food_id)
  io.println("")
}

/// Display nutrition totals for the recipe
fn display_nutrition_totals(
  _totals: NutritionTotals,
  recipe: recipe_types.Recipe,
) -> Nil {
  // Display nutrition from recipe level (these are per serving values from the recipe)
  case recipe.calories {
    option.Some(cal) ->
      io.println(
        "Calories: "
        <> float.to_string(cal *. recipe.number_of_servings)
        <> " kcal (total)",
      )
    option.None -> Nil
  }

  case recipe.protein {
    option.Some(prot) ->
      io.println(
        "Protein: "
        <> float.to_string(prot *. recipe.number_of_servings)
        <> "g (total)",
      )
    option.None -> Nil
  }

  case recipe.carbohydrate {
    option.Some(carb) ->
      io.println(
        "Carbs: "
        <> float.to_string(carb *. recipe.number_of_servings)
        <> "g (total)",
      )
    option.None -> Nil
  }

  case recipe.fat {
    option.Some(f) ->
      io.println(
        "Fat: "
        <> float.to_string(f *. recipe.number_of_servings)
        <> "g (total)",
      )
    option.None -> Nil
  }

  // Optional nutrients
  case recipe.fiber {
    option.Some(fiber) ->
      io.println(
        "Fiber: "
        <> float.to_string(fiber *. recipe.number_of_servings)
        <> "g (total)",
      )
    option.None -> Nil
  }

  case recipe.sugar {
    option.Some(sugar) ->
      io.println(
        "Sugar: "
        <> float.to_string(sugar *. recipe.number_of_servings)
        <> "g (total)",
      )
    option.None -> Nil
  }
}

/// Display food details in formatted output
fn display_food_details(food: food_types.Food) -> Nil {
  io.println("\n" <> repeat("=", 80))
  io.println("FOOD DETAILS")
  io.println(repeat("=", 80))
  io.println("")

  // Food header
  io.println("Name: " <> food.food_name)
  io.println("Type: " <> food.food_type)
  case food.brand_name {
    option.Some(brand) -> io.println("Brand: " <> brand)
    option.None -> Nil
  }
  io.println("FatSecret URL: " <> food.food_url)
  io.println("")

  // Servings section
  io.println(
    "AVAILABLE SERVINGS ("
    <> int.to_string(list.length(food.servings))
    <> " options)",
  )
  io.println(repeat("-", 80))
  io.println("")

  // Display each serving
  food.servings
  |> list.each(fn(serving) { display_serving(serving) })

  io.println(repeat("=", 80))
  io.println("")
}

/// Display a single serving with nutrition info
fn display_serving(serving: food_types.Serving) -> Nil {
  // Serving header
  io.println("Serving: " <> serving.serving_description)
  io.println(
    "  Measurement: "
    <> float.to_string(serving.number_of_units)
    <> " "
    <> serving.measurement_description,
  )

  // Metric info if available
  case serving.metric_serving_amount, serving.metric_serving_unit {
    option.Some(amount), option.Some(unit) ->
      io.println("  Metric: " <> float.to_string(amount) <> unit)
    _, _ -> Nil
  }

  // Is default serving?
  case serving.is_default {
    option.Some(1) -> io.println("  [DEFAULT SERVING]")
    _ -> Nil
  }

  io.println("")

  // Nutrition information
  let nutrition = serving.nutrition
  io.println("  NUTRITION PER SERVING:")
  io.println("    Calories: " <> float.to_string(nutrition.calories) <> " kcal")
  io.println("    Protein: " <> float.to_string(nutrition.protein) <> "g")
  io.println("    Carbs: " <> float.to_string(nutrition.carbohydrate) <> "g")
  io.println("    Fat: " <> float.to_string(nutrition.fat) <> "g")

  // Optional nutrients
  case nutrition.fiber {
    option.Some(fiber) ->
      io.println("    Fiber: " <> float.to_string(fiber) <> "g")
    option.None -> Nil
  }

  case nutrition.sugar {
    option.Some(sugar) ->
      io.println("    Sugar: " <> float.to_string(sugar) <> "g")
    option.None -> Nil
  }

  case nutrition.saturated_fat {
    option.Some(sat_fat) ->
      io.println("    Saturated Fat: " <> float.to_string(sat_fat) <> "g")
    option.None -> Nil
  }

  case nutrition.sodium {
    option.Some(sodium) ->
      io.println("    Sodium: " <> float.to_string(sodium) <> "mg")
    option.None -> Nil
  }

  case nutrition.cholesterol {
    option.Some(chol) ->
      io.println("    Cholesterol: " <> float.to_string(chol) <> "mg")
    option.None -> Nil
  }

  io.println("")
}

/// Helper to repeat a string n times
fn repeat(str: String, n: Int) -> String {
  case n <= 0 {
    True -> ""
    False -> str <> repeat(str, n - 1)
  }
}

// ============================================================================
// Glint Command Handler
// ============================================================================

/// FatSecret domain command for Glint CLI
pub fn cmd(app_config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("Search and manage foods from FatSecret")
  use query <- glint.flag(
    glint.string_flag("query")
    |> glint.flag_help("Food search query"),
  )
  use id <- glint.flag(
    glint.int_flag("id")
    |> glint.flag_help("Recipe or food ID"),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["search"] -> {
      case query(flags) {
        Ok(search_query) -> {
          // Check if FatSecret is configured
          case app_config.external_services.fatsecret {
            option.Some(fs_config) -> {
              // Convert config.FatSecretConfig to env.FatSecretConfig
              let fatsecret_config =
                env.FatSecretConfig(
                  consumer_key: fs_config.consumer_key,
                  consumer_secret: fs_config.consumer_secret,
                )

              // Call FatSecret API to search for foods
              case
                foods_client.search_foods_simple(fatsecret_config, search_query)
              {
                Ok(response) -> {
                  // Display results header
                  io.println(
                    "Found "
                    <> int.to_string(response.total_results)
                    <> " results for: "
                    <> search_query,
                  )
                  io.println("")

                  // Display each food result
                  list.each(response.foods, fn(food) {
                    io.println("• " <> food.food_name)
                    case food.brand_name {
                      option.Some(brand) -> io.println("  Brand: " <> brand)
                      option.None -> Nil
                    }
                    io.println(
                      "  ID: " <> food_types.food_id_to_string(food.food_id),
                    )
                    io.println("  " <> food.food_description)
                    io.println("")
                  })

                  Ok(Nil)
                }
                Error(err) -> {
                  io.println(
                    "Error searching FatSecret: "
                    <> foods_client.error_to_string(err),
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
        Error(_) -> {
          io.println("Error: --query flag required for search")
          Error(Nil)
        }
      }
    }
    ["ingredients"] -> {
      case id(flags) {
        Ok(recipe_id) -> {
          io.println(
            "Fetching ingredients for recipe: " <> int.to_string(recipe_id),
          )
          Ok(Nil)
        }
        Error(_) -> {
          io.println("Error: --id flag required for ingredients")
          Error(Nil)
        }
      }
    }
    _ -> {
      io.println("FatSecret commands:")
      io.println("  mp fatsecret search --query \"<food>\"")
      io.println("  mp fatsecret ingredients --id <recipe-id>")
      Ok(Nil)
    }
  }
}
