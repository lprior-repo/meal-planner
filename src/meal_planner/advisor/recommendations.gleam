/// Meal adjustment recommendations based on weekly nutrition trends
///
/// This module generates actionable meal planning recommendations by:
/// - Analyzing weekly nutrition trends
/// - Identifying macro deficiencies/overages
/// - Suggesting specific meal adjustments
/// - Generating insights for future planning
import gleam/float
import gleam/int
import gleam/list
import meal_planner/advisor/weekly_trends.{
  type NutritionTargets, type WeeklyTrends,
}

// ============================================================================
// Types
// ============================================================================

/// Complete recommendation report
pub type RecommendationReport {
  RecommendationReport(
    /// Weekly trends analyzed
    trends: WeeklyTrends,
    /// Specific meal adjustments to make
    meal_adjustments: List(MealAdjustment),
    /// Actionable insights for next week
    insights: List(Insight),
    /// Overall compliance score (0-100)
    compliance_score: Float,
  )
}

/// Specific meal adjustment suggestion
pub type MealAdjustment {
  MealAdjustment(
    /// Which nutrient to adjust (protein, carbs, fat, calories)
    nutrient: String,
    /// Increase or Decrease
    adjustment_type: AdjustmentType,
    /// Amount to adjust (grams or calories)
    amount: Float,
    /// Specific food suggestions
    food_suggestions: List(String),
    /// Priority level (1-5, 5 highest)
    priority: Int,
  )
}

/// Type of adjustment needed
pub type AdjustmentType {
  Increase
  Decrease
  Maintain
}

/// Nutrition insight
pub type Insight {
  Insight(
    /// Insight category
    category: InsightCategory,
    /// Insight message
    message: String,
    /// Impact level (Low, Medium, High)
    impact: ImpactLevel,
  )
}

/// Category of insight
pub type InsightCategory {
  MacroBalance
  ConsistencyPattern
  ProgressTracking
  Warning
  Congratulation
}

/// Impact level of insight
pub type ImpactLevel {
  Low
  Medium
  High
}

// ============================================================================
// Main Function
// ============================================================================

/// Generate complete recommendation report from weekly trends
///
/// Parameters:
/// - trends: Weekly trends analysis from weekly_trends module
/// - targets: User nutrition targets
///
/// Returns:
/// - RecommendationReport with adjustments and insights
pub fn generate_recommendations(
  trends: WeeklyTrends,
  targets: NutritionTargets,
) -> RecommendationReport {
  // Generate meal adjustments based on patterns
  let meal_adjustments = generate_meal_adjustments(trends, targets)

  // Generate insights from trends and patterns
  let insights = generate_insights(trends, targets)

  // Calculate overall compliance score
  let compliance_score = calculate_compliance_score(trends, targets)

  RecommendationReport(
    trends: trends,
    meal_adjustments: meal_adjustments,
    insights: insights,
    compliance_score: compliance_score,
  )
}

// ============================================================================
// Meal Adjustment Generation
// ============================================================================

/// Generate specific meal adjustments based on weekly trends
fn generate_meal_adjustments(
  trends: WeeklyTrends,
  targets: NutritionTargets,
) -> List(MealAdjustment) {
  []
  |> add_protein_adjustment(trends, targets)
  |> add_carbs_adjustment(trends, targets)
  |> add_fat_adjustment(trends, targets)
  |> add_calorie_adjustment(trends, targets)
  |> prioritize_adjustments
}

/// Add protein adjustment if needed
fn add_protein_adjustment(
  adjustments: List(MealAdjustment),
  trends: WeeklyTrends,
  targets: NutritionTargets,
) -> List(MealAdjustment) {
  let diff = trends.avg_protein -. targets.daily_protein
  let percent_diff = diff /. targets.daily_protein *. 100.0

  case percent_diff {
    p if p <. -10.0 -> {
      let deficit = float.absolute_value(diff)
      [
        MealAdjustment(
          nutrient: "protein",
          adjustment_type: Increase,
          amount: deficit,
          food_suggestions: [
            "Lean chicken breast (31g per 100g)",
            "Greek yogurt (10g per 100g)",
            "Eggs (6g per egg)",
            "Protein shake (20-30g per serving)",
            "Cottage cheese (11g per 100g)",
          ],
          priority: 5,
        ),
        ..adjustments
      ]
    }
    p if p >. 15.0 -> {
      let excess = diff
      [
        MealAdjustment(
          nutrient: "protein",
          adjustment_type: Decrease,
          amount: excess,
          food_suggestions: [
            "Reduce portion sizes of meat/poultry",
            "Replace one protein shake with fruit",
          ],
          priority: 2,
        ),
        ..adjustments
      ]
    }
    _ -> adjustments
  }
}

