/// Tandoor UnitConversion type definition
///
/// This module defines the UnitConversion type for unit conversion support.
/// Unit conversions enable ingredient quantity normalization across different
/// measurement units (e.g., cups to milliliters, pounds to grams).
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/option.{type Option}
import meal_planner/tandoor/core/ids.{type UserId}
import meal_planner/tandoor/food.{type Food}
import meal_planner/tandoor/unit.{type Unit}

/// Defines a conversion between two units
///
/// Represents a conversion ratio between two measurement units,
/// optionally specific to a particular food item.
///
/// Fields:
/// - id: Unique identifier
/// - base_amount: Quantity in the source unit
/// - base_unit: The source measurement unit (required reference)
/// - converted_amount: Equivalent quantity in the target unit
/// - converted_unit: The target measurement unit (required reference)
/// - food: Optional food-specific conversion (null = applies to all foods)
/// - created_by: User who created this conversion (readonly)
/// - created_at: Creation timestamp (readonly, ISO 8601)
/// - updated_at: Last update timestamp (readonly, ISO 8601)
pub type UnitConversion {
  UnitConversion(
    id: Int,
    base_amount: Float,
    base_unit: Unit,
    converted_amount: Float,
    converted_unit: Unit,
    food: Option(Food),
    created_by: UserId,
    created_at: String,
    updated_at: String,
  )
}
