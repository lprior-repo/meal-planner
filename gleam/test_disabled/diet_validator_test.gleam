import gleeunit/should
import meal_planner/diet_validator.{check_tim_ferriss, check_vertical_diet}
import meal_planner/types.{
  type FodmapLevel, type Ingredient, type Macros, type Recipe, High, Ingredient,
  Low, Macros, Recipe,
}

// Test data helpers
fn make_recipe(
  name: String,
  macros: Macros,
  fodmap: FodmapLevel,
  vertical: Bool,
  ingredients: List(Ingredient),
) -> Recipe {
  Recipe(
    id: "test-" <> name,
    name: name,
    ingredients: ingredients,
    instructions: ["Cook it"],
    macros: macros,
    servings: 1,
    category: "test",
    fodmap_level: fodmap,
    vertical_compliant: vertical,
  )
}

fn high_protein_macros() -> Macros {
  Macros(protein: 40.0, fat: 10.0, carbs: 20.0)
}

fn low_protein_macros() -> Macros {
  Macros(protein: 10.0, fat: 10.0, carbs: 50.0)
}

fn white_carb_macros() -> Macros {
  Macros(protein: 5.0, fat: 2.0, carbs: 80.0)
}

// ============================================================================
// Vertical Diet Tests
// ============================================================================

pub fn vertical_diet_compliant_low_fodmap_test() {
  let recipe =
    make_recipe("Grilled Steak", high_protein_macros(), Low, True, [
      Ingredient("Ribeye steak", "8oz"),
      Ingredient("White rice", "1 cup"),
      Ingredient("Carrots", "1/2 cup"),
    ])

  let result = check_vertical_diet(recipe)
  result.compliant
  |> should.equal(True)
  result.violations
  |> should.equal([])
}

pub fn vertical_diet_seed_oil_violation_test() {
  let recipe =
    make_recipe("Fried Chicken", high_protein_macros(), Low, True, [
      Ingredient("Chicken", "8oz"),
      Ingredient("Canola oil", "2 tbsp"),
    ])

  let result = check_vertical_diet(recipe)
  result.compliant
  |> should.equal(False)
  result.violations
  |> should.not_equal([])
}

pub fn vertical_diet_high_fodmap_test() {
  let recipe =
    make_recipe("Garlic Chicken", high_protein_macros(), High, True, [
      Ingredient("Chicken breast", "8oz"),
      Ingredient("Garlic", "4 cloves"),
      Ingredient("Onions", "1 cup"),
    ])

  let result = check_vertical_diet(recipe)
  // Should be compliant (no seed oils), but have FODMAP warnings
  result.compliant
  |> should.equal(True)
  result.warnings
  |> should.not_equal([])
}

pub fn vertical_diet_multiple_seed_oils_test() {
  let recipe =
    make_recipe("Salad", high_protein_macros(), Low, True, [
      Ingredient("Lettuce", "2 cups"),
      Ingredient("Soybean oil", "1 tbsp"),
      Ingredient("Sunflower oil", "1 tbsp"),
    ])

  let result = check_vertical_diet(recipe)
  result.compliant
  |> should.equal(False)
  // Should have 2 violations for 2 different seed oils
  result.violations
  |> should.not_equal([])
}

// ============================================================================
// Tim Ferriss 4-Hour Body Tests
// ============================================================================

pub fn tim_ferriss_high_protein_low_white_carbs_test() {
  let recipe =
    make_recipe("Protein Bowl", high_protein_macros(), Low, False, [
      Ingredient("Chicken breast", "8oz"),
      Ingredient("Black beans", "1 cup"),
      Ingredient("Spinach", "2 cups"),
    ])

  let result = check_tim_ferriss(recipe)
  result.compliant
  |> should.equal(True)
  result.violations
  |> should.equal([])
}

pub fn tim_ferriss_low_protein_test() {
  let recipe =
    make_recipe("Pasta", low_protein_macros(), Low, False, [
      Ingredient("Pasta", "2 cups"),
      Ingredient("Tomato sauce", "1 cup"),
    ])

  let result = check_tim_ferriss(recipe)
  result.compliant
  |> should.equal(False)
  // Should have both low protein AND white carbs violations
  result.violations
  |> should.not_equal([])
}

pub fn tim_ferriss_white_carbs_detected_test() {
  let recipe =
    make_recipe("Bread Sandwich", white_carb_macros(), Low, False, [
      Ingredient("White bread", "2 slices"),
      Ingredient("Turkey", "2oz"),
    ])

  let result = check_tim_ferriss(recipe)
  result.compliant
  |> should.equal(False)
  result.violations
  |> should.not_equal([])
}

pub fn tim_ferriss_white_rice_allowed_test() {
  let recipe =
    make_recipe("Post Workout Rice", high_protein_macros(), Low, False, [
      Ingredient("White rice", "1 cup"),
      Ingredient("Chicken", "8oz"),
    ])

  let result = check_tim_ferriss(recipe)
  // White rice is allowed (warning only), protein is high
  result.compliant
  |> should.equal(True)
  // Should have warning about white rice
  result.warnings
  |> should.not_equal([])
}

pub fn tim_ferriss_legumes_recommended_test() {
  let recipe =
    make_recipe("Bean Bowl", high_protein_macros(), Low, False, [
      Ingredient("Black beans", "2 cups"),
      Ingredient("Vegetables", "1 cup"),
    ])

  let result = check_tim_ferriss(recipe)
  result.compliant
  |> should.equal(True)
  // Should have no warnings about protein source
  result.warnings
  |> should.equal([])
}

// ============================================================================
// Edge Cases
// ============================================================================

pub fn empty_ingredients_vertical_test() {
  let recipe = make_recipe("Empty", high_protein_macros(), Low, True, [])

  let result = check_vertical_diet(recipe)
  // No seed oils, compliant
  result.compliant
  |> should.equal(True)
}

pub fn empty_ingredients_tim_ferriss_test() {
  let recipe = make_recipe("Empty", high_protein_macros(), Low, False, [])

  let result = check_tim_ferriss(recipe)
  // High protein, no white carbs
  result.compliant
  |> should.equal(True)
}

pub fn case_insensitive_white_carbs_test() {
  let recipe =
    make_recipe("Mixed Case", high_protein_macros(), Low, False, [
      Ingredient("WHITE BREAD", "2 slices"),
      Ingredient("Turkey", "8oz"),
    ])

  let result = check_tim_ferriss(recipe)
  result.compliant
  |> should.equal(False)
  // Should detect uppercase "WHITE BREAD"
  result.violations
  |> should.not_equal([])
}
