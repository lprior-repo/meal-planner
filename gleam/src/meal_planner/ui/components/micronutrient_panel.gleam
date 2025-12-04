/// Micronutrient Visualization Components
///
/// This module provides components for displaying micronutrient data:
/// - Visual progress bars with color coding
/// - Daily value percentages
/// - Vitamins and minerals display
/// - Responsive design with mobile support
///
/// All components render as HTML strings suitable for SSR.
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/types.{type Micronutrients}

// ===================================================================
// DAILY VALUE CONSTANTS (FDA recommended daily values)
// ===================================================================

/// Daily value reference amounts (in appropriate units)
pub type DailyValues {
  DailyValues(
    // Fiber and sugars
    fiber_g: Float,
    // 28g
    sodium_mg: Float,
    // 2300mg
    cholesterol_mg: Float,
    // 300mg
    // Vitamins
    vitamin_a_mcg: Float,
    // 900mcg
    vitamin_c_mg: Float,
    // 90mg
    vitamin_d_mcg: Float,
    // 20mcg
    vitamin_e_mg: Float,
    // 15mg
    vitamin_k_mcg: Float,
    // 120mcg
    vitamin_b6_mg: Float,
    // 1.7mg
    vitamin_b12_mcg: Float,
    // 2.4mcg
    folate_mcg: Float,
    // 400mcg
    thiamin_mg: Float,
    // 1.2mg
    riboflavin_mg: Float,
    // 1.3mg
    niacin_mg: Float,
    // 16mg
    // Minerals
    calcium_mg: Float,
    // 1300mg
    iron_mg: Float,
    // 18mg
    magnesium_mg: Float,
    // 420mg
    phosphorus_mg: Float,
    // 1250mg
    potassium_mg: Float,
    // 4700mg
    zinc_mg: Float,
    // 11mg
  )
}

/// Standard FDA daily values for adults
pub fn standard_daily_values() -> DailyValues {
  DailyValues(
    fiber_g: 28.0,
    sodium_mg: 2300.0,
    cholesterol_mg: 300.0,
    vitamin_a_mcg: 900.0,
    vitamin_c_mg: 90.0,
    vitamin_d_mcg: 20.0,
    vitamin_e_mg: 15.0,
    vitamin_k_mcg: 120.0,
    vitamin_b6_mg: 1.7,
    vitamin_b12_mcg: 2.4,
    folate_mcg: 400.0,
    thiamin_mg: 1.2,
    riboflavin_mg: 1.3,
    niacin_mg: 16.0,
    calcium_mg: 1300.0,
    iron_mg: 18.0,
    magnesium_mg: 420.0,
    phosphorus_mg: 1250.0,
    potassium_mg: 4700.0,
    zinc_mg: 11.0,
  )
}

// ===================================================================
// MICRONUTRIENT DISPLAY DATA TYPES
// ===================================================================

/// Represents a single micronutrient for display
pub type MicronutrientItem {
  MicronutrientItem(
    name: String,
    amount: Float,
    unit: String,
    daily_value: Float,
    percentage: Float,
    category: String,
  )
}

// ===================================================================
// HELPER FUNCTIONS
// ===================================================================

/// Calculate percentage of daily value
fn calculate_percentage(amount: Float, daily_value: Float) -> Float {
  case daily_value >. 0.0 {
    True -> { amount /. daily_value } *. 100.0
    False -> 0.0
  }
}

/// Determine color class based on percentage
/// - Low (< 50%): yellow (deficiency warning)
/// - Optimal (50-100%): green
/// - Excess (> 100%): orange/red
fn get_status_color(percentage: Float) -> String {
  case percentage {
    p if p <. 50.0 -> "status-low"
    p if p <=. 100.0 -> "status-optimal"
    p if p <=. 150.0 -> "status-high"
    _ -> "status-excess"
  }
}

