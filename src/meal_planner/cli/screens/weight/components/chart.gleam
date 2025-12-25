/// Weight Chart Component
///
/// Provides ASCII chart rendering for weight data visualization.
///
/// FUNCTIONS:
/// - render_chart: Create ASCII chart from weight data points
import gleam/float
import gleam/int
import gleam/list
import gleam/string
import meal_planner/cli/screens/weight/model.{type ChartPoint}

// ============================================================================
// Public API
// ============================================================================

/// Render ASCII chart from weight data
pub fn render_chart(
  data: List(ChartPoint),
  _width: Int,
  height: Int,
) -> List(String) {
  case data {
    [] -> ["No data to display"]
    _ -> {
      let weights = list.map(data, fn(p) { p.weight })
      let min_w = list.fold(weights, 999.0, fn(acc, w) { float.min(acc, w) })
      let max_w = list.fold(weights, 0.0, fn(acc, w) { float.max(acc, w) })
      let range = max_w -. min_w

      // Build rows
      list.range(0, height - 1)
      |> list.map(fn(row) {
        let y_val =
          max_w -. { int.to_float(row) /. int.to_float(height) *. range }
        let label = float_to_string(y_val) <> " |"
        let row_data =
          data
          |> list.map(fn(point) {
            let normalized = { point.weight -. min_w } /. range
            let point_row =
              height
              - 1
              - float.truncate(normalized *. int.to_float(height - 1))
            case point_row == row {
              True -> "●"
              False -> " "
            }
          })
          |> string.join("")
        string.pad_start(label, 10, " ") <> row_data
      })
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Format float to string with 1 decimal
fn float_to_string(value: Float) -> String {
  let rounded = float.truncate(value *. 10.0) |> int.to_float
  float.to_string(rounded /. 10.0)
}
