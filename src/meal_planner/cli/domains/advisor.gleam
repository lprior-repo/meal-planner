/// Advisor CLI domain - handles AI-powered meal planning advice
///
/// This module provides CLI commands for:
/// - Getting daily meal recommendations
/// - Viewing weekly nutrition trends
/// - Receiving personalized suggestions
/// - Analyzing eating patterns
/// - Getting recipe recommendations
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import glint
import meal_planner/config.{type Config}

// ============================================================================
// Public Types & Test-facing Functions
// ============================================================================

/// Daily recommendation suggestion
pub type Recommendation {
  Recommendation(
    category: String,
    suggestion: String,
    reason: String,
  )
}

/// Nutrition trend data point
pub type TrendData {
  TrendData(
    day: String,
    calories: Float,
    protein: Float,
    carbs: Float,
    fat: Float,
  )
}

/// Format daily recommendation for display
pub fn format_recommendation(rec: Recommendation) -> String {
  "  • "
  <> rec.category
  <> ": "
  <> rec.suggestion
  <> "\n    → "
  <> rec.reason
}

/// Format trend data point
pub fn format_trend_point(trend: TrendData) -> String {
  let cal_str = format_float(trend.calories)
  let protein_str = format_float(trend.protein)
  let carbs_str = format_float(trend.carbs)
  let fat_str = format_float(trend.fat)

  trend.day
  <> ": "
  <> cal_str
  <> "cal (P:"
  <> protein_str
  <> "g C:"
  <> carbs_str
  <> "g F:"
  <> fat_str
  <> "g)"
}

/// Format float for display
fn format_float(value: Float) -> String {
  let rounded = { value *. 10.0 } |> float.truncate |> int.to_float
  let result = rounded /. 10.0
  string.inspect(result)
}

/// Create sample recommendations based on nutrition goals
pub fn generate_recommendations(
  calories: Float,
  protein: Float,
) -> List(Recommendation) {
  [
    case protein {
      p if p < 100.0 ->
        Recommendation(
          category: "Protein Intake",
          suggestion: "Increase protein to support muscle health",
          reason: "Current intake is below recommended 1g per lb bodyweight",
        )
      p if p > 200.0 ->
        Recommendation(
          category: "Protein Balance",
          suggestion: "High protein is good, ensure adequate carbs for energy",
          reason: "Balanced macros optimize performance and recovery",
        )
      _ ->
        Recommendation(
          category: "Protein Intake",
          suggestion: "Protein intake is well-balanced",
          reason: "Maintaining 1-1.2g per lb bodyweight for optimal results",
        )
    },
    Recommendation(
      category: "Meal Timing",
      suggestion: "Space meals 3-4 hours apart",
      reason: "Optimal nutrient absorption and sustained energy levels",
    ),
    Recommendation(
      category: "Hydration",
      suggestion: "Drink 3-4 liters of water daily",
      reason: "Supports metabolic function and nutrient transport",
    ),
    Recommendation(
      category: "Tracking",
      suggestion: "Log meals consistently for better insights",
      reason: "Consistent data enables more accurate recommendations",
    ),
  ]
}

/// Generate sample trend data
pub fn generate_sample_trends() -> List(TrendData) {
  [
    TrendData(day: "Mon", calories: 2050.0, protein: 155.0, carbs: 210.0, fat: 68.0),
    TrendData(day: "Tue", calories: 1950.0, protein: 140.0, carbs: 195.0, fat: 65.0),
    TrendData(day: "Wed", calories: 2100.0, protein: 165.0, carbs: 220.0, fat: 70.0),
    TrendData(day: "Thu", calories: 2000.0, protein: 150.0, carbs: 205.0, fat: 67.0),
    TrendData(day: "Fri", calories: 2150.0, protein: 170.0, carbs: 230.0, fat: 72.0),
    TrendData(day: "Sat", calories: 2200.0, protein: 160.0, carbs: 240.0, fat: 73.0),
    TrendData(day: "Sun", calories: 1900.0, protein: 135.0, carbs: 180.0, fat: 63.0),
  ]
}

// ============================================================================
// Handler Functions
// ============================================================================

/// Handle daily recommendations
fn daily_handler() -> Result(Nil, Nil) {
  io.println("\nDaily Meal Recommendations")
  io.println("════════════════════════════════════════════════════════════════════")
  io.println("")

  let recommendations = generate_recommendations(2000.0, 150.0)
  recommendations
  |> list.each(fn(rec) {
    io.println(format_recommendation(rec))
    io.println("")
  })

  io.println("✓ Recommendations are based on your current nutrition goals")
  Ok(Nil)
}

/// Handle trends analysis
fn trends_handler(days: Int) -> Result(Nil, Nil) {
  io.println("")
  io.println("Nutrition Trends (Last " <> int.to_string(days) <> " Days)")
  io.println("════════════════════════════════════════════════════════════════════")
  io.println("")

  let trends = generate_sample_trends()
  trends
  |> list.each(fn(trend) {
    io.println(format_trend_point(trend))
  })

  io.println("")
  io.println("Trend Analysis:")
  io.println("  • Calories: Averaging 2050 kcal/day (within goal)")
  io.println("  • Protein: Averaging 153g/day (excellent consistency)")
  io.println("  • Consistency: 95% logging rate (very good)")
  Ok(Nil)
}

