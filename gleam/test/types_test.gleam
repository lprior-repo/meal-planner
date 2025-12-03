import gleam/float
import gleeunit/should
import shared/types.{
  Active, Gain, High, Ingredient, Lose, Low, Macros, Maintain, Medium, Moderate,
  Recipe, Sedentary, UserProfile, daily_calorie_target, daily_carb_target,
  daily_fat_target, daily_macro_targets, daily_protein_target,
  is_vertical_diet_compliant, macros_add, macros_calories, macros_per_serving,
  macros_scale, total_macros,
}

// Helper to compare floats with tolerance for floating point precision
fn float_close(actual: Float, expected: Float, tolerance: Float) -> Bool {
  float.absolute_value(actual -. expected) <. tolerance
}

pub fn macros_calories_test() {
  // 4cal/g protein, 9cal/g fat, 4cal/g carbs
  let m = Macros(protein: 30.0, fat: 10.0, carbs: 50.0)
  // (30 * 4) + (10 * 9) + (50 * 4) = 120 + 90 + 200 = 410
  macros_calories(m)
  |> should.equal(410.0)
}

pub fn macros_calories_zero_test() {
  let m = Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
  macros_calories(m)
  |> should.equal(0.0)
}

pub fn macros_add_test() {
  let m1 = Macros(protein: 20.0, fat: 10.0, carbs: 30.0)
  let m2 = Macros(protein: 15.0, fat: 5.0, carbs: 25.0)
  let result = macros_add(m1, m2)
  result.protein |> should.equal(35.0)
  result.fat |> should.equal(15.0)
  result.carbs |> should.equal(55.0)
}

pub fn macros_scale_test() {
  let m = Macros(protein: 10.0, fat: 5.0, carbs: 20.0)
  let result = macros_scale(m, 2.0)
  result.protein |> should.equal(20.0)
  result.fat |> should.equal(10.0)
  result.carbs |> should.equal(40.0)
}

// Ingredient tests

pub fn ingredient_creation_test() {
  let ing = Ingredient(name: "Chicken breast", quantity: "200g")
  ing.name |> should.equal("Chicken breast")
  ing.quantity |> should.equal("200g")
}

// Recipe tests

pub fn recipe_creation_test() {
  let macros = Macros(protein: 40.0, fat: 10.0, carbs: 5.0)
  let ingredients = [
    Ingredient(name: "Chicken breast", quantity: "200g"),
    Ingredient(name: "Olive oil", quantity: "1 tbsp"),
  ]
  let instructions = ["Season chicken", "Grill for 6 min per side"]
  let recipe =
    Recipe(
      id: "grilled-chicken",
      name: "Grilled Chicken",
      ingredients: ingredients,
      instructions: instructions,
      macros: macros,
      servings: 2,
      category: "protein",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  recipe.name |> should.equal("Grilled Chicken")
  recipe.servings |> should.equal(2)
  recipe.vertical_compliant |> should.be_true()
}

// is_vertical_diet_compliant tests

pub fn is_vertical_diet_compliant_low_fodmap_and_compliant_test() {
  let recipe =
    Recipe(
      id: "test-1",
      name: "Test",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 10.0, fat: 5.0, carbs: 0.0),
      servings: 1,
      category: "protein",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  is_vertical_diet_compliant(recipe) |> should.be_true()
}

pub fn is_vertical_diet_compliant_high_fodmap_fails_test() {
  let recipe =
    Recipe(
      id: "test-2",
      name: "Test",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 10.0, fat: 5.0, carbs: 0.0),
      servings: 1,
      category: "protein",
      fodmap_level: High,
      vertical_compliant: True,
    )
  is_vertical_diet_compliant(recipe) |> should.be_false()
}

pub fn is_vertical_diet_compliant_medium_fodmap_fails_test() {
  let recipe =
    Recipe(
      id: "test-3",
      name: "Test",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 10.0, fat: 5.0, carbs: 0.0),
      servings: 1,
      category: "protein",
      fodmap_level: Medium,
      vertical_compliant: True,
    )
  is_vertical_diet_compliant(recipe) |> should.be_false()
}

pub fn is_vertical_diet_compliant_not_marked_compliant_fails_test() {
  let recipe =
    Recipe(
      id: "test-4",
      name: "Test",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 10.0, fat: 5.0, carbs: 0.0),
      servings: 1,
      category: "protein",
      fodmap_level: Low,
      vertical_compliant: False,
    )
  is_vertical_diet_compliant(recipe) |> should.be_false()
}

// macros_per_serving tests

