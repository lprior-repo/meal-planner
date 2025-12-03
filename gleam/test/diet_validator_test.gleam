/// Tests for diet principle validation module
import gleeunit/should
import meal_planner/diet_validator.{
  type ComplianceResult, type DietPrinciple, ComplianceResult, TimFerriss,
  VerticalDiet, calculate_protein_per_serving, check_tim_ferriss,
  check_vertical_diet, has_seed_oils, has_white_carbs, validate_recipe,
}
import shared/types.{
  type FodmapLevel, type Ingredient, type Macros, type Recipe, Ingredient, Low,
  Macros, Recipe,
}

// ============================================================================
// Test Helper Functions
// ============================================================================

fn create_test_recipe(
  name: String,
  ingredients: List(Ingredient),
  protein: Float,
  fat: Float,
  carbs: Float,
  servings: Int,
  fodmap: FodmapLevel,
) -> Recipe {
  Recipe(
    id: "test-" <> name,
    name: name,
    ingredients: ingredients,
    instructions: ["Test instruction"],
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    servings: servings,
    category: "test",
    fodmap_level: fodmap,
    vertical_compliant: False,
  )
}

// ============================================================================
// Vertical Diet Tests
// ============================================================================

pub fn vertical_diet_compliant_recipe_test() {
  // Beef + white rice + spinach = compliant
  let recipe =
    create_test_recipe(
      "Beef and Rice",
      [
        Ingredient("beef", "8oz"),
        Ingredient("white rice", "1 cup"),
        Ingredient("spinach", "2 cups"),
      ],
      40.0,
      15.0,
      50.0,
      1,
      Low,
    )

  let result = check_vertical_diet(recipe)

  result.compliant
  |> should.be_true

  result.score
  |> should.equal(1.0)

  result.violations
  |> should.equal([])
}

pub fn vertical_diet_seed_oil_violation_test() {
  // Chicken with canola oil = not compliant
  let recipe =
    create_test_recipe(
      "Chicken with Oil",
      [
        Ingredient("chicken breast", "6oz"),
        Ingredient("canola oil", "1 tbsp"),
        Ingredient("white rice", "1 cup"),
      ],
      35.0,
      10.0,
      45.0,
      1,
      Low,
    )

  let result = check_vertical_diet(recipe)

  result.compliant
  |> should.be_false

  result.violations
  |> should.equal(["Contains seed oil: canola oil"])
}

pub fn vertical_diet_multiple_seed_oils_test() {
  // Multiple seed oils should be detected
  let recipe =
    create_test_recipe(
      "Mixed Oils",
      [
        Ingredient("chicken", "6oz"),
        Ingredient("soybean oil", "1 tbsp"),
        Ingredient("sunflower oil", "1 tsp"),
      ],
      30.0,
      15.0,
      20.0,
      1,
      Low,
    )

  let result = check_vertical_diet(recipe)

  result.compliant
  |> should.be_false

  result.violations
  |> should.equal([
    "Contains seed oil: soybean oil",
    "Contains seed oil: sunflower oil",
  ])
}

pub fn vertical_diet_garlic_infused_oil_allowed_test() {
  // Garlic-infused oil should be allowed (low FODMAP exception)
  let recipe =
    create_test_recipe(
      "Steak with Infused Oil",
      [
        Ingredient("ribeye steak", "8oz"),
        Ingredient("garlic-infused oil", "1 tbsp"),
        Ingredient("white rice", "1 cup"),
      ],
      45.0,
      25.0,
      45.0,
      1,
      Low,
    )

  let result = check_vertical_diet(recipe)

  result.compliant
  |> should.be_true

  result.score
  |> should.equal(1.0)
}

pub fn vertical_diet_olive_oil_allowed_test() {
  // Olive oil and coconut oil are allowed
  let recipe =
    create_test_recipe(
      "Eggs with Good Oils",
      [
        Ingredient("eggs", "3 large"),
        Ingredient("olive oil", "1 tbsp"),
        Ingredient("coconut oil", "1 tsp"),
      ],
      18.0,
      20.0,
      2.0,
      1,
      Low,
    )

  let result = check_vertical_diet(recipe)

  result.compliant
  |> should.be_true
}

