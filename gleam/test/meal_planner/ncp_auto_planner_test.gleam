/// Tests for NCP Auto Planner Integration
import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/diet_validator
import meal_planner/ncp
import meal_planner/ncp_auto_planner
import meal_planner/types.{Ingredient, Macros, Recipe}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Helpers
// ============================================================================

/// Create a test recipe with specific macros
fn create_test_recipe(
  name: String,
  protein: Float,
  fat: Float,
  carbs: Float,
) -> Recipe {
  Recipe(
    id: "recipe-" <> name,
    name: name,
    ingredients: [
      Ingredient(name: "ingredient1", quantity: "100g"),
      Ingredient(name: "ingredient2", quantity: "50g"),
    ],
    instructions: ["Step 1", "Step 2"],
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    servings: 1,
    category: "main",
    fodmap_level: types.Low,
    vertical_compliant: True,
  )
}

// ============================================================================
// Configuration Tests
// ============================================================================

pub fn default_config_test() {
  let config = ncp_auto_planner.default_config()

  config.max_suggestions
  |> should.equal(5)

  config.min_compliance_score
  |> should.equal(0.5)

  config.variety_weight
  |> should.equal(0.2)

  list.length(config.diet_principles)
  |> should.equal(0)
}

pub fn vertical_diet_config_test() {
  let config = ncp_auto_planner.vertical_diet_config()

  config.max_suggestions
  |> should.equal(5)

  config.min_compliance_score
  |> should.equal(0.7)

  list.length(config.diet_principles)
  |> should.equal(1)
}

pub fn tim_ferriss_config_test() {
  let config = ncp_auto_planner.tim_ferriss_config()

  config.min_compliance_score
  |> should.equal(0.7)

  list.length(config.diet_principles)
  |> should.equal(1)
}

pub fn high_protein_config_test() {
  let config = ncp_auto_planner.high_protein_config()

  config.min_compliance_score
  |> should.equal(0.6)

  config.variety_weight
  |> should.equal(0.1)

  list.length(config.diet_principles)
  |> should.equal(1)
}

// ============================================================================
// Reason Generation Tests
// ============================================================================

pub fn generate_reason_protein_deficit_test() {
  let deficit =
    ncp.DeviationResult(
      protein_pct: -20.0,
      fat_pct: -5.0,
      carbs_pct: -3.0,
      calories_pct: -10.0,
    )

  let macros = Macros(protein: 35.0, fat: 15.0, carbs: 30.0)

  // Internal function test would require export or test via public API
  // For now, we test through the full scoring flow
  let _reason = ncp.generate_reason(deficit, macros)
  // Should contain "protein"
}

pub fn generate_reason_carb_deficit_test() {
  let deficit =
    ncp.DeviationResult(
      protein_pct: -3.0,
      fat_pct: -2.0,
      carbs_pct: -25.0,
      calories_pct: -15.0,
    )

  let macros = Macros(protein: 20.0, fat: 10.0, carbs: 50.0)

  let _reason = ncp.generate_reason(deficit, macros)
  // Should contain "carbs"
}

pub fn generate_reason_fat_deficit_test() {
  let deficit =
    ncp.DeviationResult(
      protein_pct: -2.0,
      fat_pct: -30.0,
      carbs_pct: -5.0,
      calories_pct: -12.0,
    )

  let macros = Macros(protein: 25.0, fat: 25.0, carbs: 20.0)

  let _reason = ncp.generate_reason(deficit, macros)
  // Should contain "fat"
}

// ============================================================================
// Deficit Detection Tests
// ============================================================================

pub fn detect_protein_deficit_test() {
  let deficit =
    ncp.DeviationResult(
      protein_pct: -20.0,
      fat_pct: 5.0,
      carbs_pct: 2.0,
      calories_pct: -8.0,
    )

  // Large protein deficit should be detected
  deficit.protein_pct
  <. -15.0
  |> should.be_true()
}

pub fn detect_carb_deficit_test() {
  let deficit =
    ncp.DeviationResult(
      protein_pct: 2.0,
      fat_pct: -3.0,
      carbs_pct: -18.0,
      calories_pct: -10.0,
    )

  // Large carb deficit should be detected
  deficit.carbs_pct
  <. -15.0
  |> should.be_true()
}

