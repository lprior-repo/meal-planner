/// Tests for Keyword decoder
///
/// This module tests JSON decoding of Keyword types following TDD principles.
/// Tests cover: valid JSON, optional fields, missing fields, wrong types, and special characters.
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/decoders/keyword/keyword_decoder
import meal_planner/tandoor/types/keyword/keyword.{type Keyword}

// ============================================================================
// Valid JSON Tests
// ============================================================================

pub fn decode_keyword_full_test() {
  let json_str =
    "{
      \"id\": 1,
      \"name\": \"vegetarian\",
      \"label\": \"Vegetarian\",
      \"description\": \"Vegetarian recipes\",
      \"icon\": \"🥗\",
      \"parent\": 5,
      \"numchild\": 3,
      \"created_at\": \"2024-01-01T00:00:00Z\",
      \"updated_at\": \"2024-01-02T00:00:00Z\",
      \"full_name\": \"Diet > Vegetarian\"
    }"

  let result: Result(Keyword, _) =
    json.parse(json_str, using: keyword_decoder.keyword_decoder())

  case result {
    Ok(keyword) -> {
      keyword.id
      |> should.equal(1)
      keyword.name
      |> should.equal("vegetarian")
      keyword.label
      |> should.equal("Vegetarian")
      keyword.description
      |> should.equal("Vegetarian recipes")
      keyword.icon
      |> should.equal(Some("🥗"))
      keyword.parent
      |> should.equal(Some(5))
      keyword.numchild
      |> should.equal(3)
      keyword.created_at
      |> should.equal("2024-01-01T00:00:00Z")
      keyword.updated_at
      |> should.equal("2024-01-02T00:00:00Z")
      keyword.full_name
      |> should.equal("Diet > Vegetarian")
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_keyword_minimal_test() {
  let json_str =
    "{
      \"id\": 2,
      \"name\": \"quick\",
      \"label\": \"Quick\",
      \"description\": \"\",
      \"icon\": null,
      \"parent\": null,
      \"numchild\": 0,
      \"created_at\": \"2024-01-01T00:00:00Z\",
      \"updated_at\": \"2024-01-01T00:00:00Z\",
      \"full_name\": \"Quick\"
    }"

  let result: Result(Keyword, _) =
    json.parse(json_str, using: keyword_decoder.keyword_decoder())

  case result {
    Ok(keyword) -> {
      keyword.id
      |> should.equal(2)
      keyword.name
      |> should.equal("quick")
      keyword.icon
      |> should.equal(None)
      keyword.parent
      |> should.equal(None)
      keyword.numchild
      |> should.equal(0)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Optional Fields Tests
// ============================================================================

pub fn decode_keyword_with_icon_test() {
  let json_str =
    "{
      \"id\": 3,
      \"name\": \"spicy\",
      \"label\": \"Spicy\",
      \"description\": \"Spicy recipes\",
      \"icon\": \"🌶️\",
      \"parent\": null,
      \"numchild\": 0,
      \"created_at\": \"2024-01-01T00:00:00Z\",
      \"updated_at\": \"2024-01-01T00:00:00Z\",
      \"full_name\": \"Spicy\"
    }"

  let result = json.parse(json_str, using: keyword_decoder.keyword_decoder())

  case result {
    Ok(keyword) -> {
      keyword.icon
      |> should.equal(Some("🌶️"))
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_keyword_with_parent_test() {
  let json_str =
    "{
      \"id\": 4,
      \"name\": \"vegan\",
      \"label\": \"Vegan\",
      \"description\": \"Vegan subset\",
      \"icon\": null,
      \"parent\": 1,
      \"numchild\": 0,
      \"created_at\": \"2024-01-01T00:00:00Z\",
      \"updated_at\": \"2024-01-01T00:00:00Z\",
      \"full_name\": \"Vegetarian > Vegan\"
    }"

  let result = json.parse(json_str, using: keyword_decoder.keyword_decoder())

  case result {
    Ok(keyword) -> {
      keyword.parent
      |> should.equal(Some(1))
      keyword.full_name
      |> should.equal("Vegetarian > Vegan")
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_keyword_with_children_test() {
  let json_str =
    "{
      \"id\": 5,
      \"name\": \"diet\",
      \"label\": \"Diet\",
      \"description\": \"Dietary categories\",
      \"icon\": null,
      \"parent\": null,
      \"numchild\": 5,
      \"created_at\": \"2024-01-01T00:00:00Z\",
      \"updated_at\": \"2024-01-01T00:00:00Z\",
      \"full_name\": \"Diet\"
    }"

  let result = json.parse(json_str, using: keyword_decoder.keyword_decoder())

  case result {
    Ok(keyword) -> {
      keyword.numchild
      |> should.equal(5)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Unicode and Special Characters Tests
// ============================================================================

pub fn decode_keyword_unicode_test() {
  let json_str =
    "{
      \"id\": 6,
      \"name\": \"français\",
      \"label\": \"Français\",
      \"description\": \"Recettes françaises 🇫🇷\",
      \"icon\": \"🥐\",
      \"parent\": null,
      \"numchild\": 0,
      \"created_at\": \"2024-01-01T00:00:00Z\",
      \"updated_at\": \"2024-01-01T00:00:00Z\",
      \"full_name\": \"Français\"
    }"

  let result = json.parse(json_str, using: keyword_decoder.keyword_decoder())

  case result {
    Ok(keyword) -> {
      keyword.name
      |> should.equal("français")
      keyword.label
      |> should.equal("Français")
      keyword.description
      |> should.equal("Recettes françaises 🇫🇷")
      keyword.icon
      |> should.equal(Some("🥐"))
    }
    Error(_) -> should.fail()
  }
}

pub fn decode_keyword_special_chars_test() {
  let json_str =
    "{
      \"id\": 7,
      \"name\": \"low-carb\",
      \"label\": \"Low-Carb\",
      \"description\": \"Low carb & keto friendly\",
      \"icon\": null,
      \"parent\": null,
      \"numchild\": 0,
      \"created_at\": \"2024-01-01T00:00:00Z\",
      \"updated_at\": \"2024-01-01T00:00:00Z\",
      \"full_name\": \"Low-Carb\"
    }"

  let result = json.parse(json_str, using: keyword_decoder.keyword_decoder())

  case result {
    Ok(keyword) -> {
      keyword.name
      |> should.equal("low-carb")
      keyword.description
      |> should.equal("Low carb & keto friendly")
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Error Cases Tests
// ============================================================================

pub fn decode_keyword_missing_required_id_test() {
  let json_str =
    "{
      \"name\": \"test\",
      \"label\": \"Test\",
      \"description\": \"\",
      \"icon\": null,
      \"parent\": null,
      \"numchild\": 0,
      \"created_at\": \"2024-01-01T00:00:00Z\",
      \"updated_at\": \"2024-01-01T00:00:00Z\",
      \"full_name\": \"Test\"
    }"

  let result = json.parse(json_str, using: keyword_decoder.keyword_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_keyword_missing_required_name_test() {
  let json_str =
    "{
      \"id\": 1,
      \"label\": \"Test\",
      \"description\": \"\",
      \"icon\": null,
      \"parent\": null,
      \"numchild\": 0,
      \"created_at\": \"2024-01-01T00:00:00Z\",
      \"updated_at\": \"2024-01-01T00:00:00Z\",
      \"full_name\": \"Test\"
    }"

  let result = json.parse(json_str, using: keyword_decoder.keyword_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_keyword_wrong_type_id_test() {
  let json_str =
    "{
      \"id\": \"not_a_number\",
      \"name\": \"test\",
      \"label\": \"Test\",
      \"description\": \"\",
      \"icon\": null,
      \"parent\": null,
      \"numchild\": 0,
      \"created_at\": \"2024-01-01T00:00:00Z\",
      \"updated_at\": \"2024-01-01T00:00:00Z\",
      \"full_name\": \"Test\"
    }"

  let result = json.parse(json_str, using: keyword_decoder.keyword_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_keyword_wrong_type_numchild_test() {
  let json_str =
    "{
      \"id\": 1,
      \"name\": \"test\",
      \"label\": \"Test\",
      \"description\": \"\",
      \"icon\": null,
      \"parent\": null,
      \"numchild\": \"not_a_number\",
      \"created_at\": \"2024-01-01T00:00:00Z\",
      \"updated_at\": \"2024-01-01T00:00:00Z\",
      \"full_name\": \"Test\"
    }"

  let result = json.parse(json_str, using: keyword_decoder.keyword_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_keyword_invalid_json_test() {
  let json_str = "{invalid json}"

  let result = json.parse(json_str, using: keyword_decoder.keyword_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}

pub fn decode_keyword_empty_string_test() {
  let json_str = ""

  let result = json.parse(json_str, using: keyword_decoder.keyword_decoder())

  case result {
    Ok(_) -> should.fail()
    Error(_) -> should.be_true(True)
  }
}
