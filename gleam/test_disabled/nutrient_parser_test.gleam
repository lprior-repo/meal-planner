/// Tests for nutrient_parser module
/// Comprehensive test coverage for USDA nutrient parsing
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/nutrient_parser.{type UsdaNutrient, UsdaNutrient}

// ============================================================================
// Test Fixtures
// ============================================================================

fn make_nutrient(name: String, amount: Float, unit: String) -> UsdaNutrient {
  UsdaNutrient(name: name, amount: amount, unit: unit)
}

// ============================================================================
// Complete Nutrient Profile Tests
// ============================================================================

pub fn parse_complete_nutrient_profile_test() {
  // Test with all macros and micronutrients present
  let nutrients = [
    make_nutrient("Protein", 25.0, "g"),
    make_nutrient("Total lipid (fat)", 10.0, "g"),
    make_nutrient("Carbohydrate, by difference", 40.0, "g"),
    make_nutrient("Energy", 350.0, "kcal"),
    make_nutrient("Fiber, total dietary", 5.0, "g"),
    make_nutrient("Sugars, total", 8.0, "g"),
    make_nutrient("Sodium, Na", 200.0, "mg"),
    make_nutrient("Cholesterol", 50.0, "mg"),
    make_nutrient("Vitamin A, RAE", 500.0, "ug"),
    make_nutrient("Vitamin C, total ascorbic acid", 60.0, "mg"),
    make_nutrient("Vitamin D", 10.0, "ug"),
    make_nutrient("Vitamin E (alpha-tocopherol)", 8.0, "mg"),
    make_nutrient("Vitamin K", 80.0, "ug"),
    make_nutrient("Vitamin B-6", 1.5, "mg"),
    make_nutrient("Vitamin B-12", 2.5, "ug"),
    make_nutrient("Folate, total", 200.0, "ug"),
    make_nutrient("Thiamin", 1.0, "mg"),
    make_nutrient("Riboflavin", 1.2, "mg"),
    make_nutrient("Niacin", 15.0, "mg"),
    make_nutrient("Calcium, Ca", 300.0, "mg"),
    make_nutrient("Iron, Fe", 10.0, "mg"),
    make_nutrient("Magnesium, Mg", 100.0, "mg"),
    make_nutrient("Phosphorus, P", 250.0, "mg"),
    make_nutrient("Potassium, K", 400.0, "mg"),
    make_nutrient("Zinc, Zn", 8.0, "mg"),
  ]

  let #(macros, micronutrients, calories) =
    nutrient_parser.parse_usda_nutrients(nutrients)

  // Verify macros
  macros.protein
  |> should.equal(25.0)

  macros.fat
  |> should.equal(10.0)

  macros.carbs
  |> should.equal(40.0)

  // Verify calories
  calories
  |> should.equal(Some(350.0))

  // Verify micronutrients are present
  case micronutrients {
    None -> should.fail()
    Some(micros) -> {
      micros.fiber
      |> should.equal(Some(5.0))

      micros.sugar
      |> should.equal(Some(8.0))

      micros.sodium
      |> should.equal(Some(200.0))

      micros.vitamin_c
      |> should.equal(Some(60.0))

      micros.calcium
      |> should.equal(Some(300.0))

      micros.iron
      |> should.equal(Some(10.0))
    }
  }
}

// ============================================================================
// Minimal Nutrient Profile Tests
// ============================================================================

pub fn parse_minimal_macros_only_test() {
  // Test with only required macros, no micronutrients
  let nutrients = [
    make_nutrient("Protein", 20.0, "g"),
    make_nutrient("Total lipid (fat)", 5.0, "g"),
    make_nutrient("Carbohydrate, by difference", 30.0, "g"),
  ]

  let #(macros, micronutrients, calories) =
    nutrient_parser.parse_usda_nutrients(nutrients)

  // Verify macros
  macros.protein
  |> should.equal(20.0)

  macros.fat
  |> should.equal(5.0)

  macros.carbs
  |> should.equal(30.0)

  // No calories
  calories
  |> should.equal(None)

  // No micronutrients
  micronutrients
  |> should.equal(None)
}

