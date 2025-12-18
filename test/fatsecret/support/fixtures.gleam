/// Realistic FatSecret API response fixtures
///
/// These fixtures are based on actual FatSecret API responses and include
/// all the quirks and edge cases:
/// - Single vs array results
/// - Numeric strings vs numbers
/// - Optional fields
/// - Brand vs generic foods
import gleam/string

// ============================================================================
// Food API Responses (food.get.v5)
// ============================================================================

/// Complete food.get.v5 response with single serving
///
/// This is the structure returned when requesting a specific food by ID.
/// Note: FatSecret returns servings as an object when there's only one.
pub fn food_response() -> String {
  "{
    \"food\": {
      \"food_id\": \"33691\",
      \"food_name\": \"Apple\",
      \"food_type\": \"Generic\",
      \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/apple\",
      \"servings\": {
        \"serving\": {
          \"serving_id\": \"0\",
          \"serving_description\": \"1 medium (3\\\" dia)\",
          \"serving_url\": \"https://www.fatsecret.com/calories-nutrition/generic/apple\",
          \"metric_serving_amount\": \"182.000\",
          \"metric_serving_unit\": \"g\",
          \"number_of_units\": \"1.000\",
          \"measurement_description\": \"medium (3\\\" dia)\",
          \"calories\": \"95\",
          \"carbohydrate\": \"25.13\",
          \"protein\": \"0.47\",
          \"fat\": \"0.31\",
          \"saturated_fat\": \"0.051\",
          \"polyunsaturated_fat\": \"0.093\",
          \"monounsaturated_fat\": \"0.012\",
          \"cholesterol\": \"0\",
          \"sodium\": \"1\",
          \"potassium\": \"195\",
          \"fiber\": \"4.4\",
          \"sugar\": \"18.91\",
          \"vitamin_a\": \"2\",
          \"vitamin_c\": \"14\",
          \"calcium\": \"1\",
          \"iron\": \"1\"
        }
      }
    }
  }"
}

/// Food response with multiple servings
///
/// When a food has multiple servings, FatSecret returns them as an array.
pub fn food_multiple_servings_response() -> String {
  "{
    \"food\": {
      \"food_id\": \"174046\",
      \"food_name\": \"Milk\",
      \"food_type\": \"Generic\",
      \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/milk-whole\",
      \"servings\": {
        \"serving\": [
          {
            \"serving_id\": \"59788\",
            \"serving_description\": \"1 cup\",
            \"serving_url\": \"https://www.fatsecret.com/calories-nutrition/generic/milk-whole?portionid=59788\",
            \"metric_serving_amount\": \"244.000\",
            \"metric_serving_unit\": \"ml\",
            \"number_of_units\": \"1.000\",
            \"measurement_description\": \"cup\",
            \"calories\": \"149\",
            \"carbohydrate\": \"11.71\",
            \"protein\": \"7.69\",
            \"fat\": \"7.93\",
            \"saturated_fat\": \"4.551\",
            \"polyunsaturated_fat\": \"0.476\",
            \"monounsaturated_fat\": \"2.346\",
            \"cholesterol\": \"24\",
            \"sodium\": \"105\",
            \"potassium\": \"322\",
            \"fiber\": \"0.0\",
            \"sugar\": \"12.32\",
            \"vitamin_a\": \"5\",
            \"vitamin_c\": \"0\",
            \"calcium\": \"28\",
            \"iron\": \"0\"
          },
          {
            \"serving_id\": \"59789\",
            \"serving_description\": \"100 ml\",
            \"serving_url\": \"https://www.fatsecret.com/calories-nutrition/generic/milk-whole?portionid=59789\",
            \"metric_serving_amount\": \"100.000\",
            \"metric_serving_unit\": \"ml\",
            \"number_of_units\": \"100.000\",
            \"measurement_description\": \"ml\",
            \"calories\": \"61\",
            \"carbohydrate\": \"4.80\",
            \"protein\": \"3.15\",
            \"fat\": \"3.25\",
            \"saturated_fat\": \"1.865\",
            \"polyunsaturated_fat\": \"0.195\",
            \"monounsaturated_fat\": \"0.961\",
            \"cholesterol\": \"10\",
            \"sodium\": \"43\",
            \"potassium\": \"132\",
            \"fiber\": \"0.0\",
            \"sugar\": \"5.05\",
            \"vitamin_a\": \"2\",
            \"vitamin_c\": \"0\",
            \"calcium\": \"11\",
            \"iron\": \"0\"
          },
          {
            \"serving_id\": \"59790\",
            \"serving_description\": \"1 fl oz\",
            \"serving_url\": \"https://www.fatsecret.com/calories-nutrition/generic/milk-whole?portionid=59790\",
            \"metric_serving_amount\": \"30.500\",
            \"metric_serving_unit\": \"ml\",
            \"number_of_units\": \"1.000\",
            \"measurement_description\": \"fl oz\",
            \"calories\": \"19\",
            \"carbohydrate\": \"1.46\",
            \"protein\": \"0.96\",
            \"fat\": \"0.99\",
            \"saturated_fat\": \"0.569\",
            \"polyunsaturated_fat\": \"0.059\",
            \"monounsaturated_fat\": \"0.293\",
            \"cholesterol\": \"3\",
            \"sodium\": \"13\",
            \"potassium\": \"40\",
            \"fiber\": \"0.0\",
            \"sugar\": \"1.54\",
            \"vitamin_a\": \"1\",
            \"vitamin_c\": \"0\",
            \"calcium\": \"4\",
            \"iron\": \"0\"
          }
        ]
      }
    }
  }"
}

