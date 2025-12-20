import gleam/json
import gleam/option
import gleeunit
import gleeunit/should
import meal_planner/shared/response_encoders

pub fn main() {
  gleeunit.main()
}

// Optional value encoders
pub fn encode_optional_string_some_test() {
  let result = response_encoders.encode_optional_string(option.Some("test"))
  json.to_string(result)
  |> should.equal("\"test\"")
}

pub fn encode_optional_string_none_test() {
  let result = response_encoders.encode_optional_string(option.None)
  json.to_string(result)
  |> should.equal("null")
}

pub fn encode_optional_int_some_test() {
  let result = response_encoders.encode_optional_int(option.Some(42))
  json.to_string(result)
  |> should.equal("42")
}

pub fn encode_optional_int_none_test() {
  let result = response_encoders.encode_optional_int(option.None)
  json.to_string(result)
  |> should.equal("null")
}

pub fn encode_optional_float_some_test() {
  let result = response_encoders.encode_optional_float(option.Some(3.14))
  json.to_string(result)
  |> should.equal("3.14")
}

pub fn encode_optional_bool_test() {
  let result = response_encoders.encode_optional_bool(option.Some(True))
  json.to_string(result)
  |> should.equal("true")
}

// Pagination response encoder
pub fn paginated_response_test() {
  let results = json.array([1, 2, 3], json.int)
  let response =
    response_encoders.paginated_response(
      results,
      100,
      option.Some("http://next"),
      option.None,
    )

  let encoded = json.to_string(response)
  // Verify it contains expected fields
  encoded
  |> should.contain("\"count\":100")
  encoded
  |> should.contain("\"next\":\"http://next\"")
  encoded
  |> should.contain("\"previous\":null")
}

// List response encoder
pub fn list_response_test() {
  let items = json.array([1, 2, 3], json.int)
  let response = response_encoders.list_response(items, 50)

  let encoded = json.to_string(response)
  encoded
  |> should.contain("\"count\":50")
  encoded
  |> should.contain("\"items\":[1,2,3]")
}

// Success encoders
pub fn success_with_data_test() {
  let data = json.object([#("id", json.int(1))])
  let response = response_encoders.success_with_data(data)

  let encoded = json.to_string(response)
  encoded
  |> should.contain("\"success\":true")
  encoded
  |> should.contain("\"data\"")
}

pub fn success_message_test() {
  let response = response_encoders.success_message("Operation completed")
  let encoded = json.to_string(response)

  encoded
  |> should.contain("\"success\":true")
  encoded
  |> should.contain("\"message\":\"Operation completed\"")
}

// Error encoders
pub fn error_message_test() {
  let response = response_encoders.error_message("Not found")
  let encoded = json.to_string(response)

  encoded
  |> should.equal("{\"error\":\"Not found\"}")
}

pub fn error_with_code_test() {
  let response = response_encoders.error_with_code("NOT_FOUND", "Resource not found")
  let encoded = json.to_string(response)

  encoded
  |> should.contain("\"error\":\"NOT_FOUND\"")
  encoded
  |> should.contain("\"message\":\"Resource not found\"")
}

// Array response encoders
pub fn encode_array_test() {
  let items = [1, 2, 3]
  let response = response_encoders.encode_array(items, json.int)
  let encoded = json.to_string(response)

  encoded
  |> should.equal("[1,2,3]")
}

pub fn array_with_count_test() {
  let items = [1, 2, 3]
  let response = response_encoders.array_with_count(items, 25, json.int)
  let encoded = json.to_string(response)

  encoded
  |> should.contain("\"count\":25")
  encoded
  |> should.contain("\"items\":[1,2,3]")
}

// Object response encoders
pub fn object_response_test() {
  let fields = [
    #("id", json.int(1)),
    #("name", json.string("test")),
  ]
  let response = response_encoders.object_response(fields)
  let encoded = json.to_string(response)

  encoded
  |> should.contain("\"id\":1")
  encoded
  |> should.contain("\"name\":\"test\"")
}

pub fn status_response_with_data_test() {
  let data = json.object([#("result", json.string("success"))])
  let response =
    response_encoders.status_response("processing", option.Some(data))
  let encoded = json.to_string(response)

  encoded
  |> should.contain("\"status\":\"processing\"")
  encoded
  |> should.contain("\"data\"")
}

pub fn status_response_without_data_test() {
  let response = response_encoders.status_response("idle", option.None)
  let encoded = json.to_string(response)

  encoded
  |> should.equal("{\"status\":\"idle\"}")
}
