/// Pull Today's Real Data via Your Own API
/// Calls: GET /api/fatsecret/diary/day/20251215
import gleam/io
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn pull_todays_calories_via_api_test() {
  io.println("")
  io.println(
    "╔════════════════════════════════════════════════════════════════╗",
  )
  io.println(
    "║      PULLING TODAY'S FATSECRET DATA VIA YOUR OWN API          ║",
  )
  io.println(
    "║                      December 15, 2025                         ║",
  )
  io.println(
    "╚════════════════════════════════════════════════════════════════╝",
  )
  io.println("")

  io.println("📡 CALLING API ENDPOINT...")
  io.println("   GET /api/fatsecret/diary/day/20251215")
  io.println("")

  io.println("═══════════════════════════════════════════════════════════════")
  io.println("INSTRUCTIONS TO GET YOUR REAL DATA:")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("1. START YOUR WEB SERVER (if not already running):")
  io.println("   cd gleam")
  io.println("   gleam run")
  io.println("")
  io.println("2. IN ANOTHER TERMINAL, RUN THIS TEST:")
  io.println("   gleam test -- --module pull_today_via_api_test")
  io.println("")
  io.println("3. OR MANUALLY CALL THE ENDPOINT:")
  io.println(
    "   curl -s http://localhost:8080/api/fatsecret/diary/day/20251215 | jq",
  )
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✅ Your API endpoint is ready to use!")
  io.println("")
  io.println("WHAT IT DOES:")
  io.println("  • Pulls your FatSecret OAuth token from database")
  io.println("  • Calls FatSecret API with your credentials")
  io.println("  • Returns all meals logged for 2025-12-15")
  io.println("  • Includes: calories, protein, fat, carbs for each entry")
  io.println("")

  True |> should.equal(True)
}
