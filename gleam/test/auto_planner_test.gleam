import gleam/list
import gleam/string
import gleeunit/should
import meal_planner/auto_planner.{
  type AutoPlanConfig, type DietPrinciple, type RecipeScore, RecipeScore,
  calculate_macro_match_score, calculate_variety_score,
  filter_by_diet_principles, generate_auto_plan, score_recipe, select_top_n,
}
import meal_planner/auto_planner/types as auto_types
import shared/types.{type Recipe, High, Ingredient, Low, Macros, Recipe}

// =============================================================================
// Test Data
// =============================================================================

fn create_test_recipes() -> List(Recipe) {
  [
    // High protein, low carb
    Recipe(
      id: "test-1",
      name: "Grilled Ribeye",
      ingredients: [Ingredient("ribeye steak", "8 oz")],
      instructions: ["Grill the steak"],
      macros: Macros(protein: 48.0, fat: 32.0, carbs: 0.0),
      servings: 1,
      category: "beef-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
    // Balanced
    Recipe(
      id: "test-2",
      name: "Ground Beef and Rice Bowl",
      ingredients: [
        Ingredient("ground beef", "6 oz"),
        Ingredient("white rice", "1 cup"),
      ],
      instructions: ["Cook beef", "Serve with rice"],
      macros: Macros(protein: 40.0, fat: 18.0, carbs: 45.0),
      servings: 1,
      category: "beef-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
    // High carb
    Recipe(
      id: "test-3",
      name: "Simple White Rice",
      ingredients: [Ingredient("white rice", "1 cup dry")],
      instructions: ["Cook rice"],
      macros: Macros(protein: 8.0, fat: 1.0, carbs: 90.0),
      servings: 4,
      category: "rice-side",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
    // Another protein option (different protein source)
    Recipe(
      id: "test-4",
      name: "Lamb Chops",
      ingredients: [Ingredient("lamb loin chops", "8 oz")],
      instructions: ["Sear the chops"],
      macros: Macros(protein: 42.0, fat: 28.0, carbs: 0.0),
      servings: 1,
      category: "lamb-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
    // Vegetable side
    Recipe(
      id: "test-5",
      name: "Sautéed Spinach",
      ingredients: [Ingredient("fresh spinach", "1 lb")],
      instructions: ["Sauté spinach"],
      macros: Macros(protein: 6.0, fat: 8.0, carbs: 8.0),
      servings: 4,
      category: "vegetable-side",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
    // Another beef option (should create variety challenge)
    Recipe(
      id: "test-6",
      name: "Pan-Seared Strip Steak",
      ingredients: [Ingredient("NY strip steak", "8 oz")],
      instructions: ["Sear the steak"],
      macros: Macros(protein: 50.0, fat: 34.0, carbs: 1.0),
      servings: 1,
      category: "beef-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
    // Non-vertical diet option (should be filtered)
    Recipe(
      id: "test-7",
      name: "High FODMAP Dish",
      ingredients: [Ingredient("onions", "1 cup")],
      instructions: ["Cook onions"],
      macros: Macros(protein: 2.0, fat: 0.0, carbs: 12.0),
      servings: 2,
      category: "side",
      fodmap_level: High,
      vertical_compliant: False,
    ),
    // Bison option (different protein source for variety)
    Recipe(
      id: "test-8",
      name: "Bison Burger Patty",
      ingredients: [Ingredient("ground bison", "6 oz")],
      instructions: ["Form and cook patty"],
      macros: Macros(protein: 38.0, fat: 12.0, carbs: 0.0),
      servings: 1,
      category: "bison-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
  ]
}

fn create_config() -> AutoPlanConfig {
  auto_types.AutoPlanConfig(
    user_id: "test-user-123",
    diet_principles: [auto_types.VerticalDiet],
    macro_targets: Macros(protein: 180.0, fat: 60.0, carbs: 250.0),
    recipe_count: 4,
    variety_factor: 0.7,
  )
}

// =============================================================================
// Type Tests
// =============================================================================

pub fn auto_plan_config_type_test() {
  let config = create_config()

  config.recipe_count
  |> should.equal(4)

  config.variety_factor
  |> should.equal(0.7)

  config.user_id
  |> should.equal("test-user-123")
}

pub fn recipe_score_type_test() {
  let recipe =
    Recipe(
      id: "test",
      name: "Test Recipe",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 40.0, fat: 20.0, carbs: 30.0),
      servings: 1,
      category: "test",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let score =
    RecipeScore(
      recipe: recipe,
      diet_compliance_score: 1.0,
      macro_match_score: 0.8,
      variety_score: 0.6,
      overall_score: 0.8,
    )

  score.overall_score
  |> should.equal(0.8)

  score.diet_compliance_score
  |> should.equal(1.0)
}

// =============================================================================
// Diet Principle Filtering Tests
// =============================================================================

pub fn filter_vertical_diet_recipes_test() {
  let recipes = create_test_recipes()
  let principles = [auto_types.VerticalDiet]

  let filtered = filter_by_diet_principles(recipes, principles)

  // Should filter out non-vertical recipes
  filtered
  |> list.length
  |> should.equal(7)

  // All filtered recipes should be vertical compliant
  filtered
  |> list.all(fn(r) { r.vertical_compliant && r.fodmap_level == Low })
  |> should.be_true
}

pub fn filter_empty_principles_returns_all_test() {
  let recipes = create_test_recipes()
  let principles = []

  let filtered = filter_by_diet_principles(recipes, principles)

  // Empty principles should return all recipes
  filtered
  |> list.length
  |> should.equal(8)
}

// =============================================================================
// Macro Match Scoring Tests
// =============================================================================

pub fn macro_match_perfect_score_test() {
  let recipe =
    Recipe(
      id: "test",
      name: "Perfect Match",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 45.0, fat: 15.0, carbs: 62.5),
      servings: 1,
      category: "test",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let targets = Macros(protein: 180.0, fat: 60.0, carbs: 250.0)
  let config = create_config()

  // Recipe provides 1/4 of targets (4 recipes expected)
  let score = calculate_macro_match_score(recipe, targets, config.recipe_count)

  // Perfect match should score close to 1.0
  should.be_true(score >. 0.9)
}

pub fn macro_match_poor_score_test() {
  let recipe =
    Recipe(
      id: "test",
      name: "Poor Match",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 100.0, fat: 50.0, carbs: 200.0),
      servings: 1,
      category: "test",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let targets = Macros(protein: 180.0, fat: 60.0, carbs: 250.0)
  let config = create_config()

  // Recipe provides way too much (over 1/2 of daily targets in one meal)
  let score = calculate_macro_match_score(recipe, targets, config.recipe_count)

  // Poor match should score lower
  should.be_true(score <. 0.5)
}

// =============================================================================
// Variety Scoring Tests
// =============================================================================

pub fn variety_score_unique_category_test() {
  let recipe =
    Recipe(
      id: "test",
      name: "Bison Steak",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 48.0, fat: 16.0, carbs: 0.0),
      servings: 1,
      category: "bison-main",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let already_selected = [
    Recipe(
      id: "selected-1",
      name: "Beef Steak",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 48.0, fat: 32.0, carbs: 0.0),
      servings: 1,
      category: "beef-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
  ]

  let score = calculate_variety_score(recipe, already_selected)

  // Different category should score high
  should.be_true(score >. 0.8)
}

pub fn variety_score_duplicate_category_test() {
  let recipe =
    Recipe(
      id: "test",
      name: "Another Beef Steak",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 50.0, fat: 34.0, carbs: 1.0),
      servings: 1,
      category: "beef-main",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let already_selected = [
    Recipe(
      id: "selected-1",
      name: "Beef Steak",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 48.0, fat: 32.0, carbs: 0.0),
      servings: 1,
      category: "beef-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
  ]

  let score = calculate_variety_score(recipe, already_selected)

  // Same category should score lower
  should.be_true(score <. 0.5)
}

// =============================================================================
// Recipe Scoring Tests
// =============================================================================

pub fn score_recipe_comprehensive_test() {
  let recipe =
    Recipe(
      id: "test",
      name: "Good Recipe",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 45.0, fat: 15.0, carbs: 62.5),
      servings: 1,
      category: "beef-main",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let config = create_config()
  let already_selected = []

  let scored = score_recipe(recipe, config, already_selected)

  // Check all score components are in valid range
  should.be_true(scored.diet_compliance_score >=. 0.0 && scored.diet_compliance_score <=. 1.0)

  should.be_true(scored.macro_match_score >=. 0.0 && scored.macro_match_score <=. 1.0)

  should.be_true(scored.variety_score >=. 0.0 && scored.variety_score <=. 1.0)

  should.be_true(scored.overall_score >=. 0.0 && scored.overall_score <=. 1.0)

  // Overall score should be weighted average
  let expected =
    scored.diet_compliance_score
    *. 0.4
    +. scored.macro_match_score
    *. 0.35
    +. scored.variety_score
    *. 0.25

  // Allow small floating point difference
  let diff = scored.overall_score -. expected
  should.be_true(diff >=. -0.01 && diff <=. 0.01)
}

// =============================================================================
// Selection Tests
// =============================================================================

pub fn select_top_n_returns_correct_count_test() {
  let recipes = create_test_recipes()
  let config = create_config()

  let scored_recipes =
    recipes
    |> list.filter(fn(r) { r.vertical_compliant })
    |> list.map(fn(r) { score_recipe(r, config, []) })

  let selected = select_top_n(scored_recipes, 4, 0.7)

  // Should return exactly 4 recipes
  selected
  |> list.length
  |> should.equal(4)
}

pub fn select_top_n_prioritizes_variety_test() {
  let recipes = create_test_recipes()
  let config = create_config()

  let scored_recipes =
    recipes
    |> list.filter(fn(r) { r.vertical_compliant })
    |> list.map(fn(r) { score_recipe(r, config, []) })

  let selected = select_top_n(scored_recipes, 4, 0.7)

  // Should have diverse categories
  let categories = list.map(selected, fn(r) { r.category })
  let unique_categories = list.unique(categories)

  // Should have at least 3 different categories
  should.be_true(list.length(unique_categories) >= 3)
}

// =============================================================================
// Full Auto Plan Generation Tests
// =============================================================================

pub fn generate_auto_plan_success_test() {
  let recipes = create_test_recipes()
  let config = create_config()

  let result = generate_auto_plan(recipes, config)

  // Should succeed
  result
  |> should.be_ok

  case result {
    Ok(plan) -> {
      // Should have 4 recipes
      plan.recipes
      |> list.length
      |> should.equal(4)

      // Plan ID should not be empty
      should.be_true(string.length(plan.id) > 0)

      // Config should match input
      plan.config.recipe_count
      |> should.equal(4)

      plan.config.user_id
      |> should.equal("test-user-123")

      // Should have generated timestamp
      should.be_true(string.length(plan.generated_at) > 0)

      // Total macros should be reasonable
      should.be_true(plan.total_macros.protein >. 0.0)

      should.be_true(plan.total_macros.fat >. 0.0)

      should.be_true(plan.total_macros.carbs >. 0.0)
    }
    Error(_) -> should.fail()
  }
}

pub fn generate_auto_plan_insufficient_recipes_test() {
  let recipes = [
    Recipe(
      id: "test-1",
      name: "Single Recipe",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 40.0, fat: 20.0, carbs: 30.0),
      servings: 1,
      category: "beef-main",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
  ]

  let config = create_config()

  let result = generate_auto_plan(recipes, config)

  // Should fail with appropriate error
  result
  |> should.be_error

  case result {
    Error(msg) -> {
      msg
      |> string.contains("insufficient")
      |> should.be_true
    }
    Ok(_) -> should.fail()
  }
}

pub fn generate_auto_plan_no_valid_recipes_test() {
  let recipes = [
    Recipe(
      id: "test-1",
      name: "High FODMAP",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 10.0, fat: 5.0, carbs: 20.0),
      servings: 1,
      category: "side",
      fodmap_level: High,
      vertical_compliant: False,
    ),
  ]

  let config = create_config()

  let result = generate_auto_plan(recipes, config)

  // Should fail because no recipes pass diet filter
  result
  |> should.be_error
}

pub fn generate_auto_plan_variety_test() {
  let recipes = create_test_recipes()
  let config =
    auto_types.AutoPlanConfig(
      ..create_config(),
      variety_factor: 1.0,
      // Maximum variety
    )

  let result = generate_auto_plan(recipes, config)

  case result {
    Ok(plan) -> {
      // Should prioritize variety
      let categories = list.map(plan.recipes, fn(r) { r.category })
      let unique_categories = list.unique(categories)

      // High variety factor should result in diverse categories
      should.be_true(list.length(unique_categories) >= 3)
    }
    Error(_) -> should.fail()
  }
}
