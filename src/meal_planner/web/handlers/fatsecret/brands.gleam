/// FatSecret Food Brands handler
///
/// Handles GET requests for the /api/fatsecret/brands endpoint.
/// Supports filtering by starting letter and brand type.
import gleam/http
import gleam/json
import gleam/option.{type Option, None, Some}
import meal_planner/env
import meal_planner/fatsecret/food_brands/client
import meal_planner/fatsecret/food_brands/types
import meal_planner/fatsecret/handlers_helpers as helpers
import wisp

/// Handle brands endpoint requests
///
/// Supports GET method only to list all brands from FatSecret.
/// Query parameters:
/// - starts_with: Filter brands by starting letter (e.g., "K")
/// - brand_type: Filter by type ("manufacturer", "restaurant", "supermarket")
pub fn handle_brands(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_get_brands(req)
    _ -> wisp.method_not_allowed([http.Get])
  }
}

fn handle_get_brands(req: wisp.Request) -> wisp.Response {
  // Get FatSecret config
  case env.load_fatsecret_config() {
    None -> helpers.error_response(500, "FatSecret API not configured")
    Some(config) -> {
      // Parse query parameters
      let query = wisp.get_query(req)
      let starts_with = helpers.get_query_param(query, "starts_with")
      let brand_type = parse_brand_type(query)

      // Call FatSecret API
      case client.list_brands_with_options(config, starts_with, brand_type) {
        Ok(response) -> {
          // Encode brands as JSON array
          let brands_json =
            json.array(response.brands, fn(brand) {
              json.object([
                #(
                  "brand_id",
                  json.string(types.brand_id_to_string(brand.brand_id)),
                ),
                #("brand_name", json.string(brand.brand_name)),
                #(
                  "brand_type",
                  json.string(types.brand_type_to_string(brand.brand_type)),
                ),
              ])
            })

          // Return JSON response
          json.object([#("brands", brands_json)])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> helpers.error_response(500, "Failed to fetch brands")
      }
    }
  }
}

/// Parse brand_type query parameter to BrandType
fn parse_brand_type(params: List(#(String, String))) -> Option(types.BrandType) {
  case helpers.get_query_param(params, "brand_type") {
    None -> None
    Some(type_str) -> {
      case types.brand_type_from_string(type_str) {
        Ok(brand_type) -> Some(brand_type)
        Error(_) -> None
      }
    }
  }
}
