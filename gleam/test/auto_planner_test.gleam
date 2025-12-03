import gleam/list
import gleam/string
import gleeunit/should
import meal_planner/auto_planner
import shared/types.{type Recipe, Ingredient, Low, Macros, Recipe}

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
      ingredients: [Ingredient("ground beef", "6 oz"), Ingredient("white rice", "1 cup")],
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
      fodmap_level: types.High,
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

fn create_config() -> auto_planner.AutoPlanConfig {
  auto_planner.AutoPlanConfig(
    diet_principles: [auto_planner.VerticalDiet],
    macro_targets: Macros(protein: 180.0, fat: 60.0, carbs: 250.0),
    recipe_count: 4,
    variety_factor: 0.7,
    user_id: "test-user-123",
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
  let recipe = Recipe(
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

  let score = auto_planner.RecipeScore(
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
  let principles = [auto_planner.VerticalDiet]

  let filtered = auto_planner.filter_by_diet_principles(recipes, principles)

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

  let filtered = auto_planner.filter_by_diet_principles(recipes, principles)

  // Empty principles should return all recipes
  filtered
  |> list.length
  |> should.equal(8)
}

// =============================================================================
// Macro Match Scoring Tests
// =============================================================================

pub fn macro_match_perfect_score_test() {
  let recipe = Recipe(
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
  let score = auto_planner.calculate_macro_match_score(recipe, targets, config.recipe_count)

  // Perfect match should score close to 1.0
  score
  |> should.be_true(fn(s) { s >. 0.9 })
}

pub fn macro_match_poor_score_test() {
  let recipe = Recipe(
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
  let score = auto_planner.calculate_macro_match_score(recipe, targets, config.recipe_count)

  // Poor match should score lower
  score
  |> should.be_true(fn(s) { s <. 0.5 })
}

// =============================================================================
// Variety Scoring Tests
// =============================================================================

pub fn variety_score_unique_category_test() {
  let recipe = Recipe(
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

  let score = auto_planner.calculate_variety_score(recipe, already_selected)

  // Different category should score high
  score
  |> should.be_true(fn(s) { s >. 0.8 })
}

pub fn variety_score_duplicate_category_test() {
  let recipe = Recipe(
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

  let score = auto_planner.calculate_variety_score(recipe, already_selected)

  // Same category should score lower
  score
  |> should.be_true(fn(s) { s <. 0.5 })
}

// =============================================================================
// Recipe Scoring Tests
// =============================================================================

pub fn score_recipe_comprehensive_test() {
  let recipe = Recipe(
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

  let scored = auto_planner.score_recipe(recipe, config, already_selected)

  // Check all score components are in valid range
  scored.diet_compliance_score
  |> should.be_true(fn(s) { s >=. 0.0 && s <=. 1.0 })

  scored.macro_match_score
  |> should.be_true(fn(s) { s >=. 0.0 && s <=. 1.0 })

  scored.variety_score
  |> should.be_true(fn(s) { s >=. 0.0 && s <=. 1.0 })

  scored.overall_score
  |> should.be_true(fn(s) { s >=. 0.0 && s <=. 1.0 })

  // Overall score should be weighted average
  let expected =
    scored.diet_compliance_score *. 0.4
    +. scored.macro_match_score *. 0.35
    +. scored.variety_score *. 0.25

  // Allow small floating point difference
  scored.overall_score
  |> should.be_true(fn(s) {
    let diff = s -. expected
    diff >=. -0.01 && diff <=. 0.01
  })
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
    |> list.map(fn(r) { auto_planner.score_recipe(r, config, []) })

  let selected = auto_planner.select_top_n(scored_recipes, 4, 0.7)

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
    |> list.map(fn(r) { auto_planner.score_recipe(r, config, []) })

  let selected = auto_planner.select_top_n(scored_recipes, 4, 0.7)

  // Should have diverse categories
  let categories = list.map(selected, fn(r) { r.category })
  let unique_categories = list.unique(categories)

  // Should have at least 3 different categories
  unique_categories
  |> list.length
  |> should.be_true(fn(count) { count >= 3 })
}

// =============================================================================
// Full Auto Plan Generation Tests
// =============================================================================

pub fn generate_auto_plan_success_test() {
  let recipes = create_test_recipes()
  let config = create_config()

  let result = auto_planner.generate_auto_plan(recipes, config)

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
      plan.id
      |> string.length
      |> should.be_true(fn(len) { len > 0 })

      // Config should match input
      plan.config.recipe_count
      |> should.equal(4)

      plan.config.user_id
      |> should.equal("test-user-123")

      // Should have generated timestamp
      plan.generated_at
      |> string.length
      |> should.be_true(fn(len) { len > 0 })

      // Total macros should be reasonable
      plan.total_macros.protein
      |> should.be_true(fn(p) { p >. 0.0 })

      plan.total_macros.fat
      |> should.be_true(fn(f) { f >. 0.0 })

      plan.total_macros.carbs
      |> should.be_true(fn(c) { c >. 0.0 })
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

  let result = auto_planner.generate_auto_plan(recipes, config)

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
      fodmap_level: types.High,
      vertical_compliant: False,
    ),
  ]

  let config = create_config()

  let result = auto_planner.generate_auto_plan(recipes, config)

  // Should fail because no recipes pass diet filter
  result
  |> should.be_error
}

pub fn generate_auto_plan_variety_test() {
  let recipes = create_test_recipes()
  let config = auto_planner.AutoPlanConfig(
    ..create_config(),
    variety_factor: 1.0,  // Maximum variety
  )

  let result = auto_planner.generate_auto_plan(recipes, config)

  case result {
    Ok(plan) -> {
      // Should prioritize variety
      let categories = list.map(plan.recipes, fn(r) { r.category })
      let unique_categories = list.unique(categories)

      // High variety factor should result in diverse categories
      unique_categories
      |> list.length
      |> should.be_true(fn(count) { count >= 3 })
    }
    Error(_) -> should.fail()
  }
}
