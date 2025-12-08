/// Diet Validator Protocol
///
/// This module defines the common interface that all diet validators must implement.
/// Each diet type (Vertical, Keto, TimFerriss, etc.) implements this protocol.
///
/// This follows the "Replace Conditional with Polymorphism" refactoring pattern
/// from Martin Fowler's catalog, making it easier to:
/// - Add new diet types without modifying existing code (Open/Closed Principle)
/// - Test each diet validator in isolation
/// - Understand diet-specific logic without navigating large case statements
import meal_planner/types.{type Recipe}

// ============================================================================
// Protocol Interface
// ============================================================================

/// Result of diet compliance validation
pub type ComplianceResult {
  ComplianceResult(
    compliant: Bool,
    score: Float,
    violations: List(String),
    warnings: List(String),
  )
}

/// Diet Validator interface - all diet validators must implement this
pub type DietValidator {
  DietValidator(name: String, validate: fn(Recipe) -> ComplianceResult)
}

// ============================================================================
// Utility Functions
// ============================================================================

/// Create an empty compliance result (fully compliant)
pub fn compliant() -> ComplianceResult {
  ComplianceResult(compliant: True, score: 1.0, violations: [], warnings: [])
}

/// Create a non-compliant result with violations
pub fn non_compliant(violations: List(String)) -> ComplianceResult {
  ComplianceResult(
    compliant: False,
    score: 0.0,
    violations: violations,
    warnings: [],
  )
}

/// Create a compliant result with warnings
pub fn compliant_with_warnings(warnings: List(String)) -> ComplianceResult {
  ComplianceResult(
    compliant: True,
    score: 1.0,
    violations: [],
    warnings: warnings,
  )
}

/// Create a partial compliance result (compliant but with reduced score)
pub fn partial_compliance(
  score: Float,
  warnings: List(String),
) -> ComplianceResult {
  ComplianceResult(
    compliant: True,
    score: score,
    violations: [],
    warnings: warnings,
  )
}
