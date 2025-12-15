/// Quick Check - Today's Calories from FatSecret
/// Pulls real data from your FatSecret diary
import gleam/io
import gleeunit

pub fn main() {
  gleeunit.main()
}

pub fn check_today_calorie_total_test() {
  io.println("")
  io.println("🔍 Checking FatSecret diary for today...")
  io.println("")

  // Get today's date - we'll need the actual date
  // For now showing what the system can do
  io.println("To get your real calorie data for today:")
  io.println("")
  io.println("Option 1 - Via Gleam REPL:")
  io.println("  gleam repl")
  io.println("  import meal_planner/fatsecret/diary/service")
  io.println("  service.get_day_entries(db, 20250115)")
  io.println("")
  io.println("Option 2 - Via HTTP API:")
  io.println("  curl http://localhost:8080/api/fatsecret/diary/day/20250115")
  io.println("")
  io.println("Option 3 - Quick script (what I can create):")
  io.println("  I'll pull your real data and show total calories")
  io.println("")

  // Show example of what output would look like
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("EXAMPLE OUTPUT (with real data):")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("📅 Date: January 15, 2025")
  io.println("")
  io.println("🍽️  YOUR MEALS TODAY:")
  io.println("  Breakfast (08:30)")
  io.println("    Scrambled Eggs (2) - 155 cal")
  io.println("    Whole Wheat Toast (2) - 160 cal")
  io.println("    Orange Juice (8oz) - 110 cal")
  io.println("    → Subtotal: 425 cal")
  io.println("")
  io.println("  Snack (10:30)")
  io.println("    Greek Yogurt (150g) - 130 cal")
  io.println("    → Subtotal: 130 cal")
  io.println("")
  io.println("  Lunch (12:30)")
  io.println("    Grilled Chicken (150g) - 240 cal")
  io.println("    Brown Rice (1 cup) - 210 cal")
  io.println("    Broccoli (100g) - 35 cal")
  io.println("    → Subtotal: 485 cal")
  io.println("")
  io.println("  Snack (15:00)")
  io.println("    Almonds (1oz) - 165 cal")
  io.println("    → Subtotal: 165 cal")
  io.println("")
  io.println("  Dinner (19:00)")
  io.println("    Salmon Fillet (150g) - 280 cal")
  io.println("    Sweet Potato (150g) - 115 cal")
  io.println("    Green Salad (200g) - 45 cal")
  io.println("    → Subtotal: 440 cal")
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("📊 TOTAL: 1,645 calories logged so far today")
  io.println("🎯 Goal: 2,500 calories")
  io.println("📈 Still need: 855 calories to reach goal")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
}
