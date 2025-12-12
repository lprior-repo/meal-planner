/// Recipe Mappings Log Storage
///
/// This module provides functions to log and query recipe mappings between Mealie
/// and Tandoor recipe systems. This is essential for the audit trail and enables
/// reconciliation between the two systems.
///
/// The recipe_mappings table tracks:
/// - Mealie recipe slug (unique source identifier)
/// - Tandoor recipe ID (numeric destination identifier)
/// - Recipe names from both systems
/// - Timestamp of mapping creation
/// - Status and optional notes for debugging
///
/// Usage:
/// - Log each recipe mapping as it's created during migration
/// - Query mappings for reconciliation and debugging
/// - Mark mappings as deprecated when recipes are removed

import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/storage/utils
import pog

// ============================================================================
// Types
// ============================================================================

/// Status of a recipe mapping
pub type MappingStatus {
  Active
  Deprecated
  Error
}

/// Convert mapping status to string representation
pub fn status_to_string(status: MappingStatus) -> String {
  case status {
    Active -> "active"
    Deprecated -> "deprecated"
    Error -> "error"
  }
}

/// Parse mapping status from string
pub fn status_from_string(s: String) -> MappingStatus {
  case string.lowercase(s) {
    "deprecated" -> Deprecated
    "error" -> Error
    _ -> Active
  }
}

/// A single recipe mapping record
pub type RecipeMapping {
  RecipeMapping(
    mapping_id: Int,
    mealie_slug: String,
    tandoor_id: Int,
    mealie_name: String,
    tandoor_name: String,
    mapped_at: String,
    notes: Option(String),
    status: MappingStatus,
  )
}

/// Request to log a new recipe mapping
pub type RecipeMappingRequest {
  RecipeMappingRequest(
    mealie_slug: String,
    tandoor_id: Int,
    mealie_name: String,
    tandoor_name: String,
    notes: Option(String),
  )
}

/// Error type for recipe mapping operations
pub type RecipeMappingError {
  DatabaseError(String)
  NotFound
  DuplicateMapping
  InvalidData(String)
}

// ============================================================================
// Logging Functions
// ============================================================================

/// Save a new recipe mapping to the audit log
///
/// This function inserts a new mapping record and returns the mapping ID.
/// If a mapping with the same Mealie slug already exists, it returns a
/// DuplicateMapping error.
///
/// Arguments:
/// - db: Database connection
/// - request: Mapping data to save
///
/// Returns:
/// - Ok(mapping_id): The ID of the newly created mapping
/// - Error: Database error or validation error
pub fn log_mapping(
  db: pog.Connection,
  request: RecipeMappingRequest,
) -> Result(Int, RecipeMappingError) {
  let sql =
    "INSERT INTO recipe_mappings (mealie_slug, tandoor_id, mealie_name, tandoor_name, notes, status)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING mapping_id"

  pog.query(sql)
  |> pog.parameter(pog.text(request.mealie_slug))
  |> pog.parameter(pog.int(request.tandoor_id))
  |> pog.parameter(pog.text(request.mealie_name))
  |> pog.parameter(pog.text(request.tandoor_name))
  |> pog.parameter(case request.notes {
    Some(n) -> pog.text(n)
    None -> pog.null()
  })
  |> pog.parameter(pog.text("active"))
  |> pog.returning(fn(row) {
    use mapping_id <- result.try(
      pog.col_int(row, 0)
      |> result.map_error(fn(_) { "Failed to parse mapping_id" }),
    )
    Ok(mapping_id)
  })
  |> pog.execute(db)
  |> result.map_error(fn(err) {
    let error_msg = utils.format_pog_error(err)
    let is_duplicate = string.contains(error_msg, "duplicate") || string.contains(error_msg, "unique")
    case is_duplicate {
      True -> DuplicateMapping
      False -> DatabaseError(error_msg)
    }
  })
  |> result.try(fn(result_rows) {
    case result_rows {
      pog.Returned(_, [first, ..]) -> Ok(first)
      _ -> Error(DatabaseError("Failed to retrieve mapping_id"))
    }
  })
}

