//! Calculate Daily Nutrition Totals - Windmill Rust Lambda
//!
//! Aggregates nutrition data across multiple food entries for a day.

use meal_planner::meal_planner::infrastructure::NutritionData;
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Debug, Deserialize)]
struct Input {
    food_entries: Vec<NutritionData>,
}

#[derive(Debug, Serialize)]
struct Output {
    daily_totals: NutritionData,
    entry_count: usize,
}

fn calculate_daily_totals(entries: Vec<NutritionData>) -> NutritionData {
    entries.iter().fold(
        NutritionData {
            protein: 0.0,
            fat: 0.0,
            carbs: 0.0,
            calories: 0.0,
        },
        |mut acc, entry| {
            acc.protein += entry.protein;
            acc.fat += entry.fat;
            acc.carbs += entry.carbs;
            acc.calories += entry.calories;
            acc
        },
    )
}

fn main() -> io::Result<()> {
    let mut buffer = String::new();
    io::stdin().read_to_string(&mut buffer)?;

    let input: Input = serde_json::from_str(&buffer)
        .map_err(|e| io::Error::new(io::ErrorKind::InvalidInput, e))?;

    let daily_totals = calculate_daily_totals(input.food_entries.clone());
    let result = Output {
        daily_totals,
        entry_count: input.food_entries.len(),
    };

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
    fn test_calculate_daily_totals_empty() {
        let result = calculate_daily_totals(vec![]);
        assert_eq!(result.protein, 0.0);
        assert_eq!(result.fat, 0.0);
        assert_eq!(result.carbs, 0.0);
        assert_eq!(result.calories, 0.0);
    }

    #[test]
    fn test_calculate_daily_totals_single_entry() {
        let entries = vec![NutritionData {
            protein: 25.0,
            fat: 10.0,
            carbs: 30.0,
            calories: 310.0,
        }];

        let result = calculate_daily_totals(entries);
        assert_eq!(result.protein, 25.0);
        assert_eq!(result.fat, 10.0);
        assert_eq!(result.carbs, 30.0);
        assert_eq!(result.calories, 310.0);
    }

    #[test]
    fn test_calculate_daily_totals_multiple_entries() {
        let entries = vec![
            NutritionData {
                protein: 25.0,
                fat: 10.0,
                carbs: 30.0,
                calories: 310.0,
            },
            NutritionData {
                protein: 30.0,
                fat: 15.0,
                carbs: 40.0,
                calories: 415.0,
            },
            NutritionData {
                protein: 20.0,
                fat: 5.0,
                carbs: 25.0,
                calories: 225.0,
            },
        ];

        let result = calculate_daily_totals(entries);
        assert_eq!(result.protein, 75.0);
        assert_eq!(result.fat, 30.0);
        assert_eq!(result.carbs, 95.0);
        assert_eq!(result.calories, 950.0);
    }
}
