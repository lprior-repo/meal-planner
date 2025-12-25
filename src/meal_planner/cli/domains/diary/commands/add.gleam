/// Add commands for diary management
///
/// Provides functionality to add food entries to the FatSecret diary.
/// Searches the FatSecret food database and adds the first matching result.
import gleam/float
import gleam/io
import gleam/option.{None, Some}
import gleam/string
import meal_planner/cli/domains/diary/helpers
import meal_planner/config.{type Config}
import meal_planner/fatsecret/diary/service as diary_service
import meal_planner/fatsecret/diary/types.{
  type MealType, Breakfast, Dinner, FromFood, Lunch, Snack,
}
import meal_planner/fatsecret/foods/service as foods_service
import meal_planner/fatsecret/foods/types as foods_types

/// Parse meal type string to MealType
fn parse_meal_type(meal_type_str: String) -> Result(MealType, Nil) {
  case string.lowercase(meal_type_str) {
    "breakfast" -> Ok(Breakfast)
    "lunch" -> Ok(Lunch)
    "dinner" -> Ok(Dinner)
    "snack" | "other" -> Ok(Snack)
    _ -> Error(Nil)
  }
}

/// Handle add command - search for food and add to diary
///
/// Searches FatSecret food database for the given food name,
/// uses the first result, and adds it to the diary with the
/// specified quantity, meal type, and date.
pub fn add_handler(
  config: Config,
  food_name: String,
  date_str: String,
  meal_type_str: String,
  quantity_str: String,
) -> Result(Nil, Nil) {
  // Parse date
  case helpers.parse_date_to_int(date_str) {
    None -> {
      io.println("Error: Invalid date '" <> date_str <> "'")
      Error(Nil)
    }
    Some(date_int) -> {
      // Parse meal type
      case parse_meal_type(meal_type_str) {
        Error(_) -> {
          io.println(
            "Error: Invalid meal type '"
            <> meal_type_str
            <> "'. Use: breakfast, lunch, dinner, snack",
          )
          Error(Nil)
        }
        Ok(meal_type) -> {
          // Parse quantity
          case float.parse(quantity_str) {
            Error(_) -> {
              io.println("Error: Invalid quantity '" <> quantity_str <> "'")
              Error(Nil)
            }
            Ok(quantity) -> {
              // Search for food
              case
                foods_service.list_foods_with_options(food_name, None, Some(1))
              {
                Error(foods_service.NotConfigured) -> {
                  io.println("Error: FatSecret is not configured")
                  io.println(
                    "Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET",
                  )
                  Error(Nil)
                }
                Error(foods_service.ApiError(_)) -> {
                  io.println("Error: Failed to search foods")
                  Error(Nil)
                }
                Ok(search_response) -> {
                  case search_response.foods {
                    [] -> {
                      io.println(
                        "Error: No foods found matching '" <> food_name <> "'",
                      )
                      Error(Nil)
                    }
                    [first_food, ..] -> {
                      // Use first result
                      let food_id = first_food.food_id
                      let food_id_str =
                        foods_types.food_id_to_string(first_food.food_id)

                      io.println(
                        "Found: "
                        <> first_food.food_name
                        <> " (ID: "
                        <> food_id_str
                        <> ")",
                      )

                      // Fetch full food details to get servings
                      case foods_service.get_food(food_id) {
                        Error(foods_service.NotConfigured) -> {
                          io.println("Error: FatSecret is not configured")
                          Error(Nil)
                        }
                        Error(foods_service.ApiError(_)) -> {
                          io.println("Error: Failed to fetch food details")
                          Error(Nil)
                        }
                        Ok(full_food) -> {
                          case full_food.servings {
                            [] -> {
                              io.println(
                                "Error: No servings available for "
                                <> full_food.food_name,
                              )
                              Error(Nil)
                            }
                            [first_serving, ..] -> {
                              let serving_id =
                                foods_types.serving_id_to_string(
                                  first_serving.serving_id,
                                )

                              // Create database connection
                              case helpers.create_db_connection(config) {
                                Error(err) -> {
                                  io.println("Error: " <> err)
                                  Error(Nil)
                                }
                                Ok(conn) -> {
                                  let entry_input =
                                    FromFood(
                                      food_id: food_id_str,
                                      food_entry_name: full_food.food_name,
                                      serving_id: serving_id,
                                      number_of_units: quantity,
                                      meal: meal_type,
                                      date_int: date_int,
                                    )

                                  case
                                    diary_service.create_food_entry(
                                      conn,
                                      entry_input,
                                    )
                                  {
                                    Ok(_entry_id) -> {
                                      io.println(
                                        "✓ Added "
                                        <> full_food.food_name
                                        <> " x"
                                        <> float.to_string(quantity)
                                        <> " to diary",
                                      )
                                      Ok(Nil)
                                    }
                                    Error(diary_service.NotConfigured) -> {
                                      io.println(
                                        "Error: FatSecret is not configured",
                                      )
                                      Error(Nil)
                                    }
                                    Error(diary_service.AuthRevoked) -> {
                                      io.println(
                                        "Error: FatSecret authentication has been revoked",
                                      )
                                      Error(Nil)
                                    }
                                    Error(_) -> {
                                      io.println(
                                        "Error: Failed to add food entry to diary",
                                      )
                                      Error(Nil)
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
