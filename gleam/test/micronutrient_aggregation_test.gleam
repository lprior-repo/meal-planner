/// Tests for micronutrient aggregation
/// Ensures all 21 micronutrients are correctly parsed and aggregated from USDA data
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/storage/nutrients
import meal_planner/types.{Micronutrients}

pub fn main() {
  gleeunit.main()
}

/// Test that parse_usda_micronutrients correctly extracts all 21 micronutrients
pub fn test_parse_all_21_micronutrients() {
  let nutrients = [
    nutrients.FoodNutrientValue("Fiber, total dietary", 2.5, "g"),
    nutrients.FoodNutrientValue("Sugars, total including NLEA", 10.0, "g"),
    nutrients.FoodNutrientValue("Sodium, Na", 200.0, "mg"),
    nutrients.FoodNutrientValue("Cholesterol", 50.0, "mg"),
    nutrients.FoodNutrientValue("Vitamin A, RAE", 500.0, "mcg"),
    nutrients.FoodNutrientValue("Vitamin C, total ascorbic acid", 20.0, "mg"),
    nutrients.FoodNutrientValue("Vitamin D (D2 + D3)", 10.0, "mcg"),
    nutrients.FoodNutrientValue("Vitamin E (alpha-tocopherol)", 5.0, "mg"),
    nutrients.FoodNutrientValue("Vitamin K (phylloquinone)", 15.0, "mcg"),
    nutrients.FoodNutrientValue("Vitamin B-6", 0.5, "mg"),
    nutrients.FoodNutrientValue("Vitamin B-12", 1.0, "mcg"),
    nutrients.FoodNutrientValue("Folate, total", 150.0, "mcg"),
    nutrients.FoodNutrientValue("Thiamin", 0.1, "mg"),
    nutrients.FoodNutrientValue("Riboflavin", 0.2, "mg"),
    nutrients.FoodNutrientValue("Niacin", 2.0, "mg"),
    nutrients.FoodNutrientValue("Calcium, Ca", 300.0, "mg"),
    nutrients.FoodNutrientValue("Iron, Fe", 2.0, "mg"),
    nutrients.FoodNutrientValue("Magnesium, Mg", 100.0, "mg"),
    nutrients.FoodNutrientValue("Phosphorus, P", 200.0, "mg"),
    nutrients.FoodNutrientValue("Potassium, K", 400.0, "mg"),
    nutrients.FoodNutrientValue("Zinc, Zn", 1.5, "mg"),
  ]

  let result = nutrients.parse_usda_micronutrients(nutrients)

  case result {
    Some(micros) -> {
      // Verify all 21 micronutrients are present
      micros.fiber |> should.equal(Some(2.5))
      micros.sugar |> should.equal(Some(10.0))
      micros.sodium |> should.equal(Some(200.0))
      micros.cholesterol |> should.equal(Some(50.0))
      micros.vitamin_a |> should.equal(Some(500.0))
      micros.vitamin_c |> should.equal(Some(20.0))
      micros.vitamin_d |> should.equal(Some(10.0))
      micros.vitamin_e |> should.equal(Some(5.0))
      micros.vitamin_k |> should.equal(Some(15.0))
      micros.vitamin_b6 |> should.equal(Some(0.5))
      micros.vitamin_b12 |> should.equal(Some(1.0))
      micros.folate |> should.equal(Some(150.0))
      micros.thiamin |> should.equal(Some(0.1))
      micros.riboflavin |> should.equal(Some(0.2))
      micros.niacin |> should.equal(Some(2.0))
      micros.calcium |> should.equal(Some(300.0))
      micros.iron |> should.equal(Some(2.0))
      micros.magnesium |> should.equal(Some(100.0))
      micros.phosphorus |> should.equal(Some(200.0))
      micros.potassium |> should.equal(Some(400.0))
      micros.zinc |> should.equal(Some(1.5))
    }
    None -> should.fail("Expected Some micronutrients, got None")
  }
}

/// Test that parse_usda_micronutrients returns None when no nutrients present
pub fn test_parse_empty_nutrients_returns_none() {
  let nutrients: List(nutrients.FoodNutrientValue) = []
  let result = nutrients.parse_usda_micronutrients(nutrients)
  result |> should.equal(None)
}

/// Test that parse_usda_micronutrients returns Some when at least one nutrient present
pub fn test_parse_single_nutrient_returns_some() {
  let nutrients = [
    nutrients.FoodNutrientValue("Calcium, Ca", 200.0, "mg"),
  ]

  let result = nutrients.parse_usda_micronutrients(nutrients)

  case result {
    Some(micros) -> {
      micros.calcium |> should.equal(Some(200.0))
      // Other micronutrients should be None
      micros.fiber |> should.equal(None)
      micros.sugar |> should.equal(None)
      micros.sodium |> should.equal(None)
    }
    None -> should.fail("Expected Some micronutrients, got None")
  }
}