pub fn parse_missing_macros_defaults_to_zero_test() {
  // Test with missing macro fields - should default to 0.0
  let nutrients = [
    make_nutrient("Protein", 15.0, "g"),
    // Missing fat and carbs
  ]

  let #(macros, _micronutrients, _calories) =
    nutrient_parser.parse_usda_nutrients(nutrients)

  macros.protein
  |> should.equal(15.0)

  macros.fat
  |> should.equal(0.0)

  macros.carbs
  |> should.equal(0.0)
}

// ============================================================================
// Partial Micronutrient Tests
// ============================================================================

pub fn parse_partial_micronutrients_test() {
  // Test with only some micronutrients
  let nutrients = [
    make_nutrient("Protein", 30.0, "g"),
    make_nutrient("Total lipid (fat)", 15.0, "g"),
    make_nutrient("Carbohydrate, by difference", 10.0, "g"),
    make_nutrient("Fiber, total dietary", 3.0, "g"),
    make_nutrient("Vitamin C, total ascorbic acid", 45.0, "mg"),
    make_nutrient("Iron, Fe", 5.0, "mg"),
  ]

  let #(_macros, micronutrients, _calories) =
    nutrient_parser.parse_usda_nutrients(nutrients)

  // Micronutrients should exist
  case micronutrients {
    None -> should.fail()
    Some(micros) -> {
      // Present fields
      micros.fiber
      |> should.equal(Some(3.0))

      micros.vitamin_c
      |> should.equal(Some(45.0))

      micros.iron
      |> should.equal(Some(5.0))

      // Missing fields should be None
      micros.sugar
      |> should.equal(None)

      micros.sodium
      |> should.equal(None)

      micros.vitamin_a
      |> should.equal(None)
    }
  }
}

// ============================================================================
// Case-Insensitive Name Matching Tests
// ============================================================================

pub fn parse_case_insensitive_names_test() {
  // Test that nutrient name matching is case-insensitive
  let nutrients = [
    make_nutrient("PROTEIN", 25.0, "g"),
    make_nutrient("total LIPID (fat)", 10.0, "g"),
    make_nutrient("carbohydrate, BY DIFFERENCE", 40.0, "g"),
  ]

  let #(macros, _micronutrients, _calories) =
    nutrient_parser.parse_usda_nutrients(nutrients)

  macros.protein
  |> should.equal(25.0)

  macros.fat
  |> should.equal(10.0)

  macros.carbs
  |> should.equal(40.0)
}

// ============================================================================
// Partial Name Matching Tests
// ============================================================================

pub fn parse_partial_name_match_test() {
  // Test that partial name matching works
  let nutrients = [
    make_nutrient("Protein (total)", 22.0, "g"),
    make_nutrient("Total lipid (fat) [calculated]", 12.0, "g"),
    make_nutrient("Carbohydrate, by difference (estimate)", 35.0, "g"),
  ]

  let #(macros, _micronutrients, _calories) =
    nutrient_parser.parse_usda_nutrients(nutrients)

  macros.protein
  |> should.equal(22.0)

  macros.fat
  |> should.equal(12.0)

  macros.carbs
  |> should.equal(35.0)
}

// ============================================================================
// Edge Case Tests
// ============================================================================

pub fn parse_empty_nutrient_list_test() {
  // Test with empty nutrient list
  let nutrients = []

  let #(macros, micronutrients, calories) =
    nutrient_parser.parse_usda_nutrients(nutrients)

  // All macros should be 0.0
  macros.protein
  |> should.equal(0.0)

  macros.fat
  |> should.equal(0.0)

  macros.carbs
  |> should.equal(0.0)

  // No calories or micronutrients
  calories
  |> should.equal(None)

  micronutrients
  |> should.equal(None)
}

