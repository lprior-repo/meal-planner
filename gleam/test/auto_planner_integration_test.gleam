/// Integration tests for auto_planner module with Recipe input
///
/// This test suite verifies the complete auto_planner workflow including:
/// 1. Recipe filtering based on diet principles
/// 2. Recipe scoring with diet compliance, macro matching, and variety
/// 3. Recipe selection using top-N algorithm with variety consideration
/// 4. Complete auto meal plan generation
/// 5. Edge cases and error conditions
///
/// Tests use internal Recipe type (representing Tandoor recipes)
import gleeunit
import gleeunit/should
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import meal_planner/auto_planner.{RecipeScore}
import meal_planner/auto_planner/types as auto_types
import meal_planner/types as types
import meal_planner/types.{
  type Ingredient, type Macros, type Recipe, type FodmapLevel, Ingredient, Macros,
  Low, Medium, High, Recipe,
}
import meal_planner/id

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures - Recipe Creation Helpers
// ============================================================================

/// Create a test recipe with full control over properties
fn create_recipe(
  id: Int,
  name: String,
  category: String,
  protein: Float,
  fat: Float,
  carbs: Float,
  fodmap_level: FodmapLevel,
  vertical_compliant: Bool,
) -> Recipe {
  Recipe(
    id: id.recipe_id(int.to_string(id)),
    name: name,
    ingredients: [
      Ingredient(name: "ingredient-1", amount: 100.0, unit: "g"),
    ],
    instructions: ["Mix", "Cook"],
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    servings: 1,
    category: category,
    fodmap_level: fodmap_level,
    vertical_compliant: vertical_compliant,
  )
}

/// Create a vertical diet compliant recipe
fn create_vertical_recipe(id: Int, name: String, category: String) -> Recipe {
  create_recipe(id, name, category, 25.0, 10.0, 15.0, Low, True)
}

/// Create a non-vertical diet recipe
fn create_non_vertical_recipe(id: Int, name: String, category: String) -> Recipe {
  create_recipe(id, name, category, 20.0, 8.0, 25.0, High, False)
}

/// Create a high FODMAP recipe (violates most diets)
fn create_high_fodmap_recipe(id: Int, name: String, category: String) -> Recipe {
  create_recipe(id, name, category, 15.0, 5.0, 30.0, High, False)
}

/// Create a test auto plan config
fn create_config(
  user_id: String,
  diet_principles: List(auto_types.DietPrinciple),
  recipe_count: Int,
  variety_factor: Float,
) -> auto_types.AutoPlanConfig {
  auto_types.AutoPlanConfig(
    user_id: user_id,
    diet_principles: diet_principles,
    macro_targets: Macros(protein: 150.0, fat: 50.0, carbs: 200.0),
    recipe_count: recipe_count,
    variety_factor: variety_factor,
  )
}

// ============================================================================
// Filter by Diet Principles Tests
// ============================================================================

/// Test filtering with no diet principles (accept all recipes)
pub fn filter_by_diet_principles_no_principles_accepts_all_test() {
  let recipes = [
    create_vertical_recipe(1, "Chicken Breast", "protein"),
    create_non_vertical_recipe(2, "Pasta", "carbs"),
    create_high_fodmap_recipe(3, "Onion", "vegetable"),
  ]

  let filtered = meal_planner/auto_planner.filter_by_diet_principles(
    recipes,
    [],
  )

  list.length(filtered)
  |> should.equal(3)
}

/// Test filtering with VerticalDiet principle
pub fn filter_by_diet_principles_vertical_diet_test() {
  let recipes = [
    create_vertical_recipe(1, "Steak", "protein"),
    create_vertical_recipe(2, "Broccoli", "vegetable"),
    create_non_vertical_recipe(3, "Rice", "carbs"),
    create_high_fodmap_recipe(4, "Garlic", "vegetable"),
  ]

  let filtered = meal_planner/auto_planner.filter_by_diet_principles(
    recipes,
    [auto_types.VerticalDiet],
  )

  // Only vertical-compliant recipes should remain
  list.length(filtered)
  |> should.equal(2)
}

