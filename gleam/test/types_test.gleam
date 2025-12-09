import gleam/float
import gleam/json as gleam_json
import gleam/option
import gleam/result
import gleam/string as gleam_string
import gleeunit/should
import meal_planner/types.{
  Active, Gain, High, Ingredient, Lose, Low, Macros, Maintain, Medium, Moderate,
  Recipe, Sedentary, UserProfile, daily_calorie_target, daily_carb_target,
  daily_fat_target, daily_macro_targets, daily_protein_target,
  is_vertical_diet_compliant, macros_add, macros_calories, macros_per_serving,
  macros_scale, total_macros,
}
import meal_planner/types

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

// ============================================================================
// macros_zero and macros_sum tests
// ============================================================================

pub fn macros_zero_test() {
  let zero = types.macros_zero()
  zero.protein |> should.equal(0.0)
  zero.fat |> should.equal(0.0)
  zero.carbs |> should.equal(0.0)
}

pub fn macros_sum_empty_list_test() {
  let result = types.macros_sum([])
  result.protein |> should.equal(0.0)
  result.fat |> should.equal(0.0)
  result.carbs |> should.equal(0.0)
}

pub fn macros_sum_single_item_test() {
  let m = Macros(protein: 30.0, fat: 15.0, carbs: 50.0)
  let result = types.macros_sum([m])
  result.protein |> should.equal(30.0)
  result.fat |> should.equal(15.0)
  result.carbs |> should.equal(50.0)
}

pub fn macros_sum_multiple_items_test() {
  let m1 = Macros(protein: 30.0, fat: 15.0, carbs: 50.0)
  let m2 = Macros(protein: 20.0, fat: 10.0, carbs: 25.0)
  let m3 = Macros(protein: 10.0, fat: 5.0, carbs: 15.0)
  let result = types.macros_sum([m1, m2, m3])
  result.protein |> should.equal(60.0)
  result.fat |> should.equal(30.0)
  result.carbs |> should.equal(90.0)
}

// ============================================================================
// Micronutrients tests
// ============================================================================

pub fn micronutrients_zero_test() {
  let zero = types.micronutrients_zero()
  zero.fiber |> should.equal(option.None)
  zero.sugar |> should.equal(option.None)
  zero.sodium |> should.equal(option.None)
  zero.calcium |> should.equal(option.None)
  zero.iron |> should.equal(option.None)
}

pub fn micronutrients_add_both_some_test() {
  let a =
    types.Micronutrients(
      fiber: option.Some(10.0),
      sugar: option.Some(5.0),
      sodium: option.Some(500.0),
      cholesterol: option.None,
      vitamin_a: option.None,
      vitamin_c: option.Some(15.0),
      vitamin_d: option.None,
      vitamin_e: option.None,
      vitamin_k: option.None,
      vitamin_b6: option.None,
      vitamin_b12: option.None,
      folate: option.None,
      thiamin: option.None,
      riboflavin: option.None,
      niacin: option.None,
      calcium: option.Some(200.0),
      iron: option.Some(8.0),
      magnesium: option.None,
      phosphorus: option.None,
      potassium: option.None,
      zinc: option.None,
    )
  let b =
    types.Micronutrients(
      fiber: option.Some(5.0),
      sugar: option.Some(3.0),
      sodium: option.Some(300.0),
      cholesterol: option.None,
      vitamin_a: option.None,
      vitamin_c: option.Some(10.0),
      vitamin_d: option.None,
      vitamin_e: option.None,
      vitamin_k: option.None,
      vitamin_b6: option.None,
      vitamin_b12: option.None,
      folate: option.None,
      thiamin: option.None,
      riboflavin: option.None,
      niacin: option.None,
      calcium: option.Some(100.0),
      iron: option.Some(4.0),
      magnesium: option.None,
      phosphorus: option.None,
      potassium: option.None,
      zinc: option.None,
    )
  let result = types.micronutrients_add(a, b)
  result.fiber |> should.equal(option.Some(15.0))
  result.sugar |> should.equal(option.Some(8.0))
  result.sodium |> should.equal(option.Some(800.0))
  result.vitamin_c |> should.equal(option.Some(25.0))
  result.calcium |> should.equal(option.Some(300.0))
  result.iron |> should.equal(option.Some(12.0))
}

