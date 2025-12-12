/// Food Log API module
///
/// Handles HTTP endpoints for logging meals with Mealie recipe slugs.
/// Provides endpoints for:
/// - Creating food log entries from Mealie recipes
/// - Retrieving daily food logs
/// - Deleting food log entries

import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import meal_planner/id
import meal_planner/storage/logs
import meal_planner/types
import pog
import wisp

// ============================================================================
// Types
// ============================================================================

/// Input for creating a food log entry via API
pub type CreateFoodLogRequest {
  CreateFoodLogRequest(
    date: String,
    recipe_slug: String,
    recipe_name: String,
    servings: Float,
    protein: Float,
    fat: Float,
    carbs: Float,
    meal_type: String,
    // Optional micronutrients
    fiber: option.Option(Float),
    sugar: option.Option(Float),
    sodium: option.Option(Float),
    cholesterol: option.Option(Float),
    vitamin_a: option.Option(Float),
    vitamin_c: option.Option(Float),
    vitamin_d: option.Option(Float),
    vitamin_e: option.Option(Float),
    vitamin_k: option.Option(Float),
    vitamin_b6: option.Option(Float),
    vitamin_b12: option.Option(Float),
    folate: option.Option(Float),
    thiamin: option.Option(Float),
    riboflavin: option.Option(Float),
    niacin: option.Option(Float),
    calcium: option.Option(Float),
    iron: option.Option(Float),
    magnesium: option.Option(Float),
    phosphorus: option.Option(Float),
    potassium: option.Option(Float),
    zinc: option.Option(Float),
  )
}

/// Response for food log creation
pub type CreateFoodLogResponse {
  CreateFoodLogResponse(id: String, recipe_name: String, servings: Float)
}

// ============================================================================
// Decoders
// ============================================================================

/// Decoder for CreateFoodLogRequest from JSON
fn create_food_log_decoder() -> decode.Decoder(CreateFoodLogRequest) {
  use date <- decode.field("date", decode.string)
  use recipe_slug <- decode.field("recipe_slug", decode.string)
  use recipe_name <- decode.field("recipe_name", decode.string)
  use servings <- decode.field("servings", decode.float)
  use protein <- decode.field("protein", decode.float)
  use fat <- decode.field("fat", decode.float)
  use carbs <- decode.field("carbs", decode.float)
  use meal_type <- decode.field("meal_type", decode.string)
  use fiber <- decode.field(
    "fiber",
    decode.optional(decode.float),
  )
  use sugar <- decode.field(
    "sugar",
    decode.optional(decode.float),
  )
  use sodium <- decode.field(
    "sodium",
    decode.optional(decode.float),
  )
  use cholesterol <- decode.field(
    "cholesterol",
    decode.optional(decode.float),
  )
  use vitamin_a <- decode.field(
    "vitamin_a",
    decode.optional(decode.float),
  )
  use vitamin_c <- decode.field(
    "vitamin_c",
    decode.optional(decode.float),
  )
  use vitamin_d <- decode.field(
    "vitamin_d",
    decode.optional(decode.float),
  )
  use vitamin_e <- decode.field(
    "vitamin_e",
    decode.optional(decode.float),
  )
  use vitamin_k <- decode.field(
    "vitamin_k",
    decode.optional(decode.float),
  )
  use vitamin_b6 <- decode.field(
    "vitamin_b6",
    decode.optional(decode.float),
  )
  use vitamin_b12 <- decode.field(
    "vitamin_b12",
    decode.optional(decode.float),
  )
  use folate <- decode.field(
    "folate",
    decode.optional(decode.float),
  )
  use thiamin <- decode.field(
    "thiamin",
    decode.optional(decode.float),
  )
  use riboflavin <- decode.field(
    "riboflavin",
    decode.optional(decode.float),
  )
  use niacin <- decode.field(
    "niacin",
    decode.optional(decode.float),
  )
  use calcium <- decode.field(
    "calcium",
    decode.optional(decode.float),
  )
  use iron <- decode.field(
    "iron",
    decode.optional(decode.float),
  )
  use magnesium <- decode.field(
    "magnesium",
    decode.optional(decode.float),
  )
  use phosphorus <- decode.field(
    "phosphorus",
    decode.optional(decode.float),
  )
  use potassium <- decode.field(
    "potassium",
    decode.optional(decode.float),
  )
  use zinc <- decode.field(
    "zinc",
    decode.optional(decode.float),
  )

  decode.success(CreateFoodLogRequest(
    date,
    recipe_slug,
    recipe_name,
    servings,
    protein,
    fat,
    carbs,
    meal_type,
    fiber,
    sugar,
    sodium,
    cholesterol,
    vitamin_a,
    vitamin_c,
    vitamin_d,
    vitamin_e,
    vitamin_k,
    vitamin_b6,
    vitamin_b12,
    folate,
    thiamin,
    riboflavin,
    niacin,
    calcium,
    iron,
    magnesium,
    phosphorus,
    potassium,
    zinc,
  ))
}

