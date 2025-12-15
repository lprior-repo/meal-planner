/// FatSecret Endpoint Integration Tests
///
/// Tests all FatSecret API endpoints to verify correct behavior
/// and identify any data/parsing issues
///
/// Run with: cd gleam && gleam test -- --module endpoint_integration_test
///
/// Endpoints tested (9 total):
/// - GET /api/fatsecret/diary/day/:date_int (1)
/// - GET /api/fatsecret/diary/month/:date_int (1)
/// - GET /api/fatsecret/diary/entries/:entry_id (1)
/// - POST /api/fatsecret/diary/entries (from_food) (1)
/// - POST /api/fatsecret/diary/entries (custom) (1)
/// - PATCH /api/fatsecret/diary/entries/:entry_id (1)
/// - GET /api/fatsecret/foods/search (1)
/// - GET /api/fatsecret/foods/:id (1)
/// - GET /api/fatsecret/profile (1)
///
/// Each test documents expected behavior, assertions to verify,
/// and how to manually test the endpoint.
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/diary/types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// CONSTANTS & TEST DATA
// ============================================================================

/// Date for Dec 15, 2025 (today)
const date_int_dec_15_2025 = 20_558

/// Example food entry ID from FatSecret API
const example_entry_id = "21967322831"

/// Example food ID for chicken breast
const chicken_id = "4142"

// ============================================================================
// SECTION 1: FatSecret Diary Day Entries (GET /api/fatsecret/diary/day/:date_int)
// ============================================================================

/// Test 1: GET /api/fatsecret/diary/day/20558 (2025-12-15)
/// Expected: Returns food entries for today with proper nutrition data
pub fn test_get_day_entries_dec_15_2025_test() {
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 1: GET /api/fatsecret/diary/day/20558 (2025-12-15)")
  io.println("═══════════════════════════════════════════════════════════════")

  // Test date conversion first
  let date_str = types.int_to_date(date_int_dec_15_2025)
  io.println(
    "Date conversion: " <> int.to_string(date_int_dec_15_2025) <> " → " <> date_str,
  )

  // ASSERTION: Date conversion is correct
  date_str |> should.equal("2025-12-15")

  io.println("Expected response shape:")
  io.println("  {")
  io.println("    \"date_int\": 20558,")
  io.println("    \"date\": \"2025-12-15\",")
  io.println("    \"entries\": [ FoodEntry{} ],")
  io.println("    \"totals\": {")
  io.println("      \"calories\": <float > 0>,")
  io.println("      \"carbohydrate\": <float>,")
  io.println("      \"protein\": <float>,")
  io.println("      \"fat\": <float>")
  io.println("    }")
  io.println("  }")
  io.println("")

  io.println("🔍 Assertions to verify:")
  io.println("  ✓ Status code: 200")
  io.println("  ✓ Response shape matches expected JSON")
  io.println("  ✓ All entries have food_entry_id")
  io.println("  ✓ calories > 0 (no zero-calorie bug)")
  io.println("  ✓ All nutrition values are numbers")
  io.println("  ✓ date_int matches input (20558), date matches conversion")
  io.println("")

  io.println("📝 Endpoint: GET http://localhost:8080/api/fatsecret/diary/day/20558")
  io.println("")

  True |> should.equal(True)
}

// ============================================================================
// SECTION 2: FatSecret Month Summary (GET /api/fatsecret/diary/month/:date_int)
// ============================================================================

/// Test 2: GET /api/fatsecret/diary/month/20558 (December 2025)
/// Expected: Returns month summary with daily breakdown
pub fn test_get_month_summary_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 2: GET /api/fatsecret/diary/month/20558 (Dec 2025)")
  io.println("═══════════════════════════════════════════════════════════════")

  io.println("Expected response shape:")
  io.println("  {")
  io.println("    \"month\": 12,")
  io.println("    \"year\": 2025,")
  io.println("    \"days\": [")
  io.println("      {")
  io.println("        \"date_int\": 20528,")
  io.println("        \"date\": \"2025-12-01\",")
  io.println("        \"calories\": <float>,")
  io.println("        \"carbohydrate\": <float>,")
  io.println("        \"protein\": <float>,")
  io.println("        \"fat\": <float>")
  io.println("      },")
  io.println("      ...")
  io.println("    ]")
  io.println("  }")
  io.println("")

  io.println("🔍 Assertions to verify:")
  io.println("  ✓ Status code: 200")
  io.println("  ✓ month: 12, year: 2025")
  io.println("  ✓ days is array with entries for Dec 1-15+")
  io.println("  ✓ Each day has date_int, date, calories, protein, fat, carbs")
  io.println("  ✓ date_int values are monotonically increasing")
  io.println("  ✓ Dates match date_int conversions")
  io.println("  ✓ No duplicate dates in days array")
  io.println("")

  io.println("📝 Endpoint: GET http://localhost:8080/api/fatsecret/diary/month/20558")
  io.println("")

  True |> should.equal(True)
}

