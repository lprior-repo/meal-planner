//! Nutrition Analytics and Reporting
//!
//! This module provides comprehensive analytics for nutrition data including:
//!
//! - Daily and weekly nutrition summaries
//! - Macro ratio analysis
//! - Trend detection and visualization
//! - Goal tracking and comparison
//! - Statistical analysis (averages, variance, etc.)
//!
//! # Analysis Types
//!
//! - **Daily Analysis**: Nutrition breakdown by meal
//! - **Weekly Analysis**: 7-day trends and patterns
//! - **Goal Comparison**: Progress towards nutrition targets
//! - **Trend Analysis**: Identifying patterns over time

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use super::errors::{SyncError, SyncResult};
use super::types::{DiaryEntry, MacroRatio, MealCategory, NutritionData};

// =============================================================================
// CONFIGURATION
// =============================================================================

/// Analytics configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AnalyticsConfig {
    /// Number of days to include in trend analysis
    pub trend_window_days: usize,
    /// Whether to include meal breakdowns
    pub include_meal_breakdown: bool,
    /// Whether to calculate variance
    pub calculate_variance: bool,
    /// Minimum days required for trend analysis
    pub min_days_for_trend: usize,
    /// Whether to track micronutrients
    pub track_micronutrients: bool,
}

impl Default for AnalyticsConfig {
    fn default() -> Self {
        Self {
            trend_window_days: 7,
            include_meal_breakdown: true,
            calculate_variance: true,
            min_days_for_trend: 3,
            track_micronutrients: false,
        }
    }
}

impl AnalyticsConfig {
    /// Validate configuration
    pub fn validate(&self) -> SyncResult<()> {
        if self.trend_window_days == 0 {
            return Err(SyncError::config_invalid(
                "trend_window_days",
                "Must be at least 1",
            ));
        }
        if self.min_days_for_trend == 0 {
            return Err(SyncError::config_invalid(
                "min_days_for_trend",
                "Must be at least 1",
            ));
        }
        Ok(())
    }
}

// =============================================================================
// DAILY ANALYSIS
// =============================================================================

/// Daily nutrition analysis
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DailyAnalysis {
    /// Date analyzed
    pub date: String,
    /// Total nutrition for the day
    pub total: NutritionData,
    /// Macro ratio for the day
    pub macro_ratio: MacroRatio,
    /// Number of entries
    pub entry_count: usize,
    /// Breakdown by meal type
    pub meal_breakdown: HashMap<MealCategory, MealBreakdown>,
    /// Comparison to target (if set)
    pub target_comparison: Option<NutrientComparison>,
}

impl DailyAnalysis {
    /// Create analysis from diary entries
    #[must_use]
    pub fn from_entries(date: &str, entries: &[DiaryEntry]) -> Self {
        let total = entries
            .iter()
            .fold(NutritionData::zero(), |acc, e| acc.add(&e.nutrition));

        let macro_ratio = total.macro_ratio();

        let mut meal_breakdown = HashMap::new();
        for entry in entries {
            meal_breakdown
                .entry(entry.meal)
                .or_insert_with(|| MealBreakdown::new(entry.meal))
                .add_entry(entry);
        }

        Self {
            date: date.to_string(),
            total,
            macro_ratio,
            entry_count: entries.len(),
            meal_breakdown,
            target_comparison: None,
        }
    }

    /// Compare to a target
    #[must_use]
    pub fn with_target(mut self, target: &NutritionData) -> Self {
        self.target_comparison = Some(NutrientComparison::from_actual_target(&self.total, target));
        self
    }

    /// Get meal nutrition
    #[must_use]
    pub fn meal_nutrition(&self, meal: MealCategory) -> Option<&NutritionData> {
        self.meal_breakdown.get(&meal).map(|b| &b.nutrition)
    }

    /// Check if day meets target
    #[must_use]
    pub fn meets_target(&self, tolerance_percent: f64) -> bool {
        self.target_comparison
            .as_ref()
            .map_or(false, |c| c.calories_diff_percent.abs() <= tolerance_percent)
    }
}

/// Breakdown for a single meal
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MealBreakdown {
    /// Meal type
    pub meal: MealCategory,
    /// Total nutrition for this meal
    pub nutrition: NutritionData,
    /// Number of entries
    pub entry_count: usize,
    /// Food names in this meal
    pub foods: Vec<String>,
}

