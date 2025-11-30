import gleam/json
import gleeunit
import gleeunit/should
import shared/types.{
  Active, Breakfast, Dinner, Gain, High, Ingredient,
  Low, Lunch, Macros, Maintain, Medium, Moderate, Recipe, Sedentary, Snack,
  UserProfile, Lose,
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
  let profile = UserProfile(
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
  let profile = UserProfile(
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
  let original = Recipe(
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
  let original = UserProfile(
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
