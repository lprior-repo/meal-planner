// Meal Planner CUE Schema Index
// Master file that provides quick reference and documentation
//
// SOURCE OF TRUTH: All type definitions are authored in CUE
// GENERATION: CUE → JSON Schema → Rust types (via typify)
// TESTING: OpenAPI specs → Schemathesis tests

// =============================================================================
// SCHEMA FILES
// =============================================================================
//
// fatsecret/api.cue      - Complete FatSecret Platform API (all endpoints)
// fatsecret_oauth.cue    - OAuth 1.0a flow and token management
// base.cue               - Common types, patterns, validation rules
// tandoor.cue            - Tandoor Recipes API (from openapi/tandoor.yaml)
// resources.cue          - Windmill resource type definitions
// flows.cue              - Windmill flow definitions

// =============================================================================
// BINARY QUICK REFERENCE
// =============================================================================

// 2-LEGGED OAUTH (No user token required)
#TwoLeggedBinaries: [
	"fatsecret_foods_search",
	"fatsecret_food_get",
	"fatsecret_foods_autocomplete",
	"fatsecret_food_find_barcode",
	"fatsecret_recipes_search",
	"fatsecret_recipe_get",
	"fatsecret_recipe_types_get",
]

// 3-LEGGED OAUTH (Requires user access token)
#ThreeLeggedBinaries: [
	// Diary
	"fatsecret_food_entries_get",
	"fatsecret_food_entries_get_month",
	"fatsecret_food_entry_create",
	"fatsecret_food_entry_edit",
	"fatsecret_food_entry_delete",
	// Exercise
	"fatsecret_exercise_entries_get",
	"fatsecret_exercise_entry_create",
	"fatsecret_exercise_entry_edit",
	"fatsecret_exercise_entry_delete",
	"fatsecret_exercise_month_summary",
	// Favorites
	"fatsecret_foods_get_favorites",
	"fatsecret_foods_most_eaten",
	"fatsecret_foods_recently_eaten",
	"fatsecret_food_add_favorite",
	"fatsecret_food_delete_favorite",
	"fatsecret_recipes_get_favorites",
	"fatsecret_recipe_add_favorite",
	"fatsecret_recipe_delete_favorite",
	// Saved Meals
	"fatsecret_saved_meals_get",
	"fatsecret_saved_meals_get_items",
	"fatsecret_saved_meals_create",
	"fatsecret_saved_meals_edit",
	"fatsecret_saved_meals_delete",
	// Weight
	"fatsecret_weight_update",
	"fatsecret_weight_month_summary",
	// Profile
	"fatsecret_get_profile",
]

// OAUTH MANAGEMENT (Token lifecycle)
#OAuthBinaries: [
	"fatsecret_oauth_start",
	"fatsecret_oauth_complete",
	"fatsecret_oauth_callback",
	"fatsecret_get_token",
]

// TANDOOR (Blocking, no OAuth)
#TandoorBinaries: [
	"tandoor_test_connection",
	"tandoor_scrape_recipe",
	"tandoor_create_recipe",
]

// =============================================================================
// FLOW QUICK REFERENCE
// =============================================================================

#Flows: [
	"f/fatsecret/oauth_setup",       // OAuth 3-legged authorization
	"f/tandoor/import_recipe",       // Scrape + create single recipe
	"f/tandoor/batch_import_recipes", // Import multiple recipes
]

// =============================================================================
// TYPE CONVERSIONS
// =============================================================================

// DateInt ↔ ISO Date conversions
// date_to_int("2025-01-01") → 20088
// int_to_date(20088) → "2025-01-01"
//
// Formula: date_int = days since 1970-01-01
// In Rust: (NaiveDate.and_hms(0,0,0).timestamp() / 86400) as i32
// In JS:   Math.floor(new Date("2025-01-01").getTime() / 86400000)

// MealType mapping
// "breakfast" | "lunch" | "dinner" | "other"
// Note: "snack" is alias for "other" in some contexts

// =============================================================================
// WORKFLOW
// =============================================================================
//
// 1. Author types in CUE (schemas/cue/fatsecret/api.cue)
// 2. Generate OpenAPI:  nu scripts/gen_openapi.nu
// 3. Generate Rust types: cargo run --bin codegen_typify
// 4. Run API tests:     moon run :test-api-contracts
//
// CI Pipeline:
//   moon run :validate-cue     # CUE schema validation
//   moon run :test-api-contracts  # Schemathesis tests
//   moon run :test              # Rust unit tests

// =============================================================================
// KEY TYPE DEFINITIONS (from fatsecret/api.cue)
// =============================================================================

// Common ID types
// #DateInt: int & >=0  // Days since Unix epoch
// #FoodId: string & =~"^[0-9]+$"
// #ServingId: string & =~"^[0-9]+$"
// #FoodEntryId: string & =~"^[0-9]+$"
// #MealType: "breakfast" | "lunch" | "dinner" | "other" | "snack"

// Food Entry (Diary)
// #FoodEntry: {
//     food_entry_id: #FoodEntryId
//     food_id: #FoodId
//     food_entry_name: string
//     serving_id: #ServingId
//     number_of_units: number
//     meal: #MealType
//     date_int: #DateInt
//     calories: number
//     carbohydrate: number
//     protein: number
//     fat: number
// }

// Foods Search Input (V3)
// #FoodsSearchV3Input: {
//     search_expression: string
//     page_number?: int
//     max_results?: int & <=50
//     include_sub_categories?: bool
//     include_food_images?: bool
//     include_food_attributes?: bool
//     flag_default_serving?: bool
//     region?: string
//     language?: string
//     format?: "json" | "xml"
// }
