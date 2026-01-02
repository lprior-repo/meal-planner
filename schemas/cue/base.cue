// Meal Planner CUE Schema Definitions
// Base types and common patterns shared across all binaries and flows

package mealplanner

// =============================================================================
// CORE TYPES
// =============================================================================

// DateInt represents days since Unix epoch (1970-01-01)
// Example: 20088 = 2025-01-01
#DateInt: int & >=0

// MealType enum for food diary entries
#MealType: "breakfast" | "lunch" | "dinner" | "other" | "snack"

// OAuth authentication level
#OAuthLevel: "2-legged" | "3-legged"

// =============================================================================
// RESOURCE TYPES (Windmill Resources)
// =============================================================================

// FatSecret API credentials (OAuth 1.0a consumer)
#FatSecretResource: {
	consumer_key:    string & =~"^[A-Za-z0-9]+$"
	consumer_secret: string & =~"^[A-Za-z0-9]+$"
}

// Tandoor Recipes API connection
#TandoorResource: {
	base_url:  string & =~"^https?://"
	api_token: string
}

// =============================================================================
// COMMON INPUT/OUTPUT PATTERNS
// =============================================================================

// Base error output - all binaries use this on failure
#ErrorOutput: {
	success: false
	error:   string
}

// Base success output - extended by specific binaries
#SuccessOutput: {
	success: true
	...
}

// Standard binary output is either success or error
#BinaryOutput: #SuccessOutput | #ErrorOutput

// =============================================================================
// FATSECRET COMMON INPUT PATTERNS
// =============================================================================

// 2-legged OAuth input (no user token required)
// Used for: foods_search, food_get, recipes_search, etc.
#FatSecret2LeggedInput: {
	// Optional - falls back to FATSECRET_CONSUMER_KEY/SECRET env vars
	fatsecret?: #FatSecretResource
}

// 3-legged OAuth input (requires user access token)
// Used for: diary operations, favorites, profile, etc.
#FatSecret3LeggedInput: {
	#FatSecret2LeggedInput
	access_token:  string
	access_secret: string
}

// Alternative naming used by some binaries (oauth_complete, get_profile)
#FatSecretOAuthTokenInput: {
	#FatSecret2LeggedInput
	oauth_token:        string
	oauth_token_secret: string
}

// =============================================================================
// FATSECRET ID TYPES (Opaque identifiers)
// =============================================================================

#FoodId:          string
#ServingId:       string
#FoodEntryId:     string
#ExerciseId:      string
#ExerciseEntryId: string
#RecipeId:        string
#SavedMealId:     string
#WeightEntryId:   string

// =============================================================================
// PAGINATION
// =============================================================================

#Pagination: {
	page?:        int & >=0 // 0-indexed page number
	max_results?: int & >=1 & <=50
}

#PaginationAlt: {
	page_number?: int & >=0
	max_results?: int & >=1 & <=50
}

// =============================================================================
// TANDOOR COMMON PATTERNS
// =============================================================================

#TandoorInput: {
	tandoor: #TandoorResource
}

// Some Tandoor binaries support dual input format
#TandoorFlexibleInput: {
	tandoor?:   #TandoorResource
	base_url?:  string
	api_token?: string
}

// =============================================================================
// NUTRITION DATA
// =============================================================================

#NutritionValues: {
	calories:     number & >=0
	carbohydrate: number & >=0
	protein:      number & >=0
	fat:          number & >=0
	fiber?:       number & >=0
	sugar?:       number & >=0
	sodium?:      number & >=0
	cholesterol?: number & >=0
	saturated_fat?: number & >=0
	...
}

// =============================================================================
// WINDMILL FLOW TYPES
// =============================================================================

#WindmillResourceRef: =~"^\\$res:"

#WindmillInputTransform: {
	type: "static" | "javascript"
	value?: _
	expr?:  string
}

#WindmillFlowModule: {
	id:       string
	summary?: string
	value: {
		type: "script" | "rawscript" | "flow" | "forloopflow"
		...
	}
	suspend?: {
		required_events: int
		timeout:         int
		resume_form?: {
			schema: _
		}
	}
}

#WindmillFlowSchema: {
	"$schema": string
	type:      "object"
	properties: [string]: _
	required: [...string]
}

#WindmillFlow: {
	summary:     string
	description: string
	value: {
		modules: [...#WindmillFlowModule]
		same_worker: bool | *false
	}
	schema: #WindmillFlowSchema
}
