import gleam/list
import gleeunit/should
import meal_planner/meal_plan.{
  DailyPlan, Meal, WeeklyMealPlan, daily_plan_macros, default_recipe,
  generate_weekly_plan, meal_macros, weekly_plan_avg_daily_macros,
  weekly_plan_macros,
}
import meal_planner/types.{Active, Low, Macros, Maintain, Recipe, UserProfile}

pub fn meal_macros_test() {
  let recipe =
    Recipe(
      id: "chicken",
      name: "Chicken",
      ingredients: [types.Ingredient(name: "Chicken", quantity: "200g")],
      instructions: ["Cook"],
      macros: Macros(protein: 40.0, fat: 10.0, carbs: 5.0),
      servings: 1,
      category: "protein",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  let meal = Meal(recipe: recipe, portion_size: 2.0)
  let macros = meal_macros(meal)
  macros.protein |> should.equal(80.0)
  macros.fat |> should.equal(20.0)
  macros.carbs |> should.equal(10.0)
}

pub fn meal_macros_fractional_portion_test() {
  let recipe =
    Recipe(
      id: "rice",
      name: "Rice",
      ingredients: [types.Ingredient(name: "Rice", quantity: "100g")],
      instructions: ["Boil"],
      macros: Macros(protein: 4.0, fat: 0.5, carbs: 28.0),
      servings: 1,
      category: "carbs",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  let meal = Meal(recipe: recipe, portion_size: 0.5)
  let macros = meal_macros(meal)
  macros.protein |> should.equal(2.0)
  macros.fat |> should.equal(0.25)
  macros.carbs |> should.equal(14.0)
}

pub fn daily_plan_creation_test() {
  let recipe =
    Recipe(
      id: "eggs",
      name: "Eggs",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 12.0, fat: 10.0, carbs: 1.0),
      servings: 1,
      category: "protein",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  let meal = Meal(recipe: recipe, portion_size: 1.0)
  let plan = DailyPlan(day_name: "Monday", meals: [meal])
  plan.day_name |> should.equal("Monday")
}

pub fn daily_plan_macros_single_meal_test() {
  let recipe =
    Recipe(
      id: "steak",
      name: "Steak",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 50.0, fat: 20.0, carbs: 0.0),
      servings: 1,
      category: "beef",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  let meal = Meal(recipe: recipe, portion_size: 1.0)
  let plan = DailyPlan(day_name: "Tuesday", meals: [meal])
  let macros = daily_plan_macros(plan)
  macros.protein |> should.equal(50.0)
  macros.fat |> should.equal(20.0)
  macros.carbs |> should.equal(0.0)
}

pub fn daily_plan_macros_multiple_meals_test() {
  let breakfast =
    Meal(
      recipe: Recipe(
        id: "eggs-breakfast",
        name: "Eggs",
        ingredients: [],
        instructions: [],
        macros: Macros(protein: 24.0, fat: 18.0, carbs: 2.0),
        servings: 1,
        category: "protein",
        fodmap_level: Low,
        vertical_compliant: True,
      ),
      portion_size: 1.0,
    )
  let lunch =
    Meal(
      recipe: Recipe(
        id: "chicken-rice",
        name: "Chicken Rice",
        ingredients: [],
        instructions: [],
        macros: Macros(protein: 40.0, fat: 12.0, carbs: 45.0),
        servings: 1,
        category: "chicken",
        fodmap_level: Low,
        vertical_compliant: True,
      ),
      portion_size: 1.0,
    )
  let dinner =
    Meal(
      recipe: Recipe(
        id: "beef-rice",
        name: "Beef Rice",
        ingredients: [],
        instructions: [],
        macros: Macros(protein: 50.0, fat: 25.0, carbs: 50.0),
        servings: 1,
        category: "beef",
        fodmap_level: Low,
        vertical_compliant: True,
      ),
      portion_size: 1.0,
    )
  let plan = DailyPlan(day_name: "Wednesday", meals: [breakfast, lunch, dinner])
  let macros = daily_plan_macros(plan)
  // 24 + 40 + 50 = 114 protein
  macros.protein |> should.equal(114.0)
  // 18 + 12 + 25 = 55 fat
  macros.fat |> should.equal(55.0)
  // 2 + 45 + 50 = 97 carbs
  macros.carbs |> should.equal(97.0)
}

pub fn daily_plan_macros_empty_meals_test() {
  let plan = DailyPlan(day_name: "Thursday", meals: [])
  let macros = daily_plan_macros(plan)
  macros.protein |> should.equal(0.0)
  macros.fat |> should.equal(0.0)
  macros.carbs |> should.equal(0.0)
}

pub fn weekly_plan_macros_test() {
  let profile =
    UserProfile(
      bodyweight: 176.0,
      activity_level: Active,
      goal: Maintain,
      meals_per_day: 3,
    )
  let meal =
    Meal(
      recipe: Recipe(
        id: "standard-meal",
        name: "Standard Meal",
        ingredients: [],
        instructions: [],
        macros: Macros(protein: 30.0, fat: 15.0, carbs: 40.0),
        servings: 1,
        category: "mixed",
        fodmap_level: Low,
        vertical_compliant: True,
      ),
      portion_size: 1.0,
    )
  // 3 meals per day, 2 days
  let day1 = DailyPlan(day_name: "Monday", meals: [meal, meal, meal])
  let day2 = DailyPlan(day_name: "Tuesday", meals: [meal, meal, meal])
  let plan =
    WeeklyMealPlan(days: [day1, day2], shopping_list: [], user_profile: profile)
  let macros = weekly_plan_macros(plan)
  // 6 meals total, 30 protein each = 180
  macros.protein |> should.equal(180.0)
  // 6 meals total, 15 fat each = 90
  macros.fat |> should.equal(90.0)
  // 6 meals total, 40 carbs each = 240
  macros.carbs |> should.equal(240.0)
}

pub fn weekly_plan_avg_daily_macros_test() {
  let profile =
    UserProfile(
      bodyweight: 176.0,
      activity_level: Active,
      goal: Maintain,
      meals_per_day: 3,
    )
  let meal =
    Meal(
      recipe: Recipe(
        id: "standard-meal-2",
        name: "Standard Meal",
        ingredients: [],
        instructions: [],
        macros: Macros(protein: 30.0, fat: 15.0, carbs: 40.0),
        servings: 1,
        category: "mixed",
        fodmap_level: Low,
        vertical_compliant: True,
      ),
      portion_size: 1.0,
    )
  // 3 meals per day for 2 days
  let day1 = DailyPlan(day_name: "Monday", meals: [meal, meal, meal])
  let day2 = DailyPlan(day_name: "Tuesday", meals: [meal, meal, meal])
  let plan =
    WeeklyMealPlan(days: [day1, day2], shopping_list: [], user_profile: profile)
  let avg = weekly_plan_avg_daily_macros(plan)
  // Total: 180 protein / 2 days = 90 per day
  avg.protein |> should.equal(90.0)
  // Total: 90 fat / 2 days = 45 per day
  avg.fat |> should.equal(45.0)
  // Total: 240 carbs / 2 days = 120 per day
  avg.carbs |> should.equal(120.0)
}

pub fn weekly_plan_empty_days_test() {
  let profile =
    UserProfile(
      bodyweight: 154.0,
      activity_level: Active,
      goal: Maintain,
      meals_per_day: 3,
    )
  let plan = WeeklyMealPlan(days: [], shopping_list: [], user_profile: profile)
  let macros = weekly_plan_macros(plan)
  macros.protein |> should.equal(0.0)
  let avg = weekly_plan_avg_daily_macros(plan)
  avg.protein |> should.equal(0.0)
}

// ============================================================================
// default_recipe tests
// ============================================================================

pub fn default_recipe_returns_empty_recipe_test() {
  let recipe = default_recipe()
  recipe.id |> should.equal("")
  recipe.name |> should.equal("")
  recipe.ingredients |> should.equal([])
  recipe.instructions |> should.equal([])
  recipe.servings |> should.equal(1)
  recipe.macros.protein |> should.equal(0.0)
  recipe.macros.fat |> should.equal(0.0)
  recipe.macros.carbs |> should.equal(0.0)
  recipe.vertical_compliant |> should.be_false()
}

pub fn default_recipe_fodmap_is_low_test() {
  let recipe = default_recipe()
  recipe.fodmap_level |> should.equal(Low)
}

// ============================================================================
// generate_weekly_plan tests
// ============================================================================

pub fn generate_weekly_plan_returns_seven_days_test() {
  let profile =
    UserProfile(
      bodyweight: 180.0,
      activity_level: Active,
      goal: Maintain,
      meals_per_day: 3,
    )
  let recipe =
    Recipe(
      id: "test-recipe",
      name: "Test Recipe",
      ingredients: [types.Ingredient(name: "Chicken", quantity: "8 oz")],
      instructions: ["Cook chicken"],
      macros: Macros(protein: 50.0, fat: 15.0, carbs: 20.0),
      servings: 1,
      category: "chicken",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let result = generate_weekly_plan(profile, [recipe])
  result |> should.be_ok()

  case result {
    Ok(plan) -> {
      list.length(plan.days) |> should.equal(7)
    }
    Error(_) -> should.fail()
  }
}

pub fn generate_weekly_plan_has_correct_day_names_test() {
  let profile =
    UserProfile(
      bodyweight: 180.0,
      activity_level: Active,
      goal: Maintain,
      meals_per_day: 3,
    )
  let recipe =
    Recipe(
      id: "test-recipe",
      name: "Test Recipe",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
      servings: 1,
      category: "test",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let result = generate_weekly_plan(profile, [recipe])
  case result {
    Ok(plan) -> {
      let day_names = list.map(plan.days, fn(d) { d.day_name })
      list.contains(day_names, "Monday") |> should.be_true()
      list.contains(day_names, "Tuesday") |> should.be_true()
      list.contains(day_names, "Wednesday") |> should.be_true()
      list.contains(day_names, "Thursday") |> should.be_true()
      list.contains(day_names, "Friday") |> should.be_true()
      list.contains(day_names, "Saturday") |> should.be_true()
      list.contains(day_names, "Sunday") |> should.be_true()
    }
    Error(_) -> should.fail()
  }
}

pub fn generate_weekly_plan_with_empty_recipes_test() {
  let profile =
    UserProfile(
      bodyweight: 180.0,
      activity_level: Active,
      goal: Maintain,
      meals_per_day: 3,
    )

  let result = generate_weekly_plan(profile, [])
  result |> should.be_ok()

  case result {
    Ok(plan) -> {
      // Even with no recipes, should create 7 days with default recipe
      list.length(plan.days) |> should.equal(7)
    }
    Error(_) -> should.fail()
  }
}

pub fn generate_weekly_plan_preserves_user_profile_test() {
  let profile =
    UserProfile(
      bodyweight: 200.0,
      activity_level: Active,
      goal: types.Gain,
      meals_per_day: 4,
    )
  let recipe =
    Recipe(
      id: "test",
      name: "Test",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
      servings: 1,
      category: "test",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let result = generate_weekly_plan(profile, [recipe])
  case result {
    Ok(plan) -> {
      plan.user_profile.bodyweight |> should.equal(200.0)
      plan.user_profile.meals_per_day |> should.equal(4)
    }
    Error(_) -> should.fail()
  }
}

pub fn generate_weekly_plan_each_day_has_meal_test() {
  let profile =
    UserProfile(
      bodyweight: 180.0,
      activity_level: Active,
      goal: Maintain,
      meals_per_day: 3,
    )
  let recipe =
    Recipe(
      id: "test-recipe",
      name: "Test Recipe",
      ingredients: [types.Ingredient(name: "Beef", quantity: "6 oz")],
      instructions: ["Grill"],
      macros: Macros(protein: 45.0, fat: 20.0, carbs: 0.0),
      servings: 1,
      category: "beef",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let result = generate_weekly_plan(profile, [recipe])
  case result {
    Ok(plan) -> {
      // Each day should have at least one meal
      list.all(plan.days, fn(day) { day.meals != [] })
      |> should.be_true()
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Edge case tests for meal_macros
// ============================================================================

pub fn meal_macros_zero_portion_test() {
  let recipe =
    Recipe(
      id: "test",
      name: "Test",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
      servings: 1,
      category: "test",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  let meal = Meal(recipe: recipe, portion_size: 0.0)
  let macros = meal_macros(meal)
  macros.protein |> should.equal(0.0)
  macros.fat |> should.equal(0.0)
  macros.carbs |> should.equal(0.0)
}

pub fn meal_macros_large_portion_test() {
  let recipe =
    Recipe(
      id: "test",
      name: "Test",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 10.0, fat: 5.0, carbs: 20.0),
      servings: 1,
      category: "test",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  let meal = Meal(recipe: recipe, portion_size: 10.0)
  let macros = meal_macros(meal)
  macros.protein |> should.equal(100.0)
  macros.fat |> should.equal(50.0)
  macros.carbs |> should.equal(200.0)
}