/// Branded food response
///
/// Branded foods include the brand_name field.
pub fn branded_food_response() -> String {
  "{
    \"food\": {
      \"food_id\": \"987654\",
      \"food_name\": \"Organic Whole Milk\",
      \"brand_name\": \"Organic Valley\",
      \"food_type\": \"Brand\",
      \"food_url\": \"https://www.fatsecret.com/calories-nutrition/organic-valley/organic-whole-milk\",
      \"servings\": {
        \"serving\": {
          \"serving_id\": \"12345\",
          \"serving_description\": \"1 cup\",
          \"serving_url\": \"https://www.fatsecret.com/calories-nutrition/organic-valley/organic-whole-milk\",
          \"metric_serving_amount\": \"240.000\",
          \"metric_serving_unit\": \"ml\",
          \"number_of_units\": \"1.000\",
          \"measurement_description\": \"cup\",
          \"calories\": \"150\",
          \"carbohydrate\": \"12.00\",
          \"protein\": \"8.00\",
          \"fat\": \"8.00\",
          \"saturated_fat\": \"5.00\",
          \"cholesterol\": \"30\",
          \"sodium\": \"125\",
          \"potassium\": \"350\",
          \"calcium\": \"30\",
          \"vitamin_a\": \"10\",
          \"vitamin_d\": \"25\"
        }
      }
    }
  }"
}

// ============================================================================
// Search API Responses (foods.search.v3)
// ============================================================================

/// Search response with multiple results
///
/// This is the typical structure when searching returns multiple foods.
pub fn food_search_response() -> String {
  "{
    \"foods\": {
      \"food\": [
        {
          \"food_id\": \"33691\",
          \"food_name\": \"Apple\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Per 1 medium (3\\\" dia) - Calories: 95kcal | Fat: 0.31g | Carbs: 25.13g | Protein: 0.47g\",
          \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/apple\"
        },
        {
          \"food_id\": \"41185\",
          \"food_name\": \"Apple Juice\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Per 1 cup - Calories: 114kcal | Fat: 0.28g | Carbs: 28.11g | Protein: 0.15g\",
          \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/apple-juice\"
        },
        {
          \"food_id\": \"35205\",
          \"food_name\": \"Applesauce\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Per 1 cup - Calories: 167kcal | Fat: 0.34g | Carbs: 43.26g | Protein: 0.41g\",
          \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/applesauce\"
        }
      ],
      \"max_results\": \"20\",
      \"total_results\": \"3\",
      \"page_number\": \"0\"
    }
  }"
}