impl MealBreakdown {
    /// Create a new breakdown
    #[must_use]
    pub fn new(meal: MealCategory) -> Self {
        Self {
            meal,
            nutrition: NutritionData::zero(),
            entry_count: 0,
            foods: Vec::new(),
        }
    }

    /// Add an entry to the breakdown
    pub fn add_entry(&mut self, entry: &DiaryEntry) {
        self.nutrition = self.nutrition.add(&entry.nutrition);
        self.entry_count += 1;
        self.foods.push(entry.food_name.clone());
    }
}

// =============================================================================
// WEEKLY ANALYSIS
// =============================================================================

/// Weekly nutrition analysis
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeeklyAnalysis {
    /// Start date
    pub start_date: String,
    /// End date
    pub end_date: String,
    /// Daily analyses
    pub daily: Vec<DailyAnalysis>,
    /// Total for the week
    pub total: NutritionData,
    /// Average per day
    pub daily_average: NutritionData,
    /// Average macro ratio
    pub average_macro_ratio: MacroRatio,
    /// Calorie trend
    pub calorie_trend: NutrientTrend,
    /// Protein trend
    pub protein_trend: NutrientTrend,
    /// Statistical summary
    pub stats: NutritionStats,
}

impl WeeklyAnalysis {
    /// Create from daily analyses
    #[must_use]
    pub fn from_daily(daily: Vec<DailyAnalysis>) -> Self {
        let days_count = daily.len();

        let total = daily
            .iter()
            .fold(NutritionData::zero(), |acc, d| acc.add(&d.total));

        let daily_average = if days_count > 0 {
            total.scale(1.0 / days_count as f64)
        } else {
            NutritionData::zero()
        };

        let average_macro_ratio = daily_average.macro_ratio();

        let calories: Vec<f64> = daily.iter().map(|d| d.total.calories).collect();
        let calorie_trend = NutrientTrend::from_values(&calories, "Calories");

        let proteins: Vec<f64> = daily.iter().map(|d| d.total.protein).collect();
        let protein_trend = NutrientTrend::from_values(&proteins, "Protein");

        let stats = NutritionStats::from_daily(&daily);

        let start_date = daily.first().map_or("", |d| &d.date).to_string();
        let end_date = daily.last().map_or("", |d| &d.date).to_string();

        Self {
            start_date,
            end_date,
            daily,
            total,
            daily_average,
            average_macro_ratio,
            calorie_trend,
            protein_trend,
            stats,
        }
    }

    /// Get the most common meal pattern
    #[must_use]
    pub fn most_common_meal_count(&self) -> usize {
        let mut counts: HashMap<usize, usize> = HashMap::new();
        for day in &self.daily {
            *counts.entry(day.entry_count).or_insert(0) += 1;
        }
        counts
            .into_iter()
            .max_by_key(|(_, count)| *count)
            .map_or(0, |(meal_count, _)| meal_count)
    }

    /// Check if showing consistent patterns
    #[must_use]
    pub fn is_consistent(&self, tolerance_percent: f64) -> bool {
        self.stats.coefficient_of_variation <= tolerance_percent
    }
}

// =============================================================================
// TRENDS
// =============================================================================

/// Trend direction
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum TrendDirection {
    /// Values are increasing
    Increasing,
    /// Values are decreasing
    Decreasing,
    /// Values are stable
    Stable,
    /// Not enough data
    Insufficient,
}

impl Default for TrendDirection {
    fn default() -> Self {
        Self::Insufficient
    }
}

/// Trend analysis for a nutrient
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NutrientTrend {
    /// Nutrient name
    pub nutrient: String,
    /// Trend direction
    pub direction: TrendDirection,
    /// Average value
    pub average: f64,
    /// Minimum value
    pub min: f64,
    /// Maximum value
    pub max: f64,
    /// Trend strength (0-1)
    pub strength: f64,
    /// Percentage change from first to last
    pub percent_change: f64,
    /// Values used for trend
    pub values: Vec<f64>,
}

