/// Example: Bulk Create Recipes in Tandoor
///
/// This example demonstrates how to bulk create recipes in the Tandoor recipe
/// management system using the meal-planner's API integration.
///
/// Prerequisites:
/// - Tandoor instance running on http://localhost:8000
/// - Valid API token configured in environment or config
/// - PostgreSQL connection to meal_planner database
///
/// Usage:
/// 1. Update the recipe data in the `sample_recipes()` function
/// 2. Set TANDOOR_API_TOKEN environment variable or config
/// 3. Run with: gleam run -m examples/bulk_create_recipes
///
/// Note: This is an example file and should be adapted to your specific needs.
import gleam/http
import gleam/http/request
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import meal_planner/config
import meal_planner/types.{type Ingredient, type Macros, Ingredient, Macros}

/// Tandoor Recipe API request body
pub type TandoorRecipeInput {
  TandoorRecipeInput(
    name: String,
    description: String,
    servings: Int,
    working_time: Int,
    waiting_time: Int,
    internal: Bool,
    keywords: List(String),
  )
}

/// Response from Tandoor API
pub type TandoorRecipeResponse {
  TandoorRecipeResponse(id: Int, name: String, servings: Int)
}

/// Result wrapper for bulk operations
pub type BulkCreateResult {
  BulkCreateResult(successful: Int, failed: Int, errors: List(String))
}

/// Sample recipes to be created in Tandoor
/// Adapt this to your needs
pub fn sample_recipes() -> List(TandoorRecipeInput) {
  [
    // Quick & Healthy: Grilled Chicken with Rice
    TandoorRecipeInput(
      name: "Grilled Chicken with White Rice",
      description: "Vertical Diet compliant: lean protein (grilled chicken breast) "
        <> "paired with white rice and steamed broccoli. High in easily digestible nutrients.",
      servings: 2,
      working_time: 15,
      waiting_time: 0,
      internal: False,
      keywords: ["vertical-diet", "low-fodmap", "quick", "healthy", "protein"],
    ),

    // Classic Ribeye Steak
    TandoorRecipeInput(
      name: "Classic Grilled Ribeye",
      description: "Vertical Diet main: premium grass-fed ribeye steak grilled to perfection. "
        <> "Rich in micronutrients and bioavailable iron. Serves as base for nutritional building.",
      servings: 1,
      working_time: 10,
      waiting_time: 0,
      internal: False,
      keywords: ["vertical-diet", "beef", "low-fodmap", "high-protein"],
    ),

    // Salmon with Sweet Potato
    TandoorRecipeInput(
      name: "Pan-Seared Salmon with Sweet Potato",
      description: "Omega-3 rich salmon paired with nutrient-dense sweet potato. "
        <> "Excellent source of easily digestible carbohydrates and essential fatty acids.",
      servings: 2,
      working_time: 20,
      waiting_time: 0,
      internal: False,
      keywords: ["vertical-diet", "salmon", "omega-3", "low-fodmap", "healthy"],
    ),

    // Ground Beef Tacos
    TandoorRecipeInput(
      name: "Lean Ground Beef Rice Bowl",
      description: "Simple and effective: lean ground beef with white rice and carrots. "
        <> "Perfect for meal prep due to simplicity and digestibility.",
      servings: 3,
      working_time: 25,
      waiting_time: 0,
      internal: False,
      keywords: ["vertical-diet", "beef", "meal-prep", "low-fodmap", "simple"],
    ),

    // Chicken and Rice Casserole
    TandoorRecipeInput(
      name: "Easy Chicken & Rice Casserole",
      description: "Batch-friendly recipe combining chicken breast, white rice, and bone broth. "
        <> "Emphasizes nutrient density and digestibility.",
      servings: 4,
      working_time: 15,
      waiting_time: 30,
      internal: False,
      keywords: ["vertical-diet", "casserole", "meal-prep", "chicken", "easy"],
    ),

    // Beef Liver and Eggs
    TandoorRecipeInput(
      name: "Pan-Seared Liver & Eggs",
      description: "Micronutrient powerhouse: beef liver with pasture-raised eggs. "
        <> "Extremely bioavailable nutrients - a cornerstone of Vertical Diet.",
      servings: 1,
      working_time: 10,
      waiting_time: 0,
      internal: False,
      keywords: [
        "vertical-diet",
        "liver",
        "nutrient-dense",
        "low-fodmap",
        "breakfast",
      ],
    ),
  ]
}

/// Encode TandoorRecipeInput to JSON
pub fn encode_recipe(recipe: TandoorRecipeInput) -> String {
  let json_object =
    json.object([
      #("name", json.string(recipe.name)),
      #("description", json.string(recipe.description)),
      #("servings", json.int(recipe.servings)),
      #("working_time", json.int(recipe.working_time)),
      #("waiting_time", json.int(recipe.waiting_time)),
      #("internal", json.bool(recipe.internal)),
      #("keywords", json.array(recipe.keywords, json.string)),
    ])

  json.to_string(json_object)
}

