//// Auto meal planner types and configuration
//// Supports diet principles like Vertical Diet and Tim Ferriss 4-Hour Body

import gleam/json
import gleam/option.{type Option, None, Some}
import meal_planner/types.{type Macros, type Recipe}

// ============================================================================
// Diet Principles
// ============================================================================

/// Supported diet principles for meal planning
pub type DietPrinciple {
  VerticalDiet
  TimFerriss
  Paleo
  Keto
  Mediterranean
  HighProtein
}

/// Convert diet principle to string
pub fn diet_principle_to_string(dp: DietPrinciple) -> String {
  case dp {
    VerticalDiet -> "vertical_diet"
    TimFerriss -> "tim_ferriss"
    Paleo -> "paleo"
    Keto -> "keto"
    Mediterranean -> "mediterranean"
    HighProtein -> "high_protein"
  }
}

/// Parse diet principle from string
pub fn diet_principle_from_string(s: String) -> Option(DietPrinciple) {
  case s {
    "vertical_diet" -> Some(VerticalDiet)
    "tim_ferriss" -> Some(TimFerriss)
    "paleo" -> Some(Paleo)
    "keto" -> Some(Keto)
    "mediterranean" -> Some(Mediterranean)
    "high_protein" -> Some(HighProtein)
    _ -> None
  }
}

// ============================================================================
// Auto Planner Configuration
// ============================================================================

/// Configuration for auto meal plan generation
pub type AutoPlanConfig {
  AutoPlanConfig(
    user_id: String,
    diet_principles: List(DietPrinciple),
    macro_targets: Macros,
    recipe_count: Int,
    variety_factor: Float,
  )
}

/// Validate auto plan configuration
pub fn validate_config(config: AutoPlanConfig) -> Result(Nil, String) {
  // Check recipe count
  case config.recipe_count {
    n if n < 1 -> Error("recipe_count must be at least 1")
    n if n > 20 -> Error("recipe_count must be at most 20")
    _ -> Ok(Nil)
  }
  |> fn(r) {
    case r {
      Error(e) -> Error(e)
      Ok(_) ->
        // Check variety factor
        case config.variety_factor {
          f if f <. 0.0 -> Error("variety_factor must be between 0 and 1")
          f if f >. 1.0 -> Error("variety_factor must be between 0 and 1")
          _ -> Ok(Nil)
        }
    }
  }
  |> fn(r) {
    case r {
      Error(e) -> Error(e)
      Ok(_) ->
        // Check macro targets are positive
        case config.macro_targets {
          types.Macros(p, f, c) if p <. 0.0 || f <. 0.0 || c <. 0.0 ->
            Error("macro_targets must be positive")
          _ -> Ok(Nil)
        }
    }
  }
}

// ============================================================================
// Auto Plan Result
// ============================================================================

/// Generated auto meal plan
pub type AutoMealPlan {
  AutoMealPlan(
    id: String,
    recipes: List(Recipe),
    generated_at: String,
    total_macros: Macros,
    config: AutoPlanConfig,
  )
}

// ============================================================================
// JSON Encoding
// ============================================================================

pub fn diet_principle_to_json(dp: DietPrinciple) -> json.Json {
  json.string(diet_principle_to_string(dp))
}

pub fn auto_plan_config_to_json(config: AutoPlanConfig) -> json.Json {
  json.object([
    #("user_id", json.string(config.user_id)),
    #(
      "diet_principles",
      json.array(config.diet_principles, diet_principle_to_json),
    ),
    #("macro_targets", types.macros_to_json(config.macro_targets)),
    #("recipe_count", json.int(config.recipe_count)),
    #("variety_factor", json.float(config.variety_factor)),
  ])
}

pub fn auto_meal_plan_to_json(plan: AutoMealPlan) -> json.Json {
  json.object([
    #("id", json.string(plan.id)),
    #("recipes", json.array(plan.recipes, types.recipe_to_json)),
    #("generated_at", json.string(plan.generated_at)),
    #("total_macros", types.macros_to_json(plan.total_macros)),
    #("config", auto_plan_config_to_json(plan.config)),
  ])
}

// ============================================================================
// JSON Decoding
// ============================================================================

import gleam/dynamic/decode.{type Decoder}

pub fn diet_principle_decoder() -> Decoder(DietPrinciple) {
  use s <- decode.then(decode.string)
  case diet_principle_from_string(s) {
    Some(dp) -> decode.success(dp)
    None -> decode.failure(VerticalDiet, "DietPrinciple")
  }
}

pub fn auto_plan_config_decoder() -> Decoder(AutoPlanConfig) {
  use user_id <- decode.field("user_id", decode.string)
  use diet_principles <- decode.field(
    "diet_principles",
    decode.list(diet_principle_decoder()),
  )
  use macro_targets <- decode.field("macro_targets", types.macros_decoder())
  use recipe_count <- decode.field("recipe_count", decode.int)
  use variety_factor <- decode.field("variety_factor", decode.float)

  decode.success(AutoPlanConfig(
    user_id: user_id,
    diet_principles: diet_principles,
    macro_targets: macro_targets,
    recipe_count: recipe_count,
    variety_factor: variety_factor,
  ))
}
