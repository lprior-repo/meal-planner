/// Audit logging storage for recipe_sources table
/// Provides functions to query audit trail and set audit context
import gleam/dynamic/decode
import gleam/int
import gleam/option.{type Option, None, Some}
import meal_planner/storage/utils
import pog

// ============================================================================
// Audit Types
// ============================================================================

/// Type of audit operation
pub type AuditOperation {
  Insert
  Update
  Delete
}

/// Convert operation type to string
pub fn operation_to_string(op: AuditOperation) -> String {
  case op {
    Insert -> "INSERT"
    Update -> "UPDATE"
    Delete -> "DELETE"
  }
}

/// Parse operation from string
pub fn operation_from_string(s: String) -> AuditOperation {
  case s {
    "INSERT" -> Insert
    "UPDATE" -> Update
    "DELETE" -> Delete
    _ -> Update
  }
}

/// A single audit log entry for recipe_sources
pub type RecipeSourceAuditEntry {
  RecipeSourceAuditEntry(
    audit_id: Int,
    operation: AuditOperation,
    operation_time: String,
    record_id: Int,
    old_name: Option(String),
    new_name: Option(String),
    old_type: Option(String),
    new_type: Option(String),
    old_enabled: Option(Bool),
    new_enabled: Option(Bool),
    changed_by: Option(String),
    change_reason: Option(String),
  )
}

/// Summary of changes for an audit entry
pub type AuditChangeSummary {
  AuditChangeSummary(
    audit_id: Int,
    operation: AuditOperation,
    operation_time: String,
    record_id: Int,
    record_name: String,
    name_changed: Bool,
    type_changed: Bool,
    enabled_changed: Bool,
    changed_by: Option(String),
    change_reason: Option(String),
  )
}

/// Error type for audit operations
pub type AuditError {
  DatabaseError(String)
  NotFound
}

// ============================================================================
// Audit Context
// ============================================================================

/// Set the audit context for subsequent operations on recipe_sources
/// This sets PostgreSQL session variables that the audit triggers will capture
pub fn set_audit_context(
  conn: pog.Connection,
  changed_by: String,
  change_reason: String,
) -> Result(Nil, AuditError) {
  // Set session variables that will be captured by audit triggers
  // We need to run two SET commands
  let set_user_sql = "SELECT set_config('audit.changed_by', $1, true)"

  let set_reason_sql = "SELECT set_config('audit.change_reason', $1, true)"

  case
    pog.query(set_user_sql)
    |> pog.parameter(pog.text(changed_by))
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(_) -> {
      case
        pog.query(set_reason_sql)
        |> pog.parameter(pog.text(change_reason))
        |> pog.execute(conn)
      {
        Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
        Ok(_) -> Ok(Nil)
      }
    }
  }
}

/// Clear the audit context after operations are complete
pub fn clear_audit_context(conn: pog.Connection) -> Result(Nil, AuditError) {
  let sql =
    "SELECT set_config('audit.changed_by', '', true),
            set_config('audit.change_reason', '', true)"

  case pog.query(sql) |> pog.execute(conn) {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(_) -> Ok(Nil)
  }
}

// ============================================================================
// Query Functions
// ============================================================================

/// Get audit history for a specific recipe_source record
pub fn get_audit_history(
  conn: pog.Connection,
  record_id: Int,
) -> Result(List(RecipeSourceAuditEntry), AuditError) {
  let sql =
    "SELECT audit_id, operation, operation_time::text, record_id,
            old_name, new_name, old_type, new_type,
            old_enabled, new_enabled, changed_by, change_reason
     FROM recipe_sources_audit
     WHERE record_id = $1
     ORDER BY operation_time DESC"

  case
    pog.query(sql)
    |> pog.parameter(pog.int(record_id))
    |> pog.returning(audit_entry_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, entries)) -> Ok(entries)
  }
}

/// Get recent audit entries across all records
pub fn get_recent_audit_entries(
  conn: pog.Connection,
  limit: Int,
) -> Result(List(RecipeSourceAuditEntry), AuditError) {
  let sql =
    "SELECT audit_id, operation, operation_time::text, record_id,
            old_name, new_name, old_type, new_type,
            old_enabled, new_enabled, changed_by, change_reason
     FROM recipe_sources_audit
     ORDER BY operation_time DESC
     LIMIT $1"

  case
    pog.query(sql)
    |> pog.parameter(pog.int(limit))
    |> pog.returning(audit_entry_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, entries)) -> Ok(entries)
  }
}

/// Get audit entries filtered by operation type
pub fn get_audit_by_operation(
  conn: pog.Connection,
  operation: AuditOperation,
  limit: Int,
) -> Result(List(RecipeSourceAuditEntry), AuditError) {
  let sql =
    "SELECT audit_id, operation, operation_time::text, record_id,
            old_name, new_name, old_type, new_type,
            old_enabled, new_enabled, changed_by, change_reason
     FROM recipe_sources_audit
     WHERE operation = $1
     ORDER BY operation_time DESC
     LIMIT $2"

  case
    pog.query(sql)
    |> pog.parameter(pog.text(operation_to_string(operation)))
    |> pog.parameter(pog.int(limit))
    |> pog.returning(audit_entry_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, entries)) -> Ok(entries)
  }
}

