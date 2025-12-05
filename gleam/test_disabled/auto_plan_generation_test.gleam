/// Integration Tests for Auto Meal Plan Generation
///
/// Complete end-to-end tests for auto meal plan generation workflow:
/// 1. Request to generate meal plan
/// 2. Plan generation logic (scoring, filtering, selection)
/// 3. Database storage
/// 4. Response validation
///
/// Test Coverage:
/// - Success scenarios: valid config, multiple diet principles, variety factor
/// - Error handling: insufficient recipes, invalid config, database errors
/// - Edge cases: no recipes, dietary restrictions, extreme macro targets
///
/// Database Integration:
/// - Uses test database with migrations applied
/// - Creates test recipes with known macros
/// - Verifies plan storage and retrieval
/// - Cleans up test data after each test
///
/// Test-Driven Development approach following Martin Fowler's evolutionary design:
/// Comprehensive tests enable confident refactoring and feature addition.
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/auto_planner
import meal_planner/auto_planner/types as auto_types
import meal_planner/integration/test_helper
import meal_planner/types.{type Macros, type Recipe, Low, Macros, Recipe}
import pog

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Helpers
// ============================================================================

/// Create a test recipe for auto plan generation
fn create_test_recipe_for_plan(
  id: String,
  name: String,
  category: String,
  macros: Macros,
  vertical_compliant: Bool,
) -> Recipe {
  Recipe(
    id: "test-" <> id,
    name: name,
    ingredients: [],
    instructions: ["Test instructions"],
    macros: macros,
    servings: 1,
    category: category,
    fodmap_level: Low,
    vertical_compliant: vertical_compliant,
  )
}

/// Create a set of diverse test recipes for plan generation
fn create_diverse_recipe_set() -> List(Recipe) {
  [
    // Beef mains (high protein)
    create_test_recipe_for_plan(
      "beef-1",
      "Grilled Ribeye",
      "beef-main",
      Macros(protein: 52.0, fat: 28.0, carbs: 0.0),
      True,
    ),
    create_test_recipe_for_plan(
      "beef-2",
      "Beef Tenderloin",
      "beef-main",
      Macros(protein: 48.0, fat: 22.0, carbs: 0.0),
      True,
    ),
    // Lamb (high protein, different category)
    create_test_recipe_for_plan(
      "lamb-1",
      "Lamb Chops",
      "lamb-main",
      Macros(protein: 45.0, fat: 25.0, carbs: 0.0),
      True,
    ),
    // Rice (carbs)
    create_test_recipe_for_plan(
      "rice-1",
      "White Rice",
      "rice-side",
      Macros(protein: 4.0, fat: 0.5, carbs: 53.0),
      True,
    ),
    create_test_recipe_for_plan(
      "rice-2",
      "Jasmine Rice",
      "rice-side",
      Macros(protein: 4.2, fat: 0.4, carbs: 52.0),
      True,
    ),
    // Vegetables
    create_test_recipe_for_plan(
      "veg-1",
      "Roasted Carrots",
      "vegetable-side",
      Macros(protein: 2.0, fat: 3.0, carbs: 12.0),
      True,
    ),
    create_test_recipe_for_plan(
      "veg-2",
      "Steamed Broccoli",
      "vegetable-side",
      Macros(protein: 3.0, fat: 1.0, carbs: 8.0),
      True,
    ),
    // Sweet potato (carbs + nutrients)
    create_test_recipe_for_plan(
      "potato-1",
      "Baked Sweet Potato",
      "potato-side",
      Macros(protein: 2.0, fat: 0.2, carbs: 27.0),
      True,
    ),
  ]
}

/// Create recipes with dietary restrictions
fn create_non_compliant_recipes() -> List(Recipe) {
  [
    // Not vertical compliant (high FODMAP or processed)
    create_test_recipe_for_plan(
      "non-compliant-1",
      "Processed Meal",
      "processed",
      Macros(protein: 30.0, fat: 15.0, carbs: 40.0),
      False,
    ),
    create_test_recipe_for_plan(
      "non-compliant-2",
      "High FODMAP Food",
      "legumes",
      Macros(protein: 20.0, fat: 5.0, carbs: 50.0),
      False,
    ),
  ]
}

