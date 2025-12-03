import gleam/json
import gleam/option.{None}
import gleeunit
import gleeunit/should
import shared/types.{
  Active, Breakfast, Dinner, Gain, High, Ingredient, Lose, Low, Lunch, Macros,
  Maintain, Medium, Moderate, Recipe, Sedentary, Snack, UserProfile,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Macros Tests
// ============================================================================

pub fn macros_calories_test() {
  let m = Macros(protein: 30.0, fat: 20.0, carbs: 50.0)
  // 30*4 + 20*9 + 50*4 = 120 + 180 + 200 = 500
  types.macros_calories(m)
  |> should.equal(500.0)
}

pub fn macros_add_test() {
  let a = Macros(protein: 10.0, fat: 5.0, carbs: 20.0)
  let b = Macros(protein: 5.0, fat: 10.0, carbs: 15.0)
  let result = types.macros_add(a, b)
  result.protein |> should.equal(15.0)
  result.fat |> should.equal(15.0)
  result.carbs |> should.equal(35.0)
}

pub fn macros_scale_test() {
  let m = Macros(protein: 10.0, fat: 5.0, carbs: 20.0)
  let result = types.macros_scale(m, 2.0)
  result.protein |> should.equal(20.0)
  result.fat |> should.equal(10.0)
  result.carbs |> should.equal(40.0)
}

pub fn macros_zero_test() {
  let m = types.macros_zero()
  m.protein |> should.equal(0.0)
  m.fat |> should.equal(0.0)
  m.carbs |> should.equal(0.0)
}

pub fn macros_sum_test() {
  let macros = [
    Macros(protein: 10.0, fat: 5.0, carbs: 20.0),
    Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
    Macros(protein: 5.0, fat: 2.5, carbs: 10.0),
  ]
  let result = types.macros_sum(macros)
  result.protein |> should.equal(35.0)
  result.fat |> should.equal(17.5)
  result.carbs |> should.equal(60.0)
}

// ============================================================================
// User Profile Target Tests
// ============================================================================

pub fn daily_macro_targets_active_gain_test() {
  let profile =
    UserProfile(
      id: "test",
      bodyweight: 200.0,
      activity_level: Active,
      goal: Gain,
      meals_per_day: 4,
    )
  let targets = types.daily_macro_targets(profile)
  // Active/gain = 1.0 protein multiplier = 200g protein
  targets.protein |> should.equal(200.0)
  // Fat = 0.3 * 200 = 60g
  targets.fat |> should.equal(60.0)
  // Calories: 200 * 18 * 1.15 = 4140
  // Carbs: (4140 - 200*4 - 60*9) / 4 = (4140 - 800 - 540) / 4 = 700g
  targets.carbs |> should.equal(700.0)
}

pub fn daily_macro_targets_sedentary_lose_test() {
  let profile =
    UserProfile(
      id: "test",
      bodyweight: 180.0,
      activity_level: Sedentary,
      goal: Lose,
      meals_per_day: 3,
    )
  let targets = types.daily_macro_targets(profile)
  // Sedentary/lose = 0.8 protein multiplier = 144g protein
  targets.protein |> should.equal(144.0)
  // Fat = 0.3 * 180 = 54g
  targets.fat |> should.equal(54.0)
  // Calories: 180 * 12 * 0.85 = 1836
  // Carbs: (1836 - 144*4 - 54*9) / 4 = (1836 - 576 - 486) / 4 = 193.5g
  targets.carbs |> should.equal(193.5)
}

// ============================================================================
// JSON Encoding Tests
// ============================================================================

pub fn macros_to_json_test() {
  let m = Macros(protein: 25.0, fat: 10.0, carbs: 30.0)
  let json_str = types.macros_to_json(m) |> json.to_string
  // Should contain all fields
  json_str |> should.not_equal("")
}

pub fn fodmap_level_to_string_test() {
  types.fodmap_level_to_string(Low) |> should.equal("low")
  types.fodmap_level_to_string(Medium) |> should.equal("medium")
  types.fodmap_level_to_string(High) |> should.equal("high")
}

pub fn activity_level_to_string_test() {
  types.activity_level_to_string(Sedentary) |> should.equal("sedentary")
  types.activity_level_to_string(Moderate) |> should.equal("moderate")
  types.activity_level_to_string(Active) |> should.equal("active")
}

pub fn goal_to_string_test() {
  types.goal_to_string(Gain) |> should.equal("gain")
  types.goal_to_string(Maintain) |> should.equal("maintain")
  types.goal_to_string(Lose) |> should.equal("lose")
}

pub fn meal_type_to_string_test() {
  types.meal_type_to_string(Breakfast) |> should.equal("breakfast")
  types.meal_type_to_string(Lunch) |> should.equal("lunch")
  types.meal_type_to_string(Dinner) |> should.equal("dinner")
  types.meal_type_to_string(Snack) |> should.equal("snack")
}

// ============================================================================
// JSON Decoding Tests
// ============================================================================

pub fn macros_decoder_test() {
  let json_str = "{\"protein\": 25.0, \"fat\": 10.0, \"carbs\": 30.0}"
  let result = json.parse(json_str, types.macros_decoder())
  result |> should.be_ok
  let macros = case result {
    Ok(m) -> m
    Error(_) -> Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
  }
  macros.protein |> should.equal(25.0)
  macros.fat |> should.equal(10.0)
  macros.carbs |> should.equal(30.0)
}

pub fn ingredient_decoder_test() {
  let json_str = "{\"name\": \"Chicken breast\", \"quantity\": \"8 oz\"}"
  let result = json.parse(json_str, types.ingredient_decoder())
  result |> should.be_ok
  let ingredient = case result {
    Ok(i) -> i
    Error(_) -> Ingredient(name: "", quantity: "")
  }
  ingredient.name |> should.equal("Chicken breast")
  ingredient.quantity |> should.equal("8 oz")
}

pub fn fodmap_level_decoder_test() {
  json.parse("\"low\"", types.fodmap_level_decoder())
  |> should.equal(Ok(Low))

  json.parse("\"medium\"", types.fodmap_level_decoder())
  |> should.equal(Ok(Medium))

  json.parse("\"high\"", types.fodmap_level_decoder())
  |> should.equal(Ok(High))
}

pub fn activity_level_decoder_test() {
  json.parse("\"sedentary\"", types.activity_level_decoder())
  |> should.equal(Ok(Sedentary))

  json.parse("\"moderate\"", types.activity_level_decoder())
  |> should.equal(Ok(Moderate))

  json.parse("\"active\"", types.activity_level_decoder())
  |> should.equal(Ok(Active))
}

pub fn goal_decoder_test() {
  json.parse("\"gain\"", types.goal_decoder())
  |> should.equal(Ok(Gain))

  json.parse("\"maintain\"", types.goal_decoder())
  |> should.equal(Ok(Maintain))

  json.parse("\"lose\"", types.goal_decoder())
  |> should.equal(Ok(Lose))
}

pub fn meal_type_decoder_test() {
  json.parse("\"breakfast\"", types.meal_type_decoder())
  |> should.equal(Ok(Breakfast))

  json.parse("\"lunch\"", types.meal_type_decoder())
  |> should.equal(Ok(Lunch))

  json.parse("\"dinner\"", types.meal_type_decoder())
  |> should.equal(Ok(Dinner))

  json.parse("\"snack\"", types.meal_type_decoder())
  |> should.equal(Ok(Snack))
}

// ============================================================================
// Roundtrip Tests (Encode -> Decode)
// ============================================================================

pub fn macros_roundtrip_test() {
  let original = Macros(protein: 45.5, fat: 22.3, carbs: 100.0)
  let json_str = types.macros_to_json(original) |> json.to_string
  let result = json.parse(json_str, types.macros_decoder())
  result |> should.be_ok
  let decoded = case result {
    Ok(m) -> m
    Error(_) -> Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
  }
  decoded.protein |> should.equal(45.5)
  decoded.fat |> should.equal(22.3)
  decoded.carbs |> should.equal(100.0)
}

pub fn recipe_roundtrip_test() {
  let original =
    Recipe(
      id: "recipe-123",
      name: "Grilled Chicken",
      ingredients: [
        Ingredient(name: "Chicken breast", quantity: "8 oz"),
        Ingredient(name: "Olive oil", quantity: "1 tbsp"),
      ],
      instructions: ["Season chicken", "Grill for 6 minutes per side"],
      macros: Macros(protein: 50.0, fat: 8.0, carbs: 0.0),
      servings: 2,
      category: "chicken",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  let json_str = types.recipe_to_json(original) |> json.to_string
  let result = json.parse(json_str, types.recipe_decoder())
  result |> should.be_ok
  let decoded = case result {
    Ok(r) -> r
    Error(_) -> original
  }
  decoded.id |> should.equal("recipe-123")
  decoded.name |> should.equal("Grilled Chicken")
  decoded.servings |> should.equal(2)
  decoded.fodmap_level |> should.equal(Low)
  decoded.vertical_compliant |> should.be_true
}

pub fn user_profile_roundtrip_test() {
  let original =
    UserProfile(
      id: "user-456",
      bodyweight: 185.0,
      activity_level: Moderate,
      goal: Maintain,
      meals_per_day: 4,
    )
  let json_str = types.user_profile_to_json(original) |> json.to_string
  let result = json.parse(json_str, types.user_profile_decoder())
  result |> should.be_ok
  let decoded = case result {
    Ok(u) -> u
    Error(_) -> original
  }
  decoded.id |> should.equal("user-456")
  decoded.bodyweight |> should.equal(185.0)
  decoded.activity_level |> should.equal(Moderate)
  decoded.goal |> should.equal(Maintain)
  decoded.meals_per_day |> should.equal(4)
}

// ============================================================================
// FoodLogEntry Tests
// ============================================================================

pub fn food_log_entry_roundtrip_test() {
  let entry =
    types.FoodLogEntry(
      id: "log-001",
      recipe_id: "recipe-123",
      recipe_name: "Grilled Chicken",
      servings: 1.5,
      macros: Macros(protein: 75.0, fat: 12.0, carbs: 0.0),
      micronutrients: None,
      meal_type: Lunch,
      logged_at: "2025-01-15T12:30:00Z",
    )
  let json_str = types.food_log_entry_to_json(entry) |> json.to_string
  let result = json.parse(json_str, types.food_log_entry_decoder())
  result |> should.be_ok
  let decoded = case result {
    Ok(e) -> e
    Error(_) -> entry
  }
  decoded.id |> should.equal("log-001")
  decoded.recipe_name |> should.equal("Grilled Chicken")
  decoded.servings |> should.equal(1.5)
  decoded.meal_type |> should.equal(Lunch)
}

pub fn daily_log_roundtrip_test() {
  let entries = [
    types.FoodLogEntry(
      id: "log-001",
      recipe_id: "recipe-1",
      recipe_name: "Breakfast",
      servings: 1.0,
      macros: Macros(protein: 30.0, fat: 15.0, carbs: 20.0),
      micronutrients: None,
      meal_type: Breakfast,
      logged_at: "2025-01-15T08:00:00Z",
    ),
    types.FoodLogEntry(
      id: "log-002",
      recipe_id: "recipe-2",
      recipe_name: "Lunch",
      servings: 1.0,
      macros: Macros(protein: 45.0, fat: 20.0, carbs: 50.0),
      micronutrients: None,
      meal_type: Lunch,
      logged_at: "2025-01-15T12:00:00Z",
    ),
  ]
  let daily =
    types.DailyLog(
      date: "2025-01-15",
      entries: entries,
      total_macros: Macros(protein: 75.0, fat: 35.0, carbs: 70.0),
      total_micronutrients: None,
    )
  let json_str = types.daily_log_to_json(daily) |> json.to_string
  let result = json.parse(json_str, types.daily_log_decoder())
  result |> should.be_ok
  let decoded = case result {
    Ok(d) -> d
    Error(_) -> daily
  }
  decoded.date |> should.equal("2025-01-15")
  decoded.total_macros.protein |> should.equal(75.0)
}

// ============================================================================
// Edge Case Tests
// ============================================================================

pub fn macros_scale_zero_test() {
  let m = Macros(protein: 30.0, fat: 15.0, carbs: 40.0)
  let result = types.macros_scale(m, 0.0)
  result.protein |> should.equal(0.0)
  result.fat |> should.equal(0.0)
  result.carbs |> should.equal(0.0)
}

pub fn macros_scale_negative_test() {
  let m = Macros(protein: 30.0, fat: 15.0, carbs: 40.0)
  let result = types.macros_scale(m, -1.0)
  result.protein |> should.equal(-30.0)
  result.fat |> should.equal(-15.0)
  result.carbs |> should.equal(-40.0)
}

pub fn macros_sum_empty_list_test() {
  let result = types.macros_sum([])
  result.protein |> should.equal(0.0)
  result.fat |> should.equal(0.0)
  result.carbs |> should.equal(0.0)
}

pub fn macros_calories_zero_test() {
  let m = Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
  types.macros_calories(m) |> should.equal(0.0)
}

pub fn fodmap_level_decoder_invalid_test() {
  // Invalid value should return default (Low)
  let result = json.parse("\"invalid\"", types.fodmap_level_decoder())
  result |> should.be_error
}

pub fn activity_level_decoder_invalid_test() {
  // Invalid value should return default (Sedentary)
  let result = json.parse("\"invalid\"", types.activity_level_decoder())
  result |> should.be_error
}

pub fn goal_decoder_invalid_test() {
  // Invalid value should return default (Maintain)
  let result = json.parse("\"invalid\"", types.goal_decoder())
  result |> should.be_error
}

pub fn meal_type_decoder_invalid_test() {
  // Invalid value should return default (Snack)
  let result = json.parse("\"invalid\"", types.meal_type_decoder())
  result |> should.be_error
}

pub fn ingredient_to_json_test() {
  let ing = Ingredient(name: "Beef", quantity: "1 lb")
  let json_str = types.ingredient_to_json(ing) |> json.to_string
  json_str |> should.not_equal("")
}

// ============================================================================
// Additional Daily Macro Target Tests
// ============================================================================

pub fn daily_macro_targets_moderate_maintain_test() {
  let profile =
    UserProfile(
      id: "test",
      bodyweight: 150.0,
      activity_level: Moderate,
      goal: Maintain,
      meals_per_day: 3,
    )
  let targets = types.daily_macro_targets(profile)
  // Moderate/maintain = 0.9 protein multiplier = 135g protein
  targets.protein |> should.equal(135.0)
  // Fat = 0.3 * 150 = 45g
  targets.fat |> should.equal(45.0)
}

pub fn daily_macro_targets_active_lose_test() {
  let profile =
    UserProfile(
      id: "test",
      bodyweight: 200.0,
      activity_level: Active,
      goal: Lose,
      meals_per_day: 4,
    )
  let targets = types.daily_macro_targets(profile)
  // Active = 1.0 multiplier regardless of goal for protein
  targets.protein |> should.equal(200.0)
  // Fat = 0.3 * 200 = 60g
  targets.fat |> should.equal(60.0)
}