pub fn vertical_diet_preferred_proteins_test() {
  // Test that preferred proteins (beef, chicken, eggs) get high scores
  let beef_recipe =
    create_test_recipe(
      "Beef Bowl",
      [Ingredient("ground beef", "8oz"), Ingredient("white rice", "1 cup")],
      40.0,
      20.0,
      45.0,
      1,
      Low,
    )

  let beef_result = check_vertical_diet(beef_recipe)

  beef_result.score
  |> should.equal(1.0)

  beef_result.warnings
  |> should.equal([])
}

pub fn vertical_diet_preferred_carbs_test() {
  // White rice and sweet potatoes are preferred carbs
  let recipe =
    create_test_recipe(
      "Rice and Potatoes",
      [
        Ingredient("chicken", "6oz"),
        Ingredient("white rice", "1 cup"),
        Ingredient("sweet potato", "1 medium"),
      ],
      35.0,
      8.0,
      60.0,
      1,
      Low,
    )

  let result = check_vertical_diet(recipe)

  result.compliant
  |> should.be_true

  result.score
  |> should.equal(1.0)
}

// ============================================================================
// Tim Ferriss Diet Tests
// ============================================================================

pub fn tim_ferriss_compliant_recipe_test() {
  // Steak + black beans = compliant (high protein + legumes)
  let recipe =
    create_test_recipe(
      "Steak and Beans",
      [Ingredient("steak", "8oz"), Ingredient("black beans", "1 cup")],
      50.0,
      15.0,
      30.0,
      1,
      Low,
    )

  let result = check_tim_ferriss(recipe)

  result.compliant
  |> should.be_true

  result.score
  |> should.equal(1.0)
}

pub fn tim_ferriss_white_carbs_violation_test() {
  // Pasta + chicken = not compliant (white carbs)
  let recipe =
    create_test_recipe(
      "Pasta with Chicken",
      [
        Ingredient("chicken breast", "6oz"),
        Ingredient("pasta", "2 cups"),
        Ingredient("tomato sauce", "1/2 cup"),
      ],
      40.0,
      8.0,
      60.0,
      1,
      Low,
    )

  let result = check_tim_ferriss(recipe)

  result.compliant
  |> should.be_false

  result.violations
  |> should.equal(["Contains white carbs: pasta"])
}

pub fn tim_ferriss_low_protein_violation_test() {
  // Low protein recipe should get a warning
  let recipe =
    create_test_recipe(
      "Veggie Bowl",
      [
        Ingredient("mixed vegetables", "2 cups"),
        Ingredient("quinoa", "1 cup"),
      ],
      15.0,
      5.0,
      45.0,
      1,
      Low,
    )

  let result = check_tim_ferriss(recipe)

  result.compliant
  |> should.be_false

  result.warnings
  |> should.equal(["Low protein per serving: 15.0g (target: 30g+)"])
}

pub fn tim_ferriss_white_rice_allowed_test() {
  // White rice can be allowed with post-workout flag (for now, we'll mark it as a warning)
  let recipe =
    create_test_recipe(
      "Chicken and Rice",
      [Ingredient("chicken", "8oz"), Ingredient("white rice", "1 cup")],
      40.0,
      8.0,
      45.0,
      1,
      Low,
    )

  let result = check_tim_ferriss(recipe)

  // Should have a warning about white rice
  result.warnings
  |> should.equal(["Contains white rice (allowed post-workout)"])
}

pub fn tim_ferriss_requires_legumes_or_quality_protein_test() {
  // Should have either legumes OR quality protein
  let with_legumes =
    create_test_recipe(
      "Lentil Bowl",
      [
        Ingredient("lentils", "1.5 cups"),
        Ingredient("vegetables", "2 cups"),
      ],
      35.0,
      5.0,
      50.0,
      1,
      Low,
    )

  let legumes_result = check_tim_ferriss(with_legumes)

  legumes_result.compliant
  |> should.be_true
}

// ============================================================================
// Helper Function Tests
// ============================================================================