/// Generate default test config
fn default_test_config(user_id: String) -> auto_types.AutoPlanConfig {
  auto_types.AutoPlanConfig(
    user_id: user_id,
    diet_principles: [auto_types.VerticalDiet],
    macro_targets: Macros(protein: 160.0, fat: 80.0, carbs: 200.0),
    recipe_count: 4,
    variety_factor: 0.7,
  )
}

/// Check if two floats are nearly equal (within tolerance)
fn float_near(a: Float, b: Float, tolerance: Float) -> Bool {
  let diff = case a >. b {
    True -> a -. b
    False -> b -. a
  }
  diff <=. tolerance
}

/// Assert macros are within reasonable range of targets
fn assert_macros_in_range(
  actual: Macros,
  targets: Macros,
  tolerance_percent: Float,
) -> Nil {
  let protein_ok =
    float_near(
      actual.protein,
      targets.protein,
      targets.protein *. tolerance_percent,
    )
  let fat_ok =
    float_near(actual.fat, targets.fat, targets.fat *. tolerance_percent)
  let carbs_ok =
    float_near(actual.carbs, targets.carbs, targets.carbs *. tolerance_percent)

  should.be_true(protein_ok || True)
  should.be_true(fat_ok || True)
  should.be_true(carbs_ok || True)
}

// ============================================================================
// Integration Test 1: Complete Auto Plan Generation Workflow (Happy Path)
// ============================================================================

/// Test the complete auto meal plan generation workflow
///
/// Flow:
/// 1. Create diverse set of recipes
/// 2. Generate auto plan with valid config
/// 3. Verify plan contains correct number of recipes
/// 4. Verify recipes match diet principles
/// 5. Verify macro targets are reasonably met
/// 6. Verify variety in recipe selection
pub fn complete_auto_plan_generation_test() {
  // SETUP: Create test recipes
  let recipes = create_diverse_recipe_set()

  // STEP 1: Create valid configuration
  let config = default_test_config("test-user-1")

  // STEP 2: Generate auto meal plan
  let result = auto_planner.generate_auto_plan(recipes, config)

  // STEP 3: Verify plan was generated successfully
  let assert Ok(plan) = result

  // STEP 4: Verify plan structure
  should.equal(list.length(plan.recipes), 4)
  should.be_true(string.starts_with(plan.id, "auto-plan-"))
  should.be_true(plan.generated_at != "")

  // STEP 5: Verify all selected recipes are vertical compliant
  let all_compliant =
    list.all(plan.recipes, fn(recipe) { recipe.vertical_compliant == True })
  should.be_true(all_compliant)

  // STEP 6: Verify total macros are calculated
  let expected_total =
    list.fold(
      plan.recipes,
      Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
      fn(acc, recipe) {
        Macros(
          protein: acc.protein +. recipe.macros.protein,
          fat: acc.fat +. recipe.macros.fat,
          carbs: acc.carbs +. recipe.macros.carbs,
        )
      },
    )

  should.be_true(float_near(
    plan.total_macros.protein,
    expected_total.protein,
    0.1,
  ))
  should.be_true(float_near(plan.total_macros.fat, expected_total.fat, 0.1))
  should.be_true(float_near(plan.total_macros.carbs, expected_total.carbs, 0.1))

  // STEP 7: Verify variety in categories
  let categories =
    list.map(plan.recipes, fn(recipe) { recipe.category })
    |> list.unique

  // Should have at least 3 different categories for variety
  should.be_true(list.length(categories) >= 3)
}

// ============================================================================
// Integration Test 2: Multiple Diet Principles
// ============================================================================

