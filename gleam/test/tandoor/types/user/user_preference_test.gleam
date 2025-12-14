import gleam/dynamic/decode
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/decoders/user/user_preference_decoder
import meal_planner/tandoor/types/user/user_preference

pub fn user_preference_decoder_basic_test() {
  let json_str =
    "{
      \"user\": {
        \"id\": 1,
        \"username\": \"admin\",
        \"first_name\": \"Admin\",
        \"last_name\": \"User\",
        \"display_name\": \"Admin\",
        \"is_staff\": true,
        \"is_superuser\": true,
        \"is_active\": true
      },
      \"image\": null,
      \"theme\": \"BOOTSTRAP\",
      \"nav_bg_color\": \"#212529\",
      \"nav_text_color\": \"LIGHT\",
      \"nav_show_logo\": true,
      \"default_unit\": \"g\",
      \"default_page\": \"SEARCH\",
      \"use_fractions\": false,
      \"use_kj\": false,
      \"plan_share\": null,
      \"nav_sticky\": true,
      \"ingredient_decimals\": 2,
      \"comments\": true,
      \"shopping_auto_sync\": 5,
      \"mealplan_autoadd_shopping\": false,
      \"food_inherit_default\": \"DISABLED\",
      \"default_delay\": 4.0,
      \"mealplan_autoinclude_related\": true,
      \"mealplan_autoexclude_onhand\": false,
      \"shopping_share\": null,
      \"shopping_recent_days\": 7,
      \"csv_delim\": \",\",
      \"csv_prefix\": \"\",
      \"filter_to_supermarket\": false,
      \"shopping_add_onhand\": false,
      \"left_handed\": false,
      \"show_step_ingredients\": true,
      \"food_children_exist\": false
    }"

  let assert Ok(decoded_json) = json.parse(json_str, using: decode.dynamic)
  let result = user_preference_decoder.decode(decoded_json)

  should.be_ok(result)
  let assert Ok(pref) = result

  pref.user.id
  |> ids.user_id_to_int
  |> should.equal(1)

  pref.theme
  |> should.equal("BOOTSTRAP")

  pref.default_unit
  |> should.equal("g")

  pref.use_fractions
  |> should.equal(False)

  pref.ingredient_decimals
  |> should.equal(2)

  pref.shopping_auto_sync
  |> should.equal(5)

  pref.default_delay
  |> should.equal(4.0)
}

pub fn user_preference_decoder_with_optional_image_test() {
  let json_str =
    "{
      \"user\": {
        \"id\": 2,
        \"username\": \"testuser\",
        \"first_name\": \"Test\",
        \"last_name\": \"User\",
        \"display_name\": \"Test User\",
        \"is_staff\": false,
        \"is_superuser\": false,
        \"is_active\": true
      },
      \"image\": {
        \"id\": 10,
        \"name\": \"avatar.jpg\",
        \"file_download\": \"https://example.com/avatar.jpg\",
        \"preview\": \"https://example.com/avatar_preview.jpg\",
        \"file_size_kb\": 150,
        \"created_by\": {
          \"id\": 2,
          \"username\": \"testuser\",
          \"first_name\": \"Test\",
          \"last_name\": \"User\",
          \"display_name\": \"Test User\",
          \"is_staff\": false,
          \"is_superuser\": false,
          \"is_active\": true
        },
        \"created_at\": \"2025-12-01T10:30:00Z\"
      },
      \"theme\": \"FLATLY\",
      \"nav_bg_color\": \"#2C3E50\",
      \"nav_text_color\": \"DARK\",
      \"nav_show_logo\": false,
      \"default_unit\": \"ml\",
      \"default_page\": \"PLAN\",
      \"use_fractions\": true,
      \"use_kj\": true,
      \"plan_share\": [],
      \"nav_sticky\": false,
      \"ingredient_decimals\": 3,
      \"comments\": false,
      \"shopping_auto_sync\": 10,
      \"mealplan_autoadd_shopping\": true,
      \"food_inherit_default\": \"ENABLED\",
      \"default_delay\": 2.5,
      \"mealplan_autoinclude_related\": false,
      \"mealplan_autoexclude_onhand\": true,
      \"shopping_share\": [],
      \"shopping_recent_days\": 14,
      \"csv_delim\": \";\",
      \"csv_prefix\": \"*\",
      \"filter_to_supermarket\": true,
      \"shopping_add_onhand\": true,
      \"left_handed\": true,
      \"show_step_ingredients\": false,
      \"food_children_exist\": true
    }"

  let assert Ok(decoded_json) = json.parse(json_str, using: decode.dynamic)
  let result = user_preference_decoder.decode(decoded_json)

  should.be_ok(result)
  let assert Ok(pref) = result

  should.equal(pref.theme, "FLATLY")
  should.equal(pref.use_fractions, True)
  should.equal(pref.use_kj, True)
  should.equal(pref.ingredient_decimals, 3)
  should.equal(pref.left_handed, True)

  // Verify image is present
  case pref.image {
    Some(img) -> {
      img.id |> should.equal(10)
      img.name |> should.equal("avatar.jpg")
      img.file_size_kb |> should.equal(150)
    }
    None -> should.fail()
  }
}

pub fn user_preference_decoder_missing_required_field_test() {
  let json_str =
    "{
      \"theme\": \"BOOTSTRAP\",
      \"default_unit\": \"g\"
    }"

  let assert Ok(decoded_json) = json.parse(json_str, using: decode.dynamic)
  let result = user_preference_decoder.decode(decoded_json)

  should.be_error(result)
}
