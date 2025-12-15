import gleam/dynamic/decode
import gleam/json
import gleeunit/should
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/decoders/user/user_decoder

pub fn user_decoder_basic_fields_test() {
  let json_str =
    "{
      \"id\": 123,
      \"username\": \"testuser\",
      \"first_name\": \"Test\",
      \"last_name\": \"User\",
      \"display_name\": \"Test User\",
      \"is_staff\": false,
      \"is_superuser\": false,
      \"is_active\": true
    }"

  let assert Ok(decoded_json) = json.parse(json_str, using: decode.dynamic)
  let result = user_decoder.decode(decoded_json)

  should.be_ok(result)
  let assert Ok(user) = result

  user.id
  |> ids.user_id_to_int
  |> should.equal(123)

  user.username
  |> should.equal("testuser")

  user.first_name
  |> should.equal("Test")

  user.last_name
  |> should.equal("User")

  user.display_name
  |> should.equal("Test User")

  user.is_staff
  |> should.equal(False)

  user.is_superuser
  |> should.equal(False)

  user.is_active
  |> should.equal(True)
}

pub fn user_decoder_minimal_fields_test() {
  // Test with empty optional fields
  let json_str =
    "{
      \"id\": 456,
      \"username\": \"minimaluser\",
      \"first_name\": \"\",
      \"last_name\": \"\",
      \"display_name\": \"minimaluser\",
      \"is_staff\": true,
      \"is_superuser\": true,
      \"is_active\": false
    }"

  let assert Ok(decoded_json) = json.parse(json_str, using: decode.dynamic)
  let result = user_decoder.decode(decoded_json)

  should.be_ok(result)
  let assert Ok(user) = result

  user.id
  |> ids.user_id_to_int
  |> should.equal(456)

  user.username
  |> should.equal("minimaluser")

  user.first_name
  |> should.equal("")

  user.last_name
  |> should.equal("")

  user.display_name
  |> should.equal("minimaluser")

  user.is_staff
  |> should.equal(True)

  user.is_superuser
  |> should.equal(True)

  user.is_active
  |> should.equal(False)
}

pub fn user_decoder_missing_required_field_test() {
  let json_str =
    "{
      \"id\": 789,
      \"username\": \"testuser\",
      \"display_name\": \"Test User\"
    }"

  let assert Ok(decoded_json) = json.parse(json_str, using: decode.dynamic)
  let result = user_decoder.decode(decoded_json)

  should.be_error(result)
}