pub fn parse_zero_values_test() {
  // Test with zero values
  let nutrients = [
    make_nutrient("Protein", 0.0, "g"),
    make_nutrient("Total lipid (fat)", 0.0, "g"),
    make_nutrient("Carbohydrate, by difference", 0.0, "g"),
    make_nutrient("Fiber, total dietary", 0.0, "g"),
  ]

  let #(macros, micronutrients, _calories) =
    nutrient_parser.parse_usda_nutrients(nutrients)

  // Zero macros are valid
  macros.protein
  |> should.equal(0.0)

  macros.fat
  |> should.equal(0.0)

  macros.carbs
  |> should.equal(0.0)

  // Micronutrients should exist (fiber is Some(0.0))
  case micronutrients {
    None -> should.fail()
    Some(micros) -> {
      micros.fiber
      |> should.equal(Some(0.0))
    }
  }
}

pub fn parse_very_small_values_test() {
  // Test with trace amounts (< 1.0)
  let nutrients = [
    make_nutrient("Protein", 0.5, "g"),
    make_nutrient("Total lipid (fat)", 0.2, "g"),
    make_nutrient("Carbohydrate, by difference", 0.8, "g"),
    make_nutrient("Vitamin B-12", 0.1, "ug"),
  ]

  let #(macros, micronutrients, _calories) =
    nutrient_parser.parse_usda_nutrients(nutrients)

  macros.protein
  |> should.equal(0.5)

  macros.fat
  |> should.equal(0.2)

  case micronutrients {
    None -> should.fail()
    Some(micros) -> {
      micros.vitamin_b12
      |> should.equal(Some(0.1))
    }
  }
}

pub fn parse_very_large_values_test() {
  // Test with very large values
  let nutrients = [
    make_nutrient("Protein", 100.0, "g"),
    make_nutrient("Total lipid (fat)", 80.0, "g"),
    make_nutrient("Carbohydrate, by difference", 200.0, "g"),
    make_nutrient("Sodium, Na", 5000.0, "mg"),
  ]

  let #(macros, micronutrients, _calories) =
    nutrient_parser.parse_usda_nutrients(nutrients)

  macros.protein
  |> should.equal(100.0)

  macros.fat
  |> should.equal(80.0)

  macros.carbs
  |> should.equal(200.0)

  case micronutrients {
    None -> should.fail()
    Some(micros) -> {
      micros.sodium
      |> should.equal(Some(5000.0))
    }
  }
}

// ============================================================================
// Duplicate Nutrient Name Tests
// ============================================================================

pub fn parse_duplicate_names_uses_first_test() {
  // Test that when duplicate names exist, first one is used
  let nutrients = [
    make_nutrient("Protein", 20.0, "g"),
    make_nutrient("Protein", 30.0, "g"),
    // Duplicate - should be ignored
    make_nutrient("Total lipid (fat)", 10.0, "g"),
    make_nutrient("Carbohydrate, by difference", 40.0, "g"),
  ]

  let #(macros, _micronutrients, _calories) =
    nutrient_parser.parse_usda_nutrients(nutrients)

  // Should use first protein value
  macros.protein
  |> should.equal(20.0)
}

// ============================================================================
// Specific Micronutrient Tests
// ============================================================================

pub fn parse_b_vitamins_test() {
  // Test all B vitamins are parsed correctly
  let nutrients = [
    make_nutrient("Protein", 10.0, "g"),
    make_nutrient("Total lipid (fat)", 5.0, "g"),
    make_nutrient("Carbohydrate, by difference", 20.0, "g"),
    make_nutrient("Vitamin B-6", 1.8, "mg"),
    make_nutrient("Vitamin B-12", 2.2, "ug"),
    make_nutrient("Folate, total", 180.0, "ug"),
    make_nutrient("Thiamin", 0.9, "mg"),
    make_nutrient("Riboflavin", 1.1, "mg"),
    make_nutrient("Niacin", 12.0, "mg"),
  ]

  let #(_macros, micronutrients, _calories) =
    nutrient_parser.parse_usda_nutrients(nutrients)

  case micronutrients {
    None -> should.fail()
    Some(micros) -> {
      micros.vitamin_b6
      |> should.equal(Some(1.8))

      micros.vitamin_b12
      |> should.equal(Some(2.2))

      micros.folate
      |> should.equal(Some(180.0))

      micros.thiamin
      |> should.equal(Some(0.9))

      micros.riboflavin
      |> should.equal(Some(1.1))

      micros.niacin
      |> should.equal(Some(12.0))
    }
  }
}

