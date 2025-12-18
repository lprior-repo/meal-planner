/// Tandoor KeywordLabel type definition
///
/// This module defines the lightweight KeywordLabel type used in list/overview
/// responses (e.g., RecipeOverview.keywords). It's a minimal version of the full
/// Keyword type, containing only the essential fields needed for display in lists.
///
/// KeywordLabel is used instead of full Keyword to optimize API response size and
/// parsing performance when dealing with large recipe lists.
///
/// Based on Tandoor API 2.3.6 specification.
/// Lightweight keyword/tag for recipe categorization in list responses
///
/// This type is used in list/overview endpoints where full Keyword data is not needed.
/// It contains only the three essential fields: id, name, and label.
///
/// Fields:
/// - id: Unique identifier
/// - name: Machine-friendly name (lowercase, no spaces)
/// - label: Human-readable display name (readonly, auto-generated from name)
pub type KeywordLabel {
  KeywordLabel(id: Int, name: String, label: String)
}
