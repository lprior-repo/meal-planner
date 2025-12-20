/// User preferences web handlers for Tandoor Recipe Manager
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/option
import gleam/result

import meal_planner/tandoor/core/ids
import meal_planner/tandoor/handlers/helpers
import meal_planner/tandoor/user.{
  type UserPreference, type UserPreferenceUpdateRequest,
  UserPreferenceUpdateRequest, get_current_user_preferences, update_user_preferences,
}

import wisp

/// Handle preferences endpoint (GET current user, PUT update current user)
pub fn handle_preferences(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_get_preferences(req)
    http.Put -> handle_update_preferences(req)
    _ -> wisp.method_not_allowed([http.Get, http.Put])
  }
}

// =============================================================================
// Private Handler Functions
// =============================================================================

fn handle_get_preferences(_req: wisp.Request) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case get_current_user_preferences(config) {
        Ok(preferences) -> {
          encode_user_preference(preferences)
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> helpers.error_response(500, "Failed to get user preferences")
      }
    }
    Error(resp) -> resp
  }
}

fn handle_update_preferences(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_user_preference_update_request(body) {
    Ok(update_request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          // First get current preferences to get the user_id
          case get_current_user_preferences(config) {
            Ok(current_prefs) -> {
              case
                update_user_preferences(
                  config,
                  user_id: current_prefs.user.id,
                  update: update_request,
                )
              {
                Ok(updated_prefs) -> {
                  encode_user_preference(updated_prefs)
                  |> json.to_string
                  |> wisp.json_response(200)
                }
                Error(_) ->
                  helpers.error_response(500, "Failed to update user preferences")
              }
            }
            Error(_) ->
              helpers.error_response(
                500,
                "Failed to get current user preferences",
              )
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

// =============================================================================
// JSON Encoding
// =============================================================================

fn encode_user_preference(pref: UserPreference) -> json.Json {
  json.object([
    #(
      "user",
      json.object([
        #("id", json.int(ids.user_id_to_int(pref.user.id))),
        #("username", json.string(pref.user.username)),
        #("first_name", json.string(pref.user.first_name)),
        #("last_name", json.string(pref.user.last_name)),
        #("display_name", json.string(pref.user.display_name)),
        #("is_staff", json.bool(pref.user.is_staff)),
        #("is_superuser", json.bool(pref.user.is_superuser)),
        #("is_active", json.bool(pref.user.is_active)),
      ]),
    ),
    #(
      "image",
      case pref.image {
        option.Some(img) -> encode_user_file_view(img)
        option.None -> json.null()
      },
    ),
    #("theme", json.string(pref.theme)),
    #("nav_bg_color", json.string(pref.nav_bg_color)),
    #("nav_text_color", json.string(pref.nav_text_color)),
    #("nav_show_logo", json.bool(pref.nav_show_logo)),
    #("default_unit", json.string(pref.default_unit)),
    #("default_page", json.string(pref.default_page)),
    #("use_fractions", json.bool(pref.use_fractions)),
    #("use_kj", json.bool(pref.use_kj)),
    #(
      "plan_share",
      case pref.plan_share {
        option.Some(users) -> json.array(users, encode_user)
        option.None -> json.null()
      },
    ),
    #("nav_sticky", json.bool(pref.nav_sticky)),
    #("ingredient_decimals", json.int(pref.ingredient_decimals)),
    #("comments", json.bool(pref.comments)),
    #("shopping_auto_sync", json.int(pref.shopping_auto_sync)),
    #("mealplan_autoadd_shopping", json.bool(pref.mealplan_autoadd_shopping)),
    #("food_inherit_default", json.string(pref.food_inherit_default)),
    #("default_delay", json.float(pref.default_delay)),
    #(
      "mealplan_autoinclude_related",
      json.bool(pref.mealplan_autoinclude_related),
    ),
    #(
      "mealplan_autoexclude_onhand",
      json.bool(pref.mealplan_autoexclude_onhand),
    ),
    #(
      "shopping_share",
      case pref.shopping_share {
        option.Some(users) -> json.array(users, encode_user)
        option.None -> json.null()
      },
    ),
    #("shopping_recent_days", json.int(pref.shopping_recent_days)),
    #("csv_delim", json.string(pref.csv_delim)),
    #("csv_prefix", json.string(pref.csv_prefix)),
    #("filter_to_supermarket", json.bool(pref.filter_to_supermarket)),
    #("shopping_add_onhand", json.bool(pref.shopping_add_onhand)),
    #("left_handed", json.bool(pref.left_handed)),
    #("show_step_ingredients", json.bool(pref.show_step_ingredients)),
    #("food_children_exist", json.bool(pref.food_children_exist)),
  ])
}

fn encode_user(user: user.User) -> json.Json {
  json.object([
    #("id", json.int(ids.user_id_to_int(user.id))),
    #("username", json.string(user.username)),
    #("first_name", json.string(user.first_name)),
    #("last_name", json.string(user.last_name)),
    #("display_name", json.string(user.display_name)),
    #("is_staff", json.bool(user.is_staff)),
    #("is_superuser", json.bool(user.is_superuser)),
    #("is_active", json.bool(user.is_active)),
  ])
}

