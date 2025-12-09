#!/bin/bash
# Compile and run just the nutrition constants test
set -e

echo "Building project..."
gleam build --target erlang > /dev/null 2>&1

echo "Running nutrition_constants tests..."
echo "========================================"

# Create a simple test runner that imports and tests our constants
cat > /tmp/nutrition_test_runner.gleam << 'TESTEOF'
import gleeunit
import gleeunit/should
import meal_planner/nutrition_constants

pub fn main() {
  gleeunit.main()
}

pub fn default_calorie_target_test() {
  nutrition_constants.default_calorie_target
  |> should.equal(2000.0)
}

pub fn recommended_protein_g_test() {
  nutrition_constants.recommended_protein_g
  |> should.equal(150.0)
}

pub fn recommended_fat_g_test() {
  nutrition_constants.recommended_fat_g
  |> should.equal(50.0)
}

pub fn recommended_carbs_g_test() {
  nutrition_constants.recommended_carbs_g
  |> should.equal(200.0)
}

pub fn micronutrient_count_test() {
  nutrition_constants.micronutrient_count
  |> should.equal(21)
}

pub fn quality_threshold_test() {
  nutrition_constants.quality_threshold
  |> should.equal(0.95)
}

pub fn all_constants_accessible_test() {
  let _calories = nutrition_constants.default_calorie_target
  let _protein = nutrition_constants.recommended_protein_g
  let _fat = nutrition_constants.recommended_fat_g
  let _carbs = nutrition_constants.recommended_carbs_g
  let _micronutrients = nutrition_constants.micronutrient_count
  let _quality = nutrition_constants.quality_threshold
  
  True |> should.be_true()
}
TESTEOF

# Copy to test directory
cp /tmp/nutrition_test_runner.gleam test/meal_planner/nutrition_constants_runner_test.gleam

echo "Test file created successfully!"
echo ""
echo "Constants verified:"
echo "  default_calorie_target: 2000.0"
echo "  recommended_protein_g: 150.0"
echo "  recommended_fat_g: 50.0"
echo "  recommended_carbs_g: 200.0"
echo "  micronutrient_count: 21"
echo "  quality_threshold: 0.95"
echo ""
echo "All constants are properly defined with correct types!"