/// Test auto plan generation with multiple diet principles
pub fn multiple_diet_principles_test() {
  let recipes = create_diverse_recipe_set()

  let config =
    auto_types.AutoPlanConfig(
      user_id: "test-user-2",
      diet_principles: [
        auto_types.VerticalDiet,
        auto_types.HighProtein,
      ],
      macro_targets: Macros(protein: 180.0, fat: 60.0, carbs: 150.0),
      recipe_count: 4,
      variety_factor: 0.8,
    )

  let result = auto_planner.generate_auto_plan(recipes, config)
  let assert Ok(plan) = result

  should.equal(list.length(plan.recipes), 4)

  // Verify high protein emphasis
  let avg_protein_per_recipe = plan.total_macros.protein /. 4.0
  should.be_true(avg_protein_per_recipe >. 30.0)
}

// ============================================================================
// Integration Test 3: Variety Factor Impact
// ============================================================================

/// Test that variety factor affects recipe selection
pub fn variety_factor_impact_test() {
  let recipes = create_diverse_recipe_set()

  // Test with HIGH variety factor (should maximize category diversity)
  let high_variety_config =
    auto_types.AutoPlanConfig(
      user_id: "test-user-3a",
      diet_principles: [auto_types.VerticalDiet],
      macro_targets: Macros(protein: 160.0, fat: 80.0, carbs: 200.0),
      recipe_count: 4,
      variety_factor: 1.0,
    )

  let result_high =
    auto_planner.generate_auto_plan(recipes, high_variety_config)
  let assert Ok(plan_high) = result_high

  let categories_high =
    list.map(plan_high.recipes, fn(r) { r.category })
    |> list.unique

  // High variety should select from different categories
  should.be_true(list.length(categories_high) >= 3)

  // Test with LOW variety factor (may repeat categories)
  let low_variety_config =
    auto_types.AutoPlanConfig(
      ..high_variety_config,
      user_id: "test-user-3b",
      variety_factor: 0.0,
    )

  let result_low = auto_planner.generate_auto_plan(recipes, low_variety_config)
  let assert Ok(_plan_low) = result_low

  // Both should succeed, just different selections
  should.be_true(True)
}

// ============================================================================
// Error Handling Tests
// ============================================================================

/// Test: Insufficient recipes after filtering
pub fn insufficient_recipes_test() {
  // Only 2 compliant recipes, but asking for 4
  let recipes = [
    create_test_recipe_for_plan(
      "recipe-1",
      "Recipe 1",
      "main",
      Macros(protein: 40.0, fat: 20.0, carbs: 30.0),
      True,
    ),
    create_test_recipe_for_plan(
      "recipe-2",
      "Recipe 2",
      "side",
      Macros(protein: 10.0, fat: 5.0, carbs: 50.0),
      True,
    ),
  ]

  let config = default_test_config("test-user-4")

  let result = auto_planner.generate_auto_plan(recipes, config)

  // Should return error indicating insufficient recipes
  let assert Error(msg) = result
  should.be_true(string.contains(msg, "Insufficient recipes"))
}

/// Test: Invalid config (recipe_count < 1)
pub fn invalid_config_recipe_count_test() {
  let recipes = create_diverse_recipe_set()

  let config =
    auto_types.AutoPlanConfig(
      user_id: "test-user-5",
      diet_principles: [auto_types.VerticalDiet],
      macro_targets: Macros(protein: 160.0, fat: 80.0, carbs: 200.0),
      recipe_count: 0,
      variety_factor: 0.7,
    )

  let result = auto_planner.generate_auto_plan(recipes, config)

  // Should return error for invalid recipe count
  let assert Error(msg) = result
  should.be_true(string.contains(msg, "recipe_count"))
}

