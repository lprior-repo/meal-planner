/// Tests for Tandoor Keyword JSON encoder
///
/// This test suite validates JSON encoding of Keyword objects for Tandoor API.
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import meal_planner/tandoor/keyword.{Keyword}

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

  let json_value = keyword.encode_keyword(keyword)
  let json_string = json.to_string(json_value)

  string.contains(json_string, "\"id\":1")
  |> should.be_true

  string.contains(json_string, "\"name\":\"vegetarian\"")
  |> should.be_true

  string.contains(json_string, "\"label\":\"Vegetarian\"")
  |> should.be_true

  string.contains(json_string, "\"description\":\"\"")
  |> should.be_true

  string.contains(json_string, "\"numchild\":0")
  |> should.be_true
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

  let json_value = keyword.encode_keyword(keyword)
  let json_string = json.to_string(json_value)

  string.contains(json_string, "\"icon\":\"🇮🇹\"")
  |> should.be_true

  string.contains(json_string, "\"description\":\"Italian cuisine\"")
  |> should.be_true
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

  let json_value = keyword.encode_keyword(keyword)
  let json_string = json.to_string(json_value)

  string.contains(json_string, "\"parent\":1")
  |> should.be_true

  string.contains(json_string, "\"full_name\":\"Vegetarian > Vegan\"")
  |> should.be_true
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

  let json_value = keyword.encode_keyword(keyword)
  let json_string = json.to_string(json_value)

  string.contains(json_string, "\"numchild\":5")
  |> should.be_true

  string.contains(json_string, "\"icon\":\"🍽️\"")
  |> should.be_true
}

pub fn encode_keyword_create_request_test() {
  let create_data =
    keyword.KeywordCreateRequest(
      name: "gluten-free",
      description: "Gluten-free recipes",
      icon: Some("🌾"),
      parent: None,
    )

  let json_value = keyword.encode_keyword_create_request(create_data)
  let json_string = json.to_string(json_value)

  string.contains(json_string, "\"name\":\"gluten-free\"")
  |> should.be_true

  string.contains(json_string, "\"description\":\"Gluten-free recipes\"")
  |> should.be_true

  string.contains(json_string, "\"icon\":\"🌾\"")
  |> should.be_true

  // Should not include readonly fields
  string.contains(json_string, "\"id\":")
  |> should.be_false

  string.contains(json_string, "\"created_at\":")
  |> should.be_false
}

pub fn encode_keyword_update_request_test() {
  let update_data =
    keyword.KeywordUpdateRequest(
      name: Some("vegan-updated"),
      description: Some("Updated vegan description"),
      icon: None,
      parent: None,
    )

  let json_value = keyword.encode_keyword_update_request(update_data)
  let json_string = json.to_string(json_value)

  string.contains(json_string, "\"name\":\"vegan-updated\"")
  |> should.be_true

  string.contains(json_string, "\"description\":\"Updated vegan description\"")
  |> should.be_true

  // Should not include readonly fields
  string.contains(json_string, "\"label\":")
  |> should.be_false

  string.contains(json_string, "\"numchild\":")
  |> should.be_false
}
