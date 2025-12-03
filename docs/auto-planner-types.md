# Auto Meal Planner - Complete Type Definitions

This document contains all Gleam type definitions for the auto meal planner system.

**Version:** 1.0
**Created:** 2025-12-03
**Purpose:** Reference for implementation

---

## Module: `auto_planner.gleam`

### Core Types

```gleam
import gleam/option.{type Option}
import shared/types.{type Macros, type Recipe}
import meal_planner/ncp

/// Configuration for generating an auto meal plan
pub type AutoPlanConfig {
  AutoPlanConfig(
    user_id: String,
    diet_principles: List(DietPrinciple),
    macro_targets: Option(Macros),
    recipe_limit: Int,              // Default: 4
    variety_factor: Float,          // 0.0-1.0, weight for variety scoring
    min_score_threshold: Float,     // Minimum acceptable score (e.g., 0.5)
  )
}

/// Diet principles for filtering and validation
pub type DietPrinciple {
  VerticalDiet
  TimFerriss
  LowFodmap
  Custom(name: String)
}

/// Generated meal plan with scored recipes
pub type AutoMealPlan {
  AutoMealPlan(
    id: String,
    user_id: String,
    recipes: List(ScoredRecipe),
    total_macros: Macros,
    generated_at: String,            // ISO 8601 timestamp
    diet_principles: List(DietPrinciple),
    macro_targets: Option(Macros),
    status: PlanStatus,
  )
}

/// Status of a meal plan
pub type PlanStatus {
  Active
  Archived
}

/// Recipe with scoring metadata
pub type ScoredRecipe {
  ScoredRecipe(
    recipe: Recipe,
    score: Float,                   // 0.0-1.0
    match_reason: String,           // Human-readable explanation
    macro_contribution: Macros,     // Per serving contribution
  )
}

/// Context for tracking variety in selection
pub type VarietyContext {
  VarietyContext(
    selected_proteins: List(String),
    selected_categories: List(String),
  )
}

/// Errors that can occur during plan generation
pub type PlanError {
  InsufficientRecipes(available: Int, required: Int)
  NoCompliantRecipes(diet: DietPrinciple)
  MacroTargetUnreachable(reason: String)
  StorageError(storage.StorageError)
  ValidationError(String)
}

/// Scoring components (internal use)
pub type ScoreBreakdown {
  ScoreBreakdown(
    macro_match: Float,             // 0.0-1.0
    diet_compliance: Float,         // 0.0-1.0
    protein_quality: Float,         // 0.0-1.0
    variety: Float,                 // 0.0-1.0
    final_score: Float,             // Weighted sum
  )
}
```

### Main Functions

```gleam
/// Generate a new auto meal plan
pub fn generate_plan(
  conn: pog.Connection,
  config: AutoPlanConfig,
  nutrition_goals: ncp.NutritionGoals,
) -> Result(AutoMealPlan, PlanError)

/// Score a recipe against all criteria
pub fn score_recipe(
  recipe: Recipe,
  goals: ncp.NutritionGoals,
  diet_principles: List(DietPrinciple),
  variety_context: VarietyContext,
) -> ScoreBreakdown

/// Select top N recipes with variety filtering
pub fn select_recipes(
  scored: List(#(Recipe, ScoreBreakdown)),
  count: Int,
  variety_factor: Float,
) -> List(ScoredRecipe)

/// Calculate macro match score component
pub fn calculate_macro_match(
  recipe: Recipe,
  goals: ncp.NutritionGoals,
) -> Float

/// Calculate diet compliance score component
pub fn calculate_diet_compliance(
  recipe: Recipe,
  diets: List(DietPrinciple),
) -> Float

/// Calculate protein quality score component
pub fn calculate_protein_quality(
  recipe: Recipe,
) -> Float

/// Calculate variety penalty
pub fn calculate_variety_penalty(
  recipe: Recipe,
  variety_context: VarietyContext,
) -> Float

/// Generate human-readable match reason
pub fn generate_match_reason(
  recipe: Recipe,
  breakdown: ScoreBreakdown,
) -> String

/// Validate that selected recipes meet macro targets
pub fn validate_macro_targets(
  recipes: List(Recipe),
  targets: Option(Macros),
) -> Result(Nil, String)
```

### Helper Functions

