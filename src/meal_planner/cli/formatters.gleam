/// Output formatters for CLI results
///
/// Supports JSON, CSV, and human-readable table formats
import gleam/float
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/cli/types.{type Results}
import meal_planner/fatsecret/diary/types as diary
import meal_planner/fatsecret/exercise/types as exercise
import meal_planner/fatsecret/foods/types as food
import meal_planner/fatsecret/recipes/types as recipe
import meal_planner/fatsecret/weight/types as weight

pub fn format_json(results: Results) -> String {
  case results {
    types.FoodSearchResults(foods) -> encode_food_search_results_json(foods)
    types.FoodDetailResult(food_detail) -> encode_food_detail_json(food_detail)
    types.DiaryResults(entries) -> encode_diary_json(entries)
    types.ExerciseResults(entries) -> encode_exercise_json(entries)
    types.RecipeResults(recipes) -> encode_recipes_json(recipes)
    types.WeightResults(entries) -> encode_weight_json(entries)
    types.TextResults(text) ->
      json.object([#("data", json.string(text))])
      |> json.to_string
    types.ErrorResult(error) ->
      json.object([#("error", json.string(error))])
      |> json.to_string
  }
}

fn encode_food_search_results_json(foods: List(food.FoodSearchResult)) -> String {
  foods
  |> json.array(fn(f) {
    json.object([
      #("food_id", json.string(food.food_id_to_string(f.food_id))),
      #("food_name", json.string(f.food_name)),
      #("food_type", json.string(f.food_type)),
      #("food_description", json.string(f.food_description)),
      #("brand_name", encode_option_string(f.brand_name)),
    ])
  })
  |> json.to_string
}

fn encode_food_detail_json(f: food.Food) -> String {
  json.object([
    #("food_id", json.string(food.food_id_to_string(f.food_id))),
    #("food_name", json.string(f.food_name)),
    #("food_type", json.string(f.food_type)),
    #("brand_name", encode_option_string(f.brand_name)),
    #(
      "servings",
      json.array(f.servings, fn(s) {
        json.object([
          #("serving_description", json.string(s.serving_description)),
          #("calories", json.float(s.nutrition.calories)),
          #("carbohydrate", json.float(s.nutrition.carbohydrate)),
          #("protein", json.float(s.nutrition.protein)),
          #("fat", json.float(s.nutrition.fat)),
        ])
      }),
    ),
  ])
  |> json.to_string
}

fn encode_diary_json(entries: List(diary.FoodEntry)) -> String {
  entries
  |> json.array(fn(e) {
    json.object([
      #(
        "food_entry_id",
        json.string(diary.food_entry_id_to_string(e.food_entry_id)),
      ),
      #("food_entry_name", json.string(e.food_entry_name)),
      #("meal", json.string(diary.meal_type_to_string(e.meal))),
      #("date_int", json.int(e.date_int)),
      #("calories", json.float(e.calories)),
      #("carbohydrate", json.float(e.carbohydrate)),
      #("protein", json.float(e.protein)),
      #("fat", json.float(e.fat)),
    ])
  })
  |> json.to_string
}

fn encode_exercise_json(entries: List(exercise.ExerciseEntry)) -> String {
  entries
  |> json.array(fn(e) {
    json.object([
      #(
        "exercise_id",
        json.string(exercise.exercise_id_to_string(e.exercise_id)),
      ),
      #("exercise_name", json.string(e.exercise_name)),
      #("duration_min", json.int(e.duration_min)),
      #("calories", json.float(e.calories)),
      #("date_int", json.int(e.date_int)),
    ])
  })
  |> json.to_string
}

fn encode_recipes_json(recipes: List(recipe.Recipe)) -> String {
  recipes
  |> json.array(fn(r) {
    json.object([
      #("recipe_id", json.string(recipe.recipe_id_to_string(r.recipe_id))),
      #("recipe_name", json.string(r.recipe_name)),
      #("recipe_description", json.string(r.recipe_description)),
      #("number_of_servings", json.float(r.number_of_servings)),
      #(
        "ingredients",
        json.array(r.ingredients, fn(i) {
          json.object([
            #("food_name", json.string(i.food_name)),
            #("number_of_units", json.float(i.number_of_units)),
            #("measurement_description", json.string(i.measurement_description)),
          ])
        }),
      ),
      #("calories", encode_option_float(r.calories)),
      #("protein", encode_option_float(r.protein)),
      #("carbohydrate", encode_option_float(r.carbohydrate)),
      #("fat", encode_option_float(r.fat)),
    ])
  })
  |> json.to_string
}

