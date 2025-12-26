/// Display types for diary CLI domain
///
/// This module contains types used for displaying diary information,
/// separated from the main diary module to improve modularity.
import gleam/list
import meal_planner/fatsecret/diary/types.{type FoodEntry}

/// Day nutrition summary for display
///
/// Accumulates total calories and macronutrients across all entries for a day.
pub type DayNutrition {
  DayNutrition(
    calories: Float,
    protein: Float,
    carbohydrates: Float,
    fat: Float,
  )
}

/// Calculate total nutrition for a list of entries
///
/// Sums calories, protein, carbs, and fat across all entries.
pub fn calculate_day_nutrition(entries: List(FoodEntry)) -> DayNutrition {
  entries
  |> list.fold(
    DayNutrition(calories: 0.0, protein: 0.0, carbohydrates: 0.0, fat: 0.0),
    fn(acc, entry) {
      DayNutrition(
        calories: acc.calories +. entry.calories,
        protein: acc.protein +. entry.protein,
        carbohydrates: acc.carbohydrates +. entry.carbohydrate,
        fat: acc.fat +. entry.fat,
      )
    },
  )
}
