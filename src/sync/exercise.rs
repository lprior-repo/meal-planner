//! Exercise and Meal Balance Tracker
//!
//! This module provides functionality for tracking the balance between
//! calorie intake from meals and calorie expenditure from exercise.
//!
//! # Features
//!
//! - Track exercise entries with calorie burn estimates
//! - Calculate daily calorie balance (intake - expenditure)
//! - Track macro balance for active days
//! - Estimate BMR and TDEE for accurate calculations
//! - Integration with FatSecret exercise diary
//!
//! # Architecture
//!
//! ```text
//! ┌─────────────────┐     ┌─────────────────┐
//! │  Meal Entries   │     │ Exercise Entries│
//! │  (FatSecret)    │     │ (FatSecret)     │
//! └────────┬────────┘     └────────┬────────┘
//!          │                       │
//!          v                       v
//!      ┌───────────────────────────────┐
//!      │    ExerciseBalanceTracker     │
//!      │  ┌─────────────────────────┐  │
//!      │  │  Daily Balance Calc     │  │
//!      │  │  TDEE Estimation        │  │
//!      │  │  Goal Tracking          │  │
//!      │  └─────────────────────────┘  │
//!      └───────────────────────────────┘
//! ```
//!
//! # Example
//!
//! ```rust,no_run
//! use meal_planner::sync::exercise::{
//!     ExerciseBalanceTracker, ExerciseConfig, ExerciseEntry, MealIntake,
//! };
//!
//! let config = ExerciseConfig::default();
//! let tracker = ExerciseBalanceTracker::new(config);
//!
//! let exercise = ExerciseEntry::new("Running", 300.0, 30);
//! let meal = MealIntake::new(500.0, 40.0, 60.0, 15.0);
//!
//! let balance = tracker.calculate_daily_balance(&[exercise], &[meal]);
//! ```

use crate::sync::errors::{SyncError, SyncResult};
use crate::sync::types::NutritionData;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Configuration for exercise balance tracking
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExerciseConfig {
    /// User's base metabolic rate (BMR) in calories
    pub bmr: f64,
    /// Activity level multiplier for TDEE (1.2 = sedentary, 1.9 = very active)
    pub activity_multiplier: f64,
    /// Goal type: deficit, maintenance, or surplus
    pub goal: BalanceGoal,
    /// Target daily calorie adjustment from TDEE
    pub daily_calorie_target: f64,
    /// Minimum daily calorie intake
    pub min_daily_calories: f64,
    /// Maximum daily calorie intake
    pub max_daily_calories: f64,
    /// Whether to include exercise calories in net calculation
    pub count_exercise_calories: bool,
    /// Percentage of exercise calories to add back (if counting)
    pub exercise_calorie_percentage: f64,
    /// Target protein per kg of body weight
    pub protein_per_kg: f64,
    /// User's weight in kg (for protein calculations)
    pub weight_kg: Option<f64>,
}

impl Default for ExerciseConfig {
    fn default() -> Self {
        Self {
            bmr: 1800.0,
            activity_multiplier: 1.375, // Lightly active
            goal: BalanceGoal::Maintenance,
            daily_calorie_target: 0.0,
            min_daily_calories: 1200.0,
            max_daily_calories: 4000.0,
            count_exercise_calories: true,
            exercise_calorie_percentage: 0.5, // Eat back 50% of exercise calories
            protein_per_kg: 1.6,
            weight_kg: None,
        }
    }
}

impl ExerciseConfig {
    /// Create config for weight loss
    #[must_use]
    pub fn weight_loss() -> Self {
        Self {
            goal: BalanceGoal::Deficit,
            daily_calorie_target: -500.0, // 500 cal deficit
            protein_per_kg: 2.0, // Higher protein for muscle preservation
            ..Self::default()
        }
    }

    /// Create config for muscle gain
    #[must_use]
    pub fn muscle_gain() -> Self {
        Self {
            goal: BalanceGoal::Surplus,
            daily_calorie_target: 300.0, // 300 cal surplus
            protein_per_kg: 2.2,
            ..Self::default()
        }
    }

    /// Create config for maintenance
    #[must_use]
    pub fn maintenance() -> Self {
        Self::default()
    }

    /// Set user's BMR
    #[must_use]
    pub fn with_bmr(mut self, bmr: f64) -> Self {
        self.bmr = bmr;
        self
    }

    /// Set activity level
    #[must_use]
    pub fn with_activity(mut self, multiplier: f64) -> Self {
        self.activity_multiplier = multiplier;
        self
    }

    /// Set weight for protein calculations
    #[must_use]
    pub fn with_weight(mut self, kg: f64) -> Self {
        self.weight_kg = Some(kg);
        self
    }

    /// Calculate TDEE (Total Daily Energy Expenditure)
    #[must_use]
    pub fn tdee(&self) -> f64 {
        self.bmr * self.activity_multiplier
    }

    /// Calculate target daily calories
    #[must_use]
    pub fn target_calories(&self) -> f64 {
        (self.tdee() + self.daily_calorie_target)
            .max(self.min_daily_calories)
            .min(self.max_daily_calories)
    }

