import gleeunit/should
import meal_planner/meal_plan.{
  DailyPlan, Meal, WeeklyMealPlan, daily_plan_macros, meal_macros,
  weekly_plan_avg_daily_macros, weekly_plan_macros,
}
import meal_planner/types.{
  Active, Ingredient, Low, Macros, Maintain, Recipe, UserProfile,
}

pub fn meal_macros_test() {
  let recipe =
    Recipe(
      name: "Chicken",
      ingredients: [Ingredient(name: "Chicken", quantity: "200g")],
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
      name: "Rice",
      ingredients: [Ingredient(name: "Rice", quantity: "100g")],
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
  let plan = WeeklyMealPlan(days: [day1, day2], shopping_list: [], user_profile: profile)
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
  let plan = WeeklyMealPlan(days: [day1, day2], shopping_list: [], user_profile: profile)
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
