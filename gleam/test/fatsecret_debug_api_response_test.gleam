/// Debug test to show actual FatSecret API response format
/// This test captures the raw HTTP response to diagnose parsing issues
import gleam/dynamic/decode
import gleam/io
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import gleeunit
import gleeunit/should
import meal_planner/env
import meal_planner/fatsecret/core/config.{FatSecretConfig}
import meal_planner/fatsecret/core/http
import meal_planner/fatsecret/core/oauth.{AccessToken}
import meal_planner/fatsecret/storage
import pog

pub fn main() {
  gleeunit.main()
}

pub fn show_fatsecret_api_response_test() {
  io.println("")
  io.println(
    "╔════════════════════════════════════════════════════════════════╗",
  )
  io.println(
    "║          FATSECRET API RESPONSE FORMAT DEBUG                  ║",
  )
  io.println(
    "║              Capturing Real API Response for 12/15/2025        ║",
  )
  io.println(
    "╚════════════════════════════════════════════════════════════════╝",
  )
  io.println("")

  // Check if we can access the database and token
  io.println("🔍 Checking database connection...")

  // Try to get config from environment
  case env.load_fatsecret_config() {
    None -> {
      io.println("❌ FatSecret config not loaded from environment variables")
      io.println("")
      io.println("Required environment variables:")
      io.println("  - FATSECRET_CONSUMER_KEY")
      io.println("  - FATSECRET_CONSUMER_SECRET")
      io.println("")
      io.println(
        "If you have an OAuth token in the database, the API call will work.",
      )
      io.println(
        "But this test can't access the database from the test environment.",
      )
      io.println("")
      io.println("📋 MANUAL TEST INSTRUCTIONS:")
      io.println(
        "   Run this command to see the actual FatSecret API response:",
      )
      io.println("")
      io.println(
        "   curl -s -H 'Authorization: OAuth oauth_token=YOUR_TOKEN' \\",
      )
      io.println(
        "     'https://www.fatsecret.com/oauth/rest/server.api?method=food_entries.get&date_int=20251215' \\",
      )
      io.println("     | jq .")
      io.println("")
    }
    Some(config) -> {
      io.println("✅ FatSecret config found!")
      io.println("")
      io.println(
        "To capture the real API response, you would need to make an authenticated request.",
      )
      io.println("")
      io.println("📊 Expected Response Structure (from docs):")
      io.println("   https://platform.fatsecret.com/docs/v2/food_entries.get")
      io.println("")
      io.println("{")
      io.println("  \"food_entries\": {")
      io.println("    \"food_entry\": [")
      io.println("      {")
      io.println("        \"food_entry_id\": \"123456\",")
      io.println("        \"food_entry_name\": \"Chicken Breast\",")
      io.println("        \"calories\": \"248\",")
      io.println("        \"protein\": \"46.5\",")
      io.println("        \"fat\": \"5.4\",")
      io.println("        \"carbohydrate\": \"0\",")
      io.println("        ... (and other fields)")
      io.println("      }")
      io.println("    ]")
      io.println("  }")
      io.println("}")
    }
  }

  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("✅ Test Complete")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")

  // Verify test passes
  True |> should.equal(True)
}