/// Log multiple recipe mappings in batch
///
/// This is more efficient than calling log_mapping multiple times.
/// Returns the number of successfully mapped recipes.
///
/// Arguments:
/// - db: Database connection
/// - requests: List of mapping requests
///
/// Returns:
/// - Ok(count): Number of successfully logged mappings
/// - Error: If any database error occurs
pub fn log_batch_mappings(
  db: pog.Connection,
  requests: List(RecipeMappingRequest),
) -> Result(Int, RecipeMappingError) {
  case list.length(requests) {
    0 -> Ok(0)
    _ -> {
      let sql_values =
        requests
        |> list.index_map(fn(req, idx) {
          let line = idx + 1
          "($"
          <> int.to_string(line * 5 - 4)
          <> ", $"
          <> int.to_string(line * 5 - 3)
          <> ", $"
          <> int.to_string(line * 5 - 2)
          <> ", $"
          <> int.to_string(line * 5 - 1)
          <> ", $"
          <> int.to_string(line * 5)
          <> ")"
        })
        |> string.join(", ")

      let sql =
        "INSERT INTO recipe_mappings (mealie_slug, tandoor_id, mealie_name, tandoor_name, notes)
       VALUES "
        <> sql_values
        <> " ON CONFLICT (mealie_slug) DO NOTHING"

      let query_builder =
        list.fold(
          requests,
          pog.query(sql),
          fn(acc, req) {
            acc
            |> pog.parameter(pog.text(req.mealie_slug))
            |> pog.parameter(pog.int(req.tandoor_id))
            |> pog.parameter(pog.text(req.mealie_name))
            |> pog.parameter(pog.text(req.tandoor_name))
            |> pog.parameter(case req.notes {
              Some(n) -> pog.text(n)
              None -> pog.null()
            })
          },
        )

      query_builder
      |> pog.execute(db)
      |> result.map_error(fn(err) { DatabaseError(utils.format_pog_error(err)) })
      |> result.map(fn(_) { list.length(requests) })
    }
  }
}

/// Export all active recipe mappings for audit purposes
///
/// This retrieves all active mappings from the database. The mappings can be
/// used for external audit and reconciliation.
///
/// Arguments:
/// - db: Database connection
///
/// Returns:
/// - Ok(mappings): List of all active recipe mappings
/// - Error: If database query fails
pub fn export_mappings_for_audit(
  db: pog.Connection,
) -> Result(List(RecipeMapping), RecipeMappingError) {
  get_all_mappings(db, Active)
}

// ============================================================================
// Query Functions
// ============================================================================

/// Get a mapping by Mealie slug
///
/// This is the primary lookup method, as Mealie slugs are unique identifiers.
pub fn get_mapping_by_mealie_slug(
  db: pog.Connection,
  mealie_slug: String,
) -> Result(RecipeMapping, RecipeMappingError) {
  let sql =
    "SELECT mapping_id, mealie_slug, tandoor_id, mealie_name, tandoor_name, mapped_at, notes, status
     FROM recipe_mappings
     WHERE mealie_slug = $1"

  pog.query(sql)
  |> pog.parameter(pog.text(mealie_slug))
  |> pog.returning(mapping_decoder())
  |> pog.execute(db)
  |> result.map_error(fn(err) { DatabaseError(utils.format_pog_error(err)) })
  |> result.try(fn(result) {
    case result {
      pog.Returned(_, [first, ..]) -> Ok(first)
      pog.Returned(_, []) -> Error(NotFound)
    }
  })
}

/// Get a mapping by Tandoor ID
///
/// Useful for finding which Mealie recipe created a given Tandoor recipe.
pub fn get_mapping_by_tandoor_id(
  db: pog.Connection,
  tandoor_id: Int,
) -> Result(RecipeMapping, RecipeMappingError) {
  let sql =
    "SELECT mapping_id, mealie_slug, tandoor_id, mealie_name, tandoor_name, mapped_at, notes, status
     FROM recipe_mappings
     WHERE tandoor_id = $1
     LIMIT 1"

  pog.query(sql)
  |> pog.parameter(pog.int(tandoor_id))
  |> pog.returning(mapping_decoder())
  |> pog.execute(db)
  |> result.map_error(fn(err) { DatabaseError(utils.format_pog_error(err)) })
  |> result.try(fn(result) {
    case result {
      pog.Returned(_, rows) -> {
        case rows {
          [first, ..] -> Ok(first)
          [] -> Error(NotFound)
        }
      }
    }
  })
}

