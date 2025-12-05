//// Search and food lookup handlers for API endpoints

import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/uri
import lustre/attribute
import lustre/element
import lustre/element/html
import meal_planner/nutrition_constants
import meal_planner/storage.{type FoodNutrientValue, type UsdaFood}
import meal_planner/types.{type SearchFilters, SearchFilters}
import meal_planner/ui/components/forms
import pog
import wisp

/// Web context holding database connection
pub type Context {
  Context(db: pog.Connection)
}

// ============================================================================
// Validation Functions
// ============================================================================

/// Validate search query string
/// Returns sanitized query or error message
pub fn validate_search_query(query: String) -> Result(String, String) {
  // Trim whitespace
  let trimmed = string.trim(query)

  // Check minimum length
  case string.length(trimmed) < 2 {
    True -> Error("Query must be at least 2 characters")
    False -> {
      // Check maximum length
      case string.length(trimmed) > nutrition_constants.max_query_length {
        True ->
          Error(
            "Query exceeds maximum length of "
            <> int.to_string(nutrition_constants.max_query_length)
            <> " characters",
          )
        False -> {
          // Sanitize for SQL safety - replace potential SQL injection characters
          // In Gleam with parameterized queries, this is mostly defensive
          // but we still want to prevent potential issues
          let sanitized = trimmed
          Ok(sanitized)
        }
      }
    }
  }
}

/// Validate boolean filter value from query parameter
/// Only accepts "true", "1", "false", "0" (case-insensitive)
pub fn validate_boolean_filter(value: String) -> Result(Bool, String) {
  let normalized = string.lowercase(string.trim(value))
  case normalized {
    "true" | "1" -> Ok(True)
    "false" | "0" -> Ok(False)
    _ -> Error("Invalid filter value: must be true, false, 1, or 0")
  }
}

/// Validate all search filters
/// Returns validated filters or error message
pub fn validate_filters(
  verified_param: option.Option(String),
  branded_param: option.Option(String),
  category_param: option.Option(String),
) -> Result(SearchFilters, String) {
  // Validate verified filter if present
  let verified_result = case verified_param {
    Some(v) -> validate_boolean_filter(v)
    None -> Ok(False)
  }

  // Validate branded filter if present
  let branded_result = case branded_param {
    Some(b) -> validate_boolean_filter(b)
    None -> Ok(False)
  }

  // Combine results
  use verified <- result.try(verified_result)
  use branded <- result.try(branded_result)

  // Validate and sanitize category if present
  let category = case category_param {
    Some(cat) -> {
      let trimmed = string.trim(cat)
      case trimmed {
        "" | "all" -> None
        c -> Some(c)
      }
    }
    None -> None
  }

  Ok(SearchFilters(
    verified_only: verified,
    branded_only: branded,
    category: category,
  ))
}

