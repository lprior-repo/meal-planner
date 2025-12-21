/// Generators for property-based testing of FatSecret decoders
///
/// This module provides simple list-based generators for testing edge cases in
/// FatSecret API response handling.
import gleam/list

/// Generator for flexible float string variants
///
/// Generates valid float formats that work reliably across all environments.
/// These are the string formats FatSecret API commonly returns.
pub fn flexible_float_strings() -> List(String) {
  [
    // Standard float strings with decimal point
    "0.0", "1.0", "2.0", "5.0", "42.0", "100.0", "999.0",
    // Common decimal values
    "1.5", "3.14", "0.99", "42.42", "100.1", "0.5", "0.25", "10.5", "99.99",
    // Larger decimal values
    "123.456", "1.001",
  ]
}

/// Generator for single or array JSON string structures
///
/// Generates JSON strings that match FatSecret's quirk of returning:
/// - Single object for 1 result
/// - Array for multiple results
///
/// Returns List of raw JSON strings for testing
pub fn single_or_array_json_strings() -> List(String) {
  [
    // Single object
    "{\"food_id\": \"123\", \"name\": \"Apple\"}",
    // Array with 2 items
    "[{\"food_id\": \"123\", \"name\": \"Apple\"}, {\"food_id\": \"456\", \"name\": \"Banana\"}]",
    // Empty array
    "[]",
  ]
}

/// Generator for flexible float JSON strings (number or string)
///
/// Returns JSON strings that can be either:
/// - Actual number: {"value": 1.5}
/// - String number: {"value": "1.5"}
pub fn flexible_float_json_strings() -> List(String) {
  flexible_float_strings()
  |> list.flat_map(fn(s) {
    [
      // String variant
      "{\"value\": \"" <> s <> "\"}",
      // Number variant (for simple cases)
      "{\"value\": " <> s <> "}",
    ]
  })
}

/// Generator for food search result JSON structures
///
/// Generates various edge cases for FatSecret search responses:
/// - Single result (returns object)
/// - Multiple results (returns array)
/// - Empty results
/// - Different pagination scenarios
pub fn food_search_response_json_strings() -> List(String) {
  [
    // Empty results
    "{\"foods\": {\"food\": [], \"max_results\": \"50\", \"total_results\": \"0\", \"page_number\": \"0\"}}",
    // Single result (object, not array)
    "{\"foods\": {\"food\": {\"food_id\": \"123\", \"food_name\": \"Apple\", \"food_type\": \"Generic\", \"food_description\": \"Per 100g - Calories: 52kcal\", \"food_url\": \"https://fatsecret.com/apple\"}, \"max_results\": \"50\", \"total_results\": \"1\", \"page_number\": \"0\"}}",
    // Two results (array)
    "{\"foods\": {\"food\": [{\"food_id\": \"123\", \"food_name\": \"Apple\", \"food_type\": \"Generic\", \"food_description\": \"Per 100g - Calories: 52kcal\", \"food_url\": \"https://fatsecret.com/apple\"}, {\"food_id\": \"456\", \"food_name\": \"Banana\", \"food_type\": \"Generic\", \"food_description\": \"Per 100g - Calories: 89kcal\", \"food_url\": \"https://fatsecret.com/banana\"}], \"max_results\": \"50\", \"total_results\": \"2\", \"page_number\": \"0\"}}",
    // Page 1 with pagination
    "{\"foods\": {\"food\": [{\"food_id\": \"789\", \"food_name\": \"Orange\", \"food_type\": \"Generic\", \"food_description\": \"Per 100g - Calories: 47kcal\", \"food_url\": \"https://fatsecret.com/orange\"}], \"max_results\": \"1\", \"total_results\": \"100\", \"page_number\": \"1\"}}",
    // Branded food with brand_name
    "{\"foods\": {\"food\": {\"food_id\": \"999\", \"food_name\": \"Cheerios\", \"food_type\": \"Brand\", \"food_description\": \"Per 1 cup - Calories: 100kcal\", \"brand_name\": \"General Mills\", \"food_url\": \"https://fatsecret.com/cheerios\"}, \"max_results\": \"50\", \"total_results\": \"1\", \"page_number\": \"0\"}}",
    // Max results edge case
    "{\"foods\": {\"food\": [], \"max_results\": 50, \"total_results\": 0, \"page_number\": 0}}",
  ]
}

