package mealplanner

// =============================================================================
// FATSECRET FOODS DOMAIN - Complete Binary Contracts
// =============================================================================
// All binaries in the foods domain with their input/output schemas
// CUE is the source of truth for all contracts

// =============================================================================
// fatsecret_foods_search
// Search the FatSecret food database
// =============================================================================

#FoodsSearchInput: {
	// FatSecret credentials (optional - falls back to env vars)
	fatsecret?: {
		consumer_key: string
		consumer_secret: string
	}
	// Search query (required)
	query: string & != ""
	// Page number (0-indexed, default 0)
	page?: int & >=0
	// Maximum results per page (default 20, max 50)
	max_results?: int & >=1 & <=50
}

#FoodsSearchOutput: {
	success: true
	foods: {
		page_number: int
		total_results: int
		total_pages: int
		food: [...{
			food_id: string
			food_name: string
			food_type: "Generic" | "Brand"
			brand_name?: string
		}]
	}
} | #ErrorOutput

// =============================================================================
// fatsecret_food_get
// Get detailed food information by ID
// =============================================================================

#FoodGetInput: {
	fatsecret?: {
		consumer_key: string
		consumer_secret: string
	}
	// Food ID from FatSecret database (required)
	food_id: string & != ""
}

#FoodGetOutput: {
	success: true
	food: {
		food_id: string
		food_name: string
		food_type: "Generic" | "Brand"
		brand_name?: string
		servings: {
			serving: [...{
				serving_id: string
				serving_description: string
				serving_url?: string
				metric_serving_amount?: number
				metric_serving_unit?: string
				number_of_units?: number
				calories?: number
				carbohydrate?: number
				protein?: number
				fat?: number
				saturated_fat?: number
				fiber?: number
				sugar?: number
				sodium?: number
				cholesterol?: number
			}]
		}
	}
} | #ErrorOutput

// =============================================================================
// fatsecret_foods_autocomplete
// Get autocomplete suggestions for partial food names
// =============================================================================

#FoodsAutocompleteInput: {
	fatsecret?: {
		consumer_key: string
		consumer_secret: string
	}
	// Partial food name (required)
	expression: string & != ""
	// Maximum suggestions (default 10)
	max_results?: int & >=1 & <=20
}

#FoodsAutocompleteOutput: {
	success: true
	suggestions: [...{
		food_id: string
		food_name: string
		food_type: "Generic" | "Brand"
		score?: number
	}]
} | #ErrorOutput

// =============================================================================
// fatsecret_food_find_barcode
// Find food by barcode (UPC-A, EAN-13)
// =============================================================================

#FoodFindBarcodeInput: {
	fatsecret?: {
		consumer_key: string
		consumer_secret: string
	}
	// Barcode number (required)
	barcode: string & != ""
	// Barcode type (optional, auto-detected)
	barcode_type?: "UPC-A" | "EAN-13" | "EAN-8" | "Other"
}

#FoodFindBarcodeOutput: {
	success: true
	food: {
		food_id: string
		food_name: string
		food_type: "Generic" | "Brand"
		brand_name?: string
		servings: {...}
	}
} | #ErrorOutput

// =============================================================================
// fatsecret_foods_get_favorites
// Get user's favorite foods (3-legged OAuth)
// =============================================================================

#FoodsGetFavoritesInput: {
	fatsecret?: {
		consumer_key: string
		consumer_secret: string
	}
	// OAuth access token (required)
	access_token: string & != ""
	// OAuth access token secret (required)
	access_secret: string & != ""
}

#FoodsGetFavoritesOutput: {
	success: true
	favorites: [...{
		food_id: string
		food_name: string
		food_type: "Generic" | "Brand"
		brand_name?: string
		serving_id?: string
		number_of_units?: number
	}]
} | #ErrorOutput

// =============================================================================
// fatsecret_foods_most_eaten
// Get user's most frequently eaten foods
// =============================================================================

#FoodsMostEatenInput: {
	fatsecret?: {
		consumer_key: string
		consumer_secret: string
	}
	access_token: string & != ""
	access_secret: string & != ""
	// Optional meal type filter
	meal?: "breakfast" | "lunch" | "dinner" | "other" | "snack"
	// Maximum results (default 10)
	max_results?: int & >=1 & <=50
}

#FoodsMostEatenOutput: {
	success: true
	foods: [...{
		food_id: string
		food_name: string
		food_type: "Generic" | "Brand"
		brand_name?: string
		count: int
	}]
} | #ErrorOutput

// =============================================================================
// fatsecret_foods_recently_eaten
// Get user's recently eaten foods
// =============================================================================

#FoodsRecentlyEatenInput: {
	fatsecret?: {
		consumer_key: string
		consumer_secret: string
	}
	access_token: string & != ""
	access_secret: string & != ""
	meal?: "breakfast" | "lunch" | "dinner" | "other" | "snack"
	max_results?: int & >=1 & <=50
}

#FoodsRecentlyEatenOutput: {
	success: true
	foods: [...{
		food_id: string
		food_name: string
		food_type: "Generic" | "Brand"
		brand_name?: string
		last_eaten_date?: int
	}]
} | #ErrorOutput

// =============================================================================
// fatsecret_food_add_favorite
// Add a food to user's favorites
// =============================================================================

#FoodAddFavoriteInput: {
	fatsecret?: {
		consumer_key: string
		consumer_secret: string
	}
	access_token: string & != ""
	access_secret: string & != ""
	// Food ID to add (required)
	food_id: string & != ""
	// Optional serving suggestion
	serving_id?: string
	number_of_units?: number & >0
}

#FoodAddFavoriteOutput: {
	success: true
} | #ErrorOutput

// =============================================================================
// fatsecret_food_delete_favorite
// Remove a food from user's favorites
// =============================================================================

#FoodDeleteFavoriteInput: {
	fatsecret?: {
		consumer_key: string
		consumer_secret: string
	}
	access_token: string & != ""
	access_secret: string & != ""
	// Food ID to remove (required)
	food_id: string & != ""
}

#FoodDeleteFavoriteOutput: {
	success: true
} | #ErrorOutput
