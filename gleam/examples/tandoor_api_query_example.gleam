/// Example: Query Tandoor API for recipes
///
/// This example demonstrates how to use the meal planner with Tandoor recipes.
/// It shows how to configure the Tandoor connection and query recipes.
///
/// Prerequisites:
/// - Tandoor running on http://localhost:8000
/// - TANDOOR_API_TOKEN environment variable set
/// - Database configured and running
///
/// Usage:
/// ```bash
/// # Run the example
/// gleam run -m examples/tandoor_api_query_example
/// ```

import gleam/io
import gleam/list
import gleam/result

// Example 1: Configuration
//
// The TandoorConfig is loaded from environment variables:
// - TANDOOR_BASE_URL (default: http://localhost:8000)
// - TANDOOR_API_TOKEN (required for production, optional for development)
// - TANDOOR_CONNECT_TIMEOUT_MS (default: 5000ms)
// - TANDOOR_REQUEST_TIMEOUT_MS (default: 30000ms)
pub fn main() {
  io.println("=== Tandoor API Query Example ===\n")

  // In a real application, you would:
  // 1. Load config from environment
  // 2. Create a database connection
  // 3. Query Tandoor recipes
  // 4. Store recipe data locally for fast access

  io.println(
    "Example configuration structure:\n"
    <> "{\n"
    <> "  base_url: \"http://localhost:8000\",\n"
    <> "  api_token: \"your-token-here\",\n"
    <> "  connect_timeout_ms: 5000,\n"
    <> "  request_timeout_ms: 30000\n"
    <> "}\n",
  )

  // Example 2: Common Tandoor API endpoints
  io.println(
    "Common Tandoor API endpoints:\n"
    <> "  GET /api/recipes/ - List all recipes\n"
    <> "  GET /api/recipes/{id}/ - Get recipe by ID\n"
    <> "  GET /api/recipes/?search=chicken - Search recipes\n"
    <> "  POST /api/recipes/ - Create new recipe\n"
    <> "  PUT /api/recipes/{id}/ - Update recipe\n"
    <> "  DELETE /api/recipes/{id}/ - Delete recipe\n",
  )

  // Example 3: Recipe data structure
  io.println(
    "Example recipe response:\n"
    <> "{\n"
    <> "  \"id\": 1,\n"
    <> "  \"name\": \"Grilled Chicken Breast\",\n"
    <> "  \"author\": \"user@example.com\",\n"
    <> "  \"description\": \"Simple grilled chicken\",\n"
    <> "  \"servings\": 1,\n"
    <> "  \"servings_text\": \"1 breast\",\n"
    <> "  \"prep_time\": 5,\n"
    <> "  \"cook_time\": 15,\n"
    <> "  \"keywords\": [\"protein\", \"keto\"],\n"
    <> "  \"nutrition\": {\n"
    <> "    \"energy\": 165,\n"
    <> "    \"protein\": 31,\n"
    <> "    \"fat\": 3.6,\n"
    <> "    \"carbohydrates\": 0\n"
    <> "  }\n"
    <> "}\n",
  )

  // Example 4: Workflow for retrieving recipes
  io.println(
    "Workflow for retrieving Tandoor recipes:\n"
    <> "1. Connect to Tandoor API using config\n"
    <> "2. Get list of recipes with GET /api/recipes/\n"
    <> "3. For each recipe, fetch details with GET /api/recipes/{id}/\n"
    <> "4. Store recipe metadata in meal_planner database\n"
    <> "5. Cache nutritional information for fast lookups\n",
  )

  // Example 5: Error handling
  io.println(
    "Error handling considerations:\n"
    <> "- Network timeout: Retry with exponential backoff\n"
    <> "- 401 Unauthorized: Check TANDOOR_API_TOKEN\n"
    <> "- 404 Not Found: Recipe was deleted or ID invalid\n"
    <> "- 500 Server Error: Tandoor service issue, retry later\n",
  )

  io.println(
    "\nFor complete implementation examples, see:\n"
    <> "- tandoor_recipe_creation_example.gleam\n"
    <> "- tandoor_food_logging_example.gleam\n",
  )
}
