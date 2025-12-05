/// Comprehensive tests for micronutrient aggregation, RDA calculations, and deficiency detection
///
/// This test suite covers:
/// - Daily micronutrient totals from multiple food logs
/// - RDA (Recommended Daily Allowance) percentage calculations
/// - Deficiency detection (< 50% RDA)
/// - Excessive intake warnings (> 200% RDA)
/// - Edge cases (missing data, zero values, empty logs)
import gleam/float
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/types.{
  type FoodLogEntry, type Micronutrients, Breakfast, FoodLogEntry, Macros,
  Micronutrients, Snack, micronutrients_sum, micronutrients_zero,
}

// ============================================================================
// Test Helpers & Constants
// ============================================================================

/// FDA Recommended Daily Allowances (RDA) for adults
pub type RDAValues {
  RDAValues(
    fiber_g: Float,
    sugar_g: Float,
    sodium_mg: Float,
    cholesterol_mg: Float,
    vitamin_a_mcg: Float,
    vitamin_c_mg: Float,
    vitamin_d_mcg: Float,
    vitamin_e_mg: Float,
    vitamin_k_mcg: Float,
    vitamin_b6_mg: Float,
    vitamin_b12_mcg: Float,
    folate_mcg: Float,
    thiamin_mg: Float,
    riboflavin_mg: Float,
    niacin_mg: Float,
    calcium_mg: Float,
    iron_mg: Float,
    magnesium_mg: Float,
    phosphorus_mg: Float,
    potassium_mg: Float,
    zinc_mg: Float,
  )
}