pub fn macros_per_serving_returns_recipe_macros_test() {
  let recipe =
    Recipe(
      id: "test-5",
      name: "Test",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 25.0, fat: 12.0, carbs: 30.0),
      servings: 4,
      category: "mixed",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  let m = macros_per_serving(recipe)
  m.protein |> should.equal(25.0)
  m.fat |> should.equal(12.0)
  m.carbs |> should.equal(30.0)
}

// total_macros tests

pub fn total_macros_multiplies_by_servings_test() {
  let recipe =
    Recipe(
      id: "test-6",
      name: "Test",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 25.0, fat: 10.0, carbs: 20.0),
      servings: 4,
      category: "mixed",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  let m = total_macros(recipe)
  m.protein |> should.equal(100.0)
  m.fat |> should.equal(40.0)
  m.carbs |> should.equal(80.0)
}

pub fn total_macros_single_serving_test() {
  let recipe =
    Recipe(
      id: "test-7",
      name: "Test",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 30.0, fat: 15.0, carbs: 10.0),
      servings: 1,
      category: "protein",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  let m = total_macros(recipe)
  m.protein |> should.equal(30.0)
}

pub fn total_macros_zero_servings_treated_as_one_test() {
  let recipe =
    Recipe(
      id: "test-8",
      name: "Test",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 20.0, fat: 10.0, carbs: 5.0),
      servings: 0,
      category: "protein",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  let m = total_macros(recipe)
  // Zero servings should be treated as 1
  m.protein |> should.equal(20.0)
}

// UserProfile and daily target tests

pub fn daily_protein_target_active_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Active,
      goal: Maintain,
      meals_per_day: 3,
    )
  // Active = 1.0g per lb
  daily_protein_target(profile) |> should.equal(180.0)
}

pub fn daily_protein_target_sedentary_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Sedentary,
      goal: Maintain,
      meals_per_day: 3,
    )
  // Sedentary = 0.8g per lb
  daily_protein_target(profile) |> should.equal(144.0)
}

pub fn daily_protein_target_gain_goal_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Gain,
      meals_per_day: 3,
    )
  // Gain = 1.0g per lb
  daily_protein_target(profile) |> should.equal(180.0)
}

pub fn daily_protein_target_lose_goal_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Lose,
      meals_per_day: 3,
    )
  // Lose = 0.8g per lb
  daily_protein_target(profile) |> should.equal(144.0)
}

pub fn daily_protein_target_moderate_maintain_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Maintain,
      meals_per_day: 3,
    )
  // Moderate + Maintain = 0.9g per lb
  daily_protein_target(profile) |> should.equal(162.0)
}

pub fn daily_fat_target_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Active,
      goal: Maintain,
      meals_per_day: 3,
    )
  // 0.3g per lb
  daily_fat_target(profile) |> should.equal(54.0)
}

pub fn daily_calorie_target_sedentary_maintain_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Sedentary,
      goal: Maintain,
      meals_per_day: 3,
    )
  // Sedentary = 12 cal/lb, Maintain = 1.0x
  // 180 * 12 = 2160
  daily_calorie_target(profile) |> should.equal(2160.0)
}

pub fn daily_calorie_target_active_maintain_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Active,
      goal: Maintain,
      meals_per_day: 3,
    )
  // Active = 18 cal/lb, Maintain = 1.0x
  // 180 * 18 = 3240
  daily_calorie_target(profile) |> should.equal(3240.0)
}

pub fn daily_calorie_target_moderate_gain_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 100.0,
      activity_level: Moderate,
      goal: Gain,
      meals_per_day: 3,
    )
  // Moderate = 15 cal/lb, Gain = 1.15x
  // 100 * 15 = 1500, 1500 * 1.15 = 1725
  float_close(daily_calorie_target(profile), 1725.0, 0.01) |> should.be_true()
}

pub fn daily_calorie_target_moderate_lose_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Lose,
      meals_per_day: 3,
    )
  // Moderate = 15 cal/lb, Lose = 0.85x
  // 180 * 15 * 0.85 = 2295
  daily_calorie_target(profile) |> should.equal(2295.0)
}

pub fn daily_carb_target_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Active,
      goal: Maintain,
      meals_per_day: 3,
    )
  // Total cal = 3240 (180 * 18)
  // Protein = 180g * 4 = 720 cal
  // Fat = 54g * 9 = 486 cal
  // Remaining = 3240 - 720 - 486 = 2034 cal
  // Carbs = 2034 / 4 = 508.5g
  daily_carb_target(profile) |> should.equal(508.5)
}

pub fn daily_macro_targets_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Active,
      goal: Maintain,
      meals_per_day: 3,
    )
  let targets = daily_macro_targets(profile)
  targets.protein |> should.equal(180.0)
  targets.fat |> should.equal(54.0)
  targets.carbs |> should.equal(508.5)
}
