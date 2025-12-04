//// Search and food lookup handlers for API endpoints

import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/uri
import meal_planner/storage.{type FoodNutrientValue, type UsdaFood}
import meal_planner/types.{type SearchFilters, SearchFilters}
import pog
import wisp

/// Web context holding database connection
pub type Context {
  Context(db: pog.Connection)
}

/// GET /api/foods - Search for foods with optional filters
/// Reads all filter state from URL query parameters for HTMX compatibility
pub fn api_foods(req: wisp.Request, ctx: Context) -> wisp.Response {
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

  // Parse all filter parameters from URL query string
  // This ensures the handler is stateless and works with HTMX URL-based state
  let filters = case parsed_query {
    Ok(params) -> {
      // Parse verified filter - accepts "true" string or "1"
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified" || p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        Ok(#(_, "1")) -> True
        _ -> False
      }

      // Parse branded filter - accepts "true" string or "1"
      let branded_only = case
        list.find(params, fn(p) { p.0 == "branded" || p.0 == "branded_only" })
      {
        Ok(#(_, "true")) -> True
        Ok(#(_, "1")) -> True
        _ -> False
      }

      // Parse category filter - empty string treated as None
      let category = case list.find(params, fn(p) { p.0 == "category" }) {
        Ok(#(_, cat)) if cat != "" && cat != "all" -> Some(cat)
        _ -> None
      }

      types.SearchFilters(
        verified_only: verified_only,
        branded_only: branded_only,
        category: category,
      )
    }
    Error(_) ->
      // Default filters when no query params
      types.SearchFilters(
        verified_only: False,
        branded_only: False,
        category: None,
      )
  }

  case query {
    "" -> {
      let json_data =
        json.object([
          #("error", json.string("Query parameter 'q' or 'query' required")),
        ])
      wisp.json_response(json.to_string(json_data), 400)
    }
    q -> {
      let foods = search_foods_filtered(ctx, q, filters, 50)
      let json_data = json.array(foods, food_to_json)
      wisp.json_response(json.to_string(json_data), 200)
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
