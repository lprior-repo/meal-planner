/// Tests for diet_validator module
/// Comprehensive test coverage for all diet validation functions
import gleam/list
import gleeunit/should
import meal_planner/diet_validator.{HighProtein, Keto, VerticalDiet}
import meal_planner/types.{
  type FodmapLevel, type Ingredient, type Macros, type Recipe, Ingredient, Low,
  Macros, Recipe,
}

// ============================================================================
// Test Fixtures
// ============================================================================

fn make_macros(protein: Float, fat: Float, carbs: Float) -> Macros {
  Macros(protein: protein, fat: fat, carbs: carbs)
}

fn make_ingredient(name: String, quantity: String) -> Ingredient {
  Ingredient(name: name, quantity: quantity)
}

fn make_recipe(
  name: String,
  ingredients: List(Ingredient),
  macros: Macros,
  servings: Int,
  fodmap_level: FodmapLevel,
) -> Recipe {
  Recipe(
    id: "test-1",
    name: name,
    category: "test",
    servings: servings,
    ingredients: ingredients,
    instructions: ["Step 1"],
    macros: macros,
    fodmap_level: fodmap_level,
    vertical_compliant: True,
  )
}

// ============================================================================
// Vertical Diet Tests
// ============================================================================

pub fn check_vertical_diet_compliant_test() {
  // Recipe with preferred ingredients and no violations
  let ingredients = [
    make_ingredient("ribeye steak", "200g"),
    make_ingredient("white rice", "150g"),
    make_ingredient("carrots", "100g"),
  ]

  let recipe =
    make_recipe(
      "Vertical Diet Meal",
      ingredients,
      make_macros(40.0, 15.0, 50.0),
      1,
      Low,
    )

  let result = diet_validator.check_vertical_diet(recipe)

  result.compliant
  |> should.be_true

  result.score
  |> should.equal(1.0)

  result.violations
  |> should.equal([])
}

pub fn check_vertical_diet_with_seed_oil_test() {
  // Recipe with seed oil - major violation
  let ingredients = [
    make_ingredient("chicken breast", "200g"),
    make_ingredient("canola oil", "15ml"),
    make_ingredient("white rice", "150g"),
  ]

  let recipe =
    make_recipe(
      "Chicken with Canola Oil",
      ingredients,
      make_macros(40.0, 15.0, 50.0),
      1,
      Low,
    )

  let result = diet_validator.check_vertical_diet(recipe)

  result.compliant
  |> should.be_false

  list.is_empty(result.violations)
  |> should.be_false

  // Should contain seed oil violation
  list.any(result.violations, fn(v) { v == "Contains seed oil: canola oil" })
  |> should.be_true
}

pub fn check_vertical_diet_with_high_fodmap_test() {
  // Recipe with high FODMAP ingredients - warning only
  let ingredients = [
    make_ingredient("beef", "200g"),
    make_ingredient("garlic", "10g"),
    make_ingredient("onion", "50g"),
  ]

  let recipe =
    make_recipe(
      "Beef with Garlic",
      ingredients,
      make_macros(40.0, 15.0, 10.0),
      1,
      types.High,
    )

  let result = diet_validator.check_vertical_diet(recipe)

  // Should still be compliant (warnings don't fail compliance)
  result.compliant
  |> should.be_true

  // But should have FODMAP warnings
  list.is_empty(result.warnings)
  |> should.be_false
}

pub fn check_vertical_diet_without_preferred_protein_test() {
  // Recipe without preferred proteins - warning only
  let ingredients = [
    make_ingredient("tofu", "200g"),
    make_ingredient("white rice", "150g"),
  ]

  let recipe =
    make_recipe("Tofu Rice", ingredients, make_macros(20.0, 10.0, 50.0), 1, Low)

  let result = diet_validator.check_vertical_diet(recipe)

  result.compliant
  |> should.be_true

  // Should suggest preferred proteins
  list.any(result.warnings, fn(w) {
    w == "Consider adding preferred proteins (beef, chicken, eggs)"
  })
  |> should.be_true
}

// ============================================================================
// Tim Ferriss Diet Tests
// ============================================================================

pub fn check_tim_ferriss_compliant_test() {
  // High protein recipe with no white carbs
  let ingredients = [
    make_ingredient("beef", "200g"),
    make_ingredient("black beans", "150g"),
    make_ingredient("spinach", "100g"),
  ]

  let recipe =
    make_recipe(
      "Beef and Beans",
      ingredients,
      make_macros(35.0, 15.0, 30.0),
      1,
      Low,
    )

  let result = diet_validator.check_tim_ferriss(recipe)

  result.compliant
  |> should.be_true

  result.score
  |> should.equal(1.0)
}

