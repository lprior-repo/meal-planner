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
// BINARY INPUT/OUTPUT TYPES - ALL TANDOOR BINARIES
// =============================================================================

// =============================================================================
// UTILITY BINARIES
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

// tandoor_format_weekly_meal_plan
#TandoorFormatWeeklyMealPlanInput: {
	recipes:    [...#RecipeOutput]
	dates:      [...string]
	meal_plans: [...#MealPlanResult]
}

#RecipeOutput: {
	id:          int
	name:        string
	description?: string
	servings?:   int
	rating?:     number
	keywords?:   [...#KeywordOutput]
	working_time?: int
	waiting_time?: int
}

#KeywordOutput: {
	id:    int
	name?:  string
	label?: string
}

#MealPlanResult: {
	success:   bool
	meal_plan?: #MealPlanOutput
}

#MealPlanOutput: {
	id:              int
	from_date:       string
	to_date:         string
	servings:        number
	note?:           string
	meal_type?:      #MealTypeOutput
	meal_type_name?: string
	recipe_name:     string
}

#MealTypeOutput: {
	id:    int
	name:  string
	time?: string
	color?: string
}

#TandoorFormatWeeklyMealPlanOutput: {
	success:     bool
	recipes:     [...#RecipeOutput]
	meal_plans:  [...#MealPlanOutput]
	summary: {
		recipes_selected: int
		cooking_dates:    [...string]
		meal_plan_ids:    [...int]
	}
} | #ErrorOutput

// =============================================================================
// USER BINARIES
// =============================================================================

// tandoor_user_list
#TandoorUserListInput: {
	tandoor: #TandoorResource
}

#TandoorUserListOutput: {
	success: bool
	count?:   int
	users?:   [...#TandoorUserOutput]
	error?:   string
} | #ErrorOutput

#TandoorUserOutput: {
	id:         int
	username:   string
	email?:     string
	first_name?: string
	last_name?:  string
}

// tandoor_user_get
#TandoorUserGetInput: {
	tandoor: #TandoorResource
	user_id: int
}

#TandoorUserGetOutput: {
	success: bool
	user?:   #TandoorUserOutput
	error?:  string
} | #ErrorOutput

// =============================================================================
// RECIPE BINARIES
// =============================================================================

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

// tandoor_recipe_list_flat
#TandoorRecipeListFlatInput: {
	tandoor: #TandoorResource
}

#TandoorRecipeListFlatOutput: {
	success: bool
	recipes?: [...#TandoorRecipe]
	error?:   string
} | #ErrorOutput

// tandoor_recipe_get
#TandoorRecipeGetInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorRecipeGetOutput: {
	success: bool
	recipe?: #TandoorRecipe
	error?:  string
} | #ErrorOutput

// tandoor_recipe_get_related
#TandoorRecipeGetRelatedInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorRecipeGetRelatedOutput: {
	success:  bool
	recipes?: [...#TandoorRecipe]
	error?:   string
} | #ErrorOutput

// tandoor_recipe_delete
#TandoorRecipeDeleteInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorRecipeDeleteOutput: {
	success: bool
	error?:  string
} | #ErrorOutput

// tandoor_recipe_update
#TandoorRecipeUpdateInput: {
	tandoor: #TandoorResource
	id:      int
	name?:        string
	description?: string
	servings?:    int
	working_time?: int
	waiting_time?: int
}

#TandoorRecipeUpdateOutput: {
	success: bool
	recipe?: #TandoorRecipe
	error?:  string
} | #ErrorOutput

// tandoor_recipe_random_select
#TandoorRecipeRandomSelectInput: {
	tandoor: #TandoorResource
	keyword: string
	count?:  int & >=1
}

#TandoorRecipeRandomSelectOutput: {
	success:  bool
	recipes?: [...#TandoorRecipeSummary]
	error?:   string
} | #ErrorOutput

