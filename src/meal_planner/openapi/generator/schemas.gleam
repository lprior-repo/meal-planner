/// OpenAPI schema definitions
///
/// Contains component schema definitions for the API.
/// Schemas define the structure of request/response bodies.
import gleam/dict
import meal_planner/openapi/generator/types.{
  type Components, type Schema, Components, FloatSchema, ObjectSchema, RefSchema,
  StringSchema,
}

/// Generate all component schemas
pub fn generate_components() -> Components {
  Components(
    schemas: dict.new()
    |> dict.insert("NutritionStatus", nutrition_status_schema())
    |> dict.insert("RecipeRecommendation", recipe_recommendation_schema())
    |> dict.insert("ScoringRequest", scoring_request_schema())
    |> dict.insert("RecipeScore", recipe_score_schema())
    |> dict.insert("MacroTargets", macro_targets_schema()),
  )
}

/// Nutrition status schema
pub fn nutrition_status_schema() -> Schema {
  ObjectSchema(
    properties: dict.new()
    |> dict.insert("date", StringSchema)
    |> dict.insert("protein_consumed", FloatSchema)
    |> dict.insert("fat_consumed", FloatSchema)
    |> dict.insert("carbs_consumed", FloatSchema)
    |> dict.insert("protein_remaining", FloatSchema)
    |> dict.insert("fat_remaining", FloatSchema)
    |> dict.insert("carbs_remaining", FloatSchema),
  )
}

/// Recipe recommendation schema
pub fn recipe_recommendation_schema() -> Schema {
  ObjectSchema(
    properties: dict.new()
    |> dict.insert("recipe_id", StringSchema)
    |> dict.insert("name", StringSchema)
    |> dict.insert("score", FloatSchema)
    |> dict.insert("servings", FloatSchema),
  )
}

/// Scoring request schema
pub fn scoring_request_schema() -> Schema {
  ObjectSchema(
    properties: dict.new()
    |> dict.insert(
      "recipes",
      types.ArraySchema(items: ObjectSchema(
        properties: dict.new()
        |> dict.insert("recipe_id", StringSchema)
        |> dict.insert("servings", FloatSchema),
      )),
    )
    |> dict.insert(
      "targets",
      RefSchema(ref: "#/components/schemas/MacroTargets"),
    )
    |> dict.insert(
      "weights",
      ObjectSchema(
        properties: dict.new()
        |> dict.insert("protein_weight", FloatSchema)
        |> dict.insert("fat_weight", FloatSchema)
        |> dict.insert("carbs_weight", FloatSchema),
      ),
    ),
  )
}

/// Recipe score schema
pub fn recipe_score_schema() -> Schema {
  ObjectSchema(
    properties: dict.new()
    |> dict.insert("recipe_id", StringSchema)
    |> dict.insert("score", FloatSchema),
  )
}

/// Macro targets schema
pub fn macro_targets_schema() -> Schema {
  ObjectSchema(
    properties: dict.new()
    |> dict.insert("protein", FloatSchema)
    |> dict.insert("fat", FloatSchema)
    |> dict.insert("carbs", FloatSchema),
  )
}
