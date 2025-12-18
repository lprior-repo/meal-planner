/// UserPreference encoder for Tandoor SDK
///
/// This module provides JSON encoders for updating user preferences via Tandoor API.
/// Only writable fields are included - readonly fields (user, food_inherit_default,
/// food_children_exist) are excluded from update requests.
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

/// Request to update user preferences
///
/// Contains only the writable fields that can be updated via PATCH.
/// Readonly fields (user, food_inherit_default, food_children_exist) are excluded.
pub type UserPreferenceUpdateRequest {
  UserPreferenceUpdateRequest(
    theme: Option(String),
    nav_bg_color: Option(String),
    nav_text_color: Option(String),
    nav_show_logo: Option(Bool),
    default_unit: Option(String),
    default_page: Option(String),
    use_fractions: Option(Bool),
    use_kj: Option(Bool),
    plan_share: Option(List(Int)),
    nav_sticky: Option(Bool),
    ingredient_decimals: Option(Int),
    comments: Option(Bool),
    shopping_auto_sync: Option(Int),
    mealplan_autoadd_shopping: Option(Bool),
    default_delay: Option(Float),
    mealplan_autoinclude_related: Option(Bool),
    mealplan_autoexclude_onhand: Option(Bool),
    shopping_share: Option(List(Int)),
    shopping_recent_days: Option(Int),
    csv_delim: Option(String),
    csv_prefix: Option(String),
    filter_to_supermarket: Option(Bool),
    shopping_add_onhand: Option(Bool),
    left_handed: Option(Bool),
    show_step_ingredients: Option(Bool),
  )
}

/// Encode UserPreferenceUpdateRequest to JSON for API updates
///
/// Converts only the provided (Some) fields to JSON for partial updates.
/// None values are omitted from the request.
pub fn encode_update(req: UserPreferenceUpdateRequest) -> Json {
  let fields =
    []
    |> add_optional_string_field("theme", req.theme)
    |> add_optional_string_field("nav_bg_color", req.nav_bg_color)
    |> add_optional_string_field("nav_text_color", req.nav_text_color)
    |> add_optional_bool_field("nav_show_logo", req.nav_show_logo)
    |> add_optional_string_field("default_unit", req.default_unit)
    |> add_optional_string_field("default_page", req.default_page)
    |> add_optional_bool_field("use_fractions", req.use_fractions)
    |> add_optional_bool_field("use_kj", req.use_kj)
    |> add_optional_int_list_field("plan_share", req.plan_share)
    |> add_optional_bool_field("nav_sticky", req.nav_sticky)
    |> add_optional_int_field("ingredient_decimals", req.ingredient_decimals)
    |> add_optional_bool_field("comments", req.comments)
    |> add_optional_int_field("shopping_auto_sync", req.shopping_auto_sync)
    |> add_optional_bool_field(
      "mealplan_autoadd_shopping",
      req.mealplan_autoadd_shopping,
    )
    |> add_optional_float_field("default_delay", req.default_delay)
    |> add_optional_bool_field(
      "mealplan_autoinclude_related",
      req.mealplan_autoinclude_related,
    )
    |> add_optional_bool_field(
      "mealplan_autoexclude_onhand",
      req.mealplan_autoexclude_onhand,
    )
    |> add_optional_int_list_field("shopping_share", req.shopping_share)
    |> add_optional_int_field("shopping_recent_days", req.shopping_recent_days)
    |> add_optional_string_field("csv_delim", req.csv_delim)
    |> add_optional_string_field("csv_prefix", req.csv_prefix)
    |> add_optional_bool_field(
      "filter_to_supermarket",
      req.filter_to_supermarket,
    )
    |> add_optional_bool_field("shopping_add_onhand", req.shopping_add_onhand)
    |> add_optional_bool_field("left_handed", req.left_handed)
    |> add_optional_bool_field(
      "show_step_ingredients",
      req.show_step_ingredients,
    )

  json.object(fields)
}

// Helper functions for building optional fields

fn add_optional_string_field(
  fields: List(#(String, Json)),
  name: String,
  value: Option(String),
) -> List(#(String, Json)) {
  case value {
    Some(v) -> [#(name, json.string(v)), ..fields]
    None -> fields
  }
}

fn add_optional_bool_field(
  fields: List(#(String, Json)),
  name: String,
  value: Option(Bool),
) -> List(#(String, Json)) {
  case value {
    Some(v) -> [#(name, json.bool(v)), ..fields]
    None -> fields
  }
}

fn add_optional_int_field(
  fields: List(#(String, Json)),
  name: String,
  value: Option(Int),
) -> List(#(String, Json)) {
  case value {
    Some(v) -> [#(name, json.int(v)), ..fields]
    None -> fields
  }
}

fn add_optional_float_field(
  fields: List(#(String, Json)),
  name: String,
  value: Option(Float),
) -> List(#(String, Json)) {
  case value {
    Some(v) -> [#(name, json.float(v)), ..fields]
    None -> fields
  }
}

fn add_optional_int_list_field(
  fields: List(#(String, Json)),
  name: String,
  value: Option(List(Int)),
) -> List(#(String, Json)) {
  case value {
    Some(ids) -> [#(name, json.array(ids, json.int)), ..fields]
    None -> fields
  }
}