#TandoorRecipeSummary: {
	id:          int
	name:        string
	description?: string
	servings?:   int
	rating?:     number
	keywords?:   [...#TandoorKeyword]
	working_time?: int
	waiting_time?: int
}

// tandoor_recipe_upload_image
#TandoorRecipeUploadImageInput: {
	tandoor: #TandoorResource
	id:        int
	file_path: string
}

#TandoorRecipeUploadImageOutput: {
	success:   bool
	image?:    string
	image_url?: string
	error?:    string
} | #ErrorOutput

// tandoor_recipe_batch_update
#TandoorRecipeBatchUpdateInput: {
	tandoor?:    #TandoorResource
	base_url?:   string & =~"^https?://"
	api_token?:  string
	updates: [...#BatchUpdateRecipeEntry]
}

#BatchUpdateRecipeEntry: {
	id:            int
	name?:         string
	description?:  string
	servings?:     int
	working_time?: int
	waiting_time?: int
}

#TandoorRecipeBatchUpdateOutput: {
	success:       bool
	updated_count?: int
	error?:        string
} | #ErrorOutput

// =============================================================================
// MEAL PLAN BINARIES
// =============================================================================

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

// tandoor_meal_plan_get
#TandoorMealPlanGetInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorMealPlanGetOutput: {
	success:   bool
	meal_plan?: #TandoorMealPlan
	error?:    string
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

// tandoor_meal_plan_update
#TandoorMealPlanUpdateInput: {
	tandoor: #TandoorResource
	id:        int
	recipe?:     int
	meal_type?:  int
	from_date?:  #TandoorDateTime
	to_date?:    #TandoorDateTime
	servings?:   number
	title?:      string
	note?:       string
}

#TandoorMealPlanUpdateOutput: {
	success:   bool
	meal_plan?: #TandoorMealPlan
	error?:    string
} | #ErrorOutput

// tandoor_meal_plan_delete
#TandoorMealPlanDeleteInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorMealPlanDeleteOutput: {
	success: bool
	error?:  string
} | #ErrorOutput

// tandoor_meal_plan_export_ical
#TandoorMealPlanExportICalInput: {
	tandoor: #TandoorResource
	start_date: #TandoorDateTime
	end_date:   #TandoorDateTime
}

#TandoorMealPlanExportICalOutput: {
	success: bool
	ics_content?: string
	error?:  string
} | #ErrorOutput

// =============================================================================
// MEAL TYPE BINARIES
// =============================================================================

// tandoor_meal_type_list
#TandoorMealTypeListInput: {
	tandoor: #TandoorResource
}

#TandoorMealTypeListOutput: {
	success: true
	count:   int
	results: [...#TandoorMealType]
} | #ErrorOutput

// tandoor_meal_type_get
#TandoorMealTypeGetInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorMealTypeGetOutput: {
	success:    bool
	meal_type?: #TandoorMealType
	error?:     string
} | #ErrorOutput

// tandoor_meal_type_create
#TandoorMealTypeCreateInput: {
	tandoor: #TandoorResource
	name:   string
	order?: int
	time?:  #TandoorTime
	color?: #TandoorColor
}

#TandoorMealTypeCreateOutput: {
	success:    bool
	meal_type?: #TandoorMealType
	error?:     string
} | #ErrorOutput

// tandoor_meal_type_update
#TandoorMealTypeUpdateInput: {
	tandoor: #TandoorResource
	id:      int
	name?:   string
	order?:  int
	time?:   #TandoorTime
	color?:  #TandoorColor
}

#TandoorMealTypeUpdateOutput: {
	success:    bool
	meal_type?: #TandoorMealType
	error?:     string
} | #ErrorOutput

// tandoor_meal_type_delete
#TandoorMealTypeDeleteInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorMealTypeDeleteOutput: {
	success: bool
	error?:  string
} | #ErrorOutput

// =============================================================================
// KEYWORD BINARIES
// =============================================================================