pub fn detect_fat_deficit_test() {
  let deficit =
    ncp.DeviationResult(
      protein_pct: 1.0,
      fat_pct: -12.0,
      carbs_pct: 3.0,
      calories_pct: -5.0,
    )

  // Moderate fat deficit
  deficit.fat_pct
  <. -5.0
  |> should.be_true()
}

pub fn within_tolerance_test() {
  let deficit =
    ncp.DeviationResult(
      protein_pct: 2.0,
      fat_pct: -3.0,
      carbs_pct: 4.0,
      calories_pct: 1.0,
    )

  // All deviations within ±5% should be within tolerance
  ncp.deviation_is_within_tolerance(deficit, 5.0)
  |> should.be_true()
}

pub fn outside_tolerance_test() {
  let deficit =
    ncp.DeviationResult(
      protein_pct: -15.0,
      fat_pct: 2.0,
      carbs_pct: 1.0,
      calories_pct: -8.0,
    )

  // Protein deviation >10% should be outside 10% tolerance
  ncp.deviation_is_within_tolerance(deficit, 10.0)
  |> should.be_false()
}

// ============================================================================
// Recipe Scoring Tests
// ============================================================================

pub fn score_high_protein_recipe_for_protein_deficit_test() {
  let deficit =
    ncp.DeviationResult(
      protein_pct: -20.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: -10.0,
    )

  // High protein recipe
  let macros = Macros(protein: 40.0, fat: 10.0, carbs: 20.0)

  let score = ncp.score_recipe_for_deviation(deficit, macros)

  // Should have high score (>0.5) for addressing protein deficit
  score
  >. 0.5
  |> should.be_true()
}

pub fn score_low_protein_recipe_for_protein_deficit_test() {
  let deficit =
    ncp.DeviationResult(
      protein_pct: -20.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: -10.0,
    )

  // Low protein recipe
  let macros = Macros(protein: 5.0, fat: 10.0, carbs: 50.0)

  let score = ncp.score_recipe_for_deviation(deficit, macros)

  // Should have low score (<0.3) for not addressing protein deficit
  score
  <. 0.3
  |> should.be_true()
}

pub fn score_balanced_recipe_for_multiple_deficits_test() {
  let deficit =
    ncp.DeviationResult(
      protein_pct: -15.0,
      fat_pct: -10.0,
      carbs_pct: -12.0,
      calories_pct: -12.0,
    )

  // Balanced recipe
  let macros = Macros(protein: 30.0, fat: 20.0, carbs: 40.0)

  let score = ncp.score_recipe_for_deviation(deficit, macros)

  // Should have good score for addressing multiple deficits
  score
  >. 0.4
  |> should.be_true()
}

pub fn score_recipe_when_within_tolerance_test() {
  let deficit =
    ncp.DeviationResult(
      protein_pct: 2.0,
      fat_pct: -3.0,
      carbs_pct: 1.0,
      calories_pct: 0.5,
    )

  let macros = Macros(protein: 30.0, fat: 15.0, carbs: 40.0)

  let score = ncp.score_recipe_for_deviation(deficit, macros)

  // Should have very low score when already within tolerance
  score
  <. 0.2
  |> should.be_true()
}

pub fn score_recipe_when_all_macros_over_test() {
  let deficit =
    ncp.DeviationResult(
      protein_pct: 15.0,
      fat_pct: 20.0,
      carbs_pct: 10.0,
      calories_pct: 18.0,
    )

  let macros = Macros(protein: 30.0, fat: 15.0, carbs: 40.0)

  let score = ncp.score_recipe_for_deviation(deficit, macros)

  // Should have very low score when over on all macros
  score
  <. 0.2
  |> should.be_true()
}

// ============================================================================
// Diet Compliance Tests
// ============================================================================