```gleam
/// Get default config for a user
pub fn default_config(user_id: String) -> AutoPlanConfig

/// Parse diet principle from string
pub fn parse_diet_principle(s: String) -> Result(DietPrinciple, String)

/// Convert diet principle to string
pub fn diet_principle_to_string(d: DietPrinciple) -> String

/// Parse plan status from string
pub fn parse_status(s: String) -> Result(PlanStatus, String)

/// Convert status to string
pub fn status_to_string(s: PlanStatus) -> String
```

---

## Module: `diet_validator.gleam`

### Types

```gleam
import shared/types.{type Recipe}
import meal_planner/auto_planner.{type DietPrinciple}

/// Result of validating a recipe against a diet
pub type ValidationResult {
  ValidationResult(
    compliant: Bool,
    diet: DietPrinciple,
    violations: List(String),       // Reasons for non-compliance
    confidence: Float,              // 0.0-1.0
  )
}

/// Cached validation result
pub type CachedValidation {
  CachedValidation(
    recipe_id: String,
    validations: List(ValidationResult),
    last_checked: String,           // ISO 8601 timestamp
  )
}

/// Validation errors
pub type ValidationError {
  RecipeNotFound(String)
  InvalidDietPrinciple(String)
  CacheError(storage.StorageError)
}

/// Approved ingredients for specific diets
pub type ApprovedIngredients {
  ApprovedIngredients(
    proteins: List(String),
    carbs: List(String),
    fats: List(String),
    vegetables: List(String),
  )
}
```

### Functions

```gleam
/// Validate recipe against a diet principle
pub fn validate_recipe(
  recipe: Recipe,
  diet: DietPrinciple,
) -> ValidationResult

/// Validate against Vertical Diet rules
pub fn is_vertical_diet_compliant(
  recipe: Recipe,
) -> ValidationResult

/// Validate against Tim Ferriss 4HB rules
pub fn is_tim_ferriss_compliant(
  recipe: Recipe,
) -> ValidationResult

/// Validate against Low FODMAP rules
pub fn is_low_fodmap_compliant(
  recipe: Recipe,
) -> ValidationResult

/// Batch validate multiple recipes
pub fn validate_batch(
  recipes: List(Recipe),
  diets: List(DietPrinciple),
) -> List(#(Recipe, List(ValidationResult)))

/// Get cached validation or revalidate
pub fn get_or_validate(
  conn: pog.Connection,
  recipe_id: String,
  diet: DietPrinciple,
  max_age_days: Int,
) -> Result(ValidationResult, ValidationError)

/// Check if validation is still valid
pub fn is_cache_valid(
  last_checked: String,
  max_age_days: Int,
) -> Bool

/// Get approved ingredients for a diet
pub fn get_approved_ingredients(
  diet: DietPrinciple,
) -> ApprovedIngredients
```

---

## Module: `recipe_fetcher.gleam`

### Types

```gleam
import gleam/option.{type Option}
import gleam/dict.{type Dict}
import shared/types.{type Macros, type Recipe}

/// Configuration for a recipe source
pub type RecipeSource {
  RecipeSource(
    id: Int,
    name: String,
    source_type: SourceType,
    config: SourceConfig,
    enabled: Bool,
    created_at: String,
    updated_at: String,
  )
}

/// Type of recipe source
pub type SourceType {
  Api
  Scraper
  Manual
}

/// Configuration specific to source type
pub type SourceConfig {
  ApiConfig(
    endpoint: String,
    api_key: Option(String),
    rate_limit: Int,                // Requests per minute
    timeout_ms: Int,
  )
  ScraperConfig(
    base_url: String,
    selectors: SelectorMap,
    user_agent: String,
  )
  ManualConfig
}

/// CSS selectors for scraping
pub type SelectorMap {
  SelectorMap(
    name: String,
    ingredients: String,
    instructions: String,
    macros: Option(String),
    servings: Option(String),
  )
}

/// Recipe fetched from external source (before normalization)
pub type FetchedRecipe {
  FetchedRecipe(
    source_id: Int,
    external_id: String,
    name: String,
    ingredients: List(String),      // Raw ingredient strings
    instructions: List(String),
    macros: Option(Macros),         // May need calculation
    servings: Option(Int),
    url: String,
    raw_data: Option(String),       // JSON or HTML for debugging
  )
}

/// Errors during fetching
pub type FetchError {
  NetworkError(String)
  RateLimitExceeded(remaining_seconds: Int)
  ParseError(String)
  AuthenticationError
  SourceDisabled(Int)
  TimeoutError
}
```