/// Search response with single result
///
/// When search returns only one result, FatSecret returns an object instead of array.
/// This is a critical edge case!
pub fn food_search_single_response() -> String {
  "{
    \"foods\": {
      \"food\": {
        \"food_id\": \"33691\",
        \"food_name\": \"Apple\",
        \"food_type\": \"Generic\",
        \"food_description\": \"Per 1 medium (3\\\" dia) - Calories: 95kcal | Fat: 0.31g | Carbs: 25.13g | Protein: 0.47g\",
        \"food_url\": \"https://www.fatsecret.com/calories-nutrition/generic/apple\"
      },
      \"max_results\": \"20\",
      \"total_results\": \"1\",
      \"page_number\": \"0\"
    }
  }"
}

/// Search response with branded results
pub fn food_search_branded_response() -> String {
  "{
    \"foods\": {
      \"food\": [
        {
          \"food_id\": \"555111\",
          \"food_name\": \"Whole Milk\",
          \"brand_name\": \"Organic Valley\",
          \"food_type\": \"Brand\",
          \"food_description\": \"Per 1 cup - Calories: 150kcal | Fat: 8.00g | Carbs: 12.00g | Protein: 8.00g\",
          \"food_url\": \"https://www.fatsecret.com/calories-nutrition/organic-valley/whole-milk\"
        },
        {
          \"food_id\": \"555222\",
          \"food_name\": \"2% Milk\",
          \"brand_name\": \"Horizon Organic\",
          \"food_type\": \"Brand\",
          \"food_description\": \"Per 1 cup - Calories: 130kcal | Fat: 5.00g | Carbs: 13.00g | Protein: 8.00g\",
          \"food_url\": \"https://www.fatsecret.com/calories-nutrition/horizon-organic/2-milk\"
        }
      ],
      \"max_results\": \"20\",
      \"total_results\": \"2\",
      \"page_number\": \"0\"
    }
  }"
}

/// Empty search response
///
/// When no results are found.
pub fn empty_search_response() -> String {
  "{
    \"foods\": {
      \"max_results\": \"20\",
      \"total_results\": \"0\",
      \"page_number\": \"0\"
    }
  }"
}

// ============================================================================
// Recipe API Responses (recipe.get.v2)
// ============================================================================

/// Recipe response
pub fn recipe_response() -> String {
  "{
    \"recipe\": {
      \"recipe_id\": \"12345\",
      \"recipe_name\": \"Grilled Chicken Salad\",
      \"recipe_description\": \"A healthy and delicious grilled chicken salad\",
      \"recipe_url\": \"https://www.fatsecret.com/recipes/grilled-chicken-salad/Default.aspx\",
      \"recipe_image\": \"https://m.ftscrt.com/static/recipe/12345.jpg\",
      \"number_of_servings\": \"4\",
      \"preparation_time\": \"15\",
      \"cooking_time\": \"20\",
      \"rating\": \"4\",
      \"recipe_categories\": {
        \"recipe_category\": [
          {\"recipe_category_name\": \"Chicken\", \"recipe_category_url\": \"https://www.fatsecret.com/recipes/collections/chicken/Default.aspx\"},
          {\"recipe_category_name\": \"Salad\", \"recipe_category_url\": \"https://www.fatsecret.com/recipes/collections/salad/Default.aspx\"}
        ]
      },
      \"recipe_ingredients\": {
        \"ingredient\": [
          {\"ingredient_description\": \"4 chicken breasts\", \"ingredient_url\": \"https://www.fatsecret.com/calories-nutrition/generic/chicken-breast\"},
          {\"ingredient_description\": \"8 cups mixed greens\", \"ingredient_url\": \"https://www.fatsecret.com/calories-nutrition/generic/mixed-greens\"},
          {\"ingredient_description\": \"2 tomatoes\", \"ingredient_url\": \"https://www.fatsecret.com/calories-nutrition/generic/tomato\"},
          {\"ingredient_description\": \"1/2 cup balsamic vinegar\", \"ingredient_url\": \"https://www.fatsecret.com/calories-nutrition/generic/balsamic-vinegar\"}
        ]
      },
      \"directions\": {
        \"direction\": [
          {\"direction_description\": \"Grill chicken until cooked through\", \"direction_number\": \"1\"},
          {\"direction_description\": \"Slice chicken and place on greens\", \"direction_number\": \"2\"},
          {\"direction_description\": \"Add tomatoes and drizzle with vinegar\", \"direction_number\": \"3\"}
        ]
      },
      \"serving_sizes\": {
        \"serving\": {
          \"serving_id\": \"1\",
          \"calories\": \"320\",
          \"carbohydrate\": \"12.00\",
          \"protein\": \"45.00\",
          \"fat\": \"9.00\",
          \"saturated_fat\": \"2.00\",
          \"cholesterol\": \"95\",
          \"sodium\": \"250\",
          \"fiber\": \"3.00\",
          \"sugar\": \"6.00\"
        }
      }
    }
  }"
}