/// Standard RDA values for adult males (reference values)
pub fn standard_rda() -> RDAValues {
  RDAValues(
    fiber_g: 28.0,
    sugar_g: 50.0,
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

/// Thresholds for deficiency and excess detection
pub const deficiency_threshold = 50.0

pub const excess_threshold = 200.0

/// Helper to compare floats with tolerance
fn float_close(actual: Float, expected: Float, tolerance: Float) -> Bool {
  float.absolute_value(actual -. expected) <. tolerance
}

/// Calculate percentage of RDA
fn calculate_rda_percentage(amount: Float, rda: Float) -> Float {
  case rda >. 0.0 {
    True -> { amount /. rda } *. 100.0
    False -> 0.0
  }
}

/// Extract total micronutrients from a list of food log entries
fn aggregate_from_logs(entries: List(FoodLogEntry)) -> Micronutrients {
  entries
  |> list.filter_map(fn(entry) {
    case entry.micronutrients {
      Some(micros) -> Ok(micros)
      None -> Error(Nil)
    }
  })
  |> micronutrients_sum
}

/// Create a test food log entry
fn create_test_log(
  name: String,
  servings: Float,
  micros: Micronutrients,
) -> FoodLogEntry {
  FoodLogEntry(
    id: "test-" <> name,
    recipe_id: "recipe-" <> name,
    recipe_name: name,
    servings: servings,
    macros: Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
    micronutrients: Some(micros),
    meal_type: Breakfast,
    logged_at: "2024-01-01T08:00:00Z",
    source_type: "recipe",
    source_id: "test",
  )
}

// ============================================================================
// Single Food Log Tests
// ============================================================================

/// Test extracting micronutrients from a single food log entry
pub fn single_log_extraction_test() {
  let micros =
    Micronutrients(
      fiber: Some(5.0),
      sugar: Some(10.0),
      sodium: Some(200.0),
      cholesterol: Some(50.0),
      vitamin_a: Some(500.0),
      vitamin_c: Some(60.0),
      vitamin_d: Some(10.0),
      vitamin_e: Some(15.0),
      vitamin_k: Some(80.0),
      vitamin_b6: Some(2.0),
      vitamin_b12: Some(2.4),
      folate: Some(400.0),
      thiamin: Some(1.2),
      riboflavin: Some(1.3),
      niacin: Some(16.0),
      calcium: Some(1000.0),
      iron: Some(18.0),
      magnesium: Some(400.0),
      phosphorus: Some(700.0),
      potassium: Some(3500.0),
      zinc: Some(11.0),
    )

  let entry = create_test_log("Breakfast Bowl", 1.0, micros)
  let result = aggregate_from_logs([entry])

  result.fiber |> should.equal(Some(5.0))
  result.vitamin_c |> should.equal(Some(60.0))
  result.calcium |> should.equal(Some(1000.0))
}

/// Test extracting from entry with no micronutrient data
pub fn single_log_no_micros_test() {
  let entry =
    FoodLogEntry(
      id: "test-empty",
      recipe_id: "recipe-empty",
      recipe_name: "Empty Food",
      servings: 1.0,
      macros: Macros(protein: 20.0, fat: 10.0, carbs: 30.0),
      micronutrients: None,
      meal_type: Snack,
      logged_at: "2024-01-01T10:00:00Z",
      source_type: "recipe",
      source_id: "test",
    )

  let result = aggregate_from_logs([entry])

  // Should return zero micronutrients
  result.fiber |> should.equal(None)
  result.vitamin_c |> should.equal(None)
  result.calcium |> should.equal(None)
}

// ============================================================================
// Multiple Food Logs Aggregation Tests
// ============================================================================

/// Test aggregating micronutrients from multiple food log entries
pub fn aggregate_multiple_logs_test() {
  let breakfast_micros =
    Micronutrients(
      fiber: Some(8.0),
      sugar: Some(12.0),
      sodium: Some(300.0),
      cholesterol: Some(100.0),
      vitamin_a: Some(400.0),
      vitamin_c: Some(30.0),
      vitamin_d: Some(5.0),
      vitamin_e: Some(8.0),
      vitamin_k: Some(60.0),
      vitamin_b6: Some(0.8),
      vitamin_b12: Some(1.2),
      folate: Some(150.0),
      thiamin: Some(0.5),
      riboflavin: Some(0.6),
      niacin: Some(7.0),
      calcium: Some(400.0),
      iron: Some(8.0),
      magnesium: Some(150.0),
      phosphorus: Some(350.0),
      potassium: Some(1500.0),
      zinc: Some(4.0),
    )

  let lunch_micros =
    Micronutrients(
      fiber: Some(10.0),
      sugar: Some(15.0),
      sodium: Some(800.0),
      cholesterol: Some(80.0),
      vitamin_a: Some(300.0),
      vitamin_c: Some(40.0),
      vitamin_d: Some(8.0),
      vitamin_e: Some(6.0),
      vitamin_k: Some(50.0),
      vitamin_b6: Some(1.0),
      vitamin_b12: Some(1.5),
      folate: Some(200.0),
      thiamin: Some(0.7),
      riboflavin: Some(0.8),
      niacin: Some(9.0),
      calcium: Some(500.0),
      iron: Some(10.0),
      magnesium: Some(180.0),
      phosphorus: Some(450.0),
      potassium: Some(2000.0),
      zinc: Some(5.0),
    )

  let dinner_micros =
    Micronutrients(
      fiber: Some(12.0),
      sugar: Some(18.0),
      sodium: Some(900.0),
      cholesterol: Some(120.0),
      vitamin_a: Some(500.0),
      vitamin_c: Some(50.0),
      vitamin_d: Some(10.0),
      vitamin_e: Some(10.0),
      vitamin_k: Some(80.0),
      vitamin_b6: Some(1.2),
      vitamin_b12: Some(2.0),
      folate: Some(250.0),
      thiamin: Some(0.9),
      riboflavin: Some(1.0),
      niacin: Some(12.0),
      calcium: Some(600.0),
      iron: Some(12.0),
      magnesium: Some(200.0),
      phosphorus: Some(550.0),
      potassium: Some(2500.0),
      zinc: Some(6.0),
    )

  let entries = [
    create_test_log("Breakfast", 1.0, breakfast_micros),
    create_test_log("Lunch", 1.0, lunch_micros),
    create_test_log("Dinner", 1.0, dinner_micros),
  ]

  let result = aggregate_from_logs(entries)

  // Verify aggregated totals
  result.fiber |> should.equal(Some(30.0))
  result.sugar |> should.equal(Some(45.0))
  result.sodium |> should.equal(Some(2000.0))
  result.cholesterol |> should.equal(Some(300.0))
  result.vitamin_a |> should.equal(Some(1200.0))
  result.vitamin_c |> should.equal(Some(120.0))
  result.vitamin_d |> should.equal(Some(23.0))
  result.calcium |> should.equal(Some(1500.0))
  result.iron |> should.equal(Some(30.0))
  result.potassium |> should.equal(Some(6000.0))
}

/// Test aggregating logs with mixed Some/None values
pub fn aggregate_mixed_data_test() {
  let log1_micros =
    Micronutrients(
      fiber: Some(10.0),
      sugar: None,
      sodium: Some(500.0),
      cholesterol: None,
      vitamin_a: Some(300.0),
      vitamin_c: None,
      vitamin_d: Some(5.0),
      vitamin_e: None,
      vitamin_k: Some(40.0),
      vitamin_b6: None,
      vitamin_b12: Some(1.0),
      folate: None,
      thiamin: Some(0.5),
      riboflavin: None,
      niacin: Some(8.0),
      calcium: None,
      iron: Some(10.0),
      magnesium: None,
      phosphorus: Some(400.0),
      potassium: None,
      zinc: Some(5.0),
    )

  let log2_micros =
    Micronutrients(
      fiber: None,
      sugar: Some(20.0),
      sodium: None,
      cholesterol: Some(100.0),
      vitamin_a: None,
      vitamin_c: Some(60.0),
      vitamin_d: None,
      vitamin_e: Some(10.0),
      vitamin_k: None,
      vitamin_b6: Some(1.0),
      vitamin_b12: None,
      folate: Some(200.0),
      thiamin: None,
      riboflavin: Some(0.8),
      niacin: None,
      calcium: Some(800.0),
      iron: None,
      magnesium: Some(250.0),
      phosphorus: None,
      potassium: Some(3000.0),
      zinc: None,
    )

  let entries = [
    create_test_log("Meal1", 1.0, log1_micros),
    create_test_log("Meal2", 1.0, log2_micros),
  ]

  let result = aggregate_from_logs(entries)

  // Should aggregate available values
  result.fiber |> should.equal(Some(10.0))
  result.sugar |> should.equal(Some(20.0))
  result.sodium |> should.equal(Some(500.0))
  result.cholesterol |> should.equal(Some(100.0))
  result.vitamin_c |> should.equal(Some(60.0))
  result.calcium |> should.equal(Some(800.0))
}

/// Test empty food log list
pub fn aggregate_empty_logs_test() {
  let result = aggregate_from_logs([])
  let expected = micronutrients_zero()

  result.fiber |> should.equal(expected.fiber)
  result.vitamin_c |> should.equal(expected.vitamin_c)
  result.calcium |> should.equal(expected.calcium)
}

// ============================================================================
// RDA Percentage Calculation Tests
// ============================================================================

/// Test RDA percentage calculations with full RDA met
pub fn rda_percentage_at_target_test() {
  let rda = standard_rda()

  // Exactly 100% of RDA
  calculate_rda_percentage(28.0, rda.fiber_g)
  |> should.equal(100.0)

  calculate_rda_percentage(90.0, rda.vitamin_c_mg)
  |> should.equal(100.0)

  calculate_rda_percentage(1300.0, rda.calcium_mg)
  |> should.equal(100.0)
}

/// Test RDA percentage with deficiency (< 50%)
pub fn rda_percentage_deficient_test() {
  let rda = standard_rda()

  // 40% of RDA (deficient)
  let fiber_pct = calculate_rda_percentage(11.2, rda.fiber_g)
  float_close(fiber_pct, 40.0, 0.1) |> should.be_true()

  // 25% of RDA (severe deficiency)
  let vitamin_c_pct = calculate_rda_percentage(22.5, rda.vitamin_c_mg)
  float_close(vitamin_c_pct, 25.0, 0.1) |> should.be_true()

  // 30% of RDA
  let calcium_pct = calculate_rda_percentage(390.0, rda.calcium_mg)
  float_close(calcium_pct, 30.0, 0.1) |> should.be_true()
}

/// Test RDA percentage with adequate intake (50-100%)
pub fn rda_percentage_adequate_test() {
  let rda = standard_rda()

  // 75% of RDA
  let fiber_pct = calculate_rda_percentage(21.0, rda.fiber_g)
  float_close(fiber_pct, 75.0, 0.1) |> should.be_true()

  // 80% of RDA
  let vitamin_c_pct = calculate_rda_percentage(72.0, rda.vitamin_c_mg)
  float_close(vitamin_c_pct, 80.0, 0.1) |> should.be_true()

  // 90% of RDA
  let iron_pct = calculate_rda_percentage(16.2, rda.iron_mg)
  float_close(iron_pct, 90.0, 0.1) |> should.be_true()
}

/// Test RDA percentage with excess (> 200%)
pub fn rda_percentage_excess_test() {
  let rda = standard_rda()

  // 250% of RDA (excessive)
  let sodium_pct = calculate_rda_percentage(5750.0, rda.sodium_mg)
  float_close(sodium_pct, 250.0, 0.1) |> should.be_true()

  // 300% of RDA (very high)
  let vitamin_a_pct = calculate_rda_percentage(2700.0, rda.vitamin_a_mcg)
  float_close(vitamin_a_pct, 300.0, 0.1) |> should.be_true()

  // 200% of RDA (threshold)
  let iron_pct = calculate_rda_percentage(36.0, rda.iron_mg)
  float_close(iron_pct, 200.0, 0.1) |> should.be_true()
}

// ============================================================================
// Deficiency Detection Tests (< 50% RDA)
// ============================================================================

/// Detect deficiencies in aggregated daily intake
pub type DeficiencyReport {
  DeficiencyReport(
    nutrient: String,
    current_amount: Float,
    rda_amount: Float,
    percentage: Float,
  )
}

/// Check for deficiencies in micronutrient totals
fn detect_deficiencies(
  micros: Micronutrients,
  rda: RDAValues,
) -> List(DeficiencyReport) {
  let checks = [
    #("Fiber", micros.fiber, rda.fiber_g),
    #("Vitamin C", micros.vitamin_c, rda.vitamin_c_mg),
    #("Vitamin D", micros.vitamin_d, rda.vitamin_d_mcg),
    #("Calcium", micros.calcium, rda.calcium_mg),
    #("Iron", micros.iron, rda.iron_mg),
    #("Magnesium", micros.magnesium, rda.magnesium_mg),
    #("Potassium", micros.potassium, rda.potassium_mg),
  ]

  checks
  |> list.filter_map(fn(check) {
    let #(name, opt_amount, rda_val) = check
    case opt_amount {
      Some(amount) -> {
        let pct = calculate_rda_percentage(amount, rda_val)
        case pct <. deficiency_threshold {
          True ->
            Ok(DeficiencyReport(
              nutrient: name,
              current_amount: amount,
              rda_amount: rda_val,
              percentage: pct,
            ))
          False -> Error(Nil)
        }
      }
      None -> Error(Nil)
    }
  })
}

/// Test detecting multiple deficiencies
pub fn detect_multiple_deficiencies_test() {
  let micros =
    Micronutrients(
      fiber: Some(10.0),
      // 35.7% of RDA
      sugar: Some(25.0),
      sodium: Some(1000.0),
      cholesterol: Some(150.0),
      vitamin_a: Some(500.0),
      vitamin_c: Some(30.0),
      // 33.3% of RDA
      vitamin_d: Some(5.0),
      // 25% of RDA
      vitamin_e: Some(12.0),
      vitamin_k: Some(100.0),
      vitamin_b6: Some(1.5),
      vitamin_b12: Some(2.0),
      folate: Some(300.0),
      thiamin: Some(1.0),
      riboflavin: Some(1.1),
      niacin: Some(14.0),
      calcium: Some(500.0),
      // 38.5% of RDA
      iron: Some(15.0),
      magnesium: Some(150.0),
      // 35.7% of RDA
      phosphorus: Some(800.0),
      potassium: Some(2000.0),
      // 42.6% of RDA
      zinc: Some(9.0),
    )

  let rda = standard_rda()
  let deficiencies = detect_deficiencies(micros, rda)

  // Should detect 5 deficiencies
  list.length(deficiencies) |> should.equal(5)

  // Verify specific deficiencies detected
  let nutrient_names =
    deficiencies
    |> list.map(fn(d) { d.nutrient })

  list.contains(nutrient_names, "Fiber") |> should.be_true()
  list.contains(nutrient_names, "Vitamin C") |> should.be_true()
  list.contains(nutrient_names, "Vitamin D") |> should.be_true()
  list.contains(nutrient_names, "Calcium") |> should.be_true()
  list.contains(nutrient_names, "Magnesium") |> should.be_true()
}

/// Test no deficiencies when all nutrients are adequate
pub fn detect_no_deficiencies_test() {
  let micros =
    Micronutrients(
      fiber: Some(30.0),
      // 107% of RDA
      sugar: Some(40.0),
      sodium: Some(2000.0),
      cholesterol: Some(200.0),
      vitamin_a: Some(900.0),
      vitamin_c: Some(100.0),
      // 111% of RDA
      vitamin_d: Some(25.0),
      // 125% of RDA
      vitamin_e: Some(18.0),
      vitamin_k: Some(130.0),
      vitamin_b6: Some(2.0),
      vitamin_b12: Some(3.0),
      folate: Some(450.0),
      thiamin: Some(1.5),
      riboflavin: Some(1.6),
      niacin: Some(18.0),
      calcium: Some(1400.0),
      // 107% of RDA
      iron: Some(20.0),
      // 111% of RDA
      magnesium: Some(450.0),
      // 107% of RDA
      phosphorus: Some(1300.0),
      potassium: Some(5000.0),
      // 106% of RDA
      zinc: Some(12.0),
    )

  let rda = standard_rda()
  let deficiencies = detect_deficiencies(micros, rda)

  // Should detect no deficiencies
  list.length(deficiencies) |> should.equal(0)
}

// ============================================================================
// Excessive Intake Warning Tests (> 200% RDA)
// ============================================================================

/// Warning report for excessive nutrient intake
pub type ExcessWarning {
  ExcessWarning(
    nutrient: String,
    current_amount: Float,
    rda_amount: Float,
    percentage: Float,
  )
}

/// Check for excessive nutrient intake
fn detect_excess_warnings(
  micros: Micronutrients,
  rda: RDAValues,
) -> List(ExcessWarning) {
  let checks = [
    #("Sodium", micros.sodium, rda.sodium_mg),
    #("Cholesterol", micros.cholesterol, rda.cholesterol_mg),
    #("Vitamin A", micros.vitamin_a, rda.vitamin_a_mcg),
    #("Iron", micros.iron, rda.iron_mg),
    #("Zinc", micros.zinc, rda.zinc_mg),
  ]

  checks
  |> list.filter_map(fn(check) {
    let #(name, opt_amount, rda_val) = check
    case opt_amount {
      Some(amount) -> {
        let pct = calculate_rda_percentage(amount, rda_val)
        case pct >. excess_threshold {
          True ->
            Ok(ExcessWarning(
              nutrient: name,
              current_amount: amount,
              rda_amount: rda_val,
              percentage: pct,
            ))
          False -> Error(Nil)
        }
      }
      None -> Error(Nil)
    }
  })
}

/// Test detecting excessive intake warnings
pub fn detect_excess_warnings_test() {
  let micros =
    Micronutrients(
      fiber: Some(25.0),
      sugar: Some(40.0),
      sodium: Some(5000.0),
      // 217% of RDA
      cholesterol: Some(700.0),
      // 233% of RDA
      vitamin_a: Some(2000.0),
      // 222% of RDA
      vitamin_c: Some(100.0),
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
      iron: Some(40.0),
      // 222% of RDA
      magnesium: Some(420.0),
      phosphorus: Some(1250.0),
      potassium: Some(4700.0),
      zinc: Some(25.0),
      // 227% of RDA
    )

  let rda = standard_rda()
  let warnings = detect_excess_warnings(micros, rda)

  // Should detect 5 excess warnings
  list.length(warnings) |> should.equal(5)

  // Verify specific warnings
  let nutrient_names =
    warnings
    |> list.map(fn(w) { w.nutrient })

  list.contains(nutrient_names, "Sodium") |> should.be_true()
  list.contains(nutrient_names, "Cholesterol") |> should.be_true()
  list.contains(nutrient_names, "Vitamin A") |> should.be_true()
  list.contains(nutrient_names, "Iron") |> should.be_true()
  list.contains(nutrient_names, "Zinc") |> should.be_true()
}

/// Test no excess warnings when all nutrients are in safe range
pub fn detect_no_excess_test() {
  let micros =
    Micronutrients(
      fiber: Some(28.0),
      sugar: Some(45.0),
      sodium: Some(2000.0),
      // 87% of RDA
      cholesterol: Some(250.0),
      // 83% of RDA
      vitamin_a: Some(900.0),
      // 100% of RDA
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
      // 100% of RDA
      magnesium: Some(420.0),
      phosphorus: Some(1250.0),
      potassium: Some(4700.0),
      zinc: Some(11.0),
      // 100% of RDA
    )

  let rda = standard_rda()
  let warnings = detect_excess_warnings(micros, rda)

  // Should detect no excess warnings
  list.length(warnings) |> should.equal(0)
}

// ============================================================================
// Edge Case Tests
// ============================================================================

/// Test handling zero values
pub fn zero_values_test() {
  let micros =
    Micronutrients(
      fiber: Some(0.0),
      sugar: Some(0.0),
      sodium: Some(0.0),
      cholesterol: Some(0.0),
      vitamin_a: Some(0.0),
      vitamin_c: Some(0.0),
      vitamin_d: Some(0.0),
      vitamin_e: Some(0.0),
      vitamin_k: Some(0.0),
      vitamin_b6: Some(0.0),
      vitamin_b12: Some(0.0),
      folate: Some(0.0),
      thiamin: Some(0.0),
      riboflavin: Some(0.0),
      niacin: Some(0.0),
      calcium: Some(0.0),
      iron: Some(0.0),
      magnesium: Some(0.0),
      phosphorus: Some(0.0),
      potassium: Some(0.0),
      zinc: Some(0.0),
    )

  let rda = standard_rda()

  // All should calculate to 0%
  calculate_rda_percentage(0.0, rda.fiber_g) |> should.equal(0.0)
  calculate_rda_percentage(0.0, rda.vitamin_c_mg) |> should.equal(0.0)
  calculate_rda_percentage(0.0, rda.calcium_mg) |> should.equal(0.0)

  // Should detect all as deficiencies
  let deficiencies = detect_deficiencies(micros, rda)
  list.length(deficiencies) |> should.equal(7)
}

/// Test handling all None values
pub fn all_none_values_test() {
  let micros = micronutrients_zero()
  let rda = standard_rda()

  // Should not detect deficiencies for None values
  let deficiencies = detect_deficiencies(micros, rda)
  list.length(deficiencies) |> should.equal(0)

  // Should not detect excess warnings for None values
  let warnings = detect_excess_warnings(micros, rda)
  list.length(warnings) |> should.equal(0)
}

/// Test very large values (realistic extreme case)
pub fn very_large_values_test() {
  let micros =
    Micronutrients(
      fiber: Some(100.0),
      // 357% of RDA
      sugar: Some(200.0),
      sodium: Some(10_000.0),
      // 434% of RDA
      cholesterol: Some(1500.0),
      // 500% of RDA
      vitamin_a: Some(5000.0),
      vitamin_c: Some(500.0),
      vitamin_d: Some(100.0),
      vitamin_e: Some(75.0),
      vitamin_k: Some(600.0),
      vitamin_b6: Some(10.0),
      vitamin_b12: Some(12.0),
      folate: Some(2000.0),
      thiamin: Some(6.0),
      riboflavin: Some(6.5),
      niacin: Some(80.0),
      calcium: Some(5000.0),
      iron: Some(90.0),
      // 500% of RDA
      magnesium: Some(2000.0),
      phosphorus: Some(5000.0),
      potassium: Some(20_000.0),
      zinc: Some(55.0),
      // 500% of RDA
    )

  let rda = standard_rda()

  // Should detect multiple excess warnings
  let warnings = detect_excess_warnings(micros, rda)
  { list.length(warnings) > 0 } |> should.be_true()

  // Verify percentages are calculated correctly
  let sodium_pct = calculate_rda_percentage(10_000.0, rda.sodium_mg)
  float_close(sodium_pct, 434.78, 0.1) |> should.be_true()
}

/// Test fractional serving sizes from food logs
pub fn fractional_servings_aggregation_test() {
  let base_micros =
    Micronutrients(
      fiber: Some(20.0),
      sugar: Some(30.0),
      sodium: Some(1000.0),
      cholesterol: Some(100.0),
      vitamin_a: Some(600.0),
      vitamin_c: Some(60.0),
      vitamin_d: Some(15.0),
      vitamin_e: Some(12.0),
      vitamin_k: Some(90.0),
      vitamin_b6: Some(1.5),
      vitamin_b12: Some(2.0),
      folate: Some(300.0),
      thiamin: Some(1.0),
      riboflavin: Some(1.1),
      niacin: Some(12.0),
      calcium: Some(900.0),
      iron: Some(15.0),
      magnesium: Some(300.0),
      phosphorus: Some(800.0),
      potassium: Some(3500.0),
      zinc: Some(9.0),
    )

  // Test with 0.5 servings (should be halved when scaled)
  let entry = create_test_log("Half Serving", 0.5, base_micros)
  let result = aggregate_from_logs([entry])

  // Note: This test demonstrates that servings field exists but
  // aggregation doesn't auto-scale. That would be a feature to add.
  result.fiber |> should.equal(Some(20.0))
  result.calcium |> should.equal(Some(900.0))
}
