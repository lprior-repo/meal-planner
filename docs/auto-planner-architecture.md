# Auto Meal Planner Architecture

## Overview

The Auto Meal Planner is a sophisticated system that automatically generates personalized meal plans by selecting 4 optimal recipes based on nutritional goals, diet compliance, and variety. It integrates with the existing NCP (Nutrition Control Plane) system and leverages external recipe sources.

**Version:** 1.0
**Last Updated:** 2025-12-03
**Status:** Design Complete

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Client Layer                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │  Web UI      │  │  Mobile App  │  │  CLI         │             │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘             │
└─────────┼──────────────────┼──────────────────┼──────────────────────┘
          │                  │                  │
          └──────────────────┴──────────────────┘
                             │
┌────────────────────────────┴─────────────────────────────────────────┐
│                         API Layer (Wisp)                              │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │  POST /api/meal-plans/auto     - Generate new plan             │ │
│  │  GET  /api/meal-plans/auto/:id - Retrieve plan                 │ │
│  │  POST /api/recipe-sources      - Add recipe source             │ │
│  │  GET  /api/recipe-sources      - List sources                  │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└────────────────────────────┬─────────────────────────────────────────┘
                             │
┌────────────────────────────┴─────────────────────────────────────────┐
│                    Auto Planner Core Logic                            │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │  auto_planner.   │  │  diet_validator. │  │  recipe_fetcher. │  │
│  │     gleam        │  │      gleam       │  │      gleam       │  │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘  │
│           │                     │                     │             │
│  ┌────────┴─────────────────────┴─────────────────────┴─────────┐  │
│  │              Recipe Scoring & Selection Algorithm             │  │
│  │  • Score recipes (0-1 scale)                                  │  │
│  │  • Filter by diet compliance                                  │  │
│  │  • Match macro targets using NCP                              │  │
│  │  • Ensure variety (protein source diversity)                  │  │
│  │  • Select top 4 highest scoring                               │  │
│  └────────────────────────────────────────────────────────────────┘  │
└────────────────────────────┬─────────────────────────────────────────┘
                             │
┌────────────────────────────┴─────────────────────────────────────────┐
│                      Storage Layer (SQLite/PostgreSQL)                │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │  auto_planner_   │  │  ncp.gleam       │  │  storage.gleam   │  │
│  │  storage.gleam   │  │  (NCP State)     │  │  (Core DB)       │  │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘  │
│                                                                       │
│  Tables:                                                              │
│  • recipe_sources          - External recipe APIs/scrapers           │
│  • auto_meal_plans         - Generated plans with metadata           │
│  • recipe_diet_compliance  - Diet validation cache                   │
│  • nutrition_state         - NCP nutrition tracking                  │
│  • recipes                 - Recipe library                          │
└───────────────────────────────────────────────────────────────────────┘
```

---

## Module Architecture

### 1. `auto_planner.gleam` - Core Planning Algorithm

**Responsibility:** Orchestrate the auto meal planning workflow

**Key Types:**
```gleam
/// Configuration for auto meal plan generation
pub type AutoPlanConfig {
  AutoPlanConfig(
    user_id: String,
    diet_principles: List(DietPrinciple),
    macro_targets: Option(Macros),
    recipe_limit: Int,              // Default: 4
    variety_factor: Float,          // 0.0-1.0, weight for protein diversity
    min_score_threshold: Float,     // Minimum acceptable recipe score
  )
}

/// Diet principle for filtering and scoring
pub type DietPrinciple {
  VerticalDiet
  TimFerriss
  LowFodmap
  Custom(name: String)
}

/// Generated meal plan result
pub type AutoMealPlan {
  AutoMealPlan(
    id: String,
    user_id: String,
    recipes: List(ScoredRecipe),
    total_macros: Macros,
    generated_at: String,
    diet_principles: List(DietPrinciple),
    macro_targets: Option(Macros),
    status: PlanStatus,
  )
}

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
```

**Key Functions:**
```gleam
/// Generate a new auto meal plan
pub fn generate_plan(
  config: AutoPlanConfig,
  available_recipes: List(Recipe),
  nutrition_goals: ncp.NutritionGoals,
) -> Result(AutoMealPlan, PlanError)