impl NutrientTrend {
    /// Create from a series of values
    #[must_use]
    pub fn from_values(values: &[f64], nutrient: &str) -> Self {
        if values.is_empty() {
            return Self {
                nutrient: nutrient.to_string(),
                direction: TrendDirection::Insufficient,
                average: 0.0,
                min: 0.0,
                max: 0.0,
                strength: 0.0,
                percent_change: 0.0,
                values: Vec::new(),
            };
        }

        let sum: f64 = values.iter().sum();
        let average = sum / values.len() as f64;

        let min = values.iter().cloned().fold(f64::INFINITY, f64::min);
        let max = values.iter().cloned().fold(f64::NEG_INFINITY, f64::max);

        let (direction, strength, percent_change) = Self::calculate_trend(values);

        Self {
            nutrient: nutrient.to_string(),
            direction,
            average,
            min,
            max,
            strength,
            percent_change,
            values: values.to_vec(),
        }
    }

    /// Calculate trend direction and strength
    fn calculate_trend(values: &[f64]) -> (TrendDirection, f64, f64) {
        if values.len() < 2 {
            return (TrendDirection::Insufficient, 0.0, 0.0);
        }

        let first = values.first().copied().unwrap_or(0.0);
        let last = values.last().copied().unwrap_or(0.0);

        let percent_change = if first > 0.0 {
            ((last - first) / first) * 100.0
        } else {
            0.0
        };

        // Simple linear regression for trend strength
        let n = values.len() as f64;
        let sum_x: f64 = (0..values.len()).map(|i| i as f64).sum();
        let sum_y: f64 = values.iter().sum();
        let sum_xy: f64 = values.iter().enumerate().map(|(i, v)| i as f64 * v).sum();
        let sum_x2: f64 = (0..values.len()).map(|i| (i * i) as f64).sum();

        let denominator = n * sum_x2 - sum_x * sum_x;
        let slope = if denominator != 0.0 {
            (n * sum_xy - sum_x * sum_y) / denominator
        } else {
            0.0
        };

        let avg = sum_y / n;
        let strength = if avg != 0.0 {
            (slope.abs() / avg).min(1.0)
        } else {
            0.0
        };

        let threshold = 0.05; // 5% change is considered stable
        let direction = if percent_change > threshold {
            TrendDirection::Increasing
        } else if percent_change < -threshold {
            TrendDirection::Decreasing
        } else {
            TrendDirection::Stable
        };

        (direction, strength, percent_change)
    }
}

// =============================================================================
// COMPARISON
// =============================================================================

/// Comparison between actual and target nutrition
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NutrientComparison {
    /// Actual nutrition
    pub actual: NutritionData,
    /// Target nutrition
    pub target: NutritionData,
    /// Difference (actual - target)
    pub difference: NutritionData,
    /// Calorie difference as percentage
    pub calories_diff_percent: f64,
    /// Protein difference as percentage
    pub protein_diff_percent: f64,
    /// Fat difference as percentage
    pub fat_diff_percent: f64,
    /// Carb difference as percentage
    pub carb_diff_percent: f64,
    /// Overall score (0-100)
    pub overall_score: f64,
}

impl NutrientComparison {
    /// Create comparison from actual and target
    #[must_use]
    pub fn from_actual_target(actual: &NutritionData, target: &NutritionData) -> Self {
        let difference = NutritionData {
            calories: actual.calories - target.calories,
            protein: actual.protein - target.protein,
            fat: actual.fat - target.fat,
            carbohydrate: actual.carbohydrate - target.carbohydrate,
            fiber: None,
            sugar: None,
            saturated_fat: None,
            monounsaturated_fat: None,
            polyunsaturated_fat: None,
            trans_fat: None,
            cholesterol: None,
            sodium: None,
            potassium: None,
            calcium: None,
            iron: None,
            vitamin_a: None,
            vitamin_c: None,
        };

        let calories_diff_percent = Self::percent_diff(actual.calories, target.calories);
        let protein_diff_percent = Self::percent_diff(actual.protein, target.protein);
        let fat_diff_percent = Self::percent_diff(actual.fat, target.fat);
        let carb_diff_percent = Self::percent_diff(actual.carbohydrate, target.carbohydrate);

        // Overall score: 100 = perfect match, lower = further from target
        let avg_diff = (calories_diff_percent.abs()
            + protein_diff_percent.abs()
            + fat_diff_percent.abs()
            + carb_diff_percent.abs())
            / 4.0;
        let overall_score = (100.0 - avg_diff).max(0.0);

        Self {
            actual: actual.clone(),
            target: target.clone(),
            difference,
            calories_diff_percent,
            protein_diff_percent,
            fat_diff_percent,
            carb_diff_percent,
            overall_score,
        }
    }

