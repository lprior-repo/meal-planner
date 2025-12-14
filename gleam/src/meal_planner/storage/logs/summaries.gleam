/// Weekly nutrition summary aggregation
///
/// This module handles aggregated data and summaries:
/// - Weekly summaries
/// - Calculating total macros and micronutrients
///
/// Separated from entry-level operations and complex queries to allow focused testing
/// and maintenance of aggregation logic.
import gleam/dynamic/decode
import gleam/list
import gleam/option.{type Option, None, Some}
import meal_planner/storage/profile.{type StorageError, DatabaseError}
import meal_planner/storage/utils
import meal_planner/types.{type Macros}
import meal_planner/utils/macros as macros_utils
import meal_planner/utils/micronutrients as utils_micro
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
// Re-exported Macro Calculations (for backward compatibility)
// ============================================================================

/// Calculate total macros from food log entries
/// Re-exported from utils/macros module
pub fn calculate_total_macros(entries: List(types.FoodLogEntry)) -> Macros {
  macros_utils.calculate_total_macros(entries)
}

/// Calculate total micronutrients from food log entries
/// Re-exported from utils/micronutrients module
pub fn calculate_total_micronutrients(
  entries: List(types.FoodLogEntry),
) -> Option(types.Micronutrients) {
  utils_micro.calculate_total_micronutrients(entries)
}

/// Calculate macros summary from a list of macros
/// Re-exported from utils/macros module
pub fn sum_macros(macros_list: List(Macros)) -> Macros {
  macros_utils.sum_macros(macros_list)
}

/// Calculate average macros from a list
/// Re-exported from utils/macros module
pub fn average_macros(macros_list: List(Macros)) -> Option(Macros) {
  macros_utils.average_macros(macros_list)
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
