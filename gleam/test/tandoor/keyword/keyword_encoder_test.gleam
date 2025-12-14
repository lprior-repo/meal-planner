/// Tests for Tandoor Keyword JSON encoder
///
/// This test suite validates JSON encoding of Keyword objects for Tandoor API.
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/encoders/keyword/keyword_encoder
import meal_planner/tandoor/types/keyword/keyword.{Keyword}

pub fn encode_keyword_minimal_test() {
  let keyword =
    Keyword(
      id: 1,
      name: "vegetarian",
      label: "Vegetarian",
      description: "",
      icon: None,
      parent: None,
      numchild: 0,
      created_at: "2024-01-01T00:00:00Z",
      updated_at: "2024-01-01T00:00:00Z",
      full_name: "Vegetarian",
    )

  let json_value = keyword_encoder.encode_keyword(keyword)
  let json_string = json.to_string(json_value)

  json_string
  |> should.match_substring("\"id\":1")

  json_string
  |> should.match_substring("\"name\":\"vegetarian\"")

  json_string
  |> should.match_substring("\"label\":\"Vegetarian\"")

  json_string
  |> should.match_substring("\"description\":\"\"")

  json_string
  |> should.match_substring("\"numchild\":0")
}

pub fn encode_keyword_with_icon_test() {
  let keyword =
    Keyword(
      id: 2,
      name: "italian",
      label: "Italian",
      description: "Italian cuisine",
      icon: Some("🇮🇹"),
      parent: None,
      numchild: 0,
      created_at: "2024-01-02T00:00:00Z",
      updated_at: "2024-01-02T00:00:00Z",
      full_name: "Italian",
    )

  let json_value = keyword_encoder.encode_keyword(keyword)
  let json_string = json.to_string(json_value)

  json_string
  |> should.match_substring("\"icon\":\"🇮🇹\"")

  json_string
  |> should.match_substring("\"description\":\"Italian cuisine\"")
}

pub fn encode_keyword_with_parent_test() {
  let keyword =
    Keyword(
      id: 3,
      name: "vegan",
      label: "Vegan",
      description: "Vegan recipes",
      icon: None,
      parent: Some(1),
      numchild: 0,
      created_at: "2024-01-03T00:00:00Z",
      updated_at: "2024-01-03T00:00:00Z",
      full_name: "Vegetarian > Vegan",
    )

  let json_value = keyword_encoder.encode_keyword(keyword)
  let json_string = json.to_string(json_value)

  json_string
  |> should.match_substring("\"parent\":1")

  json_string
  |> should.match_substring("\"full_name\":\"Vegetarian > Vegan\"")
}

pub fn encode_keyword_with_children_test() {
  let keyword =
    Keyword(
      id: 4,
      name: "cuisine",
      label: "Cuisine",
      description: "Different cuisine types",
      icon: Some("🍽️"),
      parent: None,
      numchild: 5,
      created_at: "2024-01-04T00:00:00Z",
      updated_at: "2024-01-04T00:00:00Z",
      full_name: "Cuisine",
    )

  let json_value = keyword_encoder.encode_keyword(keyword)
  let json_string = json.to_string(json_value)

  json_string
  |> should.match_substring("\"numchild\":5")

  json_string
  |> should.match_substring("\"icon\":\"🍽️\"")
}

pub fn encode_keyword_create_request_test() {
  let create_data =
    keyword_encoder.KeywordCreateRequest(
      name: "gluten-free",
      description: "Gluten-free recipes",
      icon: Some("🌾"),
      parent: None,
    )

  let json_value = keyword_encoder.encode_keyword_create_request(create_data)
  let json_string = json.to_string(json_value)

  json_string
  |> should.match_substring("\"name\":\"gluten-free\"")

  json_string
  |> should.match_substring("\"description\":\"Gluten-free recipes\"")

  json_string
  |> should.match_substring("\"icon\":\"🌾\"")

  // Should not include readonly fields
  json_string
  |> should.not_match_substring("\"id\":")

  json_string
  |> should.not_match_substring("\"created_at\":")
}

pub fn encode_keyword_update_request_test() {
  let update_data =
    keyword_encoder.KeywordUpdateRequest(
      name: Some("vegan-updated"),
      description: Some("Updated vegan description"),
      icon: None,
      parent: None,
    )

  let json_value = keyword_encoder.encode_keyword_update_request(update_data)
  let json_string = json.to_string(json_value)

  json_string
  |> should.match_substring("\"name\":\"vegan-updated\"")

  json_string
  |> should.match_substring("\"description\":\"Updated vegan description\"")

  // Should not include readonly fields
  json_string
  |> should.not_match_substring("\"label\":")

  json_string
  |> should.not_match_substring("\"numchild\":")
}