/// Generator for nutrition JSON with edge cases
///
/// Tests flexible float handling with:
/// - String numbers: "95.5"
/// - Numeric numbers: 95.5
/// - Missing optional fields
/// - Zero values
pub fn nutrition_json_strings() -> List(String) {
  [
    // All required fields as strings
    "{\"calories\": \"100.0\", \"carbohydrate\": \"25.0\", \"protein\": \"5.0\", \"fat\": \"2.0\"}",
    // All required fields as numbers
    "{\"calories\": 100.0, \"carbohydrate\": 25.0, \"protein\": 5.0, \"fat\": 2.0}",
    // Mixed string/number with optionals
    "{\"calories\": \"150.5\", \"carbohydrate\": 30.0, \"protein\": \"10.5\", \"fat\": 5.0, \"saturated_fat\": \"2.5\", \"fiber\": 3.0}",
    // Zero values
    "{\"calories\": \"0.0\", \"carbohydrate\": \"0.0\", \"protein\": \"0.0\", \"fat\": \"0.0\"}",
    // All nutrition fields present
    "{\"calories\": 200.0, \"carbohydrate\": 40.0, \"protein\": 15.0, \"fat\": 8.0, \"saturated_fat\": 3.0, \"polyunsaturated_fat\": 2.0, \"monounsaturated_fat\": 2.0, \"trans_fat\": 0.0, \"cholesterol\": 10.0, \"sodium\": 200.0, \"potassium\": 300.0, \"fiber\": 5.0, \"sugar\": 10.0, \"added_sugars\": 5.0, \"vitamin_a\": 10.0, \"vitamin_c\": 20.0, \"vitamin_d\": 5.0, \"calcium\": 15.0, \"iron\": 8.0}",
    // String numbers with decimals
    "{\"calories\": \"123.456\", \"carbohydrate\": \"45.678\", \"protein\": \"12.345\", \"fat\": \"6.789\"}",
  ]
}

/// Generator for autocomplete response JSON structures
///
/// Tests single-vs-array quirk for suggestions
pub fn autocomplete_response_json_strings() -> List(String) {
  [
    // Single suggestion (object, not array)
    "{\"suggestions\": {\"suggestion\": {\"food_id\": \"123\", \"food_name\": \"Apple\"}}}",
    // Two suggestions (array)
    "{\"suggestions\": {\"suggestion\": [{\"food_id\": \"123\", \"food_name\": \"Apple\"}, {\"food_id\": \"456\", \"food_name\": \"Banana\"}]}}",
    // Many suggestions
    "{\"suggestions\": {\"suggestion\": [{\"food_id\": \"1\", \"food_name\": \"Apricot\"}, {\"food_id\": \"2\", \"food_name\": \"Avocado\"}, {\"food_id\": \"3\", \"food_name\": \"Almond\"}, {\"food_id\": \"4\", \"food_name\": \"Artichoke\"}]}}",
  ]
}

/// Generator for pagination parameter combinations
///
/// Returns tuples of (max_results, total_results, page_number)
pub fn pagination_edge_cases() -> List(#(Int, Int, Int)) {
  [
    // Empty results
    #(50, 0, 0),
    // First page, single page
    #(50, 10, 0),
    // First page, multiple pages
    #(50, 200, 0),
    // Second page
    #(50, 200, 1),
    // Last page (page 3 of 4)
    #(50, 200, 3),
    // Exactly one page boundary
    #(50, 50, 0),
    // Small max_results
    #(10, 100, 0),
    #(10, 100, 9),
    // Large total_results
    #(100, 10_000, 0),
    #(100, 10_000, 50),
  ]
}

/// Generator for serving JSON structures
///
/// Tests single-vs-array quirk and metric serving optionals
pub fn serving_json_strings() -> List(String) {
  [
    // Single serving with all fields
    "{\"serving_id\": \"1\", \"serving_description\": \"1 cup\", \"serving_url\": \"https://fatsecret.com/serving/1\", \"metric_serving_amount\": \"240.0\", \"metric_serving_unit\": \"ml\", \"number_of_units\": \"1.0\", \"measurement_description\": \"cup\", \"is_default\": \"1\", \"calories\": \"100.0\", \"carbohydrate\": \"25.0\", \"protein\": \"5.0\", \"fat\": \"2.0\"}",
    // Serving without metric info
    "{\"serving_id\": \"2\", \"serving_description\": \"1 piece\", \"serving_url\": \"https://fatsecret.com/serving/2\", \"number_of_units\": \"1.0\", \"measurement_description\": \"piece\", \"calories\": 50.0, \"carbohydrate\": 12.0, \"protein\": 2.0, \"fat\": 1.0}",
    // Serving with numeric values
    "{\"serving_id\": \"3\", \"serving_description\": \"100g\", \"serving_url\": \"https://fatsecret.com/serving/3\", \"metric_serving_amount\": 100.0, \"metric_serving_unit\": \"g\", \"number_of_units\": 1.0, \"measurement_description\": \"g\", \"is_default\": 1, \"calories\": 200.0, \"carbohydrate\": 40.0, \"protein\": 10.0, \"fat\": 5.0}",
  ]
}
