/// Weekly nutrition summary aggregation
///
/// This module handles aggregated data and summaries:
/// - Weekly summaries
/// - Calculating total macros and micronutrients
///
/// Separated from entry-level operations and complex queries to allow focused testing
/// and maintenance of aggregation logic.

import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import meal_planner/storage/profile.{type StorageError, DatabaseError}
import meal_planner/storage/utils
import meal_planner/types.{type FoodLogEntry, type Macros, Macros}
import pog

// ============================================================================
// Food Summary Types
// ============================================================================

/// Food summary item for weekly aggregation
pub type FoodSummaryItem {
  FoodSummaryItem(
    food_id: Int,
    food_name: String,
    log_count: Int,
    avg_protein: Float,
    avg_fat: Float,
    avg_carbs: Float,
  )
}

/// Weekly summary of nutrition data
pub type WeeklySummary {
  WeeklySummary(
    total_logs: Int,
    avg_protein: Float,
    avg_fat: Float,
    avg_carbs: Float,
    by_food: List(FoodSummaryItem),
  )
}

// ============================================================================
// Macro Calculations
// ============================================================================

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

/// Calculate total micronutrients from food log entries
pub fn calculate_total_micronutrients(
  entries: List(FoodLogEntry),
) -> Option(types.Micronutrients) {
  let micros_list =
    list.filter_map(entries, fn(entry) {
      case entry.micronutrients {
        Some(m) -> Ok(m)
        None -> Error(Nil)
      }
    })

  case micros_list {
    [] -> None
    _ -> Some(types.micronutrients_sum(micros_list))
  }
}

/// Calculate macros summary from a list of macros
pub fn sum_macros(macros_list: List(Macros)) -> Macros {
  list.fold(macros_list, Macros(protein: 0.0, fat: 0.0, carbs: 0.0), fn(
    acc,
    macros,
  ) {
    Macros(
      protein: acc.protein +. macros.protein,
      fat: acc.fat +. macros.fat,
      carbs: acc.carbs +. macros.carbs,
    )
  })
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

// ============================================================================
// Weekly Summary Queries
// ============================================================================

/// Get weekly summary of nutrition data aggregated by food
/// Calculates totals and averages for logs within 7 days starting from start_date
pub fn get_weekly_summary(
  conn: pog.Connection,
  user_id: Int,
  start_date: String,
) -> Result(WeeklySummary, StorageError) {
  let sql =
    "WITH weekly_logs AS (
       SELECT
         l.id,
         l.food_id,
         f.description as food_name,
         l.macros->>'protein' as protein_str,
         l.macros->>'fat' as fat_str,
         l.macros->>'carbs' as carbs_str,
         l.log_date
       FROM logs l
       JOIN foods f ON l.food_id = f.fdc_id
       WHERE l.user_id = $1
         AND l.log_date >= $2::date
         AND l.log_date < ($2::date + INTERVAL '7 days')
     )
     SELECT
       COALESCE(COUNT(DISTINCT id), 0) as total_logs,
       COALESCE(AVG(CAST(protein_str AS FLOAT)), 0.0) as avg_protein,
       COALESCE(AVG(CAST(fat_str AS FLOAT)), 0.0) as avg_fat,
       COALESCE(AVG(CAST(carbs_str AS FLOAT)), 0.0) as avg_carbs,
       food_id,
       food_name,
       COUNT(DISTINCT id) as log_count,
       COALESCE(AVG(CAST(protein_str AS FLOAT)), 0.0) as food_avg_protein,
       COALESCE(AVG(CAST(fat_str AS FLOAT)), 0.0) as food_avg_fat,
       COALESCE(AVG(CAST(carbs_str AS FLOAT)), 0.0) as food_avg_carbs
     FROM weekly_logs
     GROUP BY ROLLUP(food_id, food_name)
     ORDER BY food_id DESC NULLS FIRST"

  let summary_decoder = {
    use total_logs <- decode.field(0, decode.int)
    use avg_protein <- decode.field(1, decode.float)
    use avg_fat <- decode.field(2, decode.float)
    use avg_carbs <- decode.field(3, decode.float)
    use food_id <- decode.field(4, decode.optional(decode.int))
    use food_name <- decode.field(5, decode.optional(decode.string))
    use log_count <- decode.field(6, decode.optional(decode.int))
    use food_avg_protein <- decode.field(7, decode.float)
    use food_avg_fat <- decode.field(8, decode.float)
    use food_avg_carbs <- decode.field(9, decode.float)

    decode.success(#(
      total_logs,
      avg_protein,
      avg_fat,
      avg_carbs,
      food_id,
      food_name,
      log_count,
      food_avg_protein,
      food_avg_fat,
      food_avg_carbs,
    ))
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.int(user_id))
    |> pog.parameter(pog.text(start_date))
    |> pog.returning(summary_decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))

    Ok(pog.Returned(_, rows)) -> {
      case rows {
        [] ->
          Ok(
            WeeklySummary(
              total_logs: 0,
              avg_protein: 0.0,
              avg_fat: 0.0,
              avg_carbs: 0.0,
              by_food: [],
            ),
          )

        [first, ..] -> {
          let #(total_logs, avg_protein, avg_fat, avg_carbs, _, _, _, _, _, _) =
            first

          let food_items =
            list.filter_map(rows, fn(row) {
              let #(
                _,
                _,
                _,
                _,
                food_id,
                food_name,
                log_count,
                food_avg_protein,
                food_avg_fat,
                food_avg_carbs,
              ) = row

              case food_id, food_name, log_count {
                Some(fid), Some(fname), Some(count) ->
                  Ok(FoodSummaryItem(
                    food_id: fid,
                    food_name: fname,
                    log_count: count,
                    avg_protein: food_avg_protein,
                    avg_fat: food_avg_fat,
                    avg_carbs: food_avg_carbs,
                  ))

                _, _, _ -> Error(Nil)
              }
            })

          Ok(WeeklySummary(
            total_logs: total_logs,
            avg_protein: avg_protein,
            avg_fat: avg_fat,
            avg_carbs: avg_carbs,
            by_food: food_items,
          ))
        }
      }
    }
  }
}
