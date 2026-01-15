//! Analyze Nutrition Data
#![allow(clippy::map_unwrap_or)]
#![allow(clippy::suspicious_operation_groupings)]
#![allow(clippy::cast_precision_loss)]
#![allow(clippy::suboptimal_flops)]
#![allow(clippy::indexing_slicing)]
#![allow(clippy::cognitive_complexity)]
#![allow(clippy::or_fun_call)]
#![allow(clippy::items_after_test_module)]
//!
//! This binary analyzes nutrition data from FatSecret diary entries and
//! provides trends, statistics, and recommendations.
//!
//! This is part of the Tandoor ↔ FatSecret sync layer.
//!
//! JSON input (CLI arg or stdin):
//! ```json
//! {
//!   "fatsecret": {"consumer_key": "...", "consumer_secret": "..."},
//!   "access_token": "...",
//!   "access_secret": "...",
//!   "date_range": {"start": "2025-01-01", "end": "2025-01-31"},
//!   "analyze": ["calories", "protein", "carbohydrates", "fat"]
//! }
//! ```
//!
//! JSON stdout:
//! ```json
//! {
//!   "success": true,
//!   "analysis": {
//!     "daily_average": {...},
//!     "trends": [...],
//!     "recommendations": [...]
//!   }
//! }
//! ```

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used, clippy::too_many_lines)]

use meal_planner::fatsecret::core::{AccessToken, FatSecretConfig};
use meal_planner::fatsecret::diary::{get_food_entries, date_to_int, FoodEntry};
use meal_planner::sync::types::NutritionData;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::io::{self, Read};

#[derive(Deserialize)]
struct FatSecretResource {
    consumer_key: String,
    consumer_secret: String,
}

#[derive(Deserialize, Serialize, Clone)]
struct DateRange {
    start: String,
    end: String,
}

#[derive(Deserialize)]
struct Input {
    /// FatSecret credentials (optional, uses env if not provided)
    fatsecret: Option<FatSecretResource>,
    /// OAuth access token for FatSecret
    access_token: String,
    /// OAuth access token secret for FatSecret
    access_secret: String,
    /// Date range to analyze
    date_range: DateRange,
    /// Nutrients to analyze (optional, defaults to all, unused for now)
    #[allow(dead_code)]
    analyze: Option<Vec<String>>,
    /// Calorie target for analysis
    calorie_target: Option<f64>,
    /// Protein target for analysis
    protein_target: Option<f64>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    analysis: AnalysisResult,
}

#[derive(Serialize)]
struct AnalysisResult {
    /// Date range analyzed
    date_range: DateRange,
    /// Number of days with data
    days_with_data: usize,
    /// Daily average nutrition
    daily_average: NutritionSummary,
    /// Total nutrition for period
    total: NutritionSummary,
    /// Minimum values
    minimum: NutritionSummary,
    /// Maximum values
    maximum: NutritionSummary,
    /// Standard deviation
    std_dev: NutritionSummary,
    /// Trends for each nutrient
    trends: Vec<TrendInfo>,
    /// Recommendations based on analysis
    recommendations: Vec<String>,
    /// Daily breakdown
    daily_data: Vec<DailySummary>,
    /// Weekly averages
    weekly_averages: Vec<WeeklyAverage>,
}

#[derive(Serialize)]
struct NutritionSummary {
    calories: f64,
    protein: f64,
    carbohydrates: f64,
    fat: f64,
    fiber: Option<f64>,
}

#[derive(Serialize)]
struct TrendInfo {
    nutrient: String,
    direction: String,
    change_percent: f64,
    is_significant: bool,
    description: String,
}

#[derive(Serialize)]
struct DailySummary {
    date: String,
    calories: f64,
    protein: f64,
    carbohydrates: f64,
    fat: f64,
    meal_count: usize,
}

#[derive(Serialize)]
struct WeeklyAverage {
    week: String,
    avg_calories: f64,
    avg_protein: f64,
    days_tracked: usize,
}

#[derive(Serialize)]
struct ErrorOutput {
    success: bool,
    error: String,
}

#[tokio::main]
async fn main() {
    // Check for help and schema flags first
    let args: Vec<String> = std::env::args().collect();
    if args.len() > 1 {
        let arg = &args[1];
        if arg == "--help" || arg == "-h" || arg == "help" {
            print_help();
            std::process::exit(0);
        }
        if arg == "--schema" {
            print_schema();
            std::process::exit(0);
        }
    }

    match run().await {
        Ok(output) => {
            println!(
                "{}",
                serde_json::to_string(&output).expect("Failed to serialize output")
            );
        }
        Err(e) => {
            let error = ErrorOutput {
                success: false,
                error: e.to_string(),
            };
            println!(
                "{}",
                serde_json::to_string(&error).expect("Failed to serialize error")
            );
            std::process::exit(1);
        }
    }
}