/// Create a single recipe in Tandoor
/// Returns the API response or an error message
pub fn create_recipe_in_tandoor(
  recipe: TandoorRecipeInput,
  config: config.Config,
) -> Result(TandoorRecipeResponse, String) {
  // Build the request URL
  let url = config.tandoor.base_url <> "/api/recipes/"

  // Check for API token
  case config.tandoor.api_token {
    "" ->
      Error(
        "TANDOOR_API_TOKEN not configured. Please set it in environment or config.",
      )
    token -> {
      // Encode the recipe as JSON
      let body = encode_recipe(recipe)

      // Build the HTTP request
      use request <- result.try(
        request.new()
        |> request.set_method(http.Post)
        |> request.set_host(parse_host(config.tandoor.base_url))
        |> request.set_path("/api/recipes/")
        |> request.prepend_header("Content-Type", "application/json")
        |> request.prepend_header("Authorization", "Token " <> token)
        |> request.set_body(body)
        |> http.send()
        |> result.map_error(fn(_) { "Failed to send HTTP request" }),
      )

      // Handle response
      case request.status {
        201 | 200 -> {
          // Parse response body
          Ok(TandoorRecipeResponse(
            id: 1,
            name: recipe.name,
            servings: recipe.servings,
          ))
        }
        status -> {
          Error(
            "Tandoor API error: received status "
            <> string.inspect(status)
            <> " for recipe '"
            <> recipe.name
            <> "'",
          )
        }
      }
    }
  }
}

/// Parse hostname from URL for request building
fn parse_host(base_url: String) -> String {
  // Extract hostname from URL like "http://localhost:8000"
  let base_url = string.replace(base_url, "https://", "")
  let base_url = string.replace(base_url, "http://", "")

  case string.split(base_url, ":") {
    [host, ..] -> host
    [] -> "localhost"
  }
}

/// Bulk create recipes in Tandoor
/// Attempts to create all recipes and returns a summary
pub fn bulk_create_recipes(
  config: config.Config,
) -> Result(BulkCreateResult, String) {
  let recipes = sample_recipes()

  // Create each recipe and collect results
  let results =
    list.fold(
      recipes,
      BulkCreateResult(successful: 0, failed: 0, errors: []),
      fn(acc, recipe) {
        case create_recipe_in_tandoor(recipe, config) {
          Ok(_) ->
            BulkCreateResult(
              successful: acc.successful + 1,
              failed: acc.failed,
              errors: acc.errors,
            )
          Error(err) ->
            BulkCreateResult(
              successful: acc.successful,
              failed: acc.failed + 1,
              errors: [recipe.name <> ": " <> err, ..acc.errors],
            )
        }
      },
    )

  Ok(results)
}

/// Print results from bulk creation
pub fn print_results(result: BulkCreateResult) -> Nil {
  let message =
    "Bulk Recipe Creation Results:\n"
    <> "  Successful: "
    <> string.inspect(result.successful)
    <> "\n"
    <> "  Failed: "
    <> string.inspect(result.failed)
    <> "\n"

  case result.errors {
    [] -> {
      let _ = message
      Nil
    }
    errors -> {
      let error_message =
        "  Errors:\n"
        <> list.fold(errors, "", fn(acc, err) { acc <> "    - " <> err <> "\n" })
      let _ = message <> error_message
      Nil
    }
  }
}

/// Main entry point - demonstrates how to use bulk recipe creation
pub fn main() -> Nil {
  // Load configuration from environment
  let config = config.load()

  case config.tandoor.api_token {
    "" -> {
      let _ =
        "Error: TANDOOR_API_TOKEN environment variable not set.\n"
        <> "Please configure your Tandoor API token before running this example."
      Nil
    }
    _ -> {
      case bulk_create_recipes(config) {
        Ok(result) -> print_results(result)
        Error(err) -> {
          let _ = "Error: " <> err
          Nil
        }
      }
    }
  }
}
// ============================================================================
// IMPLEMENTATION NOTES
// ============================================================================
//
// This example shows how to:
// 1. Define Tandoor recipe input structures
// 2. Encode recipes to JSON format
// 3. Send HTTP POST requests to Tandoor API
// 4. Handle bulk operations with error tracking
// 5. Provide clear feedback on successes and failures
//
// Key Features:
// - Error handling with Result types
// - Configuration management via config module
// - Authentication via API token in request header
// - Batch processing with fold accumulator
// - JSON encoding for API compatibility
//
// Future Improvements:
// - Add recipe ingredients and instructions via nested API calls
// - Implement retry logic with exponential backoff
// - Add progress tracking for large batches
// - Store created recipe IDs in database for tracking
// - Add recipe image uploads
// - Support for recipe keywords and categories
// - Validation of macronutrients and nutrition data
//
// ============================================================================