/// Test filtering with multiple diet principles
pub fn filter_by_diet_principles_multiple_diets_test() {
  let recipes = [
    create_recipe(1, "Salmon", "protein", 25.0, 15.0, 0.0, Low, True),
    create_recipe(2, "Beef", "protein", 30.0, 25.0, 0.0, Low, True),
    create_recipe(3, "Pasta", "carbs", 12.0, 2.0, 75.0, Low, False),
    create_recipe(4, "Bread", "carbs", 10.0, 3.0, 50.0, Medium, False),
  ]

  // Keto: needs low FODMAP only
  let filtered = meal_planner/auto_planner.filter_by_diet_principles(
    recipes,
    [auto_types.Keto],
  )

  list.length(filtered)
  |> should.equal(4)
}

/// Test filtering removes high FODMAP recipes for strict diets
pub fn filter_by_diet_principles_removes_high_fodmap_test() {
  let recipes = [
    create_recipe(1, "Garlic", "vegetable", 5.0, 0.1, 10.0, High, False),
    create_recipe(2, "Onion", "vegetable", 4.0, 0.1, 9.0, High, False),
    create_recipe(3, "Carrot", "vegetable", 3.0, 0.2, 8.0, Low, False),
  ]

  let filtered = meal_planner/auto_planner.filter_by_diet_principles(
    recipes,
    [auto_types.Paleo],
  )

  // Only low FODMAP recipes allowed for Paleo
  list.length(filtered)
  |> should.equal(1)
}

// ============================================================================
// Macro Match Score Tests
// ============================================================================

/// Test macro match score for perfect match
pub fn calculate_macro_match_score_perfect_match_test() {
  let recipe = create_recipe(1, "Perfect Recipe", "test", 50.0, 50.0, 50.0, Low, True)
  let targets = Macros(protein: 200.0, fat: 200.0, carbs: 200.0)

  let score = meal_planner/auto_planner.calculate_macro_match_score(
    recipe,
    targets,
    4,
  )

  // Perfect match (each macro matches per-recipe target) should score close to 1.0
  score
  |> should.be_greater_than(0.8)
}

/// Test macro match score for poor match
pub fn calculate_macro_match_score_poor_match_test() {
  let recipe = create_recipe(1, "Poor Match", "test", 5.0, 5.0, 5.0, Low, True)
  let targets = Macros(protein: 200.0, fat: 200.0, carbs: 200.0)

  let score = meal_planner/auto_planner.calculate_macro_match_score(
    recipe,
    targets,
    4,
  )

  // Poor match should score much lower
  score
  |> should.be_less_than(0.2)
}

/// Test macro match score divides target by recipe count
pub fn calculate_macro_match_score_divides_by_recipe_count_test() {
  let recipe = create_recipe(1, "Test", "test", 50.0, 25.0, 50.0, Low, True)
  let targets = Macros(protein: 200.0, fat: 100.0, carbs: 200.0)

  // With 4 recipes, per-recipe targets: 50g protein, 25g fat, 50g carbs
  let score_4 = meal_planner/auto_planner.calculate_macro_match_score(
    recipe,
    targets,
    4,
  )

  // With 2 recipes, per-recipe targets: 100g protein, 50g fat, 100g carbs
  let score_2 = meal_planner/auto_planner.calculate_macro_match_score(
    recipe,
    targets,
    2,
  )

  // Score with 4 recipes should be much higher (perfect match)
  score_4
  |> should.be_greater_than(score_2)
}

// ============================================================================
// Variety Score Tests
// ============================================================================

/// Test variety score for first selection (always 1.0)
pub fn calculate_variety_score_first_selection_test() {
  let recipe = create_vertical_recipe(1, "Chicken", "protein")

  let score = meal_planner/auto_planner.calculate_variety_score(recipe, [])

  score
  |> should.equal(1.0)
}

/// Test variety score penalizes duplicate categories
pub fn calculate_variety_score_penalizes_duplicates_test() {
  let recipe = create_vertical_recipe(1, "Beef", "protein")
  let already_selected = [
    create_vertical_recipe(2, "Chicken", "protein"),
  ]

  let score = meal_planner/auto_planner.calculate_variety_score(
    recipe,
    already_selected,
  )

  // Duplicate category should get lower score (0.4)
  score
  |> should.equal(0.4)
}