pub fn has_seed_oils_detects_canola_test() {
  has_seed_oils([Ingredient("canola oil", "1 tbsp")])
  |> should.be_true
}

pub fn has_seed_oils_detects_soybean_test() {
  has_seed_oils([Ingredient("soybean oil", "1 tbsp")])
  |> should.be_true
}

pub fn has_seed_oils_detects_corn_test() {
  has_seed_oils([Ingredient("corn oil", "1 tbsp")])
  |> should.be_true
}

pub fn has_seed_oils_detects_sunflower_test() {
  has_seed_oils([Ingredient("sunflower oil", "1 tbsp")])
  |> should.be_true
}

pub fn has_seed_oils_allows_olive_oil_test() {
  has_seed_oils([Ingredient("olive oil", "1 tbsp")])
  |> should.be_false
}

pub fn has_seed_oils_allows_coconut_oil_test() {
  has_seed_oils([Ingredient("coconut oil", "1 tbsp")])
  |> should.be_false
}

pub fn has_seed_oils_allows_butter_test() {
  has_seed_oils([Ingredient("butter", "1 tbsp")])
  |> should.be_false
}

pub fn calculate_protein_per_serving_test() {
  let recipe =
    create_test_recipe(
      "High Protein",
      [Ingredient("chicken", "8oz")],
      40.0,
      10.0,
      5.0,
      1,
      Low,
    )

  calculate_protein_per_serving(recipe)
  |> should.equal(40.0)
}

pub fn calculate_protein_per_serving_multiple_servings_test() {
  let recipe =
    create_test_recipe(
      "High Protein",
      [Ingredient("chicken", "16oz")],
      40.0,
      10.0,
      5.0,
      2,
      Low,
    )

  // Macros are stored per serving, so this should return 40.0 directly
  calculate_protein_per_serving(recipe)
  |> should.equal(40.0)
}

pub fn has_white_carbs_detects_pasta_test() {
  has_white_carbs([Ingredient("pasta", "2 cups")])
  |> should.be_true
}

pub fn has_white_carbs_detects_bread_test() {
  has_white_carbs([Ingredient("white bread", "2 slices")])
  |> should.be_true
}

pub fn has_white_carbs_detects_tortilla_test() {
  has_white_carbs([Ingredient("flour tortilla", "2 pieces")])
  |> should.be_true
}

pub fn has_white_carbs_allows_quinoa_test() {
  has_white_carbs([Ingredient("quinoa", "1 cup")])
  |> should.be_false
}

pub fn has_white_carbs_allows_sweet_potato_test() {
  has_white_carbs([Ingredient("sweet potato", "1 medium")])
  |> should.be_false
}

// ============================================================================
// Validate Recipe with Multiple Principles Tests
// ============================================================================

pub fn validate_recipe_both_principles_compliant_test() {
  // A recipe that complies with both diets
  let recipe =
    create_test_recipe(
      "Perfect Bowl",
      [Ingredient("steak", "8oz"), Ingredient("black beans", "1 cup")],
      50.0,
      15.0,
      30.0,
      1,
      Low,
    )

  let result = validate_recipe(recipe, [VerticalDiet, TimFerriss])

  result.compliant
  |> should.be_true

  result.score
  |> should.equal(1.0)
}

pub fn validate_recipe_one_principle_fails_test() {
  // Compliant with Vertical but not Tim Ferriss (low protein)
  let recipe =
    create_test_recipe(
      "Rice Bowl",
      [Ingredient("white rice", "2 cups")],
      10.0,
      2.0,
      60.0,
      1,
      Low,
    )

  let result = validate_recipe(recipe, [VerticalDiet, TimFerriss])

  result.compliant
  |> should.be_false
}

pub fn validate_recipe_empty_principles_test() {
  // Empty principles list should return compliant result
  let recipe =
    create_test_recipe(
      "Any Recipe",
      [Ingredient("anything", "1 cup")],
      20.0,
      10.0,
      30.0,
      1,
      Low,
    )

  let result = validate_recipe(recipe, [])

  result.compliant
  |> should.be_true

  result.score
  |> should.equal(1.0)
}
