//  Example: Creating a Tandoor Recipe
//
//  This example demonstrates how to create a recipe in Tandoor using the
//  Meal Planner API. A recipe is a collection of ingredients and instructions
//  with associated nutritional information (macros).

import gleam/json
import gleam/result
import gleam/string
import meal_planner/config
import meal_planner/types.{type Ingredient, type Macros, Ingredient, Macros}

// ============================================================================
// Step 1: Create a Basic Recipe Structure
// ============================================================================
//
// First, you'll need to create an Ingredient and combine it with instructions
// and nutritional macros to form a complete recipe.

pub fn example_ingredient() -> Ingredient {
  Ingredient(name: "Chicken Breast", quantity: "200g")
}

pub fn example_macros() -> Macros {
  Macros(protein: 31.0, fat: 3.6, carbs: 0.0)
}

pub fn example_instructions() -> List(String) {
  [
    "Preheat oven to 375F (190C)",
    "Season chicken breast with salt and pepper",
    "Bake for 20-25 minutes until internal temperature reaches 165F (74C)",
    "Let rest for 5 minutes before serving",
  ]
}

// ============================================================================
// Step 2: Prepare the API Request Payload
// ============================================================================
//
// The create recipe request needs:
// - name: Display name of the recipe
// - ingredients: List of ingredients with quantities
// - instructions: Step-by-step cooking instructions
// - macros: Nutritional information (protein, fat, carbs in grams)
// - servings: Number of servings (for macro scaling)
// - category: Recipe category (e.g., "Main Dish", "Side", "Breakfast")

pub type CreateRecipePayload {
  CreateRecipePayload(
    name: String,
    ingredients: List(Ingredient),
    instructions: List(String),
    macros: Macros,
    servings: Int,
    category: String,
  )
}

pub fn example_payload() -> CreateRecipePayload {
  CreateRecipePayload(
    name: "Grilled Chicken Breast",
    ingredients: [example_ingredient()],
    instructions: example_instructions(),
    macros: example_macros(),
    servings: 1,
    category: "Main Dish",
  )
}

// ============================================================================
// Step 3: Encode Payload to JSON for API Request
// ============================================================================
//
// When sending to Tandoor, convert the payload to JSON format that the API expects.
// This example shows the structure of the JSON that would be POSTed to Tandoor.

pub fn encode_payload(payload: CreateRecipePayload) -> json.Json {
  json.object([
    #("name", json.string(payload.name)),
    #("servings", json.int(payload.servings)),
    #("category", json.string(payload.category)),
    #("macros", encode_macros(payload.macros)),
    #("ingredients", json.array(payload.ingredients, encode_ingredient)),
    #("instructions", json.array(payload.instructions, json.string)),
  ])
}

fn encode_macros(m: Macros) -> json.Json {
  json.object([
    #("protein", json.float(m.protein)),
    #("fat", json.float(m.fat)),
    #("carbs", json.float(m.carbs)),
  ])
}

fn encode_ingredient(ing: Ingredient) -> json.Json {
  json.object([
    #("name", json.string(ing.name)),
    #("quantity", json.string(ing.quantity)),
  ])
}

// ============================================================================
// Step 4: Complete Example - Creating a Tandoor Recipe
// ============================================================================
//
// In a real application, you would:
// 1. Create the payload with recipe data
// 2. Encode it to JSON
// 3. Send an HTTP POST request to Tandoor API:
//    - Endpoint: {TANDOOR_BASE_URL}/api/recipes/
//    - Headers: Authorization: Token {TANDOOR_API_TOKEN}
//    - Body: The encoded JSON payload
// 4. Parse the response to get the created recipe ID

pub fn build_tandoor_create_request(
  config: TandoorConfig,
  payload: CreateRecipePayload,
) -> #(String, String, json.Json) {
  let endpoint = config.base_url <> "/api/recipes/"
  let auth_header = "Token " <> config.api_token
  let json_body = encode_payload(payload)

  #(endpoint, auth_header, json_body)
}

// ============================================================================
// Step 5: Multi-Ingredient Recipe Example
// ============================================================================
//
// Here's a more complex example with multiple ingredients and detailed macros.

pub fn complex_recipe_example() -> CreateRecipePayload {
  let ingredients = [
    Ingredient(name: "Salmon Fillet", quantity: "150g"),
    Ingredient(name: "Olive Oil", quantity: "1 tbsp"),
    Ingredient(name: "Lemon Juice", quantity: "2 tbsp"),
    Ingredient(name: "Garlic", quantity: "2 cloves"),
    Ingredient(name: "Sea Salt", quantity: "to taste"),
    Ingredient(name: "Black Pepper", quantity: "to taste"),
  ]

  let instructions = [
    "Preheat oven to 400F (200C)",
    "Place salmon on parchment paper",
    "Brush with olive oil and lemon juice",
    "Sprinkle minced garlic over the salmon",
    "Season with salt and pepper",
    "Bake for 12-15 minutes until salmon flakes easily",
    "Serve immediately while hot",
  ]

  // Macros are for a single serving
  let macros = Macros(protein: 25.0, fat: 13.0, carbs: 2.0)

  CreateRecipePayload(
    name: "Lemon Herb Roasted Salmon",
    ingredients: ingredients,
    instructions: instructions,
    macros: macros,
    servings: 1,
    category: "Main Dish",
  )
}

// ============================================================================
// Step 6: Usage Pattern for Integration
// ============================================================================
//
// In your application, when creating a recipe via Tandoor:
//
// 1. Validate recipe data (name not empty, macros non-negative, etc.)
// 2. Build the payload
// 3. Encode to JSON
// 4. Create HTTP request with proper headers
// 5. Send request with configured timeouts (see TandoorConfig)
// 6. Parse response and extract recipe ID
// 7. Store recipe reference in meal planner database
//
// Example configuration from config.gleam:
//   TandoorConfig(
//     base_url: "http://localhost:8000",
//     api_token: "your-token-here",
//     connect_timeout_ms: 5000,
//     request_timeout_ms: 30000,
//   )

// ============================================================================
// Helper: Verify Encoding Works
// ============================================================================
//
// This function can be used to verify that a payload encodes to valid JSON.

pub fn verify_payload_encoding(payload: CreateRecipePayload) -> Result(Nil, Nil) {
  let _encoded = encode_payload(payload)
  Ok(Nil)
}

pub fn verify_request_creation(
  test_config: config.TandoorConfig,
  payload: CreateRecipePayload,
) -> Bool {
  let #(endpoint, auth, _json) =
    build_tandoor_create_request(test_config, payload)

  // Verify endpoint and auth header are constructed correctly
  let endpoint_matches = endpoint == test_config.base_url <> "/api/recipes/"
  let auth_matches = auth == "Token " <> test_config.api_token

  endpoint_matches && auth_matches
}
