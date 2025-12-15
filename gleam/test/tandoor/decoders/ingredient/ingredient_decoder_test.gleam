/// Tests for Ingredient decoder
///
/// This module tests JSON decoding of Ingredient types.
/// Tests cover: valid JSON, nested objects, optional fields, missing fields, wrong types.
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/decoders/ingredient/ingredient_decoder
import meal_planner/tandoor/types/recipe/ingredient.{type Ingredient}

// ============================================================================
// Valid JSON Tests
// ============================================================================

pub fn decode_ingredient_full_test() {
  let json_str =
    "{
      \"id\": 1,
      \"food\": {
        \"id\": 5,
        \"name\": \"Tomato\",
        \"plural_name\": \"Tomatoes\",
        \"description\": \"Fresh red tomatoes\",
        \"recipe\": null,
        \"food_onhand\": true,
        \"supermarket_category\": null,
        \"ignore_shopping\": false
      },
      \"unit\": {
        \"id\": 2,
        \"name\": \"gram\",
        \"plural_name\": \"grams\",
        \"description\": \"Metric unit\",
        \"base_unit\": null,
        \"open_data_slug\": null
      },
      \"amount\": 250.0,
      \"note\": \"diced\",
      \"order\": 1,
      \"is_header\": false,
      \"no_amount\": false,
      \"original_text\": \"250g tomatoes, diced\"
    }"

  let result: Result(Ingredient, _) =
    json.parse(json_str, using: ingredient_decoder.ingredient_decoder())

  case result {
    Ok(ingredient) -> {
      ingredient.id
      |> should.equal(1)
      ingredient.amount
      |> should.equal(250.0)
      ingredient.note
      |> should.equal(Some("diced"))
      ingredient.order
      |> should.equal(1)
      ingredient.is_header
      |> should.equal(False)
      ingredient.no_amount
      |> should.equal(False)
      ingredient.original_text
      |> should.equal(Some("250g tomatoes, diced"))

      case ingredient.food {
        Some(food) -> {
          food.id
          |> should.equal(5)
          food.name
          |> should.equal("Tomato")
        }
        None -> should.fail()
      }

      case ingredient.unit {
        Some(unit) -> {
          unit.id
          |> should.equal(2)
          unit.name
          |> should.equal("gram")
        }
        None -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_ingredient_minimal_test() {
  let json_str =
    "{
      \"id\": 2,
      \"food\": null,
      \"unit\": null,
      \"amount\": 0.0,
      \"note\": null,
      \"order\": 0,
      \"is_header\": false,
      \"no_amount\": true,
      \"original_text\": null
    }"

  let result: Result(Ingredient, _) =
    json.parse(json_str, using: ingredient_decoder.ingredient_decoder())

  case result {
    Ok(ingredient) -> {
      ingredient.id
      |> should.equal(2)
      ingredient.food
      |> should.equal(None)
      ingredient.unit
      |> should.equal(None)
      ingredient.amount
      |> should.equal(0.0)
      ingredient.note
      |> should.equal(None)
      ingredient.no_amount
      |> should.equal(True)
      ingredient.original_text
      |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Nested Objects Tests
// ============================================================================

pub fn decode_ingredient_with_food_only_test() {
  let json_str =
    "{
      \"id\": 3,
      \"food\": {
        \"id\": 10,
        \"name\": \"Garlic\",
        \"plural_name\": null,
        \"description\": \"\",
        \"recipe\": null,
        \"food_onhand\": null,
        \"supermarket_category\": null,
        \"ignore_shopping\": false
      },
      \"unit\": null,
      \"amount\": 2.0,
      \"note\": \"cloves\",
      \"order\": 2,
      \"is_header\": false,
      \"no_amount\": false,
      \"original_text\": \"2 cloves garlic\"
    }"

  let result =
    json.parse(json_str, using: ingredient_decoder.ingredient_decoder())

  case result {
    Ok(ingredient) -> {
      case ingredient.food {
        Some(food) -> {
          food.id
          |> should.equal(10)
          food.name
          |> should.equal("Garlic")
        }
        None -> should.fail()
      }
      ingredient.unit
      |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_ingredient_with_unit_only_test() {
  let json_str =
    "{
      \"id\": 4,
      \"food\": null,
      \"unit\": {
        \"id\": 3,
        \"name\": \"cup\",
        \"plural_name\": \"cups\",
        \"description\": \"US cup\",
        \"base_unit\": null,
        \"open_data_slug\": null
      },
      \"amount\": 1.5,
      \"note\": null,
      \"order\": 1,
      \"is_header\": false,
      \"no_amount\": false,
      \"original_text\": null
    }"

  let result =
    json.parse(json_str, using: ingredient_decoder.ingredient_decoder())

  case result {
    Ok(ingredient) -> {
      ingredient.food
      |> should.equal(None)
      case ingredient.unit {
        Some(unit) -> {
          unit.id
          |> should.equal(3)
          unit.name
          |> should.equal("cup")
        }
        None -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Header/Special Cases Tests
// ============================================================================

pub fn decode_ingredient_as_header_test() {
  let json_str =
    "{
      \"id\": 5,
      \"food\": null,
      \"unit\": null,
      \"amount\": 0.0,
      \"note\": \"For the sauce\",
      \"order\": 0,
      \"is_header\": true,
      \"no_amount\": true,
      \"original_text\": \"For the sauce\"
    }"

  let result =
    json.parse(json_str, using: ingredient_decoder.ingredient_decoder())

  case result {
    Ok(ingredient) -> {
      ingredient.is_header
      |> should.equal(True)
      ingredient.no_amount
      |> should.equal(True)
      ingredient.note
      |> should.equal(Some("For the sauce"))
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_ingredient_fractional_amount_test() {
  let json_str =
    "{
      \"id\": 6,
      \"food\": null,
      \"unit\": null,
      \"amount\": 0.333333,
      \"note\": null,
      \"order\": 1,
      \"is_header\": false,
      \"no_amount\": false,
      \"original_text\": \"1/3 cup\"
    }"

  let result =
    json.parse(json_str, using: ingredient_decoder.ingredient_decoder())

  case result {
    Ok(ingredient) -> {
      ingredient.amount
      |> should.equal(0.333333)
      ingredient.original_text
      |> should.equal(Some("1/3 cup"))
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Unicode and Special Characters Tests
// ============================================================================

pub fn decode_ingredient_unicode_test() {
  let json_str =
    "{
      \"id\": 7,
      \"food\": {
        \"id\": 20,
        \"name\": \"Jalapeño\",
        \"plural_name\": \"Jalapeños\",
        \"description\": \"Spicy pepper\",
        \"recipe\": null,
        \"food_onhand\": null,
        \"supermarket_category\": null,
        \"ignore_shopping\": false
      },
      \"unit\": null,
      \"amount\": 2.0,
      \"note\": \"finely chopped 🌶️\",
      \"order\": 3,
      \"is_header\": false,
      \"no_amount\": false,
      \"original_text\": \"2 jalapeños, finely chopped\"
    }"

  let result =
    json.parse(json_str, using: ingredient_decoder.ingredient_decoder())

  case result {
    Ok(ingredient) -> {
      case ingredient.food {
        Some(food) -> {
          food.name
          |> should.equal("Jalapeño")
        }
        None -> should.fail()
      }
      ingredient.note
      |> should.equal(Some("finely chopped 🌶️"))
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Error Cases Tests
// ============================================================================

pub fn decode_ingredient_missing_id_test() {
  let json_str =
    "{
      \"food\": null,
      \"unit\": null,
      \"amount\": 1.0,
      \"note\": null,
      \"order\": 1,
      \"is_header\": false,
      \"no_amount\": false,
      \"original_text\": null
    }"

  let result =
    json.parse(json_str, using: ingredient_decoder.ingredient_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_ingredient_missing_amount_test() {
  let json_str =
    "{
      \"id\": 1,
      \"food\": null,
      \"unit\": null,
      \"note\": null,
      \"order\": 1,
      \"is_header\": false,
      \"no_amount\": false,
      \"original_text\": null
    }"

  let result =
    json.parse(json_str, using: ingredient_decoder.ingredient_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_ingredient_wrong_type_amount_test() {
  let json_str =
    "{
      \"id\": 1,
      \"food\": null,
      \"unit\": null,
      \"amount\": \"not_a_number\",
      \"note\": null,
      \"order\": 1,
      \"is_header\": false,
      \"no_amount\": false,
      \"original_text\": null
    }"

  let result =
    json.parse(json_str, using: ingredient_decoder.ingredient_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_ingredient_wrong_type_is_header_test() {
  let json_str =
    "{
      \"id\": 1,
      \"food\": null,
      \"unit\": null,
      \"amount\": 1.0,
      \"note\": null,
      \"order\": 1,
      \"is_header\": \"not_a_bool\",
      \"no_amount\": false,
      \"original_text\": null
    }"

  let result =
    json.parse(json_str, using: ingredient_decoder.ingredient_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_ingredient_invalid_json_test() {
  let json_str = "{not valid json}"

  let result =
    json.parse(json_str, using: ingredient_decoder.ingredient_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}