pub fn micronutrients_add_one_none_test() {
  let a =
    types.Micronutrients(
      fiber: option.Some(10.0),
      sugar: option.None,
      sodium: option.None,
      cholesterol: option.None,
      vitamin_a: option.None,
      vitamin_c: option.None,
      vitamin_d: option.None,
      vitamin_e: option.None,
      vitamin_k: option.None,
      vitamin_b6: option.None,
      vitamin_b12: option.None,
      folate: option.None,
      thiamin: option.None,
      riboflavin: option.None,
      niacin: option.None,
      calcium: option.None,
      iron: option.None,
      magnesium: option.None,
      phosphorus: option.None,
      potassium: option.None,
      zinc: option.None,
    )
  let b = types.micronutrients_zero()
  let result = types.micronutrients_add(a, b)
  result.fiber |> should.equal(option.Some(10.0))
  result.sugar |> should.equal(option.None)
}

pub fn micronutrients_scale_test() {
  let m =
    types.Micronutrients(
      fiber: option.Some(10.0),
      sugar: option.Some(5.0),
      sodium: option.None,
      cholesterol: option.None,
      vitamin_a: option.None,
      vitamin_c: option.None,
      vitamin_d: option.None,
      vitamin_e: option.None,
      vitamin_k: option.None,
      vitamin_b6: option.None,
      vitamin_b12: option.None,
      folate: option.None,
      thiamin: option.None,
      riboflavin: option.None,
      niacin: option.None,
      calcium: option.Some(100.0),
      iron: option.None,
      magnesium: option.None,
      phosphorus: option.None,
      potassium: option.None,
      zinc: option.None,
    )
  let result = types.micronutrients_scale(m, 2.0)
  result.fiber |> should.equal(option.Some(20.0))
  result.sugar |> should.equal(option.Some(10.0))
  result.sodium |> should.equal(option.None)
  result.calcium |> should.equal(option.Some(200.0))
}

pub fn micronutrients_sum_test() {
  let m1 =
    types.Micronutrients(
      fiber: option.Some(10.0),
      sugar: option.None,
      sodium: option.None,
      cholesterol: option.None,
      vitamin_a: option.None,
      vitamin_c: option.None,
      vitamin_d: option.None,
      vitamin_e: option.None,
      vitamin_k: option.None,
      vitamin_b6: option.None,
      vitamin_b12: option.None,
      folate: option.None,
      thiamin: option.None,
      riboflavin: option.None,
      niacin: option.None,
      calcium: option.Some(50.0),
      iron: option.None,
      magnesium: option.None,
      phosphorus: option.None,
      potassium: option.None,
      zinc: option.None,
    )
  let m2 =
    types.Micronutrients(
      fiber: option.Some(5.0),
      sugar: option.None,
      sodium: option.None,
      cholesterol: option.None,
      vitamin_a: option.None,
      vitamin_c: option.None,
      vitamin_d: option.None,
      vitamin_e: option.None,
      vitamin_k: option.None,
      vitamin_b6: option.None,
      vitamin_b12: option.None,
      folate: option.None,
      thiamin: option.None,
      riboflavin: option.None,
      niacin: option.None,
      calcium: option.Some(50.0),
      iron: option.None,
      magnesium: option.None,
      phosphorus: option.None,
      potassium: option.None,
      zinc: option.None,
    )
  let result = types.micronutrients_sum([m1, m2])
  result.fiber |> should.equal(option.Some(15.0))
  result.calcium |> should.equal(option.Some(100.0))
}

// ============================================================================
// String conversion tests
// ============================================================================

pub fn fodmap_level_to_string_low_test() {
  types.fodmap_level_to_string(Low) |> should.equal("low")
}

pub fn fodmap_level_to_string_medium_test() {
  types.fodmap_level_to_string(Medium) |> should.equal("medium")
}

pub fn fodmap_level_to_string_high_test() {
  types.fodmap_level_to_string(High) |> should.equal("high")
}

pub fn activity_level_to_string_sedentary_test() {
  types.activity_level_to_string(Sedentary) |> should.equal("sedentary")
}