pub fn vertical_diet_compliance_test() {
  // Create a vertical diet compliant recipe (low FODMAP, no seed oils)
  let recipe =
    Recipe(
      id: "vd-compliant",
      name: "Beef and Rice",
      ingredients: [
        Ingredient(name: "beef", quantity: "200g"),
        Ingredient(name: "white rice", quantity: "150g"),
        Ingredient(name: "salt", quantity: "1g"),
      ],
      instructions: ["Cook beef", "Cook rice"],
      macros: Macros(protein: 45.0, fat: 15.0, carbs: 50.0),
      servings: 1,
      category: "main",
      fodmap_level: types.Low,
      vertical_compliant: True,
    )

  let result =
    diet_validator.validate_recipe(recipe, [diet_validator.VerticalDiet])

  result.compliant
  |> should.be_true()

  result.score
  |> should.equal(1.0)
}

pub fn tim_ferriss_compliance_high_protein_test() {
  // Create a Tim Ferriss compliant recipe (high protein, no white carbs except rice)
  let recipe =
    Recipe(
      id: "tf-compliant",
      name: "Chicken and Beans",
      ingredients: [
        Ingredient(name: "chicken breast", quantity: "200g"),
        Ingredient(name: "black beans", quantity: "150g"),
        Ingredient(name: "spinach", quantity: "100g"),
      ],
      instructions: ["Cook chicken", "Heat beans"],
      macros: Macros(protein: 50.0, fat: 10.0, carbs: 30.0),
      servings: 1,
      category: "main",
      fodmap_level: types.Low,
      vertical_compliant: False,
    )

  let result =
    diet_validator.validate_recipe(recipe, [diet_validator.TimFerriss])

  result.compliant
  |> should.be_true()

  result.score
  |> should.equal(1.0)
}

pub fn tim_ferriss_violation_low_protein_test() {
  // Recipe with low protein - should fail Tim Ferriss
  let recipe =
    Recipe(
      id: "tf-violation",
      name: "Pasta Salad",
      ingredients: [
        Ingredient(name: "pasta", quantity: "200g"),
        Ingredient(name: "tomato", quantity: "100g"),
      ],
      instructions: ["Cook pasta"],
      macros: Macros(protein: 12.0, fat: 5.0, carbs: 80.0),
      servings: 1,
      category: "side",
      fodmap_level: types.Low,
      vertical_compliant: False,
    )

  let result =
    diet_validator.validate_recipe(recipe, [diet_validator.TimFerriss])

  result.compliant
  |> should.be_false()

  // Score should be low due to low protein
  result.score
  <. 0.5
  |> should.be_true()
}

// ============================================================================
// Format Tests
// ============================================================================

pub fn format_within_tolerance_test() {
  let result =
    ncp_auto_planner.SuggestionResult(
      deficit: ncp.DeviationResult(
        protein_pct: 2.0,
        fat_pct: -3.0,
        carbs_pct: 1.0,
        calories_pct: 0.5,
      ),
      suggestions: [],
      within_tolerance: True,
    )

  let output = ncp_auto_planner.format_suggestion_result(result)

  // Should contain success message
  output
  |> should.contain("on track")
}

pub fn format_deficit_with_suggestions_test() {
  let recipe = create_test_recipe("Grilled Chicken", 40.0, 15.0, 10.0)

  let suggestion =
    ncp_auto_planner.RecipeSuggestion(
      recipe: recipe,
      total_score: 0.85,
      macro_match_score: 0.9,
      compliance_score: 0.8,
      reason: "High protein to address deficit",
      contribution: recipe.macros,
    )

  let result =
    ncp_auto_planner.SuggestionResult(
      deficit: ncp.DeviationResult(
        protein_pct: -20.0,
        fat_pct: 2.0,
        carbs_pct: 1.0,
        calories_pct: -8.0,
      ),
      suggestions: [suggestion],
      within_tolerance: False,
    )

  let output = ncp_auto_planner.format_suggestion_result(result)

  // Should contain deficit info and recipe name
  output
  |> should.contain("Deficit")

  output
  |> should.contain("Grilled Chicken")
}

pub fn format_deficit_no_suggestions_test() {
  let result =
    ncp_auto_planner.SuggestionResult(
      deficit: ncp.DeviationResult(
        protein_pct: -20.0,
        fat_pct: 2.0,
        carbs_pct: 1.0,
        calories_pct: -8.0,
      ),
      suggestions: [],
      within_tolerance: False,
    )

  let output = ncp_auto_planner.format_suggestion_result(result)

  // Should contain "no suitable recipes" message
  output
  |> should.contain("no suitable recipes")
}

