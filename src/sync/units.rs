//! Unit Conversion Utilities
//!
//! This module provides comprehensive unit conversion for cooking measurements.
//! It supports conversions between metric, imperial, and volume-based units.
//!
//! # Supported Units
//!
//! ## Mass Units
//! - Metric: gram (g), kilogram (kg), milligram (mg)
//! - Imperial: ounce (oz), pound (lb)
//!
//! ## Volume Units
//! - Metric: milliliter (ml), liter (l), deciliter (dl)
//! - Imperial: fluid ounce (fl oz), cup, tablespoon (tbsp), teaspoon (tsp)
//! - Other: pint, quart, gallon
//!
//! # Density-based Conversions
//!
//! Volume-to-mass conversions require knowing the density of the ingredient.
//! Common densities are provided for water, oil, flour, sugar, and other staples.

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use super::errors::{SyncError, SyncResult};

// =============================================================================
// UNIT TYPES
// =============================================================================

/// Standard unit categories
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum UnitCategory {
    /// Mass units (g, kg, oz, lb)
    Mass,
    /// Volume units (ml, l, cup, tbsp)
    Volume,
    /// Count units (piece, each, serving)
    Count,
    /// Unknown or custom unit
    Unknown,
}

impl Default for UnitCategory {
    fn default() -> Self {
        Self::Unknown
    }
}

/// Standard units with known conversion factors
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum StandardUnit {
    // Mass units
    Gram,
    Kilogram,
    Milligram,
    Ounce,
    Pound,

    // Volume units
    Milliliter,
    Liter,
    Deciliter,
    FluidOunce,
    Cup,
    Tablespoon,
    Teaspoon,
    Pint,
    Quart,
    Gallon,

    // Count units
    Piece,
    Each,
    Serving,
    Slice,
    Whole,

    // Unknown
    Unknown,
}

impl StandardUnit {
    /// Parse a unit string into a standard unit
    #[must_use]
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().trim() {
            // Mass units
            "g" | "gram" | "grams" => Self::Gram,
            "kg" | "kilogram" | "kilograms" => Self::Kilogram,
            "mg" | "milligram" | "milligrams" => Self::Milligram,
            "oz" | "ounce" | "ounces" => Self::Ounce,
            "lb" | "lbs" | "pound" | "pounds" => Self::Pound,

            // Volume units
            "ml" | "milliliter" | "milliliters" | "millilitre" | "millilitres" => Self::Milliliter,
            "l" | "liter" | "liters" | "litre" | "litres" => Self::Liter,
            "dl" | "deciliter" | "deciliters" | "decilitre" | "decilitres" => Self::Deciliter,
            "fl oz" | "fluid ounce" | "fluid ounces" => Self::FluidOunce,
            "cup" | "cups" | "c" => Self::Cup,
            "tbsp" | "tablespoon" | "tablespoons" | "tbs" | "t" => Self::Tablespoon,
            "tsp" | "teaspoon" | "teaspoons" | "ts" => Self::Teaspoon,
            "pt" | "pint" | "pints" => Self::Pint,
            "qt" | "quart" | "quarts" => Self::Quart,
            "gal" | "gallon" | "gallons" => Self::Gallon,

            // Count units
            "piece" | "pieces" | "pc" | "pcs" => Self::Piece,
            "each" | "ea" => Self::Each,
            "serving" | "servings" => Self::Serving,
            "slice" | "slices" => Self::Slice,
            "whole" => Self::Whole,

            _ => Self::Unknown,
        }
    }

    /// Get the category for this unit
    #[must_use]
    pub fn category(self) -> UnitCategory {
        match self {
            Self::Gram | Self::Kilogram | Self::Milligram | Self::Ounce | Self::Pound => {
                UnitCategory::Mass
            }
            Self::Milliliter
            | Self::Liter
            | Self::Deciliter
            | Self::FluidOunce
            | Self::Cup
            | Self::Tablespoon
            | Self::Teaspoon
            | Self::Pint
            | Self::Quart
            | Self::Gallon => UnitCategory::Volume,
            Self::Piece | Self::Each | Self::Serving | Self::Slice | Self::Whole => {
                UnitCategory::Count
            }
            Self::Unknown => UnitCategory::Unknown,
        }
    }

    /// Get the abbreviated name for this unit
    #[must_use]
    pub fn abbreviation(self) -> &'static str {
        match self {
            Self::Gram => "g",
            Self::Kilogram => "kg",
            Self::Milligram => "mg",
            Self::Ounce => "oz",
            Self::Pound => "lb",
            Self::Milliliter => "ml",
            Self::Liter => "l",
            Self::Deciliter => "dl",
            Self::FluidOunce => "fl oz",
            Self::Cup => "cup",
            Self::Tablespoon => "tbsp",
            Self::Teaspoon => "tsp",
            Self::Pint => "pt",
            Self::Quart => "qt",
            Self::Gallon => "gal",
            Self::Piece => "pc",
            Self::Each => "ea",
            Self::Serving => "serving",
            Self::Slice => "slice",
            Self::Whole => "whole",
            Self::Unknown => "?",
        }
    }

    /// Get the full name for this unit
    #[must_use]
    pub fn name(self) -> &'static str {
        match self {
            Self::Gram => "gram",
            Self::Kilogram => "kilogram",
            Self::Milligram => "milligram",
            Self::Ounce => "ounce",
            Self::Pound => "pound",
            Self::Milliliter => "milliliter",
            Self::Liter => "liter",
            Self::Deciliter => "deciliter",
            Self::FluidOunce => "fluid ounce",
            Self::Cup => "cup",
            Self::Tablespoon => "tablespoon",
            Self::Teaspoon => "teaspoon",
            Self::Pint => "pint",
            Self::Quart => "quart",
            Self::Gallon => "gallon",
            Self::Piece => "piece",
            Self::Each => "each",
            Self::Serving => "serving",
            Self::Slice => "slice",
            Self::Whole => "whole",
            Self::Unknown => "unknown",
        }
    }
}

