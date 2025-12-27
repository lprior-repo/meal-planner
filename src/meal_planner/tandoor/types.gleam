// Shared recipe types to avoid circular imports
//
// This module contains core recipe types used by both Tandoor client
// and CLI domains. By keeping these types in a separate module without
// dependencies on other Tandoor submodules, we avoid circular import cycles.

import gleam/dynamic/decode
import gleam/option.{type Option, None}

/// Basic recipe type for API responses (basic fields for list view)
///
/// This is a lightweight representation suitable for recipe lists and
/// pagination. Contains only essential fields without nested structures.
///
/// Fields:
/// - id: Unique recipe identifier
/// - name: Recipe name
/// - slug: URL-friendly name (optional, readonly)
/// - description: Recipe description (optional)
/// - servings: Number of servings
/// - servings_text: Human-readable servings description (optional, e.g., "4 people")
/// - working_time: Active preparation time in minutes (optional)
/// - waiting_time: Passive waiting time in minutes (optional, e.g., baking, marinating)
/// - created_at: Creation timestamp (optional, readonly)
/// - updated_at: Last update timestamp (optional, readonly)
pub type Recipe {
  Recipe(
    id: Int,
    name: String,
    slug: Option(String),
    description: Option(String),
    servings: Int,
    servings_text: Option(String),
    working_time: Option(Int),
    waiting_time: Option(Int),
    created_at: Option(String),
    updated_at: Option(String),
  )
}

/// Full recipe with ingredients, steps, and nutrition (for detail view)
///
/// This is the complete recipe representation including all nested structures
/// like steps, ingredients, nutrition data, and keywords. Use this for
/// detailed recipe views and when you need access to all recipe information.
///
/// Fields (extends Recipe fields):
/// - steps: List of cooking step IDs (stored as IDs to avoid circular dependency)
/// - nutrition: Optional nutrition information per serving
/// - keywords: List of categorization tags
/// - source_url: Optional URL to external recipe source
///
/// Note: To avoid circular imports, nested types (Keyword, NutritionInfo) are defined inline
pub type RecipeDetail {
  RecipeDetail(
    id: Int,
    name: String,
    slug: Option(String),
    description: Option(String),
    servings: Int,
    servings_text: Option(String),
    working_time: Option(Int),
    waiting_time: Option(Int),
    created_at: Option(String),
    updated_at: Option(String),
    steps: List(Int),
    nutrition: Option(NutritionInfo),
    keywords: List(Keyword),
    source_url: Option(String),
  )
}

/// Recipe overview type for list responses
///
/// Contains a subset of recipe data optimized for pagination and list views.
/// Lighter than full RecipeDetail, suitable for API list endpoints.
/// Includes display-friendly fields like rating and last_cooked.
///
/// Fields:
/// - id: Tandoor recipe ID
/// - name: Recipe name
/// - description: Recipe description
/// - image: Optional recipe image URL
/// - keywords: List of Keyword objects (id, name, description)
/// - rating: Optional user rating (0.0 - 5.0)
/// - last_cooked: Optional last cooked date (ISO 8601 format)
pub type RecipeOverview {
  RecipeOverview(
    id: Int,
    name: String,
    description: String,
    image: Option(String),
    keywords: List(Keyword),
    rating: Option(Float),
    last_cooked: Option(String),
  )
}

/// Minimal recipe type for embedded references
///
/// Used when a recipe is referenced from other entities (e.g., in meal plans).
/// Contains only the most essential fields needed for display and linking.
///
/// Fields:
/// - id: Tandoor recipe ID
/// - name: Recipe name
/// - image: Optional recipe image URL
pub type RecipeSimple {
  RecipeSimple(id: Int, name: String, image: Option(String))
}