    /// Calculate percentage difference
    fn percent_diff(actual: f64, target: f64) -> f64 {
        if target == 0.0 {
            if actual == 0.0 {
                return 0.0;
            }
            return 100.0;
        }
        ((actual - target) / target) * 100.0
    }

    /// Check if actual is under target
    #[must_use]
    pub fn is_under_calories(&self) -> bool {
        self.calories_diff_percent < 0.0
    }

    /// Check if actual is over target
    #[must_use]
    pub fn is_over_calories(&self) -> bool {
        self.calories_diff_percent > 0.0
    }

    /// Get summary status
    #[must_use]
    pub fn status(&self) -> ComparisonStatus {
        if self.overall_score >= 90.0 {
            ComparisonStatus::Excellent
        } else if self.overall_score >= 75.0 {
            ComparisonStatus::Good
        } else if self.overall_score >= 50.0 {
            ComparisonStatus::Fair
        } else {
            ComparisonStatus::Poor
        }
    }
}

/// Status of a nutrition comparison
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum ComparisonStatus {
    /// Very close to target (90%+)
    Excellent,
    /// Close to target (75-90%)
    Good,
    /// Moderately close (50-75%)
    Fair,
    /// Far from target (<50%)
    Poor,
}

// =============================================================================
// STATISTICS
// =============================================================================

/// Statistical summary of nutrition data
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NutritionStats {
    /// Mean calories
    pub mean_calories: f64,
    /// Standard deviation of calories
    pub std_dev_calories: f64,
    /// Coefficient of variation (std_dev / mean * 100)
    pub coefficient_of_variation: f64,
    /// Mean protein
    pub mean_protein: f64,
    /// Mean fat
    pub mean_fat: f64,
    /// Mean carbs
    pub mean_carbs: f64,
    /// Days analyzed
    pub days_analyzed: usize,
}

impl NutritionStats {
    /// Create from daily analyses
    #[must_use]
    pub fn from_daily(daily: &[DailyAnalysis]) -> Self {
        let days_analyzed = daily.len();
        if days_analyzed == 0 {
            return Self::zero();
        }

        let calories: Vec<f64> = daily.iter().map(|d| d.total.calories).collect();
        let proteins: Vec<f64> = daily.iter().map(|d| d.total.protein).collect();
        let fats: Vec<f64> = daily.iter().map(|d| d.total.fat).collect();
        let carbs: Vec<f64> = daily.iter().map(|d| d.total.carbohydrate).collect();

        let mean_calories = Self::mean(&calories);
        let std_dev_calories = Self::std_dev(&calories, mean_calories);
        let coefficient_of_variation = if mean_calories > 0.0 {
            (std_dev_calories / mean_calories) * 100.0
        } else {
            0.0
        };

        Self {
            mean_calories,
            std_dev_calories,
            coefficient_of_variation,
            mean_protein: Self::mean(&proteins),
            mean_fat: Self::mean(&fats),
            mean_carbs: Self::mean(&carbs),
            days_analyzed,
        }
    }

    /// Create zero stats
    #[must_use]
    pub fn zero() -> Self {
        Self {
            mean_calories: 0.0,
            std_dev_calories: 0.0,
            coefficient_of_variation: 0.0,
            mean_protein: 0.0,
            mean_fat: 0.0,
            mean_carbs: 0.0,
            days_analyzed: 0,
        }
    }

    /// Calculate mean
    fn mean(values: &[f64]) -> f64 {
        if values.is_empty() {
            return 0.0;
        }
        values.iter().sum::<f64>() / values.len() as f64
    }

    /// Calculate standard deviation
    fn std_dev(values: &[f64], mean: f64) -> f64 {
        if values.len() < 2 {
            return 0.0;
        }
        let variance: f64 = values.iter().map(|v| (v - mean).powi(2)).sum::<f64>()
            / (values.len() - 1) as f64;
        variance.sqrt()
    }
}

// =============================================================================
// NUTRITION ANALYZER
// =============================================================================

