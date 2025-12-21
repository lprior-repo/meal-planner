/// Encoder helpers for optional field handling
///
/// This module provides reusable encoder functions for common optional field patterns
/// used across all Tandoor type encoders. These helpers consolidate encoder duplication,
/// reducing code by ~300-400 lines while maintaining type safety.
///
/// # Common Patterns
///
/// - Optional String fields → JSON string or null
/// - Optional Int fields → JSON int or null
/// - Optional Bool fields → JSON bool or null
/// - Optional Float fields → JSON float or null
/// - Optional IDs (polymorphic) → JSON int or null
/// - Optional ID lists → JSON array or null
///
/// # Architecture
///
/// All helpers follow the same pattern:
///   Option(a) → Json
///
/// When Some(value): Encode value to appropriate JSON type
/// When None: Return json.null()
import gleam/json.{type Json}
import gleam/option

/// Encode optional String value
///
/// Some(s) → json.string(s)
/// None → json.null()
pub fn encode_optional_string(value: option.Option(String)) -> Json {
  case value {
    option.Some(s) -> json.string(s)
    option.None -> json.null()
  }
}

/// Encode optional Int value
///
/// Some(i) → json.int(i)
/// None → json.null()
pub fn encode_optional_int(value: option.Option(Int)) -> Json {
  case value {
    option.Some(i) -> json.int(i)
    option.None -> json.null()
  }
}

/// Encode optional Bool value
///
/// Some(b) → json.bool(b)
/// None → json.null()
pub fn encode_optional_bool(value: option.Option(Bool)) -> Json {
  case value {
    option.Some(b) -> json.bool(b)
    option.None -> json.null()
  }
}

/// Encode optional Float value
///
/// Some(f) → json.float(f)
/// None → json.null()
pub fn encode_optional_float(value: option.Option(Float)) -> Json {
  case value {
    option.Some(f) -> json.float(f)
    option.None -> json.null()
  }
}

/// Encode optional value via polymorphic encoder function
///
/// This is a generic helper for encoding ID types or other domain types
/// that need a conversion function to int or other JSON-compatible value.
///
/// # Example
/// ```gleam
/// // Encoding optional RecipeId
/// encode_optional_with(recipe_id, ids.recipe_id_to_int)
/// ```
pub fn encode_optional_with(
  value: option.Option(a),
  encoder: fn(a) -> Json,
) -> Json {
  case value {
    option.Some(v) -> encoder(v)
    option.None -> json.null()
  }
}

/// Encode optional ID field (converts to int)
///
/// This is a specialized version for ID types that all convert to int.
/// Requires a to_int converter function.
///
/// # Example
/// ```gleam
/// encode_optional_id(recipe_id, ids.recipe_id_to_int)
/// ```
pub fn encode_optional_id(id: option.Option(a), to_int: fn(a) -> Int) -> Json {
  case id {
    option.Some(id) -> json.int(to_int(id))
    option.None -> json.null()
  }
}

/// Encode optional list value
///
/// Some(list) → json.array(list, item_encoder)
/// None → json.null()
pub fn encode_optional_list(
  value: option.Option(List(a)),
  item_encoder: fn(a) -> Json,
) -> Json {
  case value {
    option.Some(list) -> json.array(list, item_encoder)
    option.None -> json.null()
  }
}