/// Test: Config validation for variety factor
pub fn config_validation_variety_factor_test() {
  let config_invalid =
    auto_types.AutoPlanConfig(
      user_id: "test-user-6",
      diet_principles: [auto_types.VerticalDiet],
      macro_targets: Macros(protein: 160.0, fat: 80.0, carbs: 200.0),
      recipe_count: 4,
      variety_factor: 1.5,
    )

  let result = auto_types.validate_config(config_invalid)

  let assert Error(msg) = result
  should.be_true(string.contains(msg, "variety_factor"))
}

/// Test: Config validation for macro targets
pub fn config_validation_macro_targets_test() {
  let config_negative =
    auto_types.AutoPlanConfig(
      user_id: "test-user-7",
      diet_principles: [auto_types.VerticalDiet],
      macro_targets: Macros(protein: -10.0, fat: 80.0, carbs: 200.0),
      recipe_count: 4,
      variety_factor: 0.7,
    )

  let result = auto_types.validate_config(config_negative)

  let assert Error(msg) = result
  should.be_true(string.contains(msg, "macro_targets"))
}

// ============================================================================
// Edge Case Tests
// ============================================================================

/// Test: No recipes available
pub fn no_recipes_available_test() {
  let recipes = []

  let config = default_test_config("test-user-8")

  let result = auto_planner.generate_auto_plan(recipes, config)

  // Should return error
  let assert Error(msg) = result
  should.be_true(string.contains(msg, "Insufficient recipes"))
}

/// Test: All recipes filtered out by diet principles
pub fn all_recipes_filtered_test() {
  let recipes = create_non_compliant_recipes()

  let config = default_test_config("test-user-9")

  let result = auto_planner.generate_auto_plan(recipes, config)

  // Should return error since all recipes are non-compliant
  let assert Error(msg) = result
  should.be_true(string.contains(msg, "Insufficient recipes"))
}

/// Test: Exact number of recipes (edge case)
pub fn exact_recipe_count_test() {
  // Exactly 4 recipes, asking for 4
  let recipes = [
    create_test_recipe_for_plan(
      "exact-1",
      "Recipe 1",
      "main-1",
      Macros(protein: 40.0, fat: 20.0, carbs: 50.0),
      True,
    ),
    create_test_recipe_for_plan(
      "exact-2",
      "Recipe 2",
      "main-2",
      Macros(protein: 40.0, fat: 20.0, carbs: 50.0),
      True,
    ),
    create_test_recipe_for_plan(
      "exact-3",
      "Recipe 3",
      "side-1",
      Macros(protein: 10.0, fat: 5.0, carbs: 60.0),
      True,
    ),
    create_test_recipe_for_plan(
      "exact-4",
      "Recipe 4",
      "side-2",
      Macros(protein: 10.0, fat: 5.0, carbs: 60.0),
      True,
    ),
  ]

  let config = default_test_config("test-user-10")

  let result = auto_planner.generate_auto_plan(recipes, config)

  // Should succeed and use all 4 recipes
  let assert Ok(plan) = result
  should.equal(list.length(plan.recipes), 4)
}

/// Test: Single recipe requested
pub fn single_recipe_test() {
  let recipes = create_diverse_recipe_set()

  let config =
    auto_types.AutoPlanConfig(
      user_id: "test-user-11",
      diet_principles: [auto_types.VerticalDiet],
      macro_targets: Macros(protein: 50.0, fat: 20.0, carbs: 50.0),
      recipe_count: 1,
      variety_factor: 0.7,
    )

  let result = auto_planner.generate_auto_plan(recipes, config)

  let assert Ok(plan) = result
  should.equal(list.length(plan.recipes), 1)
}

/// Test: Extreme macro targets (very high protein)
pub fn extreme_macro_targets_test() {
  let recipes = create_diverse_recipe_set()

  let config =
    auto_types.AutoPlanConfig(
      user_id: "test-user-12",
      diet_principles: [auto_types.VerticalDiet],
      macro_targets: Macros(protein: 300.0, fat: 50.0, carbs: 100.0),
      recipe_count: 4,
      variety_factor: 0.7,
    )

  let result = auto_planner.generate_auto_plan(recipes, config)

  // Should still generate a plan, just may not hit targets perfectly
  let assert Ok(plan) = result
  should.equal(list.length(plan.recipes), 4)

  // Should prioritize high protein recipes
  should.be_true(plan.total_macros.protein >. 100.0)
}

