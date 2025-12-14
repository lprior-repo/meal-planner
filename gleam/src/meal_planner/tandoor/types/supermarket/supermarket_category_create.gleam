import gleam/option.{type Option}

/// Request type for creating a new supermarket category
pub type SupermarketCategoryCreateRequest {
  SupermarketCategoryCreateRequest(
    /// Category name (e.g., "Produce", "Dairy", "Frozen Foods")
    name: String,
    /// Optional description of this category
    description: Option(String),
  )
}