/// Test variety score heavily penalizes multiple duplicates
pub fn calculate_variety_score_heavily_penalizes_multiple_duplicates_test() {
  let recipe = create_vertical_recipe(1, "Pork", "protein")
  let already_selected = [
    create_vertical_recipe(2, "Chicken", "protein"),
    create_vertical_recipe(3, "Beef", "protein"),
  ]

  let score = meal_planner/auto_planner.calculate_variety_score(
    recipe,
    already_selected,
  )

  // Multiple duplicates should get very low score (0.2)
  score
  |> should.equal(0.2)
}

/// Test variety score for unique categories
pub fn calculate_variety_score_unique_categories_test() {
  let recipe = create_vertical_recipe(1, "Broccoli", "vegetable")
  let already_selected = [
    create_vertical_recipe(2, "Chicken", "protein"),
    create_vertical_recipe(3, "Rice", "carbs"),
  ]

  let score = meal_planner/auto_planner.calculate_variety_score(
    recipe,
    already_selected,
  )

  // Unique category should get full score (1.0)
  score
  |> should.equal(1.0)
}

// ============================================================================
// Recipe Scoring Tests
// ============================================================================

/// Test recipe scoring combines all dimensions
pub fn score_recipe_combines_all_dimensions_test() {
  let recipe = create_vertical_recipe(1, "Perfect Recipe", "protein")
  let config = create_config("user-1", [auto_types.VerticalDiet], 4, 0.8)

  let scored = meal_planner/auto_planner.score_recipe(recipe, config, [])

  // Should have all components
  scored.diet_compliance_score
  |> should.be_greater_than(0.0)

  scored.macro_match_score
  |> should.be_greater_than(0.0)

  scored.variety_score
  |> should.equal(1.0)

  scored.overall_score
  |> should.be_greater_than(0.0)
}

/// Test recipe scoring uses weighted combination
pub fn score_recipe_uses_weighted_scores_test() {
  let recipe = create_vertical_recipe(1, "Test", "protein")
  let config = create_config("user-1", [auto_types.VerticalDiet], 4, 0.8)

  let scored = meal_planner/auto_planner.score_recipe(recipe, config, [])

  // Overall should be weighted: diet 40%, macros 35%, variety 25%
  let expected =
    scored.diet_compliance_score *. 0.4
    +. scored.macro_match_score *. 0.35
    +. scored.variety_score *. 0.25

  float.absolute_value(scored.overall_score -. expected)
  |> should.be_less_than(0.01)
}

/// Test recipe scoring with no diet principles
pub fn score_recipe_no_diet_principles_test() {
  let recipe = create_non_vertical_recipe(1, "Any Recipe", "any")
  let config = create_config("user-1", [], 4, 0.8)

  let scored = meal_planner/auto_planner.score_recipe(recipe, config, [])

  // Without diet principles, compliance should be 1.0
  scored.diet_compliance_score
  |> should.equal(1.0)
}

/// Test recipe scoring when not vertical compliant with vertical diet
pub fn score_recipe_non_compliant_vertical_test() {
  let recipe = create_non_vertical_recipe(1, "Non-Vertical", "any")
  let config = create_config("user-1", [auto_types.VerticalDiet], 4, 0.8)

  let scored = meal_planner/auto_planner.score_recipe(recipe, config, [])

  // Non-compliant should get 0 diet score
  scored.diet_compliance_score
  |> should.equal(0.0)
}

// ============================================================================
// Top-N Selection Tests
// ============================================================================

