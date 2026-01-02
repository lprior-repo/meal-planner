// Tandoor Recipes Domain Binary Contracts
// Extracted from openapi/tandoor.yaml

package mealplanner

// =============================================================================
// BASE TYPES (from base.cue)
// =============================================================================

#TandoorResource: {
	base_url:  string & =~"^https?://"
	api_token: string
}

#ErrorOutput: {
	success: false
	error:   string
}

// =============================================================================
// COMMON TYPES
// =============================================================================

#TandoorId: int & >=0
#TandoorDateTime: string
#TandoorDate: string
#TandoorTime: string | *"00:00:00"
#TandoorColor: string & =~"^#[0-9A-Fa-f]{6}$"
#TandoorUrl: string & =~"^https?://"

// =============================================================================
// USER & AUTH
// =============================================================================

#TandoorUser: {
	id:        int
	username:  string
	first_name?: string
	last_name?: string
	email?:    string
	is_active?: bool
	...
}

#TandoorAuthToken: {
	username: string
	password: string
	token:    string
}

// =============================================================================
// MEAL TYPE
// =============================================================================

#TandoorMealType: {
	id:        int
	name:      string
	order?:    int
	time?:     #TandoorTime
	color?:    #TandoorColor
	default?:  bool
	created_by: int
}

// =============================================================================
// KEYWORD
// =============================================================================

#TandoorKeyword: {
	id:        int
	name:      string
	label?:    string
	created_by?: int
	...
}

// =============================================================================
// INGREDIENT
// =============================================================================

#TandoorFood: {
	id:          int
	name:        string
	food_type?:  string
	brand?:      string
	energy?:     number
	carbohydrates?: number
	protein?:    number
	fat?:        number
	fiber?:      number
	...
}

#TandoorUnit: {
	id:          int
	name:        string
	plural_name?: string
	abbreviation?: string
	...

}

#TandoorIngredient: {
	id:                    int
	food:                  #TandoorFood
	unit:                  #TandoorUnit
	amount:                number
	note?:                 string
	order?:                int
	is_header?:            bool
	no_amount?:            bool
	original_text?:        string
	always_use_plural_unit?: bool
	always_use_plural_food?: bool
}

// =============================================================================
// STEP
// =============================================================================

#TandoorStep: {
	id:                    int
	name?:                 string
	instruction:           string
	ingredients:           [...#TandoorIngredient]
	instructions_markdown: string
	time?:                 int
	order:                 int
	show_as_header?:       bool
	show_ingredients_table?: bool
	...
}

// =============================================================================
// NUTRITION
// =============================================================================

#TandoorNutrition: {
	carbohydrates?: number
	fats?:          number
	proteins?:      number
	calories?:      number
	source?:        string
}

// =============================================================================
// RECIPE
// =============================================================================