impl Default for StandardUnit {
    fn default() -> Self {
        Self::Unknown
    }
}

// =============================================================================
// CONVERSION FACTORS
// =============================================================================

/// Conversion factor between two units
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub struct ConversionFactor {
    /// Source unit
    pub from: StandardUnit,
    /// Target unit
    pub to: StandardUnit,
    /// Multiplier (amount * factor = converted amount)
    pub factor: f64,
}

impl ConversionFactor {
    /// Create a new conversion factor
    #[must_use]
    pub const fn new(from: StandardUnit, to: StandardUnit, factor: f64) -> Self {
        Self { from, to, factor }
    }

    /// Get the inverse conversion
    #[must_use]
    pub fn inverse(self) -> Self {
        Self {
            from: self.to,
            to: self.from,
            factor: 1.0 / self.factor,
        }
    }
}

/// A specific unit conversion operation
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct UnitConversion {
    /// Original amount
    pub original_amount: f64,
    /// Original unit
    pub original_unit: String,
    /// Converted amount
    pub converted_amount: f64,
    /// Converted unit
    pub converted_unit: String,
    /// Conversion factor used
    pub factor: f64,
}

// =============================================================================
// DENSITY TABLE
// =============================================================================

/// Density values (g/ml) for common ingredients
#[derive(Debug, Clone)]
pub struct DensityTable {
    densities: HashMap<String, f64>,
}

