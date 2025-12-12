/// Recipe Mappings Log Storage - Audit logging for recipe migrations

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

pub type MappingStatus {
  Active
  Deprecated
  Error
}

pub fn status_to_string(status: MappingStatus) -> String {
  case status {
    Active -> "active"
    Deprecated -> "deprecated"
    Error -> "error"
  }
}

pub fn status_from_string(s: String) -> MappingStatus {
  case string.lowercase(s) {
    "deprecated" -> Deprecated
    "error" -> Error
    _ -> Active
  }
}

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

pub type RecipeMappingRequest {
  RecipeMappingRequest(
    mealie_slug: String,
    tandoor_id: Int,
    mealie_name: String,
    tandoor_name: String,
    notes: Option(String),
  )
}

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
pub fn log_mapping(
  db: pog.Connection,
  request: RecipeMappingRequest,
) -> Result(Int, RecipeMappingError) {
  let sql =
    "INSERT INTO recipe_mappings (mealie_slug, tandoor_id, mealie_name, tandoor_name, notes, status)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING mapping_id"

  case
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
  {
    Error(e) -> {
      let error_msg = utils.format_pog_error(e)
      let is_duplicate = string.contains(error_msg, "duplicate") || string.contains(error_msg, "unique")
      case is_duplicate {
        True -> Error(DuplicateMapping)
        False -> Error(DatabaseError(error_msg))
      }
    }
    Ok(pog.Returned(_, rows)) ->
      case rows {
        [first, ..] -> Ok(first)
        _ -> Error(DatabaseError("Failed to retrieve mapping_id"))
      }
  }
}

/// Log multiple recipe mappings in batch
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

      case query_builder |> pog.execute(db) {
        Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
        Ok(_) -> Ok(list.length(requests))
      }
    }
  }
}

/// Export all active recipe mappings for audit purposes
pub fn export_mappings_for_audit(
  db: pog.Connection,
) -> Result(List(RecipeMapping), RecipeMappingError) {
  get_all_mappings(db, Active)
}

// ============================================================================
// Query Functions
// ============================================================================

/// Get a mapping by Mealie slug
pub fn get_mapping_by_mealie_slug(
  db: pog.Connection,
  mealie_slug: String,
) -> Result(RecipeMapping, RecipeMappingError) {
  let sql =
    "SELECT mapping_id, mealie_slug, tandoor_id, mealie_name, tandoor_name, mapped_at, notes, status
     FROM recipe_mappings
     WHERE mealie_slug = $1"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(mealie_slug))
    |> pog.returning(mapping_decoder())
    |> pog.execute(db)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, rows)) ->
      case rows {
        [first, ..] -> Ok(first)
        [] -> Error(NotFound)
      }
  }
}

/// Get a mapping by Tandoor ID
pub fn get_mapping_by_tandoor_id(
  db: pog.Connection,
  tandoor_id: Int,
) -> Result(RecipeMapping, RecipeMappingError) {
  let sql =
    "SELECT mapping_id, mealie_slug, tandoor_id, mealie_name, tandoor_name, mapped_at, notes, status
     FROM recipe_mappings
     WHERE tandoor_id = $1
     LIMIT 1"

  case
    pog.query(sql)
    |> pog.parameter(pog.int(tandoor_id))
    |> pog.returning(mapping_decoder())
    |> pog.execute(db)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, rows)) ->
      case rows {
        [first, ..] -> Ok(first)
        [] -> Error(NotFound)
      }
  }
}

/// Get all mappings with a specific status
pub fn get_all_mappings(
  db: pog.Connection,
  status: MappingStatus,
) -> Result(List(RecipeMapping), RecipeMappingError) {
  let sql =
    "SELECT mapping_id, mealie_slug, tandoor_id, mealie_name, tandoor_name, mapped_at, notes, status
     FROM recipe_mappings
     WHERE status = $1
     ORDER BY mapped_at DESC"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(status_to_string(status)))
    |> pog.returning(mapping_decoder())
    |> pog.execute(db)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

/// Get recent mappings (within the last N records)
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

  case
    pog.query(sql)
    |> pog.parameter(pog.int(limit))
    |> pog.returning(mapping_decoder())
    |> pog.execute(db)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, rows)) -> Ok(rows)
  }
}

/// Count total mappings by status
pub fn count_mappings_by_status(
  db: pog.Connection,
  status: MappingStatus,
) -> Result(Int, RecipeMappingError) {
  let decoder = {
    use count <- decode.field(0, decode.int)
    decode.success(count)
  }

  case
    pog.query("SELECT COUNT(*)::int FROM recipe_mappings WHERE status = $1")
    |> pog.parameter(pog.text(status_to_string(status)))
    |> pog.returning(decoder)
    |> pog.execute(db)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, [count, ..])) -> Ok(count)
    Ok(pog.Returned(_, [])) -> Ok(0)
  }
}

/// Get total number of all mappings
pub fn count_total_mappings(db: pog.Connection) -> Result(Int, RecipeMappingError) {
  let decoder = {
    use count <- decode.field(0, decode.int)
    decode.success(count)
  }

  case
    pog.query("SELECT COUNT(*)::int FROM recipe_mappings")
    |> pog.returning(decoder)
    |> pog.execute(db)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, [count, ..])) -> Ok(count)
    Ok(pog.Returned(_, [])) -> Ok(0)
  }
}

// ============================================================================
// Update Functions
// ============================================================================

/// Mark a mapping as deprecated
pub fn deprecate_mapping(
  db: pog.Connection,
  mealie_slug: String,
) -> Result(Nil, RecipeMappingError) {
  case
    pog.query("UPDATE recipe_mappings SET status = 'deprecated' WHERE mealie_slug = $1")
    |> pog.parameter(pog.text(mealie_slug))
    |> pog.execute(db)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

/// Mark a mapping as error with notes
pub fn mark_mapping_error(
  db: pog.Connection,
  mealie_slug: String,
  error_notes: String,
) -> Result(Nil, RecipeMappingError) {
  case
    pog.query("UPDATE recipe_mappings SET status = 'error', notes = $2 WHERE mealie_slug = $1")
    |> pog.parameter(pog.text(mealie_slug))
    |> pog.parameter(pog.text(error_notes))
    |> pog.execute(db)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

/// Update notes for a mapping
pub fn update_mapping_notes(
  db: pog.Connection,
  mealie_slug: String,
  notes: String,
) -> Result(Nil, RecipeMappingError) {
  case
    pog.query("UPDATE recipe_mappings SET notes = $2 WHERE mealie_slug = $1")
    |> pog.parameter(pog.text(mealie_slug))
    |> pog.parameter(pog.text(notes))
    |> pog.execute(db)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

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