/// Format nutrient amount with appropriate precision
fn format_amount(amount: Float, unit: String) -> String {
  let rounded = case unit {
    "mg" | "g" ->
      float.truncate(amount *. 10.0)
      |> int.to_float
      |> fn(x) { x /. 10.0 }
    "mcg" -> float.truncate(amount) |> int.to_float
    _ -> amount
  }
  float.to_string(rounded)
}

// ===================================================================
// MICRONUTRIENT DATA EXTRACTION
// ===================================================================

/// Extract vitamins from micronutrients
pub fn extract_vitamins(
  micros: Micronutrients,
  dv: DailyValues,
) -> List(MicronutrientItem) {
  let items = [
    #("Vitamin A", micros.vitamin_a, "mcg", dv.vitamin_a_mcg),
    #("Vitamin C", micros.vitamin_c, "mg", dv.vitamin_c_mg),
    #("Vitamin D", micros.vitamin_d, "mcg", dv.vitamin_d_mcg),
    #("Vitamin E", micros.vitamin_e, "mg", dv.vitamin_e_mg),
    #("Vitamin K", micros.vitamin_k, "mcg", dv.vitamin_k_mcg),
    #("Vitamin B6", micros.vitamin_b6, "mg", dv.vitamin_b6_mg),
    #("Vitamin B12", micros.vitamin_b12, "mcg", dv.vitamin_b12_mcg),
    #("Folate", micros.folate, "mcg", dv.folate_mcg),
    #("Thiamin", micros.thiamin, "mg", dv.thiamin_mg),
    #("Riboflavin", micros.riboflavin, "mg", dv.riboflavin_mg),
    #("Niacin", micros.niacin, "mg", dv.niacin_mg),
  ]

  items
  |> list.filter_map(fn(item) {
    let #(name, opt_amount, unit, daily_value) = item
    case opt_amount {
      Some(amount) -> {
        let percentage = calculate_percentage(amount, daily_value)
        Ok(MicronutrientItem(
          name: name,
          amount: amount,
          unit: unit,
          daily_value: daily_value,
          percentage: percentage,
          category: "vitamin",
        ))
      }
      None -> Error(Nil)
    }
  })
}

/// Extract minerals from micronutrients
pub fn extract_minerals(
  micros: Micronutrients,
  dv: DailyValues,
) -> List(MicronutrientItem) {
  let items = [
    #("Calcium", micros.calcium, "mg", dv.calcium_mg),
    #("Iron", micros.iron, "mg", dv.iron_mg),
    #("Magnesium", micros.magnesium, "mg", dv.magnesium_mg),
    #("Phosphorus", micros.phosphorus, "mg", dv.phosphorus_mg),
    #("Potassium", micros.potassium, "mg", dv.potassium_mg),
    #("Zinc", micros.zinc, "mg", dv.zinc_mg),
  ]

  items
  |> list.filter_map(fn(item) {
    let #(name, opt_amount, unit, daily_value) = item
    case opt_amount {
      Some(amount) -> {
        let percentage = calculate_percentage(amount, daily_value)
        Ok(MicronutrientItem(
          name: name,
          amount: amount,
          unit: unit,
          daily_value: daily_value,
          percentage: percentage,
          category: "mineral",
        ))
      }
      None -> Error(Nil)
    }
  })
}

/// Extract other nutrients (fiber, sodium, cholesterol, sugar)
pub fn extract_other_nutrients(
  micros: Micronutrients,
  dv: DailyValues,
) -> List(MicronutrientItem) {
  let items = [
    #("Fiber", micros.fiber, "g", dv.fiber_g),
    #("Sodium", micros.sodium, "mg", dv.sodium_mg),
    #("Cholesterol", micros.cholesterol, "mg", dv.cholesterol_mg),
    #("Sugar", micros.sugar, "g", 50.0),
  ]
  // 50g arbitrary limit for sugar

  items
  |> list.filter_map(fn(item) {
    let #(name, opt_amount, unit, daily_value) = item
    case opt_amount {
      Some(amount) -> {
        let percentage = calculate_percentage(amount, daily_value)
        Ok(MicronutrientItem(
          name: name,
          amount: amount,
          unit: unit,
          daily_value: daily_value,
          percentage: percentage,
          category: "other",
        ))
      }
      None -> Error(Nil)
    }
  })
}