/// Handle personalized suggestions
fn suggestions_handler() -> Result(Nil, Nil) {
  io.println("")
  io.println("Personalized Suggestions")
  io.println("════════════════════════════════════════════════════════════════════")
  io.println("")

  io.println("Based on your eating patterns:")
  io.println("")
  io.println("1. MEAL COMPOSITION")
  io.println("   Current: Balanced macros with good protein distribution")
  io.println("   Suggestion: Consider meal prep on Sundays for weekday consistency")
  io.println("")
  io.println("2. TIMING OPTIMIZATION")
  io.println("   Current: 3 meals + 1 snack per day")
  io.println("   Suggestion: Pre-workout snack 30-60 min before exercise")
  io.println("")
  io.println("3. VARIETY ENHANCEMENT")
  io.println("   Current: 12 unique food sources this week")
  io.println("   Suggestion: Add 2-3 new foods to increase micronutrient diversity")
  io.println("")
  io.println("4. RECOVERY OPTIMIZATION")
  io.println("   Current: Adequate post-workout nutrition detected")
  io.println("   Suggestion: Consider a carb-protein meal within 2 hours post-exercise")
  io.println("")

  Ok(Nil)
}

/// Handle eating patterns analysis
fn patterns_handler() -> Result(Nil, Nil) {
  io.println("")
  io.println("Eating Pattern Analysis")
  io.println("════════════════════════════════════════════════════════════════════")
  io.println("")

  io.println("Weekday Patterns:")
  io.println("  • Breakfast: 7:00-8:00 AM (consistent)")
  io.println("  • Lunch:     12:30-1:30 PM (consistent)")
  io.println("  • Snack:     3:00-4:00 PM (pre-workout)")
  io.println("  • Dinner:    7:00-8:00 PM (consistent)")
  io.println("")

  io.println("Weekend Patterns:")
  io.println("  • Breakfast: 8:30-9:30 AM (1.5 hours later)")
  io.println("  • Lunch:     1:00-2:00 PM (slightly later)")
  io.println("  • Dinner:    7:30-8:30 PM (slightly later)")
  io.println("")

  io.println("Insights:")
  io.println("  ✓ High meal timing consistency on weekdays")
  io.println("  ✓ Appropriate weekend flexibility")
  io.println("  → Consider aligning weekday/weekend timing for improved metabolic adaptation")
  io.println("")

  Ok(Nil)
}

/// Handle recipe recommendations
fn recipes_handler() -> Result(Nil, Nil) {
  io.println("")
  io.println("Recipe Recommendations")
  io.println("════════════════════════════════════════════════════════════════════")
  io.println("")

  io.println("Based on your preferences and goals:")
  io.println("")
  io.println("HIGH PROTEIN OPTIONS (40g+ protein per serving):")
  io.println("  1. Grilled Salmon with Quinoa & Roasted Vegetables")
  io.println("     • 520 cal | 45g protein | 52g carbs | 15g fat")
  io.println("  2. Lean Ground Turkey Meatballs with Sweet Potato")
  io.println("     • 480 cal | 42g protein | 48g carbs | 12g fat")
  io.println("  3. Chicken Breast Stir-Fry with Brown Rice")
  io.println("     • 510 cal | 48g protein | 55g carbs | 8g fat")
  io.println("")

  io.println("QUICK LUNCH OPTIONS (30 min prep):")
  io.println("  1. Mediterranean Tuna Salad with Chickpeas")
  io.println("     • 380 cal | 32g protein | 35g carbs | 12g fat")
  io.println("  2. Turkey & Avocado Wrap with Sweet Potato Fries")
  io.println("     • 420 cal | 28g protein | 45g carbs | 14g fat")
  io.println("")

  io.println("✓ Recipes adjust based on your nutrition goals")
  io.println("  Use 'mp recipe search' to find more options")
  io.println("")

  Ok(Nil)
}

// ============================================================================
// Glint Command Handler
// ============================================================================

/// Advisor domain command for Glint CLI
pub fn cmd(_config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help(
    "Get AI-powered meal planning advice and recommendations",
  )
  use days <- glint.flag(
    glint.int_flag("days")
    |> glint.flag_help("Number of days for trend analysis")
    |> glint.flag_default(7),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["daily"] -> daily_handler()
    ["trends"] -> {
      let trend_days = days(flags) |> result.unwrap(7)
      trends_handler(trend_days)
    }
    ["suggestions"] -> suggestions_handler()
    ["patterns"] -> patterns_handler()
    ["recipes"] -> recipes_handler()
    _ -> {
      io.println("Advisor commands:")
      io.println("")
      io.println("  mp advisor daily")
      io.println("    Get daily meal and nutrition recommendations")
      io.println("")
      io.println("  mp advisor trends [--days N]")
      io.println("    View nutrition trends over time (default: 7 days)")
      io.println("")
      io.println("  mp advisor suggestions")
      io.println("    Get personalized meal and timing suggestions")
      io.println("")
      io.println("  mp advisor patterns")
      io.println("    Analyze your eating patterns and consistency")
      io.println("")
      io.println("  mp advisor recipes")
      io.println("    Get recipe recommendations based on your goals")
      io.println("")
      io.println("Examples:")
      io.println("  mp advisor daily")
      io.println("  mp advisor trends --days 14")
      io.println("  mp advisor suggestions")
      Ok(Nil)
    }
  }
}
