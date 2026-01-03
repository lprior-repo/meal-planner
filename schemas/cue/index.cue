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
// fatsecret/api.cue      - Complete FatSecret Platform API (all endpoints + OAuth)
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
	"tandoor_recipe_list",
	"tandoor_recipe_list_flat",
	"tandoor_recipe_get",
	"tandoor_recipe_update",
	"tandoor_recipe_delete",
	"tandoor_recipe_get_related",
	"tandoor_recipe_upload_image",
	"tandoor_recipe_batch_update",
	"tandoor_recipe_book_list",
	"tandoor_recipe_book_get",
	"tandoor_recipe_book_create",
	"tandoor_recipe_book_update",
	"tandoor_recipe_book_delete",
	"tandoor_recipe_book_entry_list",
	"tandoor_recipe_book_entry_get",
	"tandoor_recipe_book_entry_create",
	"tandoor_recipe_book_entry_delete",
	"tandoor_meal_plan_list",
	"tandoor_meal_plan_get",
	"tandoor_meal_plan_create",
	"tandoor_meal_plan_update",
	"tandoor_meal_plan_delete",
	"tandoor_meal_plan_export_ical",
	"tandoor_meal_type_list",
	"tandoor_meal_type_get",
	"tandoor_meal_type_create",
	"tandoor_meal_type_update",
	"tandoor_meal_type_delete",
	"tandoor_ingredient_list",
	"tandoor_ingredient_get",
	"tandoor_ingredient_create",
	"tandoor_ingredient_update",
	"tandoor_ingredient_delete",
	"tandoor_ingredient_from_string",
	"tandoor_food_list",
	"tandoor_food_get",
	"tandoor_food_create",
	"tandoor_food_update",
	"tandoor_food_delete",
	"tandoor_food_batch_update",
	"tandoor_unit_list",
	"tandoor_unit_get",
	"tandoor_unit_create",
	"tandoor_unit_update",
	"tandoor_unit_delete",
	"tandoor_unit_conversion_list",
	"tandoor_keyword_list",
	"tandoor_keyword_create",
	"tandoor_keyword_update",
	"tandoor_keyword_delete",
	"tandoor_shopping_list_entry_list",
	"tandoor_shopping_list_entry_create",
	"tandoor_shopping_list_entry_update",
	"tandoor_shopping_list_entry_delete",
	"tandoor_shopping_list_entry_bulk",
	"tandoor_shopping_list_recipe_add",
	"tandoor_shopping_list_recipe_get",
	"tandoor_shopping_list_recipe_delete",
	"tandoor_supermarket_list",
	"tandoor_supermarket_get",
	"tandoor_supermarket_create",
	"tandoor_supermarket_update",
	"tandoor_supermarket_delete",
	"tandoor_space_list",
	"tandoor_space_get",
	"tandoor_user_list",
	"tandoor_user_get",
	"tandoor_step_list",
	"tandoor_step_get",
	"tandoor_step_create",
	"tandoor_step_update",
	"tandoor_step_delete",
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