#TandoorRecipe: {
	id:                    int
	name:                  string
	description?:          string
	image?:                #TandoorUrl
	keywords?:             [...#TandoorKeyword]
	steps:                 [...#TandoorStep]
	working_time?:         int
	waiting_time?:         int
	created_by:            #TandoorUser
	created_at:            #TandoorDateTime
	updated_at:            #TandoorDateTime
	source_url?:           #TandoorUrl
	internal?:             bool
	show_ingredient_overview?: bool
	nutrition?:            #TandoorNutrition
	servings?:             int
	servings_text?:        string
	rating?:               number
	last_cooked?:          #TandoorDateTime
	private?:              bool
	shared?:               [...#TandoorUser]
}

#TandoorRecipeOverview: {
	id:            int
	name:          string
	image?:        #TandoorUrl
	keywords?:     [...#TandoorKeyword]
	working_time?: int
	waiting_time?: int
	recipe_url?:   #TandoorUrl
	servings?:     int
	servings_text?: string
}

// =============================================================================
// MEAL PLAN
// =============================================================================

#TandoorMealPlan: {
	id:              int
	title?:          string
	recipe?:         #TandoorRecipeOverview
	servings:        number
	note?:           string
	note_markdown:   string
	from_date:       #TandoorDateTime
	to_date?:        #TandoorDateTime
	meal_type:       #TandoorMealType
	created_by:      int
	shared?:         [...#TandoorUser]
	recipe_name:     string
	meal_type_name:  string
	shopping:        bool
}

// =============================================================================
// SHOPPING LIST
// =============================================================================

#TandoorShoppingListEntry: {
	id:              int
	shopping_list:   int
	recipe?:         int
	recipe_recipe?:  #TandoorRecipe
	ingredient?:     #TandoorIngredient
	amount?:         number
	unit?:           #TandoorUnit
	food?:           #TandoorFood
	note?:           string
	checked?:        bool
	created_by?:     int
}

#TandoorShoppingListRecipe: {
	id:              int
	recipe:          #TandoorRecipe
	servings:        number
	entries?:        [...#TandoorShoppingListEntry]
}

// =============================================================================
// FOOD
// =============================================================================

#TandoorFood: {
	id:              int
	name:            string
	food_type?:      string
	food_group?:     int
	brand?:          string
	description?:    string
	store?:          string
	unit?:           #TandoorUnit
	energy?:         number
	carbohydrates?:  number
	protein?:        number
	fat?:            number
	unsaturated?:    number
	sugar?:          number
	sodium?:         number
	alcohol?:        number
	trans_fat?:      number
	cholesterol?:    number
	created_by?:     int
	...
}

// =============================================================================
// UNIT
// =============================================================================

#TandoorUnit: {
	id:              int
	name:            string
	plural_name?:    string
	abbreviation?:   string
	dimension?:      string
	KitchenQuantity?: string
	KitchenUnit?:    string
	...
}

#TandoorUnitConversion: {
	id:              int
	base_unit:       #TandoorUnit
	another_unit:    #TandoorUnit
	factor:          number
}

// =============================================================================
// RECIPE BOOK
// =============================================================================

#TandoorRecipeBook: {
	id:              int
	name:            string
	description?:    string
	icon?:           string
	shared?:         [...#TandoorUser]
	created_by?:     int
	...
}

#TandoorRecipeBookEntry: {
	id:              int
	recipe_book:     #TandoorRecipeBook
	recipe:          #TandoorRecipe
	order?:          int
	...
}

// =============================================================================
// SUPERMARKET
// =============================================================================

#TandoorSupermarket: {
	id:              int
	name:            string
	description?:    string
	created_by?:     int
	...
}

#TandoorSupermarketCategory: {
	id:              int
	name:            string
	supermarket:     #TandoorSupermarket
	order?:          int
	...
}

// =============================================================================
// SPACE
// =============================================================================

#TandoorSpace: {
	id:              int
	name:            string
	created_by?:     int
	...
}

// =============================================================================
// BINARY INPUT/OUTPUT TYPES
// =============================================================================

// tandoor_test_connection
#TandoorTestConnectionInput: {
	tandoor?: #TandoorResource
	base_url?:  string & =~"^https?://"
	api_token?: string
}

#TandoorTestConnectionOutput: {
	success:      true
	message:      string
	recipe_count: int
} | #ErrorOutput

// tandoor_scrape_recipe
#TandoorScrapeRecipeInput: {
	tandoor: #TandoorResource
	url:     string & =~"^https?://"
}

#TandoorScrapeRecipeOutput: {
	success:      true
	recipe_json?: _
	images?:      [...string]
	error?:       string
} | #ErrorOutput

// tandoor_create_recipe
#TandoorCreateRecipeInput: {
	tandoor:             #TandoorResource
	recipe:              #SourceImportRecipe
	additional_keywords?: [...string]
}

#TandoorCreateRecipeOutput: {
	success:    true
	recipe_id?: int
	name?:      string
	error?:     string
} | #ErrorOutput

// tandoor_recipe_list
#TandoorRecipeListInput: {
	tandoor: #TandoorResource
	page?:   int & >=1
	per_page?: int & >=1 & <=100
	search?: string
}

