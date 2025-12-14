/// Tests for FatSecret Foods types
///
/// These tests verify opaque type constructors and converters.
import gleeunit/should
import meal_planner/fatsecret/foods/types

pub fn food_id_creation_test() {
  let id = types.food_id("12345")
  types.food_id_to_string(id)
  |> should.equal("12345")
}

pub fn food_id_round_trip_test() {
  let original = "987654"
  let id = types.food_id(original)
  let result = types.food_id_to_string(id)

  result
  |> should.equal(original)
}

pub fn serving_id_creation_test() {
  let id = types.serving_id("67890")
  types.serving_id_to_string(id)
  |> should.equal("67890")
}

pub fn serving_id_round_trip_test() {
  let original = "111222"
  let id = types.serving_id(original)
  let result = types.serving_id_to_string(id)

  result
  |> should.equal(original)
}

pub fn nutrition_construction_test() {
  let nutrition =
    types.Nutrition(
      calories: 150.0,
      carbohydrate: 20.0,
      protein: 5.0,
      fat: 8.0,
      saturated_fat: None,
      polyunsaturated_fat: None,
      monounsaturated_fat: None,
      cholesterol: None,
      sodium: None,
      potassium: None,
      fiber: None,
      sugar: None,
      vitamin_a: None,
      vitamin_c: None,
      calcium: None,
      iron: None,
    )

  nutrition.calories
  |> should.equal(150.0)

  nutrition.carbohydrate
  |> should.equal(20.0)

  nutrition.protein
  |> should.equal(5.0)

  nutrition.fat
  |> should.equal(8.0)
}

pub fn serving_construction_test() {
  let nutrition =
    types.Nutrition(
      calories: 95.0,
      carbohydrate: 25.0,
      protein: 0.5,
      fat: 0.3,
      saturated_fat: None,
      polyunsaturated_fat: None,
      monounsaturated_fat: None,
      cholesterol: None,
      sodium: None,
      potassium: None,
      fiber: None,
      sugar: None,
      vitamin_a: None,
      vitamin_c: None,
      calcium: None,
      iron: None,
    )

  let serving =
    types.Serving(
      serving_id: types.serving_id("1"),
      serving_description: "1 medium apple",
      serving_url: "https://example.com",
      metric_serving_amount: Some(182.0),
      metric_serving_unit: Some("g"),
      number_of_units: 1.0,
      measurement_description: "medium",
      nutrition: nutrition,
    )

  types.serving_id_to_string(serving.serving_id)
  |> should.equal("1")

  serving.serving_description
  |> should.equal("1 medium apple")

  serving.nutrition.calories
  |> should.equal(95.0)
}

pub fn food_construction_test() {
  let nutrition =
    types.Nutrition(
      calories: 95.0,
      carbohydrate: 25.0,
      protein: 0.5,
      fat: 0.3,
      saturated_fat: None,
      polyunsaturated_fat: None,
      monounsaturated_fat: None,
      cholesterol: None,
      sodium: None,
      potassium: None,
      fiber: None,
      sugar: None,
      vitamin_a: None,
      vitamin_c: None,
      calcium: None,
      iron: None,
    )

  let serving =
    types.Serving(
      serving_id: types.serving_id("1"),
      serving_description: "1 medium",
      serving_url: "https://example.com/s",
      metric_serving_amount: Some(182.0),
      metric_serving_unit: Some("g"),
      number_of_units: 1.0,
      measurement_description: "medium",
      nutrition: nutrition,
    )

  let food =
    types.Food(
      food_id: types.food_id("123"),
      food_name: "Apple",
      food_type: "Generic",
      food_url: "https://example.com/food",
      brand_name: None,
      servings: [serving],
    )

  types.food_id_to_string(food.food_id)
  |> should.equal("123")

  food.food_name
  |> should.equal("Apple")

  food.food_type
  |> should.equal("Generic")
}

pub fn food_search_result_construction_test() {
  let result =
    types.FoodSearchResult(
      food_id: types.food_id("456"),
      food_name: "Banana",
      food_type: "Generic",
      food_description: "Per 1 medium - Calories: 105kcal | Fat: 0.39g | Carbs: 27g | Protein: 1.29g",
      brand_name: None,
      food_url: "https://example.com/banana",
    )

  types.food_id_to_string(result.food_id)
  |> should.equal("456")

  result.food_name
  |> should.equal("Banana")
}

pub fn food_search_response_construction_test() {
  let result =
    types.FoodSearchResult(
      food_id: types.food_id("789"),
      food_name: "Orange",
      food_type: "Generic",
      food_description: "Per 1 medium - Calories: 62kcal | Fat: 0.16g | Carbs: 15g | Protein: 1.23g",
      brand_name: None,
      food_url: "https://example.com/orange",
    )

  let response =
    types.FoodSearchResponse(
      foods: [result],
      max_results: 20,
      total_results: 45,
      page_number: 0,
    )

  response.max_results
  |> should.equal(20)

  response.total_results
  |> should.equal(45)

  response.page_number
  |> should.equal(0)
}
