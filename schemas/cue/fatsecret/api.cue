// FatSecret Platform API - CUE Schema
// Source of truth for Rust types, OpenAPI, and validation

package fatsecret

// =============================================================================
// COMMON TYPES
// =============================================================================

#DateInt: int & >=0
#FoodId: string & =~"^[0-9]+$"
#ServingId: string & =~"^[0-9]+$"
#FoodEntryId: string & =~"^[0-9]+$"
#RecipeId: string & =~"^[0-9]+$"
#ExerciseId: string & =~"^[0-9]+$"
#ExerciseEntryId: string & =~"^[0-9]+$"
#MealType: "breakfast" | "lunch" | "dinner" | "other" | "snack"
#FoodType: "Generic" | "Brand"
#Format: "json" | "xml"
#WeightUnit: "kg" | "lb"
#HeightUnit: "cm" | "inch"

// =============================================================================
// NUTRITION
// =============================================================================

#NutritionData: {
	calories?: number
	fat?: number
	saturated_fat?: number
	trans_fat?: number
	polyunsaturated_fat?: number
	monounsaturated_fat?: number
	cholesterol?: number
	sodium?: number
	carbohydrate?: number
	fiber?: number
	sugar?: number
	protein?: number
	vitamin_a?: number
	vitamin_c?: number
	calcium?: number
	iron?: number
	potassium?: number
}

#Serving: {
	serving_id: #ServingId
	serving_description: string
	serving_url?: string
	metric_serving_amount?: number
	metric_serving_unit?: string
	number_of_units?: number
	nutrition: #NutritionData
}

#FoodSummary: {
	food_id: #FoodId
	food_name: string
	food_type: #FoodType
	food_url?: string
	brand_name?: string
	...
}

#FoodComplete: #FoodSummary & {
	servings: {
		serving: [...#Serving]
	}
}

// =============================================================================
// FOODS
// =============================================================================

#FoodsSearchV3Input: {
	search_expression: string
	page_number?: int
	max_results?: int & <=50
	include_sub_categories?: bool
	include_food_images?: bool
	include_food_attributes?: bool
	flag_default_serving?: bool
	region?: string
	language?: string
	format?: #Format
}

#FoodsSearchV3Output: {
	success: true
	foods: {
		max_results: int
		page_number: int
		total_results: int
		food: [...#FoodSummary]
	}
}

#FoodsSearchV1Input: {
	search_expression: string
	page_number?: int
	max_results?: int & <=50
	format?: #Format
}

#FoodsSearchV1Output: {
	success: true
	foods: {
		max_results: int
		page_number: int
		total_results: int
		food: [...#FoodSummary]
	}
}

#FoodGetV1Input: {
	food_id: #FoodId
	format?: #Format
	include_sub_categories?: bool
	flag_default_serving?: bool
	region?: string
	language?: string
}

#FoodGetV1Output: {
	success: true
	food: #FoodComplete
}

#FoodsAutocompleteInput: {
	expression: string
	max_results?: int & <=20
	format?: #Format
}

#FoodsAutocompleteOutput: {
	success: true
	suggestions: [...{
		food_id: #FoodId
		food_name: string
		food_type: #FoodType
		score?: number
	}]
}

#FoodFindBarcodeInput: {
	barcode: string
	barcode_type?: string
	format?: #Format
}

#FoodFindBarcodeOutput: {
	success: true
	food?: #FoodComplete
}

#FoodCategoriesOutput: {
	success: true
	categories: {
		category: [...{
			category_id: string
			category_name: string
			category_description?: string
			food_category_type: string
		}]
	}
}

#FoodSubCategoriesInput: {
	category_id: string
	format?: #Format
}

#FoodSubCategoriesOutput: {
	success: true
	sub_categories: {
		sub_category: [...{
			sub_category_id: string
			sub_category_name: string
			parent_category_id: string
		}]
	}
}

#FoodBrandsInput: {
	page_number?: int
	max_results?: int & <=50
	format?: #Format
}