/// Add carbs adjustment if needed
fn add_carbs_adjustment(
  adjustments: List(MealAdjustment),
  trends: WeeklyTrends,
  targets: NutritionTargets,
) -> List(MealAdjustment) {
  let diff = trends.avg_carbs -. targets.daily_carbs
  let percent_diff = diff /. targets.daily_carbs *. 100.0

  case percent_diff {
    p if p <. -10.0 -> {
      let deficit = float.absolute_value(diff)
      [
        MealAdjustment(
          nutrient: "carbs",
          adjustment_type: Increase,
          amount: deficit,
          food_suggestions: [
            "Brown rice (23g per 100g cooked)",
            "Sweet potato (20g per 100g)",
            "Oatmeal (12g per 100g cooked)",
            "Whole wheat bread (40g per slice)",
            "Quinoa (21g per 100g cooked)",
          ],
          priority: 4,
        ),
        ..adjustments
      ]
    }
    p if p >. 15.0 -> {
      let excess = diff
      [
        MealAdjustment(
          nutrient: "carbs",
          adjustment_type: Decrease,
          amount: excess,
          food_suggestions: [
            "Reduce rice/pasta portions by 1/3",
            "Replace refined carbs with vegetables",
            "Limit bread to 1-2 slices per day",
          ],
          priority: 4,
        ),
        ..adjustments
      ]
    }
    _ -> adjustments
  }
}

/// Add fat adjustment if needed
fn add_fat_adjustment(
  adjustments: List(MealAdjustment),
  trends: WeeklyTrends,
  targets: NutritionTargets,
) -> List(MealAdjustment) {
  let diff = trends.avg_fat -. targets.daily_fat
  let percent_diff = diff /. targets.daily_fat *. 100.0

  case percent_diff {
    p if p <. -10.0 -> {
      let deficit = float.absolute_value(diff)
      [
        MealAdjustment(
          nutrient: "fat",
          adjustment_type: Increase,
          amount: deficit,
          food_suggestions: [
            "Avocado (15g per 100g)",
            "Olive oil (14g per tablespoon)",
            "Almonds (14g per 28g)",
            "Salmon (13g per 100g)",
            "Peanut butter (16g per 2 tbsp)",
          ],
          priority: 3,
        ),
        ..adjustments
      ]
    }
    p if p >. 15.0 -> {
      let excess = diff
      [
        MealAdjustment(
          nutrient: "fat",
          adjustment_type: Decrease,
          amount: excess,
          food_suggestions: [
            "Use cooking spray instead of oil",
            "Choose lean cuts of meat",
            "Limit nuts to 1 serving per day",
          ],
          priority: 3,
        ),
        ..adjustments
      ]
    }
    _ -> adjustments
  }
}

/// Add calorie adjustment if needed
fn add_calorie_adjustment(
  adjustments: List(MealAdjustment),
  trends: WeeklyTrends,
  targets: NutritionTargets,
) -> List(MealAdjustment) {
  let diff = trends.avg_calories -. targets.daily_calories
  let percent_diff = diff /. targets.daily_calories *. 100.0

  case percent_diff {
    p if p <. -10.0 -> {
      let deficit = float.absolute_value(diff)
      [
        MealAdjustment(
          nutrient: "calories",
          adjustment_type: Increase,
          amount: deficit,
          food_suggestions: [
            "Add healthy snacks between meals",
            "Increase portion sizes by 10-15%",
            "Add calorie-dense foods like nuts or dried fruit",
          ],
          priority: 5,
        ),
        ..adjustments
      ]
    }
    p if p >. 15.0 -> {
      let excess = diff
      [
        MealAdjustment(
          nutrient: "calories",
          adjustment_type: Decrease,
          amount: excess,
          food_suggestions: [
            "Reduce portion sizes by 10-15%",
            "Replace high-calorie snacks with vegetables",
            "Drink water instead of caloric beverages",
          ],
          priority: 5,
        ),
        ..adjustments
      ]
    }
    _ -> adjustments
  }
}

