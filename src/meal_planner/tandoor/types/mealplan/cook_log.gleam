/// Tandoor CookLog type definition
///
/// This module defines the CookLog type for tracking cooking history.
/// CookLog records when recipes were cooked, enabling analytics and rotation tracking.
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/option.{type Option}
import meal_planner/tandoor/core/ids.{type UserId}

/// Record of when a recipe was cooked
///
/// Tracks cooking history for analytics, preferences, and meal planning rotation.
///
/// Fields:
/// - id: Unique identifier
/// - recipe: Recipe ID (readonly reference)
/// - servings: Number of servings prepared (int)
/// - rating: Optional subjective rating (1-5 scale, nullable)
/// - created_by: User who recorded this cook log (readonly)
/// - created_at: When the cooking occurred (readonly, ISO 8601)
pub type CookLog {
  CookLog(
    id: Int,
    recipe: Int,
    servings: Int,
    rating: Option(Int),
    created_by: UserId,
    created_at: String,
  )
}
