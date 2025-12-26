/// Shared utility functions for macro calculations
///
/// This module consolidates duplicate macro calculation logic that was previously
/// scattered across storage/logs/queries.gleam and storage/logs/summaries.gleam
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import meal_planner/types/food.{type FoodLogEntry}
import meal_planner/types/macros.{type Macros, Macros}

/// Calculate total macros from food log entries
pub fn calculate_total_macros(entries: List(FoodLogEntry)) -> Macros {
  list.fold(entries, Macros(protein: 0.0, fat: 0.0, carbs: 0.0), fn(acc, entry) {
    Macros(
      protein: acc.protein +. entry.macros.protein,
      fat: acc.fat +. entry.macros.fat,
      carbs: acc.carbs +. entry.macros.carbs,
    )
  })
}

/// Calculate macros summary from a list of macros
pub fn sum_macros(macros_list: List(Macros)) -> Macros {
  list.fold(
    macros_list,
    Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
    fn(acc, macros) {
      Macros(
        protein: acc.protein +. macros.protein,
        fat: acc.fat +. macros.fat,
        carbs: acc.carbs +. macros.carbs,
      )
    },
  )
}

/// Calculate average macros from a list
pub fn average_macros(macros_list: List(Macros)) -> Option(Macros) {
  case list.length(macros_list) {
    0 -> None
    count -> {
      let total = sum_macros(macros_list)
      let count_float = int.to_float(count)
      Some(Macros(
        protein: total.protein /. count_float,
        fat: total.fat /. count_float,
        carbs: total.carbs /. count_float,
      ))
    }
  }
}