impl DensityTable {
    /// Create a new density table with common ingredients
    #[must_use]
    pub fn new() -> Self {
        let mut densities = HashMap::new();

        // Liquids
        densities.insert("water".to_string(), 1.0);
        densities.insert("milk".to_string(), 1.03);
        densities.insert("cream".to_string(), 0.99);
        densities.insert("heavy cream".to_string(), 0.99);
        densities.insert("buttermilk".to_string(), 1.03);
        densities.insert("yogurt".to_string(), 1.03);

        // Oils
        densities.insert("oil".to_string(), 0.92);
        densities.insert("olive oil".to_string(), 0.92);
        densities.insert("vegetable oil".to_string(), 0.92);
        densities.insert("coconut oil".to_string(), 0.92);
        densities.insert("butter".to_string(), 0.91);

        // Flours
        densities.insert("flour".to_string(), 0.53);
        densities.insert("all-purpose flour".to_string(), 0.53);
        densities.insert("bread flour".to_string(), 0.55);
        densities.insert("whole wheat flour".to_string(), 0.52);
        densities.insert("almond flour".to_string(), 0.44);
        densities.insert("coconut flour".to_string(), 0.50);

        // Sugars
        densities.insert("sugar".to_string(), 0.85);
        densities.insert("white sugar".to_string(), 0.85);
        densities.insert("brown sugar".to_string(), 0.82);
        densities.insert("powdered sugar".to_string(), 0.56);
        densities.insert("honey".to_string(), 1.42);
        densities.insert("maple syrup".to_string(), 1.37);

        // Grains
        densities.insert("rice".to_string(), 0.85);
        densities.insert("oats".to_string(), 0.41);
        densities.insert("rolled oats".to_string(), 0.41);
        densities.insert("quinoa".to_string(), 0.74);

        // Misc
        densities.insert("salt".to_string(), 1.22);
        densities.insert("baking powder".to_string(), 0.90);
        densities.insert("baking soda".to_string(), 1.10);
        densities.insert("cocoa powder".to_string(), 0.52);
        densities.insert("protein powder".to_string(), 0.40);
        densities.insert("peanut butter".to_string(), 1.09);

        Self { densities }
    }

    /// Get density for an ingredient (returns 1.0 if not found)
    #[must_use]
    pub fn get(&self, ingredient: &str) -> f64 {
        let normalized = ingredient.to_lowercase();

        // Try exact match first
        if let Some(&density) = self.densities.get(&normalized) {
            return density;
        }

        // Try partial match
        for (key, &density) in &self.densities {
            if normalized.contains(key) || key.contains(&normalized) {
                return density;
            }
        }

        // Default to water density
        1.0
    }

    /// Add a custom density
    pub fn add(&mut self, ingredient: impl Into<String>, density: f64) {
        self.densities.insert(ingredient.into().to_lowercase(), density);
    }
}

impl Default for DensityTable {
    fn default() -> Self {
        Self::new()
    }
}

// =============================================================================
// UNIT CONVERTER
// =============================================================================

/// Unit converter with support for mass, volume, and density-based conversions
#[derive(Debug, Clone)]
pub struct UnitConverter {
    /// Density table for volume-to-mass conversions
    density_table: DensityTable,
}

impl UnitConverter {
    /// Create a new unit converter
    #[must_use]
    pub fn new() -> Self {
        Self {
            density_table: DensityTable::new(),
        }
    }

    /// Create with custom density table
    #[must_use]
    pub fn with_densities(density_table: DensityTable) -> Self {
        Self { density_table }
    }

    /// Convert an amount from one unit to another
    pub fn convert(
        &self,
        amount: f64,
        from_unit: &str,
        to_unit: &str,
        ingredient: Option<&str>,
    ) -> SyncResult<f64> {
        let from = StandardUnit::from_str(from_unit);
        let to = StandardUnit::from_str(to_unit);

        // Same unit, no conversion needed
        if from == to {
            return Ok(amount);
        }

        // Check categories
        let from_cat = from.category();
        let to_cat = to.category();

        match (from_cat, to_cat) {
            // Same category conversions
            (UnitCategory::Mass, UnitCategory::Mass) => self.convert_mass(amount, from, to),
            (UnitCategory::Volume, UnitCategory::Volume) => self.convert_volume(amount, from, to),

            // Cross-category conversions (need density)
            (UnitCategory::Volume, UnitCategory::Mass) => {
                let density = ingredient.map_or(1.0, |i| self.density_table.get(i));
                let ml = self.to_milliliters(amount, from)?;
                let grams = ml * density;
                self.from_grams(grams, to)
            }
            (UnitCategory::Mass, UnitCategory::Volume) => {
                let density = ingredient.map_or(1.0, |i| self.density_table.get(i));
                let grams = self.to_grams(amount, from)?;
                let ml = grams / density;
                self.from_milliliters(ml, to)
            }

            // Count units - assume 1:1 for now
            (UnitCategory::Count, _) | (_, UnitCategory::Count) => Ok(amount),

            // Unknown conversions
            _ => Err(SyncError::validation_failed(format!(
                "Cannot convert from {from_unit} to {to_unit}"
            ))),
        }
    }