/// Test that parse_usda_macros correctly extracts protein, fat, carbs
pub fn test_parse_usda_macros() {
  let nutrients = [
    nutrients.FoodNutrientValue("Protein", 20.0, "g"),
    nutrients.FoodNutrientValue("Total lipid (fat)", 10.0, "g"),
    nutrients.FoodNutrientValue("Carbohydrate, by difference", 50.0, "g"),
  ]

  let macros = nutrients.parse_usda_macros(nutrients)

  macros.protein |> should.equal(20.0)
  macros.fat |> should.equal(10.0)
  macros.carbs |> should.equal(50.0)
}

/// Test that parse_usda_macros defaults to 0.0 when nutrient not found
pub fn test_parse_usda_macros_missing_values() {
  let nutrients = [
    nutrients.FoodNutrientValue("Protein", 15.0, "g"),
  ]

  let macros = nutrients.parse_usda_macros(nutrients)

  macros.protein |> should.equal(15.0)
  macros.fat |> should.equal(0.0)
  macros.carbs |> should.equal(0.0)
}

/// Test partial micronutrient data (some nutrients missing)
pub fn test_parse_partial_micronutrients() {
  let nutrients = [
    nutrients.FoodNutrientValue("Calcium, Ca", 300.0, "mg"),
    nutrients.FoodNutrientValue("Iron, Fe", 2.0, "mg"),
    nutrients.FoodNutrientValue("Zinc, Zn", 1.5, "mg"),
  ]

  let result = nutrients.parse_usda_micronutrients(nutrients)

  case result {
    Some(micros) -> {
      // Present values
      micros.calcium |> should.equal(Some(300.0))
      micros.iron |> should.equal(Some(2.0))
      micros.zinc |> should.equal(Some(1.5))
      // Missing values should be None
      micros.fiber |> should.equal(None)
      micros.sugar |> should.equal(None)
      micros.sodium |> should.equal(None)
    }
    None -> should.fail("Expected Some micronutrients, got None")
  }
}

/// Test that micronutrient aggregation correctly sums multiple entries
pub fn test_micronutrient_summation() {
  let micros1 =
    Micronutrients(
      fiber: Some(2.0),
      sugar: Some(5.0),
      sodium: Some(100.0),
      cholesterol: Some(20.0),
      vitamin_a: Some(200.0),
      vitamin_c: Some(10.0),
      vitamin_d: Some(5.0),
      vitamin_e: Some(2.0),
      vitamin_k: Some(10.0),
      vitamin_b6: Some(0.3),
      vitamin_b12: Some(0.5),
      folate: Some(100.0),
      thiamin: Some(0.05),
      riboflavin: Some(0.1),
      niacin: Some(1.0),
      calcium: Some(150.0),
      iron: Some(1.0),
      magnesium: Some(50.0),
      phosphorus: Some(100.0),
      potassium: Some(200.0),
      zinc: Some(0.8),
    )

  let micros2 =
    Micronutrients(
      fiber: Some(1.5),
      sugar: Some(3.0),
      sodium: Some(50.0),
      cholesterol: Some(10.0),
      vitamin_a: Some(100.0),
      vitamin_c: Some(5.0),
      vitamin_d: Some(2.0),
      vitamin_e: Some(1.0),
      vitamin_k: Some(5.0),
      vitamin_b6: Some(0.2),
      vitamin_b12: Some(0.3),
      folate: Some(50.0),
      thiamin: Some(0.03),
      riboflavin: Some(0.05),
      niacin: Some(0.5),
      calcium: Some(100.0),
      iron: Some(0.8),
      magnesium: Some(30.0),
      phosphorus: Some(80.0),
      potassium: Some(150.0),
      zinc: Some(0.7),
    )

  let sum = types.micronutrients_add(micros1, micros2)

  sum.fiber |> should.equal(Some(3.5))
  sum.sugar |> should.equal(Some(8.0))
  sum.sodium |> should.equal(Some(150.0))
  sum.cholesterol |> should.equal(Some(30.0))
  sum.vitamin_a |> should.equal(Some(300.0))
  sum.calcium |> should.equal(Some(250.0))
  sum.iron |> should.equal(Some(1.8))
  sum.zinc |> should.equal(Some(1.5))
}

/// Test micronutrient addition with partial data
pub fn test_micronutrient_addition_with_missing_values() {
  let micros1 =
    Micronutrients(
      fiber: Some(2.0),
      sugar: None,
      sodium: Some(100.0),
      cholesterol: None,
      vitamin_a: Some(200.0),
      vitamin_c: None,
      vitamin_d: None,
      vitamin_e: None,
      vitamin_k: None,
      vitamin_b6: None,
      vitamin_b12: None,
      folate: None,
      thiamin: None,
      riboflavin: None,
      niacin: None,
      calcium: Some(150.0),
      iron: None,
      magnesium: None,
      phosphorus: None,
      potassium: None,
      zinc: None,
    )

  let micros2 =
    Micronutrients(
      fiber: None,
      sugar: Some(3.0),
      sodium: Some(50.0),
      cholesterol: Some(10.0),
      vitamin_a: None,
      vitamin_c: Some(5.0),
      vitamin_d: None,
      vitamin_e: None,
      vitamin_k: None,
      vitamin_b6: None,
      vitamin_b12: None,
      folate: None,
      thiamin: None,
      riboflavin: None,
      niacin: None,
      calcium: None,
      iron: Some(0.8),
      magnesium: None,
      phosphorus: None,
      potassium: None,
      zinc: None,
    )

  let sum = types.micronutrients_add(micros1, micros2)

  sum.fiber |> should.equal(Some(2.0))
  sum.sugar |> should.equal(Some(3.0))
  sum.sodium |> should.equal(Some(150.0))
  sum.cholesterol |> should.equal(Some(10.0))
  sum.vitamin_a |> should.equal(Some(200.0))
  sum.calcium |> should.equal(Some(150.0))
  sum.iron |> should.equal(Some(0.8))
}

