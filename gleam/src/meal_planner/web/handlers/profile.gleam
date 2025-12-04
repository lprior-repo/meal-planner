//// Profile handlers for API endpoints

import gleam/json
import meal_planner/nutrition_constants
import meal_planner/storage
import meal_planner/types.{type UserProfile, Macros}
import pog
import wisp

type Profile =
  types.UserProfile

/// Web context holding database connection
pub type Context {
  Context(db: pog.Connection)
}

/// GET /api/profile - Get user profile with macros and settings
pub fn api_profile(_req: wisp.Request, ctx: Context) -> wisp.Response {
  let profile = load_profile(ctx)
  let json_data = profile_to_json(profile)
  wisp.json_response(json.to_string(json_data), 200)
}

// ============================================================================
// Helper Functions
// ============================================================================

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
