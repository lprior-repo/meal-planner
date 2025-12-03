import gleam/list
import gleam/string
import gleeunit/should
import meal_planner/diet_validator.{
  ComplianceResult, HighProtein, Keto, Mediterranean, Paleo, TimFerriss,
  VerticalDiet, calculate_protein_per_serving, check_high_protein, check_keto,
  check_mediterranean, check_paleo, check_tim_ferriss, check_vertical_diet,
  has_seed_oils, has_white_carbs, validate_recipe,
}
import meal_planner/types.{High, Ingredient, Low, Macros, Medium, Recipe}

// =============================================================================
// Test Data Helpers
// =============================================================================

fn create_vertical_compliant_recipe() -> Recipe {
  Recipe(
    id: "grilled-ribeye",
    name: "Grilled Ribeye",
    ingredients: [
      Ingredient(name: "Ribeye steak", quantity: "8 oz"),
      Ingredient(name: "Salt", quantity: "1 tsp"),
      Ingredient(name: "Olive oil", quantity: "1 tbsp"),
    ],
    instructions: ["Season steak", "Grill to desired doneness"],
    macros: Macros(protein: 48.0, fat: 32.0, carbs: 0.0),
    servings: 1,
    category: "beef",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

fn create_recipe_with_seed_oil() -> Recipe {
  Recipe(
    id: "fried-chicken",
    name: "Fried Chicken",
    ingredients: [
      Ingredient(name: "Chicken breast", quantity: "8 oz"),
      Ingredient(name: "Canola oil", quantity: "2 cups"),
      Ingredient(name: "Flour", quantity: "1 cup"),
    ],
    instructions: ["Bread chicken", "Fry in oil"],
    macros: Macros(protein: 40.0, fat: 25.0, carbs: 30.0),
    servings: 1,
    category: "chicken",
    fodmap_level: Low,
    vertical_compliant: False,
  )
}

fn create_high_fodmap_recipe() -> Recipe {
  Recipe(
    id: "garlic-bread",
    name: "Garlic Bread",
    ingredients: [
      Ingredient(name: "Bread", quantity: "4 slices"),
      Ingredient(name: "Garlic", quantity: "4 cloves"),
      Ingredient(name: "Butter", quantity: "2 tbsp"),
    ],
    instructions: ["Spread on bread", "Toast"],
    macros: Macros(protein: 8.0, fat: 15.0, carbs: 40.0),
    servings: 2,
    category: "bread",
    fodmap_level: High,
    vertical_compliant: False,
  )
}

fn create_low_protein_recipe() -> Recipe {
  Recipe(
    id: "plain-rice",
    name: "Plain Rice",
    ingredients: [Ingredient(name: "White rice", quantity: "1 cup dry")],
    instructions: ["Cook rice"],
    macros: Macros(protein: 8.0, fat: 0.5, carbs: 90.0),
    servings: 4,
    category: "rice",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

fn create_high_protein_recipe() -> Recipe {
  Recipe(
    id: "steak-dinner",
    name: "Steak Dinner",
    ingredients: [
      Ingredient(name: "Beef steak", quantity: "12 oz"),
      Ingredient(name: "Butter", quantity: "1 tbsp"),
    ],
    instructions: ["Season and cook steak"],
    macros: Macros(protein: 60.0, fat: 30.0, carbs: 0.0),
    servings: 1,
    category: "beef",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

fn create_high_carb_recipe() -> Recipe {
  Recipe(
    id: "pasta-dish",
    name: "Pasta Dish",
    ingredients: [
      Ingredient(name: "Pasta", quantity: "200g"),
      Ingredient(name: "Tomato sauce", quantity: "1 cup"),
    ],
    instructions: ["Cook pasta", "Add sauce"],
    macros: Macros(protein: 15.0, fat: 5.0, carbs: 80.0),
    servings: 2,
    category: "pasta",
    fodmap_level: Medium,
    vertical_compliant: False,
  )
}

fn create_keto_recipe() -> Recipe {
  Recipe(
    id: "keto-eggs",
    name: "Keto Eggs and Bacon",
    ingredients: [
      Ingredient(name: "Eggs", quantity: "4"),
      Ingredient(name: "Bacon", quantity: "4 strips"),
      Ingredient(name: "Butter", quantity: "1 tbsp"),
    ],
    instructions: ["Cook bacon", "Fry eggs in butter"],
    macros: Macros(protein: 30.0, fat: 35.0, carbs: 2.0),
    servings: 1,
    category: "eggs",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

// =============================================================================
// validate_recipe Tests
// =============================================================================

pub fn validate_recipe_empty_principles_test() {
  let recipe = create_vertical_compliant_recipe()
  let result = validate_recipe(recipe, [])

  result.compliant |> should.be_true()
  result.score |> should.equal(1.0)
  result.violations |> should.equal([])
  result.warnings |> should.equal([])
}

pub fn validate_recipe_single_principle_compliant_test() {
  let recipe = create_vertical_compliant_recipe()
  let result = validate_recipe(recipe, [VerticalDiet])

  result.compliant |> should.be_true()
  result.score |> should.equal(1.0)
  list.length(result.violations) |> should.equal(0)
}

pub fn validate_recipe_single_principle_non_compliant_test() {
  let recipe = create_recipe_with_seed_oil()
  let result = validate_recipe(recipe, [VerticalDiet])

  result.compliant |> should.be_false()
  // Should have seed oil violation
  list.length(result.violations) > 0 |> should.be_true()
}

pub fn validate_recipe_multiple_principles_test() {
  let recipe = create_high_protein_recipe()
  let result = validate_recipe(recipe, [VerticalDiet, HighProtein])

  // Should combine results from both principles
  { result.score >=. 0.0 && result.score <=. 1.0 } |> should.be_true()
}

// =============================================================================
// check_vertical_diet Tests
// =============================================================================

pub fn check_vertical_diet_compliant_recipe_test() {
  let recipe = create_vertical_compliant_recipe()
  let result = check_vertical_diet(recipe)

  result.compliant |> should.be_true()
  result.score |> should.equal(1.0)
  result.violations |> should.equal([])
}

pub fn check_vertical_diet_with_seed_oil_test() {
  let recipe = create_recipe_with_seed_oil()
  let result = check_vertical_diet(recipe)

  result.compliant |> should.be_false()
  // Should have at least one violation for seed oil
  list.length(result.violations) > 0 |> should.be_true()
}

pub fn check_vertical_diet_high_fodmap_warning_test() {
  let recipe = create_high_fodmap_recipe()
  let result = check_vertical_diet(recipe)

  // High FODMAP generates warnings, not violations
  list.length(result.warnings) > 0 |> should.be_true()
}

pub fn check_vertical_diet_missing_preferred_protein_warning_test() {
  let recipe = create_low_protein_recipe()
  let result = check_vertical_diet(recipe)

  // Should have warning about preferred proteins
  list.any(result.warnings, fn(w) {
    gleam_string_contains(w, "protein") || gleam_string_contains(w, "carb")
  })
  |> should.be_true()
}

// =============================================================================
// check_tim_ferriss Tests
// =============================================================================

pub fn check_tim_ferriss_high_protein_compliant_test() {
  let recipe = create_high_protein_recipe()
  let result = check_tim_ferriss(recipe)

  result.compliant |> should.be_true()
  result.score |> should.equal(1.0)
}

pub fn check_tim_ferriss_low_protein_not_compliant_test() {
  let recipe = create_low_protein_recipe()
  let result = check_tim_ferriss(recipe)

  // Low protein fails Tim Ferriss compliance
  result.compliant |> should.be_false()
  // Should have warning about low protein
  list.length(result.warnings) > 0 |> should.be_true()
}

pub fn check_tim_ferriss_white_carbs_violation_test() {
  let recipe = create_high_carb_recipe()
  let result = check_tim_ferriss(recipe)

  // Pasta is a white carb violation
  list.length(result.violations) > 0 |> should.be_true()
}

pub fn check_tim_ferriss_white_rice_warning_test() {
  let recipe =
    Recipe(
      id: "rice-bowl",
      name: "Rice Bowl",
      ingredients: [
        Ingredient(name: "White rice", quantity: "2 cups"),
        Ingredient(name: "Chicken breast", quantity: "8 oz"),
      ],
      instructions: ["Cook rice and chicken"],
      macros: Macros(protein: 45.0, fat: 10.0, carbs: 60.0),
      servings: 1,
      category: "bowl",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  let result = check_tim_ferriss(recipe)

  // White rice should be a warning (allowed post-workout)
  list.any(result.warnings, fn(w) { gleam_string_contains(w, "rice") })
  |> should.be_true()
}

// =============================================================================
// check_keto Tests
// =============================================================================

pub fn check_keto_low_carb_compliant_test() {
  let recipe = create_keto_recipe()
  let result = check_keto(recipe)

  result.compliant |> should.be_true()
  result.score |> should.equal(1.0)
  result.violations |> should.equal([])
}

pub fn check_keto_high_carb_not_compliant_test() {
  let recipe = create_high_carb_recipe()
  let result = check_keto(recipe)

  result.compliant |> should.be_false()
  result.score |> should.equal(0.0)
  // Should have violation about too many carbs
  list.length(result.violations) > 0 |> should.be_true()
}

// =============================================================================
// check_paleo Tests
// =============================================================================

pub fn check_paleo_returns_compliant_test() {
  // Paleo check is stubbed, always returns compliant
  let recipe = create_vertical_compliant_recipe()
  let result = check_paleo(recipe)

  result.compliant |> should.be_true()
  result.score |> should.equal(1.0)
}

// =============================================================================
// check_mediterranean Tests
// =============================================================================

pub fn check_mediterranean_returns_compliant_test() {
  // Mediterranean check is stubbed, always returns compliant
  let recipe = create_vertical_compliant_recipe()
  let result = check_mediterranean(recipe)

  result.compliant |> should.be_true()
  result.score |> should.equal(1.0)
}

// =============================================================================
// check_high_protein Tests
// =============================================================================

pub fn check_high_protein_meets_target_test() {
  let recipe = create_high_protein_recipe()
  let result = check_high_protein(recipe)

  // 60g protein per serving >= 40g target
  result.compliant |> should.be_true()
  result.score |> should.equal(1.0)
  result.warnings |> should.equal([])
}

pub fn check_high_protein_below_target_test() {
  let recipe = create_low_protein_recipe()
  let result = check_high_protein(recipe)

  // 8g/4 servings = 2g per serving < 40g target
  // Still compliant but with warning
  result.compliant |> should.be_true()
  list.length(result.warnings) > 0 |> should.be_true()
  // Score should be proportional to protein
  { result.score <. 1.0 } |> should.be_true()
}

// =============================================================================
// Helper Function Tests
// =============================================================================

pub fn has_seed_oils_with_canola_test() {
  let ingredients = [
    Ingredient(name: "Chicken", quantity: "8 oz"),
    Ingredient(name: "Canola oil", quantity: "2 tbsp"),
  ]
  has_seed_oils(ingredients) |> should.be_true()
}

pub fn has_seed_oils_with_soybean_test() {
  let ingredients = [Ingredient(name: "Soybean oil", quantity: "1 tbsp")]
  has_seed_oils(ingredients) |> should.be_true()
}

pub fn has_seed_oils_with_vegetable_oil_test() {
  let ingredients = [Ingredient(name: "Vegetable oil", quantity: "1/4 cup")]
  has_seed_oils(ingredients) |> should.be_true()
}

pub fn has_seed_oils_without_seed_oils_test() {
  let ingredients = [
    Ingredient(name: "Olive oil", quantity: "2 tbsp"),
    Ingredient(name: "Butter", quantity: "1 tbsp"),
  ]
  has_seed_oils(ingredients) |> should.be_false()
}

pub fn has_seed_oils_garlic_infused_oil_exception_test() {
  // Garlic-infused oil is an exception (low-FODMAP safe)
  let ingredients = [Ingredient(name: "Garlic-infused oil", quantity: "1 tbsp")]
  has_seed_oils(ingredients) |> should.be_false()
}

pub fn has_white_carbs_with_pasta_test() {
  let ingredients = [Ingredient(name: "Pasta", quantity: "200g")]
  has_white_carbs(ingredients) |> should.be_true()
}

pub fn has_white_carbs_with_bread_test() {
  let ingredients = [Ingredient(name: "White bread", quantity: "2 slices")]
  has_white_carbs(ingredients) |> should.be_true()
}

pub fn has_white_carbs_with_tortilla_test() {
  let ingredients = [Ingredient(name: "Flour tortilla", quantity: "2")]
  has_white_carbs(ingredients) |> should.be_true()
}

pub fn has_white_carbs_without_white_carbs_test() {
  let ingredients = [
    Ingredient(name: "White rice", quantity: "1 cup"),
    Ingredient(name: "Chicken", quantity: "8 oz"),
  ]
  has_white_carbs(ingredients) |> should.be_false()
}

pub fn calculate_protein_per_serving_test() {
  let recipe = create_high_protein_recipe()
  // 60g protein, 1 serving = 60g per serving
  calculate_protein_per_serving(recipe) |> should.equal(60.0)
}

pub fn calculate_protein_per_serving_multiple_servings_test() {
  let recipe = create_low_protein_recipe()
  // 8g protein per serving (macros are already per serving in this codebase)
  calculate_protein_per_serving(recipe) |> should.equal(8.0)
}

// =============================================================================
// ComplianceResult Type Tests
// =============================================================================

pub fn compliance_result_creation_test() {
  let result =
    ComplianceResult(
      compliant: True,
      score: 0.95,
      violations: [],
      warnings: ["Minor suggestion"],
    )

  result.compliant |> should.be_true()
  result.score |> should.equal(0.95)
  result.violations |> should.equal([])
  list.length(result.warnings) |> should.equal(1)
}

// =============================================================================
// Edge Case Tests
// =============================================================================

pub fn validate_recipe_empty_ingredients_test() {
  let recipe =
    Recipe(
      id: "empty",
      name: "Empty Recipe",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
      servings: 1,
      category: "other",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  let result = validate_recipe(recipe, [VerticalDiet])

  // Should be compliant (no violations from empty ingredients)
  result.compliant |> should.be_true()
}

pub fn validate_recipe_zero_servings_test() {
  let recipe =
    Recipe(
      id: "zero-servings",
      name: "Zero Servings",
      ingredients: [Ingredient(name: "Beef", quantity: "8 oz")],
      instructions: ["Cook"],
      macros: Macros(protein: 40.0, fat: 20.0, carbs: 0.0),
      servings: 0,
      category: "beef",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  // Should not crash with zero servings
  let result = validate_recipe(recipe, [Keto])
  { result.score >=. 0.0 } |> should.be_true()
}

// Helper function to check if string contains substring
fn gleam_string_contains(s: String, substring: String) -> Bool {
  string.contains(s, substring)
}