fn encode_weight_json(entries: List(weight.WeightEntry)) -> String {
  entries
  |> json.array(fn(e) {
    json.object([
      #("date_int", json.int(e.date_int)),
      #("weight_kg", json.float(e.weight_kg)),
      #("weight_comment", encode_option_string(e.weight_comment)),
    ])
  })
  |> json.to_string
}

fn encode_option_string(opt: Option(String)) -> json.Json {
  case opt {
    Some(s) -> json.string(s)
    None -> json.null()
  }
}

fn encode_option_float(opt: Option(Float)) -> json.Json {
  case opt {
    Some(f) -> json.float(f)
    None -> json.null()
  }
}

pub fn format_table(results: Results) -> String {
  case results {
    types.FoodSearchResults(foods) -> format_food_search_table(foods)
    types.FoodDetailResult(food_detail) -> format_food_detail_table(food_detail)
    types.DiaryResults(entries) -> format_diary_table(entries)
    types.ExerciseResults(entries) -> format_exercise_table(entries)
    types.RecipeResults(recipes) -> format_recipes_table(recipes)
    types.WeightResults(entries) -> format_weight_table(entries)
    types.TextResults(text) -> text
    types.ErrorResult(error) -> "Error: " <> error
  }
}

fn format_food_search_table(foods: List(food.FoodSearchResult)) -> String {
  let header = "ID       | Name                      | Description"
  let separator =
    "---------|---------------------------|------------------------------------------"

  let rows =
    foods
    |> list.map(fn(f) {
      let id = food.food_id_to_string(f.food_id) |> pad_right(8)
      let name = f.food_name |> pad_right(25)
      let desc = f.food_description |> pad_right(40)

      id <> " | " <> name <> " | " <> desc
    })
    |> string.join("\n")

  header <> "\n" <> separator <> "\n" <> rows
}

fn format_food_detail_table(f: food.Food) -> String {
  let header =
    "ID       | Name                      | Calories | Protein | Carbs | Fat"
  let separator =
    "---------|---------------------------|----------|---------|-------|-----"

  let id = food.food_id_to_string(f.food_id) |> pad_right(8)
  let name = f.food_name |> pad_right(25)

  let calories = case list.first(f.servings) {
    Ok(s) -> float.to_string(s.nutrition.calories) |> pad_left(8)
    Error(_) -> pad_left("N/A", 8)
  }

  let protein = case list.first(f.servings) {
    Ok(s) -> float.to_string(s.nutrition.protein) |> pad_left(7)
    Error(_) -> pad_left("N/A", 7)
  }

  let carbs = case list.first(f.servings) {
    Ok(s) -> float.to_string(s.nutrition.carbohydrate) |> pad_left(5)
    Error(_) -> pad_left("N/A", 5)
  }

  let fat = case list.first(f.servings) {
    Ok(s) -> float.to_string(s.nutrition.fat) |> pad_left(4)
    Error(_) -> pad_left("N/A", 4)
  }

  let row =
    id
    <> " | "
    <> name
    <> " | "
    <> calories
    <> " | "
    <> protein
    <> " | "
    <> carbs
    <> " | "
    <> fat

  header <> "\n" <> separator <> "\n" <> row
}

fn format_diary_table(entries: List(diary.FoodEntry)) -> String {
  let header = "Date     | Meal      | Food                      | Calories"
  let separator = "---------|-----------|---------------------------|----------"

  let rows =
    entries
    |> list.map(fn(e) {
      let date = exercise.int_to_date(e.date_int) |> pad_right(8)
      let meal = diary.meal_type_to_string(e.meal) |> pad_right(9)
      let name = e.food_entry_name |> pad_right(25)
      let calories = float.to_string(e.calories) |> pad_left(8)

      date <> " | " <> meal <> " | " <> name <> " | " <> calories
    })
    |> string.join("\n")

  header <> "\n" <> separator <> "\n" <> rows
}