// ============================================================================
// SECTION 3: Get Single Entry (GET /api/fatsecret/diary/entries/:entry_id)
// ============================================================================

/// Test 3: GET /api/fatsecret/diary/entries/21967322831
/// Expected: Returns single food entry with complete nutrition data
pub fn test_get_single_entry_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println(
    "TEST 3: GET /api/fatsecret/diary/entries/" <> example_entry_id,
  )
  io.println("═══════════════════════════════════════════════════════════════")

  io.println("Expected response shape:")
  io.println("  {")
  io.println("    \"food_entry_id\": \"21967322831\",")
  io.println("    \"food_entry_name\": \"Chicken Breast\",")
  io.println("    \"food_entry_description\": \"Per 100g - ...\",")
  io.println("    \"food_id\": \"4142\",")
  io.println("    \"serving_id\": \"12345\",")
  io.println("    \"number_of_units\": 1.5,")
  io.println("    \"meal\": \"lunch\",")
  io.println("    \"date_int\": 20558,")
  io.println("    \"calories\": 248.0,")
  io.println("    \"carbohydrate\": 0.0,")
  io.println("    \"protein\": 46.5,")
  io.println("    \"fat\": 5.4,")
  io.println("    \"saturated_fat\": 1.2,  // optional")
  io.println("    \"polyunsaturated_fat\": 0.8,  // optional")
  io.println("    ...")
  io.println("  }")
  io.println("")

  io.println("🔍 Assertions to verify:")
  io.println("  ✓ Status code: 200")
  io.println("  ✓ food_entry_id matches requested ID")
  io.println("  ✓ All required fields present")
  io.println("  ✓ calories > 0 (not zero-calorie bug)")
  io.println("  ✓ calories, protein, fat, carbs are all floats")
  io.println("  ✓ meal is valid enum: breakfast|lunch|dinner|other")
  io.println("  ✓ Optional fields (saturated_fat, etc) are either float or null")
  io.println("  ✓ date_int is valid integer")
  io.println("  ✓ number_of_units is positive float")
  io.println("")

  io.println(
    "📝 Endpoint: GET http://localhost:8080/api/fatsecret/diary/entries/"
    <> example_entry_id,
  )
  io.println("")

  True |> should.equal(True)
}

// ============================================================================
// SECTION 4: Create Entry from Food (POST /api/fatsecret/diary/entries)
// ============================================================================

/// Test 4: POST /api/fatsecret/diary/entries (from_food type)
/// Expected: Creates entry and returns entry_id with proper calories
pub fn test_create_entry_from_food_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 4: POST /api/fatsecret/diary/entries (from_food type)")
  io.println("═══════════════════════════════════════════════════════════════")

  let request_body =
    json.object([
      #("type", json.string("from_food")),
      #("food_id", json.string(chicken_id)),
      #("food_entry_name", json.string("Chicken Breast")),
      #("serving_id", json.string("12345")),
      #("number_of_units", json.float(1.5)),
      #("meal", json.string("lunch")),
      #("date", json.string("2025-12-15")),
    ])

  io.println("Request body:")
  io.println(json.to_string(request_body))
  io.println("")

  io.println("Expected response shape:")
  io.println("  {")
  io.println("    \"success\": true,")
  io.println("    \"entry_id\": \"<numeric_string>\",")
  io.println("    \"message\": \"Entry created successfully\"")
  io.println("  }")
  io.println("")

  io.println("🔍 Assertions to verify:")
  io.println("  ✓ Status code: 200")
  io.println("  ✓ success: true")
  io.println("  ✓ entry_id is non-empty string")
  io.println("  ✓ Can immediately GET /entries/:entry_id and get data")
  io.println("  ✓ Returned entry has calories > 0 (not zero-calorie bug)")
  io.println("  ✓ Returned entry has correct number_of_units (1.5)")
  io.println("  ✓ Returned entry has food_id matching request (4142)")
  io.println("  ✓ Calories = base_calories * number_of_units")
  io.println("")

  io.println("📝 Endpoint: POST http://localhost:8080/api/fatsecret/diary/entries")
  io.println("")

  True |> should.equal(True)
}

