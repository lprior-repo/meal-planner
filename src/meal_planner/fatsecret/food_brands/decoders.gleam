/// FatSecret Food Brands JSON decoders
///
/// This module provides type-safe decoders for FatSecret Brands API responses.
///
/// FatSecret API quirks handled:
/// 1. Single vs array: Returns object for 1 result, array for multiple
/// 2. Invalid brand type: Defaults to Manufacturer for unknown types
import gleam/dynamic
import gleam/dynamic/decode
import meal_planner/fatsecret/food_brands/types.{
  type Brand, type BrandType, type BrandsResponse, Brand, BrandsResponse,
  Manufacturer, Restaurant, Supermarket, brand_id,
}

// ============================================================================
// Brand Type Decoder
// ============================================================================

/// Decode a BrandType from string
///
/// Returns Manufacturer for unknown types (FatSecret fallback behavior)
fn brand_type_decoder() -> decode.Decoder(BrandType) {
  use type_str <- decode.then(decode.string)
  let brand_type = case type_str {
    "manufacturer" -> Manufacturer
    "restaurant" -> Restaurant
    "supermarket" -> Supermarket
    _ -> Manufacturer // Default to Manufacturer for unknown types
  }
  decode.success(brand_type)
}

// ============================================================================
// Brand Decoder
// ============================================================================

/// Decoder for a single brand
pub fn brand_decoder() -> decode.Decoder(Brand) {
  use brand_id_str <- decode.field("brand_id", decode.string)
  use brand_name <- decode.field("brand_name", decode.string)
  use brand_type <- decode.field("brand_type", brand_type_decoder())

  decode.success(Brand(
    brand_id: brand_id(brand_id_str),
    brand_name: brand_name,
    brand_type: brand_type,
  ))
}

// ============================================================================
// Brands List Decoder
// ============================================================================

/// Decode brands list handling single-vs-array quirk
///
/// FatSecret returns:
/// - `{"brands": {...}}` for 1 brand
/// - `{"brands": [{...}, {...}]}` for multiple brands
fn brands_list_decoder() -> decode.Decoder(List(Brand)) {
  decode.one_of(
    // Try array first
    decode.list(brand_decoder()),
    or: [
      // Fallback to single object wrapped in list
      {
        use single <- decode.then(brand_decoder())
        decode.success([single])
      },
    ],
  )
}

// ============================================================================
// Brands Response Decoder
// ============================================================================

/// Decoder for brands.get.v2 API response
///
/// Handles the brands array/object quirk
pub fn brands_response_decoder() -> decode.Decoder(BrandsResponse) {
  use brands <- decode.field("brands", brands_list_decoder())
  decode.success(BrandsResponse(brands: brands))
}

/// Decode BrandsResponse from API response
pub fn decode_brands_response(
  json: dynamic.Dynamic,
) -> Result(BrandsResponse, List(decode.DecodeError)) {
  decode.run(json, brands_response_decoder())
}