async fn run() -> Result<Output, Box<dyn std::error::Error>> {
    let input: Input = read_input()?;

    // Set up FatSecret config
    let fs_config = match input.fatsecret {
        Some(r) => FatSecretConfig::new(r.consumer_key, r.consumer_secret)?,
        None => FatSecretConfig::from_env()?,
    };

    let token = AccessToken::new(input.access_token, input.access_secret);

    // Validate and convert date range with strict YYYY-MM-DD format checking
    let start_int = date_to_int(&input.date_range.start)
        .map_err(|e| format!("Invalid start date '{}': {}", input.date_range.start, e))?;
    let end_int = date_to_int(&input.date_range.end)
        .map_err(|e| format!("Invalid end date '{}': {}", input.date_range.end, e))?;

    let mut entries: Vec<FoodEntry> = Vec::new();
    for date_int in start_int..=end_int {
        match get_food_entries(&fs_config, &token, date_int).await {
            Ok(day_entries) => entries.extend(day_entries),
            Err(e) => {
                // Log error but continue with other days
                eprintln!("Warning: Failed to get entries for day {}: {}", date_int, e);
            }
        }
    }

    // Group entries by date and calculate daily nutrition
    let mut daily_nutrition: HashMap<String, (NutritionData, usize)> = HashMap::new();

    for entry in &entries {
        // Convert date_int to date string
        let date_str = int_to_date(i64::from(entry.date_int));

        let entry_nutrition = NutritionData {
            calories: entry.calories,
            protein: entry.protein,
            carbohydrate: entry.carbohydrate,
            fat: entry.fat,
            fiber: entry.fiber,
            ..NutritionData::zero()
        };

        let daily = daily_nutrition
            .entry(date_str)
            .or_insert((NutritionData::zero(), 0));
        daily.0 = daily.0.add(&entry_nutrition);
        daily.1 += 1;
    }

    // Sort daily data by date
    let mut sorted_dates: Vec<String> = daily_nutrition.keys().cloned().collect();
    sorted_dates.sort();

    // Calculate statistics
    let days_count = daily_nutrition.len();

    if days_count == 0 {
        return Err("No nutrition data found for the specified date range".into());
    }

    // Calculate totals and averages
    let mut total = NutritionData::zero();
    let mut min_cal = f64::MAX;
    let mut max_cal = f64::MIN;
    let mut min_prot = f64::MAX;
    let mut max_prot = f64::MIN;

    let mut daily_data = Vec::new();

    for date in &sorted_dates {
        let (nutrition, meal_count) = &daily_nutrition[date];
        total = total.add(nutrition);

        min_cal = min_cal.min(nutrition.calories);
        max_cal = max_cal.max(nutrition.calories);
        min_prot = min_prot.min(nutrition.protein);
        max_prot = max_prot.max(nutrition.protein);

        daily_data.push(DailySummary {
            date: date.clone(),
            calories: nutrition.calories,
            protein: nutrition.protein,
            carbohydrates: nutrition.carbohydrates(),
            fat: nutrition.fat,
            meal_count: *meal_count,
        });
    }

    let avg = total.scale(1.0 / days_count as f64);

    // Calculate standard deviation
    let mut cal_var = 0.0;
    let mut prot_var = 0.0;
    for (nutrition, _) in daily_nutrition.values() {
        cal_var += (nutrition.calories - avg.calories).powi(2);
        prot_var += (nutrition.protein - avg.protein).powi(2);
    }
    let std_cal = (cal_var / days_count as f64).sqrt();
    let std_prot = (prot_var / days_count as f64).sqrt();

    // Calculate trends (simple linear regression)
    let calories: Vec<f64> = sorted_dates
        .iter()
        .map(|d| daily_nutrition[d].0.calories)
        .collect();

    let cal_trend = calculate_trend(&calories);
    let protein: Vec<f64> = sorted_dates
        .iter()
        .map(|d| daily_nutrition[d].0.protein)
        .collect();
    let prot_trend = calculate_trend(&protein);

    let mut trends = Vec::new();

    let cal_change_pct = if calories.first().map(|&f| f > 0.0).unwrap_or(false) {
        (cal_trend / calories.first().unwrap()) * 100.0 * (calories.len() as f64 - 1.0)
    } else {
        0.0
    };

    let cal_direction = if cal_change_pct.abs() < 5.0 {
        "stable"
    } else if cal_change_pct > 0.0 {
        "increasing"
    } else {
        "decreasing"
    };

    trends.push(TrendInfo {
        nutrient: "calories".to_string(),
        direction: cal_direction.to_string(),
        change_percent: cal_change_pct,
        is_significant: cal_change_pct.abs() >= 10.0,
        description: format!(
            "Calories are {} ({:.1}% change over period)",
            cal_direction, cal_change_pct
        ),
    });

    let prot_change_pct = if protein.first().map(|&f| f > 0.0).unwrap_or(false) {
        (prot_trend / protein.first().unwrap()) * 100.0 * (protein.len() as f64 - 1.0)
    } else {
        0.0
    };

    let prot_direction = if prot_change_pct.abs() < 5.0 {
        "stable"
    } else if prot_change_pct > 0.0 {
        "increasing"
    } else {
        "decreasing"
    };

    trends.push(TrendInfo {
        nutrient: "protein".to_string(),
        direction: prot_direction.to_string(),
        change_percent: prot_change_pct,
        is_significant: prot_change_pct.abs() >= 10.0,
        description: format!(
            "Protein intake is {} ({:.1}% change over period)",
            prot_direction, prot_change_pct
        ),
    });

    // Generate recommendations
    let mut recommendations = Vec::new();

    // Calorie recommendations
    if let Some(target) = input.calorie_target {
        let diff = avg.calories - target;
        if diff.abs() > 200.0 {
            if diff > 0.0 {
                recommendations.push(format!(
                    "Average calorie intake ({:.0}) is {:.0} above target ({:.0}). Consider reducing portion sizes.",
                    avg.calories, diff, target
                ));
            } else {
                recommendations.push(format!(
                    "Average calorie intake ({:.0}) is {:.0} below target ({:.0}). Consider adding nutrient-dense foods.",
                    avg.calories, diff.abs(), target
                ));
            }
        }
    }

    // Protein recommendations
    if let Some(target) = input.protein_target {
        let diff = avg.protein - target;
        if diff < -10.0 {
            recommendations.push(format!(
                "Average protein ({:.0}g) is below target ({:.0}g). Add more lean protein sources.",
                avg.protein, target
            ));
        }
    }

    // Consistency recommendations
    if std_cal > 500.0 {
        recommendations.push(format!(
            "High calorie variation (σ={:.0}). Try to maintain more consistent daily intake.",
            std_cal
        ));
    }

    // Calculate weekly averages
    let mut weekly_data: HashMap<String, (f64, f64, usize)> = HashMap::new();
    for date in &sorted_dates {
        // Get week of year
        if let Ok(parsed) = chrono::NaiveDate::parse_from_str(date, "%Y-%m-%d") {
            let week = format!("{}-W{:02}", parsed.format("%G"), parsed.format("%V"));
            let (nutrition, _) = &daily_nutrition[date];

            let weekly = weekly_data.entry(week).or_insert((0.0, 0.0, 0));
            weekly.0 += nutrition.calories;
            weekly.1 += nutrition.protein;
            weekly.2 += 1;
        }
    }

    let mut weekly_averages: Vec<WeeklyAverage> = weekly_data
        .into_iter()
        .map(|(week, (cal, prot, days))| WeeklyAverage {
            week,
            avg_calories: cal / days as f64,
            avg_protein: prot / days as f64,
            days_tracked: days,
        })
        .collect();
    weekly_averages.sort_by(|a, b| a.week.cmp(&b.week));

    Ok(Output {
        success: true,
        analysis: AnalysisResult {
            date_range: DateRange {
                start: input.date_range.start,
                end: input.date_range.end,
            },
            days_with_data: days_count,
            daily_average: NutritionSummary {
                calories: avg.calories,
                protein: avg.protein,
                carbohydrates: avg.carbohydrates(),
                fat: avg.fat,
                fiber: avg.fiber,
            },
            total: NutritionSummary {
                calories: total.calories,
                protein: total.protein,
                carbohydrates: total.carbohydrates(),
                fat: total.fat,
                fiber: total.fiber,
            },
            minimum: NutritionSummary {
                calories: min_cal,
                protein: min_prot,
                carbohydrates: 0.0, // TODO: track these
                fat: 0.0,
                fiber: None,
            },
            maximum: NutritionSummary {
                calories: max_cal,
                protein: max_prot,
                carbohydrates: 0.0,
                fat: 0.0,
                fiber: None,
            },
            std_dev: NutritionSummary {
                calories: std_cal,
                protein: std_prot,
                carbohydrates: 0.0,
                fat: 0.0,
                fiber: None,
            },
            trends,
            recommendations,
            daily_data,
            weekly_averages,
        },
    })
}