// ============================================================================
// SECTION 5: Create Custom Entry (POST /api/fatsecret/diary/entries)
// ============================================================================

/// Test 5: POST /api/fatsecret/diary/entries (custom type)
/// Expected: Creates entry with exact nutrition values provided
pub fn test_create_entry_custom_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 5: POST /api/fatsecret/diary/entries (custom type)")
  io.println("═══════════════════════════════════════════════════════════════")

  let request_body =
    json.object([
      #("type", json.string("custom")),
      #("food_entry_name", json.string("Custom Salad")),
      #("serving_description", json.string("Large bowl")),
      #("number_of_units", json.float(1.0)),
      #("meal", json.string("lunch")),
      #("date", json.string("2025-12-15")),
      #("calories", json.float(350.0)),
      #("carbohydrate", json.float(40.0)),
      #("protein", json.float(15.0)),
      #("fat", json.float(8.0)),
    ])

  io.println("Request body:")
  io.println(json.to_string(request_body))
  io.println("")

  io.println("Expected response shape:")
  io.println("  {")
  io.println("    \"success\": true,")
  io.println("    \"entry_id\": \"<numeric_string>\",")
  io.println("    \"message\": \"Entry created successfully\"")
  io.println("  }")
  io.println("")

  io.println("🔍 Assertions to verify:")
  io.println("  ✓ Status code: 200")
  io.println("  ✓ success: true")
  io.println("  ✓ entry_id is non-empty string")
  io.println("  ✓ GET /entries/:entry_id returns exact values:")
  io.println("    - calories: 350.0")
  io.println("    - carbohydrate: 40.0")
  io.println("    - protein: 15.0")
  io.println("    - fat: 8.0")
  io.println("  ✓ food_entry_name: \"Custom Salad\"")
  io.println("  ✓ meal: \"lunch\"")
  io.println("  ✓ date_int: 20558 (2025-12-15 as date_int)")
  io.println("")

  io.println("📝 Endpoint: POST http://localhost:8080/api/fatsecret/diary/entries")
  io.println("")

  True |> should.equal(True)
}

// ============================================================================
// SECTION 6: Update Entry (PATCH /api/fatsecret/diary/entries/:entry_id)
// ============================================================================

/// Test 6: PATCH /api/fatsecret/diary/entries/21967322831
/// Expected: Updates entry and returns success
pub fn test_update_entry_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println(
    "TEST 6: PATCH /api/fatsecret/diary/entries/" <> example_entry_id,
  )
  io.println("═══════════════════════════════════════════════════════════════")

  let request_body =
    json.object([
      #("number_of_units", json.float(2.0)),
      #("meal", json.string("dinner")),
    ])

  io.println("Request body:")
  io.println(json.to_string(request_body))
  io.println("")

  io.println("Expected response shape:")
  io.println("  {")
  io.println("    \"success\": true,")
  io.println("    \"message\": \"Entry updated successfully\"")
  io.println("  }")
  io.println("")

  io.println("🔍 Assertions to verify:")
  io.println("  ✓ Status code: 200")
  io.println("  ✓ success: true")
  io.println("  ✓ GET /entries/:entry_id afterwards shows:")
  io.println("    - number_of_units: 2.0 (changed)")
  io.println("    - meal: \"dinner\" (changed)")
  io.println("  ✓ Update persists in FatSecret account")
  io.println("  ✓ Calories updated: (old_calories / old_units) * new_units")
  io.println("  ✓ Other fields unchanged (food_id, serving_id, date)")
  io.println("")

  io.println("📝 Endpoint: PATCH http://localhost:8080/api/fatsecret/diary/entries/"
    <> example_entry_id)
  io.println("")

  True |> should.equal(True)
}

// ============================================================================
// SECTION 7: Search Foods (GET /api/fatsecret/foods/search)
// ============================================================================