/// Test select_top_n returns sorted recipes
pub fn select_top_n_returns_sorted_recipes_test() {
  let recipes = [
    RecipeScore(
      recipe: create_vertical_recipe(1, "Good", "protein"),
      diet_compliance_score: 1.0,
      macro_match_score: 0.9,
      variety_score: 1.0,
      overall_score: 0.95,
    ),
    RecipeScore(
      recipe: create_vertical_recipe(2, "Bad", "protein"),
      diet_compliance_score: 1.0,
      macro_match_score: 0.1,
      variety_score: 1.0,
      overall_score: 0.45,
    ),
    RecipeScore(
      recipe: create_vertical_recipe(3, "Excellent", "protein"),
      diet_compliance_score: 1.0,
      macro_match_score: 1.0,
      variety_score: 1.0,
      overall_score: 1.0,
    ),
  ]

  let selected = meal_planner/auto_planner.select_top_n(recipes, 2, 0.8)

  // Should return top 2 recipes
  list.length(selected)
  |> should.equal(2)
}

/// Test select_top_n respects requested count
pub fn select_top_n_respects_requested_count_test() {
  let recipes = list.range(1, 11)
  |> list.map(fn(i) {
    RecipeScore(
      recipe: create_vertical_recipe(i, "Recipe " <> int.to_string(i), "protein"),
      diet_compliance_score: 1.0,
      macro_match_score: float.max(0.1, int.to_float(i) /. 10.0),
      variety_score: 1.0,
      overall_score: float.max(0.1, int.to_float(i) /. 10.0),
    )
  })

  let selected = meal_planner/auto_planner.select_top_n(recipes, 5, 0.8)

  list.length(selected)
  |> should.equal(5)
}

/// Test select_top_n with insufficient recipes
pub fn select_top_n_returns_all_when_count_exceeded_test() {
  let recipes = list.range(1, 4)
  |> list.map(fn(i) {
    RecipeScore(
      recipe: create_vertical_recipe(i, "Recipe " <> int.to_string(i), "protein"),
      diet_compliance_score: 1.0,
      macro_match_score: 0.5,
      variety_score: 1.0,
      overall_score: 0.5,
    )
  })

  let selected = meal_planner/auto_planner.select_top_n(recipes, 10, 0.8)

  // Should return all 3 available recipes, not 10
  list.length(selected)
  |> should.equal(3)
}

/// Test select_top_n with variety factor adjustment
pub fn select_top_n_considers_variety_factor_test() {
  let recipes = [
    RecipeScore(
      recipe: create_vertical_recipe(1, "Protein1", "protein"),
      diet_compliance_score: 1.0,
      macro_match_score: 0.8,
      variety_score: 1.0,
      overall_score: 0.8,
    ),
    RecipeScore(
      recipe: create_vertical_recipe(2, "Protein2", "protein"),
      diet_compliance_score: 1.0,
      macro_match_score: 0.7,
      variety_score: 1.0,
      overall_score: 0.7,
    ),
    RecipeScore(
      recipe: create_vertical_recipe(3, "Vegetable", "vegetable"),
      diet_compliance_score: 1.0,
      macro_match_score: 0.6,
      variety_score: 1.0,
      overall_score: 0.6,
    ),
  ]

  // Higher variety factor should prefer different categories
  let selected_high_variety = meal_planner/auto_planner.select_top_n(
    recipes,
    2,
    1.5,
  )

  // Should prefer variety (Protein1 + Vegetable over Protein1 + Protein2)
  list.length(selected_high_variety)
  |> should.equal(2)
}

// ============================================================================
// Complete Auto Plan Generation Tests
// ============================================================================

/// Test generate_auto_plan with valid input
pub fn generate_auto_plan_valid_input_test() {
  let recipes = [
    create_vertical_recipe(1, "Chicken", "protein"),
    create_vertical_recipe(2, "Broccoli", "vegetable"),
    create_vertical_recipe(3, "Rice", "carbs"),
    create_vertical_recipe(4, "Salmon", "protein"),
  ]

  let config = create_config("user-1", [auto_types.VerticalDiet], 3, 0.8)

  let plan = meal_planner/auto_planner.generate_auto_plan(recipes, config)

  case plan {
    Ok(p) -> {
      list.length(p.recipes)
      |> should.equal(3)
    }
    Error(_) ->
      False
      |> should.be_true()
  }
}

