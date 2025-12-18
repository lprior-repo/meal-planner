//// TCR Cycle 1: Weekly Generation Engine Types
//// GREEN PHASE - Implementing to pass tests

import gleeunit/should
import meal_planner/generator/weekly.{
  type DailyMacros, type DayMeals, type MacroComparison, type WeeklyMealPlan,
  DayMeals, OnTarget, Over, Under, WeeklyMealPlan, calculate_daily_macros,
  days_count, total_weekly_macros,
}
import meal_planner/id
import meal_planner/types.{type Macros, type Recipe, Low, Macros, Recipe}

// ============================================================================
// Test Fixtures
// ============================================================================

fn test_recipe(name: String, protein: Float, fat: Float, carbs: Float) -> Recipe {
  Recipe(
    id: id.recipe_id("1"),
    name: name,
    ingredients: [],
    instructions: [],
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    servings: 1,
    category: "test",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

fn test_day_meals() -> DayMeals {
  DayMeals(
    day: "Monday",
    breakfast: test_recipe("Eggs", 20.0, 15.0, 2.0),
    lunch: test_recipe("Chicken Salad", 40.0, 10.0, 15.0),
    dinner: test_recipe("Salmon", 35.0, 20.0, 10.0),
  )
}

fn target_macros() -> Macros {
  // Target: 150g protein, 65g fat, 200g carbs (~2000 cal)
  Macros(protein: 150.0, fat: 65.0, carbs: 200.0)
}

// ============================================================================
// DayMeals Tests
// ============================================================================

pub fn day_meals_creation_test() {
  let day = test_day_meals()
  day.day |> should.equal("Monday")
  day.breakfast.name |> should.equal("Eggs")
  day.lunch.name |> should.equal("Chicken Salad")
  day.dinner.name |> should.equal("Salmon")
}

pub fn calculate_daily_macros_sums_all_meals_test() {
  let day = test_day_meals()
  let target = target_macros()
  let daily = calculate_daily_macros(day, target)

  // Expected: 20+40+35 = 95g protein, 15+10+20 = 45g fat, 2+15+10 = 27g carbs
  daily.actual.protein |> should.equal(95.0)
  daily.actual.fat |> should.equal(45.0)
  daily.actual.carbs |> should.equal(27.0)
}

pub fn calculate_daily_macros_calories_test() {
  let day = test_day_meals()
  let target = target_macros()
  let daily = calculate_daily_macros(day, target)

  // Calories: 95*4 + 45*9 + 27*4 = 380 + 405 + 108 = 893 cal
  daily.calories |> should.equal(893.0)
}

pub fn daily_macros_under_target_test() {
  let day = test_day_meals()
  let target = target_macros()
  let daily = calculate_daily_macros(day, target)

  // 95g protein vs 150g target = Under
  daily.protein_status |> should.equal(Under)
  // 45g fat vs 65g target = Under
  daily.fat_status |> should.equal(Under)
  // 27g carbs vs 200g target = Under
  daily.carbs_status |> should.equal(Under)
}

// ============================================================================
// WeeklyMealPlan Tests
// ============================================================================

pub fn weekly_meal_plan_has_seven_days_test() {
  let plan =
    WeeklyMealPlan(
      week_of: "2025-12-22",
      days: [
        test_day_meals(),
        test_day_meals(),
        test_day_meals(),
        test_day_meals(),
        test_day_meals(),
        test_day_meals(),
        test_day_meals(),
      ],
      target_macros: target_macros(),
    )

  days_count(plan) |> should.equal(7)
}

pub fn total_weekly_macros_sums_all_days_test() {
  let day = test_day_meals()
  let plan =
    WeeklyMealPlan(
      week_of: "2025-12-22",
      days: [day, day, day, day, day, day, day],
      target_macros: target_macros(),
    )

  let weekly = total_weekly_macros(plan)
  // 7 days * 95g protein = 665g
  weekly.protein |> should.equal(665.0)
  // 7 days * 45g fat = 315g
  weekly.fat |> should.equal(315.0)
  // 7 days * 27g carbs = 189g
  weekly.carbs |> should.equal(189.0)
}

// ============================================================================
// MacroComparison Tests
// ============================================================================

pub fn macro_comparison_on_target_within_10_percent_test() {
  // 135g actual vs 150g target = 90% = On Target
  let day =
    DayMeals(
      day: "Tuesday",
      breakfast: test_recipe("High Protein", 45.0, 20.0, 60.0),
      lunch: test_recipe("High Protein", 45.0, 20.0, 60.0),
      dinner: test_recipe("High Protein", 45.0, 23.0, 60.0),
    )
  let target = target_macros()
  let daily = calculate_daily_macros(day, target)

  // 135g protein vs 150g = 90% = On Target (within 10%)
  daily.protein_status |> should.equal(OnTarget)
  // 63g fat vs 65g = 97% = On Target
  daily.fat_status |> should.equal(OnTarget)
  // 180g carbs vs 200g = 90% = On Target
  daily.carbs_status |> should.equal(OnTarget)
}

pub fn macro_comparison_over_target_test() {
  let day =
    DayMeals(
      day: "Wednesday",
      breakfast: test_recipe("Surplus", 60.0, 30.0, 80.0),
      lunch: test_recipe("Surplus", 60.0, 30.0, 80.0),
      dinner: test_recipe("Surplus", 60.0, 30.0, 80.0),
    )
  // Lower targets to force Over status
  let target = Macros(protein: 100.0, fat: 50.0, carbs: 150.0)
  let daily = calculate_daily_macros(day, target)

  // 180g protein vs 100g target = 180% = Over
  daily.protein_status |> should.equal(Over)
  // 90g fat vs 50g = 180% = Over
  daily.fat_status |> should.equal(Over)
  // 240g carbs vs 150g = 160% = Over
  daily.carbs_status |> should.equal(Over)
}