fn read_input() -> Result<Input, Box<dyn std::error::Error>> {
    if let Some(arg) = std::env::args().nth(1) {
        Ok(serde_json::from_str(&arg)?)
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        Ok(serde_json::from_str(&input_str)?)
    }
}

/// Convert FatSecret date_int back to date string
fn int_to_date(date_int: i64) -> String {
    let days_since_epoch = date_int;
    let epoch = chrono::NaiveDate::from_ymd_opt(1970, 1, 1).expect("Valid date");
    let date = epoch + chrono::Duration::days(days_since_epoch);
    date.format("%Y-%m-%d").to_string()
}

/// Calculate trend (slope) using simple linear regression
fn calculate_trend(values: &[f64]) -> f64 {
    if values.len() < 2 {
        return 0.0;
    }

    let n = values.len() as f64;
    let sum_x: f64 = (0..values.len()).map(|i| i as f64).sum();
    let sum_y: f64 = values.iter().sum();
    let sum_xy: f64 = values.iter().enumerate().map(|(i, &y)| i as f64 * y).sum();
    let sum_xx: f64 = (0..values.len()).map(|i| (i * i) as f64).sum();

    (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_output_serialize() {
        let output = Output {
            success: true,
            analysis: AnalysisResult {
                date_range: DateRange {
                    start: "2025-01-01".to_string(),
                    end: "2025-01-31".to_string(),
                },
                days_with_data: 30,
                daily_average: NutritionSummary {
                    calories: 2000.0,
                    protein: 100.0,
                    carbohydrates: 200.0,
                    fat: 70.0,
                    fiber: Some(25.0),
                },
                total: NutritionSummary {
                    calories: 60000.0,
                    protein: 3000.0,
                    carbohydrates: 6000.0,
                    fat: 2100.0,
                    fiber: Some(750.0),
                },
                minimum: NutritionSummary {
                    calories: 1500.0,
                    protein: 80.0,
                    carbohydrates: 150.0,
                    fat: 50.0,
                    fiber: None,
                },
                maximum: NutritionSummary {
                    calories: 2500.0,
                    protein: 150.0,
                    carbohydrates: 250.0,
                    fat: 90.0,
                    fiber: None,
                },
                std_dev: NutritionSummary {
                    calories: 250.0,
                    protein: 20.0,
                    carbohydrates: 30.0,
                    fat: 15.0,
                    fiber: None,
                },
                trends: vec![],
                recommendations: vec![],
                daily_data: vec![],
                weekly_averages: vec![],
            },
        };
        let json = serde_json::to_string(&output).expect("Failed to serialize");
        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"days_with_data\":30"));
    }

    #[test]
    fn test_calculate_trend_increasing() {
        let values = vec![100.0, 120.0, 140.0, 160.0, 180.0];
        let trend = calculate_trend(&values);
        assert!(trend > 0.0);
    }

    #[test]
    fn test_calculate_trend_decreasing() {
        let values = vec![200.0, 180.0, 160.0, 140.0, 120.0];
        let trend = calculate_trend(&values);
        assert!(trend < 0.0);
    }

    #[test]
    fn test_calculate_trend_stable() {
        let values = vec![100.0, 100.0, 100.0, 100.0];
        let trend = calculate_trend(&values);
        assert!(trend.abs() < 0.01);
    }

    #[test]
    fn test_int_to_date() {
        // 2025-01-01 is day 20089 since 1970-01-01
        let date = int_to_date(20089);
        assert_eq!(date, "2025-01-01");
    }
}

