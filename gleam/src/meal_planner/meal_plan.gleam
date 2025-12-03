/// Meal planning types for daily and weekly plans
import shared/types.{
  type Ingredient, type Macros, type Recipe, type UserProfile, Low, Macros,
  Recipe, macros_scale,
}

/// Meal represents a recipe with a portion size multiplier
pub type Meal {
  Meal(recipe: Recipe, portion_size: Float)
}

/// Calculate macros for a meal adjusted by portion size
pub fn meal_macros(m: Meal) -> Macros {
  macros_scale(m.recipe.macros, m.portion_size)
}

/// DailyPlan represents all meals for a single day
pub type DailyPlan {
  DailyPlan(day_name: String, meals: List(Meal))
}

/// Create a default empty recipe
pub fn default_recipe() -> Recipe {
  Recipe(
    id: "",
    name: "",
    ingredients: [],
    instructions: [],
    macros: Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
    servings: 1,
    category: "",
    fodmap_level: Low,
    vertical_compliant: False,
  )
}

/// Calculate total macros for a daily plan
pub fn daily_plan_macros(plan: DailyPlan) -> Macros {
  list_fold(
    plan.meals,
    Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
    fn(acc, meal) {
      let m = meal_macros(meal)
      Macros(
        protein: acc.protein +. m.protein,
        fat: acc.fat +. m.fat,
        carbs: acc.carbs +. m.carbs,
      )
    },
  )
}

fn list_fold(list: List(a), acc: b, f: fn(b, a) -> b) -> b {
  case list {
    [] -> acc
    [first, ..rest] -> list_fold(rest, f(acc, first), f)
  }
}

/// WeeklyMealPlan represents 7 days of meal plans
pub type WeeklyMealPlan {
  WeeklyMealPlan(
    days: List(DailyPlan),
    shopping_list: List(Ingredient),
    user_profile: UserProfile,
  )
}

/// Calculate total macros for the entire week
pub fn weekly_plan_macros(plan: WeeklyMealPlan) -> Macros {
  list_fold(plan.days, Macros(protein: 0.0, fat: 0.0, carbs: 0.0), fn(acc, day) {
    let m = daily_plan_macros(day)
    Macros(
      protein: acc.protein +. m.protein,
      fat: acc.fat +. m.fat,
      carbs: acc.carbs +. m.carbs,
    )
  })
}

/// Calculate average daily macros for the week
pub fn weekly_plan_avg_daily_macros(plan: WeeklyMealPlan) -> Macros {
  let total = weekly_plan_macros(plan)
  let days = int_to_float(list_length(plan.days))
  case days {
    0.0 -> Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
    _ ->
      Macros(
        protein: total.protein /. days,
        fat: total.fat /. days,
        carbs: total.carbs /. days,
      )
  }
}

fn list_length(list: List(a)) -> Int {
  case list {
    [] -> 0
    [_, ..rest] -> 1 + list_length(rest)
  }
}

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float