pub fn activity_level_to_string_moderate_test() {
  types.activity_level_to_string(Moderate) |> should.equal("moderate")
}

pub fn activity_level_to_string_active_test() {
  types.activity_level_to_string(Active) |> should.equal("active")
}

pub fn goal_to_string_gain_test() {
  types.goal_to_string(Gain) |> should.equal("gain")
}

pub fn goal_to_string_maintain_test() {
  types.goal_to_string(Maintain) |> should.equal("maintain")
}

pub fn goal_to_string_lose_test() {
  types.goal_to_string(Lose) |> should.equal("lose")
}

pub fn meal_type_to_string_breakfast_test() {
  types.meal_type_to_string(types.Breakfast) |> should.equal("breakfast")
}

pub fn meal_type_to_string_lunch_test() {
  types.meal_type_to_string(types.Lunch) |> should.equal("lunch")
}

pub fn meal_type_to_string_dinner_test() {
  types.meal_type_to_string(types.Dinner) |> should.equal("dinner")
}

pub fn meal_type_to_string_snack_test() {
  types.meal_type_to_string(types.Snack) |> should.equal("snack")
}

// ============================================================================
// JSON encoding tests
// ============================================================================

pub fn macros_to_json_test() {
  let m = Macros(protein: 30.0, fat: 15.0, carbs: 50.0)
  let json = types.macros_to_json(m)
  let json_str = gleam_json.to_string(json)
  gleam_string.contains(json_str, "\"protein\"") |> should.be_true()
  gleam_string.contains(json_str, "30") |> should.be_true()
  gleam_string.contains(json_str, "\"calories\"") |> should.be_true()
}

pub fn ingredient_to_json_test() {
  let ing = Ingredient(name: "Chicken breast", quantity: "200g")
  let json = types.ingredient_to_json(ing)
  let json_str = gleam_json.to_string(json)
  gleam_string.contains(json_str, "Chicken breast") |> should.be_true()
  gleam_string.contains(json_str, "200g") |> should.be_true()
}

pub fn recipe_to_json_test() {
  let recipe =
    Recipe(
      id: "test-recipe",
      name: "Test Recipe",
      ingredients: [Ingredient(name: "Chicken", quantity: "8 oz")],
      instructions: ["Cook it"],
      macros: Macros(protein: 40.0, fat: 10.0, carbs: 5.0),
      servings: 2,
      category: "chicken",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  let json = types.recipe_to_json(recipe)
  let json_str = gleam_json.to_string(json)
  gleam_string.contains(json_str, "test-recipe") |> should.be_true()
  gleam_string.contains(json_str, "Test Recipe") |> should.be_true()
  gleam_string.contains(json_str, "chicken") |> should.be_true()
}

pub fn user_profile_to_json_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Active,
      goal: Maintain,
      meals_per_day: 3,
    )
  let json = types.user_profile_to_json(profile)
  let json_str = gleam_json.to_string(json)
  gleam_string.contains(json_str, "test-user") |> should.be_true()
  gleam_string.contains(json_str, "180") |> should.be_true()
  gleam_string.contains(json_str, "active") |> should.be_true()
}

// ============================================================================
// JSON decoder tests
// ============================================================================

pub fn macros_decoder_test() {
  let json_str = "{\"protein\": 30.0, \"fat\": 15.0, \"carbs\": 50.0}"
  let result =
    gleam_json.decode(json_str, types.macros_decoder())
    |> result.map_error(fn(_) { "decode failed" })
  result |> should.be_ok()
  case result {
    Ok(m) -> {
      m.protein |> should.equal(30.0)
      m.fat |> should.equal(15.0)
      m.carbs |> should.equal(50.0)
    }
    Error(_) -> should.fail()
  }
}

pub fn ingredient_decoder_test() {
  let json_str = "{\"name\": \"Chicken\", \"quantity\": \"8 oz\"}"
  let result =
    gleam_json.decode(json_str, types.ingredient_decoder())
    |> result.map_error(fn(_) { "decode failed" })
  result |> should.be_ok()
  case result {
    Ok(ing) -> {
      ing.name |> should.equal("Chicken")
      ing.quantity |> should.equal("8 oz")
    }
    Error(_) -> should.fail()
  }
}