/// Test scaling micronutrients (e.g., for servings)
pub fn test_micronutrient_scaling() {
  let micros =
    Micronutrients(
      fiber: Some(2.0),
      sugar: Some(10.0),
      sodium: Some(200.0),
      cholesterol: Some(50.0),
      vitamin_a: Some(500.0),
      vitamin_c: Some(20.0),
      vitamin_d: Some(10.0),
      vitamin_e: Some(5.0),
      vitamin_k: Some(15.0),
      vitamin_b6: Some(0.5),
      vitamin_b12: Some(1.0),
      folate: Some(150.0),
      thiamin: Some(0.1),
      riboflavin: Some(0.2),
      niacin: Some(2.0),
      calcium: Some(300.0),
      iron: Some(2.0),
      magnesium: Some(100.0),
      phosphorus: Some(200.0),
      potassium: Some(400.0),
      zinc: Some(1.5),
    )

  let scaled = types.micronutrients_scale(micros, 2.0)

  // All values should be doubled
  scaled.fiber |> should.equal(Some(4.0))
  scaled.sugar |> should.equal(Some(20.0))
  scaled.sodium |> should.equal(Some(400.0))
  scaled.calcium |> should.equal(Some(600.0))
  scaled.zinc |> should.equal(Some(3.0))
}

/// Test micronutrient scaling with missing values
pub fn test_micronutrient_scaling_with_missing_values() {
  let micros =
    Micronutrients(
      fiber: Some(2.0),
      sugar: None,
      sodium: Some(200.0),
      cholesterol: None,
      vitamin_a: Some(500.0),
      vitamin_c: None,
      vitamin_d: None,
      vitamin_e: None,
      vitamin_k: None,
      vitamin_b6: None,
      vitamin_b12: None,
      folate: None,
      thiamin: None,
      riboflavin: None,
      niacin: None,
      calcium: Some(300.0),
      iron: None,
      magnesium: None,
      phosphorus: None,
      potassium: None,
      zinc: None,
    )

  let scaled = types.micronutrients_scale(micros, 1.5)

  scaled.fiber |> should.equal(Some(3.0))
  scaled.sugar |> should.equal(None)
  scaled.sodium |> should.equal(Some(300.0))
  scaled.calcium |> should.equal(Some(450.0))
}

/// Test micronutrient summing across multiple entries
pub fn test_micronutrient_list_summation() {
  let entry1 =
    Micronutrients(
      fiber: Some(2.0),
      sugar: Some(5.0),
      sodium: Some(100.0),
      cholesterol: Some(20.0),
      vitamin_a: Some(200.0),
      vitamin_c: Some(10.0),
      vitamin_d: Some(5.0),
      vitamin_e: Some(2.0),
      vitamin_k: Some(10.0),
      vitamin_b6: Some(0.3),
      vitamin_b12: Some(0.5),
      folate: Some(100.0),
      thiamin: Some(0.05),
      riboflavin: Some(0.1),
      niacin: Some(1.0),
      calcium: Some(150.0),
      iron: Some(1.0),
      magnesium: Some(50.0),
      phosphorus: Some(100.0),
      potassium: Some(200.0),
      zinc: Some(0.8),
    )

  let entry2 =
    Micronutrients(
      fiber: Some(1.5),
      sugar: Some(3.0),
      sodium: Some(50.0),
      cholesterol: Some(10.0),
      vitamin_a: Some(100.0),
      vitamin_c: Some(5.0),
      vitamin_d: Some(2.0),
      vitamin_e: Some(1.0),
      vitamin_k: Some(5.0),
      vitamin_b6: Some(0.2),
      vitamin_b12: Some(0.3),
      folate: Some(50.0),
      thiamin: Some(0.03),
      riboflavin: Some(0.05),
      niacin: Some(0.5),
      calcium: Some(100.0),
      iron: Some(0.8),
      magnesium: Some(30.0),
      phosphorus: Some(80.0),
      potassium: Some(150.0),
      zinc: Some(0.7),
    )

  let entries = [entry1, entry2]
  let sum = types.micronutrients_sum(entries)

  sum.fiber |> should.equal(Some(3.5))
  sum.sodium |> should.equal(Some(150.0))
  sum.calcium |> should.equal(Some(250.0))
  sum.zinc |> should.equal(Some(1.5))
}
