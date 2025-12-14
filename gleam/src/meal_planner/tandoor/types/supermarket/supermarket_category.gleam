import gleam/option.{type Option}

/// Supermarket category for organizing foods by store aisles/sections
/// Maps food categories to supermarket departments (e.g., "Produce", "Dairy")
pub type SupermarketCategory {
  SupermarketCategory(
    /// Tandoor supermarket category ID
    id: Int,
    /// Category name (e.g., "Produce", "Dairy", "Frozen Foods")
    name: String,
    /// Optional description of this category
    description: Option(String),
    /// Optional slug for external data integration
    open_data_slug: Option(String),
  )
}