#FoodBrandsOutput: {
	success: true
	brands: {
		max_results: int
		page_number: int
		total_results: int
		brand: [...{
			brand_name: string
			brand_description?: string
		}]
	}
}

#FoodsGetFavoritesInput: {
	format?: #Format
}

#FoodsGetFavoritesOutput: {
	success: true
	favorites: {
		food: [...#FoodSummary]
	}
}

#FoodAddFavoriteInput: {
	food_id: #FoodId
	serving_id?: #ServingId
	number_of_units?: number & >0
	format?: #Format
}

#FoodAddFavoriteOutput: {
	success: true
}

#FoodDeleteFavoriteInput: {
	food_id: #FoodId
	format?: #Format
}

#FoodDeleteFavoriteOutput: {
	success: true
}

// =============================================================================
// DIARY
// =============================================================================

#FoodEntry: {
	food_entry_id: #FoodEntryId
	food_id: #FoodId
	food_entry_name: string
	serving_id: #ServingId
	number_of_units: number
	meal: #MealType
	date_int: #DateInt
	calories: number
	carbohydrate: number
	protein: number
	fat: number
	saturated_fat?: number
	polyunsaturated_fat?: number
	monounsaturated_fat?: number
	cholesterol?: number
	sodium?: number
	potassium?: number
	fiber?: number
	sugar?: number
}

#FoodEntriesGetInput: {
	date?: #DateInt
	food_entry_id?: #FoodEntryId
	format?: #Format
}

#FoodEntriesGetOutput: {
	success: true
	food_entries: {
		food_entry: [...#FoodEntry]
	}
}

#FoodEntryCreateInput: {
	food_id: #FoodId
	food_entry_name: string
	serving_id: #ServingId
	number_of_units: number & >0
	meal: #MealType
	date?: #DateInt
	format?: #Format
}

#FoodEntryCreateOutput: {
	success: true
	food_entry: #FoodEntry
}

#FoodEntryEditInput: {
	food_entry_id: #FoodEntryId
	food_id?: #FoodId
	food_entry_name?: string
	serving_id?: #ServingId
	number_of_units?: number & >0
	meal?: #MealType
	date?: #DateInt
	format?: #Format
}

#FoodEntryEditOutput: {
	success: true
}

#FoodEntryDeleteInput: {
	food_entry_id: #FoodEntryId
	format?: #Format
}

#FoodEntryDeleteOutput: {
	success: true
}

// =============================================================================
// RECIPES
// =============================================================================

#RecipeSummary: {
	recipe_id: #RecipeId
	recipe_name: string
	recipe_description?: string
	recipe_image?: string
	recipe_nutrition: {
		calories: number
		carbohydrate: number
		fat: number
		protein: number
	}
	recipe_ingredients?: {
		ingredient: [...string]
	}
	recipe_types?: {
		recipe_type: [...string]
	}
}

#RecipesSearchV2Input: {
	search_expression?: string
	must_have_images?: bool
	"calories.from"?: int & >=0
	"calories.to"?: int & >=0
	"carb_percentage.from"?: int & <=100
	"carb_percentage.to"?: int & <=100
	"protein_percentage.from"?: int & <=100
	"protein_percentage.to"?: int & <=100
	"fat_percentage.from"?: int & <=100
	"fat_percentage.to"?: int & <=100
	"prep_time.from"?: int & >=0
	"prep_time.to"?: int & >=0
	page_number?: int
	max_results?: int & <=50
	sort_by?: string
	region?: string
	format?: #Format
}

#RecipesSearchV2Output: {
	success: true
	recipes: {
		max_results: int
		page_number: int
		total_results: int
		recipe: [...#RecipeSummary]
	}
}

#RecipeGetV1Input: {
	recipe_id: #RecipeId
	format?: #Format
}

