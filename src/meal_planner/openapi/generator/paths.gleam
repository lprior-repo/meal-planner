/// OpenAPI path definitions
///
/// Contains all endpoint path definitions for the API.
/// Each function generates a complete PathItem with operations.
import gleam/dict.{type Dict}
import gleam/option.{None, Some}
import meal_planner/openapi/generator/types.{
  type Operation, type PathItem, type Response, ArraySchema, MediaType,
  ObjectSchema, Operation, PathItem, RefSchema, Response, StringSchema,
}

/// Generate all API paths
pub fn generate_paths() -> Dict(String, PathItem) {
  dict.new()
  |> dict.insert("/", health_root_path())
  |> dict.insert("/health", health_check_path())
  |> dict.insert("/api/nutrition/daily-status", nutrition_daily_status_path())
  |> dict.insert(
    "/api/nutrition/recommend-dinner",
    nutrition_recommend_dinner_path(),
  )
  |> dict.insert("/api/ai/score-recipe", ai_score_recipe_path())
}

/// Health check root endpoint
pub fn health_root_path() -> PathItem {
  PathItem(
    get: Some(Operation(
      operation_id: "getHealth",
      tags: ["Health"],
      summary: "Health check",
      description: "Returns 200 if server is running",
      parameters: [],
      request_body: None,
      responses: dict.new()
        |> dict.insert(
          "200",
          Response(
            description: "Server is healthy",
            content: Some(
              dict.new()
              |> dict.insert(
                "application/json",
                MediaType(schema: ObjectSchema(
                  properties: dict.new()
                  |> dict.insert("status", StringSchema)
                  |> dict.insert("service", StringSchema)
                  |> dict.insert("version", StringSchema),
                )),
              ),
            ),
          ),
        ),
    )),
    post: None,
    put: None,
    patch: None,
    delete: None,
  )
}

/// Health check endpoint
pub fn health_check_path() -> PathItem {
  PathItem(
    get: Some(Operation(
      operation_id: "getHealthCheck",
      tags: ["Health"],
      summary: "Health check endpoint",
      description: "Returns 200 if server is running",
      parameters: [],
      request_body: None,
      responses: dict.new()
        |> dict.insert(
          "200",
          Response(
            description: "Server is healthy",
            content: Some(
              dict.new()
              |> dict.insert(
                "application/json",
                MediaType(schema: ObjectSchema(
                  properties: dict.new()
                  |> dict.insert("status", StringSchema)
                  |> dict.insert("service", StringSchema)
                  |> dict.insert("version", StringSchema),
                )),
              ),
            ),
          ),
        ),
    )),
    post: None,
    put: None,
    patch: None,
    delete: None,
  )
}

/// Nutrition daily status endpoint
pub fn nutrition_daily_status_path() -> PathItem {
  PathItem(
    get: Some(Operation(
      operation_id: "getNutritionDailyStatus",
      tags: ["Nutrition Control"],
      summary: "Get daily nutrition status",
      description: "Returns current nutrition status for the day including macros consumed and remaining",
      parameters: [],
      request_body: None,
      responses: dict.new()
        |> dict.insert(
          "200",
          Response(
            description: "Daily nutrition status",
            content: Some(
              dict.new()
              |> dict.insert(
                "application/json",
                MediaType(schema: RefSchema(
                  ref: "#/components/schemas/NutritionStatus",
                )),
              ),
            ),
          ),
        ),
    )),
    post: None,
    put: None,
    patch: None,
    delete: None,
  )
}

/// Nutrition recommend dinner endpoint
pub fn nutrition_recommend_dinner_path() -> PathItem {
  PathItem(
    get: Some(Operation(
      operation_id: "getNutritionRecommendDinner",
      tags: ["Nutrition Control"],
      summary: "Get dinner recommendations",
      description: "Returns recommended dinner options based on remaining daily macros",
      parameters: [],
      request_body: None,
      responses: dict.new()
        |> dict.insert(
          "200",
          Response(
            description: "Dinner recommendations",
            content: Some(
              dict.new()
              |> dict.insert(
                "application/json",
                MediaType(
                  schema: ArraySchema(items: RefSchema(
                    ref: "#/components/schemas/RecipeRecommendation",
                  )),
                ),
              ),
            ),
          ),
        ),
    )),
    post: None,
    put: None,
    patch: None,
    delete: None,
  )
}

/// AI score recipe endpoint
pub fn ai_score_recipe_path() -> PathItem {
  PathItem(
    get: None,
    post: Some(Operation(
      operation_id: "postAiScoreRecipe",
      tags: ["Meal Planning"],
      summary: "Score recipes against targets",
      description: "Scores a list of recipes against macro targets using weighted scoring algorithm",
      parameters: [],
      request_body: Some(types.RequestBody(
        description: "Recipe scoring request",
        content: dict.new()
          |> dict.insert(
            "application/json",
            MediaType(schema: RefSchema(
              ref: "#/components/schemas/ScoringRequest",
            )),
          ),
      )),
      responses: dict.new()
        |> dict.insert(
          "200",
          Response(
            description: "Recipe scores",
            content: Some(
              dict.new()
              |> dict.insert(
                "application/json",
                MediaType(
                  schema: ArraySchema(items: RefSchema(
                    ref: "#/components/schemas/RecipeScore",
                  )),
                ),
              ),
            ),
          ),
        )
        |> dict.insert(
          "400",
          Response(description: "Invalid request", content: None),
        )
        |> dict.insert(
          "501",
          Response(description: "Not implemented", content: None),
        ),
    )),
    put: None,
    patch: None,
    delete: None,
  )
}