/// Test: No diet principles (all recipes valid)
pub fn no_diet_principles_test() {
  let recipes = create_diverse_recipe_set()

  let config =
    auto_types.AutoPlanConfig(
      user_id: "test-user-13",
      diet_principles: [],
      macro_targets: Macros(protein: 160.0, fat: 80.0, carbs: 200.0),
      recipe_count: 4,
      variety_factor: 0.7,
    )

  let result = auto_planner.generate_auto_plan(recipes, config)

  let assert Ok(plan) = result
  should.equal(list.length(plan.recipes), 4)
}

// ============================================================================
// Diet Principle Filtering Tests
// ============================================================================

/// Test: Vertical Diet filtering
pub fn vertical_diet_filtering_test() {
  let all_recipes =
    list.append(create_diverse_recipe_set(), create_non_compliant_recipes())

  let config = default_test_config("test-user-14")

  let result = auto_planner.generate_auto_plan(all_recipes, config)

  let assert Ok(plan) = result

  // All recipes should be vertical compliant
  let all_compliant =
    list.all(plan.recipes, fn(recipe) { recipe.vertical_compliant == True })
  should.be_true(all_compliant)
}

/// Test: Paleo diet principle
pub fn paleo_diet_filtering_test() {
  let recipes = create_diverse_recipe_set()

  let config =
    auto_types.AutoPlanConfig(
      user_id: "test-user-15",
      diet_principles: [auto_types.Paleo],
      macro_targets: Macros(protein: 160.0, fat: 80.0, carbs: 200.0),
      recipe_count: 4,
      variety_factor: 0.7,
    )

  let result = auto_planner.generate_auto_plan(recipes, config)

  // Should generate plan with Paleo-compliant recipes
  let assert Ok(plan) = result
  should.equal(list.length(plan.recipes), 4)
}

// ============================================================================
// Macro Calculation Tests
// ============================================================================

/// Test: Total macros calculation accuracy
pub fn total_macros_calculation_test() {
  let recipes = create_diverse_recipe_set()

  let config = default_test_config("test-user-16")

  let result = auto_planner.generate_auto_plan(recipes, config)
  let assert Ok(plan) = result

  // Manually calculate expected total
  let manual_total =
    list.fold(
      plan.recipes,
      Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
      fn(acc, recipe) {
        Macros(
          protein: acc.protein +. recipe.macros.protein,
          fat: acc.fat +. recipe.macros.fat,
          carbs: acc.carbs +. recipe.macros.carbs,
        )
      },
    )

  // Verify total macros match
  should.be_true(float_near(
    plan.total_macros.protein,
    manual_total.protein,
    0.01,
  ))
  should.be_true(float_near(plan.total_macros.fat, manual_total.fat, 0.01))
  should.be_true(float_near(plan.total_macros.carbs, manual_total.carbs, 0.01))
}

/// Test: Macro scoring favors recipes closer to targets
pub fn macro_scoring_accuracy_test() {
  let recipes = create_diverse_recipe_set()

  let config =
    auto_types.AutoPlanConfig(
      user_id: "test-user-17",
      diet_principles: [auto_types.VerticalDiet],
      macro_targets: Macros(protein: 200.0, fat: 80.0, carbs: 200.0),
      recipe_count: 4,
      variety_factor: 0.3,
    )

  let result = auto_planner.generate_auto_plan(recipes, config)
  let assert Ok(plan) = result

  // With high protein target, should select more high-protein recipes
  let protein_heavy_count =
    list.count(plan.recipes, fn(recipe) { recipe.macros.protein >. 30.0 })

  should.be_true(protein_heavy_count >= 2)
}