// ===================================================================
// COMPONENT RENDERING
// ===================================================================

/// Render a single micronutrient progress bar
pub fn micronutrient_bar(item: MicronutrientItem) -> String {
  let percentage_str = item.percentage |> float.truncate |> int.to_string
  let amount_str = format_amount(item.amount, item.unit)
  let dv_str = format_amount(item.daily_value, item.unit)
  let color_class = get_status_color(item.percentage)

  // Cap visual width at 100% but show actual percentage in label
  let visual_percentage = case item.percentage >. 100.0 {
    True -> 100.0
    False -> item.percentage
  }
  let width_str = float.to_string(visual_percentage)

  "<div class=\"micronutrient-bar "
  <> color_class
  <> "\">"
  <> "<div class=\"micro-header\">"
  <> "<span class=\"micro-name\">"
  <> item.name
  <> "</span>"
  <> "<span class=\"micro-value\">"
  <> amount_str
  <> item.unit
  <> " / "
  <> dv_str
  <> item.unit
  <> "</span>"
  <> "</div>"
  <> "<div class=\"micro-progress\">"
  <> "<div class=\"micro-fill\" style=\"width: "
  <> width_str
  <> "%\"></div>"
  <> "</div>"
  <> "<div class=\"micro-percentage\">"
  <> percentage_str
  <> "% DV</div>"
  <> "</div>"
}

/// Render a section of micronutrients (vitamins, minerals, or other)
pub fn micronutrient_section(
  title: String,
  items: List(MicronutrientItem),
) -> String {
  case items {
    [] -> ""
    _ -> {
      let items_html = items |> list.map(micronutrient_bar) |> string.concat
      "<div class=\"micro-section\">"
      <> "<h3 class=\"micro-section-title\">"
      <> title
      <> "</h3>"
      <> "<div class=\"micro-list\">"
      <> items_html
      <> "</div>"
      <> "</div>"
    }
  }
}

/// Complete micronutrient panel with all nutrients
pub fn micronutrient_panel(micros: Option(Micronutrients)) -> String {
  case micros {
    None ->
      "<div class=\"micronutrient-panel empty\">"
      <> "<p class=\"empty-message\">No micronutrient data available</p>"
      <> "</div>"
    Some(m) -> {
      let dv = standard_daily_values()
      let vitamins = extract_vitamins(m, dv)
      let minerals = extract_minerals(m, dv)
      let other = extract_other_nutrients(m, dv)

      case
        list.is_empty(vitamins)
        && list.is_empty(minerals)
        && list.is_empty(other)
      {
        True ->
          "<div class=\"micronutrient-panel empty\">"
          <> "<p class=\"empty-message\">No micronutrient data available</p>"
          <> "</div>"
        False ->
          "<div class=\"micronutrient-panel\">"
          <> micronutrient_section("Vitamins", vitamins)
          <> micronutrient_section("Minerals", minerals)
          <> micronutrient_section("Other Nutrients", other)
          <> "</div>"
      }
    }
  }
}

/// Compact micronutrient summary for cards
pub fn micronutrient_summary(micros: Option(Micronutrients)) -> String {
  case micros {
    None -> "<p class=\"micro-summary-empty\">No micronutrient data</p>"
    Some(m) -> {
      let dv = standard_daily_values()
      let vitamins = extract_vitamins(m, dv)
      let minerals = extract_minerals(m, dv)

      let vitamin_count =
        list.fold(vitamins, 0, fn(acc, _) { acc + 1 }) |> int.to_string
      let mineral_count =
        list.fold(minerals, 0, fn(acc, _) { acc + 1 }) |> int.to_string

      "<div class=\"micro-summary\">"
      <> "<span class=\"badge badge-vitamin\">"
      <> vitamin_count
      <> " vitamins</span>"
      <> "<span class=\"badge badge-mineral\">"
      <> mineral_count
      <> " minerals</span>"
      <> "</div>"
    }
  }
}
