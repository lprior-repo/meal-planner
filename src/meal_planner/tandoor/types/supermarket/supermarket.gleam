import gleam/option.{type Option}

/// Supermarket/store definition
/// Represents a physical or online grocery store with category mappings
pub type Supermarket {
  Supermarket(
    /// Tandoor supermarket ID
    id: Int,
    /// Supermarket name (e.g., "Whole Foods", "Trader Joe's")
    name: String,
    /// Optional description
    description: Option(String),
    /// Category mappings for this supermarket
    /// Maps food categories to store-specific aisles/sections
    category_to_supermarket: List(SupermarketCategoryRelation),
    /// Optional slug for external data integration
    open_data_slug: Option(String),
  )
}

/// Relation between a supermarket and a category
/// Defines the ordering and association of categories within a specific store
pub type SupermarketCategoryRelation {
  SupermarketCategoryRelation(
    /// Relation ID
    id: Int,
    /// The category being mapped
    category_id: Int,
    /// The supermarket this category belongs to
    supermarket_id: Int,
    /// Display order for this category in the supermarket
    order: Int,
  )
}
