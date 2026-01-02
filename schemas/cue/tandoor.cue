// Tandoor Recipes Domain Binary Contracts
// Binaries: tandoor_test_connection, tandoor_scrape_recipe, tandoor_create_recipe

package mealplanner

// =============================================================================
// tandoor_test_connection
// Test Tandoor API connection and authentication
// Supports dual input format (Windmill resource or standalone)
// =============================================================================

#TandoorTestConnectionInput: {
	// Windmill format (nested resource)
	tandoor?: #TandoorResource
	// Standalone format (flat)
	base_url?:  string & =~"^https?://"
	api_token?: string
}

#TandoorTestConnectionOutput: {
	success:      true
	message:      string
	recipe_count: int  // number of recipes in instance
} | #ErrorOutput

// =============================================================================
// tandoor_scrape_recipe
// Scrape recipe from URL using Tandoor's built-in scraper
// =============================================================================

#TandoorScrapeRecipeInput: {
	tandoor: #TandoorResource
	url:     string & =~"^https?://"  // recipe URL to scrape
}

#TandoorScrapeRecipeOutput: {
	success:      true
	recipe_json?: _           // scraped recipe data (SourceImportRecipe)
	images?:      [...string] // image URLs found
	error?:       string      // only on partial success
} | {
	success: false
	error:   string
}

// =============================================================================
// tandoor_create_recipe
// Create a recipe in Tandoor from scraped data
// =============================================================================

#TandoorCreateRecipeInput: {
	tandoor:             #TandoorResource
	recipe:              #SourceImportRecipe
	additional_keywords?: [...string]  // extra tags to add
}

#TandoorCreateRecipeOutput: {
	success:    true
	recipe_id?: int     // created recipe ID
	name?:      string  // recipe name
	error?:     string  // only on partial success
} | {
	success: false
	error:   string
}

// =============================================================================
// TANDOOR RECIPE SCHEMAS
// =============================================================================

// Recipe structure from Tandoor scraper
#SourceImportRecipe: {
	name:         string
	description?: string
	keywords?: [...string]
	servings?:          int
	servings_text?:     string
	working_time?:      int  // minutes
	waiting_time?:      int  // minutes
	source_url?:        string
	internal?:          bool
	nutrition?: {
		calories?:      string
		carbohydrates?: string
		proteins?:      string
		fats?:          string
		...
	}
	steps?: [...{
		instruction: string
		time?:       int
		order?:      int
		ingredients?: [...{
			food: {
				name: string
				...
			}
			unit?: {
				name: string
				...
			}
			amount?: number
			note?:   string
			...
		}]
		...
	}]
	...
}

// Recipe as stored in Tandoor
#TandoorRecipe: {
	id:           int
	name:         string
	description?: string
	keywords?: [...{
		id:    int
		name:  string
		label: string
		...
	}]
	servings?:     int
	working_time?: int
	waiting_time?: int
	source_url?:   string
	created_at?:   string
	updated_at?:   string
	...
}
