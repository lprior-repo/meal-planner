/// Tests for audit logging storage module
/// Unit tests for helper functions and type conversions
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/storage/audit.{
  type AuditChangeSummary, type RecipeSourceAuditEntry, AuditChangeSummary,
  Delete, Insert, RecipeSourceAuditEntry, Update,
}

// ===================================================================
// OPERATION TYPE TESTS
// ===================================================================

pub fn operation_to_string_insert_test() {
  audit.operation_to_string(Insert)
  |> should.equal("INSERT")
}

pub fn operation_to_string_update_test() {
  audit.operation_to_string(Update)
  |> should.equal("UPDATE")
}

pub fn operation_to_string_delete_test() {
  audit.operation_to_string(Delete)
  |> should.equal("DELETE")
}

pub fn operation_from_string_insert_test() {
  audit.operation_from_string("INSERT")
  |> should.equal(Insert)
}

pub fn operation_from_string_update_test() {
  audit.operation_from_string("UPDATE")
  |> should.equal(Update)
}

pub fn operation_from_string_delete_test() {
  audit.operation_from_string("DELETE")
  |> should.equal(Delete)
}

pub fn operation_from_string_unknown_defaults_to_update_test() {
  // Unknown operations default to Update
  audit.operation_from_string("UNKNOWN")
  |> should.equal(Update)
}

pub fn operation_roundtrip_insert_test() {
  Insert
  |> audit.operation_to_string
  |> audit.operation_from_string
  |> should.equal(Insert)
}

pub fn operation_roundtrip_update_test() {
  Update
  |> audit.operation_to_string
  |> audit.operation_from_string
  |> should.equal(Update)
}

pub fn operation_roundtrip_delete_test() {
  Delete
  |> audit.operation_to_string
  |> audit.operation_from_string
  |> should.equal(Delete)
}

// ===================================================================
// GET EFFECTIVE NAME TESTS
// ===================================================================

fn make_entry(
  operation: audit.AuditOperation,
  old_name: option.Option(String),
  new_name: option.Option(String),
) -> RecipeSourceAuditEntry {
  RecipeSourceAuditEntry(
    audit_id: 1,
    operation: operation,
    operation_time: "2024-01-01T00:00:00Z",
    record_id: 100,
    old_name: old_name,
    new_name: new_name,
    old_type: None,
    new_type: None,
    old_enabled: None,
    new_enabled: None,
    changed_by: None,
    change_reason: None,
  )
}

pub fn get_effective_name_insert_returns_new_name_test() {
  let entry = make_entry(Insert, None, Some("New Source"))

  audit.get_effective_name(entry)
  |> should.equal(Some("New Source"))
}

pub fn get_effective_name_update_returns_new_name_test() {
  let entry = make_entry(Update, Some("Old Source"), Some("Updated Source"))

  audit.get_effective_name(entry)
  |> should.equal(Some("Updated Source"))
}

pub fn get_effective_name_delete_returns_old_name_test() {
  let entry = make_entry(Delete, Some("Deleted Source"), None)

  audit.get_effective_name(entry)
  |> should.equal(Some("Deleted Source"))
}

pub fn get_effective_name_insert_no_name_returns_none_test() {
  let entry = make_entry(Insert, None, None)

  audit.get_effective_name(entry)
  |> should.equal(None)
}

// ===================================================================
// FORMAT AUDIT ENTRY TESTS
// ===================================================================

pub fn format_audit_entry_insert_test() {
  let entry =
    RecipeSourceAuditEntry(
      audit_id: 1,
      operation: Insert,
      operation_time: "2024-01-15T10:30:00Z",
      record_id: 42,
      old_name: None,
      new_name: Some("Mealie API"),
      old_type: None,
      new_type: Some("api"),
      old_enabled: None,
      new_enabled: Some(True),
      changed_by: Some("admin"),
      change_reason: Some("Initial setup"),
    )

  let formatted = audit.format_audit_entry(entry)

  // Should contain operation
  { formatted |> contains("INSERT") } |> should.be_true

  // Should contain name
  { formatted |> contains("Mealie API") } |> should.be_true

  // Should contain record id
  { formatted |> contains("42") } |> should.be_true

  // Should contain changed_by
  { formatted |> contains("by admin") } |> should.be_true

  // Should contain reason
  { formatted |> contains("Initial setup") } |> should.be_true
}