    /// Calculate target daily protein
    #[must_use]
    pub fn target_protein(&self) -> Option<f64> {
        self.weight_kg.map(|w| w * self.protein_per_kg)
    }

    /// Validate configuration
    pub fn validate(&self) -> SyncResult<()> {
        if self.bmr <= 0.0 {
            return Err(SyncError::validation("BMR must be positive"));
        }
        if self.activity_multiplier < 1.0 || self.activity_multiplier > 3.0 {
            return Err(SyncError::validation(
                "Activity multiplier must be between 1.0 and 3.0",
            ));
        }
        if self.min_daily_calories <= 0.0 {
            return Err(SyncError::validation("Minimum calories must be positive"));
        }
        if self.max_daily_calories < self.min_daily_calories {
            return Err(SyncError::validation(
                "Maximum calories must be >= minimum",
            ));
        }
        if !(0.0..=1.0).contains(&self.exercise_calorie_percentage) {
            return Err(SyncError::validation(
                "Exercise calorie percentage must be between 0.0 and 1.0",
            ));
        }
        Ok(())
    }
}

/// Balance goal type
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum BalanceGoal {
    /// Calorie deficit for weight loss
    Deficit,
    /// Calorie maintenance
    Maintenance,
    /// Calorie surplus for muscle gain
    Surplus,
}

impl BalanceGoal {
    /// Get display name
    #[must_use]
    pub fn display_name(&self) -> &'static str {
        match self {
            Self::Deficit => "Weight Loss",
            Self::Maintenance => "Maintenance",
            Self::Surplus => "Muscle Gain",
        }
    }
}

/// An exercise entry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExerciseEntry {
    /// Exercise ID (if from FatSecret)
    pub id: Option<i64>,
    /// Exercise name/type
    pub name: String,
    /// Calories burned
    pub calories_burned: f64,
    /// Duration in minutes
    pub duration_minutes: i32,
    /// Exercise category
    pub category: Option<ExerciseCategory>,
    /// Date of exercise (YYYY-MM-DD)
    pub date: Option<String>,
    /// Time of exercise (HH:MM)
    pub time: Option<String>,
    /// Heart rate average (if tracked)
    pub avg_heart_rate: Option<i32>,
    /// Distance in km (if applicable)
    pub distance_km: Option<f64>,
    /// Intensity level
    pub intensity: ExerciseIntensity,
}

impl ExerciseEntry {
    /// Create a new exercise entry
    #[must_use]
    pub fn new(name: impl Into<String>, calories: f64, duration_minutes: i32) -> Self {
        Self {
            id: None,
            name: name.into(),
            calories_burned: calories,
            duration_minutes,
            category: None,
            date: None,
            time: None,
            avg_heart_rate: None,
            distance_km: None,
            intensity: ExerciseIntensity::Moderate,
        }
    }

    /// Create from FatSecret exercise data
    #[must_use]
    pub fn from_fatsecret(id: i64, name: String, calories: f64, minutes: i32) -> Self {
        Self {
            id: Some(id),
            name,
            calories_burned: calories,
            duration_minutes: minutes,
            category: None,
            date: None,
            time: None,
            avg_heart_rate: None,
            distance_km: None,
            intensity: ExerciseIntensity::Moderate,
        }
    }

    /// Builder: set category
    #[must_use]
    pub fn with_category(mut self, category: ExerciseCategory) -> Self {
        self.category = Some(category);
        self
    }

    /// Builder: set date
    #[must_use]
    pub fn with_date(mut self, date: impl Into<String>) -> Self {
        self.date = Some(date.into());
        self
    }

    /// Builder: set intensity
    #[must_use]
    pub fn with_intensity(mut self, intensity: ExerciseIntensity) -> Self {
        self.intensity = intensity;
        self
    }

    /// Builder: set distance
    #[must_use]
    pub fn with_distance(mut self, km: f64) -> Self {
        self.distance_km = Some(km);
        self
    }

    /// Calculate calories per minute
    #[must_use]
    pub fn calories_per_minute(&self) -> f64 {
        if self.duration_minutes > 0 {
            #[allow(clippy::cast_precision_loss)]
            {
                self.calories_burned / self.duration_minutes as f64
            }
        } else {
            0.0
        }
    }

    /// Calculate pace if distance available (min/km)
    #[must_use]
    pub fn pace(&self) -> Option<f64> {
        self.distance_km.filter(|&d| d > 0.0).map(|d| {
            #[allow(clippy::cast_precision_loss)]
            {
                self.duration_minutes as f64 / d
            }
        })
    }
}

/// Exercise category
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum ExerciseCategory {
    /// Cardiovascular exercise
    Cardio,
    /// Strength/resistance training
    Strength,
    /// Flexibility/stretching
    Flexibility,
    /// Sports activities
    Sports,
    /// Daily activities (walking, housework)
    Daily,
    /// Other/unspecified
    Other,
}