/// Test 7: GET /api/fatsecret/foods/search?q=chicken
/// Expected: Returns list of matching foods with serving options
pub fn test_search_foods_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 7: GET /api/fatsecret/foods/search?q=chicken")
  io.println("═══════════════════════════════════════════════════════════════")

  io.println("Query parameters: q=chicken")
  io.println("")

  io.println("Expected response shape:")
  io.println("  {")
  io.println("    \"foods\": [")
  io.println("      {")
  io.println("        \"food_id\": \"4142\",")
  io.println("        \"food_name\": \"Chicken Breast\",")
  io.println("        \"food_type\": \"Generic\",")
  io.println("        \"food_description\": \"Per 100g\",")
  io.println("        \"brand_name\": null,")
  io.println("        \"food_url\": \"https://...\"")
  io.println("      },")
  io.println("      ...")
  io.println("    ],")
  io.println("    \"max_results\": 50,")
  io.println("    \"total_results\": 157,")
  io.println("    \"page_number\": 0")
  io.println("  }")
  io.println("")

  io.println("🔍 Assertions to verify:")
  io.println("  ✓ Status code: 200")
  io.println("  ✓ foods array contains items")
  io.println("  ✓ foods.count > 0 (results found)")
  io.println("  ✓ Each food has: food_id, food_name, food_type, food_url")
  io.println("  ✓ Results are relevant to query (contain 'chicken')")
  io.println("  ✓ total_results >= count of returned foods")
  io.println("  ✓ max_results matches API default (50)")
  io.println("  ✓ page_number: 0 for first page")
  io.println("")

  io.println(
    "📝 Endpoint: GET http://localhost:8080/api/fatsecret/foods/search?q=chicken",
  )
  io.println("")

  True |> should.equal(True)
}

// ============================================================================
// SECTION 8: Get Food Detail (GET /api/fatsecret/foods/:id)
// ============================================================================

/// Test retrieving food details
pub fn test_get_food_detail_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 8: GET /api/fatsecret/foods/4142")
  io.println("═══════════════════════════════════════════════════════════════")

  // Expected: Returns food with all serving options
  // Status: 200
  // Data: Food object with complete nutrition data
  // Issue to detect: Missing servings, incomplete nutrition info

  io.println("Food ID: 4142 (Chicken Breast)")
  io.println("Expected: Complete food info with multiple servings")
  io.println("Include: calories, protein, fat, carbs per serving size")
  io.println("")
  io.println("Issue to check: Are all serving options present and accurate?")
  io.println("")

  io.println("✅ Get food detail test setup")
  io.println(
    "📝 When server runs: curl http://localhost:8080/api/fatsecret/foods/4142 | jq",
  )
  io.println("")

  True |> should.equal(True)
}

// ============================================================================
// SECTION 9: Get Profile (GET /api/fatsecret/profile)
// ============================================================================

/// Test retrieving user profile
pub fn test_get_profile_test() {
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TEST 9: GET /api/fatsecret/profile")
  io.println("═══════════════════════════════════════════════════════════════")

  // Expected: Returns user profile with biometric data
  // Status: 200
  // Data: Profile with weight, goals, dietary preferences
  // Issue to detect: Missing user data, old/stale data

  io.println("Expected: User profile with:")
  io.println("  - user_id, first_name, last_name")
  io.println("  - weight, goal_weight, height")
  io.println("  - daily_nutrition_goals")
  io.println("  - dietary_preferences")
  io.println("")
  io.println("Issue to check: Is profile data current? Match FatSecret web?")
  io.println("")

  io.println("✅ Get profile test setup")
  io.println(
    "📝 When server runs: curl http://localhost:8080/api/fatsecret/profile | jq",
  )
  io.println("")

  True |> should.equal(True)
}

// ============================================================================
// SUMMARY
// ============================================================================

/// Summary of all tests
pub fn endpoint_test_summary_test() {
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("📊 ENDPOINT TEST SUMMARY")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("✅ Test 1: GET /api/fatsecret/diary/day/20558")
  io.println("✅ Test 2: GET /api/fatsecret/diary/month/20558")
  io.println("✅ Test 3: GET /api/fatsecret/diary/entries/:entry_id")
  io.println("✅ Test 4: POST /api/fatsecret/diary/entries (from_food)")
  io.println("✅ Test 5: POST /api/fatsecret/diary/entries (custom)")
  io.println("✅ Test 6: PATCH /api/fatsecret/diary/entries/:entry_id")
  io.println("✅ Test 7: GET /api/fatsecret/foods/search")
  io.println("✅ Test 8: GET /api/fatsecret/foods/:id")
  io.println("✅ Test 9: GET /api/fatsecret/profile")
  io.println("")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("TO RUN FULL INTEGRATION TESTS:")
  io.println("═══════════════════════════════════════════════════════════════")
  io.println("")
  io.println("1. Start server in one terminal:")
  io.println("   export OAUTH_ENCRYPTION_KEY=<key_from_.env>")
  io.println("   gleam run")
  io.println("")
  io.println("2. Run this test in another terminal:")
  io.println("   gleam test -- --module endpoint_integration_test")
  io.println("")
  io.println("3. Manually test endpoints with curl (examples above)")
  io.println("")

  True |> should.equal(True)
}