fn format_exercise_table(entries: List(exercise.ExerciseEntry)) -> String {
  let header = "Date     | Exercise                  | Duration | Calories"
  let separator = "---------|---------------------------|----------|----------"

  let rows =
    entries
    |> list.map(fn(e) {
      let date = exercise.int_to_date(e.date_int) |> pad_right(8)
      let name = e.exercise_name |> pad_right(25)
      let duration = int.to_string(e.duration_min) <> " min" |> pad_left(8)
      let calories = float.to_string(e.calories) |> pad_left(8)

      date <> " | " <> name <> " | " <> duration <> " | " <> calories
    })
    |> string.join("\n")

  header <> "\n" <> separator <> "\n" <> rows
}

fn format_recipes_table(recipes: List(recipe.Recipe)) -> String {
  let header = "ID       | Name                      | Servings | Calories"
  let separator = "---------|---------------------------|----------|----------"

  let rows =
    recipes
    |> list.map(fn(r) {
      let id = recipe.recipe_id_to_string(r.recipe_id) |> pad_right(8)
      let name = r.recipe_name |> pad_right(25)
      let servings = float.to_string(r.number_of_servings) |> pad_left(8)
      let calories = case r.calories {
        Some(c) -> float.to_string(c) |> pad_left(8)
        None -> pad_left("N/A", 8)
      }

      id <> " | " <> name <> " | " <> servings <> " | " <> calories
    })
    |> string.join("\n")

  header <> "\n" <> separator <> "\n" <> rows
}

fn format_weight_table(entries: List(weight.WeightEntry)) -> String {
  let header = "Date     | Weight (kg) | Comment"
  let separator = "---------|-------------|---------------------------"

  let rows =
    entries
    |> list.map(fn(e) {
      let date = exercise.int_to_date(e.date_int) |> pad_right(8)
      let weight_str = float.to_string(e.weight_kg) |> pad_left(11)
      let comment = case e.weight_comment {
        Some(c) -> c
        None -> ""
      }

      date <> " | " <> weight_str <> " | " <> comment
    })
    |> string.join("\n")

  header <> "\n" <> separator <> "\n" <> rows
}

pub fn format_csv(results: Results) -> String {
  case results {
    types.FoodSearchResults(foods) -> format_food_search_csv(foods)
    types.FoodDetailResult(food_detail) -> format_food_detail_csv(food_detail)
    types.DiaryResults(entries) -> format_diary_csv(entries)
    types.ExerciseResults(entries) -> format_exercise_csv(entries)
    types.RecipeResults(recipes) -> format_recipes_csv(recipes)
    types.WeightResults(entries) -> format_weight_csv(entries)
    types.TextResults(text) -> text
    types.ErrorResult(error) -> "error\n" <> escape_csv(error)
  }
}

fn format_food_search_csv(foods: List(food.FoodSearchResult)) -> String {
  let header = "food_id,food_name,food_type,food_description,brand_name"

  let rows =
    foods
    |> list.map(fn(f) {
      let id = food.food_id_to_string(f.food_id)
      let name = escape_csv(f.food_name)
      let food_type = escape_csv(f.food_type)
      let desc = escape_csv(f.food_description)
      let brand = case f.brand_name {
        Some(b) -> escape_csv(b)
        None -> ""
      }

      id <> "," <> name <> "," <> food_type <> "," <> desc <> "," <> brand
    })
    |> string.join("\n")

  header <> "\n" <> rows
}

fn format_food_detail_csv(f: food.Food) -> String {
  let header = "food_id,food_name,calories,protein,carbs,fat"

  let id = food.food_id_to_string(f.food_id)
  let name = escape_csv(f.food_name)

  let row = case list.first(f.servings) {
    Ok(s) -> {
      let calories = float.to_string(s.nutrition.calories)
      let protein = float.to_string(s.nutrition.protein)
      let carbs = float.to_string(s.nutrition.carbohydrate)
      let fat = float.to_string(s.nutrition.fat)

      id
      <> ","
      <> name
      <> ","
      <> calories
      <> ","
      <> protein
      <> ","
      <> carbs
      <> ","
      <> fat
    }
    Error(_) -> id <> "," <> name <> ",N/A,N/A,N/A,N/A"
  }

  header <> "\n" <> row
}