// ============================================================================
// Encoders
// ============================================================================

/// Encode CreateFoodLogResponse to JSON
fn encode_create_response(response: CreateFoodLogResponse) -> String {
  json.object([
    #("id", json.string(response.id)),
    #("recipe_name", json.string(response.recipe_name)),
    #("servings", json.float(response.servings)),
  ])
  |> json.to_string
}

// ============================================================================
// API Handlers
// ============================================================================

/// Handle POST request to create a food log entry from Mealie recipe slug
pub fn handle_create_food_log(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  // Parse request body as JSON
  case wisp.read_body_to_bitstring(req) {
    Ok(body) -> {
      // Decode the JSON request
      case json.decode(body, create_food_log_decoder()) {
        Ok(request) -> create_food_log_from_request(conn, request)
        Error(_) ->
          wisp.response(400)
          |> wisp.string_body(
            "Invalid request body. Expected JSON with food log entry fields.",
          )
      }
    }
    Error(_) ->
      wisp.response(400)
      |> wisp.string_body("Failed to read request body")
  }
}

/// Create a food log entry from a CreateFoodLogRequest
fn create_food_log_from_request(
  conn: pog.Connection,
  request: CreateFoodLogRequest,
) -> wisp.Response {
  // Validate input
  case validate_food_log_request(request) {
    Error(error_msg) ->
      wisp.response(400)
      |> wisp.string_body("Validation error: " <> error_msg)

    Ok(Nil) -> {
      // Convert request to logs.FoodLogInput
      let input = logs.FoodLogInput(
        date: request.date,
        recipe_slug: request.recipe_slug,
        recipe_name: request.recipe_name,
        servings: request.servings,
        protein: request.protein,
        fat: request.fat,
        carbs: request.carbs,
        meal_type: request.meal_type,
        fiber: request.fiber,
        sugar: request.sugar,
        sodium: request.sodium,
        cholesterol: request.cholesterol,
        vitamin_a: request.vitamin_a,
        vitamin_c: request.vitamin_c,
        vitamin_d: request.vitamin_d,
        vitamin_e: request.vitamin_e,
        vitamin_k: request.vitamin_k,
        vitamin_b6: request.vitamin_b6,
        vitamin_b12: request.vitamin_b12,
        folate: request.folate,
        thiamin: request.thiamin,
        riboflavin: request.riboflavin,
        niacin: request.niacin,
        calcium: request.calcium,
        iron: request.iron,
        magnesium: request.magnesium,
        phosphorus: request.phosphorus,
        potassium: request.potassium,
        zinc: request.zinc,
      )

      // Save to database
      case logs.save_food_log_from_mealie_recipe(conn, input) {
        Ok(entry_id) -> {
          let response = CreateFoodLogResponse(
            id: entry_id,
            recipe_name: request.recipe_name,
            servings: request.servings,
          )
          wisp.response(201)
          |> wisp.json_body(
            json.object([
              #("id", json.string(response.id)),
              #("recipe_name", json.string(response.recipe_name)),
              #("servings", json.float(response.servings)),
            ]),
          )
        }
        Error(err) -> {
          wisp.response(500)
          |> wisp.string_body("Failed to save food log: " <> string.inspect(err))
        }
      }
    }
  }
}

// ============================================================================
// Validation
// ============================================================================

/// Validate a CreateFoodLogRequest
fn validate_food_log_request(
  request: CreateFoodLogRequest,
) -> Result(Nil, String) {
  // Validate date format (basic ISO 8601 check)
  case string.length(request.date) {
    10 if string.contains(request.date, "-") -> Ok(Nil)
    _ -> Error("Invalid date format. Expected YYYY-MM-DD")
  }
  |> result.try(fn(_) {
    // Validate recipe slug is not empty
    case string.length(string.trim(request.recipe_slug)) {
      0 -> Error("recipe_slug cannot be empty")
      _ -> Ok(Nil)
    }
  })
  |> result.try(fn(_) {
    // Validate recipe name is not empty
    case string.length(string.trim(request.recipe_name)) {
      0 -> Error("recipe_name cannot be empty")
      _ -> Ok(Nil)
    }
  })
  |> result.try(fn(_) {
    // Validate servings is positive
    case request.servings >. 0.0 {
      False -> Error("servings must be greater than 0")
      True -> Ok(Nil)
    }
  })
  |> result.try(fn(_) {
    // Validate macro values are non-negative
    case
      request.protein >=. 0.0,
      request.fat >=. 0.0,
      request.carbs >=. 0.0
    {
      False, _, _ -> Error("protein cannot be negative")
      _, False, _ -> Error("fat cannot be negative")
      _, _, False -> Error("carbs cannot be negative")
      True, True, True -> Ok(Nil)
    }
  })
  |> result.try(fn(_) {
    // Validate meal type
    case request.meal_type {
      "breakfast" | "lunch" | "dinner" | "snack" -> Ok(Nil)
      _ -> Error("meal_type must be one of: breakfast, lunch, dinner, snack")
    }
  })
}
