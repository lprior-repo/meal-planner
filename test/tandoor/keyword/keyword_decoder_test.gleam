/// Tests for Tandoor Keyword JSON decoder
///
/// This test suite validates JSON decoding of Keyword objects from Tandoor API.
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/keyword.{type Keyword}

pub fn decode_keyword_minimal_test() {
  let json_string =
    "{
    \"id\": 1,
    \"name\": \"vegetarian\",
    \"label\": \"Vegetarian\",
    \"description\": \"\",
    \"parent\": null,
    \"numchild\": 0,
    \"created_at\": \"2024-01-01T00:00:00Z\",
    \"updated_at\": \"2024-01-01T00:00:00Z\",
    \"full_name\": \"Vegetarian\"
  }"

  let assert Ok(json_data) = json.parse(json_string, using: decode.dynamic)
  let result: Result(Keyword, _) =
    decode.run(json_data, keyword.keyword_decoder())

  case result {
    Ok(keyword) -> {
      keyword.id
      |> should.equal(1)

      keyword.name
      |> should.equal("vegetarian")

      keyword.label
      |> should.equal("Vegetarian")

      keyword.description
      |> should.equal("")

      keyword.icon
      |> should.equal(None)

      keyword.parent
      |> should.equal(None)

      keyword.numchild
      |> should.equal(0)

      keyword.full_name
      |> should.equal("Vegetarian")
    }
    Error(_) -> {
      should.fail()
    }
  }
}

pub fn decode_keyword_with_icon_test() {
  let json_string =
    "{
    \"id\": 2,
    \"name\": \"italian\",
    \"label\": \"Italian\",
    \"description\": \"Italian cuisine\",
    \"icon\": \"flag_it\",
    \"parent\": null,
    \"numchild\": 0,
    \"created_at\": \"2024-01-02T00:00:00Z\",
    \"updated_at\": \"2024-01-02T00:00:00Z\",
    \"full_name\": \"Italian\"
  }"

  let assert Ok(json_data) = json.parse(json_string, using: decode.dynamic)
  let result: Result(Keyword, _) =
    decode.run(json_data, keyword.keyword_decoder())

  case result {
    Ok(keyword) -> {
      keyword.icon
      |> should.equal(Some("flag_it"))

      keyword.description
      |> should.equal("Italian cuisine")
    }
    Error(_) -> {
      should.fail()
    }
  }
}

pub fn decode_keyword_with_parent_test() {
  let json_string =
    "{
    \"id\": 3,
    \"name\": \"vegan\",
    \"label\": \"Vegan\",
    \"description\": \"Vegan recipes\",
    \"parent\": 1,
    \"numchild\": 0,
    \"created_at\": \"2024-01-03T00:00:00Z\",
    \"updated_at\": \"2024-01-03T00:00:00Z\",
    \"full_name\": \"Vegetarian > Vegan\"
  }"

  let assert Ok(json_data) = json.parse(json_string, using: decode.dynamic)
  let result: Result(Keyword, _) =
    decode.run(json_data, keyword.keyword_decoder())

  case result {
    Ok(keyword) -> {
      keyword.parent
      |> should.equal(Some(1))

      keyword.full_name
      |> should.equal("Vegetarian > Vegan")
    }
    Error(_) -> {
      should.fail()
    }
  }
}

pub fn decode_keyword_with_children_test() {
  let json_string =
    "{
    \"id\": 4,
    \"name\": \"cuisine\",
    \"label\": \"Cuisine\",
    \"description\": \"Different cuisine types\",
    \"parent\": null,
    \"numchild\": 5,
    \"created_at\": \"2024-01-04T00:00:00Z\",
    \"updated_at\": \"2024-01-04T00:00:00Z\",
    \"full_name\": \"Cuisine\"
  }"

  let assert Ok(json_data) = json.parse(json_string, using: decode.dynamic)
  let result: Result(Keyword, _) =
    decode.run(json_data, keyword.keyword_decoder())

  case result {
    Ok(keyword) -> {
      keyword.numchild
      |> should.equal(5)

      keyword.parent
      |> should.equal(None)
    }
    Error(_) -> {
      should.fail()
    }
  }
}

pub fn decode_keyword_list_test() {
  let json_string =
    "[
    {
      \"id\": 1,
      \"name\": \"vegetarian\",
      \"label\": \"Vegetarian\",
      \"description\": \"\",
      \"parent\": null,
      \"numchild\": 1,
      \"created_at\": \"2024-01-01T00:00:00Z\",
      \"updated_at\": \"2024-01-01T00:00:00Z\",
      \"full_name\": \"Vegetarian\"
    },
    {
      \"id\": 2,
      \"name\": \"vegan\",
      \"label\": \"Vegan\",
      \"description\": \"Vegan recipes\",
      \"parent\": 1,
      \"numchild\": 0,
      \"created_at\": \"2024-01-02T00:00:00Z\",
      \"updated_at\": \"2024-01-02T00:00:00Z\",
      \"full_name\": \"Vegetarian > Vegan\"
    }
  ]"

  let assert Ok(json_data) = json.parse(json_string, using: decode.dynamic)
  let result = decode.run(json_data, decode.list(keyword.keyword_decoder()))

  case result {
    Ok(keywords) -> {
      keywords
      |> list.length
      |> should.equal(2)

      let first = case keywords {
        [keyword, ..] -> keyword
        _ -> {
          should.fail()
          panic as "unreachable"
        }
      }

      first.id
      |> should.equal(1)

      first.numchild
      |> should.equal(1)
    }
    Error(_) -> {
      should.fail()
    }
  }
}

pub fn decode_keyword_invalid_json_test() {
  let json_string = "{ \"invalid\": \"json\" }"

  let assert Ok(json_data) = json.parse(json_string, using: decode.dynamic)
  let result = decode.run(json_data, keyword.keyword_decoder())

  case result {
    Ok(_) -> {
      should.fail()
    }
    Error(_) -> {
      should.be_true(True)
    }
  }
}
