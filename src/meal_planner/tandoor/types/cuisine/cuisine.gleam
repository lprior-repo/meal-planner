/// Cuisine types for Tandoor recipe management
///
/// Cuisines represent the cultural or regional origin of recipes (e.g., Italian, Mexican, Thai).
/// In Tandoor, cuisines are typically managed as a specialized keyword category.
import gleam/option.{type Option}
import meal_planner/tandoor/core/ids.{type CuisineId}

/// Cuisine data structure from Tandoor API
///
/// Cuisines categorize recipes by their cultural or regional origin.
/// They can be hierarchical (e.g., Asian > Chinese > Szechuan).
///
/// Fields:
/// - id: Unique identifier (readonly)
/// - name: Display name (e.g., "Italian", "Mexican") (max 128 chars)
/// - description: Optional detailed description
/// - icon: Optional emoji or icon identifier
/// - parent: Optional parent cuisine ID for hierarchy
/// - num_recipes: Number of recipes tagged with this cuisine (readonly)
/// - created_at: Timestamp when created (readonly)
/// - updated_at: Timestamp when last modified (readonly)
pub type Cuisine {
  Cuisine(
    id: CuisineId,
    name: String,
    description: Option(String),
    icon: Option(String),
    parent: Option(CuisineId),
    num_recipes: Int,
    created_at: String,
    updated_at: String,
  )
}

/// Request data for creating a new cuisine
///
/// Only required field is `name`. All other fields are optional.
pub type CuisineCreateRequest {
  CuisineCreateRequest(
    name: String,
    description: Option(String),
    icon: Option(String),
    parent: Option(Int),
  )
}

/// Request data for updating an existing cuisine
///
/// All fields are optional - only provided fields will be updated (PATCH semantics).
/// For nullable fields (description, icon, parent):
/// - None: Don't update this field
/// - Some(None): Set to null
/// - Some(Some(value)): Set to value
pub type CuisineUpdateRequest {
  CuisineUpdateRequest(
    name: Option(String),
    description: Option(Option(String)),
    icon: Option(Option(String)),
    parent: Option(Option(Int)),
  )
}