fn format_diary_csv(entries: List(diary.FoodEntry)) -> String {
  let header = "date,meal,food,calories,protein,carbs,fat"

  let rows =
    entries
    |> list.map(fn(e) {
      let date = exercise.int_to_date(e.date_int)
      let meal = diary.meal_type_to_string(e.meal)
      let name = escape_csv(e.food_entry_name)
      let calories = float.to_string(e.calories)
      let protein = float.to_string(e.protein)
      let carbs = float.to_string(e.carbohydrate)
      let fat = float.to_string(e.fat)

      date
      <> ","
      <> meal
      <> ","
      <> name
      <> ","
      <> calories
      <> ","
      <> protein
      <> ","
      <> carbs
      <> ","
      <> fat
    })
    |> string.join("\n")

  header <> "\n" <> rows
}

fn format_exercise_csv(entries: List(exercise.ExerciseEntry)) -> String {
  let header = "date,exercise,duration_min,calories"

  let rows =
    entries
    |> list.map(fn(e) {
      let date = exercise.int_to_date(e.date_int)
      let name = escape_csv(e.exercise_name)
      let duration = int.to_string(e.duration_min)
      let calories = float.to_string(e.calories)

      date <> "," <> name <> "," <> duration <> "," <> calories
    })
    |> string.join("\n")

  header <> "\n" <> rows
}

fn format_recipes_csv(recipes: List(recipe.Recipe)) -> String {
  let header = "recipe_id,recipe_name,servings,calories,protein,carbs,fat"

  let rows =
    recipes
    |> list.map(fn(r) {
      let id = recipe.recipe_id_to_string(r.recipe_id)
      let name = escape_csv(r.recipe_name)
      let servings = float.to_string(r.number_of_servings)
      let calories = case r.calories {
        Some(c) -> float.to_string(c)
        None -> "N/A"
      }
      let protein = case r.protein {
        Some(p) -> float.to_string(p)
        None -> "N/A"
      }
      let carbs = case r.carbohydrate {
        Some(c) -> float.to_string(c)
        None -> "N/A"
      }
      let fat = case r.fat {
        Some(f) -> float.to_string(f)
        None -> "N/A"
      }

      id
      <> ","
      <> name
      <> ","
      <> servings
      <> ","
      <> calories
      <> ","
      <> protein
      <> ","
      <> carbs
      <> ","
      <> fat
    })
    |> string.join("\n")

  header <> "\n" <> rows
}

fn format_weight_csv(entries: List(weight.WeightEntry)) -> String {
  let header = "date,weight_kg,comment"

  let rows =
    entries
    |> list.map(fn(e) {
      let date = exercise.int_to_date(e.date_int)
      let weight_str = float.to_string(e.weight_kg)
      let comment = case e.weight_comment {
        Some(c) -> escape_csv(c)
        None -> ""
      }

      date <> "," <> weight_str <> "," <> comment
    })
    |> string.join("\n")

  header <> "\n" <> rows
}

fn escape_csv(field: String) -> String {
  case
    string.contains(field, ",")
    || string.contains(field, "\"")
    || string.contains(field, "\n")
  {
    True -> "\"" <> string.replace(field, "\"", "\"\"") <> "\""
    False -> field
  }
}

fn pad_right(s: String, width: Int) -> String {
  let len = string.length(s)
  case len >= width {
    True -> string.slice(s, 0, width)
    False -> s <> string.repeat(" ", width - len)
  }
}

fn pad_left(s: String, width: Int) -> String {
  let len = string.length(s)
  case len >= width {
    True -> string.slice(s, 0, width)
    False -> string.repeat(" ", width - len) <> s
  }
}

pub fn format(results: Results) -> String {
  format_table(results)
}
