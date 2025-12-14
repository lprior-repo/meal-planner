/// FatSecret Weight Management types
///
/// These types represent weight entries and summaries from the FatSecret API.
/// The API uses date_int (days since Unix epoch) for all date operations.
import gleam/option.{type Option}

// ============================================================================
// Weight Entry Types
// ============================================================================

/// Single weight measurement entry
///
/// Represents a weight logged to the user's profile on a specific date.
pub type WeightEntry {
  WeightEntry(
    /// Date as days since Unix epoch (0 = 1970-01-01)
    date_int: Int,
    /// Weight in kilograms
    weight_kg: Float,
    /// Optional comment about the measurement
    weight_comment: Option(String),
  )
}

/// Input for updating weight
///
/// Used to log a new weight measurement or update an existing one.
/// FatSecret API has specific rules about which dates can be updated.
pub type WeightUpdate {
  WeightUpdate(
    /// Current weight in kilograms
    current_weight_kg: Float,
    /// Date as days since Unix epoch
    date_int: Int,
    /// Optional goal weight in kilograms
    goal_weight_kg: Option(Float),
    /// Optional height in centimeters
    height_cm: Option(Float),
    /// Optional comment about the measurement
    comment: Option(String),
  )
}

// ============================================================================
// Summary Types
// ============================================================================

/// Single day's weight summary
///
/// Used within monthly summaries to show weight for each day.
pub type WeightDaySummary {
  WeightDaySummary(
    /// Date as days since Unix epoch
    date_int: Int,
    /// Weight in kilograms
    weight_kg: Float,
  )
}

/// Monthly weight summary
///
/// Contains weight measurements for each day in the month that has data.
/// The FatSecret API returns date ranges using from_date_int/to_date_int
/// rather than explicit month/year fields.
pub type WeightMonthSummary {
  WeightMonthSummary(
    /// Start date of the month as days since Unix epoch
    from_date_int: Int,
    /// End date of the month as days since Unix epoch
    to_date_int: Int,
    /// List of daily weight measurements
    days: List(WeightDaySummary),
  )
}