### Functions

```gleam
/// Fetch recipes from all enabled sources
pub fn fetch_from_all_sources(
  conn: pog.Connection,
) -> Result(List(FetchedRecipe), FetchError)

/// Fetch from a single source
pub fn fetch_from_source(
  source: RecipeSource,
) -> Result(List(FetchedRecipe), FetchError)

/// Fetch from API source
fn fetch_from_api(
  config: ApiConfig,
) -> Result(List(FetchedRecipe), FetchError)

/// Scrape from web source
fn scrape_from_web(
  config: ScraperConfig,
) -> Result(List(FetchedRecipe), FetchError)

/// Parse and normalize a fetched recipe
pub fn normalize_recipe(
  fetched: FetchedRecipe,
) -> Result(Recipe, ParseError)

/// Extract macros from recipe text (NLP/regex)
pub fn extract_macros(
  recipe_text: String,
) -> Option(Macros)

/// Sync fetched recipes to database
pub fn sync_recipes_to_db(
  conn: pog.Connection,
  recipes: List(Recipe),
) -> Result(Int, StorageError)

/// Check rate limit for a source
pub fn check_rate_limit(
  source_id: Int,
) -> Result(Nil, Int)

/// Parse Spoonacular API response
fn parse_spoonacular_response(
  json: String,
) -> Result(List(FetchedRecipe), ParseError)

/// Parse Edamam API response
fn parse_edamam_response(
  json: String,
) -> Result(List(FetchedRecipe), ParseError)
```

---

## Module: `auto_planner_storage.gleam`

### Functions

```gleam
import pog
import meal_planner/storage.{type StorageError}
import meal_planner/auto_planner.{
  type AutoMealPlan, type DietPrinciple, type PlanStatus,
}
import meal_planner/diet_validator.{
  type CachedValidation, type ValidationResult,
}
import meal_planner/recipe_fetcher.{
  type RecipeSource, type SourceType, type SourceConfig,
}

// ============================================================================
// Meal Plan Storage
// ============================================================================

/// Save a generated meal plan to database
pub fn save_meal_plan(
  conn: pog.Connection,
  plan: AutoMealPlan,
) -> Result(Int, StorageError)

/// Retrieve a meal plan by ID
pub fn get_meal_plan(
  conn: pog.Connection,
  plan_id: String,
) -> Result(AutoMealPlan, StorageError)

/// List meal plans for a user
pub fn list_user_plans(
  conn: pog.Connection,
  user_id: String,
  limit: Int,
  offset: Int,
) -> Result(List(AutoMealPlan), StorageError)

/// List meal plans with filters
pub fn list_plans_filtered(
  conn: pog.Connection,
  user_id: Option(String),
  status: Option(PlanStatus),
  diet: Option(DietPrinciple),
  limit: Int,
) -> Result(List(AutoMealPlan), StorageError)

/// Update plan status
pub fn update_plan_status(
  conn: pog.Connection,
  plan_id: String,
  status: PlanStatus,
) -> Result(Nil, StorageError)

/// Archive a meal plan
pub fn archive_plan(
  conn: pog.Connection,
  plan_id: String,
) -> Result(Nil, StorageError)

/// Delete a meal plan (soft delete)
pub fn delete_plan(
  conn: pog.Connection,
  plan_id: String,
) -> Result(Nil, StorageError)

// ============================================================================
// Recipe Source Storage
// ============================================================================

/// Save recipe source configuration
pub fn save_recipe_source(
  conn: pog.Connection,
  source: RecipeSource,
) -> Result(Int, StorageError)

/// Get recipe source by ID
pub fn get_recipe_source(
  conn: pog.Connection,
  source_id: Int,
) -> Result(RecipeSource, StorageError)

/// List all recipe sources
pub fn list_recipe_sources(
  conn: pog.Connection,
  enabled_only: Bool,
) -> Result(List(RecipeSource), StorageError)

/// Update recipe source
pub fn update_recipe_source(
  conn: pog.Connection,
  source_id: Int,
  source: RecipeSource,
) -> Result(Nil, StorageError)

/// Enable/disable a recipe source
pub fn toggle_recipe_source(
  conn: pog.Connection,
  source_id: Int,
  enabled: Bool,
) -> Result(Nil, StorageError)

/// Delete recipe source
pub fn delete_recipe_source(
  conn: pog.Connection,
  source_id: Int,
) -> Result(Nil, StorageError)

// ============================================================================
// Diet Compliance Storage
// ============================================================================

/// Save validation result for a recipe
pub fn save_compliance(
  conn: pog.Connection,
  recipe_id: String,
  validations: List(ValidationResult),
) -> Result(Nil, StorageError)

/// Get cached compliance for a recipe
pub fn get_compliance(
  conn: pog.Connection,
  recipe_id: String,
) -> Result(CachedValidation, StorageError)

/// Batch get compliance for multiple recipes
pub fn batch_get_compliance(
  conn: pog.Connection,
  recipe_ids: List(String),
) -> Result(List(CachedValidation), StorageError)

/// Clear expired compliance cache
pub fn clear_expired_compliance(
  conn: pog.Connection,
  max_age_days: Int,
) -> Result(Int, StorageError)

// ============================================================================
// Recipe Queries for Planning
// ============================================================================

/// Get recipes eligible for auto planning
pub fn get_recipes_for_planning(
  conn: pog.Connection,
  diet_filter: Option(DietPrinciple),
  limit: Int,
) -> Result(List(Recipe), StorageError)

/// Get recipes by IDs
pub fn get_recipes_by_ids(
  conn: pog.Connection,
  recipe_ids: List(String),
) -> Result(List(Recipe), StorageError)

// ============================================================================
// JSON Serialization Helpers
// ============================================================================

/// Serialize diet principles to JSON
pub fn serialize_diet_principles(
  diets: List(DietPrinciple),
) -> String

/// Deserialize diet principles from JSON
pub fn deserialize_diet_principles(
  json: String,
) -> Result(List(DietPrinciple), String)

/// Serialize recipe IDs to JSON
pub fn serialize_recipe_ids(
  recipe_ids: List(String),
) -> String

/// Deserialize recipe IDs from JSON
pub fn deserialize_recipe_ids(
  json: String,
) -> Result(List(String), String)

/// Serialize source config to JSON
pub fn serialize_source_config(
  config: SourceConfig,
) -> String

/// Deserialize source config from JSON
pub fn deserialize_source_config(
  json: String,
) -> Result(SourceConfig, String)
```