/// Request to update an existing recipe (partial update)
///
/// All fields are optional to support partial updates.
/// Only provided fields will be sent in the PATCH request.
///
/// Fields:
/// - name: New recipe name
/// - description: New recipe description
/// - servings: New serving count
/// - servings_text: New servings description
/// - working_time: New active preparation time in minutes
/// - waiting_time: New passive waiting time in minutes
pub type RecipeUpdate {
  RecipeUpdate(
    name: Option(String),
    description: Option(String),
    servings: Option(Int),
    servings_text: Option(String),
    working_time: Option(Int),
    waiting_time: Option(Int),
  )
}

/// Request structure for creating a new recipe
///
/// Only includes writable fields. Tandoor API requires a steps array
/// with at least one step (which can be empty).
///
/// Fields:
/// - name: Recipe name (required)
/// - description: Recipe description (optional)
/// - servings: Number of servings (required)
/// - servings_text: Human-readable servings description (optional)
/// - working_time: Active preparation time in minutes (optional)
/// - waiting_time: Passive waiting time in minutes (optional)
pub type RecipeCreateRequest {
  RecipeCreateRequest(
    name: String,
    description: Option(String),
    servings: Int,
    servings_text: Option(String),
    working_time: Option(Int),
    waiting_time: Option(Int),
  )
}

/// Keyword type for recipe categorization
///
/// Keywords are tags that can be applied to recipes for organization
/// and filtering (e.g., "Vegetarian", "Quick Meal", "Italian").
///
/// Fields:
/// - id: Unique keyword identifier
/// - name: Keyword name
/// - label: Display label
/// - description: Keyword description
/// - icon: Optional icon name
/// - parent: Optional parent keyword ID
/// - numchild: Number of child keywords
/// - created_at: Creation timestamp
/// - updated_at: Last update timestamp
/// - full_name: Full hierarchical name
pub type Keyword {
  Keyword(
    id: Int,
    name: String,
    label: String,
    description: String,
    icon: Option(String),
    parent: Option(Int),
    numchild: Int,
    created_at: String,
    updated_at: String,
    full_name: String,
  )
}

/// Nutrition information for recipes
///
/// Contains per-serving nutritional data. All fields are optional
/// as not all recipes have complete nutrition information.
///
/// Fields:
/// - calories: Calories per serving (kcal)
/// - fat: Total fat per serving (g)
/// - saturated_fat: Saturated fat per serving (g)
/// - carbohydrates: Total carbohydrates per serving (g)
/// - sugars: Sugars per serving (g)
/// - fiber: Dietary fiber per serving (g)
/// - protein: Protein per serving (g)
/// - salt: Salt/sodium per serving (g)
pub type NutritionInfo {
  NutritionInfo(
    calories: Option(Float),
    fat: Option(Float),
    saturated_fat: Option(Float),
    carbohydrates: Option(Float),
    sugars: Option(Float),
    fiber: Option(Float),
    protein: Option(Float),
    salt: Option(Float),
  )
}

// ============================================================================
// Decoder Functions
// ============================================================================

/// Decode a Keyword from JSON
///
/// Used for recipe keywords/categorization.
///
/// Example JSON:
/// ```json
/// {
///   "id": 1,
///   "name": "Vegetarian",
///   "label": "Vegetarian",
///   "description": "Vegetarian recipes",
///   "icon": "leaf",
///   "parent": null,
///   "numchild": 0,
///   "created_at": "2024-01-01T00:00:00Z",
///   "updated_at": "2024-01-01T00:00:00Z",
///   "full_name": "Vegetarian"
/// }
/// ```
pub fn keyword_decoder() -> decode.Decoder(Keyword) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use label <- decode.field("label", decode.string)
  use description <- decode.field("description", decode.string)
  use icon <- decode.optional_field(
    "icon",
    None,
    decode.optional(decode.string),
  )
  use parent <- decode.field("parent", decode.optional(decode.int))
  use numchild <- decode.field("numchild", decode.int)
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)
  use full_name <- decode.field("full_name", decode.string)

  decode.success(Keyword(
    id: id,
    name: name,
    label: label,
    description: description,
    icon: icon,
    parent: parent,
    numchild: numchild,
    created_at: created_at,
    updated_at: updated_at,
    full_name: full_name,
  ))
}