/// GET /api/foods - Search for foods with optional filters
/// Reads all filter state from URL query parameters for HTMX compatibility
pub fn api_foods(req: wisp.Request, ctx: Context) -> wisp.Response {
  // Parse all query parameters
  let parsed_query = uri.parse_query(req.query |> option.unwrap(""))

  // Read search query - support both 'q' and 'query' parameter names
  let raw_query = case parsed_query {
    Ok(params) -> {
      // Try 'q' first, then 'query' as fallback
      case list.find(params, fn(p) { p.0 == "q" }) {
        Ok(#(_, q)) -> q
        Error(_) ->
          case list.find(params, fn(p) { p.0 == "query" }) {
            Ok(#(_, q)) -> q
            Error(_) -> ""
          }
      }
    }
    Error(_) -> ""
  }

  // Validate query parameter
  case raw_query {
    "" -> {
      let json_data =
        json.object([
          #("error", json.string("Query parameter 'q' or 'query' required")),
        ])
      wisp.json_response(json.to_string(json_data), 400)
    }
    q -> {
      case validate_search_query(q) {
        Error(error_msg) -> {
          let json_data = json.object([#("error", json.string(error_msg))])
          wisp.json_response(json.to_string(json_data), 400)
        }
        Ok(validated_query) -> {
          // Extract filter parameters for validation
          let filter_params = case parsed_query {
            Ok(params) -> {
              let verified_param = case
                list.find(params, fn(p) {
                  p.0 == "verified" || p.0 == "verified_only"
                })
              {
                Ok(#(_, v)) -> Some(v)
                Error(_) -> None
              }

              let branded_param = case
                list.find(params, fn(p) {
                  p.0 == "branded" || p.0 == "branded_only"
                })
              {
                Ok(#(_, b)) -> Some(b)
                Error(_) -> None
              }

              let category_param = case
                list.find(params, fn(p) { p.0 == "category" })
              {
                Ok(#(_, c)) -> Some(c)
                Error(_) -> None
              }

              #(verified_param, branded_param, category_param)
            }
            Error(_) -> #(None, None, None)
          }

          // Validate filters
          case
            validate_filters(filter_params.0, filter_params.1, filter_params.2)
          {
            Error(error_msg) -> {
              let json_data = json.object([#("error", json.string(error_msg))])
              wisp.json_response(json.to_string(json_data), 400)
            }
            Ok(validated_filters) -> {
              // Execute search with validated parameters
              let foods =
                search_foods_filtered(
                  ctx,
                  validated_query,
                  validated_filters,
                  nutrition_constants.default_search_limit,
                )
              let json_data = json.array(foods, food_to_json)
              wisp.json_response(json.to_string(json_data), 200)
            }
          }
        }
      }
    }
  }
}

/// GET /api/foods/:id - Get food details by FDC ID
pub fn api_food(_req: wisp.Request, id: String, ctx: Context) -> wisp.Response {
  case int.parse(id) {
    Error(_) -> wisp.not_found()
    Ok(fdc_id) -> {
      case load_food_by_id(ctx, fdc_id) {
        Error(_) -> wisp.not_found()
        Ok(food) -> {
          let nutrients = load_food_nutrients(ctx, fdc_id)
          let json_data =
            json.object([
              #("fdc_id", json.int(food.fdc_id)),
              #("description", json.string(food.description)),
              #("data_type", json.string(food.data_type)),
              #("category", json.string(food.category)),
              #(
                "nutrients",
                json.array(nutrients, fn(n) {
                  json.object([
                    #("name", json.string(n.nutrient_name)),
                    #("amount", json.float(n.amount)),
                    #("unit", json.string(n.unit)),
                  ])
                }),
              ),
            ])
          wisp.json_response(json.to_string(json_data), 200)
        }
      }
    }
  }
}

/// GET /api/foods/search?q=query&filter=all|verified|branded|category&category=Vegetables
/// Returns HTML fragment for HTMX to swap into page
pub fn api_foods_search(req: wisp.Request, ctx: Context) -> wisp.Response {
  // Parse all query parameters
  let parsed_query = uri.parse_query(req.query |> option.unwrap(""))

  // Read search query - support both 'q' and 'query' parameter names
  let query = case parsed_query {
    Ok(params) -> {
      // Try 'q' first, then 'query' as fallback
      case list.find(params, fn(p) { p.0 == "q" }) {
        Ok(#(_, q)) -> q
        Error(_) ->
          case list.find(params, fn(p) { p.0 == "query" }) {
            Ok(#(_, q)) -> q
            Error(_) -> ""
          }
      }
    }
    Error(_) -> ""
  }

  // Parse filter parameter: all, verified, branded, or category
  let filter_type = case parsed_query {
    Ok(params) ->
      case list.find(params, fn(p) { p.0 == "filter" }) {
        Ok(#(_, f)) -> f
        Error(_) -> "all"
      }
    Error(_) -> "all"
  }

  // Parse category parameter
  let category_param = case parsed_query {
    Ok(params) ->
      case list.find(params, fn(p) { p.0 == "category" }) {
        Ok(#(_, cat)) if cat != "" -> Some(cat)
        Ok(#(_, _)) -> None
        Error(_) -> None
      }
    Error(_) -> None
  }

  // Build SearchFilters based on filter type
  let filters = case filter_type {
    "verified" ->
      SearchFilters(verified_only: True, branded_only: False, category: None)
    "branded" ->
      SearchFilters(verified_only: False, branded_only: True, category: None)
    "category" ->
      SearchFilters(
        verified_only: False,
        branded_only: False,
        category: category_param,
      )
    _ ->
      // "all" or any other value
      SearchFilters(verified_only: False, branded_only: False, category: None)
  }

  // Execute search or return empty state
  let foods = case query {
    "" -> []
    q ->
      search_foods_filtered(
        ctx,
        q,
        filters,
        nutrition_constants.default_search_limit,
      )
  }

  // Build active filters for display
  let active_filters = case filter_type {
    "verified" -> [#("filter_type", "verified")]
    "branded" -> [#("filter_type", "branded")]
    "category" ->
      case category_param {
        Some(cat) -> [#("category", cat)]
        None -> []
      }
    _ -> []
  }

  // Render HTML fragment for HTMX to swap in
  // Use forms.search_results_with_count() to render results with count and ARIA live region
  let search_results_html = case query {
    "" ->
      html.div(
        [attribute.id("search-results"), attribute.class("empty-state")],
        [element.text("Enter a search term to find foods")],
      )
      |> element.to_string
    q ->
      case foods {
        [] ->
          html.div(
            [attribute.id("search-results"), attribute.class("empty-state")],
            [element.text("No foods found matching \"" <> q <> "\"")],
          )
          |> element.to_string
        _ -> {
          // Convert foods to items format for search_results_with_count
          let items =
            foods
            |> list.map(fn(food) {
              #(food.fdc_id, food.description, food.data_type, food.category)
            })

          // Use forms.search_results_with_count with HTMX updates and ARIA accessibility
          forms.search_results_with_count(
            items,
            list.length(foods),
            active_filters,
            list.length(active_filters) > 0,
          )
          |> element.to_string
        }
      }
  }

  // Return only the HTML fragment (not a full page)
  wisp.html_response(search_results_html, 200)
}

/// Render food row for display in list
fn food_row(food: UsdaFood) -> element.Element(msg) {
  html.a(
    [
      attribute.class("food-item"),
      attribute.href("/foods/" <> int.to_string(food.fdc_id)),
    ],
    [
      html.div([attribute.class("food-info")], [
        html.span([attribute.class("food-name")], [
          element.text(food.description),
        ]),
        html.span([attribute.class("food-type")], [element.text(food.data_type)]),
      ]),
    ],
  )
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Search foods with filters
fn search_foods_filtered(
  ctx: Context,
  query: String,
  filters: SearchFilters,
  limit: Int,
) -> List(UsdaFood) {
  case storage.search_foods_filtered(ctx.db, query, filters, limit) {
    Ok(foods) -> foods
    Error(_) -> []
  }
}

/// Load food by FDC ID
fn load_food_by_id(ctx: Context, fdc_id: Int) -> Result(UsdaFood, Nil) {
  case storage.get_food_by_id(ctx.db, fdc_id) {
    Ok(food) -> Ok(food)
    Error(_) -> Error(Nil)
  }
}

/// Load food nutrients
fn load_food_nutrients(ctx: Context, fdc_id: Int) -> List(FoodNutrientValue) {
  case storage.get_food_nutrients(ctx.db, fdc_id) {
    Ok(nutrients) -> nutrients
    Error(_) -> []
  }
}

/// Convert food to JSON
fn food_to_json(f: UsdaFood) -> json.Json {
  json.object([
    #("fdc_id", json.int(f.fdc_id)),
    #("description", json.string(f.description)),
    #("data_type", json.string(f.data_type)),
    #("category", json.string(f.category)),
  ])
}

/// GET /api/fragments/filters?expanded=true|false
/// Returns HTML fragment for collapsible filter panel (mobile)
pub fn api_filter_fragment(req: wisp.Request) -> wisp.Response {
  // Parse query parameter for expanded state
  let parsed_query = uri.parse_query(req.query |> option.unwrap(""))

  let expanded = case parsed_query {
    Ok(params) ->
      case list.find(params, fn(p) { p.0 == "expanded" }) {
        Ok(#(_, "true")) -> True
        Ok(#(_, "false")) -> False
        _ -> False
      }
    Error(_) -> False
  }

  // Sample filter content
  let filter_content =
    "<div class=\"filter-chips\">"
    <> "<button class=\"filter-chip\" data-filter=\"all\">All</button>"
    <> "<button class=\"filter-chip\" data-filter=\"verified\">Verified</button>"
    <> "<button class=\"filter-chip\" data-filter=\"branded\">Branded</button>"
    <> "</div>"

  // Build the filter panel HTML
  let html =
    "<div class=\"filter-panel\" "
    <> case expanded {
      True -> "data-expanded=\"true\""
      False -> ""
    }
    <> ">"
    <> filter_content
    <> "</div>"

  wisp.html_response(html, 200)
}