pub fn format_audit_entry_without_context_test() {
  let entry =
    RecipeSourceAuditEntry(
      audit_id: 2,
      operation: Update,
      operation_time: "2024-01-16T14:00:00Z",
      record_id: 42,
      old_name: Some("Old Name"),
      new_name: Some("New Name"),
      old_type: None,
      new_type: None,
      old_enabled: None,
      new_enabled: None,
      changed_by: None,
      change_reason: None,
    )

  let formatted = audit.format_audit_entry(entry)

  // Should contain operation
  { formatted |> contains("UPDATE") } |> should.be_true

  // Should contain new name (for updates)
  { formatted |> contains("New Name") } |> should.be_true

  // Should NOT contain "by" (no changed_by)
  { formatted |> contains(" by ") } |> should.be_false
}

pub fn format_audit_entry_delete_test() {
  let entry =
    RecipeSourceAuditEntry(
      audit_id: 3,
      operation: Delete,
      operation_time: "2024-01-17T09:00:00Z",
      record_id: 99,
      old_name: Some("Removed Source"),
      new_name: None,
      old_type: Some("database"),
      new_type: None,
      old_enabled: Some(True),
      new_enabled: None,
      changed_by: Some("cleanup_script"),
      change_reason: Some("Deprecated"),
    )

  let formatted = audit.format_audit_entry(entry)

  // Should contain DELETE operation
  { formatted |> contains("DELETE") } |> should.be_true

  // Should contain old name (for deletes)
  { formatted |> contains("Removed Source") } |> should.be_true

  // Should contain changed_by
  { formatted |> contains("cleanup_script") } |> should.be_true
}

pub fn format_audit_entry_unknown_name_test() {
  let entry =
    RecipeSourceAuditEntry(
      audit_id: 4,
      operation: Update,
      operation_time: "2024-01-18T12:00:00Z",
      record_id: 1,
      old_name: None,
      new_name: None,
      old_type: None,
      new_type: None,
      old_enabled: None,
      new_enabled: None,
      changed_by: None,
      change_reason: None,
    )

  let formatted = audit.format_audit_entry(entry)

  // Should contain "unknown" when no name available
  { formatted |> contains("unknown") } |> should.be_true
}

// ===================================================================
// AUDIT CHANGE SUMMARY TYPE TESTS
// ===================================================================

pub fn audit_change_summary_type_test() {
  // Verify we can construct an AuditChangeSummary
  let summary =
    AuditChangeSummary(
      audit_id: 1,
      operation: Insert,
      operation_time: "2024-01-01T00:00:00Z",
      record_id: 10,
      record_name: "Test Source",
      name_changed: False,
      type_changed: False,
      enabled_changed: False,
      changed_by: Some("user1"),
      change_reason: Some("Test"),
    )

  summary.audit_id |> should.equal(1)
  summary.operation |> should.equal(Insert)
  summary.record_name |> should.equal("Test Source")
  summary.name_changed |> should.be_false
  summary.changed_by |> should.equal(Some("user1"))
}

pub fn audit_change_summary_with_changes_test() {
  let summary =
    AuditChangeSummary(
      audit_id: 2,
      operation: Update,
      operation_time: "2024-01-02T00:00:00Z",
      record_id: 20,
      record_name: "Updated Source",
      name_changed: True,
      type_changed: True,
      enabled_changed: True,
      changed_by: None,
      change_reason: None,
    )

  summary.name_changed |> should.be_true
  summary.type_changed |> should.be_true
  summary.enabled_changed |> should.be_true
  summary.changed_by |> should.equal(None)
}

// ===================================================================
// HELPER FUNCTION
// ===================================================================

fn contains(haystack: String, needle: String) -> Bool {
  case haystack {
    "" -> needle == ""
    _ -> {
      let haystack_len = string_length(haystack)
      let needle_len = string_length(needle)
      case needle_len > haystack_len {
        True -> False
        False -> contains_helper(haystack, needle, 0, haystack_len - needle_len)
      }
    }
  }
}

fn contains_helper(
  haystack: String,
  needle: String,
  pos: Int,
  max_pos: Int,
) -> Bool {
  case pos > max_pos {
    True -> False
    False -> {
      case string_slice(haystack, pos, string_length(needle)) == needle {
        True -> True
        False -> contains_helper(haystack, needle, pos + 1, max_pos)
      }
    }
  }
}

@external(erlang, "string", "length")
fn string_length(s: String) -> Int

@external(erlang, "string", "slice")
fn string_slice(s: String, start: Int, length: Int) -> String