#RecipeGetV1Output: {
	success: true
	recipe: {
		recipe_id: #RecipeId
		recipe_name: string
		recipe_description?: string
		recipe_image?: string
		recipe_url?: string
		prep_time?: int
		cook_time?: int
		servings?: number
		serving_description?: string
		recipe_nutrition: #RecipeSummary["recipe_nutrition"]
		recipe_types?: {
			recipe_type: [...string]
		}
	}
}

#RecipeTypesOutput: {
	success: true
	recipe_types: {
		recipe_type: [...string]
	}
}

// =============================================================================
// PROFILE
// =============================================================================

#Profile: {
	weight_measure: #WeightUnit
	height_measure: #HeightUnit
	last_weight_kg: number
	last_weight_date_int: #DateInt
	last_weight_comment?: string
	goal_weight_kg: number
	height_cm: number
}

#ProfileGetInput: {
	format?: #Format
}

#ProfileGetOutput: {
	success: true
	profile: #Profile
}

#ProfileCreateInput: {
	weight_measure?: #WeightUnit
	height_measure?: #HeightUnit
	goal_weight_kg?: number
	height_cm?: number
	format?: #Format
}

#ProfileCreateOutput: {
	success: true
}

#ProfileGetAuthInput: {
	format?: #Format
}

#ProfileGetAuthOutput: {
	success: true
	authorized: bool
}

// =============================================================================
// EXERCISE
// =============================================================================

#ExerciseEntry: {
	exercise_entry_id: #ExerciseEntryId
	exercise_id: #ExerciseId
	exercise_name: string
	duration_minutes: int
	calories_burned: number
	date_int: #DateInt
}

#ExerciseEntriesGetInput: {
	date: #DateInt
	format?: #Format
}

#ExerciseEntriesGetOutput: {
	success: true
	exercise_entries: {
		exercise_entry: [...#ExerciseEntry]
	}
}

#ExerciseEntryCreateInput: {
	exercise_id: #ExerciseId
	duration_minutes: int & >=1 & <=1440
	date: #DateInt
	format?: #Format
}

#ExerciseEntryCreateOutput: {
	success: true
	exercise_entry: #ExerciseEntry
}

#ExerciseEntryEditInput: {
	exercise_entry_id: #ExerciseEntryId
	exercise_id?: #ExerciseId
	duration_minutes?: int & >=1 & <=1440
	format?: #Format
}

#ExerciseEntryEditOutput: {
	success: true
}

#ExerciseEntryDeleteInput: {
	exercise_entry_id: #ExerciseEntryId
	format?: #Format
}

#ExerciseEntryDeleteOutput: {
	success: true
}

#ExerciseMonthSummaryInput: {
	year: int & >=2000 & <=2100
	month: int & >=1 & <=12
	format?: #Format
}

#ExerciseMonthSummaryOutput: {
	success: true
	month_summary: {
		year: int
		month: int
		total_exercises: int
		total_duration_minutes: int
		total_calories_burned: number
	}
}

// =============================================================================
// SAVED MEALS
// =============================================================================

#SavedMeal: {
	saved_meal_id: string
	saved_meal_name: string
	foods: [...{
		food_id: #FoodId
		food_entry_name: string
		serving_id: #ServingId
		number_of_units: number
	}]
	meal_type: #MealType
}

#SavedMealsGetInput: {
	format?: #Format
}

#SavedMealsGetOutput: {
	success: true
	saved_meals: {
		saved_meal: [...#SavedMeal]
	}
}

#SavedMealCreateInput: {
	saved_meal_name: string
	foods: [...{
		food_id: #FoodId
		food_entry_name: string
		serving_id: #ServingId
		number_of_units: number & >0
	}]
	meal_type: #MealType
	format?: #Format
}

#SavedMealCreateOutput: {
	success: true
	saved_meal_id: string
}

#SavedMealDeleteInput: {
	saved_meal_id: string
	format?: #Format
}

#SavedMealDeleteOutput: {
	success: true
}

// =============================================================================
// WEIGHT
// =============================================================================

#WeightEntry: {
	weight_kg: number
	date_int: #DateInt
	comment?: string
}