pub fn check_tim_ferriss_low_protein_test() {
  // Low protein recipe - non-compliant
  let ingredients = [
    make_ingredient("quinoa", "200g"),
    make_ingredient("vegetables", "150g"),
  ]

  let recipe =
    make_recipe(
      "Quinoa Bowl",
      ingredients,
      make_macros(15.0, 10.0, 40.0),
      1,
      Low,
    )

  let result = diet_validator.check_tim_ferriss(recipe)

  result.compliant
  |> should.be_false

  // Score should be proportional to protein (15/30 = 0.5)
  result.score
  |> should.equal(0.5)
}

pub fn check_tim_ferriss_with_white_carbs_test() {
  // Contains prohibited white carbs
  let ingredients = [
    make_ingredient("chicken breast", "200g"),
    make_ingredient("pasta", "150g"),
  ]

  let recipe =
    make_recipe(
      "Chicken Pasta",
      ingredients,
      make_macros(35.0, 10.0, 60.0),
      1,
      Low,
    )

  let result = diet_validator.check_tim_ferriss(recipe)

  result.compliant
  |> should.be_false

  list.is_empty(result.violations)
  |> should.be_false
}

pub fn check_tim_ferriss_with_white_rice_test() {
  // White rice is allowed (post-workout exception)
  let ingredients = [
    make_ingredient("chicken breast", "200g"),
    make_ingredient("white rice", "150g"),
  ]

  let recipe =
    make_recipe(
      "Chicken and Rice",
      ingredients,
      make_macros(40.0, 10.0, 50.0),
      1,
      Low,
    )

  let result = diet_validator.check_tim_ferriss(recipe)

  result.compliant
  |> should.be_true

  // Should have warning about white rice being post-workout only
  list.any(result.warnings, fn(w) {
    w == "Contains white rice (allowed post-workout)"
  })
  |> should.be_true
}

// ============================================================================
// Keto Diet Tests
// ============================================================================

pub fn check_keto_compliant_test() {
  // Very low carb recipe
  let ingredients = [
    make_ingredient("ribeye steak", "200g"),
    make_ingredient("butter", "30g"),
    make_ingredient("spinach", "50g"),
  ]

  let recipe =
    make_recipe(
      "Keto Steak",
      ingredients,
      make_macros(40.0, 35.0, 15.0),
      1,
      Low,
    )

  let result = diet_validator.check_keto(recipe)

  result.compliant
  |> should.be_true

  result.score
  |> should.equal(1.0)
}

pub fn check_keto_too_many_carbs_test() {
  // Too many carbs for keto
  let ingredients = [
    make_ingredient("chicken", "200g"),
    make_ingredient("rice", "150g"),
  ]

  let recipe =
    make_recipe(
      "Chicken Rice",
      ingredients,
      make_macros(40.0, 15.0, 250.0),
      1,
      Low,
    )

  let result = diet_validator.check_keto(recipe)

  result.compliant
  |> should.be_false

  result.score
  |> should.equal(0.0)

  list.is_empty(result.violations)
  |> should.be_false
}

// ============================================================================
// High Protein Diet Tests
// ============================================================================

pub fn check_high_protein_compliant_test() {
  // High protein per serving
  let ingredients = [make_ingredient("chicken breast", "300g")]

  let recipe =
    make_recipe(
      "Grilled Chicken",
      ingredients,
      make_macros(200.0, 20.0, 0.0),
      2,
      Low,
    )

  let result = diet_validator.check_high_protein(recipe)

  result.compliant
  |> should.be_true

  result.score
  |> should.equal(1.0)
}

pub fn check_high_protein_low_protein_test() {
  // Lower protein - still compliant but with warning
  let ingredients = [make_ingredient("turkey", "150g")]

  let recipe =
    make_recipe(
      "Turkey Breast",
      ingredients,
      make_macros(60.0, 10.0, 5.0),
      2,
      Low,
    )

  let result = diet_validator.check_high_protein(recipe)

  result.compliant
  |> should.be_true

  list.is_empty(result.warnings)
  |> should.be_false
}

// ============================================================================
// Multi-Principle Validation Tests
// ============================================================================