/// Service for analyzing nutrition data
#[derive(Debug, Clone)]
pub struct NutritionAnalyzer {
    config: AnalyticsConfig,
}

impl NutritionAnalyzer {
    /// Create a new analyzer
    #[must_use]
    pub fn new(config: AnalyticsConfig) -> Self {
        Self { config }
    }

    /// Create with default config
    #[must_use]
    pub fn with_defaults() -> Self {
        Self::new(AnalyticsConfig::default())
    }

    /// Analyze a single day
    #[must_use]
    pub fn analyze_day(&self, date: &str, entries: &[DiaryEntry]) -> DailyAnalysis {
        DailyAnalysis::from_entries(date, entries)
    }

    /// Analyze a week
    #[must_use]
    pub fn analyze_week(&self, daily: Vec<DailyAnalysis>) -> WeeklyAnalysis {
        WeeklyAnalysis::from_daily(daily)
    }

    /// Analyze multiple days
    #[must_use]
    pub fn analyze_days(&self, entries: &[DiaryEntry]) -> Vec<DailyAnalysis> {
        let mut by_date: HashMap<String, Vec<&DiaryEntry>> = HashMap::new();

        for entry in entries {
            by_date
                .entry(entry.date.clone())
                .or_default()
                .push(entry);
        }

        let mut analyses: Vec<DailyAnalysis> = by_date
            .into_iter()
            .map(|(date, day_entries)| {
                let owned: Vec<DiaryEntry> = day_entries.into_iter().cloned().collect();
                DailyAnalysis::from_entries(&date, &owned)
            })
            .collect();

        analyses.sort_by(|a, b| a.date.cmp(&b.date));
        analyses
    }

    /// Compare to targets
    #[must_use]
    pub fn compare_to_target(
        &self,
        analysis: &DailyAnalysis,
        target: &NutritionData,
    ) -> NutrientComparison {
        NutrientComparison::from_actual_target(&analysis.total, target)
    }

    /// Get trending nutrients
    #[must_use]
    pub fn analyze_trends(&self, daily: &[DailyAnalysis]) -> Vec<NutrientTrend> {
        if daily.len() < self.config.min_days_for_trend {
            return Vec::new();
        }

        let calories: Vec<f64> = daily.iter().map(|d| d.total.calories).collect();
        let proteins: Vec<f64> = daily.iter().map(|d| d.total.protein).collect();
        let fats: Vec<f64> = daily.iter().map(|d| d.total.fat).collect();
        let carbs: Vec<f64> = daily.iter().map(|d| d.total.carbohydrate).collect();

        vec![
            NutrientTrend::from_values(&calories, "Calories"),
            NutrientTrend::from_values(&proteins, "Protein"),
            NutrientTrend::from_values(&fats, "Fat"),
            NutrientTrend::from_values(&carbs, "Carbohydrate"),
        ]
    }
}