---

## Module: `auto_planner_web.gleam` (API Handlers)

### Request/Response Types

```gleam
import gleam/json.{type Json}
import gleam/option.{type Option}
import shared/types.{type Macros}
import meal_planner/auto_planner.{type DietPrinciple}

/// Request body for generating a meal plan
pub type GeneratePlanRequest {
  GeneratePlanRequest(
    user_id: String,
    diet_principles: List(String),  // Strings to parse
    macro_targets: Option(Macros),
    recipe_count: Option(Int),      // Default: 4
    min_score: Option(Float),       // Default: 0.5
  )
}

/// Response for generated meal plan
pub type GeneratePlanResponse {
  GeneratePlanResponse(
    id: String,
    user_id: String,
    recipes: List(ScoredRecipeJson),
    total_macros: Macros,
    generated_at: String,
    diet_principles: List(String),
    status: String,
  )
}

/// JSON representation of scored recipe
pub type ScoredRecipeJson {
  ScoredRecipeJson(
    recipe: Json,                   // Full recipe object
    score: Float,
    match_reason: String,
    macro_contribution: Macros,
  )
}

/// Request body for creating recipe source
pub type CreateSourceRequest {
  CreateSourceRequest(
    name: String,
    source_type: String,
    config: Json,                   // Source-specific config
    enabled: Option(Bool),
  )
}

/// Response for recipe source
pub type RecipeSourceResponse {
  RecipeSourceResponse(
    id: Int,
    name: String,
    source_type: String,
    enabled: Bool,
    created_at: String,
  )
}

/// Error response
pub type ErrorResponse {
  ErrorResponse(
    error: String,
    message: String,
    details: Option(Json),
  )
}
```

### Handler Functions

