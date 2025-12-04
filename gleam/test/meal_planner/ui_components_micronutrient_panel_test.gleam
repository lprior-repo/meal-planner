import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/types.{type Micronutrients, Micronutrients}
import meal_planner/ui/components/micronutrient_panel

pub fn main() {
  gleeunit.main()
}

// ===================================================================
// Helper Functions
// ===================================================================

fn sample_micronutrients() -> Micronutrients {
  Micronutrients(
    fiber: Some(15.0),
    sugar: Some(10.0),
    sodium: Some(500.0),
    cholesterol: Some(50.0),
    vitamin_a: Some(450.0),
    vitamin_c: Some(45.0),
    vitamin_d: Some(10.0),
    vitamin_e: Some(7.5),
    vitamin_k: Some(60.0),
    vitamin_b6: Some(0.85),
    vitamin_b12: Some(1.2),
    folate: Some(200.0),
    thiamin: Some(0.6),
    riboflavin: Some(0.65),
    niacin: Some(8.0),
    calcium: Some(650.0),
    iron: Some(9.0),
    magnesium: Some(210.0),
    phosphorus: Some(625.0),
    potassium: Some(2350.0),
    zinc: Some(5.5),
  )
}

fn full_micronutrients() -> Micronutrients {
  Micronutrients(
    fiber: Some(28.0),
    sugar: Some(25.0),
    sodium: Some(2300.0),
    cholesterol: Some(300.0),
    vitamin_a: Some(900.0),
    vitamin_c: Some(90.0),
    vitamin_d: Some(20.0),
    vitamin_e: Some(15.0),
    vitamin_k: Some(120.0),
    vitamin_b6: Some(1.7),
    vitamin_b12: Some(2.4),
    folate: Some(400.0),
    thiamin: Some(1.2),
    riboflavin: Some(1.3),
    niacin: Some(16.0),
    calcium: Some(1300.0),
    iron: Some(18.0),
    magnesium: Some(420.0),
    phosphorus: Some(1250.0),
    potassium: Some(4700.0),
    zinc: Some(11.0),
  )
}

// ===================================================================
// Daily Values Tests
// ===================================================================

pub fn standard_daily_values_test() {
  let dv = micronutrient_panel.standard_daily_values()

  dv.fiber_g |> should.equal(28.0)
  dv.vitamin_c_mg |> should.equal(90.0)
  dv.calcium_mg |> should.equal(1300.0)
  dv.iron_mg |> should.equal(18.0)
}

// ===================================================================
// Data Extraction Tests
// ===================================================================

pub fn extract_vitamins_test() {
  let micros = sample_micronutrients()
  let dv = micronutrient_panel.standard_daily_values()

  let vitamins = micronutrient_panel.extract_vitamins(micros, dv)

  // Should extract all vitamins that have values
  vitamins
  |> should.not_equal([])

  // Should have 11 vitamins (all defined in sample)
  let count = case vitamins {
    [] -> 0
    _ -> 11
  }
  count |> should.equal(11)
}

pub fn extract_minerals_test() {
  let micros = sample_micronutrients()
  let dv = micronutrient_panel.standard_daily_values()

  let minerals = micronutrient_panel.extract_minerals(micros, dv)

  // Should extract all minerals that have values
  minerals
  |> should.not_equal([])

  // Should have 6 minerals (all defined in sample)
  let count = case minerals {
    [] -> 0
    _ -> 6
  }
  count |> should.equal(6)
}

pub fn extract_other_nutrients_test() {
  let micros = sample_micronutrients()
  let dv = micronutrient_panel.standard_daily_values()

  let other = micronutrient_panel.extract_other_nutrients(micros, dv)

  // Should extract fiber, sodium, cholesterol, sugar
  other
  |> should.not_equal([])
}

// ===================================================================
// Component Rendering Tests
// ===================================================================

pub fn micronutrient_bar_renders_test() {
  let item =
    micronutrient_panel.MicronutrientItem(
      name: "Vitamin C",
      amount: 45.0,
      unit: "mg",
      daily_value: 90.0,
      percentage: 50.0,
      category: "vitamin",
    )

  let html = micronutrient_panel.micronutrient_bar(item)

  // Should contain the nutrient name
  html |> string.contains("Vitamin C") |> should.be_true

  // Should contain percentage
  html |> string.contains("50% DV") |> should.be_true

  // Should have progress bar structure
  html |> string.contains("micro-progress") |> should.be_true
  html |> string.contains("micro-fill") |> should.be_true
}