// ============================================================================
// OAuth API Responses
// ============================================================================

/// Request token response (OAuth step 1)
pub fn request_token_response() -> String {
  "oauth_token=abc123&oauth_token_secret=def456&oauth_callback_confirmed=true"
}

/// Access token response (OAuth step 3)
pub fn access_token_response() -> String {
  "oauth_token=xyz789&oauth_token_secret=uvw012"
}

// ============================================================================
// User Profile API Responses (profile.get)
// ============================================================================

/// User profile response
pub fn profile_response() -> String {
  "{
    \"profile\": {
      \"user_id\": \"user123\",
      \"height_cm\": \"175.0\",
      \"weight_kg\": \"75.5\",
      \"goal_weight_kg\": \"70.0\",
      \"date_of_birth\": \"1990-01-15\",
      \"gender\": \"M\",
      \"last_weight_date_int\": \"20251214\",
      \"last_weight_kg\": \"74.8\"
    }
  }"
}

// ============================================================================
// Food Diary API Responses (food_entries.get.v2)
// ============================================================================

/// Food entries response
pub fn food_entries_response() -> String {
  "{
    \"food_entries\": {
      \"food_entry\": [
        {
          \"food_entry_id\": \"123456\",
          \"food_id\": \"33691\",
          \"food_entry_name\": \"Apple\",
          \"serving_id\": \"0\",
          \"number_of_units\": \"1.00\",
          \"measurement_description\": \"medium (3\\\" dia)\",
          \"calories\": \"95\",
          \"carbohydrate\": \"25.13\",
          \"protein\": \"0.47\",
          \"fat\": \"0.31\",
          \"date_int\": \"20251214\"
        },
        {
          \"food_entry_id\": \"123457\",
          \"food_id\": \"174046\",
          \"food_entry_name\": \"Milk\",
          \"serving_id\": \"59788\",
          \"number_of_units\": \"1.00\",
          \"measurement_description\": \"cup\",
          \"calories\": \"149\",
          \"carbohydrate\": \"11.71\",
          \"protein\": \"7.69\",
          \"fat\": \"7.93\",
          \"date_int\": \"20251214\"
        }
      ]
    }
  }"
}

/// Empty food entries response
pub fn empty_food_entries_response() -> String {
  "{
    \"food_entries\": {}
  }"
}

// ============================================================================
// Error Responses
// ============================================================================

/// FatSecret API error response
///
/// All API errors follow this format, even for non-2xx HTTP responses.
pub fn error_response(code: Int, message: String) -> String {
  "{\"error\": {\"code\": "
  <> string.inspect(code)
  <> ", \"message\": \""
  <> message
  <> "\"}}"
}

/// Common error responses
pub fn missing_parameter_error() -> String {
  error_response(101, "Missing required parameter: search_expression")
}

pub fn invalid_parameter_error() -> String {
  error_response(102, "Invalid parameter value")
}

pub fn oauth_error() -> String {
  error_response(108, "Invalid / used nonce")
}

pub fn not_found_error() -> String {
  error_response(110, "Food not found")
}
