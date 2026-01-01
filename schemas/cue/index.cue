// Meal Planner CUE Schema Index
// Master file that imports all schemas and provides quick reference

package mealplanner

// =============================================================================
// SCHEMA FILES
// =============================================================================
//
// base.cue              - Core types, common patterns, base definitions
// fatsecret_foods.cue   - Food search, get, autocomplete, barcode, favorites
// fatsecret_diary.cue   - Food diary entries CRUD
// fatsecret_exercise.cue - Exercise entries CRUD, month summary
// fatsecret_recipes.cue - Recipe search, get, favorites
// fatsecret_saved_meals.cue - Saved meal templates CRUD
// fatsecret_weight.cue  - Weight tracking
// fatsecret_oauth.cue   - OAuth flow, token management, profile
// tandoor.cue           - Tandoor API: test, scrape, create
// flows.cue             - Windmill flow definitions
// resources.cue         - Windmill resource types

// =============================================================================
// BINARY QUICK REFERENCE
// =============================================================================

// 2-LEGGED OAUTH (No user token required)
// These operations work with just API credentials
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
// These operations require user authorization
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
	"f/fatsecret/oauth_setup",      // OAuth 3-legged authorization
	"f/tandoor/import_recipe",      // Scrape + create single recipe
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
// VALIDATION EXAMPLES
// =============================================================================

// Example: Validate a food entry create input
_exampleFoodEntryCreate: #FoodEntryCreateInput & {
	fatsecret: {
		consumer_key:    "abc123"
		consumer_secret: "xyz789"
	}
	access_token:    "user_token"
	access_secret:   "user_secret"
	food_id:         "33691"
	food_entry_name: "Chicken Breast"
	serving_id:      "12345"
	number_of_units: 1.5
	meal:            "lunch"
	date_int:        20088
}

// Example: Validate a foods search input
_exampleFoodsSearch: #FoodsSearchInput & {
	query:       "grilled chicken"
	page:        0
	max_results: 20
}

// Example: Validate a Tandoor scrape input
_exampleTandoorScrape: #TandoorScrapeRecipeInput & {
	tandoor: {
		base_url:  "https://recipes.example.com"
		api_token: "token123"
	}
	url: "https://seriouseats.com/recipe/chicken"
}