// tandoor_keyword_list
#TandoorKeywordListInput: {
	tandoor: #TandoorResource
}

#TandoorKeywordListOutput: {
	success: true
	count:   int
	results: [...#TandoorKeyword]
} | #ErrorOutput

// tandoor_keyword_get
#TandoorKeywordGetInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorKeywordGetOutput: {
	success:  bool
	keyword?: #TandoorKeyword
	error?:   string
} | #ErrorOutput

// tandoor_keyword_create
#TandoorKeywordCreateInput: {
	tandoor: #TandoorResource
	name:   string
	label?: string
}

#TandoorKeywordCreateOutput: {
	success:  bool
	keyword?: #TandoorKeyword
	error?:   string
} | #ErrorOutput

// tandoor_keyword_update
#TandoorKeywordUpdateInput: {
	tandoor: #TandoorResource
	id:      int
	name?:   string
	label?:  string
}

#TandoorKeywordUpdateOutput: {
	success:  bool
	keyword?: #TandoorKeyword
	error?:   string
} | #ErrorOutput

// tandoor_keyword_delete
#TandoorKeywordDeleteInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorKeywordDeleteOutput: {
	success: bool
	error?:  string
} | #ErrorOutput

// =============================================================================
// INGREDIENT BINARIES
// =============================================================================

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

// tandoor_ingredient_get
#TandoorIngredientGetInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorIngredientGetOutput: {
	success:     bool
	ingredient?: #TandoorIngredient
	error?:      string
} | #ErrorOutput

// tandoor_ingredient_create
#TandoorIngredientCreateInput: {
	tandoor: #TandoorResource
	food:    int
	unit?:   int
	amount?: number
}

#TandoorIngredientCreateOutput: {
	success:     bool
	ingredient?: #TandoorIngredient
	error?:      string
} | #ErrorOutput

// tandoor_ingredient_update
#TandoorIngredientUpdateInput: {
	tandoor: #TandoorResource
	id:      int
	food?:   int
	unit?:   int
	amount?: number
}

#TandoorIngredientUpdateOutput: {
	success:     bool
	ingredient?: #TandoorIngredient
	error?:      string
} | #ErrorOutput

// tandoor_ingredient_delete
#TandoorIngredientDeleteInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorIngredientDeleteOutput: {
	success: bool
	error?:  string
} | #ErrorOutput

// tandoor_ingredient_from_string
#TandoorIngredientFromStringInput: {
	tandoor: #TandoorResource
	text:    string
}

#TandoorIngredientFromStringOutput: {
	success:     bool
	ingredient?: #ParsedIngredientOutput
	error?:      string
} | #ErrorOutput

#ParsedIngredientOutput: {
	amount?:       number
	unit?:         #TandoorUnitOutput
	food?:         #TandoorFoodOutput
	note?:         string
	original_text?: string
}

#TandoorUnitOutput: {
	id?:   int
	name:  string
}

#TandoorFoodOutput: {
	id?:   int
	name:  string
}

// =============================================================================
// FOOD BINARIES
// =============================================================================

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

// tandoor_food_get
#TandoorFoodGetInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorFoodGetOutput: {
	success: bool
	food?:   #TandoorFood
	error?:  string
} | #ErrorOutput

// tandoor_food_create
#TandoorFoodCreateInput: {
	tandoor: #TandoorResource
	name:        string
	description?: string
}

#TandoorFoodCreateOutput: {
	success: bool
	food?:   #TandoorFood
	error?:  string
} | #ErrorOutput

// tandoor_food_update
#TandoorFoodUpdateInput: {
	tandoor: #TandoorResource
	id:          int
	name?:       string
	description?: string
}

#TandoorFoodUpdateOutput: {
	success: bool
	food?:   #TandoorFood
	error?:  string
} | #ErrorOutput

// tandoor_food_delete
#TandoorFoodDeleteInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorFoodDeleteOutput: {
	success: bool
	error?:  string
} | #ErrorOutput