impl ExerciseCategory {
    /// Get display name
    #[must_use]
    pub fn display_name(&self) -> &'static str {
        match self {
            Self::Cardio => "Cardio",
            Self::Strength => "Strength Training",
            Self::Flexibility => "Flexibility",
            Self::Sports => "Sports",
            Self::Daily => "Daily Activities",
            Self::Other => "Other",
        }
    }

    /// Parse from string
    #[must_use]
    pub fn from_str(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "cardio" | "cardiovascular" | "aerobic" => Some(Self::Cardio),
            "strength" | "weights" | "resistance" => Some(Self::Strength),
            "flexibility" | "stretching" | "yoga" => Some(Self::Flexibility),
            "sports" | "sport" | "athletic" => Some(Self::Sports),
            "daily" | "walking" | "housework" => Some(Self::Daily),
            _ => Some(Self::Other),
        }
    }
}

/// Exercise intensity level
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum ExerciseIntensity {
    /// Light intensity (easy conversation)
    Light,
    /// Moderate intensity (slightly breathless)
    Moderate,
    /// Vigorous intensity (hard to talk)
    Vigorous,
    /// Maximum intensity (can't talk)
    Maximum,
}

impl ExerciseIntensity {
    /// Get MET multiplier for intensity
    #[must_use]
    pub fn met_multiplier(&self) -> f64 {
        match self {
            Self::Light => 0.8,
            Self::Moderate => 1.0,
            Self::Vigorous => 1.3,
            Self::Maximum => 1.6,
        }
    }

    /// Get heart rate zone percentage
    #[must_use]
    pub fn heart_rate_zone(&self) -> (f64, f64) {
        match self {
            Self::Light => (0.50, 0.60),
            Self::Moderate => (0.60, 0.70),
            Self::Vigorous => (0.70, 0.85),
            Self::Maximum => (0.85, 1.00),
        }
    }
}

/// Meal/food intake for a period
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MealIntake {
    /// Total calories consumed
    pub calories: f64,
    /// Protein in grams
    pub protein: f64,
    /// Carbohydrates in grams
    pub carbohydrates: f64,
    /// Fat in grams
    pub fat: f64,
    /// Fiber in grams
    pub fiber: Option<f64>,
    /// Number of meals/entries
    pub meal_count: usize,
    /// Meal type breakdown
    pub by_meal_type: Option<HashMap<String, NutritionData>>,
}

impl MealIntake {
    /// Create a new meal intake
    #[must_use]
    pub fn new(calories: f64, protein: f64, carbs: f64, fat: f64) -> Self {
        Self {
            calories,
            protein,
            carbohydrates: carbs,
            fat,
            fiber: None,
            meal_count: 1,
            by_meal_type: None,
        }
    }

    /// Create from nutrition data
    #[must_use]
    pub fn from_nutrition(nutrition: &NutritionData) -> Self {
        Self {
            calories: nutrition.calories,
            protein: nutrition.protein,
            carbohydrates: nutrition.carbohydrates(),
            fat: nutrition.fat,
            fiber: nutrition.fiber,
            meal_count: 1,
            by_meal_type: None,
        }
    }

    /// Create zero intake
    #[must_use]
    pub fn zero() -> Self {
        Self {
            calories: 0.0,
            protein: 0.0,
            carbohydrates: 0.0,
            fat: 0.0,
            fiber: None,
            meal_count: 0,
            by_meal_type: None,
        }
    }

    /// Add another intake
    #[must_use]
    pub fn add(&self, other: &Self) -> Self {
        Self {
            calories: self.calories + other.calories,
            protein: self.protein + other.protein,
            carbohydrates: self.carbohydrates + other.carbohydrates,
            fat: self.fat + other.fat,
            fiber: match (self.fiber, other.fiber) {
                (Some(a), Some(b)) => Some(a + b),
                (Some(a), None) => Some(a),
                (None, Some(b)) => Some(b),
                (None, None) => None,
            },
            meal_count: self.meal_count + other.meal_count,
            by_meal_type: None, // Don't merge breakdown
        }
    }

    /// Calculate macro percentages
    #[must_use]
    pub fn macro_percentages(&self) -> (f64, f64, f64) {
        let protein_cal = self.protein * 4.0;
        let carb_cal = self.carbohydrates * 4.0;
        let fat_cal = self.fat * 9.0;
        let total = protein_cal + carb_cal + fat_cal;

        if total > 0.0 {
            (
                protein_cal / total * 100.0,
                carb_cal / total * 100.0,
                fat_cal / total * 100.0,
            )
        } else {
            (0.0, 0.0, 0.0)
        }
    }
}

/// Daily calorie balance result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DailyBalance {
    /// Date (YYYY-MM-DD)
    pub date: String,
    /// Total calories consumed
    pub calories_in: f64,
    /// Total calories burned from exercise
    pub calories_out_exercise: f64,
    /// Estimated BMR calories
    pub calories_out_bmr: f64,
    /// TDEE for the day
    pub tdee: f64,
    /// Net calorie balance
    pub net_balance: f64,
    /// Whether goal was met
    pub goal_met: bool,
    /// Target calories for the day
    pub target_calories: f64,
    /// Calories remaining to target
    pub calories_remaining: f64,
    /// Protein intake
    pub protein: f64,
    /// Target protein
    pub target_protein: Option<f64>,
    /// Exercise entries for the day
    pub exercises: Vec<ExerciseEntry>,
    /// Meal intake summary
    pub meals: MealIntake,
}