#TandoorRecipeListOutput: {
	success: true
	count:   int
	next?:   string
	previous?: string
	results: [...#TandoorRecipe]
} | #ErrorOutput

// tandoor_recipe_get
#TandoorRecipeGetInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorRecipeGetOutput: {
	success: true
	recipe: #TandoorRecipe
} | #ErrorOutput

// tandoor_meal_plan_list
#TandoorMealPlanListInput: {
	tandoor: #TandoorResource
	start_date?: #TandoorDateTime
	end_date?: #TandoorDateTime
	page?:   int & >=1
	per_page?: int & >=1 & <=100
}

#TandoorMealPlanListOutput: {
	success: true
	count:   int
	next?:   string
	previous?: string
	results: [...#TandoorMealPlan]
} | #ErrorOutput

// tandoor_meal_plan_create
#TandoorMealPlanCreateInput: {
	tandoor: #TandoorResource
	meal_plan: {
		title?:      string
		recipe:      int
		servings:    number
		note?:       string
		from_date:   #TandoorDateTime
		to_date?:    #TandoorDateTime
		meal_type:   int
	}
}

#TandoorMealPlanCreateOutput: {
	success:   true
	meal_plan: #TandoorMealPlan
} | #ErrorOutput

// tandoor_meal_type_list
#TandoorMealTypeListInput: {
	tandoor: #TandoorResource
}

#TandoorMealTypeListOutput: {
	success: true
	count:   int
	results: [...#TandoorMealType]
} | #ErrorOutput

// tandoor_ingredient_list
#TandoorIngredientListInput: {
	tandoor: #TandoorResource
	search?: string
	page?:   int & >=1
	per_page?: int & >=1 & <=100
}

#TandoorIngredientListOutput: {
	success: true
	count:   int
	next?:   string
	previous?: string
	results: [...#TandoorIngredient]
} | #ErrorOutput

// tandoor_food_list
#TandoorFoodListInput: {
	tandoor: #TandoorResource
	search?: string
	page?:   int & >=1
	per_page?: int & >=1 & <=100
}

#TandoorFoodListOutput: {
	success: true
	count:   int
	next?:   string
	previous?: string
	results: [...#TandoorFood]
} | #ErrorOutput

// tandoor_unit_list
#TandoorUnitListInput: {
	tandoor: #TandoorResource
}

#TandoorUnitListOutput: {
	success: true
	count:   int
	results: [...#TandoorUnit]
} | #ErrorOutput

// tandoor_shopping_list_entry_list
#TandoorShoppingListEntryListInput: {
	tandoor: #TandoorResource
	shopping_date?: #TandoorDate
}

#TandoorShoppingListEntryListOutput: {
	success: true
	results: [...#TandoorShoppingListEntry]
} | #ErrorOutput

// tandoor_recipe_book_list
#TandoorRecipeBookListInput: {
	tandoor: #TandoorResource
}

#TandoorRecipeBookListOutput: {
	success: true
	count:   int
	results: [...#TandoorRecipeBook]
} | #ErrorOutput

// tandoor_keyword_list
#TandoorKeywordListInput: {
	tandoor: #TandoorResource
}

#TandoorKeywordListOutput: {
	success: true
	count:   int
	results: [...#TandoorKeyword]
} | #ErrorOutput

// tandoor_supermarket_list
#TandoorSupermarketListInput: {
	tandoor: #TandoorResource
}

#TandoorSupermarketListOutput: {
	success: true
	count:   int
	results: [...#TandoorSupermarket]
} | #ErrorOutput

// tandoor_space_list
#TandoorSpaceListInput: {
	tandoor: #TandoorResource
}

#TandoorSpaceListOutput: {
	success: true
	count:   int
	results: [...#TandoorSpace]
} | #ErrorOutput

// =============================================================================
// RECIPE IMPORT SCHEMA
// =============================================================================

#SourceImportRecipe: {
	name:         string
	description?: string
	keywords?: [...string]
	servings?:          int
	servings_text?:     string
	working_time?:      int
	waiting_time?:      int
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
