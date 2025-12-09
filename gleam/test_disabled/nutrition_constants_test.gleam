import gleeunit
import gleeunit/should
import meal_planner/nutrition_constants

pub fn main() {
  gleeunit.main()
}

// Test default calorie target constant
pub fn default_calorie_target_test() {
  nutrition_constants.default_calorie_target
  |> should.equal(2000.0)
}

// Test recommended protein constant
pub fn recommended_protein_g_test() {
  nutrition_constants.recommended_protein_g
  |> should.equal(150.0)
}

// Test recommended fat constant
pub fn recommended_fat_g_test() {
  nutrition_constants.recommended_fat_g
  |> should.equal(50.0)
}

// Test recommended carbs constant
pub fn recommended_carbs_g_test() {
  nutrition_constants.recommended_carbs_g
  |> should.equal(200.0)
}

// Test micronutrient count constant
pub fn micronutrient_count_test() {
  nutrition_constants.micronutrient_count
  |> should.equal(21)
}

// Test quality threshold constant
pub fn quality_threshold_test() {
  nutrition_constants.quality_threshold
  |> should.equal(0.95)
}

// Test that constants are accessible and have correct types
pub fn all_constants_accessible_test() {
  let _calories = nutrition_constants.default_calorie_target
  let _protein = nutrition_constants.recommended_protein_g
  let _fat = nutrition_constants.recommended_fat_g
  let _carbs = nutrition_constants.recommended_carbs_g
  let _micronutrients = nutrition_constants.micronutrient_count
  let _quality = nutrition_constants.quality_threshold

  True
  |> should.be_true()
}
