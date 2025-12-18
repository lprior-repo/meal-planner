/// Tandoor Keyword type definition
///
/// This module defines the Keyword type used for recipe categorization in Tandoor.
/// Keywords form a tree structure with parent-child relationships and are used
/// to organize recipes by cuisine, diet type, course, etc.
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/option.{type Option}

/// Keyword/tag for recipe categorization
///
/// Keywords in Tandoor form a hierarchical tree structure allowing nested
/// categorization (e.g., Cuisine > Italian > Sicilian).
///
/// Fields:
/// - id: Unique identifier
/// - name: Machine-friendly name (lowercase, no spaces)
/// - label: Human-readable display name (readonly, auto-generated from name)
/// - description: Optional detailed description
/// - icon: Optional emoji or icon character
/// - parent: ID of parent keyword (None for root keywords)
/// - numchild: Number of direct children (readonly)
/// - created_at: Creation timestamp (readonly)
/// - updated_at: Last update timestamp (readonly)
/// - full_name: Full path from root (e.g., "Cuisine > Italian > Sicilian") (readonly)
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
