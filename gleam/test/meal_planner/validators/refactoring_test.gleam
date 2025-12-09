/// Test to verify the diet validator refactoring works correctly
/// This ensures that the polymorphic implementation produces the same results
/// as the original conditional implementation.
import gleam/list
import gleeunit/should
import meal_planner/diet_validator.{
  type DietPrinciple, HighProtein, Keto, Paleo, TimFerriss, VerticalDiet,
}
import meal_planner/types.{type Recipe, Low, Macros, Recipe}
import meal_planner/validators/high_protein
import meal_planner/validators/keto
import meal_planner/validators/tim_ferriss
import meal_planner/validators/vertical_diet

// ============================================================================
// Test Data
// ============================================================================

fn make_test_recipe(
  name: String,
  protein: Float,
  carbs: Float,
  fat: Float,
) -> Recipe {
  Recipe(
    id: "test-1",
    name: name,
    ingredients: [],
    instructions: [],
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    servings: 1,
    category: "test",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

// ============================================================================
// Polymorphism Tests
// ============================================================================

pub fn validate_recipe_delegates_to_keto_validator_test() {
  let recipe = make_test_recipe("Low carb meal", 30.0, 5.0, 20.0)

  // Call via polymorphic dispatch
  let result_via_main = diet_validator.validate_recipe(recipe, [Keto])

  // Call validator directly
  let result_direct = keto.validate(recipe)

  // Both should produce same result
  result_via_main.compliant
  |> should.equal(result_direct.compliant)

  result_via_main.score
  |> should.equal(result_direct.score)
}

pub fn validate_recipe_delegates_to_high_protein_validator_test() {
  let recipe = make_test_recipe("High protein meal", 50.0, 20.0, 15.0)

  let result_via_main = diet_validator.validate_recipe(recipe, [HighProtein])
  let result_direct = high_protein.validate(recipe)

  result_via_main.compliant
  |> should.equal(result_direct.compliant)

  result_via_main.score
  |> should.equal(result_direct.score)
}

pub fn validate_recipe_delegates_to_tim_ferriss_validator_test() {
  let recipe = make_test_recipe("Slow carb meal", 35.0, 30.0, 15.0)

  let result_via_main = diet_validator.validate_recipe(recipe, [TimFerriss])
  let result_direct = tim_ferriss.validate(recipe)

  result_via_main.compliant
  |> should.equal(result_direct.compliant)
}

pub fn validate_recipe_delegates_to_vertical_diet_validator_test() {
  let recipe = make_test_recipe("Vertical diet meal", 30.0, 40.0, 15.0)

  let result_via_main = diet_validator.validate_recipe(recipe, [VerticalDiet])
  let result_direct = vertical_diet.validate(recipe)

  result_via_main.compliant
  |> should.equal(result_direct.compliant)
}

pub fn validate_recipe_combines_multiple_validators_test() {
  let recipe = make_test_recipe("Multi-diet meal", 45.0, 10.0, 20.0)

  // Validate against multiple diets
  let result = diet_validator.validate_recipe(recipe, [Keto, HighProtein])

  // Should combine results
  // Both Keto (low carb) and HighProtein should be satisfied
  result.compliant
  |> should.be_true()

  // Score should be average of both validators (positive value)
  should.be_true(result.score >=. 0.0)
}

pub fn validate_recipe_empty_principles_returns_compliant_test() {
  let recipe = make_test_recipe("Any meal", 10.0, 50.0, 10.0)

  let result = diet_validator.validate_recipe(recipe, [])

  result.compliant
  |> should.be_true()

  result.score
  |> should.equal(1.0)

  result.violations
  |> list.is_empty()
  |> should.be_true()
}

// ============================================================================
// Backward Compatibility Tests
// ============================================================================

pub fn deprecated_check_keto_still_works_test() {
  let recipe = make_test_recipe("Keto meal", 30.0, 5.0, 60.0)

  // Old API should still work
  let result = diet_validator.check_keto(recipe)

  result.compliant
  |> should.be_true()
}

pub fn deprecated_check_high_protein_still_works_test() {
  let recipe = make_test_recipe("Protein meal", 45.0, 20.0, 15.0)

  let result = diet_validator.check_high_protein(recipe)

  result.compliant
  |> should.be_true()
}
