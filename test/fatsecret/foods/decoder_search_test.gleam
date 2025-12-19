/// Test for food search decoder - verifies handling of absent brand_name field
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleeunit/should
import meal_planner/fatsecret/foods/decoders

/// Test: Decoding array of foods without brand_name field
pub fn search_response_array_without_brand_name_test() {
  // FatSecret returns array for multiple results, NO brand_name for generic foods
  let response =
    "{
    \"foods\": {
      \"food\": [
        {
          \"food_id\": \"35755\",
          \"food_name\": \"Bananas\",
          \"food_type\": \"Generic\",
          \"food_description\": \"Per 100g - Calories: 89kcal\",
          \"food_url\": \"https://foods.fatsecret.com/calories-nutrition/usda/bananas\"
        }
      ],
      \"max_results\": \"3\",
      \"page_number\": \"0\",
      \"total_results\": \"1991\"
    }
  }"

  let result = json.parse(response, decoders.food_search_response_decoder())

  should.be_ok(result)
  let assert Ok(parsed) = result
  should.equal(
    parsed.foods |> list.first |> result.map(fn(f) { f.brand_name }),
    Ok(None),
  )
}

/// Test: Decoding SINGLE food object (not array) - FatSecret quirk when max_results=1
pub fn search_response_single_object_test() {
  // When max_results=1, FatSecret returns object NOT array
  let response =
    "{
    \"foods\": {
      \"food\": {
        \"food_id\": \"35755\",
        \"food_name\": \"Bananas\",
        \"food_type\": \"Generic\",
        \"food_description\": \"Per 100g - Calories: 89kcal\",
        \"food_url\": \"https://foods.fatsecret.com/calories-nutrition/usda/bananas\"
      },
      \"max_results\": \"1\",
      \"page_number\": \"0\",
      \"total_results\": \"1991\"
    }
  }"

  let result = json.parse(response, decoders.food_search_response_decoder())

  should.be_ok(result)
  let assert Ok(parsed) = result
  should.equal(list.length(parsed.foods), 1)
}

/// Test: brand_name present for branded foods
pub fn search_response_with_brand_name_test() {
  let response =
    "{
    \"foods\": {
      \"food\": [
        {
          \"food_id\": \"123456\",
          \"food_name\": \"Protein Bar\",
          \"food_type\": \"Brand\",
          \"food_description\": \"Per bar - Calories: 200kcal\",
          \"brand_name\": \"Quest\",
          \"food_url\": \"https://foods.fatsecret.com/calories-nutrition/quest/protein-bar\"
        }
      ],
      \"max_results\": \"3\",
      \"page_number\": \"0\",
      \"total_results\": \"500\"
    }
  }"

  let result = json.parse(response, decoders.food_search_response_decoder())

  should.be_ok(result)
  let assert Ok(parsed) = result
  should.equal(
    parsed.foods |> list.first |> result.map(fn(f) { f.brand_name }),
    Ok(Some("Quest")),
  )
}