pub fn fodmap_level_decoder_low_test() {
  let json_str = "\"low\""
  let result =
    gleam_json.decode(json_str, types.fodmap_level_decoder())
    |> result.map_error(fn(_) { "decode failed" })
  result |> should.be_ok()
  case result {
    Ok(level) -> level |> should.equal(Low)
    Error(_) -> should.fail()
  }
}

pub fn activity_level_decoder_test() {
  let json_str = "\"active\""
  let result =
    gleam_json.decode(json_str, types.activity_level_decoder())
    |> result.map_error(fn(_) { "decode failed" })
  result |> should.be_ok()
  case result {
    Ok(level) -> level |> should.equal(Active)
    Error(_) -> should.fail()
  }
}

pub fn goal_decoder_test() {
  let json_str = "\"maintain\""
  let result =
    gleam_json.decode(json_str, types.goal_decoder())
    |> result.map_error(fn(_) { "decode failed" })
  result |> should.be_ok()
  case result {
    Ok(goal) -> goal |> should.equal(Maintain)
    Error(_) -> should.fail()
  }
}

pub fn meal_type_decoder_test() {
  let json_str = "\"breakfast\""
  let result =
    gleam_json.decode(json_str, types.meal_type_decoder())
    |> result.map_error(fn(_) { "decode failed" })
  result |> should.be_ok()
  case result {
    Ok(mt) -> mt |> should.equal(types.Breakfast)
    Error(_) -> should.fail()
  }
}

// ============================================================================
// FoodSource and FoodSearchResult type tests
// ============================================================================

pub fn food_source_recipe_source_test() {
  let source = types.RecipeSource("recipe-123")
  case source {
    types.RecipeSource(id) -> id |> should.equal("recipe-123")
    _ -> should.fail()
  }
}

pub fn food_source_custom_food_source_test() {
  let source = types.CustomFoodSource("food-123", "user-456")
  case source {
    types.CustomFoodSource(food_id, user_id) -> {
      food_id |> should.equal("food-123")
      user_id |> should.equal("user-456")
    }
    _ -> should.fail()
  }
}

pub fn food_source_usda_source_test() {
  let source = types.UsdaFoodSource(12_345)
  case source {
    types.UsdaFoodSource(fdc_id) -> fdc_id |> should.equal(12_345)
    _ -> should.fail()
  }
}

pub fn custom_food_creation_test() {
  let food =
    types.CustomFood(
      id: "food-1",
      user_id: "user-1",
      name: "My Custom Food",
      brand: option.Some("Brand X"),
      description: option.Some("A delicious food"),
      serving_size: 100.0,
      serving_unit: "g",
      macros: Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
      calories: 290.0,
      micronutrients: option.None,
    )
  food.name |> should.equal("My Custom Food")
  food.brand |> should.equal(option.Some("Brand X"))
  food.serving_size |> should.equal(100.0)
}

pub fn food_search_response_creation_test() {
  let response =
    types.FoodSearchResponse(
      results: [],
      total_count: 0,
      custom_count: 0,
      usda_count: 0,
    )
  response.total_count |> should.equal(0)
}

// ============================================================================
// DailyLog and FoodLogEntry tests
// ============================================================================

pub fn food_log_entry_creation_test() {
  let entry =
    types.FoodLogEntry(
      id: "entry-1",
      recipe_id: "recipe-1",
      recipe_name: "Grilled Chicken",
      servings: 1.5,
      macros: Macros(protein: 60.0, fat: 15.0, carbs: 0.0),
      micronutrients: option.None,
      meal_type: types.Dinner,
      logged_at: "2024-01-15T18:30:00Z",
      source_type: "recipe",
      source_id: "recipe-1",
    )
  entry.recipe_name |> should.equal("Grilled Chicken")
  entry.servings |> should.equal(1.5)
  entry.meal_type |> should.equal(types.Dinner)
}

pub fn daily_log_creation_test() {
  let log =
    types.DailyLog(
      date: "2024-01-15",
      entries: [],
      total_macros: Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
      total_micronutrients: option.None,
    )
  log.date |> should.equal("2024-01-15")
  log.entries |> should.equal([])
}
