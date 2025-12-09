//// Profile handlers for API endpoints

import gleam/float
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None}
import meal_planner/storage
import meal_planner/storage/profile as storage_profile
import meal_planner/types
import pog
import wisp

type Profile =
  types.UserProfile

/// Web context holding database connection
pub type Context {
  Context(db: pog.Connection)
}

/// API endpoint for profile operations
pub fn api_profile(req: wisp.Request, ctx: Context) -> wisp.Response {
  case req.method {
    http.Get -> get_profile(ctx)
    http.Post -> update_profile(req, ctx)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

/// GET /api/profile - Get user profile with macros and settings
fn get_profile(ctx: Context) -> wisp.Response {
  let profile = load_profile(ctx)
  let json_data = profile_to_json(profile)
  wisp.json_response(json.to_string(json_data), 200)
}

/// POST /api/profile - Update user profile with validation
fn update_profile(req: wisp.Request, ctx: Context) -> wisp.Response {
  use form <- wisp.require_form(req)

  // Parse and validate form data
  case parse_profile_form(form.values) {
    Error(errors) -> {
      // Return validation errors as JSON
      let error_json =
        json.object([
          #("success", json.bool(False)),
          #("errors", json.array(errors, json.string)),
        ])
      wisp.json_response(json.to_string(error_json), 400)
    }
    Ok(profile) -> {
      // Save to database
      case storage_profile.save_user_profile(ctx.db, profile) {
        Ok(_) -> {
          let success_json =
            json.object([
              #("success", json.bool(True)),
              #("message", json.string("Profile updated successfully")),
              #("profile", profile_to_json(profile)),
            ])
          wisp.json_response(json.to_string(success_json), 200)
        }
        Error(storage_profile.DatabaseError(msg)) -> {
          let error_json =
            json.object([
              #("success", json.bool(False)),
              #("errors", json.array([msg], json.string)),
            ])
          wisp.json_response(json.to_string(error_json), 500)
        }
        Error(_) -> {
          let error_json =
            json.object([
              #("success", json.bool(False)),
              #("errors", json.array(["Failed to save profile"], json.string)),
            ])
          wisp.json_response(json.to_string(error_json), 500)
        }
      }
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Parse and validate profile form data
fn parse_profile_form(
  form_values: List(#(String, String)),
) -> Result(Profile, List(String)) {
  let errors = []

  // Parse bodyweight
  let bodyweight_result = {
    case list.find(form_values, fn(pair) { pair.0 == "bodyweight" }) {
      Ok(#(_, value)) ->
        case float.parse(value) {
          Ok(bw) if bw >. 0.0 -> Ok(bw)
          Ok(_) -> {
            let errors = ["Bodyweight must be greater than 0", ..errors]
            Error(errors)
          }
          Error(_) -> {
            let errors = ["Invalid bodyweight value", ..errors]
            Error(errors)
          }
        }
      Error(_) -> {
        let errors = ["Bodyweight is required", ..errors]
        Error(errors)
      }
    }
  }

  // Parse activity level
  let activity_level_result = {
    case list.find(form_values, fn(pair) { pair.0 == "activity_level" }) {
      Ok(#(_, "sedentary")) -> Ok(types.Sedentary)
      Ok(#(_, "moderate")) -> Ok(types.Moderate)
      Ok(#(_, "active")) -> Ok(types.Active)
      Ok(#(_, _)) -> {
        let errors = ["Invalid activity level", ..errors]
        Error(errors)
      }
      Error(_) -> {
        let errors = ["Activity level is required", ..errors]
        Error(errors)
      }
    }
  }

  // Parse goal
  let goal_result = {
    case list.find(form_values, fn(pair) { pair.0 == "goal" }) {
      Ok(#(_, "lose")) -> Ok(types.Lose)
      Ok(#(_, "maintain")) -> Ok(types.Maintain)
      Ok(#(_, "gain")) -> Ok(types.Gain)
      Ok(#(_, _)) -> {
        let errors = ["Invalid goal", ..errors]
        Error(errors)
      }
      Error(_) -> {
        let errors = ["Goal is required", ..errors]
        Error(errors)
      }
    }
  }

  // Parse meals per day
  let meals_per_day_result = {
    case list.find(form_values, fn(pair) { pair.0 == "meals_per_day" }) {
      Ok(#(_, value)) ->
        case int.parse(value) {
          Ok(mpd) if mpd >= 1 && mpd <= 10 -> Ok(mpd)
          Ok(_) -> {
            let errors = ["Meals per day must be between 1 and 10", ..errors]
            Error(errors)
          }
          Error(_) -> {
            let errors = ["Invalid meals per day value", ..errors]
            Error(errors)
          }
        }
      Error(_) -> {
        let errors = ["Meals per day is required", ..errors]
        Error(errors)
      }
    }
  }

  // Collect errors from each result
  let bodyweight_errors = case bodyweight_result {
    Error(errs) -> errs
    Ok(_) -> []
  }
  let activity_errors = case activity_level_result {
    Error(errs) -> errs
    Ok(_) -> []
  }
  let goal_errors = case goal_result {
    Error(errs) -> errs
    Ok(_) -> []
  }
  let meals_errors = case meals_per_day_result {
    Error(errs) -> errs
    Ok(_) -> []
  }

  let all_errors = list.flatten([bodyweight_errors, activity_errors, goal_errors, meals_errors])

  // Check for errors
  case all_errors {
    [] -> {
      // All validations passed, construct profile
      case
        bodyweight_result,
        activity_level_result,
        goal_result,
        meals_per_day_result
      {
        Ok(bw), Ok(al), Ok(g), Ok(mpd) ->
          Ok(types.UserProfile(
            id: "1",
            bodyweight: bw,
            activity_level: al,
            goal: g,
            meals_per_day: mpd,
            micronutrient_goals: None,
          ))
        _, _, _, _ -> Error(all_errors)
      }
    }
    _ -> Error(all_errors)
  }
}

/// Load user profile
fn load_profile(ctx: Context) -> Profile {
  storage.get_user_profile_or_default(ctx.db)
}

/// Convert profile to JSON
fn profile_to_json(p: Profile) -> json.Json {
  json.object([
    #("id", json.string(p.id)),
    #("bodyweight", json.float(p.bodyweight)),
    #(
      "activity_level",
      json.string(case p.activity_level {
        types.Sedentary -> "sedentary"
        types.Moderate -> "moderate"
        types.Active -> "active"
      }),
    ),
    #(
      "goal",
      json.string(case p.goal {
        types.Lose -> "lose"
        types.Maintain -> "maintain"
        types.Gain -> "gain"
      }),
    ),
    #("meals_per_day", json.int(p.meals_per_day)),
  ])
}
