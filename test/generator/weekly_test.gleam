//// TCR Cycle 2: Weekly Generation Engine
//// Testing types and generation functions

import gleam/list
import gleeunit/should
import meal_planner/generator/weekly.{
  type Constraints, type DailyMacros, type DayMeals, type GenerationError,
  type MacroComparison, type MealType, type RotationEntry, type WeeklyMealPlan,
  Constraints, DayMeals, Dinner, LockedMeal, NotEnoughRecipes, OnTarget, Over,
  RotationEntry, Under, WeeklyMealPlan, analyze_plan, calculate_daily_macros,
  days_count, filter_by_rotation, generate_weekly_plan,
  generate_weekly_plan_with_constraints, is_plan_balanced, is_travel_day,
  total_weekly_macros,
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

// ============================================================================
// TCR Cycle 2: Generation Function Tests
// ============================================================================

pub fn generate_weekly_plan_creates_seven_days_test() {
  let recipes = [
    test_recipe("Recipe1", 30.0, 15.0, 40.0),
    test_recipe("Recipe2", 35.0, 12.0, 45.0),
    test_recipe("Recipe3", 25.0, 18.0, 35.0),
    test_recipe("Recipe4", 40.0, 10.0, 50.0),
    test_recipe("Recipe5", 28.0, 14.0, 38.0),
    test_recipe("Recipe6", 32.0, 16.0, 42.0),
    test_recipe("Recipe7", 38.0, 11.0, 48.0),
  ]
  let target = target_macros()

  let result = generate_weekly_plan("2025-12-22", recipes, target)

  case result {
    Ok(plan) -> {
      days_count(plan) |> should.equal(7)
      plan.week_of |> should.equal("2025-12-22")
    }
    Error(_) -> should.fail()
  }
}

pub fn generate_weekly_plan_fails_with_insufficient_recipes_test() {
  // Only 2 recipes - not enough for 7 days × 3 meals = 21 meals
  let recipes = [
    test_recipe("Recipe1", 30.0, 15.0, 40.0),
    test_recipe("Recipe2", 35.0, 12.0, 45.0),
  ]
  let target = target_macros()

  let result = generate_weekly_plan("2025-12-22", recipes, target)

  case result {
    Ok(_) -> should.fail()
    Error(NotEnoughRecipes) -> should.be_true(True)
  }
}

pub fn generate_weekly_plan_assigns_all_meals_test() {
  let recipes = [
    test_recipe("Breakfast1", 30.0, 15.0, 40.0),
    test_recipe("Breakfast2", 28.0, 14.0, 38.0),
    test_recipe("Lunch1", 45.0, 12.0, 55.0),
    test_recipe("Lunch2", 42.0, 14.0, 52.0),
    test_recipe("Dinner1", 50.0, 20.0, 30.0),
    test_recipe("Dinner2", 48.0, 18.0, 32.0),
    test_recipe("Extra", 35.0, 16.0, 45.0),
  ]
  let target = target_macros()

  let result = generate_weekly_plan("2025-12-22", recipes, target)

  case result {
    Ok(plan) -> {
      // Each day should have non-empty meal names
      list.each(plan.days, fn(day: DayMeals) {
        should.not_equal(day.breakfast.name, "")
        should.not_equal(day.lunch.name, "")
        should.not_equal(day.dinner.name, "")
      })
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// TCR Cycle 3: Macro Validation Tests
// ============================================================================

pub fn analyze_plan_returns_daily_macros_for_each_day_test() {
  let day = test_day_meals()
  let plan =
    WeeklyMealPlan(
      week_of: "2025-12-22",
      days: [day, day, day, day, day, day, day],
      target_macros: target_macros(),
    )

  let analysis = analyze_plan(plan)

  // Should return 7 daily macro summaries
  list.length(analysis) |> should.equal(7)
}

pub fn analyze_plan_calculates_correct_macros_test() {
  let day = test_day_meals()
  let plan =
    WeeklyMealPlan(
      week_of: "2025-12-22",
      days: [day],
      target_macros: target_macros(),
    )

  let analysis = analyze_plan(plan)
  let assert [first_day] = analysis

  // From test_day_meals: 95g protein, 45g fat, 27g carbs
  first_day.actual.protein |> should.equal(95.0)
  first_day.actual.fat |> should.equal(45.0)
  first_day.actual.carbs |> should.equal(27.0)
}

pub fn is_plan_balanced_returns_true_when_all_days_on_target_test() {
  // Create recipes that sum to exactly the target
  // Target: 150g protein, 65g fat, 200g carbs
  let balanced_day =
    DayMeals(
      day: "Monday",
      // 50g protein + 22g fat + 67g carbs each meal = 150/66/201
      breakfast: test_recipe("B", 50.0, 22.0, 67.0),
      lunch: test_recipe("L", 50.0, 22.0, 67.0),
      dinner: test_recipe("D", 50.0, 22.0, 67.0),
    )
  let plan =
    WeeklyMealPlan(
      week_of: "2025-12-22",
      days: [
        balanced_day,
        balanced_day,
        balanced_day,
        balanced_day,
        balanced_day,
        balanced_day,
        balanced_day,
      ],
      target_macros: target_macros(),
    )

  is_plan_balanced(plan) |> should.be_true
}

pub fn is_plan_balanced_returns_false_when_under_target_test() {
  // Use test_day_meals which is under target
  let day = test_day_meals()
  let plan =
    WeeklyMealPlan(
      week_of: "2025-12-22",
      days: [day, day, day, day, day, day, day],
      target_macros: target_macros(),
    )

  is_plan_balanced(plan) |> should.be_false
}

// ============================================================================
// TCR Cycle 4: Constraint Types Tests
// ============================================================================

pub fn locked_meal_sets_specific_recipe_test() {
  let special_recipe = test_recipe("Locked Pasta", 45.0, 20.0, 80.0)
  let recipes = [
    test_recipe("Recipe1", 30.0, 15.0, 40.0),
    test_recipe("Recipe2", 35.0, 12.0, 45.0),
    test_recipe("Recipe3", 25.0, 18.0, 35.0),
  ]
  let constraints =
    Constraints(
      locked_meals: [
        LockedMeal(day: "Friday", meal_type: Dinner, recipe: special_recipe),
      ],
      travel_dates: [],
    )

  let result =
    generate_weekly_plan_with_constraints(
      "2025-12-22",
      recipes,
      target_macros(),
      constraints,
    )

  case result {
    Ok(plan) -> {
      // Find Friday and check dinner
      let friday = list.find(plan.days, fn(d: DayMeals) { d.day == "Friday" })
      case friday {
        Ok(day) -> day.dinner.name |> should.equal("Locked Pasta")
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn empty_constraints_generates_normal_plan_test() {
  let recipes = [
    test_recipe("Recipe1", 30.0, 15.0, 40.0),
    test_recipe("Recipe2", 35.0, 12.0, 45.0),
    test_recipe("Recipe3", 25.0, 18.0, 35.0),
  ]
  let constraints = Constraints(locked_meals: [], travel_dates: [])

  let result =
    generate_weekly_plan_with_constraints(
      "2025-12-22",
      recipes,
      target_macros(),
      constraints,
    )

  case result {
    Ok(plan) -> days_count(plan) |> should.equal(7)
    Error(_) -> should.fail()
  }
}

// ============================================================================
// TCR Cycle 5: Rotation History Tests
// ============================================================================

pub fn filter_by_rotation_excludes_recent_recipes_test() {
  let all_recipes = [
    test_recipe("Fresh Recipe", 30.0, 15.0, 40.0),
    test_recipe("Recent Recipe", 35.0, 12.0, 45.0),
    test_recipe("Old Recipe", 25.0, 18.0, 35.0),
  ]
  // Recent recipe was used 10 days ago (within 30-day window)
  let history = [RotationEntry(recipe_name: "Recent Recipe", days_ago: 10)]

  let available = filter_by_rotation(all_recipes, history, 30)

  // Should exclude "Recent Recipe"
  list.length(available) |> should.equal(2)
  list.any(available, fn(r) { r.name == "Fresh Recipe" }) |> should.be_true
  list.any(available, fn(r) { r.name == "Old Recipe" }) |> should.be_true
  list.any(available, fn(r) { r.name == "Recent Recipe" }) |> should.be_false
}

pub fn filter_by_rotation_includes_old_recipes_test() {
  let all_recipes = [test_recipe("Old Recipe", 30.0, 15.0, 40.0)]
  // Recipe was used 35 days ago (outside 30-day window)
  let history = [RotationEntry(recipe_name: "Old Recipe", days_ago: 35)]

  let available = filter_by_rotation(all_recipes, history, 30)

  // Should include the old recipe
  list.length(available) |> should.equal(1)
}

pub fn filter_by_rotation_with_empty_history_returns_all_test() {
  let all_recipes = [
    test_recipe("Recipe1", 30.0, 15.0, 40.0),
    test_recipe("Recipe2", 35.0, 12.0, 45.0),
  ]
  let history: List(RotationEntry) = []

  let available = filter_by_rotation(all_recipes, history, 30)

  list.length(available) |> should.equal(2)
}

// ============================================================================
// TCR Cycle 6: Travel Date Tests
// ============================================================================

pub fn is_travel_day_returns_true_for_matching_day_test() {
  let constraints =
    Constraints(locked_meals: [], travel_dates: ["Tuesday", "Wednesday"])

  is_travel_day("Tuesday", constraints) |> should.be_true
  is_travel_day("Wednesday", constraints) |> should.be_true
}

pub fn is_travel_day_returns_false_for_non_travel_day_test() {
  let constraints = Constraints(locked_meals: [], travel_dates: ["Tuesday"])

  is_travel_day("Monday", constraints) |> should.be_false
  is_travel_day("Friday", constraints) |> should.be_false
}

pub fn is_travel_day_returns_false_with_empty_travel_dates_test() {
  let constraints = Constraints(locked_meals: [], travel_dates: [])

  is_travel_day("Monday", constraints) |> should.be_false
}
