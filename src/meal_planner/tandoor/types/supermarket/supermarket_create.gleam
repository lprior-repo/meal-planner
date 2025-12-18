import gleam/option.{type Option}

/// Request type for creating a new supermarket
///
/// This type is used when creating a new supermarket in the Tandoor API.
/// It contains only the fields needed for creation (not the ID or relations).
pub type SupermarketCreateRequest {
  SupermarketCreateRequest(
    /// Supermarket name (e.g., "Whole Foods", "Trader Joe's")
    name: String,
    /// Optional description
    description: Option(String),
  )
}