/// Score a single recipe against criteria
pub fn score_recipe(
  recipe: Recipe,
  goals: ncp.NutritionGoals,
  diet_principles: List(DietPrinciple),
  variety_context: VarietyContext,
) -> Float

/// Select top N recipes ensuring variety
pub fn select_recipes(
  scored: List(#(Recipe, Float)),
  count: Int,
  variety_factor: Float,
) -> List(ScoredRecipe)

/// Calculate variety score (penalize similar protein sources)
fn calculate_variety_penalty(
  recipe: Recipe,
  already_selected: List(Recipe),
) -> Float
```

**Algorithm Flow:**
1. Fetch available recipes from database
2. Filter by diet compliance (if specified)
3. Score each recipe (see scoring algorithm below)
4. Sort by score (descending)
5. Apply variety filtering (penalize duplicate protein sources)
6. Select top 4 recipes
7. Validate total macros meet targets
8. Store plan in database

---

### 2. `diet_validator.gleam` - Diet Compliance Validation

**Responsibility:** Validate recipes against specific diet principles

**Key Types:**
```gleam
/// Validation result for a recipe
pub type ValidationResult {
  ValidationResult(
    compliant: Bool,
    diet: DietPrinciple,
    violations: List(String),       // Reasons for non-compliance
    confidence: Float,              // 0.0-1.0 validation confidence
  )
}

/// Cached validation for performance
pub type CachedValidation {
  CachedValidation(
    recipe_id: String,
    validations: List(ValidationResult),
    last_checked: String,
  )
}
```

**Key Functions:**
```gleam
/// Validate recipe against a diet principle
pub fn validate_recipe(
  recipe: Recipe,
  diet: DietPrinciple,
) -> ValidationResult

/// Check Vertical Diet compliance
pub fn is_vertical_diet_compliant(recipe: Recipe) -> ValidationResult

/// Check Tim Ferriss 4HB compliance
pub fn is_tim_ferriss_compliant(recipe: Recipe) -> ValidationResult

/// Batch validate multiple recipes
pub fn validate_batch(
  recipes: List(Recipe),
  diets: List(DietPrinciple),
) -> List(#(Recipe, List(ValidationResult)))

/// Check cached validation or revalidate
pub fn get_or_validate(
  recipe_id: String,
  diet: DietPrinciple,
  max_age_days: Int,
) -> Result(ValidationResult, ValidationError)
```

**Validation Rules:**

**Vertical Diet:**
- Must be marked `vertical_compliant: True` in Recipe
- FODMAP level must be `Low`
- Protein source should be on approved list (beef, chicken, salmon, eggs)
- Carb sources: white rice, sweet potato, oats
- No dairy except Greek yogurt and certain cheeses

**Tim Ferriss 4HB:**
- High protein (>20g per serving)
- Low glycemic carbs (<30g per serving OR from beans/legumes)
- Moderate fat (<15g per serving)
- No white carbs (bread, pasta, rice) except post-workout
- Minimum 20g protein per meal

---

### 3. `recipe_fetcher.gleam` - External Recipe Integration

**Responsibility:** Fetch and parse recipes from external sources

**Key Types:**
```gleam
/// Recipe source configuration
pub type RecipeSource {
  RecipeSource(
    id: Int,
    name: String,
    source_type: SourceType,
    config: SourceConfig,
    enabled: Bool,
  )
}

pub type SourceType {
  Api
  Scraper
  Manual
}

/// Configuration for different source types
pub type SourceConfig {
  ApiConfig(endpoint: String, api_key: Option(String), rate_limit: Int)
  ScraperConfig(base_url: String, selectors: SelectorMap)
  ManualConfig
}

/// Fetched recipe (before validation)
pub type FetchedRecipe {
  FetchedRecipe(
    source_id: Int,
    external_id: String,
    name: String,
    ingredients: List(String),      // Raw ingredient strings
    instructions: List(String),
    macros: Option(Macros),         // May need calculation
    url: String,
  )
}
```

**Key Functions:**
```gleam
/// Fetch recipes from all enabled sources
pub fn fetch_from_all_sources(
  sources: List(RecipeSource),
) -> Result(List(FetchedRecipe), FetchError)

/// Fetch from a single source
pub fn fetch_from_source(
  source: RecipeSource,
) -> Result(List(FetchedRecipe), FetchError)

/// Parse and normalize a fetched recipe
pub fn normalize_recipe(
  fetched: FetchedRecipe,
) -> Result(Recipe, ParseError)

/// Extract macros from recipe text (if not provided)
pub fn extract_macros(
  recipe_text: String,
) -> Option(Macros)

/// Sync recipes to database
pub fn sync_recipes_to_db(
  conn: pog.Connection,
  recipes: List(Recipe),
) -> Result(Int, StorageError)
```

**Supported Sources (Phase 1):**
1. **Manual Entry** - User-created recipes
2. **Spoonacular API** - Comprehensive recipe database
3. **Edamam API** - Nutrition-focused recipe search
4. **Future:** Recipe scrapers for popular blogs

---

### 4. `auto_planner_storage.gleam` - Database Operations

**Responsibility:** Persist auto planner data

**Key Functions:**
```gleam
/// Save a generated meal plan
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
) -> Result(List(AutoMealPlan), StorageError)

/// Archive a meal plan
pub fn archive_plan(
  conn: pog.Connection,
  plan_id: String,
) -> Result(Nil, StorageError)

/// Save recipe source
pub fn save_recipe_source(
  conn: pog.Connection,
  source: RecipeSource,
) -> Result(Int, StorageError)

/// Get all enabled recipe sources
pub fn get_enabled_sources(
  conn: pog.Connection,
) -> Result(List(RecipeSource), StorageError)

/// Save diet compliance validation
pub fn save_compliance(
  conn: pog.Connection,
  recipe_id: String,
  validations: List(ValidationResult),
) -> Result(Nil, StorageError)

/// Get cached compliance
pub fn get_compliance(
  conn: pog.Connection,
  recipe_id: String,
) -> Result(CachedValidation, StorageError)
```

---

## API Specifications

### POST `/api/meal-plans/auto` - Generate Meal Plan

**Request Body:**
```json
{
  "user_id": "user123",
  "diet_principles": ["vertical_diet", "tim_ferriss"],
  "macro_targets": {
    "protein": 180.0,
    "fat": 60.0,
    "carbs": 250.0
  },
  "recipe_count": 4,
  "min_score": 0.5
}
```

**Response (200 OK):**
```json
{
  "id": "plan_abc123",
  "user_id": "user123",
  "recipes": [
    {
      "recipe": {
        "id": "recipe_1",
        "name": "Grilled Salmon with Rice",
        "macros": {
          "protein": 45.0,
          "fat": 15.0,
          "carbs": 50.0,
          "calories": 505.0
        },
        "servings": 1,
        "category": "dinner",
        "fodmap_level": "low",
        "vertical_compliant": true
      },
      "score": 0.95,
      "match_reason": "High protein (45g), low FODMAP, vertical diet compliant",
      "macro_contribution": {
        "protein": 45.0,
        "fat": 15.0,
        "carbs": 50.0,
        "calories": 505.0
      }
    },
    // ... 3 more recipes
  ],
  "total_macros": {
    "protein": 175.0,
    "fat": 58.0,
    "carbs": 240.0,
    "calories": 2145.0
  },
  "generated_at": "2025-12-03T10:30:00Z",
  "diet_principles": ["vertical_diet", "tim_ferriss"],
  "status": "active"
}
```

**Error Responses:**
- `400 Bad Request` - Invalid input (missing user_id, invalid diet principle)
- `404 Not Found` - User not found or no recipes available
- `500 Internal Server Error` - Database or processing error

---

### GET `/api/meal-plans/auto/:id` - Retrieve Meal Plan

**Response (200 OK):**
```json
{
  "id": "plan_abc123",
  "user_id": "user123",
  "recipes": [ /* same as above */ ],
  "total_macros": { /* ... */ },
  "generated_at": "2025-12-03T10:30:00Z",
  "status": "active"
}
```

**Error Responses:**
- `404 Not Found` - Plan ID does not exist

---

### POST `/api/recipe-sources` - Add Recipe Source

**Request Body:**
```json
{
  "name": "Spoonacular API",
  "type": "api",
  "config": {
    "endpoint": "https://api.spoonacular.com/recipes",
    "api_key": "your_key_here",
    "rate_limit": 150
  },
  "enabled": true
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "name": "Spoonacular API",
  "type": "api",
  "enabled": true,
  "created_at": "2025-12-03T10:30:00Z"
}
```

---

### GET `/api/recipe-sources` - List Recipe Sources

**Response (200 OK):**
```json
{
  "sources": [
    {
      "id": 1,
      "name": "Spoonacular API",
      "type": "api",
      "enabled": true,
      "created_at": "2025-12-03T10:30:00Z"
    },
    {
      "id": 2,
      "name": "Manual Recipes",
      "type": "manual",
      "enabled": true,
      "created_at": "2025-12-03T10:00:00Z"
    }
  ]
}
```

---

## Recipe Scoring Algorithm

The scoring system evaluates recipes on a 0.0-1.0 scale using multiple weighted factors:

### Scoring Factors

1. **Macro Match Score (Weight: 0.40)**
   - How well recipe macros align with user's goals
   - Uses NCP deviation calculation
   - Perfect match = 1.0, Large deviation = 0.0
   - Formula:
     ```gleam
     let protein_match = 1.0 - (abs(recipe.protein - target.protein) / target.protein)
     let fat_match = 1.0 - (abs(recipe.fat - target.fat) / target.fat)
     let carb_match = 1.0 - (abs(recipe.carbs - target.carbs) / target.carbs)
     let macro_score = (protein_match + fat_match + carb_match) / 3.0
     ```

2. **Diet Compliance Score (Weight: 0.30)**
   - Boolean compliance with each diet principle
   - Multiple diets can be specified
   - Formula:
     ```gleam
     let compliant_count = list.filter(diets, fn(d) { validate_recipe(recipe, d).compliant })
     let compliance_score = float(length(compliant_count)) / float(length(diets))
     ```

3. **Protein Quality Score (Weight: 0.20)**
   - Prioritizes high-quality protein sources
   - Scale: 1.0 = beef/salmon, 0.8 = chicken, 0.6 = eggs, 0.4 = plant
   - Formula:
     ```gleam
     let protein_quality = protein_source_quality(recipe.primary_protein)
     let protein_amount = recipe.macros.protein
     let protein_score = protein_quality * min(protein_amount / 40.0, 1.0)
     ```

4. **Variety Score (Weight: 0.10)**
   - Penalizes recipes with protein sources already in plan
   - Ensures diverse meal plan
   - Formula:
     ```gleam
     let selected_proteins = list.map(already_selected, fn(r) { r.primary_protein })
     let variety_score = case list.contains(selected_proteins, recipe.primary_protein) {
       True -> 0.3  // Heavy penalty for duplicate
       False -> 1.0 // Bonus for new protein source
     }
     ```

### Final Score Calculation

```gleam
pub fn score_recipe(
  recipe: Recipe,
  goals: ncp.NutritionGoals,
  diets: List(DietPrinciple),
  selected: List(Recipe),
) -> Float {
  let macro_score = calculate_macro_match(recipe, goals)
  let diet_score = calculate_diet_compliance(recipe, diets)
  let protein_score = calculate_protein_quality(recipe)
  let variety_score = calculate_variety(recipe, selected)

  let final =
    (macro_score *. 0.40) +.
    (diet_score *. 0.30) +.
    (protein_score *. 0.20) +.
    (variety_score *. 0.10)

  float.clamp(final, 0.0, 1.0)
}
```

---

## Database Schema Usage

### Tables

#### `recipe_sources`
```sql
CREATE TABLE recipe_sources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL CHECK(type IN ('api', 'scraper', 'manual')),
    config TEXT, -- JSON: API keys, endpoints, etc.
    enabled BOOLEAN NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

**Gleam Mapping:**
```gleam
pub type RecipeSource {
  RecipeSource(
    id: Int,
    name: String,
    source_type: SourceType,
    config: SourceConfig,
    enabled: Bool,
  )
}
```

#### `auto_meal_plans`
```sql
CREATE TABLE auto_meal_plans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    diet_principles TEXT NOT NULL, -- JSON: ["vertical_diet", "tim_ferriss"]
    recipe_ids TEXT NOT NULL, -- JSON: [1, 2, 3, 4]
    macro_targets TEXT, -- JSON: {"protein": 180, "fat": 60, "carbs": 250}
    status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'archived')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

**Gleam Mapping:**
```gleam
pub type AutoMealPlan {
  AutoMealPlan(
    id: String,
    user_id: String,
    recipes: List(ScoredRecipe),
    total_macros: Macros,
    generated_at: String,
    diet_principles: List(DietPrinciple),
    macro_targets: Option(Macros),
    status: PlanStatus,
  )
}
```

#### `recipe_diet_compliance`
```sql
CREATE TABLE recipe_diet_compliance (
    recipe_id INTEGER PRIMARY KEY,
    vertical_diet_compliant BOOLEAN NOT NULL DEFAULT 0,
    tim_ferriss_compliant BOOLEAN NOT NULL DEFAULT 0,
    compliance_notes TEXT, -- JSON: reasons, violations
    last_checked TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
);
```

**Gleam Mapping:**
```gleam
pub type CachedValidation {
  CachedValidation(
    recipe_id: String,
    validations: List(ValidationResult),
    last_checked: String,
  )
}
```

---

## Integration Points

### 1. NCP (Nutrition Control Plane) Integration

**Module:** `meal_planner/ncp.gleam`

**Integration Points:**
- Use `ncp.NutritionGoals` for macro targets
- Use `ncp.calculate_deviation()` for recipe scoring
- Use `ncp.score_recipe_for_deviation()` for NCP-based scoring
- Use `ncp.NutritionState` for historical nutrition data

**Example:**
```gleam
import meal_planner/ncp

pub fn score_with_ncp(
  recipe: Recipe,
  goals: ncp.NutritionGoals,
) -> Float {
  // Convert recipe macros to NutritionData
  let recipe_nutrition = ncp.NutritionData(
    protein: recipe.macros.protein,
    fat: recipe.macros.fat,
    carbs: recipe.macros.carbs,
    calories: macros_calories(recipe.macros),
  )

  // Calculate how well recipe addresses current deviation
  let deviation = ncp.calculate_deviation(goals, recipe_nutrition)
  ncp.score_recipe_for_deviation(deviation, recipe.macros)
}
```

### 2. Storage Integration

**Module:** `meal_planner/storage.gleam`

**Integration Points:**
- Use existing `pog.Connection` for database access
- Reuse storage patterns for error handling
- Follow existing decoder patterns for SQLite/PostgreSQL

**Example:**
```gleam
import meal_planner/storage

pub fn fetch_recipes_for_planning(
  conn: pog.Connection,
  diets: List(DietPrinciple),
) -> Result(List(Recipe), StorageError) {
  // Leverage existing recipe storage functions
  case storage.get_all_recipes(conn) {
    Ok(recipes) -> {
      // Additional filtering by diet if needed
      Ok(filter_by_diet(recipes, diets))
    }
    Error(e) -> Error(e)
  }
}
```

### 3. Web Handler Integration

**Module:** `meal_planner/web.gleam`

**New Handler Functions:**
```gleam
// In handle_api function, add:
["meal-plans", "auto"] ->
  case req.method {
    http.Post -> generate_meal_plan_handler(req, ctx)
    _ -> wisp.method_not_allowed([http.Post])
  }

["meal-plans", "auto", id] ->
  case req.method {
    http.Get -> get_meal_plan_handler(id, ctx)
    _ -> wisp.method_not_allowed([http.Get])
  }

["recipe-sources"] ->
  case req.method {
    http.Post -> create_recipe_source_handler(req, ctx)
    http.Get -> list_recipe_sources_handler(ctx)
    _ -> wisp.method_not_allowed([http.Post, http.Get])
  }
```

---

## Type Definitions Summary

### Core Types in `auto_planner.gleam`

```gleam
/// Main configuration
pub type AutoPlanConfig {
  AutoPlanConfig(
    user_id: String,
    diet_principles: List(DietPrinciple),
    macro_targets: Option(Macros),
    recipe_limit: Int,
    variety_factor: Float,
    min_score_threshold: Float,
  )
}

/// Diet principles
pub type DietPrinciple {
  VerticalDiet
  TimFerriss
  LowFodmap
  Custom(name: String)
}

/// Generated plan
pub type AutoMealPlan {
  AutoMealPlan(
    id: String,
    user_id: String,
    recipes: List(ScoredRecipe),
    total_macros: Macros,
    generated_at: String,
    diet_principles: List(DietPrinciple),
    macro_targets: Option(Macros),
    status: PlanStatus,
  )
}

pub type PlanStatus {
  Active
  Archived
}

/// Recipe with score
pub type ScoredRecipe {
  ScoredRecipe(
    recipe: Recipe,
    score: Float,
    match_reason: String,
    macro_contribution: Macros,
  )
}

/// Variety tracking
pub type VarietyContext {
  VarietyContext(
    selected_proteins: List(String),
    selected_categories: List(String),
  )
}

/// Error types
pub type PlanError {
  InsufficientRecipes(available: Int, required: Int)
  NoCompliantRecipes(diet: DietPrinciple)
  MacroTargetUnreachable(reason: String)
  StorageError(storage.StorageError)
}
```

### Diet Validator Types in `diet_validator.gleam`

```gleam
pub type ValidationResult {
  ValidationResult(
    compliant: Bool,
    diet: DietPrinciple,
    violations: List(String),
    confidence: Float,
  )
}

pub type CachedValidation {
  CachedValidation(
    recipe_id: String,
    validations: List(ValidationResult),
    last_checked: String,
  )
}

pub type ValidationError {
  RecipeNotFound(String)
  InvalidDietPrinciple(String)
  CacheError(storage.StorageError)
}
```

### Recipe Fetcher Types in `recipe_fetcher.gleam`

```gleam
pub type RecipeSource {
  RecipeSource(
    id: Int,
    name: String,
    source_type: SourceType,
    config: SourceConfig,
    enabled: Bool,
  )
}

pub type SourceType {
  Api
  Scraper
  Manual
}

pub type SourceConfig {
  ApiConfig(endpoint: String, api_key: Option(String), rate_limit: Int)
  ScraperConfig(base_url: String, selectors: SelectorMap)
  ManualConfig
}

pub type FetchedRecipe {
  FetchedRecipe(
    source_id: Int,
    external_id: String,
    name: String,
    ingredients: List(String),
    instructions: List(String),
    macros: Option(Macros),
    url: String,
  )
}

pub type FetchError {
  NetworkError(String)
  RateLimitExceeded(Int)
  ParseError(String)
  AuthenticationError
  SourceDisabled(Int)
}

pub type SelectorMap {
  SelectorMap(
    name: String,
    ingredients: String,
    instructions: String,
    macros: Option(String),
  )
}
```

---

## Implementation Phases

### Phase 1: Core Algorithm (Week 1)
- [ ] Implement `auto_planner.gleam` core types
- [ ] Implement recipe scoring algorithm
- [ ] Implement variety filtering
- [ ] Unit tests for scoring and selection
- [ ] Integration with NCP for macro matching

### Phase 2: Diet Validation (Week 1)
- [ ] Implement `diet_validator.gleam`
- [ ] Vertical Diet validation rules
- [ ] Tim Ferriss 4HB validation rules
- [ ] Compliance caching system
- [ ] Unit tests for validation

### Phase 3: Storage Layer (Week 2)
- [ ] Implement `auto_planner_storage.gleam`
- [ ] Database queries for meal plans
- [ ] Recipe source management
- [ ] Compliance cache operations
- [ ] Integration tests with SQLite

### Phase 4: API Layer (Week 2)
- [ ] POST `/api/meal-plans/auto` handler
- [ ] GET `/api/meal-plans/auto/:id` handler
- [ ] POST/GET `/api/recipe-sources` handlers
- [ ] JSON encoding/decoding
- [ ] API integration tests

### Phase 5: Recipe Fetcher (Week 3)
- [ ] Implement `recipe_fetcher.gleam`
- [ ] Spoonacular API integration
- [ ] Rate limiting and error handling
- [ ] Recipe normalization
- [ ] Sync to database

### Phase 6: UI Integration (Week 3)
- [ ] Meal plan generation form
- [ ] Plan display page
- [ ] Recipe source management UI
- [ ] Integration with existing dashboard

---

## Performance Considerations

1. **Recipe Scoring Optimization**
   - Cache recipe scores for common goal combinations
   - Batch score calculations
   - Early exit for low-scoring recipes

2. **Database Query Optimization**
   - Index on `recipe_diet_compliance.vertical_diet_compliant`
   - Index on `recipe_diet_compliance.tim_ferriss_compliant`
   - Composite index on `auto_meal_plans(user_id, status, generated_at)`
   - Use EXPLAIN QUERY PLAN to optimize joins

3. **Validation Caching**
   - Cache validation results for 7 days
   - Invalidate cache when recipe is updated
   - Batch validation for efficiency

4. **API Rate Limiting**
   - Implement exponential backoff for external APIs
   - Queue recipe fetches to respect rate limits
   - Cache fetched recipes for 24 hours

---

## Testing Strategy

### Unit Tests
- `auto_planner_test.gleam` - Scoring algorithm, variety filtering
- `diet_validator_test.gleam` - Validation rules for each diet
- `recipe_fetcher_test.gleam` - Parsing and normalization

### Integration Tests
- `auto_planner_storage_test.gleam` - Database operations
- `auto_planner_api_test.gleam` - API endpoints

### End-to-End Tests
- Generate meal plan for user with specific goals
- Verify recipe diversity and compliance
- Test error handling for insufficient recipes

---

## Security Considerations

1. **API Key Storage**
   - Store external API keys encrypted in database
   - Never return API keys in API responses
   - Use environment variables for sensitive keys

2. **Input Validation**
   - Validate user_id exists before plan generation
   - Sanitize diet principle inputs
   - Validate macro targets are positive numbers

3. **Rate Limiting**
   - Limit meal plan generations per user (e.g., 10/hour)
   - Protect recipe source endpoints with authentication
   - Monitor for abuse patterns

---

## Future Enhancements

1. **Advanced Variety**
   - Ensure different cooking methods (grilled, baked, etc.)
   - Vary meal categories (breakfast, lunch, dinner, snack)
   - Track user meal history for long-term variety

2. **Machine Learning**
   - Learn user preferences from meal selections
   - Improve scoring based on feedback
   - Predict optimal meal times

3. **Meal Prep Optimization**
   - Group recipes by shared ingredients
   - Optimize cooking order
   - Generate shopping lists

4. **Social Features**
   - Share meal plans with friends
   - Rate and review recipes
   - Community-contributed recipes

---

## References

- [Existing NCP System](../gleam/src/meal_planner/ncp.gleam)
- [Storage Module](../gleam/src/meal_planner/storage.gleam)
- [Shared Types](../shared/src/shared/types.gleam)
- [Migration 006](../gleam/migrations/006_auto_meal_planner.sql)
- [Web Handlers](../gleam/src/meal_planner/web.gleam)

---

**Document Status:** ✅ Complete
**Review Required:** Yes
**Next Steps:** Begin Phase 1 implementation
