import gleam/option.{type Option}

/// Tandoor Unit type
/// Represents a unit of measurement (gram, liter, piece, etc.)
pub type Unit {
  Unit(
    /// Tandoor unit ID
    id: Int,
    /// Unit name (required)
    name: String,
    /// Optional plural form of the unit name
    plural_name: Option(String),
    /// Optional description of the unit
    description: Option(String),
    /// Optional base unit for conversion
    base_unit: Option(String),
    /// Optional Open Food Facts data slug
    open_data_slug: Option(String),
  )
}
