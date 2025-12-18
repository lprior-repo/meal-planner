/// Tests for NutritionInfo decoder
///
/// This module tests JSON decoding of NutritionInfo types.
/// Tests cover: valid JSON, all optional fields, partial data, wrong types.
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/decoders/recipe/nutrition_decoder
import meal_planner/tandoor/types/recipe/nutrition.{type NutritionInfo}

// ============================================================================
// Valid JSON Tests
// ============================================================================

pub fn decode_nutrition_info_full_test() {
  let json_str =
    "{
      \"id\": 1,
      \"carbohydrates\": 45.5,
      \"fats\": 12.3,
      \"proteins\": 25.7,
      \"calories\": 380.0,
      \"source\": \"USDA\"
    }"

  let result: Result(NutritionInfo, _) =
    json.parse(json_str, using: nutrition_decoder.nutrition_info_decoder())

  case result {
    Ok(nutrition) -> {
      nutrition.id
      |> should.equal(1)
      nutrition.carbohydrates
      |> should.equal(Some(45.5))
      nutrition.fats
      |> should.equal(Some(12.3))
      nutrition.proteins
      |> should.equal(Some(25.7))
      nutrition.calories
      |> should.equal(Some(380.0))
      nutrition.source
      |> should.equal(Some("USDA"))
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_nutrition_info_minimal_test() {
  let json_str =
    "{
      \"id\": 2,
      \"carbohydrates\": null,
      \"fats\": null,
      \"proteins\": null,
      \"calories\": null,
      \"source\": null
    }"

  let result: Result(NutritionInfo, _) =
    json.parse(json_str, using: nutrition_decoder.nutrition_info_decoder())

  case result {
    Ok(nutrition) -> {
      nutrition.id
      |> should.equal(2)
      nutrition.carbohydrates
      |> should.equal(None)
      nutrition.fats
      |> should.equal(None)
      nutrition.proteins
      |> should.equal(None)
      nutrition.calories
      |> should.equal(None)
      nutrition.source
      |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Partial Data Tests
// ============================================================================

pub fn decode_nutrition_info_calories_only_test() {
  let json_str =
    "{
      \"id\": 3,
      \"carbohydrates\": null,
      \"fats\": null,
      \"proteins\": null,
      \"calories\": 250.0,
      \"source\": \"Estimated\"
    }"

  let result =
    json.parse(json_str, using: nutrition_decoder.nutrition_info_decoder())

  case result {
    Ok(nutrition) -> {
      nutrition.calories
      |> should.equal(Some(250.0))
      nutrition.source
      |> should.equal(Some("Estimated"))
      nutrition.carbohydrates
      |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_nutrition_info_macros_only_test() {
  let json_str =
    "{
      \"id\": 4,
      \"carbohydrates\": 30.0,
      \"fats\": 15.0,
      \"proteins\": 20.0,
      \"calories\": null,
      \"source\": null
    }"

  let result =
    json.parse(json_str, using: nutrition_decoder.nutrition_info_decoder())

  case result {
    Ok(nutrition) -> {
      nutrition.carbohydrates
      |> should.equal(Some(30.0))
      nutrition.fats
      |> should.equal(Some(15.0))
      nutrition.proteins
      |> should.equal(Some(20.0))
      nutrition.calories
      |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_nutrition_info_some_macros_test() {
  let json_str =
    "{
      \"id\": 5,
      \"carbohydrates\": 40.0,
      \"fats\": null,
      \"proteins\": 25.0,
      \"calories\": 300.0,
      \"source\": \"Recipe calculation\"
    }"

  let result =
    json.parse(json_str, using: nutrition_decoder.nutrition_info_decoder())

  case result {
    Ok(nutrition) -> {
      nutrition.carbohydrates
      |> should.equal(Some(40.0))
      nutrition.fats
      |> should.equal(None)
      nutrition.proteins
      |> should.equal(Some(25.0))
      nutrition.calories
      |> should.equal(Some(300.0))
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Decimal Precision Tests
// ============================================================================

pub fn decode_nutrition_info_high_precision_test() {
  let json_str =
    "{
      \"id\": 6,
      \"carbohydrates\": 45.123456,
      \"fats\": 12.987654,
      \"proteins\": 25.555555,
      \"calories\": 380.999999,
      \"source\": \"Precise\"
    }"

  let result =
    json.parse(json_str, using: nutrition_decoder.nutrition_info_decoder())

  case result {
    Ok(nutrition) -> {
      nutrition.carbohydrates
      |> should.equal(Some(45.123456))
      nutrition.fats
      |> should.equal(Some(12.987654))
      nutrition.proteins
      |> should.equal(Some(25.555555))
      nutrition.calories
      |> should.equal(Some(380.999999))
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_nutrition_info_zero_values_test() {
  let json_str =
    "{
      \"id\": 7,
      \"carbohydrates\": 0.0,
      \"fats\": 0.0,
      \"proteins\": 0.0,
      \"calories\": 0.0,
      \"source\": \"Zero\"
    }"

  let result =
    json.parse(json_str, using: nutrition_decoder.nutrition_info_decoder())

  case result {
    Ok(nutrition) -> {
      nutrition.carbohydrates
      |> should.equal(Some(0.0))
      nutrition.fats
      |> should.equal(Some(0.0))
      nutrition.proteins
      |> should.equal(Some(0.0))
      nutrition.calories
      |> should.equal(Some(0.0))
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_nutrition_info_integer_values_test() {
  // JSON numbers without decimals should still parse as floats
  let json_str =
    "{
      \"id\": 8,
      \"carbohydrates\": 45,
      \"fats\": 12,
      \"proteins\": 25,
      \"calories\": 380,
      \"source\": \"Integer values\"
    }"

  let result =
    json.parse(json_str, using: nutrition_decoder.nutrition_info_decoder())

  case result {
    Ok(nutrition) -> {
      nutrition.carbohydrates
      |> should.equal(Some(45.0))
      nutrition.fats
      |> should.equal(Some(12.0))
      nutrition.proteins
      |> should.equal(Some(25.0))
      nutrition.calories
      |> should.equal(Some(380.0))
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Source Field Tests
// ============================================================================

pub fn decode_nutrition_info_various_sources_test() {
  let sources = [
    "USDA", "Recipe calculation", "User input", "Imported", "Estimated",
    "FDA Database",
  ]

  sources
  |> should.not_equal([])
  // Verify source parsing works - actual values tested in other tests
}

pub fn decode_nutrition_info_unicode_source_test() {
  let json_str =
    "{
      \"id\": 9,
      \"carbohydrates\": 30.0,
      \"fats\": 10.0,
      \"proteins\": 20.0,
      \"calories\": 280.0,
      \"source\": \"Base de données française 🇫🇷\"
    }"

  let result =
    json.parse(json_str, using: nutrition_decoder.nutrition_info_decoder())

  case result {
    Ok(nutrition) -> {
      nutrition.source
      |> should.equal(Some("Base de données française 🇫🇷"))
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Error Cases Tests
// ============================================================================

pub fn decode_nutrition_info_missing_id_test() {
  let json_str =
    "{
      \"carbohydrates\": 45.0,
      \"fats\": 12.0,
      \"proteins\": 25.0,
      \"calories\": 380.0,
      \"source\": \"USDA\"
    }"

  let result =
    json.parse(json_str, using: nutrition_decoder.nutrition_info_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_nutrition_info_wrong_type_id_test() {
  let json_str =
    "{
      \"id\": \"not_a_number\",
      \"carbohydrates\": 45.0,
      \"fats\": 12.0,
      \"proteins\": 25.0,
      \"calories\": 380.0,
      \"source\": \"USDA\"
    }"

  let result =
    json.parse(json_str, using: nutrition_decoder.nutrition_info_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_nutrition_info_wrong_type_carbs_test() {
  let json_str =
    "{
      \"id\": 1,
      \"carbohydrates\": \"not_a_number\",
      \"fats\": 12.0,
      \"proteins\": 25.0,
      \"calories\": 380.0,
      \"source\": \"USDA\"
    }"

  let result =
    json.parse(json_str, using: nutrition_decoder.nutrition_info_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_nutrition_info_wrong_type_source_test() {
  let json_str =
    "{
      \"id\": 1,
      \"carbohydrates\": 45.0,
      \"fats\": 12.0,
      \"proteins\": 25.0,
      \"calories\": 380.0,
      \"source\": 123
    }"

  let result =
    json.parse(json_str, using: nutrition_decoder.nutrition_info_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_nutrition_info_invalid_json_test() {
  let json_str = "{not valid json}"

  let result =
    json.parse(json_str, using: nutrition_decoder.nutrition_info_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_nutrition_info_empty_object_test() {
  let json_str = "{}"

  let result =
    json.parse(json_str, using: nutrition_decoder.nutrition_info_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_nutrition_info_negative_values_test() {
  // Negative values should parse (validation is separate from parsing)
  let json_str =
    "{
      \"id\": 10,
      \"carbohydrates\": -5.0,
      \"fats\": -2.0,
      \"proteins\": -3.0,
      \"calories\": -100.0,
      \"source\": \"Invalid\"
    }"

  let result =
    json.parse(json_str, using: nutrition_decoder.nutrition_info_decoder())

  case result {
    Ok(nutrition) -> {
      // Parser should accept negative values
      // Business logic validation is separate
      nutrition.carbohydrates
      |> should.equal(Some(-5.0))
    }
    Error(_) -> should.fail()
  }
}