pub fn validate_recipe_empty_principles_test() {
  // No principles = everything compliant
  let ingredients = [make_ingredient("anything", "100g")]

  let recipe =
    make_recipe("Test", ingredients, make_macros(10.0, 10.0, 10.0), 1, Low)

  let result = diet_validator.validate_recipe(recipe, [])

  result.compliant
  |> should.be_true

  result.score
  |> should.equal(1.0)
}

pub fn validate_recipe_single_principle_test() {
  // Test with single principle
  let ingredients = [
    make_ingredient("beef", "200g"),
    make_ingredient("white rice", "150g"),
  ]

  let recipe =
    make_recipe("Beef Rice", ingredients, make_macros(40.0, 15.0, 50.0), 1, Low)

  let result = diet_validator.validate_recipe(recipe, [VerticalDiet])

  result.compliant
  |> should.be_true
}

pub fn validate_recipe_multiple_principles_test() {
  // Test with multiple principles - all must pass
  let ingredients = [
    make_ingredient("beef", "200g"),
    make_ingredient("spinach", "100g"),
  ]

  let recipe =
    make_recipe(
      "Beef Spinach",
      ingredients,
      make_macros(50.0, 40.0, 10.0),
      1,
      Low,
    )

  let result =
    diet_validator.validate_recipe(recipe, [VerticalDiet, HighProtein, Keto])

  result.compliant
  |> should.be_true

  // Score should be average of all principles
  { result.score >. 0.0 }
  |> should.be_true
}

pub fn validate_recipe_conflicting_principles_test() {
  // Recipe that passes one but fails another
  let ingredients = [
    make_ingredient("chicken", "200g"),
    make_ingredient("rice", "200g"),
  ]

  let recipe =
    make_recipe(
      "Chicken Rice",
      ingredients,
      make_macros(40.0, 10.0, 80.0),
      1,
      Low,
    )

  // Should pass VerticalDiet but fail Keto (too many carbs)
  let result = diet_validator.validate_recipe(recipe, [VerticalDiet, Keto])

  result.compliant
  |> should.be_false
}

// ============================================================================
// Helper Function Tests
// ============================================================================

pub fn has_seed_oils_true_test() {
  let ingredients = [
    make_ingredient("chicken", "200g"),
    make_ingredient("soybean oil", "15ml"),
  ]

  diet_validator.has_seed_oils(ingredients)
  |> should.be_true
}

pub fn has_seed_oils_false_test() {
  let ingredients = [
    make_ingredient("chicken", "200g"),
    make_ingredient("olive oil", "15ml"),
  ]

  diet_validator.has_seed_oils(ingredients)
  |> should.be_false
}

pub fn has_seed_oils_garlic_infused_exception_test() {
  // Garlic-infused oil is allowed on Vertical Diet
  let ingredients = [
    make_ingredient("beef", "200g"),
    make_ingredient("garlic-infused olive oil", "15ml"),
  ]

  diet_validator.has_seed_oils(ingredients)
  |> should.be_false
}

pub fn has_white_carbs_true_test() {
  let ingredients = [
    make_ingredient("chicken", "200g"),
    make_ingredient("pasta", "150g"),
  ]

  diet_validator.has_white_carbs(ingredients)
  |> should.be_true
}

pub fn has_white_carbs_false_with_rice_test() {
  // White rice is NOT considered a prohibited white carb (allowed post-workout in Tim Ferriss diet)
  let ingredients = [
    make_ingredient("chicken", "200g"),
    make_ingredient("white rice", "150g"),
  ]

  diet_validator.has_white_carbs(ingredients)
  |> should.be_false
}

pub fn calculate_protein_per_serving_test() {
  let recipe = make_recipe("Test", [], make_macros(60.0, 20.0, 40.0), 2, Low)

  let protein = diet_validator.calculate_protein_per_serving(recipe)

  protein
  |> should.equal(60.0)
}

// ============================================================================
// Stub Diet Tests (Paleo, Mediterranean)
// ============================================================================

pub fn check_paleo_returns_compliant_test() {
  // Paleo is a stub - should always return compliant
  let recipe = make_recipe("Test", [], make_macros(20.0, 10.0, 30.0), 1, Low)

  let result = diet_validator.check_paleo(recipe)

  result.compliant
  |> should.be_true

  result.score
  |> should.equal(1.0)
}

pub fn check_mediterranean_returns_compliant_test() {
  // Mediterranean is a stub - should always return compliant
  let recipe = make_recipe("Test", [], make_macros(20.0, 10.0, 30.0), 1, Low)

  let result = diet_validator.check_mediterranean(recipe)

  result.compliant
  |> should.be_true

  result.score
  |> should.equal(1.0)
}
