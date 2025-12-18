/// Value objects for measurements
///
/// Replaces primitive obsession by creating type-safe wrappers for common measurements.
/// This prevents mixing grams with milliliters, calories with kilograms, etc.
/// Grams - mass measurement for food (protein, fat, carbs)
pub type Grams =
  Float

/// Calories - energy measurement
pub type Calories =
  Float

/// Percentage - ratio expressed as 0.0 to 1.0
pub type Percentage =
  Float

/// Portion multiplier - how many servings (e.g., 1.5x = 1.5 servings)
pub type PortionMultiplier =
  Float

/// Milligrams - small mass measurement (for micronutrients)
pub type Milligrams =
  Float

/// Micrograms - very small mass measurement (for vitamins)
pub type Micrograms =
  Float

// ============================================================================
// Value Object Constructors with Validation
// ============================================================================

/// Create grams value with validation (must be >= 0)
pub fn grams(value: Float) -> Result(Grams, String) {
  case value <. 0.0 {
    True -> Error("Grams must be non-negative, got " <> float_to_string(value))
    False -> Ok(value)
  }
}

/// Create calories value with validation (must be >= 0)
pub fn calories(value: Float) -> Result(Calories, String) {
  case value <. 0.0 {
    True ->
      Error("Calories must be non-negative, got " <> float_to_string(value))
    False -> Ok(value)
  }
}

/// Create percentage value with validation (must be 0.0 to 1.0)
pub fn percentage(value: Float) -> Result(Percentage, String) {
  case value <. 0.0 || value >. 1.0 {
    True ->
      Error(
        "Percentage must be between 0.0 and 1.0, got " <> float_to_string(value),
      )
    False -> Ok(value)
  }
}

/// Create portion multiplier with validation (must be > 0)
pub fn portion_multiplier(value: Float) -> Result(PortionMultiplier, String) {
  case value <=. 0.0 {
    True ->
      Error(
        "PortionMultiplier must be positive, got " <> float_to_string(value),
      )
    False -> Ok(value)
  }
}

/// Create milligrams value with validation (must be >= 0)
pub fn milligrams(value: Float) -> Result(Milligrams, String) {
  case value <. 0.0 {
    True ->
      Error("Milligrams must be non-negative, got " <> float_to_string(value))
    False -> Ok(value)
  }
}

/// Create micrograms value with validation (must be >= 0)
pub fn micrograms(value: Float) -> Result(Micrograms, String) {
  case value <. 0.0 {
    True ->
      Error("Micrograms must be non-negative, got " <> float_to_string(value))
    False -> Ok(value)
  }
}

// ============================================================================
// Value Object Accessors
// ============================================================================

/// Get the underlying Float value from grams
pub fn grams_value(g: Grams) -> Float {
  g
}

/// Get the underlying Float value from calories
pub fn calories_value(c: Calories) -> Float {
  c
}

/// Get the underlying Float value from percentage
pub fn percentage_value(p: Percentage) -> Float {
  p
}

/// Get the underlying Float value from portion multiplier
pub fn portion_multiplier_value(m: PortionMultiplier) -> Float {
  m
}

/// Get the underlying Float value from milligrams
pub fn milligrams_value(mg: Milligrams) -> Float {
  mg
}

/// Get the underlying Float value from micrograms
pub fn micrograms_value(mcg: Micrograms) -> Float {
  mcg
}

// ============================================================================
// Display Formatting
// ============================================================================

/// Format grams for display (e.g., "25g")
pub fn grams_to_string(g: Grams) -> String {
  int_to_string(float_round(g)) <> "g"
}

/// Format calories for display (e.g., "200 cal")
pub fn calories_to_string(c: Calories) -> String {
  int_to_string(float_round(c)) <> " cal"
}

/// Format percentage for display (e.g., "35%")
pub fn percentage_to_string(p: Percentage) -> String {
  let percent = float_round(p *. 100.0)
  int_to_string(percent) <> "%"
}

/// Format portion multiplier for display (e.g., "1.5x")
pub fn portion_multiplier_to_string(m: PortionMultiplier) -> String {
  float_to_1_decimal(m) <> "x"
}

/// Format milligrams for display (e.g., "500mg")
pub fn milligrams_to_string(mg: Milligrams) -> String {
  int_to_string(float_round(mg)) <> "mg"
}

/// Format micrograms for display (e.g., "100mcg")
pub fn micrograms_to_string(mcg: Micrograms) -> String {
  int_to_string(float_round(mcg)) <> "mcg"
}

// ============================================================================
// Helper Functions
// ============================================================================

import gleam/float
import gleam/int

fn float_round(f: Float) -> Int {
  float.round(f)
}

fn float_to_string(f: Float) -> String {
  float.to_string(f)
}

fn int_to_string(i: Int) -> String {
  int.to_string(i)
}

fn float_to_1_decimal(f: Float) -> String {
  let whole = float.truncate(f)
  let frac = float.round({ f -. int_to_float(whole) } *. 10.0)
  int.to_string(whole) <> "." <> int.to_string(frac)
}

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float
