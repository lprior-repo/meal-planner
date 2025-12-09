import gleam/list
import gleam/option.{None}
import gleeunit/should
import meal_planner/types.{
  type Recipe, type UserProfile, Active, Gain, Ingredient, Low, Macros, Maintain,
  Moderate, Recipe, UserProfile,
}
import meal_planner/weekly_plan.{day_names, generate_weekly_plan}

// Helper to create compliant test recipes
fn make_compliant_recipes() -> List(Recipe) {
  [
    Recipe(
      id: "beef-steak",
      name: "Beef Steak",
      ingredients: [
        Ingredient(name: "Ribeye steak", quantity: "12 oz"),
        Ingredient(name: "Salt", quantity: "1 tsp"),
      ],
      instructions: ["Season", "Grill"],
      macros: Macros(protein: 50.0, fat: 30.0, carbs: 0.0),
      servings: 1,
      category: "beef",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
    Recipe(
      id: "ground-beef-bowl",
      name: "Ground Beef Bowl",
      ingredients: [
        Ingredient(name: "Ground beef", quantity: "1 lb"),
        Ingredient(name: "White rice", quantity: "1 cup"),
      ],
      instructions: ["Cook beef", "Add rice"],
      macros: Macros(protein: 40.0, fat: 25.0, carbs: 45.0),
      servings: 1,
      category: "beef",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
    Recipe(
      id: "salmon-fillet",
      name: "Salmon Fillet",
      ingredients: [Ingredient(name: "Salmon", quantity: "8 oz")],
      instructions: ["Bake salmon"],
      macros: Macros(protein: 45.0, fat: 20.0, carbs: 0.0),
      servings: 1,
      category: "fish",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
    Recipe(
      id: "scrambled-eggs",
      name: "Scrambled Eggs",
      ingredients: [
        Ingredient(name: "Eggs", quantity: "4"),
        Ingredient(name: "Butter", quantity: "1 tbsp"),
      ],
      instructions: ["Scramble eggs"],
      macros: Macros(protein: 24.0, fat: 20.0, carbs: 2.0),
      servings: 1,
      category: "breakfast",
      fodmap_level: Low,
      vertical_compliant: True,
    ),
  ]
}

fn make_test_profile() -> UserProfile {
  UserProfile(
    id: "test-user",
    bodyweight: 180.0,
    activity_level: Moderate,
    goal: Gain,
    meals_per_day: 3,
    micronutrient_goals: None,
  )
}

// Test day names
pub fn day_names_returns_seven_days_test() {
  let days = day_names()
  list.length(days) |> should.equal(7)
}

pub fn day_names_starts_monday_test() {
  let days = day_names()
  case days {
    [first, ..] -> first |> should.equal("Monday")
    [] -> should.fail()
  }
}

pub fn day_names_ends_sunday_test() {
  let days = day_names()
  case list.last(days) {
    Ok(last) -> last |> should.equal("Sunday")
    Error(_) -> should.fail()
  }
}

// Test generate_weekly_plan
pub fn generate_weekly_plan_creates_seven_days_test() {
  let profile = make_test_profile()
  let recipes = make_compliant_recipes()

  let plan = generate_weekly_plan(profile, recipes)

  list.length(plan.days) |> should.equal(7)
}

pub fn generate_weekly_plan_includes_user_profile_test() {
  let profile = make_test_profile()
  let recipes = make_compliant_recipes()

  let plan = generate_weekly_plan(profile, recipes)

  plan.user_profile.bodyweight |> should.equal(180.0)
  plan.user_profile.meals_per_day |> should.equal(3)
}

pub fn generate_weekly_plan_assigns_day_names_test() {
  let profile = make_test_profile()
  let recipes = make_compliant_recipes()

  let plan = generate_weekly_plan(profile, recipes)

  case plan.days {
    [first, ..] -> first.day_name |> should.equal("Monday")
    [] -> should.fail()
  }
}

pub fn generate_weekly_plan_creates_meals_per_day_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Gain,
      meals_per_day: 3,
      micronutrient_goals: None,
    )
  let recipes = make_compliant_recipes()

  let plan = generate_weekly_plan(profile, recipes)

  // Each day should have 3 meals
  case plan.days {
    [day, ..] -> list.length(day.meals) |> should.equal(3)
    [] -> should.fail()
  }
}

pub fn generate_weekly_plan_four_meals_per_day_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 200.0,
      activity_level: Active,
      goal: Gain,
      meals_per_day: 4,
      micronutrient_goals: None,
    )
  let recipes = make_compliant_recipes()

  let plan = generate_weekly_plan(profile, recipes)

  case plan.days {
    [day, ..] -> list.length(day.meals) |> should.equal(4)
    [] -> should.fail()
  }
}

pub fn generate_weekly_plan_generates_shopping_list_test() {
  let profile = make_test_profile()
  let recipes = make_compliant_recipes()

  let plan = generate_weekly_plan(profile, recipes)

  // Should have non-empty shopping list
  { plan.shopping_list != [] } |> should.be_true()
}

pub fn generate_weekly_plan_meals_have_portion_sizes_test() {
  let profile = make_test_profile()
  let recipes = make_compliant_recipes()

  let plan = generate_weekly_plan(profile, recipes)

  case plan.days {
    [day, ..] ->
      case day.meals {
        [meal, ..] -> {
          // Portion size should be positive
          { meal.portion_size >. 0.0 } |> should.be_true()
        }
        [] -> should.fail()
      }
    [] -> should.fail()
  }
}

pub fn generate_weekly_plan_empty_recipes_test() {
  let profile = make_test_profile()

  let plan = generate_weekly_plan(profile, [])

  // Should still create 7 days, but with empty meals
  list.length(plan.days) |> should.equal(7)
}

pub fn generate_weekly_plan_no_compliant_recipes_test() {
  let profile = make_test_profile()
  // Non-compliant recipe
  let recipes = [
    Recipe(
      id: "bad-recipe",
      name: "Bad Recipe",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
      servings: 1,
      category: "test",
      fodmap_level: Low,
      vertical_compliant: False,
    ),
  ]

  let plan = generate_weekly_plan(profile, recipes)

  // Should create 7 days even with no compliant recipes
  list.length(plan.days) |> should.equal(7)
}

// Test total meals calculation
pub fn generate_weekly_plan_total_meals_correct_test() {
  let profile =
    UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Maintain,
      meals_per_day: 3,
      micronutrient_goals: None,
    )
  let recipes = make_compliant_recipes()

  let plan = generate_weekly_plan(profile, recipes)

  // Total meals should be 7 days * 3 meals = 21 (or less if not enough recipes)
  let total_meals =
    list.fold(plan.days, 0, fn(acc, day) { acc + list.length(day.meals) })

  // Should have at least some meals
  { total_meals > 0 } |> should.be_true()
}