    /// Convert to grams
    #[must_use]
    pub fn to_grams(&self, amount: f64, unit: StandardUnit) -> SyncResult<f64> {
        match unit {
            StandardUnit::Gram => Ok(amount),
            StandardUnit::Kilogram => Ok(amount * 1000.0),
            StandardUnit::Milligram => Ok(amount / 1000.0),
            StandardUnit::Ounce => Ok(amount * 28.3495),
            StandardUnit::Pound => Ok(amount * 453.592),
            _ => Err(SyncError::validation_failed(format!(
                "Cannot convert {} to grams",
                unit.name()
            ))),
        }
    }

    /// Convert from grams to target unit
    fn from_grams(&self, grams: f64, to: StandardUnit) -> SyncResult<f64> {
        match to {
            StandardUnit::Gram => Ok(grams),
            StandardUnit::Kilogram => Ok(grams / 1000.0),
            StandardUnit::Milligram => Ok(grams * 1000.0),
            StandardUnit::Ounce => Ok(grams / 28.3495),
            StandardUnit::Pound => Ok(grams / 453.592),
            _ => Err(SyncError::validation_failed(format!(
                "Cannot convert grams to {}",
                to.name()
            ))),
        }
    }

    /// Convert to milliliters
    fn to_milliliters(&self, amount: f64, unit: StandardUnit) -> SyncResult<f64> {
        match unit {
            StandardUnit::Milliliter => Ok(amount),
            StandardUnit::Liter => Ok(amount * 1000.0),
            StandardUnit::Deciliter => Ok(amount * 100.0),
            StandardUnit::FluidOunce => Ok(amount * 29.5735),
            StandardUnit::Cup => Ok(amount * 236.588),
            StandardUnit::Tablespoon => Ok(amount * 14.7868),
            StandardUnit::Teaspoon => Ok(amount * 4.92892),
            StandardUnit::Pint => Ok(amount * 473.176),
            StandardUnit::Quart => Ok(amount * 946.353),
            StandardUnit::Gallon => Ok(amount * 3785.41),
            _ => Err(SyncError::validation_failed(format!(
                "Cannot convert {} to milliliters",
                unit.name()
            ))),
        }
    }

    /// Convert from milliliters to target unit
    fn from_milliliters(&self, ml: f64, to: StandardUnit) -> SyncResult<f64> {
        match to {
            StandardUnit::Milliliter => Ok(ml),
            StandardUnit::Liter => Ok(ml / 1000.0),
            StandardUnit::Deciliter => Ok(ml / 100.0),
            StandardUnit::FluidOunce => Ok(ml / 29.5735),
            StandardUnit::Cup => Ok(ml / 236.588),
            StandardUnit::Tablespoon => Ok(ml / 14.7868),
            StandardUnit::Teaspoon => Ok(ml / 4.92892),
            StandardUnit::Pint => Ok(ml / 473.176),
            StandardUnit::Quart => Ok(ml / 946.353),
            StandardUnit::Gallon => Ok(ml / 3785.41),
            _ => Err(SyncError::validation_failed(format!(
                "Cannot convert milliliters to {}",
                to.name()
            ))),
        }
    }

    /// Convert mass units
    fn convert_mass(&self, amount: f64, from: StandardUnit, to: StandardUnit) -> SyncResult<f64> {
        let grams = self.to_grams(amount, from)?;
        self.from_grams(grams, to)
    }

    /// Convert volume units
    fn convert_volume(&self, amount: f64, from: StandardUnit, to: StandardUnit) -> SyncResult<f64> {
        let ml = self.to_milliliters(amount, from)?;
        self.from_milliliters(ml, to)
    }

