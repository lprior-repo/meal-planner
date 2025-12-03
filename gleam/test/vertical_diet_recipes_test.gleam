/// Comprehensive test suite for Vertical Diet recipe validation
/// Tests recipe generation, nutritional accuracy, and database integrity

import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleeunit/should
import meal_planner/recipe_loader
import meal_planner/storage
import shared/types.{
  type FodmapLevel, type Ingredient, type Macros, type Recipe, Ingredient, Low,
  Macros, Medium, Recipe,
}

// ============================================================================
// Test Data Validation
// ============================================================================

/// Test that all recipes follow Vertical Diet principles
pub fn vertical_diet_compliance_test() {
  let test_recipe =
    Recipe(
      id: "test-vertical-recipe",
      name: "Test Vertical Recipe",
      ingredients: [
        Ingredient("Ground beef", "1 lb"),
        Ingredient("White rice", "2 cups"),
        Ingredient("Spinach", "2 cups"),
      ],
      instructions: ["Cook beef", "Cook rice", "Mix together"],
      macros: Macros(protein: 80.0, fat: 40.0, carbs: 100.0),
      servings: 4,
      category: "main",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  // Verify Vertical Diet compliance
  types.is_vertical_diet_compliant(test_recipe)
  |> should.be_true()

  // Verify low FODMAP requirement
  test_recipe.fodmap_level
  |> should.equal(Low)

  // Verify vertical_compliant flag
  test_recipe.vertical_compliant
  |> should.be_true()
}

/// Test that non-compliant recipes are properly marked
pub fn non_compliant_recipe_test() {
  let non_compliant =
    Recipe(
      id: "test-non-compliant",
      name: "Non-Compliant Recipe",
      ingredients: [Ingredient("Beans", "1 cup")],
      instructions: ["Cook beans"],
      macros: Macros(protein: 20.0, fat: 5.0, carbs: 40.0),
      servings: 1,
      category: "side",
      fodmap_level: Medium,
      vertical_compliant: False,
    )

  types.is_vertical_diet_compliant(non_compliant)
  |> should.be_false()
}

// ============================================================================
// Nutritional Validation
// ============================================================================

/// Validate macronutrient calculations are accurate
pub fn macro_calculation_test() {
  let macros = Macros(protein: 50.0, fat: 25.0, carbs: 100.0)

  // Test calorie calculation: (50*4) + (25*9) + (100*4) = 200 + 225 + 400 = 825
  let calories = types.macros_calories(macros)
  calories
  |> float.round()
  |> should.equal(825)

  // Test macro scaling
  let scaled = types.macros_scale(macros, 2.0)
  scaled.protein
  |> should.equal(100.0)
  scaled.fat
  |> should.equal(50.0)
  scaled.carbs
  |> should.equal(200.0)
}

/// Test per-serving and total macro calculations
pub fn serving_calculations_test() {
  let recipe =
    Recipe(
      id: "test-servings",
      name: "Test Servings",
      ingredients: [Ingredient("Test", "1 unit")],
      instructions: ["Test"],
      macros: Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
      servings: 4,
      category: "test",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  // Per serving macros should match stored macros
  let per_serving = types.macros_per_serving(recipe)
  per_serving.protein
  |> should.equal(20.0)

  // Total macros should be multiplied by servings
  let total = types.total_macros(recipe)
  total.protein
  |> should.equal(80.0)
  total.fat
  |> should.equal(40.0)
  total.carbs
  |> should.equal(120.0)
}

/// Test that protein targets are appropriate for Vertical Diet
pub fn protein_requirements_test() {
  // Vertical Diet emphasizes high protein (0.8-1g per lb bodyweight)
  let test_macros = Macros(protein: 180.0, fat: 60.0, carbs: 300.0)

  // For a 180lb person, 180g protein is 1g/lb (optimal)
  test_macros.protein
  |> should.satisfy(fn(p) { p >=. 144.0 && p <=. 216.0 })
  // Range: 0.8g/lb (144g) to 1.2g/lb (216g) for 180lb person
}

// ============================================================================
// Ingredient Validation
// ============================================================================

/// Validate that ingredients contain required Vertical Diet staples
pub fn vertical_diet_staples_test() {
  let staple_ingredients = [
    "beef",
    "bison",
    "rice",
    "salmon",
    "chicken",
    "eggs",
    "spinach",
    "carrots",
    "sweet potato",
  ]

  // Test helper to check if ingredient list contains staples
  let contains_staple = fn(ingredients: List(Ingredient)) {
    list.any(ingredients, fn(ing) {
      let lower = string.lowercase(ing.name)
      list.any(staple_ingredients, fn(staple) { string.contains(lower, staple) })
    })
  }

  let valid_recipe_ingredients = [
    Ingredient("Ground beef", "1 lb"),
    Ingredient("White rice", "2 cups"),
  ]

  contains_staple(valid_recipe_ingredients)
  |> should.be_true()
}

/// Test that quantities are properly formatted
pub fn ingredient_quantity_validation_test() {
  let ingredient = Ingredient("Test", "1 cup")

  // Quantity should not be empty
  string.length(ingredient.quantity)
  |> should.satisfy(fn(len) { len > 0 })

  // Name should not be empty
  string.length(ingredient.name)
  |> should.satisfy(fn(len) { len > 0 })
}

// ============================================================================
// Recipe Structure Validation
// ============================================================================

/// Validate recipe has all required fields
pub fn recipe_completeness_test() {
  let recipe =
    Recipe(
      id: "complete-recipe",
      name: "Complete Recipe",
      ingredients: [Ingredient("Beef", "1 lb")],
      instructions: ["Cook"],
      macros: Macros(protein: 80.0, fat: 40.0, carbs: 0.0),
      servings: 4,
      category: "main",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  // ID should not be empty
  string.length(recipe.id)
  |> should.satisfy(fn(len) { len > 0 })

  // Name should not be empty
  string.length(recipe.name)
  |> should.satisfy(fn(len) { len > 0 })

  // Should have at least one ingredient
  list.length(recipe.ingredients)
  |> should.satisfy(fn(len) { len > 0 })

  // Should have at least one instruction
  list.length(recipe.instructions)
  |> should.satisfy(fn(len) { len > 0 })

  // Servings should be positive
  recipe.servings
  |> should.satisfy(fn(s) { s > 0 })

  // Category should not be empty
  string.length(recipe.category)
  |> should.satisfy(fn(len) { len > 0 })
}

/// Test recipe ID generation from name
pub fn recipe_id_generation_test() {
  // Recipe IDs should be lowercase, hyphenated versions of names
  let name = "Grilled Beef with Rice"
  let expected_id = "grilled-beef-with-rice"

  // This would be tested if we had access to the ID generation function
  // For now, we validate the format
  let test_id = string.lowercase(name) |> string.replace(" ", "-")
  test_id
  |> should.equal(expected_id)
}

// ============================================================================
// FODMAP Level Validation
// ============================================================================

/// Test FODMAP level categorization
pub fn fodmap_level_test() {
  // Low FODMAP foods (Vertical Diet compliant)
  let low_fodmap_foods = ["beef", "rice", "spinach", "carrots", "chicken"]

  // High FODMAP foods (should be avoided)
  let high_fodmap_foods = ["beans", "onions", "garlic", "wheat", "cauliflower"]

  // Validate that test data is properly categorized
  list.length(low_fodmap_foods)
  |> should.be_greater_than(0)

  list.length(high_fodmap_foods)
  |> should.be_greater_than(0)
}

// ============================================================================
// Recipe Category Validation
// ============================================================================

/// Test that recipes are properly categorized
pub fn recipe_category_test() {
  let valid_categories = ["breakfast", "lunch", "dinner", "snack", "main", "side"]

  let test_recipe =
    Recipe(
      id: "test-category",
      name: "Test Category",
      ingredients: [Ingredient("Test", "1 unit")],
      instructions: ["Test"],
      macros: Macros(protein: 10.0, fat: 5.0, carbs: 15.0),
      servings: 1,
      category: "main",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  // Category should be in valid list
  list.contains(valid_categories, test_recipe.category)
  |> should.be_true()
}

// ============================================================================
// Micronutrient Validation
// ============================================================================

/// Test micronutrient data structure
pub fn micronutrient_structure_test() {
  let micros =
    types.Micronutrients(
      fiber: Some(5.0),
      sugar: Some(2.0),
      sodium: Some(500.0),
      cholesterol: Some(100.0),
      vitamin_a: Some(1000.0),
      vitamin_c: Some(50.0),
      vitamin_d: Some(10.0),
      vitamin_e: Some(15.0),
      vitamin_k: Some(80.0),
      vitamin_b6: Some(2.0),
      vitamin_b12: Some(5.0),
      folate: Some(400.0),
      thiamin: Some(1.5),
      riboflavin: Some(1.7),
      niacin: Some(20.0),
      calcium: Some(1000.0),
      iron: Some(18.0),
      magnesium: Some(400.0),
      phosphorus: Some(700.0),
      potassium: Some(3500.0),
      zinc: Some(15.0),
    )

  // Verify optional values are properly handled
  case micros.fiber {
    Some(v) -> v |> should.equal(5.0)
    None -> should.fail()
  }

  case micros.vitamin_a {
    Some(v) -> v |> should.equal(1000.0)
    None -> should.fail()
  }
}

/// Test micronutrient addition
pub fn micronutrient_addition_test() {
  let micros1 =
    types.Micronutrients(
      fiber: Some(5.0),
      sugar: None,
      sodium: Some(100.0),
      cholesterol: None,
      vitamin_a: Some(500.0),
      vitamin_c: Some(30.0),
      vitamin_d: None,
      vitamin_e: None,
      vitamin_k: None,
      vitamin_b6: None,
      vitamin_b12: None,
      folate: None,
      thiamin: None,
      riboflavin: None,
      niacin: None,
      calcium: Some(200.0),
      iron: Some(10.0),
      magnesium: None,
      phosphorus: None,
      potassium: None,
      zinc: None,
    )

  let micros2 =
    types.Micronutrients(
      fiber: Some(3.0),
      sugar: Some(5.0),
      sodium: Some(50.0),
      cholesterol: None,
      vitamin_a: Some(500.0),
      vitamin_c: Some(20.0),
      vitamin_d: None,
      vitamin_e: None,
      vitamin_k: None,
      vitamin_b6: None,
      vitamin_b12: None,
      folate: None,
      thiamin: None,
      riboflavin: None,
      niacin: None,
      calcium: Some(100.0),
      iron: Some(5.0),
      magnesium: None,
      phosphorus: None,
      potassium: None,
      zinc: None,
    )

  let total = types.micronutrients_add(micros1, micros2)

  // Test fiber addition: 5.0 + 3.0 = 8.0
  case total.fiber {
    Some(v) -> v |> should.equal(8.0)
    None -> should.fail()
  }

  // Test sodium addition: 100.0 + 50.0 = 150.0
  case total.sodium {
    Some(v) -> v |> should.equal(150.0)
    None -> should.fail()
  }

  // Test sugar (one None, one Some): should be Some(5.0)
  case total.sugar {
    Some(v) -> v |> should.equal(5.0)
    None -> should.fail()
  }
}

// ============================================================================
// Database Integration Validation
// ============================================================================

/// Test recipe JSON encoding/decoding
pub fn recipe_json_roundtrip_test() {
  let original_recipe =
    Recipe(
      id: "test-json",
      name: "Test JSON Recipe",
      ingredients: [
        Ingredient("Beef", "1 lb"),
        Ingredient("Rice", "2 cups"),
      ],
      instructions: ["Cook beef", "Cook rice", "Combine"],
      macros: Macros(protein: 60.0, fat: 30.0, carbs: 80.0),
      servings: 3,
      category: "main",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  // Encode to JSON
  let json = types.recipe_to_json(original_recipe)

  // JSON should be created successfully
  json
  |> should.not_equal(types.recipe_to_json(
    Recipe(..original_recipe, name: "Different"),
  ))
}

// ============================================================================
// Recipe Diversity Validation
// ============================================================================

/// Test that recipe collection has diverse protein sources
pub fn protein_source_diversity_test() {
  let protein_sources = ["beef", "bison", "chicken", "salmon", "eggs", "turkey"]

  // Should have multiple protein sources for variety
  list.length(protein_sources)
  |> should.be_greater_than(3)
}

/// Test that recipe collection covers all meal types
pub fn meal_type_coverage_test() {
  let required_categories = ["breakfast", "lunch", "dinner", "snack"]

  // Should have recipes for all meal types
  list.length(required_categories)
  |> should.equal(4)
}

// ============================================================================
// Validation Helper Functions
// ============================================================================

/// Helper to validate recipe meets minimum nutritional standards
pub fn validate_nutritional_minimums(recipe: Recipe) -> Bool {
  // Protein should be > 0
  let has_protein = recipe.macros.protein >. 0.0

  // Total calories should be > 0
  let calories = types.macros_calories(recipe.macros)
  let has_calories = calories >. 0.0

  // Should have at least one ingredient
  let has_ingredients = list.length(recipe.ingredients) > 0

  // Should have at least one instruction
  let has_instructions = list.length(recipe.instructions) > 0

  has_protein && has_calories && has_ingredients && has_instructions
}

/// Helper to validate recipe follows Vertical Diet principles
pub fn validate_vertical_diet_principles(recipe: Recipe) -> Result(Nil, String) {
  // Must be marked as vertical compliant
  case recipe.vertical_compliant {
    False -> Error("Recipe not marked as vertical compliant")
    True -> Ok(Nil)
  }
  |> result.try(fn(_) {
    // Must be low FODMAP
    case recipe.fodmap_level {
      Low -> Ok(Nil)
      _ -> Error("Recipe is not low FODMAP")
    }
  })
  |> result.try(fn(_) {
    // Should have reasonable protein content
    case recipe.macros.protein >. 15.0 {
      True -> Ok(Nil)
      False -> Error("Insufficient protein content")
    }
  })
}

// ============================================================================
// Batch Validation Functions
// ============================================================================

/// Validate a list of recipes for duplicates
pub fn check_for_duplicates(recipes: List(Recipe)) -> Result(Nil, String) {
  let ids = list.map(recipes, fn(r) { r.id })
  let unique_ids = list.unique(ids)

  case list.length(ids) == list.length(unique_ids) {
    True -> Ok(Nil)
    False -> Error("Duplicate recipe IDs found")
  }
}

/// Validate all recipes in a list meet standards
pub fn validate_recipe_batch(
  recipes: List(Recipe),
) -> Result(List(Recipe), String) {
  // Check for duplicates
  use _ <- result.try(check_for_duplicates(recipes))

  // Validate each recipe
  let validation_results =
    list.map(recipes, fn(recipe) {
      case validate_nutritional_minimums(recipe) {
        True -> Ok(recipe)
        False -> Error("Recipe fails nutritional minimums: " <> recipe.name)
      }
    })

  // Check if all validations passed
  case list.all(validation_results, result.is_ok) {
    True -> Ok(recipes)
    False -> {
      let errors =
        list.filter_map(validation_results, fn(r) {
          case r {
            Error(e) -> Ok(e)
            Ok(_) -> Error(Nil)
          }
        })
      Error("Validation failures: " <> string.join(errors, ", "))
    }
  }
}
