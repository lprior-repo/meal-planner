//// Type-safe ID wrappers for the meal planner application.

import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/json.{type Json}
import gleam/string

// ============================================================================
// Opaque ID Types
// ============================================================================

/// Food Data Central ID (USDA database identifier)
pub opaque type FdcId {
  FdcId(value: Int)
}

/// Recipe ID (meal planner recipe identifier)
pub opaque type RecipeId {
  RecipeId(value: String)
}

/// User ID (user account identifier)
pub opaque type UserId {
  UserId(value: String)
}

/// Custom Food ID (user-created food identifier)
pub opaque type CustomFoodId {
  CustomFoodId(value: String)
}

/// Food Log Entry ID (food log record identifier)
pub opaque type LogEntryId {
  LogEntryId(value: String)
}

/// Job ID (scheduled job identifier)
pub opaque type JobId {
  JobId(value: String)
}

// ============================================================================
// FdcId Constructors and Accessors
// ============================================================================

pub fn fdc_id(value: Int) -> FdcId {
  FdcId(value)
}

pub fn fdc_id_validated(value: Int) -> Result(FdcId, String) {
  case value > 0 {
    True -> Ok(FdcId(value))
    False -> Error("FDC ID must be positive, got: " <> int.to_string(value))
  }
}

pub fn fdc_id_to_int(id: FdcId) -> Int {
  id.value
}

pub fn fdc_id_to_string(id: FdcId) -> String {
  int.to_string(id.value)
}

pub fn fdc_id_from_string(s: String) -> Result(FdcId, String) {
  case int.parse(s) {
    Ok(i) -> fdc_id_validated(i)
    Error(_) -> Error("Invalid FDC ID format: '" <> s <> "'")
  }
}

// ============================================================================
// RecipeId Constructors and Accessors
// ============================================================================

pub fn recipe_id(value: String) -> RecipeId {
  RecipeId(value)
}

pub fn recipe_id_validated(value: String) -> Result(RecipeId, String) {
  let trimmed = string.trim(value)
  case string.length(trimmed) {
    0 -> Error("Recipe ID cannot be empty")
    _ -> Ok(RecipeId(trimmed))
  }
}

pub fn recipe_id_to_string(id: RecipeId) -> String {
  id.value
}

// ============================================================================
// UserId Constructors and Accessors
// ============================================================================

pub fn user_id(value: String) -> UserId {
  UserId(value)
}

pub fn user_id_validated(value: String) -> Result(UserId, String) {
  let trimmed = string.trim(value)
  case string.length(trimmed) {
    0 -> Error("User ID cannot be empty")
    _ -> Ok(UserId(trimmed))
  }
}

pub fn user_id_to_string(id: UserId) -> String {
  id.value
}

// ============================================================================
// CustomFoodId Constructors and Accessors
// ============================================================================

pub fn custom_food_id(value: String) -> CustomFoodId {
  CustomFoodId(value)
}

pub fn custom_food_id_validated(value: String) -> Result(CustomFoodId, String) {
  let trimmed = string.trim(value)
  case string.length(trimmed) {
    0 -> Error("Custom Food ID cannot be empty")
    _ -> Ok(CustomFoodId(trimmed))
  }
}

pub fn custom_food_id_to_string(id: CustomFoodId) -> String {
  id.value
}

// ============================================================================
// LogEntryId Constructors and Accessors
// ============================================================================

pub fn log_entry_id(value: String) -> LogEntryId {
  LogEntryId(value)
}

pub fn log_entry_id_validated(value: String) -> Result(LogEntryId, String) {
  let trimmed = string.trim(value)
  case string.length(trimmed) {
    0 -> Error("Log Entry ID cannot be empty")
    _ -> Ok(LogEntryId(trimmed))
  }
}

pub fn log_entry_id_to_string(id: LogEntryId) -> String {
  id.value
}

// ============================================================================
// JobId Constructors and Accessors
// ============================================================================

pub fn job_id(value: String) -> JobId {
  JobId(value)
}

pub fn job_id_validated(value: String) -> Result(JobId, String) {
  let trimmed = string.trim(value)
  case string.length(trimmed) {
    0 -> Error("Job ID cannot be empty")
    _ -> Ok(JobId(trimmed))
  }
}

pub fn job_id_to_string(id: JobId) -> String {
  id.value
}

// ============================================================================
// JSON Encoding
// ============================================================================

pub fn fdc_id_to_json(id: FdcId) -> Json {
  json.int(id.value)
}

pub fn recipe_id_to_json(id: RecipeId) -> Json {
  json.string(id.value)
}

pub fn user_id_to_json(id: UserId) -> Json {
  json.string(id.value)
}

pub fn custom_food_id_to_json(id: CustomFoodId) -> Json {
  json.string(id.value)
}

pub fn log_entry_id_to_json(id: LogEntryId) -> Json {
  json.string(id.value)
}

pub fn job_id_to_json(id: JobId) -> Json {
  json.string(id.value)
}

// ============================================================================
// JSON Decoding
// ============================================================================

pub fn fdc_id_decoder() -> Decoder(FdcId) {
  use value <- decode.then(decode.int)
  case value > 0 {
    True -> decode.success(FdcId(value))
    False ->
      decode.failure(
        FdcId(0),
        "FdcId must be positive, got: " <> int.to_string(value),
      )
  }
}

pub fn recipe_id_decoder() -> Decoder(RecipeId) {
  use value <- decode.then(decode.string)
  case recipe_id_validated(value) {
    Ok(id) -> decode.success(id)
    Error(msg) -> decode.failure(RecipeId(""), msg)
  }
}

pub fn user_id_decoder() -> Decoder(UserId) {
  use value <- decode.then(decode.string)
  case user_id_validated(value) {
    Ok(id) -> decode.success(id)
    Error(msg) -> decode.failure(UserId(""), msg)
  }
}

pub fn custom_food_id_decoder() -> Decoder(CustomFoodId) {
  use value <- decode.then(decode.string)
  case custom_food_id_validated(value) {
    Ok(id) -> decode.success(id)
    Error(msg) -> decode.failure(CustomFoodId(""), msg)
  }
}

pub fn log_entry_id_decoder() -> Decoder(LogEntryId) {
  use value <- decode.then(decode.string)
  case log_entry_id_validated(value) {
    Ok(id) -> decode.success(id)
    Error(msg) -> decode.failure(LogEntryId(""), msg)
  }
}

pub fn job_id_decoder() -> Decoder(JobId) {
  use value <- decode.then(decode.string)
  case job_id_validated(value) {
    Ok(id) -> decode.success(id)
    Error(msg) -> decode.failure(JobId(""), msg)
  }
}

// ============================================================================
// Equality
// ============================================================================

pub fn fdc_id_equal(a: FdcId, b: FdcId) -> Bool {
  a.value == b.value
}

pub fn recipe_id_equal(a: RecipeId, b: RecipeId) -> Bool {
  a.value == b.value
}

pub fn user_id_equal(a: UserId, b: UserId) -> Bool {
  a.value == b.value
}

pub fn custom_food_id_equal(a: CustomFoodId, b: CustomFoodId) -> Bool {
  a.value == b.value
}

pub fn log_entry_id_equal(a: LogEntryId, b: LogEntryId) -> Bool {
  a.value == b.value
}

pub fn job_id_equal(a: JobId, b: JobId) -> Bool {
  a.value == b.value
}
