/// Comprehensive test suite for diet validator module
/// Tests Vertical Diet and Tim Ferriss 4-Hour Body diet compliance
/// Validates ingredient checks, macro requirements, and scoring algorithms

import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import shared/types.{
  type FodmapLevel, type Ingredient, type Macros, type Recipe, Ingredient, Low,
  Macros, Medium, Recipe,
}

// ============================================================================
// Vertical Diet Compliance Tests
// ============================================================================

/// Test compliant recipe: beef + white rice + spinach
pub fn vertical_diet_compliant_recipe_test() {
  let recipe =
    Recipe(
      id: "beef-bowl",
      name: "Beef Bowl",
      ingredients: [
        Ingredient("Ground beef", "1 lb"),
        Ingredient("White rice", "2 cups"),
        Ingredient("Spinach", "2 cups"),
      ],
      instructions: [
        "Brown ground beef in pan",
        "Cook white rice according to package",
        "Steam spinach",
        "Mix all ingredients together",
      ],
      macros: Macros(protein: 80.0, carbs: 100.0, fat: 40.0),
      servings: 4,
      category: "main",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  // Test compliance function
  types.is_vertical_diet_compliant(recipe)
  |> should.be_true

  // Test compliance score (should be high)
  let score = calculate_vertical_diet_score(recipe)
  score
  |> should.satisfy(fn(s) { s >. 0.8 })
}

/// Test seed oil violation: canola oil should fail
pub fn seed_oil_violation_test() {
  let recipe =
    Recipe(
      id: "chicken-stir-fry",
      name: "Chicken Stir Fry",
      ingredients: [
        Ingredient("Chicken breast", "1 lb"),
        Ingredient("Canola oil", "2 tbsp"),
        Ingredient("Mixed vegetables", "2 cups"),
      ],
      instructions: [
        "Heat canola oil in wok",
        "Cook chicken",
        "Add vegetables",
      ],
      macros: Macros(protein: 60.0, carbs: 20.0, fat: 25.0),
      servings: 2,
      category: "main",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  // Should not be compliant due to seed oil
  types.is_vertical_diet_compliant(recipe)
  |> should.be_false

  // Check for seed oil violation
  let violations = check_vertical_diet_violations(recipe)
  violations
  |> list.any(fn(v) { string.contains(v, "seed oil") })
  |> should.be_true
}

/// Test that recipe with proper ingredients passes
pub fn vertical_diet_allowed_ingredients_test() {
  let recipe =
    Recipe(
      id: "salmon-rice",
      name: "Salmon with Rice",
      ingredients: [
        Ingredient("Salmon", "8 oz"),
        Ingredient("White rice", "1 cup"),
        Ingredient("Butter", "1 tbsp"),
      ],
      instructions: ["Cook salmon", "Cook rice", "Mix with butter"],
      macros: Macros(protein: 50.0, carbs: 60.0, fat: 20.0),
      servings: 1,
      category: "main",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  types.is_vertical_diet_compliant(recipe)
  |> should.be_true
}

/// Test high FODMAP violation
pub fn high_fodmap_violation_test() {
  let recipe =
    Recipe(
      id: "bean-dish",
      name: "Bean and Onion Dish",
      ingredients: [
        Ingredient("Black beans", "1 cup"),
        Ingredient("Onions", "1 cup"),
        Ingredient("Garlic", "3 cloves"),
      ],
      instructions: ["Cook beans", "Sauté onions and garlic", "Mix together"],
      macros: Macros(protein: 20.0, carbs: 45.0, fat: 5.0),
      servings: 2,
      category: "main",
      fodmap_level: Medium,
      vertical_compliant: False,
    )

  types.is_vertical_diet_compliant(recipe)
  |> should.be_false

  let violations = check_vertical_diet_violations(recipe)
  violations
  |> list.any(fn(v) { string.contains(v, "FODMAP") })
  |> should.be_true
}

/// Test prohibited ingredients (seed oils)
pub fn prohibited_ingredients_test() {
  let seed_oils = [
    "canola oil",
    "vegetable oil",
    "soybean oil",
    "corn oil",
    "sunflower oil",
  ]

  // Each seed oil should be detected
  list.each(seed_oils, fn(oil) {
    let recipe =
      Recipe(
        id: "test-" <> oil,
        name: "Test Recipe",
        ingredients: [Ingredient(oil, "1 tbsp")],
        instructions: ["Cook"],
        macros: Macros(protein: 0.0, carbs: 0.0, fat: 14.0),
        servings: 1,
        category: "test",
        fodmap_level: Low,
        vertical_compliant: False,
      )

    has_seed_oil(recipe)
    |> should.be_true
  })
}

// ============================================================================
// Tim Ferriss 4-Hour Body Diet Tests
// ============================================================================

/// Test high protein requirement (30g+ per meal)
pub fn tim_ferriss_high_protein_test() {
  let recipe =
    Recipe(
      id: "eggs-beans",
      name: "Eggs and Black Beans",
      ingredients: [
        Ingredient("Eggs", "4 large"),
        Ingredient("Black beans", "1 cup"),
        Ingredient("Salsa", "2 tbsp"),
      ],
      instructions: ["Scramble eggs", "Heat beans", "Top with salsa"],
      macros: Macros(protein: 40.0, carbs: 30.0, fat: 20.0),
      servings: 1,
      category: "breakfast",
      fodmap_level: Medium,
      vertical_compliant: False,
    )

  // Should meet Tim Ferriss protein requirement (30g+)
  meets_tim_ferriss_protein_requirement(recipe)
  |> should.be_true

  // Protein score should be high
  let score = calculate_tim_ferriss_protein_score(recipe)
  score
  |> should.satisfy(fn(s) { s >. 0.9 })
}

/// Test white carbs violation (pasta, bread, rice)
pub fn tim_ferriss_white_carbs_violation_test() {
  let recipe =
    Recipe(
      id: "pasta-dish",
      name: "Pasta with Chicken",
      ingredients: [
        Ingredient("Chicken breast", "6 oz"),
        Ingredient("Pasta", "2 cups cooked"),
        Ingredient("Tomato sauce", "1/2 cup"),
      ],
      instructions: ["Cook pasta", "Grill chicken", "Mix together"],
      macros: Macros(protein: 45.0, carbs: 80.0, fat: 10.0),
      servings: 1,
      category: "main",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  // Should violate Tim Ferriss white carbs rule
  has_white_carbs(recipe)
  |> should.be_true

  let violations = check_tim_ferriss_violations(recipe)
  violations
  |> list.any(fn(v) { string.contains(v, "white carb") })
  |> should.be_true
}

/// Test allowed Tim Ferriss carbs (legumes, vegetables)
pub fn tim_ferriss_allowed_carbs_test() {
  let recipe =
    Recipe(
      id: "beans-veggies",
      name: "Beans and Vegetables",
      ingredients: [
        Ingredient("Chicken breast", "6 oz"),
        Ingredient("Black beans", "1 cup"),
        Ingredient("Broccoli", "2 cups"),
        Ingredient("Cauliflower", "1 cup"),
      ],
      instructions: [
        "Grill chicken",
        "Heat beans",
        "Steam vegetables",
        "Serve together",
      ],
      macros: Macros(protein: 50.0, carbs: 40.0, fat: 8.0),
      servings: 1,
      category: "main",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  // Should pass Tim Ferriss carb requirements (legumes OK)
  has_white_carbs(recipe)
  |> should.be_false

  // Should have adequate protein
  meets_tim_ferriss_protein_requirement(recipe)
  |> should.be_true
}

/// Test Tim Ferriss compliance score
pub fn tim_ferriss_compliance_score_test() {
  let compliant_recipe =
    Recipe(
      id: "perfect-meal",
      name: "Perfect Slow-Carb Meal",
      ingredients: [
        Ingredient("Grass-fed beef", "8 oz"),
        Ingredient("Lentils", "1 cup"),
        Ingredient("Spinach", "3 cups"),
      ],
      instructions: ["Cook beef", "Prepare lentils", "Sauté spinach"],
      macros: Macros(protein: 60.0, carbs: 40.0, fat: 25.0),
      servings: 1,
      category: "main",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  let score = calculate_tim_ferriss_score(compliant_recipe)
  score
  |> should.satisfy(fn(s) { s >. 0.85 })
}

/// Test insufficient protein violation
pub fn tim_ferriss_low_protein_test() {
  let recipe =
    Recipe(
      id: "low-protein",
      name: "Salad",
      ingredients: [
        Ingredient("Lettuce", "3 cups"),
        Ingredient("Tomatoes", "1 cup"),
        Ingredient("Cucumber", "1 cup"),
      ],
      instructions: ["Chop vegetables", "Toss together"],
      macros: Macros(protein: 5.0, carbs: 15.0, fat: 2.0),
      servings: 1,
      category: "side",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  // Should fail protein requirement
  meets_tim_ferriss_protein_requirement(recipe)
  |> should.be_false

  let violations = check_tim_ferriss_violations(recipe)
  violations
  |> list.any(fn(v) { string.contains(v, "protein") })
  |> should.be_true
}

// ============================================================================
// Helper Functions (test implementations)
// ============================================================================

fn calculate_vertical_diet_score(recipe: Recipe) -> Float {
  case types.is_vertical_diet_compliant(recipe) {
    True -> 1.0
    False -> 0.0
  }
}

fn check_vertical_diet_violations(recipe: Recipe) -> List(String) {
  let violations = []

  let violations = case recipe.fodmap_level {
    Low -> violations
    _ -> ["Not low FODMAP", ..violations]
  }

  let violations = case has_seed_oil(recipe) {
    True -> ["Contains seed oil", ..violations]
    False -> violations
  }

  violations
}

fn has_seed_oil(recipe: Recipe) -> Bool {
  let seed_oils = [
    "canola",
    "vegetable oil",
    "soybean",
    "corn oil",
    "sunflower oil",
  ]

  list.any(recipe.ingredients, fn(ing) {
    let lower = string.lowercase(ing.name)
    list.any(seed_oils, fn(oil) { string.contains(lower, oil) })
  })
}

fn meets_tim_ferriss_protein_requirement(recipe: Recipe) -> Bool {
  let per_serving = types.macros_per_serving(recipe)
  per_serving.protein >=. 30.0
}

fn calculate_tim_ferriss_protein_score(recipe: Recipe) -> Float {
  let protein = types.macros_per_serving(recipe).protein

  case protein {
    p if p >=. 40.0 -> 1.0
    p if p >=. 30.0 -> 0.9
    _ -> 0.3
  }
}

fn check_tim_ferriss_violations(recipe: Recipe) -> List(String) {
  let violations = []

  let violations = case meets_tim_ferriss_protein_requirement(recipe) {
    True -> violations
    False -> ["Insufficient protein (need 30g+)", ..violations]
  }

  let violations = case has_white_carbs(recipe) {
    True -> ["Contains white carbs", ..violations]
    False -> violations
  }

  violations
}

fn has_white_carbs(recipe: Recipe) -> Bool {
  let white_carbs = ["pasta", "bread", "rice", "potato", "tortilla", "cereal"]

  list.any(recipe.ingredients, fn(ing) {
    let lower = string.lowercase(ing.name)
    list.any(white_carbs, fn(carb) { string.contains(lower, carb) })
  })
}

fn calculate_tim_ferriss_score(recipe: Recipe) -> Float {
  let score = 0.0

  let score = case meets_tim_ferriss_protein_requirement(recipe) {
    True -> score +. 0.5
    False -> score
  }

  let score = case has_white_carbs(recipe) {
    False -> score +. 0.5
    True -> score
  }

  score
}
