//// Tests for meal_planner/types/meal_plan module
////
//// Tests core types and operations for meal planning:
//// - DailyMacros creation and accessors
//// - DayMeals validation and meal access
//// - MealPlan validation and weekly totals

import gleeunit
import gleeunit/should
import meal_planner/types/macros.{Macros}
import meal_planner/types/meal_plan.{
  DailyMacros, DayMeals, MealPlan, daily_macros_actual, daily_macros_calories,
  day_meals_day, meal_plan_avg_daily_macros, meal_plan_target_macros,
  meal_plan_week_of, new_daily_macros, new_day_meals, new_meal_plan,
}
import meal_planner/types/recipe.{MealPlanRecipe}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// DailyMacros Tests
// ============================================================================

pub fn test_new_daily_macros_creates_instance() {
  let actual = Macros(protein: 100.0, fat: 50.0, carbs: 150.0)
  let target = Macros(protein: 150.0, fat: 60.0, carbs: 200.0)

  let result = new_daily_macros(actual, target)

  result
  |> should.be_ok()
}

pub fn test_daily_macros_actual_accessor() {
  let actual = Macros(protein: 100.0, fat: 50.0, carbs: 150.0)
  let target = Macros(protein: 150.0, fat: 60.0, carbs: 200.0)

  let result = new_daily_macros(actual, target)
  case result {
    Ok(dm) -> {
      let retrieved = daily_macros_actual(dm)
      retrieved.protein |> should.equal(100.0)
      retrieved.fat |> should.equal(50.0)
      retrieved.carbs |> should.equal(150.0)
    }
    Error(_) -> should.fail()
  }
}

