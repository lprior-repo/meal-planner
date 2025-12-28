//! Calculate Macro Percentages - Windmill Rust Lambda
//!
//! Calculates the percentage distribution of protein, fat, and carbs from total calories.

use serde::{Deserialize, Serialize};
use std::io::{self, Read};
use windmill_lambdas::NutritionData;

#[derive(Debug, Deserialize)]
struct Input {
    nutrition: NutritionData,
}

#[derive(Debug, Serialize)]
struct MacroPercentages {
    protein_pct: f64,
    fat_pct: f64,
    carbs_pct: f64,
    total_pct: f64,
}

/// Calories per gram for each macro
const PROTEIN_CALS_PER_GRAM: f64 = 4.0;
const FAT_CALS_PER_GRAM: f64 = 9.0;
const CARBS_CALS_PER_GRAM: f64 = 4.0;

fn calculate_macro_percentages(nutrition: &NutritionData) -> MacroPercentages {
    let protein_cals = nutrition.protein * PROTEIN_CALS_PER_GRAM;
    let fat_cals = nutrition.fat * FAT_CALS_PER_GRAM;
    let carbs_cals = nutrition.carbs * CARBS_CALS_PER_GRAM;

    let total_macro_cals = protein_cals + fat_cals + carbs_cals;

    if total_macro_cals == 0.0 {
        return MacroPercentages {
            protein_pct: 0.0,
            fat_pct: 0.0,
            carbs_pct: 0.0,
            total_pct: 0.0,
        };
    }

    MacroPercentages {
        protein_pct: (protein_cals / total_macro_cals) * 100.0,
        fat_pct: (fat_cals / total_macro_cals) * 100.0,
        carbs_pct: (carbs_cals / total_macro_cals) * 100.0,
        total_pct: 100.0,
    }
}

fn main() -> io::Result<()> {
    let mut buffer = String::new();
    io::stdin().read_to_string(&mut buffer)?;

    let input: Input = serde_json::from_str(&buffer)
        .map_err(|e| io::Error::new(io::ErrorKind::InvalidInput, e))?;

    let result = calculate_macro_percentages(&input.nutrition);

    println!(
        "{}",
        serde_json::to_string(&result)
            .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?
    );

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_calculate_macro_percentages_balanced() {
        let nutrition = NutritionData {
            protein: 150.0, // 600 cals
            fat: 66.67,     // ~600 cals
            carbs: 150.0,   // 600 cals
            calories: 1800.0,
        };

        let result = calculate_macro_percentages(&nutrition);

        // Should be roughly 33.3% each
        assert!((result.protein_pct - 33.33).abs() < 0.1);
        assert!((result.fat_pct - 33.33).abs() < 0.1);
        assert!((result.carbs_pct - 33.33).abs() < 0.1);
        assert_eq!(result.total_pct, 100.0);
    }

    #[test]
    fn test_calculate_macro_percentages_high_protein() {
        let nutrition = NutritionData {
            protein: 200.0, // 800 cals
            fat: 44.44,     // ~400 cals
            carbs: 100.0,   // 400 cals
            calories: 1600.0,
        };

        let result = calculate_macro_percentages(&nutrition);

        // Protein should be ~50%, others ~25%
        assert!((result.protein_pct - 50.0).abs() < 1.0);
        assert!((result.fat_pct - 25.0).abs() < 1.0);
        assert!((result.carbs_pct - 25.0).abs() < 1.0);
    }

    #[test]
    fn test_calculate_macro_percentages_zero() {
        let nutrition = NutritionData {
            protein: 0.0,
            fat: 0.0,
            carbs: 0.0,
            calories: 0.0,
        };

        let result = calculate_macro_percentages(&nutrition);

        assert_eq!(result.protein_pct, 0.0);
        assert_eq!(result.fat_pct, 0.0);
        assert_eq!(result.carbs_pct, 0.0);
    }
}