/// Prioritize adjustments by impact and urgency
fn prioritize_adjustments(
  adjustments: List(MealAdjustment),
) -> List(MealAdjustment) {
  list.sort(adjustments, fn(a, b) {
    // Sort by priority descending (5 = highest)
    int.compare(b.priority, a.priority)
  })
}

// ============================================================================
// Insight Generation
// ============================================================================

/// Generate insights from weekly trends
fn generate_insights(
  trends: WeeklyTrends,
  targets: NutritionTargets,
) -> List(Insight) {
  []
  |> add_macro_balance_insights(trends, targets)
  |> add_consistency_insights(trends)
  |> add_progress_insights(trends, targets)
  |> add_warning_insights(trends, targets)
  |> add_congratulation_insights(trends, targets)
}

/// Add macro balance insights
fn add_macro_balance_insights(
  insights: List(Insight),
  trends: WeeklyTrends,
  targets: NutritionTargets,
) -> List(Insight) {
  let protein_ratio = trends.avg_protein /. targets.daily_protein
  let carbs_ratio = trends.avg_carbs /. targets.daily_carbs
  let fat_ratio = trends.avg_fat /. targets.daily_fat

  case protein_ratio, carbs_ratio, fat_ratio {
    p, c, f
      if p >. 0.85
      && p <. 1.15
      && c >. 0.85
      && c <. 1.15
      && f >. 0.85
      && f <. 1.15
    -> [
      Insight(
        category: MacroBalance,
        message: "Excellent macro balance! All nutrients are within target ranges.",
        impact: High,
      ),
      ..insights
    ]
    _, _, _ ->
      case list.length(trends.patterns) {
        0 -> insights
        1 -> [
          Insight(
            category: MacroBalance,
            message: "Minor macro imbalance detected. Focus on one adjustment this week.",
            impact: Low,
          ),
          ..insights
        ]
        count if count >= 3 -> [
          Insight(
            category: MacroBalance,
            message: "Multiple macro imbalances. Prioritize highest-impact adjustments first.",
            impact: High,
          ),
          ..insights
        ]
        _ -> [
          Insight(
            category: MacroBalance,
            message: "Some macro adjustments needed. Review recommendations below.",
            impact: Medium,
          ),
          ..insights
        ]
      }
  }
}

/// Add consistency insights
fn add_consistency_insights(
  insights: List(Insight),
  trends: WeeklyTrends,
) -> List(Insight) {
  case trends.days_analyzed {
    7 -> [
      Insight(
        category: ConsistencyPattern,
        message: "Great consistency! You logged all 7 days this week.",
        impact: High,
      ),
      ..insights
    ]
    days if days >= 5 -> [
      Insight(
        category: ConsistencyPattern,
        message: "Good tracking consistency. Try to log every day next week.",
        impact: Medium,
      ),
      ..insights
    ]
    days if days < 5 -> [
      Insight(
        category: ConsistencyPattern,
        message: "Inconsistent tracking detected. More data yields better recommendations.",
        impact: Medium,
      ),
      ..insights
    ]
    _ -> insights
  }
}

/// Add progress tracking insights
fn add_progress_insights(
  insights: List(Insight),
  trends: WeeklyTrends,
  targets: NutritionTargets,
) -> List(Insight) {
  let best_day = trends.best_day
  let worst_day = trends.worst_day

  case best_day, worst_day {
    "", "" -> insights
    best, worst if best != "" && worst != "" -> [
      Insight(
        category: ProgressTracking,
        message: "Best day: "
          <> best
          <> ". Worst day: "
          <> worst
          <> ". Review patterns to understand differences.",
        impact: Medium,
      ),
      ..insights
    ]
    _, _ -> insights
  }
}