fn print_help() {
    println!(
        r#"analyze_nutrition - Analyze nutrition data from FatSecret diary

USAGE
    echo '{{...}}' | analyze_nutrition
    analyze_nutrition --help
    analyze_nutrition -h
    analyze_nutrition help

    This binary analyzes nutrition data from FatSecret diary entries and provides
    trends, statistics, and recommendations. Part of the Tandoor ↔ FatSecret sync layer.

INPUT SCHEMA
    JSON input via stdin (or first command-line argument):
    {{
        "fatsecret": {{               // Optional: FatSecret credentials
            "consumer_key": "...",     // (if not provided, uses env vars)
            "consumer_secret": "..."
        }},
        "access_token": "...",        // Required: OAuth access token
        "access_secret": "...",       // Required: OAuth access secret
        "date_range": {{              // Required: Date range to analyze
            "start": "2025-01-01",     // Start date (YYYY-MM-DD)
            "end": "2025-01-31"        // End date (YYYY-MM-DD)
        }},
        "analyze": [                  // Optional: Nutrients to analyze
            "calories",                // (defaults to all)
            "protein",
            "carbohydrates",
            "fat"
        ],
        "calorie_target": 2000,       // Optional: Daily calorie target
        "protein_target": 150         // Optional: Daily protein target (g)
    }}

OUTPUT SCHEMA
    Success response (JSON on stdout):
    {{
        "success": true,
        "analysis": {{
            "date_range": {{"start": "2025-01-01", "end": "2025-01-31"}},
            "days_with_data": 31,
            "daily_average": {{"calories": 2100, "protein": 145, ...}},
            "total": {{"calories": 65100, "protein": 4495, ...}},
            "minimum": {{"calories": 1500, ...}},
            "maximum": {{"calories": 2800, ...}},
            "std_dev": {{"calories": 250, ...}},
            "trends": [...],
            "recommendations": [...],
            "daily_data": [...],
            "weekly_averages": [...]
        }}
    }}

    Error response (JSON on stdout):
    {{
        "success": false,
        "error": "Error description"
    }}

EXAMPLES
    1. Analyze last 30 days:
       $ echo '{{"access_token":"token","access_secret":"secret","date_range":{{"start":"2025-01-01","end":"2025-01-31"}}}}' | analyze_nutrition

    2. Analyze with targets:
       $ echo '{{"access_token":"token","access_secret":"secret","date_range":{{"start":"2025-01-01","end":"2025-01-31"}},"calorie_target":2200,"protein_target":160}}' | analyze_nutrition

    3. Display help:
       $ analyze_nutrition --help

EXIT CODES
    0 - Success (analysis completed)
    1 - Error (invalid input, authentication failure, or API error)

NOTES
    - Fetches diary entries for each day in the date range
    - Calculates daily averages, totals, min/max, and standard deviation
    - Provides trend analysis (increasing, decreasing, stable)
    - Generates recommendations based on targets and patterns
    - Weekly averages group data by 7-day periods
"#
    );
}

