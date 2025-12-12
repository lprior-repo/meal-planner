/// Example: Create recipes in Tandoor and log nutritional data
///
/// This example demonstrates how to create recipes in Tandoor via the API
/// and track the nutritional information in the meal planner database.
///
/// Prerequisites:
/// - Tandoor running on http://localhost:8000
/// - TANDOOR_API_TOKEN environment variable set
/// - Database configured and running
///
/// Usage:
/// ```bash
/// # Run the example
/// gleam run -m examples/tandoor_recipe_creation_example
/// ```

import gleam/io
import gleam/list

// Example 1: Create Recipe Request Structure
//
// POST /api/recipes/
pub fn example_create_recipe_request() {
  io.println("=== Create Recipe in Tandoor Example ===\n")

  // Request body for creating a new recipe
  io.println(
    "Example request to create a recipe:\n"
    <> "POST http://localhost:8000/api/recipes/\n"
    <> "Authorization: Token {TANDOOR_API_TOKEN}\n"
    <> "Content-Type: application/json\n\n"
    <> "{\n"
    <> "  \"name\": \"High-Protein Breakfast Bowl\",\n"
    <> "  \"description\": \"Eggs, bacon, and vegetables\",\n"
    <> "  \"keywords\": [\"breakfast\", \"protein\", \"low-carb\"],\n"
    <> "  \"prep_time\": 10,\n"
    <> "  \"cook_time\": 15,\n"
    <> "  \"servings\": 1,\n"
    <> "  \"servings_text\": \"1 bowl\",\n"
    <> "  \"steps\": [\n"
    <> "    {\n"
    <> "      \"step\": 1,\n"
    <> "      \"instruction\": \"Cook bacon until crispy\",\n"
    <> "      \"ingredients\": []\n"
    <> "    },\n"
    <> "    {\n"
    <> "      \"step\": 2,\n"
    <> "      \"instruction\": \"Scramble 3 eggs\",\n"
    <> "      \"ingredients\": []\n"
    <> "    }\n"
    <> "  ],\n"
    <> "  \"nutrition\": {\n"
    <> "    \"energy\": 450,\n"
    <> "    \"protein\": 35,\n"
    <> "    \"fat\": 30,\n"
    <> "    \"carbohydrates\": 5\n"
    <> "  }\n"
    <> "}\n",
  )

  io.println(
    "Example response:\n"
    <> "{\n"
    <> "  \"id\": 42,\n"
    <> "  \"name\": \"High-Protein Breakfast Bowl\",\n"
    <> "  \"slug\": \"high-protein-breakfast-bowl\",\n"
    <> "  \"author\": \"user@example.com\",\n"
    <> "  \"servings\": 1,\n"
    <> "  \"created_at\": \"2025-12-12T10:30:00Z\",\n"
    <> "  \"updated_at\": \"2025-12-12T10:30:00Z\"\n"
    <> "}\n",
  )
}

// Example 2: Update existing recipe
pub fn example_update_recipe_request() {
  io.println("\n=== Update Recipe in Tandoor Example ===\n")

  io.println(
    "Example request to update a recipe:\n"
    <> "PUT http://localhost:8000/api/recipes/42/\n"
    <> "Authorization: Token {TANDOOR_API_TOKEN}\n"
    <> "Content-Type: application/json\n\n"
    <> "{\n"
    <> "  \"name\": \"Enhanced Breakfast Bowl\",\n"
    <> "  \"description\": \"Eggs, bacon, and roasted vegetables\",\n"
    <> "  \"servings\": 1,\n"
    <> "  \"nutrition\": {\n"
    <> "    \"energy\": 520,\n"
    <> "    \"protein\": 35,\n"
    <> "    \"fat\": 35,\n"
    <> "    \"carbohydrates\": 15\n"
    <> "  }\n"
    <> "}\n",
  )
}