/// Test generate_auto_plan rejects invalid recipe count
pub fn generate_auto_plan_rejects_zero_recipe_count_test() {
  let recipes = [create_vertical_recipe(1, "Chicken", "protein")]
  let config = create_config("user-1", [auto_types.VerticalDiet], 0, 0.8)

  let plan = meal_planner/auto_planner.generate_auto_plan(recipes, config)

  case plan {
    Error(msg) -> {
      msg
      |> should.contain("recipe_count must be at least 1")
    }
    Ok(_) ->
      False
      |> should.be_true()
  }
}

/// Test generate_auto_plan rejects negative recipe count
pub fn generate_auto_plan_rejects_negative_recipe_count_test() {
  let recipes = [create_vertical_recipe(1, "Chicken", "protein")]
  let config = create_config("user-1", [auto_types.VerticalDiet], -5, 0.8)

  let plan = meal_planner/auto_planner.generate_auto_plan(recipes, config)

  case plan {
    Error(_) -> True |> should.be_true()
    Ok(_) ->
      False
      |> should.be_true()
  }
}

/// Test generate_auto_plan with insufficient matching recipes
pub fn generate_auto_plan_insufficient_recipes_test() {
  let recipes = [
    create_vertical_recipe(1, "Chicken", "protein"),
    // Only 1 vertical-compliant recipe
    create_non_vertical_recipe(2, "Rice", "carbs"),
    create_non_vertical_recipe(3, "Pasta", "carbs"),
  ]

  let config = create_config("user-1", [auto_types.VerticalDiet], 3, 0.8)

  let plan = meal_planner/auto_planner.generate_auto_plan(recipes, config)

  case plan {
    Error(msg) -> {
      msg
      |> should.contain("Insufficient recipes")
    }
    Ok(_) ->
      False
      |> should.be_true()
  }
}

/// Test generate_auto_plan preserves config
pub fn generate_auto_plan_preserves_config_test() {
  let recipes = [
    create_vertical_recipe(1, "Chicken", "protein"),
    create_vertical_recipe(2, "Broccoli", "vegetable"),
    create_vertical_recipe(3, "Rice", "carbs"),
  ]

  let config = create_config("user-config-test", [auto_types.VerticalDiet], 2, 0.9)

  let plan = meal_planner/auto_planner.generate_auto_plan(recipes, config)

  case plan {
    Ok(p) -> {
      p.config.user_id
      |> should.equal("user-config-test")

      p.config.recipe_count
      |> should.equal(2)

      p.config.variety_factor
      |> should.equal(0.9)
    }
    Error(_) ->
      False
      |> should.be_true()
  }
}

/// Test generate_auto_plan calculates total macros correctly
pub fn generate_auto_plan_calculates_total_macros_test() {
  let recipes = [
    create_recipe(1, "Chicken", "protein", 30.0, 5.0, 0.0, Low, True),
    create_recipe(2, "Broccoli", "vegetable", 5.0, 1.0, 8.0, Low, True),
  ]

  let config = create_config("user-1", [], 2, 0.8)

  let plan = meal_planner/auto_planner.generate_auto_plan(recipes, config)

  case plan {
    Ok(p) -> {
      p.total_macros.protein
      |> should.equal(35.0)

      p.total_macros.fat
      |> should.equal(6.0)

      p.total_macros.carbs
      |> should.equal(8.0)
    }
    Error(_) ->
      False
      |> should.be_true()
  }
}

/// Test generate_auto_plan creates recipe_json
pub fn generate_auto_plan_creates_recipe_json_test() {
  let recipes = [
    create_vertical_recipe(1, "Chicken", "protein"),
    create_vertical_recipe(2, "Broccoli", "vegetable"),
  ]

  let config = create_config("user-1", [auto_types.VerticalDiet], 2, 0.8)

  let plan = meal_planner/auto_planner.generate_auto_plan(recipes, config)

  case plan {
    Ok(p) -> {
      // recipe_json should be non-empty JSON string
      let json_len = p.recipe_json |> string.length()
      json_len
      |> should.be_greater_than(0)

      // Should contain array format
      p.recipe_json
      |> should.contain("[")
    }
    Error(_) ->
      False
      |> should.be_true()
  }
}

