/// FatSecret Profile API Tests
/// Tests for POST /api/fatsecret/profile and GET /api/fatsecret/profile/auth
///
/// This test module covers:
/// - Profile creation and authentication
/// - Profile decoding and response handling
/// - Profile auth credentials
///
/// Run with: cd gleam && gleam test
import gleam/dict
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/profile/types.{
  Profile, ProfileAuth, ProfileCreateInput,
}
import meal_planner/fatsecret/profile/decoders

pub fn main() {
  gleeunit.main()
}

// Tests for Profile Decoder

pub fn profile_decoder_full_response_test() {
  let json_str = json.object([
    #("goal_weight_kg", json.float(75.5)),
    #("last_weight_kg", json.float(80.2)),
    #("last_weight_date_int", json.int(20251214)),
    #("last_weight_comment", json.string("Woohoo!")),
    #("height_cm", json.float(175.0)),
    #("calorie_goal", json.int(2000)),
    #("weight_measure", json.string("Kg")),
    #("height_measure", json.string("Cm")),
  ])
  |> json.to_string

  let result = json.parse(json_str, decoders.profile_decoder())
  should.be_ok(result)
}

pub fn profile_decoder_partial_response_test() {
  let json_str = json.object([
    #("goal_weight_kg", json.float(75.5)),
    #("last_weight_kg", json.null()),
    #("last_weight_date_int", json.null()),
    #("last_weight_comment", json.null()),
    #("height_cm", json.float(175.0)),
    #("calorie_goal", json.int(2000)),
    #("weight_measure", json.string("Kg")),
    #("height_measure", json.string("Cm")),
  ])
  |> json.to_string

  let result = json.parse(json_str, decoders.profile_decoder())
  should.be_ok(result)
}

pub fn profile_decoder_empty_response_test() {
  let json_str = json.object([
    #("goal_weight_kg", json.null()),
    #("last_weight_kg", json.null()),
    #("last_weight_date_int", json.null()),
    #("last_weight_comment", json.null()),
    #("height_cm", json.null()),
    #("calorie_goal", json.null()),
    #("weight_measure", json.null()),
    #("height_measure", json.null()),
  ])
  |> json.to_string

  let result = json.parse(json_str, decoders.profile_decoder())
  should.be_ok(result)
}

pub fn profile_response_decoder_unwraps_field_test() {
  let json_str = json.object([
    #("profile", json.object([
      #("goal_weight_kg", json.float(75.5)),
      #("last_weight_kg", json.float(80.2)),
      #("last_weight_date_int", json.int(20251214)),
      #("last_weight_comment", json.string("Woohoo!")),
      #("height_cm", json.float(175.0)),
      #("calorie_goal", json.int(2000)),
      #("weight_measure", json.string("Kg")),
      #("height_measure", json.string("Cm")),
    ])),
  ])
  |> json.to_string

  let result = json.parse(json_str, decoders.profile_response_decoder())
  should.be_ok(result)
}

// Tests for Profile Auth Decoder

pub fn profile_auth_decoder_valid_response_test() {
  let json_str = json.object([
    #("auth_token", json.string("639aa3c886b849d2811c09bb640ec2b3")),
    #("auth_secret", json.string("cadff7ef247744b4bff48fb2489451fc")),
  ])
  |> json.to_string

  let result = json.parse(json_str, decoders.profile_auth_decoder())
  should.be_ok(result)
}

pub fn profile_auth_response_decoder_unwraps_field_test() {
  let json_str = json.object([
    #("profile", json.object([
      #("auth_token", json.string("639aa3c886b849d2811c09bb640ec2b3")),
      #("auth_secret", json.string("cadff7ef247744b4bff48fb2489451fc")),
    ])),
  ])
  |> json.to_string

  let result = json.parse(json_str, decoders.profile_auth_response_decoder())
  should.be_ok(result)
}

pub fn profile_auth_decoder_missing_fields_test() {
  let json_str = json.object([
    #("auth_token", json.string("639aa3c886b849d2811c09bb640ec2b3")),
  ])
  |> json.to_string

  let result = json.parse(json_str, decoders.profile_auth_decoder())
  should.be_error(result)
}

