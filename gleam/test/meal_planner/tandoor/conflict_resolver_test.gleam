import gleam/option.{None, Some}
import gleeunit
import gleeunit/should

import meal_planner/tandoor/conflict_resolver

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Conflict Detection Tests
// ============================================================================

pub fn test_has_local_modifications_with_local_newer() {
  conflict_resolver.has_local_modifications(
    Some("2025-12-13T12:00:00Z"),
    Some("2025-12-13T11:00:00Z"),
  )
  |> should.be_true()
}

pub fn test_has_local_modifications_with_local_older() {
  conflict_resolver.has_local_modifications(
    Some("2025-12-13T11:00:00Z"),
    Some("2025-12-13T12:00:00Z"),
  )
  |> should.be_false()
}

pub fn test_has_local_modifications_with_no_local() {
  conflict_resolver.has_local_modifications(None, Some("2025-12-13T11:00:00Z"))
  |> should.be_false()
}

pub fn test_has_local_modifications_with_no_sync() {
  conflict_resolver.has_local_modifications(Some("2025-12-13T11:00:00Z"), None)
  |> should.be_true()
}

pub fn test_has_remote_modifications_with_remote_newer() {
  conflict_resolver.has_remote_modifications(
    Some("2025-12-13T12:00:00Z"),
    Some("2025-12-13T11:00:00Z"),
  )
  |> should.be_true()
}

pub fn test_has_remote_modifications_with_remote_older() {
  conflict_resolver.has_remote_modifications(
    Some("2025-12-13T11:00:00Z"),
    Some("2025-12-13T12:00:00Z"),
  )
  |> should.be_false()
}

pub fn test_detect_conflict_with_both_modified() {
  conflict_resolver.detect_conflict(
    Some("2025-12-13T12:00:00Z"),
    Some("2025-12-13T11:30:00Z"),
    Some("2025-12-13T11:00:00Z"),
  )
  |> should.be_true()
}

pub fn test_detect_conflict_with_only_local_modified() {
  conflict_resolver.detect_conflict(
    Some("2025-12-13T12:00:00Z"),
    Some("2025-12-13T10:00:00Z"),
    Some("2025-12-13T11:00:00Z"),
  )
  |> should.be_false()
}

pub fn test_detect_conflict_with_only_remote_modified() {
  conflict_resolver.detect_conflict(
    Some("2025-12-13T10:00:00Z"),
    Some("2025-12-13T12:00:00Z"),
    Some("2025-12-13T11:00:00Z"),
  )
  |> should.be_false()
}

// ============================================================================
// Conflict Classification Tests
// ============================================================================

pub fn test_classify_conflict_bidirectional() {
  conflict_resolver.classify_conflict(
    Some("2025-12-13T12:00:00Z"),
    Some("2025-12-13T11:30:00Z"),
    Some("2025-12-13T11:00:00Z"),
  )
  |> should.equal(Some(conflict_resolver.BidirectionalConflict))
}

pub fn test_classify_conflict_local_only() {
  conflict_resolver.classify_conflict(
    Some("2025-12-13T12:00:00Z"),
    Some("2025-12-13T10:00:00Z"),
    Some("2025-12-13T11:00:00Z"),
  )
  |> should.equal(Some(conflict_resolver.LocalOnlyConflict))
}

pub fn test_classify_conflict_remote_only() {
  conflict_resolver.classify_conflict(
    Some("2025-12-13T10:00:00Z"),
    Some("2025-12-13T12:00:00Z"),
    Some("2025-12-13T11:00:00Z"),
  )
  |> should.equal(Some(conflict_resolver.RemoteOnlyConflict))
}

pub fn test_classify_conflict_no_conflict() {
  conflict_resolver.classify_conflict(
    Some("2025-12-13T10:00:00Z"),
    Some("2025-12-13T10:00:00Z"),
    Some("2025-12-13T11:00:00Z"),
  )
  |> should.equal(None)
}

// ============================================================================
// Conflict Analysis Tests
// ============================================================================

pub fn test_which_is_more_recent_local() {
  conflict_resolver.which_is_more_recent(
    Some("2025-12-13T12:00:00Z"),
    Some("2025-12-13T11:00:00Z"),
  )
  |> should.equal(Some(#("local", "2025-12-13T12:00:00Z")))
}

pub fn test_which_is_more_recent_remote() {
  conflict_resolver.which_is_more_recent(
    Some("2025-12-13T11:00:00Z"),
    Some("2025-12-13T12:00:00Z"),
  )
  |> should.equal(Some(#("remote", "2025-12-13T12:00:00Z")))
}

pub fn test_which_is_more_recent_equal() {
  conflict_resolver.which_is_more_recent(
    Some("2025-12-13T11:00:00Z"),
    Some("2025-12-13T11:00:00Z"),
  )
  |> should.equal(None)
}

pub fn test_which_is_more_recent_only_local() {
  conflict_resolver.which_is_more_recent(
    Some("2025-12-13T11:00:00Z"),
    None,
  )
  |> should.equal(Some(#("local", "2025-12-13T11:00:00Z")))
}

// ============================================================================
// Description Tests
// ============================================================================

pub fn test_describe_conflict_bidirectional() {
  let desc = conflict_resolver.describe_conflict(
    Some("2025-12-13T12:00:00Z"),
    Some("2025-12-13T11:30:00Z"),
    Some("2025-12-13T11:00:00Z"),
  )
  
  desc
  |> should.contain("Local has modifications")
}

pub fn test_conflict_type_to_string_bidirectional() {
  conflict_resolver.conflict_type_to_string(
    conflict_resolver.BidirectionalConflict,
  )
  |> should.equal("Bidirectional conflict")
}

pub fn test_conflict_type_to_string_local_only() {
  conflict_resolver.conflict_type_to_string(
    conflict_resolver.LocalOnlyConflict,
  )
  |> should.equal("Local-only changes")
}

pub fn test_conflict_type_to_string_remote_only() {
  conflict_resolver.conflict_type_to_string(
    conflict_resolver.RemoteOnlyConflict,
  )
  |> should.equal("Remote-only changes")
}

// ============================================================================
// Strategy String Tests
// ============================================================================

pub fn test_strategy_to_string_prefer_local() {
  conflict_resolver.strategy_to_string(conflict_resolver.PreferLocal)
  |> should.equal("Prefer local version")
}

pub fn test_strategy_to_string_prefer_remote() {
  conflict_resolver.strategy_to_string(conflict_resolver.PreferRemote)
  |> should.equal("Prefer remote version")
}

pub fn test_strategy_to_string_manual_review() {
  conflict_resolver.strategy_to_string(conflict_resolver.ManualReview)
  |> should.equal("Manual review required")
}

pub fn test_strategy_to_string_auto_resolve_more_recent() {
  conflict_resolver.strategy_to_string(
    conflict_resolver.AutoResolve(conflict_resolver.MoreRecent),
  )
  |> should.contain("Auto-resolve")
  |> should.equal(Nil)
}