```gleam
import wisp.{type Request, type Response}
import meal_planner/web.{type Context}

/// POST /api/meal-plans/auto - Generate meal plan
pub fn generate_meal_plan_handler(
  req: Request,
  ctx: Context,
) -> Response

/// GET /api/meal-plans/auto/:id - Get meal plan
pub fn get_meal_plan_handler(
  plan_id: String,
  ctx: Context,
) -> Response

/// GET /api/meal-plans/auto - List user's meal plans
pub fn list_meal_plans_handler(
  req: Request,
  ctx: Context,
) -> Response

/// POST /api/recipe-sources - Create recipe source
pub fn create_recipe_source_handler(
  req: Request,
  ctx: Context,
) -> Response

/// GET /api/recipe-sources - List recipe sources
pub fn list_recipe_sources_handler(
  ctx: Context,
) -> Response

/// PUT /api/recipe-sources/:id - Update recipe source
pub fn update_recipe_source_handler(
  source_id: String,
  req: Request,
  ctx: Context,
) -> Response

/// DELETE /api/recipe-sources/:id - Delete recipe source
pub fn delete_recipe_source_handler(
  source_id: String,
  ctx: Context,
) -> Response
```

### JSON Encoding/Decoding

```gleam
/// Encode AutoMealPlan to JSON
pub fn encode_meal_plan(plan: AutoMealPlan) -> Json

/// Encode ScoredRecipe to JSON
pub fn encode_scored_recipe(scored: ScoredRecipe) -> Json

/// Encode RecipeSource to JSON
pub fn encode_recipe_source(source: RecipeSource) -> Json

/// Decode GeneratePlanRequest from JSON
pub fn decode_generate_plan_request(json: Json) -> Result(GeneratePlanRequest, String)

/// Decode CreateSourceRequest from JSON
pub fn decode_create_source_request(json: Json) -> Result(CreateSourceRequest, String)
```

---

## Type Aliases and Constants

### Constants

```gleam
/// Default number of recipes to select
pub const default_recipe_count = 4

/// Default minimum score threshold
pub const default_min_score = 0.5

/// Default variety factor
pub const default_variety_factor = 0.1

/// Scoring weights
pub const macro_match_weight = 0.40
pub const diet_compliance_weight = 0.30
pub const protein_quality_weight = 0.20
pub const variety_weight = 0.10

/// Validation cache duration
pub const validation_cache_days = 7

/// Rate limit defaults
pub const default_rate_limit = 150  // requests per minute
pub const default_timeout_ms = 5000
```

### Type Aliases

```gleam
/// Recipe with score tuple (internal use)
pub type ScoredTuple = #(Recipe, Float)

/// Diet compliance map
pub type ComplianceMap = dict.Dict(DietPrinciple, Bool)

/// Protein source quality map
pub type ProteinQualityMap = dict.Dict(String, Float)
```

---

## Example Usage

### Generating a Meal Plan

```gleam
import meal_planner/auto_planner
import meal_planner/ncp
import meal_planner/storage
import pog

pub fn example_generate_plan() {
  // Setup
  let assert Ok(db) = storage.start_pool(storage.default_config())
  let assert Ok(goals) = ncp.get_goals(db, "user123")

  // Configure plan generation
  let config = auto_planner.AutoPlanConfig(
    user_id: "user123",
    diet_principles: [auto_planner.VerticalDiet, auto_planner.TimFerriss],
    macro_targets: Some(types.Macros(
      protein: 180.0,
      fat: 60.0,
      carbs: 250.0,
    )),
    recipe_limit: 4,
    variety_factor: 0.1,
    min_score_threshold: 0.5,
  )

  // Generate plan
  case auto_planner.generate_plan(db, config, goals) {
    Ok(plan) -> {
      io.println("Generated plan: " <> plan.id)
      io.println("Selected " <> int.to_string(list.length(plan.recipes)) <> " recipes")
      Ok(plan)
    }
    Error(e) -> {
      io.println("Error: " <> debug.format(e))
      Error(e)
    }
  }
}
```

### Validating a Recipe

```gleam
import meal_planner/diet_validator
import shared/types

pub fn example_validate_recipe() {
  let recipe = types.Recipe(
    id: "recipe_1",
    name: "Grilled Salmon with Rice",
    // ... other fields
  )

  let validation = diet_validator.validate_recipe(
    recipe,
    auto_planner.VerticalDiet,
  )

  case validation.compliant {
    True -> io.println("Recipe is Vertical Diet compliant")
    False -> {
      io.println("Violations:")
      list.each(validation.violations, io.println)
    }
  }
}
```

---

**Document Status:** ✅ Complete
**Purpose:** Implementation reference for all types and functions
**Next Steps:** Use these definitions during TDD implementation