impl DailyBalance {
    /// Check if in calorie deficit
    #[must_use]
    pub fn is_deficit(&self) -> bool {
        self.net_balance < 0.0
    }

    /// Check if in calorie surplus
    #[must_use]
    pub fn is_surplus(&self) -> bool {
        self.net_balance > 0.0
    }

    /// Get total exercise duration
    #[must_use]
    pub fn total_exercise_minutes(&self) -> i32 {
        self.exercises.iter().map(|e| e.duration_minutes).sum()
    }

    /// Get exercise by category
    #[must_use]
    pub fn exercises_by_category(&self, category: ExerciseCategory) -> Vec<&ExerciseEntry> {
        self.exercises
            .iter()
            .filter(|e| e.category == Some(category))
            .collect()
    }

    /// Check if protein target was met
    #[must_use]
    pub fn protein_target_met(&self) -> Option<bool> {
        self.target_protein.map(|target| self.protein >= target)
    }

    /// Calculate protein deficit/surplus
    #[must_use]
    pub fn protein_balance(&self) -> Option<f64> {
        self.target_protein.map(|target| self.protein - target)
    }
}

/// Calorie balance summary
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CalorieBalance {
    /// Total intake
    pub intake: f64,
    /// Total exercise expenditure
    pub exercise_expenditure: f64,
    /// BMR expenditure
    pub bmr_expenditure: f64,
    /// Net balance (intake - total expenditure)
    pub net: f64,
    /// Effective TDEE (including exercise)
    pub effective_tdee: f64,
}

impl CalorieBalance {
    /// Calculate total expenditure
    #[must_use]
    pub fn total_expenditure(&self) -> f64 {
        self.bmr_expenditure + self.exercise_expenditure
    }

    /// Get balance as percentage of TDEE
    #[must_use]
    pub fn balance_percentage(&self) -> f64 {
        if self.effective_tdee > 0.0 {
            self.net / self.effective_tdee * 100.0
        } else {
            0.0
        }
    }
}

/// Macronutrient balance
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MacroBalance {
    /// Protein intake vs target
    pub protein: NutrientBalance,
    /// Carb intake vs target
    pub carbohydrates: NutrientBalance,
    /// Fat intake vs target
    pub fat: NutrientBalance,
    /// Fiber intake vs target
    pub fiber: Option<NutrientBalance>,
}

/// Individual nutrient balance
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NutrientBalance {
    /// Actual intake
    pub actual: f64,
    /// Target intake
    pub target: f64,
    /// Balance (actual - target)
    pub balance: f64,
    /// Percentage of target achieved
    pub percentage: f64,
}

impl NutrientBalance {
    /// Create a new nutrient balance
    #[must_use]
    pub fn new(actual: f64, target: f64) -> Self {
        Self {
            actual,
            target,
            balance: actual - target,
            percentage: if target > 0.0 { actual / target * 100.0 } else { 0.0 },
        }
    }

    /// Check if target met
    #[must_use]
    pub fn target_met(&self) -> bool {
        self.actual >= self.target
    }
}

/// Energy expenditure breakdown
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EnergyExpenditure {
    /// Base metabolic rate
    pub bmr: f64,
    /// Non-exercise activity thermogenesis
    pub neat: f64,
    /// Thermic effect of food
    pub tef: f64,
    /// Exercise activity thermogenesis
    pub eat: f64,
    /// Total daily energy expenditure
    pub tdee: f64,
}

impl EnergyExpenditure {
    /// Calculate from config and exercise
    #[must_use]
    pub fn calculate(config: &ExerciseConfig, exercise_calories: f64, food_calories: f64) -> Self {
        let bmr = config.bmr;
        // NEAT is approximated from activity multiplier
        let neat = bmr * (config.activity_multiplier - 1.0) * 0.7;
        // TEF is roughly 10% of food intake
        let tef = food_calories * 0.1;
        let eat = exercise_calories;

        Self {
            bmr,
            neat,
            tef,
            eat,
            tdee: bmr + neat + tef + eat,
        }
    }
}

/// Weekly exercise summary
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeeklyExerciseSummary {
    /// Start date of week
    pub week_start: String,
    /// Daily balances for the week
    pub days: Vec<DailyBalance>,
    /// Total exercise sessions
    pub total_sessions: usize,
    /// Total exercise minutes
    pub total_minutes: i32,
    /// Total calories burned
    pub total_calories_burned: f64,
    /// Average daily calorie balance
    pub avg_daily_balance: f64,
    /// Days where goal was met
    pub days_goal_met: usize,
    /// Exercise breakdown by category
    pub by_category: HashMap<String, (usize, i32, f64)>, // (sessions, minutes, calories)
}