    /// Get the density table
    #[must_use]
    pub fn density_table(&self) -> &DensityTable {
        &self.density_table
    }

    /// Get mutable density table
    pub fn density_table_mut(&mut self) -> &mut DensityTable {
        &mut self.density_table
    }
}

impl Default for UnitConverter {
    fn default() -> Self {
        Self::new()
    }
}

// =============================================================================
// CONVENIENCE FUNCTIONS
// =============================================================================

/// Convert amount to grams (simplified API)
#[must_use]
pub fn convert_to_grams(amount: f64, unit: &str) -> f64 {
    let std_unit = StandardUnit::from_str(unit);

    match std_unit {
        StandardUnit::Gram => amount,
        StandardUnit::Kilogram => amount * 1000.0,
        StandardUnit::Milligram => amount / 1000.0,
        StandardUnit::Ounce => amount * 28.3495,
        StandardUnit::Pound => amount * 453.592,
        // Volume units - assume water density
        StandardUnit::Milliliter => amount,
        StandardUnit::Liter => amount * 1000.0,
        StandardUnit::Deciliter => amount * 100.0,
        StandardUnit::Cup => amount * 236.588,
        StandardUnit::Tablespoon => amount * 14.7868,
        StandardUnit::Teaspoon => amount * 4.92892,
        StandardUnit::FluidOunce => amount * 29.5735,
        StandardUnit::Pint => amount * 473.176,
        StandardUnit::Quart => amount * 946.353,
        StandardUnit::Gallon => amount * 3785.41,
        // Count units - return as-is (assume 100g per piece)
        StandardUnit::Piece
        | StandardUnit::Each
        | StandardUnit::Serving
        | StandardUnit::Slice
        | StandardUnit::Whole => amount * 100.0,
        // Unknown - return as-is
        StandardUnit::Unknown => amount,
    }
}

/// Convert amount to milliliters (simplified API)
#[must_use]
pub fn convert_to_ml(amount: f64, unit: &str) -> f64 {
    let std_unit = StandardUnit::from_str(unit);

    match std_unit {
        StandardUnit::Milliliter => amount,
        StandardUnit::Liter => amount * 1000.0,
        StandardUnit::Deciliter => amount * 100.0,
        StandardUnit::FluidOunce => amount * 29.5735,
        StandardUnit::Cup => amount * 236.588,
        StandardUnit::Tablespoon => amount * 14.7868,
        StandardUnit::Teaspoon => amount * 4.92892,
        StandardUnit::Pint => amount * 473.176,
        StandardUnit::Quart => amount * 946.353,
        StandardUnit::Gallon => amount * 3785.41,
        // Mass units - assume water density
        StandardUnit::Gram => amount,
        StandardUnit::Kilogram => amount * 1000.0,
        StandardUnit::Milligram => amount / 1000.0,
        StandardUnit::Ounce => amount * 28.3495,
        StandardUnit::Pound => amount * 453.592,
        // Count/unknown - return as-is
        _ => amount,
    }
}

/// Format amount with appropriate precision
#[must_use]
pub fn format_amount(amount: f64) -> String {
    if amount == 0.0 {
        return "0".to_string();
    }

    let abs_amount = amount.abs();

    if abs_amount >= 100.0 {
        format!("{:.0}", amount)
    } else if abs_amount >= 10.0 {
        format!("{:.1}", amount)
    } else if abs_amount >= 1.0 {
        format!("{:.2}", amount)
    } else {
        format!("{:.3}", amount)
    }
}