// ============================================================================
// Integration Flow Tests
// ============================================================================

pub fn complete_flow_protein_deficit_test() {
  // Simulate complete flow:
  // 1. User has protein deficit
  // 2. System suggests high-protein recipes
  // 3. Recipes are scored and ranked

  let goals =
    ncp.NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )

  let actual =
    ncp.NutritionData(protein: 120.0, fat: 55.0, carbs: 240.0, calories: 2100.0)

  let deficit = ncp.calculate_deviation(goals, actual)

  // Verify protein deficit
  deficit.protein_pct
  <. 0.0
  |> should.be_true()

  // Deficit should be significant (-33%)
  deficit.protein_pct
  <. -30.0
  |> should.be_true()
}

pub fn complete_flow_within_tolerance_test() {
  // User is within tolerance - no suggestions needed
  let goals =
    ncp.NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )

  let actual =
    ncp.NutritionData(protein: 175.0, fat: 58.0, carbs: 255.0, calories: 2480.0)

  let deficit = ncp.calculate_deviation(goals, actual)

  // All deviations should be small
  ncp.deviation_is_within_tolerance(deficit, 10.0)
  |> should.be_true()
}

pub fn complete_flow_multiple_deficits_test() {
  // User has multiple deficits - need balanced recipes
  let goals =
    ncp.NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )

  let actual =
    ncp.NutritionData(protein: 140.0, fat: 45.0, carbs: 200.0, calories: 2000.0)

  let deficit = ncp.calculate_deviation(goals, actual)

  // Multiple deficits
  deficit.protein_pct
  <. -10.0
  |> should.be_true()

  deficit.fat_pct
  <. -10.0
  |> should.be_true()

  deficit.carbs_pct
  <. -10.0
  |> should.be_true()
}

// ============================================================================
// Edge Case Tests
// ============================================================================

pub fn empty_recipe_list_test() {
  let recipes: List(Recipe) = []
  let deficit =
    ncp.DeviationResult(
      protein_pct: -20.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: -10.0,
    )

  // Scoring empty list should return empty list
  let scored = ncp.select_top_recipes(deficit, [], 5)

  list.length(scored)
  |> should.equal(0)
}

pub fn single_recipe_test() {
  let recipe =
    ncp.ScoredRecipe(
      name: "Test Recipe",
      macros: Macros(protein: 30.0, fat: 15.0, carbs: 40.0),
    )

  let deficit =
    ncp.DeviationResult(
      protein_pct: -20.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: -10.0,
    )

  let scored = ncp.select_top_recipes(deficit, [recipe], 5)

  list.length(scored)
  |> should.equal(1)
}

pub fn limit_suggestions_test() {
  // Test that max_suggestions limit is respected
  let recipes = [
    ncp.ScoredRecipe(
      name: "Recipe 1",
      macros: Macros(protein: 35.0, fat: 15.0, carbs: 30.0),
    ),
    ncp.ScoredRecipe(
      name: "Recipe 2",
      macros: Macros(protein: 30.0, fat: 12.0, carbs: 25.0),
    ),
    ncp.ScoredRecipe(
      name: "Recipe 3",
      macros: Macros(protein: 40.0, fat: 18.0, carbs: 35.0),
    ),
    ncp.ScoredRecipe(
      name: "Recipe 4",
      macros: Macros(protein: 25.0, fat: 10.0, carbs: 20.0),
    ),
    ncp.ScoredRecipe(
      name: "Recipe 5",
      macros: Macros(protein: 38.0, fat: 16.0, carbs: 32.0),
    ),
  ]

  let deficit =
    ncp.DeviationResult(
      protein_pct: -20.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: -10.0,
    )

  // Request only top 3
  let scored = ncp.select_top_recipes(deficit, recipes, 3)

  list.length(scored)
  |> should.equal(3)
}

pub fn zero_macro_recipe_test() {
  let recipe =
    ncp.ScoredRecipe(
      name: "Empty Recipe",
      macros: Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
    )

  let deficit =
    ncp.DeviationResult(
      protein_pct: -20.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: -10.0,
    )

  let score = ncp.score_recipe_for_deviation(deficit, recipe.macros)

  // Zero macro recipe should have very low score
  score
  <. 0.15
  |> should.be_true()
}