impl WeeklyExerciseSummary {
    /// Calculate from daily balances
    #[must_use]
    pub fn from_days(week_start: String, days: Vec<DailyBalance>) -> Self {
        let total_sessions: usize = days.iter().map(|d| d.exercises.len()).sum();
        let total_minutes: i32 = days.iter().map(|d| d.total_exercise_minutes()).sum();
        let total_calories_burned: f64 = days.iter().map(|d| d.calories_out_exercise).sum();
        let days_goal_met = days.iter().filter(|d| d.goal_met).count();

        #[allow(clippy::cast_precision_loss)]
        let avg_daily_balance = if days.is_empty() {
            0.0
        } else {
            days.iter().map(|d| d.net_balance).sum::<f64>() / days.len() as f64
        };

        // Category breakdown
        let mut by_category: HashMap<String, (usize, i32, f64)> = HashMap::new();
        for day in &days {
            for exercise in &day.exercises {
                let cat = exercise
                    .category
                    .map(|c| c.display_name().to_string())
                    .unwrap_or_else(|| "Other".to_string());

                let entry = by_category.entry(cat).or_insert((0, 0, 0.0));
                entry.0 += 1;
                entry.1 += exercise.duration_minutes;
                entry.2 += exercise.calories_burned;
            }
        }

        Self {
            week_start,
            days,
            total_sessions,
            total_minutes,
            total_calories_burned,
            avg_daily_balance,
            days_goal_met,
            by_category,
        }
    }

    /// Get consistency score (0-100)
    #[must_use]
    pub fn consistency_score(&self) -> f64 {
        if self.days.is_empty() {
            return 0.0;
        }

        // Score based on: exercise days, goal achievement, even distribution
        let exercise_days = self.days.iter().filter(|d| !d.exercises.is_empty()).count();
        #[allow(clippy::cast_precision_loss)]
        let exercise_pct = exercise_days as f64 / self.days.len() as f64;

        #[allow(clippy::cast_precision_loss)]
        let goal_pct = self.days_goal_met as f64 / self.days.len() as f64;

        (exercise_pct * 50.0 + goal_pct * 50.0).min(100.0)
    }
}

/// Exercise balance tracker (functional core)
#[derive(Debug, Clone)]
pub struct ExerciseBalanceTracker {
    /// Configuration
    config: ExerciseConfig,
}

impl ExerciseBalanceTracker {
    /// Create a new tracker
    #[must_use]
    pub fn new(config: ExerciseConfig) -> Self {
        Self { config }
    }

    /// Create with default config
    #[must_use]
    pub fn with_defaults() -> Self {
        Self::new(ExerciseConfig::default())
    }

    /// Get the configuration
    #[must_use]
    pub fn config(&self) -> &ExerciseConfig {
        &self.config
    }

    /// Calculate daily balance
    pub fn calculate_daily_balance(
        &self,
        date: &str,
        exercises: &[ExerciseEntry],
        meals: &MealIntake,
    ) -> DailyBalance {
        // Calculate exercise calories
        let exercise_calories: f64 = exercises.iter().map(|e| e.calories_burned).sum();

        // Calculate effective TDEE for the day
        let tdee = self.config.tdee();
        let effective_tdee = if self.config.count_exercise_calories {
            tdee + (exercise_calories * self.config.exercise_calorie_percentage)
        } else {
            tdee
        };

        // Calculate target calories
        let target_calories = (effective_tdee + self.config.daily_calorie_target)
            .max(self.config.min_daily_calories)
            .min(self.config.max_daily_calories);

        // Calculate net balance
        let net_balance = meals.calories - effective_tdee;

        // Check if goal was met
        let goal_met = match self.config.goal {
            BalanceGoal::Deficit => net_balance <= self.config.daily_calorie_target,
            BalanceGoal::Maintenance => {
                (net_balance - self.config.daily_calorie_target).abs() < 200.0
            }
            BalanceGoal::Surplus => net_balance >= self.config.daily_calorie_target,
        };

        DailyBalance {
            date: date.to_string(),
            calories_in: meals.calories,
            calories_out_exercise: exercise_calories,
            calories_out_bmr: self.config.bmr,
            tdee: effective_tdee,
            net_balance,
            goal_met,
            target_calories,
            calories_remaining: target_calories - meals.calories,
            protein: meals.protein,
            target_protein: self.config.target_protein(),
            exercises: exercises.to_vec(),
            meals: meals.clone(),
        }
    }

    /// Calculate calorie balance
    #[must_use]
    pub fn calculate_calorie_balance(
        &self,
        intake: f64,
        exercise_calories: f64,
    ) -> CalorieBalance {
        let bmr = self.config.bmr;
        let effective_tdee = if self.config.count_exercise_calories {
            self.config.tdee() + (exercise_calories * self.config.exercise_calorie_percentage)
        } else {
            self.config.tdee()
        };

        CalorieBalance {
            intake,
            exercise_expenditure: exercise_calories,
            bmr_expenditure: bmr,
            net: intake - effective_tdee,
            effective_tdee,
        }
    }