// tandoor_food_batch_update
#TandoorFoodBatchUpdateInput: {
	tandoor?:   #TandoorResource
	base_url?:  string & =~"^https?://"
	api_token?: string
	updates: [...#BatchUpdateFoodEntry]
}

#BatchUpdateFoodEntry: {
	id:           int
	name?:        string
	description?: string
}

#TandoorFoodBatchUpdateOutput: {
	success:       bool
	updated_count?: int
	updated_ids?:   [...int]
	error?:        string
} | #ErrorOutput

// =============================================================================
// UNIT BINARIES
// =============================================================================

// tandoor_unit_list
#TandoorUnitListInput: {
	tandoor: #TandoorResource
}

#TandoorUnitListOutput: {
	success: true
	count:   int
	results: [...#TandoorUnit]
} | #ErrorOutput

// tandoor_unit_get
#TandoorUnitGetInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorUnitGetOutput: {
	success: bool
	unit?:   #TandoorUnit
	error?:  string
} | #ErrorOutput

// tandoor_unit_create
#TandoorUnitCreateInput: {
	tandoor: #TandoorResource
	name:         string
	plural_name?: string
}

#TandoorUnitCreateOutput: {
	success: bool
	unit?:   #TandoorUnit
	error?:  string
} | #ErrorOutput

// tandoor_unit_update
#TandoorUnitUpdateInput: {
	tandoor: #TandoorResource
	id:          int
	name?:       string
	plural_name?: string
}

#TandoorUnitUpdateOutput: {
	success: bool
	unit?:   #TandoorUnit
	error?:  string
} | #ErrorOutput

// tandoor_unit_delete
#TandoorUnitDeleteInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorUnitDeleteOutput: {
	success: bool
	error?:  string
} | #ErrorOutput

// tandoor_unit_conversion_list
#TandoorUnitConversionListInput: {
	tandoor: #TandoorResource
}

#TandoorUnitConversionListOutput: {
	success:   bool
	conversions?: [...#TandoorUnitConversion]
	error?:    string
} | #ErrorOutput

// =============================================================================
// STEP BINARIES
// =============================================================================

// tandoor_step_list
#TandoorStepListInput: {
	tandoor: #TandoorResource
	recipe_id?: int
}

#TandoorStepListOutput: {
	success: bool
	steps?:  [...#TandoorStep]
	error?:  string
} | #ErrorOutput

// tandoor_step_get
#TandoorStepGetInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorStepGetOutput: {
	success: bool
	step?:   #TandoorStep
	error?:  string
} | #ErrorOutput

// tandoor_step_create
#TandoorStepCreateInput: {
	tandoor: #TandoorResource
	instruction: string
	recipe?:     int
	order?:      int
}

#TandoorStepCreateOutput: {
	success: bool
	step?:   #TandoorStep
	error?:  string
} | #ErrorOutput

// tandoor_step_update
#TandoorStepUpdateInput: {
	tandoor: #TandoorResource
	id:           int
	instruction?: string
	recipe?:      int
	order?:       int
}

#TandoorStepUpdateOutput: {
	success: bool
	step?:   #TandoorStep
	error?:  string
} | #ErrorOutput

// tandoor_step_delete
#TandoorStepDeleteInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorStepDeleteOutput: {
	success: bool
	error?:  string
} | #ErrorOutput

// =============================================================================
// RECIPE BOOK BINARIES
// =============================================================================

// tandoor_recipe_book_list
#TandoorRecipeBookListInput: {
	tandoor: #TandoorResource
}

#TandoorRecipeBookListOutput: {
	success: true
	count:   int
	results: [...#TandoorRecipeBook]
} | #ErrorOutput

// tandoor_recipe_book_get
#TandoorRecipeBookGetInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorRecipeBookGetOutput: {
	success:      bool
	recipe_book?: #TandoorRecipeBook
	error?:       string
} | #ErrorOutput

