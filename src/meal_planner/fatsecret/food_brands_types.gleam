/// FatSecret SDK Food Brands domain types
///
/// This module defines the core types for the FatSecret Food Brands API.
/// These types are independent from the Tandoor domain and represent
/// FatSecret's data structures.
///
/// Opaque types are used for IDs to ensure type safety and prevent
/// accidental mixing of different ID types.
// ============================================================================
// Opaque ID Types
// ============================================================================

/// Opaque type for FatSecret brand IDs
pub opaque type BrandId {
  BrandId(String)
}

/// Create a BrandId from a string
pub fn brand_id(id: String) -> BrandId {
  BrandId(id)
}

/// Convert BrandId to string (for API calls)
pub fn brand_id_to_string(id: BrandId) -> String {
  case id {
    BrandId(s) -> s
  }
}

// ============================================================================
// Brand Type Enumeration
// ============================================================================

/// Type of food brand (manufacturer, restaurant, or supermarket)
///
/// FatSecret categorizes brands into three types based on their origin
/// and business model.
pub type BrandType {
  /// Manufacturer - Food production companies
  Manufacturer
  /// Restaurant - Restaurant chains or dining establishments
  Restaurant
  /// Supermarket - Supermarket chains or food retailers
  Supermarket
}

/// Convert BrandType to FatSecret API string representation
pub fn brand_type_to_string(brand_type: BrandType) -> String {
  case brand_type {
    Manufacturer -> "manufacturer"
    Restaurant -> "restaurant"
    Supermarket -> "supermarket"
  }
}

/// Parse FatSecret API string to BrandType
///
/// Returns Ok(type) if the string matches a known brand type.
/// Returns Error(Nil) for unknown types.
pub fn brand_type_from_string(s: String) -> Result(BrandType, Nil) {
  case s {
    "manufacturer" -> Ok(Manufacturer)
    "restaurant" -> Ok(Restaurant)
    "supermarket" -> Ok(Supermarket)
    _ -> Error(Nil)
  }
}

// ============================================================================
// Brand Information
// ============================================================================

/// Complete brand information from brands.get.v2 API
///
/// Contains brand details including ID, name, and type classification.
pub type Brand {
  Brand(
    /// Unique brand identifier
    brand_id: BrandId,
    /// Brand name (e.g., "Kraft", "KFC", "Whole Foods")
    brand_name: String,
    /// Brand type (Manufacturer, Restaurant, or Supermarket)
    brand_type: BrandType,
  )
}

// ============================================================================
// API Responses
// ============================================================================

/// Response from brands.get.v2 API
///
/// Contains a list of brands, optionally filtered by starting letter or type.
pub type BrandsResponse {
  BrandsResponse(
    /// List of matching brands
    brands: List(Brand),
  )
}