/// Add warning insights
fn add_warning_insights(
  insights: List(Insight),
  trends: WeeklyTrends,
  targets: NutritionTargets,
) -> List(Insight) {
  let calorie_deficit = targets.daily_calories -. trends.avg_calories
  let calorie_surplus = trends.avg_calories -. targets.daily_calories

  case calorie_deficit, calorie_surplus {
    deficit, _ if deficit >. 500.0 -> [
      Insight(
        category: Warning,
        message: "Large calorie deficit detected. Ensure adequate nutrition for health and energy.",
        impact: High,
      ),
      ..insights
    ]
    _, surplus if surplus >. 500.0 -> [
      Insight(
        category: Warning,
        message: "Large calorie surplus detected. Consider reducing portions or increasing activity.",
        impact: High,
      ),
      ..insights
    ]
    _, _ -> insights
  }
}

/// Add congratulation insights
fn add_congratulation_insights(
  insights: List(Insight),
  trends: WeeklyTrends,
  targets: NutritionTargets,
) -> List(Insight) {
  let compliance = calculate_compliance_score(trends, targets)

  case compliance {
    score if score >. 90.0 -> [
      Insight(
        category: Congratulation,
        message: "Outstanding nutrition adherence! Keep up the excellent work.",
        impact: High,
      ),
      ..insights
    ]
    score if score >. 80.0 -> [
      Insight(
        category: Congratulation,
        message: "Great nutrition consistency. Small adjustments will push you to excellence.",
        impact: Medium,
      ),
      ..insights
    ]
    _ -> insights
  }
}

// ============================================================================
// Compliance Scoring
// ============================================================================

/// Calculate overall compliance score (0-100)
///
/// Based on how close average macros are to targets:
/// - 100 = perfect adherence
/// - 80-100 = excellent
/// - 60-80 = good
/// - 40-60 = needs improvement
/// - <40 = significant adjustments needed
fn calculate_compliance_score(
  trends: WeeklyTrends,
  targets: NutritionTargets,
) -> Float {
  let protein_score =
    calculate_macro_compliance(trends.avg_protein, targets.daily_protein)
  let carbs_score =
    calculate_macro_compliance(trends.avg_carbs, targets.daily_carbs)
  let fat_score = calculate_macro_compliance(trends.avg_fat, targets.daily_fat)
  let calorie_score =
    calculate_macro_compliance(trends.avg_calories, targets.daily_calories)

  // Average all scores, weight calories slightly higher
  let total =
    protein_score +. carbs_score +. fat_score +. { calorie_score *. 1.5 }
  let count = 4.5

  total /. count
}

/// Calculate compliance score for a single macro
///
/// Returns 0-100 based on percentage deviation from target
fn calculate_macro_compliance(actual: Float, target: Float) -> Float {
  let diff = float.absolute_value(actual -. target)
  let percent_diff = diff /. target *. 100.0

  case percent_diff {
    p if p <. 5.0 -> 100.0
    p if p <. 10.0 -> 95.0
    p if p <. 15.0 -> 85.0
    p if p <. 20.0 -> 75.0
    p if p <. 25.0 -> 65.0
    p if p <. 30.0 -> 55.0
    p if p <. 40.0 -> 40.0
    p if p <. 50.0 -> 25.0
    _ -> 0.0
  }
}

// ============================================================================
// Formatting Helpers
// ============================================================================

/// Format adjustment type as string
pub fn adjustment_type_to_string(adjustment_type: AdjustmentType) -> String {
  case adjustment_type {
    Increase -> "Increase"
    Decrease -> "Decrease"
    Maintain -> "Maintain"
  }
}

/// Format impact level as string
pub fn impact_level_to_string(impact: ImpactLevel) -> String {
  case impact {
    Low -> "Low"
    Medium -> "Medium"
    High -> "High"
  }
}

/// Format insight category as string
pub fn insight_category_to_string(category: InsightCategory) -> String {
  case category {
    MacroBalance -> "Macro Balance"
    ConsistencyPattern -> "Consistency"
    ProgressTracking -> "Progress"
    Warning -> "Warning"
    Congratulation -> "Congratulation"
  }
}