pub fn test_daily_macros_calories() {
  let actual = Macros(protein: 100.0, fat: 50.0, carbs: 150.0)
  let target = Macros(protein: 150.0, fat: 60.0, carbs: 200.0)

  let result = new_daily_macros(actual, target)
  case result {
    Ok(dm) -> {
      let calories = daily_macros_calories(dm)
      // Calories = protein*4 + fat*9 + carbs*4 = 400 + 450 + 600 = 1450
      calories |> should.equal(1450.0)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// DayMeals Tests
// ============================================================================

pub fn test_new_day_meals_requires_valid_day() {
  let breakfast = MealPlanRecipe(name: "Eggs", macros: Macros(50.0, 20.0, 30.0))
  let lunch = MealPlanRecipe(name: "Chicken", macros: Macros(40.0, 15.0, 35.0))
  let dinner = MealPlanRecipe(name: "Steak", macros: Macros(60.0, 25.0, 40.0))
  let target = Macros(protein: 150.0, fat: 60.0, carbs: 200.0)

  let result =
    new_day_meals(
      day: "Monday",
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      target_macros: target,
    )

  result |> should.be_ok()
}

pub fn test_day_meals_day_accessor() {
  let breakfast = MealPlanRecipe(name: "Eggs", macros: Macros(50.0, 20.0, 30.0))
  let lunch = MealPlanRecipe(name: "Chicken", macros: Macros(40.0, 15.0, 35.0))
  let dinner = MealPlanRecipe(name: "Steak", macros: Macros(60.0, 25.0, 40.0))
  let target = Macros(protein: 150.0, fat: 60.0, carbs: 200.0)

  let result =
    new_day_meals(
      day: "Tuesday",
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      target_macros: target,
    )

  case result {
    Ok(dm) -> {
      day_meals_day(dm) |> should.equal("Tuesday")
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// MealPlan Tests
// ============================================================================

pub fn test_new_meal_plan_requires_exactly_seven_days() {
  let breakfast = MealPlanRecipe(name: "Eggs", macros: Macros(50.0, 20.0, 30.0))
  let lunch = MealPlanRecipe(name: "Chicken", macros: Macros(40.0, 15.0, 35.0))
  let dinner = MealPlanRecipe(name: "Steak", macros: Macros(60.0, 25.0, 40.0))
  let target = Macros(protein: 150.0, fat: 60.0, carbs: 200.0)

  let day_result =
    new_day_meals(
      day: "Monday",
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      target_macros: target,
    )

  case day_result {
    Ok(day) -> {
      let seven_days = [day, day, day, day, day, day, day]
      let plan_result =
        new_meal_plan(
          week_of: "2025-01-06",
          days: seven_days,
          target_macros: target,
        )
      plan_result |> should.be_ok()
    }
    Error(_) -> should.fail()
  }
}

pub fn test_new_meal_plan_rejects_wrong_day_count() {
  let breakfast = MealPlanRecipe(name: "Eggs", macros: Macros(50.0, 20.0, 30.0))
  let lunch = MealPlanRecipe(name: "Chicken", macros: Macros(40.0, 15.0, 35.0))
  let dinner = MealPlanRecipe(name: "Steak", macros: Macros(60.0, 25.0, 40.0))
  let target = Macros(protein: 150.0, fat: 60.0, carbs: 200.0)

  let day_result =
    new_day_meals(
      day: "Monday",
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      target_macros: target,
    )

  case day_result {
    Ok(day) -> {
      let six_days = [day, day, day, day, day, day]
      let plan_result =
        new_meal_plan(
          week_of: "2025-01-06",
          days: six_days,
          target_macros: target,
        )
      plan_result |> should.be_error()
    }
    Error(_) -> should.fail()
  }
}

pub fn test_meal_plan_week_of_accessor() {
  let breakfast = MealPlanRecipe(name: "Eggs", macros: Macros(50.0, 20.0, 30.0))
  let lunch = MealPlanRecipe(name: "Chicken", macros: Macros(40.0, 15.0, 35.0))
  let dinner = MealPlanRecipe(name: "Steak", macros: Macros(60.0, 25.0, 40.0))
  let target = Macros(protein: 150.0, fat: 60.0, carbs: 200.0)

  let day_result =
    new_day_meals(
      day: "Monday",
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      target_macros: target,
    )

  case day_result {
    Ok(day) -> {
      let seven_days = [day, day, day, day, day, day, day]
      let plan_result =
        new_meal_plan(
          week_of: "2025-01-06",
          days: seven_days,
          target_macros: target,
        )

      case plan_result {
        Ok(plan) -> {
          meal_plan_week_of(plan) |> should.equal("2025-01-06")
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn test_meal_plan_target_macros_accessor() {
  let breakfast = MealPlanRecipe(name: "Eggs", macros: Macros(50.0, 20.0, 30.0))
  let lunch = MealPlanRecipe(name: "Chicken", macros: Macros(40.0, 15.0, 35.0))
  let dinner = MealPlanRecipe(name: "Steak", macros: Macros(60.0, 25.0, 40.0))
  let target = Macros(protein: 150.0, fat: 60.0, carbs: 200.0)

  let day_result =
    new_day_meals(
      day: "Monday",
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      target_macros: target,
    )

  case day_result {
    Ok(day) -> {
      let seven_days = [day, day, day, day, day, day, day]
      let plan_result =
        new_meal_plan(
          week_of: "2025-01-06",
          days: seven_days,
          target_macros: target,
        )

      case plan_result {
        Ok(plan) -> {
          let retrieved = meal_plan_target_macros(plan)
          retrieved.protein |> should.equal(150.0)
          retrieved.fat |> should.equal(60.0)
          retrieved.carbs |> should.equal(200.0)
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn test_meal_plan_avg_daily_macros() {
  let breakfast = MealPlanRecipe(name: "Eggs", macros: Macros(50.0, 20.0, 30.0))
  let lunch = MealPlanRecipe(name: "Chicken", macros: Macros(40.0, 15.0, 35.0))
  let dinner = MealPlanRecipe(name: "Steak", macros: Macros(60.0, 25.0, 40.0))
  let target = Macros(protein: 150.0, fat: 60.0, carbs: 200.0)

  let day_result =
    new_day_meals(
      day: "Monday",
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      target_macros: target,
    )

  case day_result {
    Ok(day) -> {
      let seven_days = [day, day, day, day, day, day, day]
      let plan_result =
        new_meal_plan(
          week_of: "2025-01-06",
          days: seven_days,
          target_macros: target,
        )

      case plan_result {
        Ok(plan) -> {
          let avg = meal_plan_avg_daily_macros(plan)
          // Daily total = 50+40+60=150 protein, 20+15+25=60 fat, 30+35+40=105 carbs
          // Weekly = 150*7=1050, 60*7=420, 105*7=735
          // Average = 1050/7=150, 420/7=60, 735/7=105
          avg.protein |> should.equal(150.0)
          avg.fat |> should.equal(60.0)
          avg.carbs |> should.equal(105.0)
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}