// Tests for Types and Constructors

pub fn profile_create_input_construction_test() {
  let input = ProfileCreateInput(user_id: "user-12345")
  should.equal(input.user_id, "user-12345")
}

pub fn profile_auth_construction_test() {
  let auth = ProfileAuth(
    auth_token: "token-xyz",
    auth_secret: "secret-abc",
  )
  should.equal(auth.auth_token, "token-xyz")
  should.equal(auth.auth_secret, "secret-abc")
}

pub fn profile_with_all_fields_test() {
  let profile = Profile(
    goal_weight_kg: Some(75.5),
    last_weight_kg: Some(80.2),
    last_weight_date_int: Some(20251214),
    last_weight_comment: Some("Good progress!"),
    height_cm: Some(175.0),
    calorie_goal: Some(2000),
    weight_measure: Some("Kg"),
    height_measure: Some("Cm"),
  )

  should.equal(profile.goal_weight_kg, Some(75.5))
  should.equal(profile.height_cm, Some(175.0))
}

pub fn profile_with_none_fields_test() {
  let profile = Profile(
    goal_weight_kg: None,
    last_weight_kg: None,
    last_weight_date_int: None,
    last_weight_comment: None,
    height_cm: None,
    calorie_goal: None,
    weight_measure: None,
    height_measure: None,
  )

  should.equal(profile.goal_weight_kg, None)
  should.equal(profile.height_cm, None)
}

// Tests for JSON Serialization

pub fn serialize_profile_create_input_test() {
  let input = ProfileCreateInput(user_id: "user-12345")
  let json_obj = json.object([
    #("user_id", json.string(input.user_id)),
  ])
  let json_str = json.to_string(json_obj)
  should.be_true(string.length(json_str) > 0)
}

pub fn build_profile_request_parameters_test() {
  let params = dict.new()
  |> dict.insert("user_id", "user-12345")
  should.equal(dict.get(params, "user_id"), Ok("user-12345"))
}

// Tests for Error Handling

pub fn handle_malformed_json_test() {
  let malformed = "{ invalid json"
  let result = json.parse(malformed, decoders.profile_decoder())
  should.be_error(result)
}

pub fn handle_missing_required_fields_test() {
  let json_str = json.object([
    #("profile", json.object([
      #("auth_token", json.string("token")),
    ])),
  ])
  |> json.to_string

  let result = json.parse(json_str, decoders.profile_auth_response_decoder())
  should.be_error(result)
}

pub fn handle_wrong_type_in_response_test() {
  let json_str = json.object([
    #("goal_weight_kg", json.string("not a number")),
    #("last_weight_kg", json.null()),
    #("last_weight_date_int", json.null()),
    #("last_weight_comment", json.null()),
    #("height_cm", json.null()),
    #("calorie_goal", json.null()),
    #("weight_measure", json.null()),
    #("height_measure", json.null()),
  ])
  |> json.to_string

  let result = json.parse(json_str, decoders.profile_decoder())
  should.be_error(result)
}

// Integration-style tests for API Response Formats

pub fn fatsecret_profile_response_format_test() {
  let response = json.object([
    #("profile", json.object([
      #("goal_weight_kg", json.float(75.5)),
      #("last_weight_kg", json.float(80.2)),
      #("last_weight_date_int", json.int(20251214)),
      #("last_weight_comment", json.string("Woohoo!")),
      #("height_cm", json.float(175.0)),
      #("calorie_goal", json.int(2000)),
      #("weight_measure", json.string("Kg")),
      #("height_measure", json.string("Cm")),
    ])),
  ])
  |> json.to_string

  should.be_ok(json.parse(response, decoders.profile_response_decoder()))
}

pub fn fatsecret_profile_auth_response_format_test() {
  let response = json.object([
    #("profile", json.object([
      #("auth_token", json.string("639aa3c886b849d2811c09bb640ec2b3")),
      #("auth_secret", json.string("cadff7ef247744b4bff48fb2489451fc")),
    ])),
  ])
  |> json.to_string

  should.be_ok(json.parse(response, decoders.profile_auth_response_decoder()))
}