// Example 3: Batch create recipes
pub fn example_batch_create_recipes() {
  io.println("\n=== Batch Create Recipes Example ===\n")

  let recipes = [
    #("Chicken Stir Fry", 350, 28.0, 12.0, 35.0),
    #("Salmon with Asparagus", 420, 40.0, 25.0, 8.0),
    #("Beef and Broccoli", 480, 35.0, 28.0, 18.0),
    #("Turkey Burger", 380, 38.0, 20.0, 12.0),
  ]

  io.println("Workflow for batch creating recipes:\n")

  let _ =
    list.map(recipes, fn(recipe) {
      let #(name, energy, protein, fat, carbs) = recipe
      io.println(
        "Recipe: "
        <> name
        <> "\n  Energy: "
        <> int.to_string(energy)
        <> " kcal\n"
        <> "  Protein: "
        <> float.to_string(protein)
        <> "g\n"
        <> "  Fat: "
        <> float.to_string(fat)
        <> "g\n"
        <> "  Carbs: "
        <> float.to_string(carbs)
        <> "g\n",
      )
      Nil
    })

  io.println(
    "Implementation notes:\n"
    <> "1. Create a list of recipe definitions\n"
    <> "2. For each recipe, make a POST request to /api/recipes/\n"
    <> "3. Collect response IDs for later reference\n"
    <> "4. Store recipe metadata in meal_planner database\n"
    <> "5. Use concurrent requests for faster processing\n",
  )
}

// Example 4: Retrieve and sync recipes
pub fn example_sync_recipes_workflow() {
  io.println("\n=== Sync Recipes from Tandoor Example ===\n")

  io.println(
    "Step 1: Get all recipes\n"
    <> "GET http://localhost:8000/api/recipes/?limit=100&offset=0\n"
    <> "Response: List of recipes with pagination\n\n"
    <> "Step 2: For each recipe, fetch full details\n"
    <> "GET http://localhost:8000/api/recipes/{id}/\n"
    <> "Response: Complete recipe with nutrition\n\n"
    <> "Step 3: Store in meal_planner database\n"
    <> "INSERT INTO recipes (\n"
    <> "  tandoor_id, name, slug, protein, fat, carbs, servings\n"
    <> ") VALUES (...)\n\n"
    <> "Step 4: Use cached data for fast lookups\n"
    <> "SELECT * FROM recipes WHERE tandoor_id = $1\n",
  )
}

// Example 5: Error handling for recipe creation
pub fn example_error_handling() {
  io.println("\n=== Error Handling for Recipe Operations ===\n")

  io.println(
    "Common errors when creating recipes:\n\n"
    <> "401 Unauthorized\n"
    <> "  Cause: Invalid or missing TANDOOR_API_TOKEN\n"
    <> "  Solution: Check token is set in environment\n\n"
    <> "400 Bad Request\n"
    <> "  Cause: Invalid recipe data (missing fields, invalid format)\n"
    <> "  Solution: Validate all required fields before sending\n\n"
    <> "409 Conflict\n"
    <> "  Cause: Recipe with same name already exists\n"
    <> "  Solution: Check if recipe exists before creating\n\n"
    <> "500 Internal Server Error\n"
    <> "  Cause: Tandoor service error\n"
    <> "  Solution: Retry with exponential backoff\n\n"
    <> "Network Timeout\n"
    <> "  Cause: Request took too long\n"
    <> "  Solution: Increase timeout or check network\n",
  )
}

pub fn main() {
  example_create_recipe_request()
  example_update_recipe_request()
  example_batch_create_recipes()
  example_sync_recipes_workflow()
  example_error_handling()

  io.println(
    "\n=== Implementation Summary ===\n"
    <> "To implement recipe creation in your application:\n\n"
    <> "1. Load TandoorConfig from environment variables\n"
    <> "2. Create HTTP client with proper timeout configuration\n"
    <> "3. Implement request/response handling for recipes\n"
    <> "4. Store recipes in PostgreSQL for offline access\n"
    <> "5. Handle errors gracefully with retries\n"
    <> "6. Use concurrent requests for batch operations\n"
    <> "7. Cache nutrition data for performance\n",
  )
}