fn print_schema() {
    use meal_planner::schema::SchemaBuilder;

    let schema = SchemaBuilder::new("analyze_nutrition", env!("CARGO_PKG_VERSION"))
        .description("Analyze nutrition data from FatSecret diary with trends and recommendations")
        .input_schema(serde_json::json!({
            "type": "object",
            "properties": {
                "fatsecret": {
                    "type": "object",
                    "properties": {
                        "consumer_key": {"type": "string"},
                        "consumer_secret": {"type": "string"}
                    }
                },
                "access_token": {"type": "string"},
                "access_secret": {"type": "string"},
                "date_range": {
                    "type": "object",
                    "properties": {
                        "start": {"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$"},
                        "end": {"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$"}
                    },
                    "required": ["start", "end"]
                },
                "calorie_target": {"type": "number"},
                "protein_target": {"type": "number"}
            },
            "required": ["access_token", "access_secret", "date_range"]
        }))
        .output_success_schema(serde_json::json!({
            "type": "object",
            "properties": {
                "success": {"type": "boolean"},
                "analysis": {"type": "object"}
            },
            "required": ["success", "analysis"]
        }))
        .output_error_schema(serde_json::json!({
            "type": "object",
            "properties": {
                "success": {"type": "boolean", "const": false},
                "error": {"type": "string"}
            },
            "required": ["success", "error"]
        }))
        .example(
            "Analyze one month",
            serde_json::json!({
                "access_token": "user_token",
                "access_secret": "user_secret",
                "date_range": {
                    "start": "2025-01-01",
                    "end": "2025-01-31"
                },
                "calorie_target": 2000.0,
                "protein_target": 150.0
            }),
            serde_json::json!({
                "success": true,
                "analysis": {
                    "days_with_data": 30,
                    "daily_average": {
                        "calories": 1950.0,
                        "protein": 145.0
                    }
                }
            })
        )
        .example(
            "Weekly analysis",
            serde_json::json!({
                "access_token": "user_token",
                "access_secret": "user_secret",
                "date_range": {
                    "start": "2025-01-15",
                    "end": "2025-01-22"
                }
            }),
            serde_json::json!({
                "success": true,
                "analysis": {
                    "days_with_data": 7,
                    "daily_average": {
                        "calories": 2100.0,
                        "protein": 160.0
                    }
                }
            })
        )
        .build();

    println!(
        "{}",
        serde_json::to_string_pretty(&schema).expect("Failed to serialize schema")
    );
}