#WeightGetInput: {
	format?: #Format
}

#WeightGetOutput: {
	success: true
	weights: {
		weight: [...#WeightEntry]
	}
}

#WeightEntryCreateInput: {
	weight_kg: number & >0
	date?: #DateInt
	comment?: string
	format?: #Format
}

#WeightEntryCreateOutput: {
	success: true
	weight_entry: #WeightEntry
}

#WeightEntryDeleteInput: {
	date_int: #DateInt
	format?: #Format
}

#WeightEntryDeleteOutput: {
	success: true
}

// =============================================================================
// IMAGE RECOGNITION
// =============================================================================

#ImageRecognitionInput: {
	image_url: string
	format?: #Format
}

#ImageRecognitionOutput: {
	success: true
	foods: [...{
		food_id: #FoodId
		food_name: string
		confidence: number
		servings: [...{
			serving_id: #ServingId
			serving_description: string
			number_of_units?: number
		}]
	}]
}

// =============================================================================
// NATURAL LANGUAGE
// =============================================================================

#NaturalLanguageInput: {
	text: string
	format?: #Format
}

#NaturalLanguageOutput: {
	success: true
	interpretations: [...{
		interpretation_type: string
		foods?: [...{
			food_id: #FoodId
			food_name: string
			serving_id: #ServingId
			number_of_units: number
			meal_type?: #MealType
		}]
		exercise?: {
			exercise_id: #ExerciseId
			duration_minutes: int
		}
		weight?: {
			weight_kg: number
		}
	}]
}

// =============================================================================
// API PATHS
// =============================================================================

#FoodsSearchPath: "/rest/foods/search/v3" | "/rest/foods/search/v1"
#FoodGetPath: "/rest/food/v1"
#FoodsAutocompletePath: "/rest/foods/autocomplete"
#FoodFindBarcodePath: "/rest/food/find-by-barcode"
#FoodCategoriesPath: "/rest/food-categories/get"
#FoodSubCategoriesPath: "/rest/food-sub-categories/get"
#FoodBrandsPath: "/rest/food-brands/get"
#FoodsFavoritesPath: "/rest/foods/get-favorites"
#FoodAddFavoritePath: "/rest/food/add-favorite"
#FoodDeleteFavoritePath: "/rest/food/delete-favorite"
#FoodEntriesPath: "/rest/food-entries/v1"
#FoodEntryCreatePath: "/rest/food-entries/v1"
#FoodEntryEditPath: "/rest/food-entries/v1"
#FoodEntryDeletePath: "/rest/food-entries/v1"
#RecipesSearchPath: "/rest/recipes/search/v2"
#RecipeGetPath: "/rest/recipe/v1"
#RecipeTypesPath: "/rest/recipe-types/get"
#ProfilePath: "/rest/profile/v1"
#ProfileCreatePath: "/rest/profile/create"
#ProfileGetAuthPath: "/rest/profile/get-auth"
#ExerciseEntriesPath: "/rest/exercise-entries/get"
#ExerciseEntryCreatePath: "/rest/exercise-entry/create"
#ExerciseEntryEditPath: "/rest/exercise-entry/edit"
#ExerciseEntryDeletePath: "/rest/exercise-entry/delete"
#ExerciseMonthSummaryPath: "/rest/exercise/month-summary"
#SavedMealsPath: "/rest/saved-meals/get"
#SavedMealCreatePath: "/rest/saved-meal/create"
#SavedMealDeletePath: "/rest/saved-meal/delete"
#WeightPath: "/rest/weight/get"
#WeightEntryCreatePath: "/rest/weight-entry/create"
#WeightEntryDeletePath: "/rest/weight-entry/delete"
#ImageRecognitionPath: "/rest/image/recognize"
#NaturalLanguagePath: "/rest/natural-language"

// =============================================================================
// ERROR
// =============================================================================

#Error: {
	success: false
	error: {
		code: string
		message: string
	}
}