/// Get all mappings with a specific status
///
/// Returns all mappings matching the given status (active, deprecated, error).
pub fn get_all_mappings(
  db: pog.Connection,
  status: MappingStatus,
) -> Result(List(RecipeMapping), RecipeMappingError) {
  let sql =
    "SELECT mapping_id, mealie_slug, tandoor_id, mealie_name, tandoor_name, mapped_at, notes, status
     FROM recipe_mappings
     WHERE status = $1
     ORDER BY mapped_at DESC"

  pog.query(sql)
  |> pog.parameter(pog.text(status_to_string(status)))
  |> pog.returning(mapping_decoder())
  |> pog.execute(db)
  |> result.map_error(fn(err) { DatabaseError(utils.format_pog_error(err)) })
  |> result.map(fn(result) { case result { pog.Returned(_, rows) } { rows })
}

/// Get recent mappings (within the last N records)
///
/// Useful for quick audits of recent migrations.
pub fn get_recent_mappings(
  db: pog.Connection,
  limit: Int,
) -> Result(List(RecipeMapping), RecipeMappingError) {
  let sql =
    "SELECT mapping_id, mealie_slug, tandoor_id, mealie_name, tandoor_name, mapped_at, notes, status
     FROM recipe_mappings
     WHERE status = 'active'
     ORDER BY mapped_at DESC
     LIMIT $1"

  pog.query(sql)
  |> pog.parameter(pog.int(limit))
  |> pog.returning(mapping_decoder())
  |> pog.execute(db)
  |> result.map_error(fn(err) { DatabaseError(utils.format_pog_error(err)) })
  |> result.map(fn(result) { case result { pog.Returned(_, rows) } { rows })
}

/// Count total mappings by status
///
/// Returns the number of mappings with the given status.
pub fn count_mappings_by_status(
  db: pog.Connection,
  status: MappingStatus,
) -> Result(Int, RecipeMappingError) {
  let sql =
    "SELECT COUNT(*)::int FROM recipe_mappings WHERE status = $1"

  let decoder = {
    use count <- decode.field(0, decode.int)
    decode.success(count)
  }

  pog.query(sql)
  |> pog.parameter(pog.text(status_to_string(status)))
  |> pog.returning(decoder)
  |> pog.execute(db)
  |> result.map_error(fn(err) { DatabaseError(utils.format_pog_error(err)) })
  |> result.try(fn(pog.Returned(_, rows)) {
    case rows {
      [count, ..] -> Ok(count)
      _ -> Ok(0)
    }
  })
}

/// Get total number of all mappings
pub fn count_total_mappings(db: pog.Connection) -> Result(Int, RecipeMappingError) {
  let sql = "SELECT COUNT(*)::int FROM recipe_mappings"

  let decoder = {
    use count <- decode.field(0, decode.int)
    decode.success(count)
  }

  pog.query(sql)
  |> pog.returning(decoder)
  |> pog.execute(db)
  |> result.map_error(fn(err) { DatabaseError(utils.format_pog_error(err)) })
  |> result.try(fn(pog.Returned(_, rows)) {
    case rows {
      [count, ..] -> Ok(count)
      _ -> Ok(0)
    }
  })
}

// ============================================================================
// Update Functions
// ============================================================================

/// Mark a mapping as deprecated
///
/// This is used when a recipe is removed or superseded in Tandoor.
pub fn deprecate_mapping(
  db: pog.Connection,
  mealie_slug: String,
) -> Result(Nil, RecipeMappingError) {
  let sql =
    "UPDATE recipe_mappings
     SET status = 'deprecated'
     WHERE mealie_slug = $1"

  pog.query(sql)
  |> pog.parameter(pog.text(mealie_slug))
  |> pog.execute(db)
  |> result.map_error(fn(err) { DatabaseError(utils.format_pog_error(err)) })
  |> result.map(fn(_) { Nil })
}

/// Mark a mapping as error
///
/// This is used when there's an issue with the mapping.
pub fn mark_mapping_error(
  db: pog.Connection,
  mealie_slug: String,
  error_notes: String,
) -> Result(Nil, RecipeMappingError) {
  let sql =
    "UPDATE recipe_mappings
     SET status = 'error', notes = $2
     WHERE mealie_slug = $1"

  pog.query(sql)
  |> pog.parameter(pog.text(mealie_slug))
  |> pog.parameter(pog.text(error_notes))
  |> pog.execute(db)
  |> result.map_error(fn(err) { DatabaseError(utils.format_pog_error(err)) })
  |> result.map(fn(_) { Nil })
}

/// Update notes for a mapping
pub fn update_mapping_notes(
  db: pog.Connection,
  mealie_slug: String,
  notes: String,
) -> Result(Nil, RecipeMappingError) {
  let sql =
    "UPDATE recipe_mappings
     SET notes = $2
     WHERE mealie_slug = $1"

  pog.query(sql)
  |> pog.parameter(pog.text(mealie_slug))
  |> pog.parameter(pog.text(notes))
  |> pog.execute(db)
  |> result.map_error(fn(err) { DatabaseError(utils.format_pog_error(err)) })
  |> result.map(fn(_) { Nil })
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Decoder for converting database rows to RecipeMapping records
fn mapping_decoder() -> decode.Decoder(RecipeMapping) {
  use mapping_id <- decode.field(0, decode.int)
  use mealie_slug <- decode.field(1, decode.string)
  use tandoor_id <- decode.field(2, decode.int)
  use mealie_name <- decode.field(3, decode.string)
  use tandoor_name <- decode.field(4, decode.string)
  use mapped_at <- decode.field(5, decode.string)
  use notes <- decode.field(6, decode.optional(decode.string))
  use status_str <- decode.field(7, decode.string)

  decode.success(RecipeMapping(
    mapping_id: mapping_id,
    mealie_slug: mealie_slug,
    tandoor_id: tandoor_id,
    mealie_name: mealie_name,
    tandoor_name: tandoor_name,
    mapped_at: mapped_at,
    notes: notes,
    status: status_from_string(status_str),
  ))
}

/// Format a mapping as JSON for audit export
pub fn format_mapping_as_json(mapping: RecipeMapping) -> String {
  let notes_str = case mapping.notes {
    Some(n) -> "\"" <> string.replace(n, "\"", "\\\"") <> "\""
    None -> "null"
  }

  "      {\n"
  <> "        \"mapping_id\": "
  <> int.to_string(mapping.mapping_id)
  <> ",\n"
  <> "        \"mealie_slug\": \""
  <> string.replace(mapping.mealie_slug, "\"", "\\\"")
  <> "\",\n"
  <> "        \"tandoor_id\": "
  <> int.to_string(mapping.tandoor_id)
  <> ",\n"
  <> "        \"mealie_name\": \""
  <> string.replace(mapping.mealie_name, "\"", "\\\"")
  <> "\",\n"
  <> "        \"tandoor_name\": \""
  <> string.replace(mapping.tandoor_name, "\"", "\\\"")
  <> "\",\n"
  <> "        \"mapped_at\": \""
  <> mapping.mapped_at
  <> "\",\n"
  <> "        \"status\": \""
  <> status_to_string(mapping.status)
  <> "\",\n"
  <> "        \"notes\": "
  <> notes_str
  <> "\n"
  <> "      }"
}

/// Format mapping for logging/display
pub fn format_mapping_for_display(mapping: RecipeMapping) -> String {
  "RecipeMapping { "
  <> "mealie_slug: "
  <> mapping.mealie_slug
  <> ", tandoor_id: "
  <> int.to_string(mapping.tandoor_id)
  <> ", mealie_name: "
  <> mapping.mealie_name
  <> ", tandoor_name: "
  <> mapping.tandoor_name
  <> ", status: "
  <> status_to_string(mapping.status)
  <> " }"
}
