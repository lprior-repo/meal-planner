import gleeunit/should
import meal_planner/ncp.{
  DeviationResult, NutritionData, NutritionGoals,
  calculate_deviation, deviation_is_within_tolerance,
  deviation_max, nutrition_goals_validate,
}

pub fn nutrition_goals_validate_valid_test() {
  let goals =
    NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )
  nutrition_goals_validate(goals) |> should.be_ok()
}

pub fn nutrition_goals_validate_zero_protein_test() {
  let goals =
    NutritionGoals(
      daily_protein: 0.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )
  nutrition_goals_validate(goals) |> should.be_error()
}

pub fn nutrition_goals_validate_negative_fat_test() {
  let goals =
    NutritionGoals(
      daily_protein: 180.0,
      daily_fat: -10.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )
  nutrition_goals_validate(goals) |> should.be_error()
}

pub fn calculate_deviation_over_test() {
  let goals =
    NutritionGoals(
      daily_protein: 100.0,
      daily_fat: 50.0,
      daily_carbs: 200.0,
      daily_calories: 2000.0,
    )
  let actual =
    NutritionData(protein: 120.0, fat: 60.0, carbs: 220.0, calories: 2200.0)
  let dev = calculate_deviation(goals, actual)
  // (120-100)/100*100 = 20%
  dev.protein_pct |> should.equal(20.0)
  // (60-50)/50*100 = 20%
  dev.fat_pct |> should.equal(20.0)
  // (220-200)/200*100 = 10%
  dev.carbs_pct |> should.equal(10.0)
  // (2200-2000)/2000*100 = 10%
  dev.calories_pct |> should.equal(10.0)
}

pub fn calculate_deviation_under_test() {
  let goals =
    NutritionGoals(
      daily_protein: 100.0,
      daily_fat: 50.0,
      daily_carbs: 200.0,
      daily_calories: 2000.0,
    )
  let actual =
    NutritionData(protein: 80.0, fat: 40.0, carbs: 180.0, calories: 1800.0)
  let dev = calculate_deviation(goals, actual)
  // (80-100)/100*100 = -20%
  dev.protein_pct |> should.equal(-20.0)
  dev.fat_pct |> should.equal(-20.0)
  dev.carbs_pct |> should.equal(-10.0)
  dev.calories_pct |> should.equal(-10.0)
}

pub fn deviation_is_within_tolerance_true_test() {
  let dev =
    DeviationResult(
      protein_pct: 5.0,
      fat_pct: -3.0,
      carbs_pct: 8.0,
      calories_pct: 4.0,
    )
  deviation_is_within_tolerance(dev, 10.0) |> should.be_true()
}

pub fn deviation_is_within_tolerance_false_test() {
  let dev =
    DeviationResult(
      protein_pct: 15.0,
      fat_pct: -3.0,
      carbs_pct: 8.0,
      calories_pct: 4.0,
    )
  deviation_is_within_tolerance(dev, 10.0) |> should.be_false()
}

pub fn deviation_max_test() {
  let dev =
    DeviationResult(
      protein_pct: -25.0,
      fat_pct: 10.0,
      carbs_pct: 15.0,
      calories_pct: 5.0,
    )
  // abs(-25) = 25 is max
  deviation_max(dev) |> should.equal(25.0)
}