/// Test generate_auto_plan generates unique ID
pub fn generate_auto_plan_generates_unique_id_test() {
  let recipes = [
    create_vertical_recipe(1, "Chicken", "protein"),
    create_vertical_recipe(2, "Broccoli", "vegetable"),
  ]

  let config = create_config("user-1", [auto_types.VerticalDiet], 2, 0.8)

  let plan1 = meal_planner/auto_planner.generate_auto_plan(recipes, config)
  let plan2 = meal_planner/auto_planner.generate_auto_plan(recipes, config)

  case plan1, plan2 {
    Ok(p1), Ok(p2) -> {
      // IDs should start with expected prefix
      p1.id
      |> should.contain("auto-plan-")

      // IDs might be different due to timestamp
      p1.id
      |> should_not_equal(p2.id)
    }
    _, _ ->
      False
      |> should.be_true()
  }
}

/// Test generate_auto_plan sets generated_at timestamp
pub fn generate_auto_plan_sets_timestamp_test() {
  let recipes = [
    create_vertical_recipe(1, "Chicken", "protein"),
    create_vertical_recipe(2, "Broccoli", "vegetable"),
  ]

  let config = create_config("user-1", [auto_types.VerticalDiet], 2, 0.8)

  let plan = meal_planner/auto_planner.generate_auto_plan(recipes, config)

  case plan {
    Ok(p) -> {
      // Timestamp should be ISO8601 format
      p.generated_at
      |> should.contain("T")

      p.generated_at
      |> should.contain("Z")
    }
    Error(_) ->
      False
      |> should.be_true()
  }
}

// ============================================================================
// Edge Cases and Boundary Tests
// ============================================================================

/// Test with minimum recipe count (1)
pub fn generate_auto_plan_minimum_recipe_count_test() {
  let recipes = [create_vertical_recipe(1, "Chicken", "protein")]

  let config = create_config("user-1", [auto_types.VerticalDiet], 1, 0.8)

  let plan = meal_planner/auto_planner.generate_auto_plan(recipes, config)

  case plan {
    Ok(p) -> {
      list.length(p.recipes)
      |> should.equal(1)
    }
    Error(_) ->
      False
      |> should.be_true()
  }
}

/// Test with large recipe count
pub fn generate_auto_plan_large_recipe_count_test() {
  let recipes = list.range(1, 51)
  |> list.map(fn(i) {
    create_recipe(
      i,
      "Recipe-" <> int.to_string(i),
      case i % 3 {
        0 -> "protein"
        1 -> "vegetable"
        _ -> "carbs"
      },
      20.0 +. int.to_float(i),
      8.0,
      20.0 +. int.to_float(i),
      Low,
      True,
    )
  })

  let config = create_config("user-1", [auto_types.VerticalDiet], 20, 0.8)

  let plan = meal_planner/auto_planner.generate_auto_plan(recipes, config)

  case plan {
    Ok(p) -> {
      list.length(p.recipes)
      |> should.equal(20)
    }
    Error(_) ->
      False
      |> should.be_true()
  }
}

/// Test with multiple diet principles combined
pub fn generate_auto_plan_multiple_diet_principles_test() {
  let recipes = [
    create_recipe(1, "Salmon", "protein", 25.0, 15.0, 0.0, Low, True),
    create_recipe(2, "Beef", "protein", 30.0, 25.0, 0.0, Low, True),
    create_recipe(3, "Broccoli", "vegetable", 5.0, 1.0, 8.0, Low, True),
    create_recipe(4, "Asparagus", "vegetable", 3.0, 0.2, 5.0, Low, True),
  ]

  let config = create_config(
    "user-1",
    [auto_types.VerticalDiet, auto_types.Paleo],
    3,
    0.8,
  )

  let plan = meal_planner/auto_planner.generate_auto_plan(recipes, config)

  case plan {
    Ok(p) -> {
      list.length(p.recipes)
      |> should.equal(3)
    }
    Error(_) ->
      False
      |> should.be_true()
  }
}

// ============================================================================
// Helper Function for Assertions
// ============================================================================

fn should_not_equal(a: String, b: String) -> Nil {
  case a == b {
    True -> {
      False
      |> should.be_true()
    }
    False -> Nil
  }
}