pub fn parse_minerals_test() {
  // Test all minerals are parsed correctly
  let nutrients = [
    make_nutrient("Protein", 10.0, "g"),
    make_nutrient("Total lipid (fat)", 5.0, "g"),
    make_nutrient("Carbohydrate, by difference", 20.0, "g"),
    make_nutrient("Calcium, Ca", 250.0, "mg"),
    make_nutrient("Iron, Fe", 8.0, "mg"),
    make_nutrient("Magnesium, Mg", 90.0, "mg"),
    make_nutrient("Phosphorus, P", 200.0, "mg"),
    make_nutrient("Potassium, K", 350.0, "mg"),
    make_nutrient("Zinc, Zn", 7.0, "mg"),
    make_nutrient("Sodium, Na", 150.0, "mg"),
  ]

  let #(_macros, micronutrients, _calories) =
    nutrient_parser.parse_usda_nutrients(nutrients)

  case micronutrients {
    None -> should.fail()
    Some(micros) -> {
      micros.calcium
      |> should.equal(Some(250.0))

      micros.iron
      |> should.equal(Some(8.0))

      micros.magnesium
      |> should.equal(Some(90.0))

      micros.phosphorus
      |> should.equal(Some(200.0))

      micros.potassium
      |> should.equal(Some(350.0))

      micros.zinc
      |> should.equal(Some(7.0))

      micros.sodium
      |> should.equal(Some(150.0))
    }
  }
}

pub fn parse_fat_soluble_vitamins_test() {
  // Test fat-soluble vitamins (A, D, E, K)
  let nutrients = [
    make_nutrient("Protein", 10.0, "g"),
    make_nutrient("Total lipid (fat)", 5.0, "g"),
    make_nutrient("Carbohydrate, by difference", 20.0, "g"),
    make_nutrient("Vitamin A, RAE", 600.0, "ug"),
    make_nutrient("Vitamin D", 15.0, "ug"),
    make_nutrient("Vitamin E (alpha-tocopherol)", 10.0, "mg"),
    make_nutrient("Vitamin K", 120.0, "ug"),
  ]

  let #(_macros, micronutrients, _calories) =
    nutrient_parser.parse_usda_nutrients(nutrients)

  case micronutrients {
    None -> should.fail()
    Some(micros) -> {
      micros.vitamin_a
      |> should.equal(Some(600.0))

      micros.vitamin_d
      |> should.equal(Some(15.0))

      micros.vitamin_e
      |> should.equal(Some(10.0))

      micros.vitamin_k
      |> should.equal(Some(120.0))
    }
  }
}

// ============================================================================
// Energy (Calories) Tests
// ============================================================================

pub fn parse_energy_with_kcal_test() {
  // Test energy parsing
  let nutrients = [
    make_nutrient("Protein", 20.0, "g"),
    make_nutrient("Total lipid (fat)", 10.0, "g"),
    make_nutrient("Carbohydrate, by difference", 30.0, "g"),
    make_nutrient("Energy", 300.0, "kcal"),
  ]

  let #(_macros, _micronutrients, calories) =
    nutrient_parser.parse_usda_nutrients(nutrients)

  calories
  |> should.equal(Some(300.0))
}

pub fn parse_no_energy_test() {
  // Test when energy is not provided
  let nutrients = [
    make_nutrient("Protein", 20.0, "g"),
    make_nutrient("Total lipid (fat)", 10.0, "g"),
    make_nutrient("Carbohydrate, by difference", 30.0, "g"),
  ]

  let #(_macros, _micronutrients, calories) =
    nutrient_parser.parse_usda_nutrients(nutrients)

  calories
  |> should.equal(None)
}