fn encode_user_file_view(file: user.UserFileView) -> json.Json {
  json.object([
    #("id", json.int(file.id)),
    #("name", json.string(file.name)),
    #("file_download", json.string(file.file_download)),
    #("preview", json.string(file.preview)),
    #("file_size_kb", json.int(file.file_size_kb)),
    #("created_by", encode_user(file.created_by)),
    #("created_at", json.string(file.created_at)),
  ])
}

// =============================================================================
// JSON Decoding
// =============================================================================

fn parse_user_preference_update_request(
  json_data: dynamic.Dynamic,
) -> Result(UserPreferenceUpdateRequest, String) {
  decode.run(json_data, user_preference_update_decoder())
  |> result.map_error(fn(_) { "Invalid user preference update request" })
}

fn user_preference_update_decoder() -> decode.Decoder(UserPreferenceUpdateRequest) {
  use theme <- decode.optional_field("theme", option.None, decode.optional(
    decode.string,
  ))
  use nav_bg_color <- decode.optional_field(
    "nav_bg_color",
    option.None,
    decode.optional(decode.string),
  )
  use nav_text_color <- decode.optional_field(
    "nav_text_color",
    option.None,
    decode.optional(decode.string),
  )
  use nav_show_logo <- decode.optional_field(
    "nav_show_logo",
    option.None,
    decode.optional(decode.bool),
  )
  use default_unit <- decode.optional_field(
    "default_unit",
    option.None,
    decode.optional(decode.string),
  )
  use default_page <- decode.optional_field(
    "default_page",
    option.None,
    decode.optional(decode.string),
  )
  use use_fractions <- decode.optional_field(
    "use_fractions",
    option.None,
    decode.optional(decode.bool),
  )
  use use_kj <- decode.optional_field(
    "use_kj",
    option.None,
    decode.optional(decode.bool),
  )
  use plan_share <- decode.optional_field(
    "plan_share",
    option.None,
    decode.optional(decode.list(decode.int)),
  )
  use nav_sticky <- decode.optional_field(
    "nav_sticky",
    option.None,
    decode.optional(decode.bool),
  )
  use ingredient_decimals <- decode.optional_field(
    "ingredient_decimals",
    option.None,
    decode.optional(decode.int),
  )
  use comments <- decode.optional_field(
    "comments",
    option.None,
    decode.optional(decode.bool),
  )
  use shopping_auto_sync <- decode.optional_field(
    "shopping_auto_sync",
    option.None,
    decode.optional(decode.int),
  )
  use mealplan_autoadd_shopping <- decode.optional_field(
    "mealplan_autoadd_shopping",
    option.None,
    decode.optional(decode.bool),
  )
  use default_delay <- decode.optional_field(
    "default_delay",
    option.None,
    decode.optional(decode.float),
  )
  use mealplan_autoinclude_related <- decode.optional_field(
    "mealplan_autoinclude_related",
    option.None,
    decode.optional(decode.bool),
  )
  use mealplan_autoexclude_onhand <- decode.optional_field(
    "mealplan_autoexclude_onhand",
    option.None,
    decode.optional(decode.bool),
  )
  use shopping_share <- decode.optional_field(
    "shopping_share",
    option.None,
    decode.optional(decode.list(decode.int)),
  )
  use shopping_recent_days <- decode.optional_field(
    "shopping_recent_days",
    option.None,
    decode.optional(decode.int),
  )
  use csv_delim <- decode.optional_field(
    "csv_delim",
    option.None,
    decode.optional(decode.string),
  )
  use csv_prefix <- decode.optional_field(
    "csv_prefix",
    option.None,
    decode.optional(decode.string),
  )
  use filter_to_supermarket <- decode.optional_field(
    "filter_to_supermarket",
    option.None,
    decode.optional(decode.bool),
  )
  use shopping_add_onhand <- decode.optional_field(
    "shopping_add_onhand",
    option.None,
    decode.optional(decode.bool),
  )
  use left_handed <- decode.optional_field(
    "left_handed",
    option.None,
    decode.optional(decode.bool),
  )
  use show_step_ingredients <- decode.optional_field(
    "show_step_ingredients",
    option.None,
    decode.optional(decode.bool),
  )

  decode.success(UserPreferenceUpdateRequest(
    theme: theme,
    nav_bg_color: nav_bg_color,
    nav_text_color: nav_text_color,
    nav_show_logo: nav_show_logo,
    default_unit: default_unit,
    default_page: default_page,
    use_fractions: use_fractions,
    use_kj: use_kj,
    plan_share: plan_share,
    nav_sticky: nav_sticky,
    ingredient_decimals: ingredient_decimals,
    comments: comments,
    shopping_auto_sync: shopping_auto_sync,
    mealplan_autoadd_shopping: mealplan_autoadd_shopping,
    default_delay: default_delay,
    mealplan_autoinclude_related: mealplan_autoinclude_related,
    mealplan_autoexclude_onhand: mealplan_autoexclude_onhand,
    shopping_share: shopping_share,
    shopping_recent_days: shopping_recent_days,
    csv_delim: csv_delim,
    csv_prefix: csv_prefix,
    filter_to_supermarket: filter_to_supermarket,
    shopping_add_onhand: shopping_add_onhand,
    left_handed: left_handed,
    show_step_ingredients: show_step_ingredients,
  ))
}
