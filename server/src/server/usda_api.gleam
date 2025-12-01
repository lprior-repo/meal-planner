//// USDA FoodData Central API endpoints
//// Provides search and food detail from USDA database

import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import server/storage
import sqlight
import wisp

// ============================================================================
// USDA Search Types
// ============================================================================

type UsdaFood {
  UsdaFood(
    fdc_id: Int,
    description: String,
    food_category: option.Option(String),
  )
}

type FoodNutrient {
  FoodNutrient(nutrient_name: String, amount: Float, unit: String)
}

// ============================================================================
// API Handlers
// ============================================================================

/// Search for USDA foods by query string
/// GET /api/foods/search?q=chicken
pub fn handle_search(req: wisp.Request) -> wisp.Response {
  // Get query parameter
  let query = case wisp.get_query(req) {
    [#("q", q), ..] -> q
    _ -> ""
  }

  // Minimum query length
  case string.length(query) < 2 {
    True -> {
      let empty = json.array([], fn(x) { x })
      wisp.json_response(json.to_string(empty), 200)
    }
    False -> {
      use conn <- storage.with_connection(storage.db_path)

      // Use FTS5 for fast full-text search
      let sql =
        "SELECT f.fdc_id, f.description, f.food_category
         FROM foods_fts
         JOIN foods f ON foods_fts.rowid = f.fdc_id
         WHERE foods_fts.description MATCH ?
         LIMIT 20"

      let pattern = query <> "*"

      let decoder = food_search_decoder()

      case
        sqlight.query(
          sql,
          on: conn,
          with: [sqlight.text(pattern)],
          expecting: decoder,
        )
      {
        Ok(results) -> {
          let json_results =
            json.array(results, fn(food) {
              json.object([
                #("fdc_id", json.int(food.fdc_id)),
                #("description", json.string(food.description)),
                #("food_category", case food.food_category {
                  Some(cat) -> json.string(cat)
                  None -> json.null()
                }),
              ])
            })
          wisp.json_response(json.to_string(json_results), 200)
        }
        Error(e) -> {
          let error = json.object([#("error", json.string(e.message))])
          wisp.json_response(json.to_string(error), 500)
        }
      }
    }
  }
}

/// Get detailed food information including nutrients
/// GET /api/foods/:fdc_id
pub fn handle_get_food(_req: wisp.Request, fdc_id_str: String) -> wisp.Response {
  case int.parse(fdc_id_str) {
    Error(_) -> {
      let error = json.object([#("error", json.string("Invalid fdc_id"))])
      wisp.json_response(json.to_string(error), 400)
    }
    Ok(fdc_id) -> {
      use conn <- storage.with_connection(storage.db_path)

      // Get food details
      let food_sql =
        "SELECT fdc_id, description, food_category FROM foods WHERE fdc_id = ?"

      let food_decoder = food_detail_decoder()

      case
        sqlight.query(
          food_sql,
          on: conn,
          with: [sqlight.int(fdc_id)],
          expecting: food_decoder,
        )
      {
        Error(e) -> {
          let error = json.object([#("error", json.string(e.message))])
          wisp.json_response(json.to_string(error), 500)
        }
        Ok([]) -> wisp.not_found()
        Ok([food]) -> {
          // Get macronutrients (Protein, Fat, Carbs)
          let nutrients_sql =
            "SELECT n.name, fn.amount, n.unit_name
             FROM food_nutrients fn
             JOIN nutrients n ON fn.nutrient_id = n.id
             WHERE fn.fdc_id = ?
             AND n.name IN ('Protein', 'Total lipid (fat)', 'Carbohydrate, by difference', 'Energy')
             AND fn.amount IS NOT NULL"

          let nutrient_decoder = nutrient_decoder()

          case
            sqlight.query(
              nutrients_sql,
              on: conn,
              with: [sqlight.int(fdc_id)],
              expecting: nutrient_decoder,
            )
          {
            Error(e) -> {
              let error = json.object([#("error", json.string(e.message))])
              wisp.json_response(json.to_string(error), 500)
            }
            Ok(nutrients) -> {
              let json_food =
                json.object([
                  #("fdc_id", json.int(food.fdc_id)),
                  #("description", json.string(food.description)),
                  #("food_category", case food.food_category {
                    Some(cat) -> json.string(cat)
                    None -> json.null()
                  }),
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
              wisp.json_response(json.to_string(json_food), 200)
            }
          }
        }
        Ok(_) -> {
          // Multiple results shouldn't happen with primary key
          let error =
            json.object([#("error", json.string("Unexpected multiple results"))])
          wisp.json_response(json.to_string(error), 500)
        }
      }
    }
  }
}

// ============================================================================
// Decoders
// ============================================================================

fn food_search_decoder() -> decode.Decoder(UsdaFood) {
  use fdc_id <- decode.field(0, decode.int)
  use description <- decode.field(1, decode.string)
  use food_category <- decode.field(2, decode.optional(decode.string))

  decode.success(UsdaFood(
    fdc_id: fdc_id,
    description: description,
    food_category: food_category,
  ))
}

fn food_detail_decoder() -> decode.Decoder(UsdaFood) {
  use fdc_id <- decode.field(0, decode.int)
  use description <- decode.field(1, decode.string)
  use food_category <- decode.field(2, decode.optional(decode.string))

  decode.success(UsdaFood(
    fdc_id: fdc_id,
    description: description,
    food_category: food_category,
  ))
}

fn nutrient_decoder() -> decode.Decoder(FoodNutrient) {
  use name <- decode.field(0, decode.string)
  use amount <- decode.field(1, decode.float)
  use unit <- decode.field(2, decode.string)

  decode.success(FoodNutrient(nutrient_name: name, amount: amount, unit: unit))
}