impl Default for NutritionAnalyzer {
    fn default() -> Self {
        Self::with_defaults()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::sync::types::DiaryEntrySource;

    fn create_entry(date: &str, meal: MealCategory, calories: f64) -> DiaryEntry {
        DiaryEntry {
            entry_id: None,
            date: date.to_string(),
            meal,
            food_name: "Test Food".to_string(),
            serving_description: "1 serving".to_string(),
            servings: 1.0,
            nutrition: NutritionData::macros_only(calories, calories / 10.0, calories / 20.0, calories / 5.0),
            source: DiaryEntrySource::Manual,
        }
    }

    #[test]
    fn test_daily_analysis() {
        let entries = vec![
            create_entry("2025-01-15", MealCategory::Breakfast, 300.0),
            create_entry("2025-01-15", MealCategory::Lunch, 500.0),
            create_entry("2025-01-15", MealCategory::Dinner, 700.0),
        ];

        let analysis = DailyAnalysis::from_entries("2025-01-15", &entries);

        assert_eq!(analysis.date, "2025-01-15");
        assert_eq!(analysis.entry_count, 3);
        assert!((analysis.total.calories - 1500.0).abs() < 0.01);
        assert_eq!(analysis.meal_breakdown.len(), 3);
    }

    #[test]
    fn test_weekly_analysis() {
        let daily: Vec<DailyAnalysis> = (1..=7)
            .map(|day| {
                let date = format!("2025-01-{:02}", day);
                let entries = vec![create_entry(&date, MealCategory::Dinner, 2000.0)];
                DailyAnalysis::from_entries(&date, &entries)
            })
            .collect();

        let weekly = WeeklyAnalysis::from_daily(daily);

        assert_eq!(weekly.daily.len(), 7);
        assert!((weekly.total.calories - 14000.0).abs() < 0.01);
        assert!((weekly.daily_average.calories - 2000.0).abs() < 0.01);
    }

    #[test]
    fn test_nutrient_trend_increasing() {
        let values = vec![100.0, 120.0, 140.0, 160.0, 180.0];
        let trend = NutrientTrend::from_values(&values, "Test");

        assert_eq!(trend.direction, TrendDirection::Increasing);
        assert!(trend.percent_change > 0.0);
        assert!((trend.average - 140.0).abs() < 0.01);
    }

    #[test]
    fn test_nutrient_trend_decreasing() {
        let values = vec![200.0, 180.0, 160.0, 140.0, 120.0];
        let trend = NutrientTrend::from_values(&values, "Test");

        assert_eq!(trend.direction, TrendDirection::Decreasing);
        assert!(trend.percent_change < 0.0);
    }

    #[test]
    fn test_nutrient_trend_stable() {
        let values = vec![100.0, 101.0, 99.0, 100.0, 100.0];
        let trend = NutrientTrend::from_values(&values, "Test");

        assert_eq!(trend.direction, TrendDirection::Stable);
    }

    #[test]
    fn test_nutrient_comparison() {
        let actual = NutritionData::macros_only(2000.0, 100.0, 80.0, 200.0);
        let target = NutritionData::macros_only(2000.0, 100.0, 80.0, 200.0);

        let comparison = NutrientComparison::from_actual_target(&actual, &target);

        assert!((comparison.calories_diff_percent - 0.0).abs() < 0.01);
        assert!((comparison.overall_score - 100.0).abs() < 0.01);
        assert_eq!(comparison.status(), ComparisonStatus::Excellent);
    }

    #[test]
    fn test_nutrient_comparison_off_target() {
        let actual = NutritionData::macros_only(2500.0, 120.0, 100.0, 250.0);
        let target = NutritionData::macros_only(2000.0, 100.0, 80.0, 200.0);

        let comparison = NutrientComparison::from_actual_target(&actual, &target);

        assert!((comparison.calories_diff_percent - 25.0).abs() < 0.01);
        assert!(comparison.is_over_calories());
        assert!(comparison.overall_score < 100.0);
    }

    #[test]
    fn test_nutrition_stats() {
        let daily: Vec<DailyAnalysis> = vec![
            DailyAnalysis::from_entries("2025-01-01", &[create_entry("2025-01-01", MealCategory::Dinner, 1800.0)]),
            DailyAnalysis::from_entries("2025-01-02", &[create_entry("2025-01-02", MealCategory::Dinner, 2000.0)]),
            DailyAnalysis::from_entries("2025-01-03", &[create_entry("2025-01-03", MealCategory::Dinner, 2200.0)]),
        ];

        let stats = NutritionStats::from_daily(&daily);

        assert!((stats.mean_calories - 2000.0).abs() < 0.01);
        assert!(stats.std_dev_calories > 0.0);
        assert_eq!(stats.days_analyzed, 3);
    }

    #[test]
    fn test_analyzer() {
        let analyzer = NutritionAnalyzer::with_defaults();

        let entries = vec![
            create_entry("2025-01-15", MealCategory::Breakfast, 400.0),
            create_entry("2025-01-15", MealCategory::Lunch, 600.0),
            create_entry("2025-01-16", MealCategory::Dinner, 800.0),
        ];

        let analyses = analyzer.analyze_days(&entries);
        assert_eq!(analyses.len(), 2);

        let target = NutritionData::macros_only(1000.0, 50.0, 40.0, 100.0);
        let comparison = analyzer.compare_to_target(&analyses[0], &target);
        assert!(comparison.overall_score > 0.0);
    }

    #[test]
    fn test_config_validation() {
        let valid = AnalyticsConfig::default();
        assert!(valid.validate().is_ok());

        let invalid = AnalyticsConfig {
            trend_window_days: 0,
            ..AnalyticsConfig::default()
        };
        assert!(invalid.validate().is_err());
    }
}
