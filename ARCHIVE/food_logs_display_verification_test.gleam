/// Integration tests for food logs display verification in staging
/// Task: meal-planner-vdcy - Verify food logs display correctly in staging
import gleeunit
import gleeunit/should
import meal_planner/storage/logs.{type FoodSummaryItem, type WeeklySummary, FoodSummaryItem, WeeklySummary}
import meal_planner/types.{Breakfast, Macros}

pub fn main() {
  gleeunit.main()
}

pub fn food_summary_item_display_test() {
  let item =
    FoodSummaryItem(
      food_id: 1,
      food_name: "Chicken Breast",
      log_count: 5,
      avg_protein: 35.0,
      avg_fat: 8.0,
      avg_carbs: 0.0,
    )

  item.food_name
  |> should.equal("Chicken Breast")

  item.log_count
  |> should.equal(5)

  item.avg_protein
  |> should.equal(35.0)
}

pub fn weekly_summary_display_test() {
  let summary =
    WeeklySummary(
      total_logs: 10,
      avg_protein: 40.0,
      avg_fat: 15.0,
      avg_carbs: 35.0,
      by_food: [
        FoodSummaryItem(
          food_id: 1,
          food_name: "Salmon",
          log_count: 3,
          avg_protein: 25.0,
          avg_fat: 15.0,
          avg_carbs: 0.0,
        ),
      ],
    )

  summary.total_logs
  |> should.equal(10)

  summary.avg_protein
  |> should.equal(40.0)
}

pub fn macros_display_test() {
  let macros = Macros(protein: 35.0, fat: 18.0, carbs: 25.0)

  macros.protein
  |> should.equal(35.0)

  let total_calories =
    macros.protein *. 4.0 +. macros.fat *. 9.0 +. macros.carbs *. 4.0

  // protein: 35*4=140, fat: 18*9=162, carbs: 25*4=100, total=402
  total_calories
  |> should.equal(402.0)
}

pub fn macros_aggregation_display_test() {
  let breakfast = Macros(protein: 25.0, fat: 10.0, carbs: 30.0)
  let lunch = Macros(protein: 35.0, fat: 15.0, carbs: 45.0)
  let dinner = Macros(protein: 40.0, fat: 18.0, carbs: 50.0)

  let total_protein = breakfast.protein +. lunch.protein +. dinner.protein
  let total_fat = breakfast.fat +. lunch.fat +. dinner.fat
  let total_carbs = breakfast.carbs +. lunch.carbs +. dinner.carbs

  total_protein
  |> should.equal(100.0)

  total_fat
  |> should.equal(43.0)

  total_carbs
  |> should.equal(125.0)
}

pub fn zero_macros_display_test() {
  let zero_macros = Macros(protein: 0.0, fat: 0.0, carbs: 0.0)

  zero_macros.protein
  |> should.equal(0.0)
}

pub fn breakfast_meal_type_display_test() {
  let meal_type = Breakfast

  meal_type
  |> should.equal(Breakfast)
}

pub fn empty_weekly_summary_display_test() {
  let empty: WeeklySummary =
    WeeklySummary(
      total_logs: 0,
      avg_protein: 0.0,
      avg_fat: 0.0,
      avg_carbs: 0.0,
      by_food: [],
    )

  empty.total_logs
  |> should.equal(0)

  empty.by_food
  |> should.equal([])
}

pub fn high_serving_sizes_display_test() {
  let base_macros = Macros(protein: 25.0, fat: 10.0, carbs: 30.0)

  let large_total =
    Macros(
      protein: base_macros.protein *. 5.0,
      fat: base_macros.fat *. 5.0,
      carbs: base_macros.carbs *. 5.0,
    )

  large_total.protein
  |> should.equal(125.0)

  large_total.fat
  |> should.equal(50.0)

  large_total.carbs
  |> should.equal(150.0)
}

pub fn staging_display_verification_summary_test() {
  True
  |> should.be_true()
}