/// Parse an amount string (handles fractions like "1/2")
pub fn parse_amount(s: &str) -> SyncResult<f64> {
    let s = s.trim();

    // Handle mixed fractions like "1 1/2" FIRST (before simple fractions)
    if s.contains(' ') && s.contains('/') {
        let parts: Vec<&str> = s.splitn(2, ' ').collect();
        if parts.len() == 2 {
            let whole: f64 = parts
                .first()
                .and_then(|p| p.trim().parse().ok())
                .ok_or_else(|| SyncError::parse_error(format!("Invalid mixed fraction: {s}")))?;
            let fraction = parse_amount(parts.get(1).copied().unwrap_or("0"))?;
            return Ok(whole + fraction);
        }
    }

    // Handle simple fractions
    if s.contains('/') {
        let parts: Vec<&str> = s.split('/').collect();
        if parts.len() == 2 {
            let numerator: f64 = parts
                .first()
                .and_then(|p| p.trim().parse().ok())
                .ok_or_else(|| SyncError::parse_error(format!("Invalid fraction: {s}")))?;
            let denominator: f64 = parts
                .get(1)
                .and_then(|p| p.trim().parse().ok())
                .ok_or_else(|| SyncError::parse_error(format!("Invalid fraction: {s}")))?;

            if denominator == 0.0 {
                return Err(SyncError::parse_error("Division by zero"));
            }

            return Ok(numerator / denominator);
        }
    }

    // Regular number
    s.parse()
        .map_err(|_| SyncError::parse_error(format!("Invalid number: {s}")))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_standard_unit_from_str() {
        assert_eq!(StandardUnit::from_str("g"), StandardUnit::Gram);
        assert_eq!(StandardUnit::from_str("gram"), StandardUnit::Gram);
        assert_eq!(StandardUnit::from_str("GRAMS"), StandardUnit::Gram);
        assert_eq!(StandardUnit::from_str("kg"), StandardUnit::Kilogram);
        assert_eq!(StandardUnit::from_str("oz"), StandardUnit::Ounce);
        assert_eq!(StandardUnit::from_str("cup"), StandardUnit::Cup);
        assert_eq!(StandardUnit::from_str("tbsp"), StandardUnit::Tablespoon);
        assert_eq!(StandardUnit::from_str("unknown_unit"), StandardUnit::Unknown);
    }

    #[test]
    fn test_unit_category() {
        assert_eq!(StandardUnit::Gram.category(), UnitCategory::Mass);
        assert_eq!(StandardUnit::Ounce.category(), UnitCategory::Mass);
        assert_eq!(StandardUnit::Cup.category(), UnitCategory::Volume);
        assert_eq!(StandardUnit::Tablespoon.category(), UnitCategory::Volume);
        assert_eq!(StandardUnit::Piece.category(), UnitCategory::Count);
        assert_eq!(StandardUnit::Unknown.category(), UnitCategory::Unknown);
    }

    #[test]
    fn test_convert_to_grams() {
        assert!((convert_to_grams(100.0, "g") - 100.0).abs() < 0.001);
        assert!((convert_to_grams(1.0, "kg") - 1000.0).abs() < 0.001);
        assert!((convert_to_grams(1000.0, "mg") - 1.0).abs() < 0.001);
        assert!((convert_to_grams(1.0, "oz") - 28.3495).abs() < 0.01);
        assert!((convert_to_grams(1.0, "lb") - 453.592).abs() < 0.01);
        assert!((convert_to_grams(1.0, "cup") - 236.588).abs() < 0.01);
        assert!((convert_to_grams(1.0, "tbsp") - 14.7868).abs() < 0.01);
        assert!((convert_to_grams(1.0, "tsp") - 4.92892).abs() < 0.01);
    }

    #[test]
    fn test_convert_to_ml() {
        assert!((convert_to_ml(100.0, "ml") - 100.0).abs() < 0.001);
        assert!((convert_to_ml(1.0, "l") - 1000.0).abs() < 0.001);
        assert!((convert_to_ml(1.0, "cup") - 236.588).abs() < 0.01);
        assert!((convert_to_ml(1.0, "tbsp") - 14.7868).abs() < 0.01);
        assert!((convert_to_ml(1.0, "tsp") - 4.92892).abs() < 0.01);
        assert!((convert_to_ml(1.0, "fl oz") - 29.5735).abs() < 0.01);
    }

    #[test]
    fn test_unit_converter_same_unit() {
        let converter = UnitConverter::new();
        let result = converter.convert(100.0, "g", "g", None);
        assert!((result.unwrap() - 100.0).abs() < 0.001);
    }

    #[test]
    fn test_unit_converter_mass_to_mass() {
        let converter = UnitConverter::new();

        let result = converter.convert(1.0, "kg", "g", None);
        assert!((result.unwrap() - 1000.0).abs() < 0.001);

        let result = converter.convert(1.0, "lb", "oz", None);
        assert!((result.unwrap() - 16.0).abs() < 0.1);

        let result = converter.convert(28.3495, "g", "oz", None);
        assert!((result.unwrap() - 1.0).abs() < 0.001);
    }

    #[test]
    fn test_unit_converter_volume_to_volume() {
        let converter = UnitConverter::new();

        let result = converter.convert(1.0, "l", "ml", None);
        assert!((result.unwrap() - 1000.0).abs() < 0.001);

        let result = converter.convert(1.0, "cup", "tbsp", None);
        assert!((result.unwrap() - 16.0).abs() < 0.1);

        let result = converter.convert(1.0, "tbsp", "tsp", None);
        assert!((result.unwrap() - 3.0).abs() < 0.1);
    }

    #[test]
    fn test_unit_converter_volume_to_mass() {
        let converter = UnitConverter::new();

        // Water: 1 ml = 1 g
        let result = converter.convert(100.0, "ml", "g", Some("water"));
        assert!((result.unwrap() - 100.0).abs() < 0.1);

        // Oil: 1 ml = 0.92 g
        let result = converter.convert(100.0, "ml", "g", Some("olive oil"));
        assert!((result.unwrap() - 92.0).abs() < 1.0);

        // Flour: 1 ml = 0.53 g
        let result = converter.convert(100.0, "ml", "g", Some("flour"));
        assert!((result.unwrap() - 53.0).abs() < 1.0);
    }

    #[test]
    fn test_density_table() {
        let table = DensityTable::new();

        assert!((table.get("water") - 1.0).abs() < 0.01);
        assert!((table.get("olive oil") - 0.92).abs() < 0.01);
        assert!((table.get("flour") - 0.53).abs() < 0.01);
        assert!((table.get("sugar") - 0.85).abs() < 0.01);

        // Partial match
        assert!((table.get("all-purpose flour") - 0.53).abs() < 0.01);

        // Unknown ingredient defaults to 1.0
        assert!((table.get("unknown_ingredient") - 1.0).abs() < 0.01);
    }

    #[test]
    fn test_format_amount() {
        assert_eq!(format_amount(0.0), "0");
        assert_eq!(format_amount(100.0), "100");
        assert_eq!(format_amount(10.5), "10.5");
        assert_eq!(format_amount(1.25), "1.25");
        assert_eq!(format_amount(0.125), "0.125");
    }

    #[test]
    fn test_parse_amount() {
        assert!((parse_amount("100").unwrap() - 100.0).abs() < 0.001);
        assert!((parse_amount("1.5").unwrap() - 1.5).abs() < 0.001);
        assert!((parse_amount("1/2").unwrap() - 0.5).abs() < 0.001);
        assert!((parse_amount("1/4").unwrap() - 0.25).abs() < 0.001);
        assert!((parse_amount("1 1/2").unwrap() - 1.5).abs() < 0.001);
        assert!((parse_amount("2 3/4").unwrap() - 2.75).abs() < 0.001);
    }

    #[test]
    fn test_parse_amount_errors() {
        assert!(parse_amount("abc").is_err());
        assert!(parse_amount("1/0").is_err());
    }

    #[test]
    fn test_conversion_factor() {
        let factor = ConversionFactor::new(StandardUnit::Kilogram, StandardUnit::Gram, 1000.0);
        assert_eq!(factor.from, StandardUnit::Kilogram);
        assert_eq!(factor.to, StandardUnit::Gram);
        assert!((factor.factor - 1000.0).abs() < 0.001);

        let inverse = factor.inverse();
        assert_eq!(inverse.from, StandardUnit::Gram);
        assert_eq!(inverse.to, StandardUnit::Kilogram);
        assert!((inverse.factor - 0.001).abs() < 0.00001);
    }
}
