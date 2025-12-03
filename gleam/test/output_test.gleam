import gleam/string
import gleeunit/should
import meal_planner/meal_plan.{DailyPlan, Meal, WeeklyMealPlan}
import meal_planner/output.{
  format_categorized_shopping_list, format_daily_plan, format_macros,
  format_meal_timing, format_recipe, format_user_profile, format_weekly_plan,
}
import meal_planner/shopping_list.{organize_shopping_list}
import shared/types.{
  type Recipe, Active, Gain, Ingredient, Low, Macros, Moderate, Recipe,
  UserProfile,
}

// Helper to create test recipe
fn make_recipe(name: String) -> Recipe {
  Recipe(
    id: name,
    name: name,
    ingredients: [
      Ingredient(name: "Ground beef", quantity: "1 lb"),
      Ingredient(name: "Salt", quantity: "1 tsp"),
    ],
    instructions: ["Cook beef", "Season with salt"],
    macros: Macros(protein: 40.0, fat: 20.0, carbs: 0.0),
    servings: 1,
    category: "beef",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

// Test format_macros
pub fn format_macros_basic_test() {
  let macros = Macros(protein: 40.0, fat: 20.0, carbs: 30.0)
  let result = format_macros(macros)

  result |> string.contains("P:40g") |> should.be_true()
  result |> string.contains("F:20g") |> should.be_true()
  result |> string.contains("C:30g") |> should.be_true()
}

pub fn format_macros_with_decimals_test() {
  let macros = Macros(protein: 42.5, fat: 18.3, carbs: 25.7)
  let result = format_macros(macros)

  // Should round to whole numbers
  result |> string.contains("P:43g") |> should.be_true()
  result |> string.contains("F:18g") |> should.be_true()
  result |> string.contains("C:26g") |> should.be_true()
}

// Test format_recipe
pub fn format_recipe_basic_test() {
  let recipe = make_recipe("Grilled Steak")
  let result = format_recipe(recipe)

  result |> string.contains("Grilled Steak") |> should.be_true()
  result |> string.contains("Ground beef") |> should.be_true()
  result |> string.contains("1 lb") |> should.be_true()
  result |> string.contains("Cook beef") |> should.be_true()
}

pub fn format_recipe_includes_macros_test() {
  let recipe = make_recipe("Test Recipe")
  let result = format_recipe(recipe)

  result |> string.contains("P:40g") |> should.be_true()
}

// Test format_meal_timing
pub fn format_meal_timing_morning_test() {
  let result = format_meal_timing(1, 7)
  result |> string.contains("7:00 AM") |> should.be_true()
  result |> string.contains("Meal 1") |> should.be_true()
}

pub fn format_meal_timing_afternoon_test() {
  let result = format_meal_timing(2, 12)
  result |> string.contains("12:00 PM") |> should.be_true()
}

pub fn format_meal_timing_evening_test() {
  let result = format_meal_timing(3, 18)
  result |> string.contains("6:00 PM") |> should.be_true()
}

// Test format_user_profile
pub fn format_user_profile_basic_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Gain,
      meals_per_day: 4,
    )
  let result = format_user_profile(profile)

  result |> string.contains("180") |> should.be_true()
  result |> string.contains("Moderate") |> should.be_true()
  result |> string.contains("Gain") |> should.be_true()
  result |> string.contains("4") |> should.be_true()
}

pub fn format_user_profile_includes_targets_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 200.0,
      activity_level: Active,
      goal: Gain,
      meals_per_day: 4,
    )
  let result = format_user_profile(profile)

  // Should include calculated macro targets
  result |> string.contains("Daily") |> should.be_true()
  result |> string.contains("Protein") |> should.be_true()
}

// Test format_daily_plan
pub fn format_daily_plan_test() {
  let recipe = make_recipe("Steak Dinner")
  let plan =
    DailyPlan(day_name: "Monday", meals: [
      Meal(recipe: recipe, portion_size: 1.0),
    ])

  let result = format_daily_plan(plan, 7)

  result |> string.contains("Monday") |> should.be_true()
  result |> string.contains("Steak Dinner") |> should.be_true()
}

pub fn format_daily_plan_multiple_meals_test() {
  let recipe1 = make_recipe("Breakfast")
  let recipe2 = make_recipe("Lunch")
  let plan =
    DailyPlan(day_name: "Tuesday", meals: [
      Meal(recipe: recipe1, portion_size: 1.0),
      Meal(recipe: recipe2, portion_size: 1.5),
    ])

  let result = format_daily_plan(plan, 7)

  result |> string.contains("Breakfast") |> should.be_true()
  result |> string.contains("Lunch") |> should.be_true()
  result |> string.contains("1.5x") |> should.be_true()
}

// Test format_categorized_shopping_list
pub fn format_categorized_shopping_list_test() {
  let ingredients = [
    Ingredient(name: "Ground beef", quantity: "2 lb"),
    Ingredient(name: "Cheddar cheese", quantity: "8 oz"),
    Ingredient(name: "Spinach", quantity: "1 cup"),
    Ingredient(name: "Salt", quantity: "2 tsp"),
  ]

  let categorized = organize_shopping_list(ingredients)
  let result = format_categorized_shopping_list(categorized)

  result |> string.contains("Protein") |> should.be_true()
  result |> string.contains("Ground beef") |> should.be_true()
  result |> string.contains("Dairy") |> should.be_true()
  result |> string.contains("Cheddar cheese") |> should.be_true()
}

pub fn format_categorized_shopping_list_empty_categories_test() {
  let ingredients = [Ingredient(name: "Ground beef", quantity: "1 lb")]

  let categorized = organize_shopping_list(ingredients)
  let result = format_categorized_shopping_list(categorized)

  // Should only show Protein category since that's all we have
  result |> string.contains("Protein") |> should.be_true()
  // Should not include empty category headers
  { string.contains(result, "Dairy:") == False } |> should.be_true()
}

// Test format_weekly_plan
pub fn format_weekly_plan_basic_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Gain,
      meals_per_day: 3,
    )

  let recipe = make_recipe("Steak")
  let day =
    DailyPlan(day_name: "Monday", meals: [
      Meal(recipe: recipe, portion_size: 1.0),
    ])

  let plan =
    WeeklyMealPlan(days: [day], shopping_list: [], user_profile: profile)

  let result = format_weekly_plan(plan)

  result |> string.contains("Weekly Meal Plan") |> should.be_true()
  result |> string.contains("Monday") |> should.be_true()
  result |> string.contains("Steak") |> should.be_true()
}

pub fn format_weekly_plan_includes_summary_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Gain,
      meals_per_day: 3,
    )

  let recipe = make_recipe("Steak")
  let day =
    DailyPlan(day_name: "Monday", meals: [
      Meal(recipe: recipe, portion_size: 1.0),
    ])

  let plan =
    WeeklyMealPlan(
      days: [day],
      shopping_list: [Ingredient(name: "Ground beef", quantity: "1 lb")],
      user_profile: profile,
    )

  let result = format_weekly_plan(plan)

  result |> string.contains("Summary") |> should.be_true()
  result |> string.contains("Shopping List") |> should.be_true()
}

// Test empty weekly plan formatting
pub fn format_weekly_plan_empty_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Gain,
      meals_per_day: 3,
    )

  let plan = WeeklyMealPlan(days: [], shopping_list: [], user_profile: profile)

  let result = format_weekly_plan(plan)

  result |> string.contains("Weekly Meal Plan") |> should.be_true()
}
