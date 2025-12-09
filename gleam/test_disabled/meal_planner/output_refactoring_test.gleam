/// Tests for refactored output formatting functions
/// Tests that formatting methods have been properly moved to their data types
/// without changing functionality
import gleam/int
import gleeunit
import gleeunit/should
import meal_planner/meal_plan.{
  type Meal, format_daily_plan, format_meal_entry, format_meal_timing,
  format_portion, format_weekly_plan_header,
}
import meal_planner/types.{
  Active, Gain, Ingredient, Low, Macros, Recipe, Sedentary, UserProfile,
  activity_level_to_display_string, goal_to_display_string,
  ingredient_to_display_string, ingredient_to_shopping_list_line,
  macros_to_string, macros_to_string_with_calories, recipe_to_display_string,
  user_profile_to_display_string,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Macros Formatting Tests
// ============================================================================

pub fn test_macros_to_string() {
  let m = Macros(protein: 50.4, fat: 20.6, carbs: 75.1)
  let result = macros_to_string(m)
  result
  |> should.equal("P:50g F:21g C:75g")
}

pub fn test_macros_to_string_with_calories() {
  let m = Macros(protein: 50.0, fat: 20.0, carbs: 75.0)
  let result = macros_to_string_with_calories(m)
  // Calories: 50*4 + 20*9 + 75*4 = 200 + 180 + 300 = 680
  result
  |> should.equal("P:50g F:20g C:75g (680 cal)")
}

pub fn test_macros_to_string_zero() {
  let m = Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
  let result = macros_to_string(m)
  result
  |> should.equal("P:0g F:0g C:0g")
}

// ============================================================================
// Ingredient Formatting Tests
// ============================================================================

pub fn test_ingredient_to_display_string() {
  let ing = Ingredient(name: "Flour", quantity: "2 cups")
  let result = ingredient_to_display_string(ing)
  result
  |> should.equal("  - Flour: 2 cups")
}

pub fn test_ingredient_to_shopping_list_line() {
  let ing = Ingredient(name: "Chicken", quantity: "1 lb")
  let result = ingredient_to_shopping_list_line(ing)
  result
  |> should.equal("    - Chicken: 1 lb")
}

// ============================================================================
// Recipe Formatting Tests
// ============================================================================

pub fn test_recipe_to_display_string_simple() {
  let recipe =
    Recipe(
      id: "test1",
      name: "Simple Salad",
      ingredients: [
        Ingredient(name: "Lettuce", quantity: "2 cups"),
        Ingredient(name: "Tomato", quantity: "1"),
      ],
      instructions: ["Wash vegetables", "Chop and mix", "Serve"],
      macros: Macros(protein: 10.0, fat: 5.0, carbs: 15.0),
      servings: 1,
      category: "Vegetable",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let result = recipe_to_display_string(recipe)

  result
  |> should.contain("Simple Salad")
  result
  |> should.contain("Macros: P:10g F:5g C:15g")
  result
  |> should.contain("Ingredients:")
  result
  |> should.contain("  - Lettuce: 2 cups")
  result
  |> should.contain("  - Tomato: 1")
  result
  |> should.contain("Instructions:")
  result
  |> should.contain("  1. Wash vegetables")
  result
  |> should.contain("  2. Chop and mix")
  result
  |> should.contain("  3. Serve")
}

// ============================================================================
// Meal Timing Tests (moved from output.gleam)
// ============================================================================

pub fn test_format_meal_timing_breakfast() {
  let result = format_meal_timing(1, 7)
  result
  |> should.equal("[7:00 AM] Meal 1")
}

pub fn test_format_meal_timing_lunch() {
  let result = format_meal_timing(2, 11)
  result
  |> should.equal("[11:00 AM] Meal 2")
}

pub fn test_format_meal_timing_dinner() {
  let result = format_meal_timing(3, 18)
  result
  |> should.equal("[6:00 PM] Meal 3")
}

pub fn test_format_meal_timing_midnight() {
  let result = format_meal_timing(4, 0)
  result
  |> should.equal("[12:00 AM] Meal 4")
}

pub fn test_format_meal_timing_noon() {
  let result = format_meal_timing(2, 12)
  result
  |> should.equal("[12:00 PM] Meal 2")
}

// ============================================================================
// Portion Formatting Tests
// ============================================================================

pub fn test_format_portion_whole() {
  let result = format_portion(1.0)
  result
  |> should.equal("1.0x portion")
}

pub fn test_format_portion_half() {
  let result = format_portion(0.5)
  result
  |> should.equal("0.5x portion")
}

pub fn test_format_portion_one_and_half() {
  let result = format_portion(1.5)
  result
  |> should.equal("1.5x portion")
}

// ============================================================================
// User Profile Formatting Tests
// ============================================================================

pub fn test_user_profile_to_display_string() {
  let profile =
    UserProfile(
      id: "user1",
      bodyweight: 200.0,
      activity_level: Active,
      goal: Gain,
      meals_per_day: 4,
      micronutrient_goals: None,
    )

  let result = user_profile_to_display_string(profile)

  result
  |> should.contain("==== YOUR VERTICAL DIET PROFILE ====")
  result
  |> should.contain("Bodyweight: 200 lbs")
  result
  |> should.contain("Activity Level: Active")
  result
  |> should.contain("Goal: Gain")
  result
  |> should.contain("Meals per Day: 4")
  result
  |> should.contain("--- Daily Macro Targets ---")
  result
  |> should.contain("====================================")
}

// ============================================================================
// Activity Level and Goal Display Tests
// ============================================================================

pub fn test_activity_level_to_display_string_active() {
  activity_level_to_display_string(Active)
  |> should.equal("Active")
}

pub fn test_activity_level_to_display_string_sedentary() {
  activity_level_to_display_string(Sedentary)
  |> should.equal("Sedentary")
}

pub fn test_goal_to_display_string_gain() {
  goal_to_display_string(Gain)
  |> should.equal("Gain")
}

// ============================================================================
// Daily Plan Formatting Tests
// ============================================================================

pub fn test_format_daily_plan() {
  let recipe =
    Recipe(
      id: "test1",
      name: "Eggs and Toast",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
      servings: 1,
      category: "Breakfast",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let meal = Meal(recipe: recipe, portion_size: 1.0)

  let daily_plan = meal_plan.DailyPlan(day_name: "Monday", meals: [meal])

  let result = format_daily_plan(daily_plan, 7)

  result
  |> should.contain("--- Monday ---")
  result
  |> should.contain("Day Total: P:20g F:10g C:30g")
  result
  |> should.contain("[7:00 AM] Meal 1")
  result
  |> should.contain("Eggs and Toast")
  result
  |> should.contain("1.0x portion")
}

pub fn test_format_meal_entry() {
  let recipe =
    Recipe(
      id: "test2",
      name: "Chicken Breast",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 35.0, fat: 5.0, carbs: 0.0),
      servings: 1,
      category: "Protein",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let meal = Meal(recipe: recipe, portion_size: 1.5)

  let result = format_meal_entry(meal, 0, 7)

  result
  |> should.contain("[7:00 AM] Meal 1")
  result
  |> should.contain("Chicken Breast")
  result
  |> should.contain("1.5x portion")
  result
  |> should.contain("P:52g F:7g C:0g")
}

// ============================================================================
// Weekly Plan Header Formatting Tests
// ============================================================================

pub fn test_format_weekly_plan_header() {
  let profile =
    UserProfile(
      id: "user1",
      bodyweight: 180.0,
      activity_level: Active,
      goal: Gain,
      meals_per_day: 5,
      micronutrient_goals: None,
    )

  let result = format_weekly_plan_header(profile)

  result
  |> should.contain("=== Weekly Meal Plan ===")
  result
  |> should.contain("Profile:")
  result
  |> should.contain("180 lbs")
  result
  |> should.contain("Active")
  result
  |> should.contain("Gain")
  result
  |> should.contain("Daily Targets:")
}
