// FatSecret Foods Domain Binary Contracts
// Binaries: foods_search, food_get, foods_autocomplete, food_find_barcode,
//           foods_get_favorites, foods_most_eaten, foods_recently_eaten,
//           food_add_favorite, food_delete_favorite

package mealplanner

// =============================================================================
// fatsecret_foods_search
// Search the FatSecret food database
// OAuth: 2-legged (no user token required)
// =============================================================================

#FoodsSearchInput: {
	#FatSecret2LeggedInput
	query:       string & !=""
	page?:       int & >=0  // 0-indexed, default 0
	max_results?: int & >=1 & <=50  // default 20
}

#FoodsSearchOutput: {
	success: true
	foods:   _ // FoodSearchResponse with foods array and pagination
} | #ErrorOutput

// =============================================================================
// fatsecret_food_get
// Get detailed food information by ID
// OAuth: 2-legged (no user token required)
// =============================================================================

#FoodGetInput: {
	#FatSecret2LeggedInput
	food_id: #FoodId
}

#FoodGetOutput: {
	success: true
	food:    _ // Food object with servings, nutrition, etc.
} | #ErrorOutput

// =============================================================================
// fatsecret_foods_autocomplete
// Get autocomplete suggestions for partial food names
// OAuth: 2-legged (no user token required)
// =============================================================================

#FoodsAutocompleteInput: {
	#FatSecret2LeggedInput
	expression: string & !=""  // partial food name
}

#FoodsAutocompleteOutput: {
	success:     true
	suggestions: [..._]  // array of suggestion objects
} | #ErrorOutput

// =============================================================================
// fatsecret_food_find_barcode
// Find food by barcode (UPC-A, EAN-13, etc.)
// OAuth: 2-legged (no user token required)
// =============================================================================

#FoodFindBarcodeInput: {
	#FatSecret2LeggedInput
	barcode:      string & !=""
	barcode_type?: string  // UPC-A, EAN-13, etc.
}

#FoodFindBarcodeOutput: {
	success: true
	food:    _  // Food object
} | #ErrorOutput

// =============================================================================
// fatsecret_foods_get_favorites
// Get user's favorite foods
// OAuth: 3-legged (requires user access token)
// =============================================================================

#FoodsGetFavoritesInput: {
	#FatSecret3LeggedInput
}

#FoodsGetFavoritesOutput: {
	success:   true
	favorites: _  // array of favorite food objects
} | #ErrorOutput

// =============================================================================
// fatsecret_foods_most_eaten
// Get user's most frequently eaten foods
// OAuth: 3-legged (requires user access token)
// =============================================================================

#FoodsMostEatenInput: {
	#FatSecret3LeggedInput
	meal?: #MealType  // optional filter by meal
}

#FoodsMostEatenOutput: {
	success: true
	foods:   [..._]  // array of food objects
} | #ErrorOutput

// =============================================================================
// fatsecret_foods_recently_eaten
// Get user's recently eaten foods
// OAuth: 3-legged (requires user access token)
// =============================================================================

#FoodsRecentlyEatenInput: {
	#FatSecret3LeggedInput
	meal?: #MealType  // optional filter by meal
}

#FoodsRecentlyEatenOutput: {
	success: true
	foods:   [..._]  // array of food objects
} | #ErrorOutput

// =============================================================================
// fatsecret_food_add_favorite
// Add a food to user's favorites
// OAuth: 3-legged (requires user access token)
// =============================================================================

#FoodAddFavoriteInput: {
	#FatSecret3LeggedInput
	food_id:         #FoodId
	serving_id?:     #ServingId
	number_of_units?: number & >0
}

#FoodAddFavoriteOutput: {
	success: true
} | #ErrorOutput

// =============================================================================
// fatsecret_food_delete_favorite
// Remove a food from user's favorites
// OAuth: 3-legged (requires user access token)
// =============================================================================

#FoodDeleteFavoriteInput: {
	#FatSecret3LeggedInput
	food_id: #FoodId
}

#FoodDeleteFavoriteOutput: {
	success: true
} | #ErrorOutput