// tandoor_recipe_book_create
#TandoorRecipeBookCreateInput: {
	tandoor: #TandoorResource
	name:        string
	description?: string
	icon?:       string
}

#TandoorRecipeBookCreateOutput: {
	success:      bool
	recipe_book?: #TandoorRecipeBook
	error?:       string
} | #ErrorOutput

// tandoor_recipe_book_update
#TandoorRecipeBookUpdateInput: {
	tandoor: #TandoorResource
	id:          int
	name?:       string
	description?: string
	icon?:       string
}

#TandoorRecipeBookUpdateOutput: {
	success:      bool
	recipe_book?: #TandoorRecipeBook
	error?:       string
} | #ErrorOutput

// tandoor_recipe_book_delete
#TandoorRecipeBookDeleteInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorRecipeBookDeleteOutput: {
	success: bool
	error?:  string
} | #ErrorOutput

// tandoor_recipe_book_entry_list
#TandoorRecipeBookEntryListInput: {
	tandoor: #TandoorResource
	recipe_book?: int
}

#TandoorRecipeBookEntryListOutput: {
	success:             bool
	recipe_book_entries?: [...#TandoorRecipeBookEntry]
	error?:              string
} | #ErrorOutput

// tandoor_recipe_book_entry_get
#TandoorRecipeBookEntryGetInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorRecipeBookEntryGetOutput: {
	success:             bool
	recipe_book_entry?:  #TandoorRecipeBookEntry
	error?:              string
} | #ErrorOutput

// tandoor_recipe_book_entry_create
#TandoorRecipeBookEntryCreateInput: {
	tandoor: #TandoorResource
	recipe_book: int
	recipe:      int
	position?:   int
}

#TandoorRecipeBookEntryCreateOutput: {
	success:             bool
	recipe_book_entry?:  #TandoorRecipeBookEntry
	error?:              string
} | #ErrorOutput

// tandoor_recipe_book_entry_delete
#TandoorRecipeBookEntryDeleteInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorRecipeBookEntryDeleteOutput: {
	success: bool
	error?:  string
} | #ErrorOutput

// =============================================================================
// SHOPPING LIST BINARIES
// =============================================================================

// tandoor_shopping_list_entry_list
#TandoorShoppingListEntryListInput: {
	tandoor: #TandoorResource
	shopping_date?: #TandoorDate
}

#TandoorShoppingListEntryListOutput: {
	success: true
	results: [...#TandoorShoppingListEntry]
} | #ErrorOutput

// tandoor_shopping_list_entry_create
#TandoorShoppingListEntryCreateInput: {
	tandoor: #TandoorResource
	mealplan_id: int
	entry: {
		list:       int
		ingredient?: int
		unit?:      string
		amount?:    number
		food?:      string
		checked?:   bool
	}
}

#TandoorShoppingListEntryCreateOutput: {
	success: bool
	entry?:  #TandoorShoppingListEntry
	error?:  string
} | #ErrorOutput

// tandoor_shopping_list_entry_update
#TandoorShoppingListEntryUpdateInput: {
	tandoor: #TandoorResource
	id:      int
	entry: {
		list?:       int
		ingredient?: int
		unit?:       string
		amount?:     number
		food?:       string
		checked?:    bool
	}
}

#TandoorShoppingListEntryUpdateOutput: {
	success: bool
	entry?:  #TandoorShoppingListEntry
	error?:  string
} | #ErrorOutput

// tandoor_shopping_list_entry_delete
#TandoorShoppingListEntryDeleteInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorShoppingListEntryDeleteOutput: {
	success: bool
	error?:  string
} | #ErrorOutput

// tandoor_shopping_list_entry_bulk
#TandoorShoppingListEntryBulkInput: {
	tandoor: #TandoorResource
	entries: [...#CreateShoppingListEntryRequest]
}

#CreateShoppingListEntryRequest: {
	list:        int
	ingredient?: int
	unit?:       string
	amount?:     number
	food?:       string
	checked?:    bool
}