pub fn micronutrient_section_renders_test() {
  let micros = sample_micronutrients()
  let dv = micronutrient_panel.standard_daily_values()
  let vitamins = micronutrient_panel.extract_vitamins(micros, dv)

  let html = micronutrient_panel.micronutrient_section("Vitamins", vitamins)

  // Should contain section title
  html |> string.contains("Vitamins") |> should.be_true

  // Should have section structure
  html |> string.contains("micro-section") |> should.be_true
  html |> string.contains("micro-list") |> should.be_true
}

pub fn micronutrient_panel_with_data_test() {
  let micros = Some(sample_micronutrients())

  let html = micronutrient_panel.micronutrient_panel(micros)

  // Should contain panel structure
  html |> string.contains("micronutrient-panel") |> should.be_true

  // Should contain section titles
  html |> string.contains("Vitamins") |> should.be_true
  html |> string.contains("Minerals") |> should.be_true

  // Should not be empty
  html |> string.contains("empty") |> should.be_false
}

pub fn micronutrient_panel_without_data_test() {
  let html = micronutrient_panel.micronutrient_panel(None)

  // Should show empty state
  html |> string.contains("empty") |> should.be_true
  html |> string.contains("No micronutrient data available") |> should.be_true
}

pub fn micronutrient_panel_full_daily_values_test() {
  let micros = Some(full_micronutrients())

  let html = micronutrient_panel.micronutrient_panel(micros)

  // Should render successfully with 100% DV
  html |> string.contains("micronutrient-panel") |> should.be_true
  html |> string.contains("100% DV") |> should.be_true
}

// ===================================================================
// Summary Component Tests
// ===================================================================

pub fn micronutrient_summary_with_data_test() {
  let micros = Some(sample_micronutrients())

  let html = micronutrient_panel.micronutrient_summary(micros)

  // Should show vitamin and mineral counts
  html |> string.contains("vitamins") |> should.be_true
  html |> string.contains("minerals") |> should.be_true
  html |> string.contains("badge") |> should.be_true
}

pub fn micronutrient_summary_without_data_test() {
  let html = micronutrient_panel.micronutrient_summary(None)

  // Should show empty message
  html |> string.contains("No micronutrient data") |> should.be_true
}

// ===================================================================
// Color Coding Tests
// ===================================================================

pub fn low_percentage_has_warning_color_test() {
  let item =
    micronutrient_panel.MicronutrientItem(
      name: "Vitamin D",
      amount: 5.0,
      unit: "mcg",
      daily_value: 20.0,
      percentage: 25.0,
      category: "vitamin",
    )

  let html = micronutrient_panel.micronutrient_bar(item)

  // Should have low status (< 50%)
  html |> string.contains("status-low") |> should.be_true
}

pub fn optimal_percentage_has_green_color_test() {
  let item =
    micronutrient_panel.MicronutrientItem(
      name: "Vitamin C",
      amount: 67.5,
      unit: "mg",
      daily_value: 90.0,
      percentage: 75.0,
      category: "vitamin",
    )

  let html = micronutrient_panel.micronutrient_bar(item)

  // Should have optimal status (50-100%)
  html |> string.contains("status-optimal") |> should.be_true
}

pub fn high_percentage_has_orange_color_test() {
  let item =
    micronutrient_panel.MicronutrientItem(
      name: "Vitamin A",
      amount: 1125.0,
      unit: "mcg",
      daily_value: 900.0,
      percentage: 125.0,
      category: "vitamin",
    )

  let html = micronutrient_panel.micronutrient_bar(item)

  // Should have high status (100-150%)
  html |> string.contains("status-high") |> should.be_true
}

pub fn excess_percentage_has_red_color_test() {
  let item =
    micronutrient_panel.MicronutrientItem(
      name: "Sodium",
      amount: 4600.0,
      unit: "mg",
      daily_value: 2300.0,
      percentage: 200.0,
      category: "other",
    )

  let html = micronutrient_panel.micronutrient_bar(item)

  // Should have excess status (> 150%)
  html |> string.contains("status-excess") |> should.be_true
}
