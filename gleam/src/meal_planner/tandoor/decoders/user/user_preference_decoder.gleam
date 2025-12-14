/// UserPreference decoder for Tandoor SDK
///
/// This module provides JSON decoders for UserPreference types from Tandoor API.
import gleam/dynamic/decode
import gleam/option.{None}
import meal_planner/tandoor/decoders/user/user_decoder
import meal_planner/tandoor/decoders/user/user_file_view_decoder
import meal_planner/tandoor/types/user/user_preference.{UserPreference}

/// Decode a UserPreference from JSON
///
/// Decodes complete user preferences from Tandoor API.
/// Handles nullable fields (image, plan_share, shopping_share) appropriately.
///
/// ## Example JSON
/// ```json
/// {
///   "user": { ...user object... },
///   "image": null,
///   "theme": "BOOTSTRAP",
///   "nav_bg_color": "#212529",
///   "nav_text_color": "LIGHT",
///   ...
/// }
/// ```
pub fn decode(
  json: dynamic.Dynamic,
) -> Result(UserPreference, List(decode.DecodeError)) {
  use user <- decode.field("user", user_decoder.decode)
  use image <- decode.field(
    "image",
    decode.optional(user_file_view_decoder.decode),
  )
  use theme <- decode.field("theme", decode.string)
  use nav_bg_color <- decode.field("nav_bg_color", decode.string)
  use nav_text_color <- decode.field("nav_text_color", decode.string)
  use nav_show_logo <- decode.field("nav_show_logo", decode.bool)
  use default_unit <- decode.field("default_unit", decode.string)
  use default_page <- decode.field("default_page", decode.string)
  use use_fractions <- decode.field("use_fractions", decode.bool)
  use use_kj <- decode.field("use_kj", decode.bool)
  use plan_share <- decode.field(
    "plan_share",
    decode.optional(decode.list(user_decoder.decode)),
  )
  use nav_sticky <- decode.field("nav_sticky", decode.bool)
  use ingredient_decimals <- decode.field("ingredient_decimals", decode.int)
  use comments <- decode.field("comments", decode.bool)
  use shopping_auto_sync <- decode.field("shopping_auto_sync", decode.int)
  use mealplan_autoadd_shopping <- decode.field(
    "mealplan_autoadd_shopping",
    decode.bool,
  )
  use food_inherit_default <- decode.field(
    "food_inherit_default",
    decode.string,
  )
  use default_delay <- decode.field("default_delay", decode.float)
  use mealplan_autoinclude_related <- decode.field(
    "mealplan_autoinclude_related",
    decode.bool,
  )
  use mealplan_autoexclude_onhand <- decode.field(
    "mealplan_autoexclude_onhand",
    decode.bool,
  )
  use shopping_share <- decode.field(
    "shopping_share",
    decode.optional(decode.list(user_decoder.decode)),
  )
  use shopping_recent_days <- decode.field("shopping_recent_days", decode.int)
  use csv_delim <- decode.field("csv_delim", decode.string)
  use csv_prefix <- decode.field("csv_prefix", decode.string)
  use filter_to_supermarket <- decode.field(
    "filter_to_supermarket",
    decode.bool,
  )
  use shopping_add_onhand <- decode.field("shopping_add_onhand", decode.bool)
  use left_handed <- decode.field("left_handed", decode.bool)
  use show_step_ingredients <- decode.field(
    "show_step_ingredients",
    decode.bool,
  )
  use food_children_exist <- decode.field("food_children_exist", decode.bool)

  decode.success(UserPreference(
    user: user,
    image: image,
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
    food_inherit_default: food_inherit_default,
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
    food_children_exist: food_children_exist,
  ))
  |> decode.run(json)
}