#TandoorShoppingListEntryBulkOutput: {
	success:       bool
	created_count?: int
	created_ids?:   [...int]
	error?:        string
} | #ErrorOutput

// tandoor_shopping_list_recipe_add
#TandoorShoppingListRecipeAddInput: {
	tandoor: #TandoorResource
	mealplan_id: int
	recipe_id:   int
	servings:    number
}

#TandoorShoppingListRecipeAddOutput: {
	success: bool
	entries?: [...#TandoorShoppingListRecipe]
	error?:  string
} | #ErrorOutput

// tandoor_shopping_list_recipe_get
#TandoorShoppingListRecipeGetInput: {
	tandoor: #TandoorResource
	mealplan_id: int
}

#TandoorShoppingListRecipeGetOutput: {
	success: bool
	entries?: [...#TandoorShoppingListRecipe]
	error?:  string
} | #ErrorOutput

// tandoor_shopping_list_recipe_delete
#TandoorShoppingListRecipeDeleteInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorShoppingListRecipeDeleteOutput: {
	success: bool
	error?:  string
} | #ErrorOutput

// =============================================================================
// SUPERMARKET BINARIES
// =============================================================================

// tandoor_supermarket_list
#TandoorSupermarketListInput: {
	tandoor: #TandoorResource
}

#TandoorSupermarketListOutput: {
	success: true
	count:   int
	results: [...#TandoorSupermarket]
} | #ErrorOutput

// tandoor_supermarket_get
#TandoorSupermarketGetInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorSupermarketGetOutput: {
	success:    bool
	supermarket?: #TandoorSupermarket
	error?:     string
} | #ErrorOutput

// tandoor_supermarket_create
#TandoorSupermarketCreateInput: {
	tandoor: #TandoorResource
	name:        string
	description?: string
}

#TandoorSupermarketCreateOutput: {
	success:    bool
	supermarket?: #TandoorSupermarket
	error?:     string
} | #ErrorOutput

// tandoor_supermarket_update
#TandoorSupermarketUpdateInput: {
	tandoor: #TandoorResource
	id:          int
	name?:       string
	description?: string
}

#TandoorSupermarketUpdateOutput: {
	success:    bool
	supermarket?: #TandoorSupermarket
	error?:     string
} | #ErrorOutput

// tandoor_supermarket_delete
#TandoorSupermarketDeleteInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorSupermarketDeleteOutput: {
	success: bool
	error?:  string
} | #ErrorOutput

// =============================================================================
// SPACE BINARIES
// =============================================================================

// tandoor_space_list
#TandoorSpaceListInput: {
	tandoor: #TandoorResource
}

#TandoorSpaceListOutput: {
	success: true
	count:   int
	results: [...#TandoorSpace]
} | #ErrorOutput

// tandoor_space_get
#TandoorSpaceGetInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorSpaceGetOutput: {
	success: bool
	space?:  #TandoorSpace
	error?:  string
} | #ErrorOutput

// =============================================================================
// PROPERTY BINARIES
// =============================================================================

// tandoor_property_type_list
#TandoorPropertyTypeListInput: {
	tandoor: #TandoorResource
}

#TandoorPropertyTypeListOutput: {
	success:  bool
	count:    int
	results?: [...#TandoorPropertyType]
	error?:   string
} | #ErrorOutput

#TandoorPropertyType: {
	id?:           int
	name:          string
	unit?:         string
	description?:  string
	order?:        int
	open_data_slug?: string
	fdc_id?:       int
	category?:     string
}

// tandoor_property_type_get
#TandoorPropertyTypeGetInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorPropertyTypeGetOutput: {
	success:      bool
	property_type?: #TandoorPropertyType
	error?:       string
} | #ErrorOutput

// tandoor_property_type_create
#TandoorPropertyTypeCreateInput: {
	tandoor: #TandoorResource
	name:       string
	unit?:      string
	description?: string
	order?:     int
	category?:  string
}