/// Get summarized change view for easier display
pub fn get_audit_changes_summary(
  conn: pog.Connection,
  limit: Int,
) -> Result(List(AuditChangeSummary), AuditError) {
  let sql =
    "SELECT audit_id, operation, operation_time::text, record_id, record_name,
            name_change IS NOT NULL as name_changed,
            type_change IS NOT NULL as type_changed,
            enabled_change IS NOT NULL as enabled_changed,
            changed_by, change_reason
     FROM recipe_sources_audit_changes
     LIMIT $1"

  case
    pog.query(sql)
    |> pog.parameter(pog.int(limit))
    |> pog.returning(audit_summary_decoder())
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, summaries)) -> Ok(summaries)
  }
}

/// Count total audit entries for a record
pub fn count_audit_entries(
  conn: pog.Connection,
  record_id: Int,
) -> Result(Int, AuditError) {
  let sql =
    "SELECT COUNT(*)::int FROM recipe_sources_audit WHERE record_id = $1"

  let decoder = {
    use count <- decode.field(0, decode.int)
    decode.success(count)
  }

  case
    pog.query(sql)
    |> pog.parameter(pog.int(record_id))
    |> pog.returning(decoder)
    |> pog.execute(conn)
  {
    Error(e) -> Error(DatabaseError(utils.format_pog_error(e)))
    Ok(pog.Returned(_, [count, ..])) -> Ok(count)
    Ok(pog.Returned(_, [])) -> Ok(0)
  }
}

// ============================================================================
// Decoders
// ============================================================================

fn audit_entry_decoder() -> decode.Decoder(RecipeSourceAuditEntry) {
  use audit_id <- decode.field(0, decode.int)
  use operation_str <- decode.field(1, decode.string)
  use operation_time <- decode.field(2, decode.string)
  use record_id <- decode.field(3, decode.int)
  use old_name <- decode.field(4, decode.optional(decode.string))
  use new_name <- decode.field(5, decode.optional(decode.string))
  use old_type <- decode.field(6, decode.optional(decode.string))
  use new_type <- decode.field(7, decode.optional(decode.string))
  use old_enabled <- decode.field(8, decode.optional(decode.bool))
  use new_enabled <- decode.field(9, decode.optional(decode.bool))
  use changed_by <- decode.field(10, decode.optional(decode.string))
  use change_reason <- decode.field(11, decode.optional(decode.string))

  decode.success(RecipeSourceAuditEntry(
    audit_id: audit_id,
    operation: operation_from_string(operation_str),
    operation_time: operation_time,
    record_id: record_id,
    old_name: old_name,
    new_name: new_name,
    old_type: old_type,
    new_type: new_type,
    old_enabled: old_enabled,
    new_enabled: new_enabled,
    changed_by: changed_by,
    change_reason: change_reason,
  ))
}

fn audit_summary_decoder() -> decode.Decoder(AuditChangeSummary) {
  use audit_id <- decode.field(0, decode.int)
  use operation_str <- decode.field(1, decode.string)
  use operation_time <- decode.field(2, decode.string)
  use record_id <- decode.field(3, decode.int)
  use record_name <- decode.field(4, decode.string)
  use name_changed <- decode.field(5, decode.bool)
  use type_changed <- decode.field(6, decode.bool)
  use enabled_changed <- decode.field(7, decode.bool)
  use changed_by <- decode.field(8, decode.optional(decode.string))
  use change_reason <- decode.field(9, decode.optional(decode.string))

  decode.success(AuditChangeSummary(
    audit_id: audit_id,
    operation: operation_from_string(operation_str),
    operation_time: operation_time,
    record_id: record_id,
    record_name: record_name,
    name_changed: name_changed,
    type_changed: type_changed,
    enabled_changed: enabled_changed,
    changed_by: changed_by,
    change_reason: change_reason,
  ))
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Get the effective name from an audit entry (new_name for INSERT/UPDATE, old_name for DELETE)
pub fn get_effective_name(entry: RecipeSourceAuditEntry) -> Option(String) {
  case entry.operation {
    Insert -> entry.new_name
    Update -> entry.new_name
    Delete -> entry.old_name
  }
}

/// Format audit entry for display
pub fn format_audit_entry(entry: RecipeSourceAuditEntry) -> String {
  let op = operation_to_string(entry.operation)
  let name = case get_effective_name(entry) {
    Some(n) -> n
    None -> "unknown"
  }
  let by = case entry.changed_by {
    Some(user) -> " by " <> user
    None -> ""
  }
  let reason = case entry.change_reason {
    Some(r) -> " (" <> r <> ")"
    None -> ""
  }

  "["
  <> entry.operation_time
  <> "] "
  <> op
  <> " "
  <> name
  <> " (id: "
  <> int.to_string(entry.record_id)
  <> ")"
  <> by
  <> reason
}