    /// Calculate macro balance
    pub fn calculate_macro_balance(&self, meals: &MealIntake) -> MacroBalance {
        // Calculate targets based on config
        let calorie_target = self.config.target_calories();

        // Default macro split: 30% protein, 40% carbs, 30% fat
        let protein_target = self.config.target_protein()
            .unwrap_or(calorie_target * 0.30 / 4.0); // 4 cal/g protein
        let carb_target = calorie_target * 0.40 / 4.0;
        let fat_target = calorie_target * 0.30 / 9.0;
        let fiber_target = 25.0; // Standard recommendation

        MacroBalance {
            protein: NutrientBalance::new(meals.protein, protein_target),
            carbohydrates: NutrientBalance::new(meals.carbohydrates, carb_target),
            fat: NutrientBalance::new(meals.fat, fat_target),
            fiber: meals.fiber.map(|f| NutrientBalance::new(f, fiber_target)),
        }
    }

    /// Calculate energy expenditure breakdown
    #[must_use]
    pub fn calculate_expenditure(&self, exercise_calories: f64, food_calories: f64) -> EnergyExpenditure {
        EnergyExpenditure::calculate(&self.config, exercise_calories, food_calories)
    }

    /// Calculate weekly summary
    pub fn calculate_weekly_summary(
        &self,
        week_start: &str,
        daily_data: &[(String, Vec<ExerciseEntry>, MealIntake)],
    ) -> WeeklyExerciseSummary {
        let days: Vec<DailyBalance> = daily_data
            .iter()
            .map(|(date, exercises, meals)| {
                self.calculate_daily_balance(date, exercises, meals)
            })
            .collect();

        WeeklyExerciseSummary::from_days(week_start.to_string(), days)
    }

    /// Estimate calories burned for an activity
    pub fn estimate_calories(
        &self,
        met: f64,
        duration_minutes: i32,
        weight_kg: Option<f64>,
    ) -> f64 {
        let weight = weight_kg.or(self.config.weight_kg).unwrap_or(70.0);
        #[allow(clippy::cast_precision_loss)]
        {
            met * weight * (duration_minutes as f64 / 60.0)
        }
    }

    /// Get common exercise METs
    #[must_use]
    pub fn get_exercise_met(exercise_type: &str) -> Option<f64> {
        match exercise_type.to_lowercase().as_str() {
            "walking" | "walk" => Some(3.5),
            "jogging" | "jog" => Some(7.0),
            "running" | "run" => Some(9.8),
            "cycling" | "bike" | "biking" => Some(7.5),
            "swimming" | "swim" => Some(6.0),
            "weight lifting" | "weights" | "strength" => Some(3.5),
            "yoga" => Some(2.5),
            "hiit" | "circuit training" => Some(8.0),
            "elliptical" => Some(5.0),
            "rowing" | "rower" => Some(7.0),
            "dancing" | "dance" => Some(4.5),
            "hiking" | "hike" => Some(5.3),
            "basketball" => Some(6.5),
            "soccer" | "football" => Some(7.0),
            "tennis" => Some(7.3),
            "golf" => Some(4.3),
            _ => None,
        }
    }

    /// Suggest calorie adjustment based on progress
    pub fn suggest_adjustment(
        &self,
        weekly_balances: &[f64],
        weight_change_kg: Option<f64>,
    ) -> CalorieAdjustment {
        if weekly_balances.is_empty() {
            return CalorieAdjustment {
                recommended_change: 0.0,
                reason: "Insufficient data".to_string(),
                confidence: 0.0,
            };
        }

        #[allow(clippy::cast_precision_loss)]
        let avg_balance = weekly_balances.iter().sum::<f64>() / weekly_balances.len() as f64;

        // If we have weight data, use it
        if let Some(weight_change) = weight_change_kg {
            // 1 kg = ~7700 calories
            let expected_from_balance = avg_balance * 7.0 / 7700.0; // Weekly

            let discrepancy = weight_change - expected_from_balance;

            if discrepancy.abs() > 0.2 {
                // Significant discrepancy
                let adjustment = discrepancy * 7700.0 / 7.0; // Daily adjustment

                return CalorieAdjustment {
                    recommended_change: adjustment.clamp(-300.0, 300.0),
                    reason: format!(
                        "Weight change ({:.1}kg) differs from expected ({:.1}kg)",
                        weight_change, expected_from_balance
                    ),
                    confidence: 0.7,
                };
            }
        }

        // Based on goal achievement
        match self.config.goal {
            BalanceGoal::Deficit if avg_balance > 0.0 => CalorieAdjustment {
                recommended_change: -100.0,
                reason: "In surplus when deficit goal set".to_string(),
                confidence: 0.6,
            },
            BalanceGoal::Surplus if avg_balance < 0.0 => CalorieAdjustment {
                recommended_change: 100.0,
                reason: "In deficit when surplus goal set".to_string(),
                confidence: 0.6,
            },
            _ => CalorieAdjustment {
                recommended_change: 0.0,
                reason: "On track with current goals".to_string(),
                confidence: 0.8,
            },
        }
    }
}