#TandoorPropertyTypeCreateOutput: {
	success:      bool
	property_type?: #TandoorPropertyType
	error?:       string
} | #ErrorOutput

// tandoor_property_type_update
#TandoorPropertyTypeUpdateInput: {
	tandoor: #TandoorResource
	id:           int
	name?:        string
	unit?:        string
	description?: string
	order?:       int
	category?:    string
}

#TandoorPropertyTypeUpdateOutput: {
	success:      bool
	property_type?: #TandoorPropertyType
	error?:       string
} | #ErrorOutput

// tandoor_property_type_delete
#TandoorPropertyTypeDeleteInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorPropertyTypeDeleteOutput: {
	success: bool
	error?:  string
} | #ErrorOutput

// tandoor_property_list
#TandoorPropertyListInput: {
	tandoor: #TandoorResource
	food_id?: int
}

#TandoorPropertyListOutput: {
	success:   bool
	properties?: [...#TandoorProperty]
	error?:    string
} | #ErrorOutput

#TandoorProperty: {
	id?:              int
	property_amount?: number
	property_type:    #TandoorPropertyType
}

// tandoor_property_get
#TandoorPropertyGetInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorPropertyGetOutput: {
	success:   bool
	property?: #TandoorProperty
	error?:    string
} | #ErrorOutput

// tandoor_property_create
#TandoorPropertyCreateInput: {
	tandoor: #TandoorResource
	property_amount: number
	property_type:   int
}

#TandoorPropertyCreateOutput: {
	success:   bool
	property?: #TandoorProperty
	error?:    string
} | #ErrorOutput

// tandoor_property_update
#TandoorPropertyUpdateInput: {
	tandoor: #TandoorResource
	id:              int
	property_amount?: number
	property_type?:   int
}

#TandoorPropertyUpdateOutput: {
	success:   bool
	property?: #TandoorProperty
	error?:    string
} | #ErrorOutput

// tandoor_property_delete
#TandoorPropertyDeleteInput: {
	tandoor: #TandoorResource
	id:      int
}

#TandoorPropertyDeleteOutput: {
	success: bool
	error?:  string
} | #ErrorOutput

// =============================================================================
// AI IMPORT BINARY
// =============================================================================

// tandoor_ai_import
#TandoorAIImportInput: {
	tandoor?:       #TandoorResource
	base_url?:      string & =~"^https?://"
	api_token?:     string
	file_path:      string
	ai_provider_id: int
	recipe_id?:     int
}

#TandoorAIImportOutput: {
	success:    bool
	recipe?:    #SourceImportRecipe
	recipe_id?: int
	images?:    [...string]
	duplicates?: [...#SourceImportDuplicate]
	message?:   string
	error?:     string
} | #ErrorOutput

#SourceImportDuplicate: {
	id:   int
	name: string
}

// =============================================================================
// SOURCE IMPORT RECIPE SCHEMA
// =============================================================================

#SourceImportRecipe: {
	name:           string
	description?:   string
	source_url?:    string
	image?:         string
	servings:       int & >=1
	servings_text?: string
	working_time?:  int
	waiting_time?:  int
	internal?:      bool
	keywords:       [...#SourceImportKeyword]
	steps:          [...#SourceImportStep]
}

#SourceImportKeyword: {
	id?:    int
	name:   string
	label?: string
}

#SourceImportStep: {
	instruction:           string
	show_ingredients_table?: bool
	ingredients?:          [...#SourceImportIngredient]
}

#SourceImportIngredient: {
	amount?:       number
	food?:         #SourceImportFood
	unit?:         #SourceImportUnit
	note?:         string
	original_text?: string
}

#SourceImportFood: {
	name: string
}

#SourceImportUnit: {
	name: string
}

// =============================================================================
// ORIGINAL LEGACY DEFINITIONS (kept for backward compatibility)
// =============================================================================

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
