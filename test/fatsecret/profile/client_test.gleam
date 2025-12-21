/// Tests for FatSecret Profile API client and decoders
///
/// Verifies correct parsing of profile API responses including:
/// - User profile data
/// - Profile auth credentials
/// - Profile creation
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/fatsecret/profile/decoders
import meal_planner/fatsecret/profile/types

// ============================================================================
// Profile Response Decoder Tests
// ============================================================================

pub fn decode_profile_complete_test() {
  let json_str = profile_complete_fixture()

  let result =
    json.parse(json_str, decoders.profile_response_decoder())
    |> should.be_ok

  result.goal_weight_kg |> should.equal(Some(70.0))
  result.last_weight_kg |> should.equal(Some(75.5))
  result.height_cm |> should.equal(Some(175.0))
  result.last_weight_date_int |> should.equal(Some(19_723))
  result.calorie_goal |> should.equal(Some(2000))
  result.weight_measure |> should.equal(Some("Kg"))
  result.height_measure |> should.equal(Some("Cm"))
}

pub fn decode_profile_minimal_test() {
  let json_str = profile_minimal_fixture()

  let result =
    json.parse(json_str, decoders.profile_response_decoder())
    |> should.be_ok

  // Optional fields should be None
  result.goal_weight_kg |> should.equal(None)
  result.last_weight_kg |> should.equal(None)
  result.height_cm |> should.equal(None)
  result.last_weight_date_int |> should.equal(None)
  result.calorie_goal |> should.equal(None)
}

// ============================================================================
// Profile Auth Response Decoder Tests
// ============================================================================

pub fn decode_profile_auth_test() {
  let json_str = profile_auth_fixture()

  let result =
    json.parse(json_str, decoders.profile_auth_response_decoder())
    |> should.be_ok

  result.auth_token |> should.equal("abc123token")
  result.auth_secret |> should.equal("xyz789secret")
}

// ============================================================================
// Profile Type Tests
// ============================================================================

pub fn profile_with_all_fields_test() {
  let profile =
    types.Profile(
      goal_weight_kg: Some(70.0),
      last_weight_kg: Some(75.5),
      last_weight_date_int: Some(19_723),
      last_weight_comment: Some("Morning weight"),
      height_cm: Some(175.0),
      calorie_goal: Some(2000),
      weight_measure: Some("Kg"),
      height_measure: Some("Cm"),
    )

  profile.goal_weight_kg |> should.equal(Some(70.0))
  profile.last_weight_kg |> should.equal(Some(75.5))
  profile.height_cm |> should.equal(Some(175.0))
  profile.last_weight_date_int |> should.equal(Some(19_723))
  profile.calorie_goal |> should.equal(Some(2000))
}

pub fn profile_with_no_fields_test() {
  let profile =
    types.Profile(
      goal_weight_kg: None,
      last_weight_kg: None,
      last_weight_date_int: None,
      last_weight_comment: None,
      height_cm: None,
      calorie_goal: None,
      weight_measure: None,
      height_measure: None,
    )

  profile.goal_weight_kg |> should.equal(None)
  profile.last_weight_kg |> should.equal(None)
  profile.height_cm |> should.equal(None)
  profile.last_weight_date_int |> should.equal(None)
  profile.calorie_goal |> should.equal(None)
}

pub fn profile_auth_test() {
  let auth =
    types.ProfileAuth(auth_token: "token123", auth_secret: "secret456")

  auth.auth_token |> should.equal("token123")
  auth.auth_secret |> should.equal("secret456")
}

// ============================================================================
// Test Fixtures
// ============================================================================

fn profile_complete_fixture() -> String {
  "{
    \"profile\": {
      \"goal_weight_kg\": 70.0,
      \"last_weight_kg\": 75.5,
      \"height_cm\": 175.0,
      \"last_weight_date_int\": 19723,
      \"last_weight_comment\": \"Morning weight\",
      \"calorie_goal\": 2000,
      \"weight_measure\": \"Kg\",
      \"height_measure\": \"Cm\"
    }
  }"
}

fn profile_minimal_fixture() -> String {
  "{
    \"profile\": {
      \"goal_weight_kg\": null,
      \"last_weight_kg\": null,
      \"height_cm\": null,
      \"last_weight_date_int\": null,
      \"last_weight_comment\": null,
      \"calorie_goal\": null,
      \"weight_measure\": null,
      \"height_measure\": null
    }
  }"
}

fn profile_auth_fixture() -> String {
  "{
    \"profile\": {
      \"auth_token\": \"abc123token\",
      \"auth_secret\": \"xyz789secret\"
    }
  }"
}