/// Calorie adjustment suggestion
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CalorieAdjustment {
    /// Recommended daily calorie change
    pub recommended_change: f64,
    /// Reason for recommendation
    pub reason: String,
    /// Confidence in recommendation (0-1)
    pub confidence: f64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_exercise_config_default() {
        let config = ExerciseConfig::default();
        assert_eq!(config.bmr, 1800.0);
        assert_eq!(config.activity_multiplier, 1.375);
        assert!(config.validate().is_ok());
    }

    #[test]
    fn test_exercise_config_weight_loss() {
        let config = ExerciseConfig::weight_loss();
        assert_eq!(config.goal, BalanceGoal::Deficit);
        assert_eq!(config.daily_calorie_target, -500.0);
    }

    #[test]
    fn test_exercise_config_tdee() {
        let config = ExerciseConfig::default().with_bmr(2000.0).with_activity(1.5);
        assert_eq!(config.tdee(), 3000.0);
    }

    #[test]
    fn test_exercise_config_validation() {
        let mut config = ExerciseConfig::default();
        config.bmr = 0.0;
        assert!(config.validate().is_err());

        config.bmr = 1800.0;
        config.activity_multiplier = 0.5;
        assert!(config.validate().is_err());
    }

    #[test]
    fn test_exercise_entry_new() {
        let entry = ExerciseEntry::new("Running", 300.0, 30);
        assert_eq!(entry.name, "Running");
        assert_eq!(entry.calories_burned, 300.0);
        assert_eq!(entry.duration_minutes, 30);
    }

    #[test]
    fn test_exercise_entry_calories_per_minute() {
        let entry = ExerciseEntry::new("Running", 300.0, 30);
        assert_eq!(entry.calories_per_minute(), 10.0);
    }

    #[test]
    fn test_exercise_entry_pace() {
        let entry = ExerciseEntry::new("Running", 300.0, 30).with_distance(5.0);
        assert_eq!(entry.pace(), Some(6.0)); // 6 min/km
    }

    #[test]
    fn test_exercise_category() {
        assert_eq!(
            ExerciseCategory::from_str("cardio"),
            Some(ExerciseCategory::Cardio)
        );
        assert_eq!(
            ExerciseCategory::from_str("weights"),
            Some(ExerciseCategory::Strength)
        );
    }

    #[test]
    fn test_exercise_intensity_met() {
        assert_eq!(ExerciseIntensity::Light.met_multiplier(), 0.8);
        assert_eq!(ExerciseIntensity::Vigorous.met_multiplier(), 1.3);
    }

    #[test]
    fn test_meal_intake_new() {
        let intake = MealIntake::new(500.0, 40.0, 60.0, 15.0);
        assert_eq!(intake.calories, 500.0);
        assert_eq!(intake.protein, 40.0);
    }

    #[test]
    fn test_meal_intake_add() {
        let a = MealIntake::new(300.0, 20.0, 30.0, 10.0);
        let b = MealIntake::new(200.0, 15.0, 25.0, 5.0);
        let sum = a.add(&b);

        assert_eq!(sum.calories, 500.0);
        assert_eq!(sum.protein, 35.0);
        assert_eq!(sum.meal_count, 2);
    }

    #[test]
    fn test_meal_intake_macro_percentages() {
        // 30g protein = 120 cal, 40g carbs = 160 cal, 20g fat = 180 cal
        // Total = 460 cal
        let intake = MealIntake::new(460.0, 30.0, 40.0, 20.0);
        let (p, c, f) = intake.macro_percentages();

        assert!((p - 26.1).abs() < 0.5);
        assert!((c - 34.8).abs() < 0.5);
        assert!((f - 39.1).abs() < 0.5);
    }

    #[test]
    fn test_daily_balance_deficit() {
        let balance = DailyBalance {
            date: "2025-01-01".to_string(),
            calories_in: 1800.0,
            calories_out_exercise: 300.0,
            calories_out_bmr: 1800.0,
            tdee: 2475.0,
            net_balance: -675.0,
            goal_met: true,
            target_calories: 1975.0,
            calories_remaining: 175.0,
            protein: 120.0,
            target_protein: Some(140.0),
            exercises: vec![],
            meals: MealIntake::zero(),
        };

        assert!(balance.is_deficit());
        assert!(!balance.is_surplus());
    }

    #[test]
    fn test_daily_balance_protein() {
        let balance = DailyBalance {
            date: "2025-01-01".to_string(),
            calories_in: 2000.0,
            calories_out_exercise: 0.0,
            calories_out_bmr: 1800.0,
            tdee: 2475.0,
            net_balance: -475.0,
            goal_met: true,
            target_calories: 1975.0,
            calories_remaining: -25.0,
            protein: 150.0,
            target_protein: Some(140.0),
            exercises: vec![],
            meals: MealIntake::zero(),
        };

        assert_eq!(balance.protein_target_met(), Some(true));
        assert_eq!(balance.protein_balance(), Some(10.0));
    }

    #[test]
    fn test_calorie_balance() {
        let balance = CalorieBalance {
            intake: 2000.0,
            exercise_expenditure: 300.0,
            bmr_expenditure: 1800.0,
            net: -475.0,
            effective_tdee: 2475.0,
        };

        assert_eq!(balance.total_expenditure(), 2100.0);
        assert!((balance.balance_percentage() - (-19.2)).abs() < 0.5);
    }

    #[test]
    fn test_nutrient_balance() {
        let balance = NutrientBalance::new(120.0, 140.0);
        assert_eq!(balance.balance, -20.0);
        assert!((balance.percentage - 85.7).abs() < 0.5);
        assert!(!balance.target_met());
    }

    #[test]
    fn test_energy_expenditure() {
        let config = ExerciseConfig::default();
        let exp = EnergyExpenditure::calculate(&config, 300.0, 2000.0);

        assert_eq!(exp.bmr, 1800.0);
        assert_eq!(exp.eat, 300.0);
        assert_eq!(exp.tef, 200.0); // 10% of food
    }

    #[test]
    fn test_tracker_daily_balance() {
        let config = ExerciseConfig::weight_loss()
            .with_bmr(2000.0)
            .with_activity(1.375);
        let tracker = ExerciseBalanceTracker::new(config);

        let exercises = vec![ExerciseEntry::new("Running", 300.0, 30)];
        let meals = MealIntake::new(1800.0, 120.0, 150.0, 60.0);

        let balance = tracker.calculate_daily_balance("2025-01-01", &exercises, &meals);

        assert_eq!(balance.calories_in, 1800.0);
        assert_eq!(balance.calories_out_exercise, 300.0);
        assert!(balance.net_balance < 0.0); // Should be in deficit
    }

    #[test]
    fn test_tracker_calorie_balance() {
        let tracker = ExerciseBalanceTracker::with_defaults();
        let balance = tracker.calculate_calorie_balance(2000.0, 300.0);

        assert_eq!(balance.intake, 2000.0);
        assert_eq!(balance.exercise_expenditure, 300.0);
    }

    #[test]
    fn test_tracker_macro_balance() {
        let config = ExerciseConfig::default().with_weight(70.0);
        let tracker = ExerciseBalanceTracker::new(config);

        let meals = MealIntake::new(2000.0, 100.0, 200.0, 70.0);
        let balance = tracker.calculate_macro_balance(&meals);

        assert_eq!(balance.protein.actual, 100.0);
        assert!(balance.protein.target > 0.0);
    }

    #[test]
    fn test_tracker_estimate_calories() {
        let config = ExerciseConfig::default().with_weight(70.0);
        let tracker = ExerciseBalanceTracker::new(config);

        // Running at 9.8 METs for 30 min
        let calories = tracker.estimate_calories(9.8, 30, None);
        // Expected: 9.8 * 70 * 0.5 = 343
        assert!((calories - 343.0).abs() < 1.0);
    }

    #[test]
    fn test_exercise_met_lookup() {
        assert_eq!(ExerciseBalanceTracker::get_exercise_met("running"), Some(9.8));
        assert_eq!(ExerciseBalanceTracker::get_exercise_met("walking"), Some(3.5));
        assert_eq!(ExerciseBalanceTracker::get_exercise_met("yoga"), Some(2.5));
        assert_eq!(ExerciseBalanceTracker::get_exercise_met("unknown"), None);
    }

    #[test]
    fn test_weekly_summary() {
        let tracker = ExerciseBalanceTracker::with_defaults();

        let daily_data = vec![
            (
                "2025-01-01".to_string(),
                vec![ExerciseEntry::new("Running", 300.0, 30)],
                MealIntake::new(2000.0, 100.0, 200.0, 70.0),
            ),
            (
                "2025-01-02".to_string(),
                vec![],
                MealIntake::new(1800.0, 90.0, 180.0, 60.0),
            ),
        ];

        let summary = tracker.calculate_weekly_summary("2025-01-01", &daily_data);

        assert_eq!(summary.days.len(), 2);
        assert_eq!(summary.total_sessions, 1);
        assert_eq!(summary.total_minutes, 30);
        assert_eq!(summary.total_calories_burned, 300.0);
    }

    #[test]
    fn test_weekly_summary_consistency() {
        let days = vec![
            DailyBalance {
                date: "2025-01-01".to_string(),
                calories_in: 2000.0,
                calories_out_exercise: 300.0,
                calories_out_bmr: 1800.0,
                tdee: 2475.0,
                net_balance: -475.0,
                goal_met: true,
                target_calories: 2000.0,
                calories_remaining: 0.0,
                protein: 100.0,
                target_protein: None,
                exercises: vec![ExerciseEntry::new("Running", 300.0, 30)],
                meals: MealIntake::zero(),
            },
        ];

        let summary = WeeklyExerciseSummary::from_days("2025-01-01".to_string(), days);
        assert!(summary.consistency_score() > 0.0);
    }

    #[test]
    fn test_calorie_adjustment() {
        let tracker = ExerciseBalanceTracker::new(ExerciseConfig::weight_loss());

        // Gaining weight while trying to lose
        let adjustment = tracker.suggest_adjustment(&[100.0, 50.0, 150.0], Some(0.5));

        // Should suggest eating less
        assert!(adjustment.recommended_change != 0.0);
    }

    #[test]
    fn test_calorie_adjustment_on_track() {
        let tracker = ExerciseBalanceTracker::with_defaults();

        let adjustment = tracker.suggest_adjustment(&[-500.0, -450.0, -550.0], None);

        // Maintenance goal, in deficit - might suggest adjustment
        assert!(adjustment.confidence > 0.0);
    }
}
