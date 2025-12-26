/// Preferences CLI domain - handles user preferences and settings
///
/// This module provides CLI commands for:
/// - Viewing current preferences
/// - Setting nutrition goals
/// - Managing dietary restrictions
/// - Configuring meal preferences
import gleam/float
import gleam/int
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import glint
import meal_planner/config.{type Config}
import meal_planner/id
import meal_planner/ncp.{type NutritionGoals, NutritionGoals}
import meal_planner/postgres
import meal_planner/storage/profile
import meal_planner/types/user_profile.{
  type UserProfile, Active, Gain, Lose, Maintain, Moderate, Sedentary,
  new_user_profile, user_profile_activity_level, user_profile_bodyweight,
  user_profile_goal, user_profile_id, user_profile_meals_per_day,
  user_profile_micronutrient_goals,
}
import pog

// ============================================================================
// Glint Command Handler
// ============================================================================

/// Preferences domain command for Glint CLI
pub fn cmd(config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("View and manage user preferences and settings")
  // Goal flags
  use calories <- glint.flag(
    glint.int_flag("calories")
    |> glint.flag_help("Daily calorie target (500-10000)"),
  )
  use protein <- glint.flag(
    glint.int_flag("protein")
    |> glint.flag_help("Daily protein target in grams (1-500)"),
  )
  use carbs <- glint.flag(
    glint.int_flag("carbs")
    |> glint.flag_help("Daily carbs target in grams (1-1000)"),
  )
  use fat <- glint.flag(
    glint.int_flag("fat")
    |> glint.flag_help("Daily fat target in grams (1-500)"),
  )
  // Profile flags
  use bodyweight <- glint.flag(
    glint.float_flag("bodyweight")
    |> glint.flag_help("Body weight in kg"),
  )
  use activity <- glint.flag(
    glint.string_flag("activity")
    |> glint.flag_help("Activity level: sedentary, moderate, active"),
  )
  use goal <- glint.flag(
    glint.string_flag("goal")
    |> glint.flag_help("Goal: gain, maintain, lose"),
  )
  use meals <- glint.flag(
    glint.int_flag("meals")
    |> glint.flag_help("Number of meals per day (1-10)"),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["view"] -> {
      case view_all_preferences(config) {
        Ok(output) -> {
          io.println(output)
          Ok(Nil)
        }
        Error(err) -> {
          io.println("Error: " <> err)
          Error(Nil)
        }
      }
    }
    ["goals"] -> {
      // Check if any goal flags were provided
      let calories_val = result_to_option(calories(flags))
      let protein_val = result_to_option(protein(flags))
      let carbs_val = result_to_option(carbs(flags))
      let fat_val = result_to_option(fat(flags))

      case calories_val, protein_val, carbs_val, fat_val {
        None, None, None, None -> {
          // No flags provided, display current goals
          case display_goals(config) {
            Ok(output) -> {
              io.println(output)
              Ok(Nil)
            }
            Error(err) -> {
              io.println("Error: " <> err)
              io.println("\nUsing default goals:")
              io.println(format_goals(ncp.get_default_goals()))
              Ok(Nil)
            }
          }
        }
        _, _, _, _ -> {
          // At least one flag provided, update goals
          case
            update_goals(
              config,
              calories: calories_val,
              protein: protein_val,
              carbs: carbs_val,
              fat: fat_val,
            )
          {
            Ok(output) -> {
              io.println(output)
              Ok(Nil)
            }
            Error(err) -> {
              io.println("Error: " <> err)
              Error(Nil)
            }
          }
        }
      }
    }
    ["profile"] -> {
      // Check if any profile flags were provided
      let bodyweight_val = result_to_option(bodyweight(flags))
      let activity_val = result_to_option(activity(flags))
      let goal_val = result_to_option(goal(flags))
      let meals_val = result_to_option(meals(flags))

      case bodyweight_val, activity_val, goal_val, meals_val {
        None, None, None, None -> {
          // No flags provided, display current profile
          case display_profile(config) {
            Ok(output) -> {
              io.println(output)
              Ok(Nil)
            }
            Error(err) -> {
              io.println("Error: " <> err)
              Error(Nil)
            }
          }
        }
        _, _, _, _ -> {
          // At least one flag provided, update profile
          case
            update_profile(
              config,
              bodyweight: bodyweight_val,
              activity: activity_val,
              goal: goal_val,
              meals: meals_val,
            )
          {
            Ok(output) -> {
              io.println(output)
              Ok(Nil)
            }
            Error(err) -> {
              io.println("Error: " <> err)
              Error(Nil)
            }
          }
        }
      }
    }
    ["dietary"] -> {
      io.println("Dietary Preferences")
      io.println(string.repeat("=", 50))
      io.println("")
      io.println("Dietary restrictions are configured per recipe filter.")
      io.println("Use the recipe search command with filters:")
      io.println("")
      io.println("  mp recipe search --fodmap low")
      io.println("  mp recipe search --vertical-diet")
      io.println("")
      io.println("Supported dietary modes:")
      io.println("  - FODMAP levels: low, medium, high")
      io.println("  - Vertical Diet compliance")
      io.println("  - Cuisine-based filtering")
      Ok(Nil)
    }
    ["meals"] -> {
      // View/set meals per day
      let meals_val = result_to_option(meals(flags))
      case meals_val {
        None -> {
          // Display current meal settings
          case display_meal_preferences(config) {
            Ok(output) -> {
              io.println(output)
              Ok(Nil)
            }
            Error(err) -> {
              io.println("Error: " <> err)
              Error(Nil)
            }
          }
        }
        Some(num_meals) -> {
          case update_meals_per_day(config, num_meals) {
            Ok(output) -> {
              io.println(output)
              Ok(Nil)
            }
            Error(err) -> {
              io.println("Error: " <> err)
              Error(Nil)
            }
          }
        }
      }
    }
    _ -> {
      io.println("Preferences commands:")
      io.println("")
      io.println(
        "  mp preferences view                    - View all preferences",
      )
      io.println(
        "  mp preferences goals                   - View nutrition goals",
      )
      io.println("  mp preferences goals --calories 2000   - Set calorie goal")
      io.println("  mp preferences goals --protein 150     - Set protein goal")
      io.println("  mp preferences profile                 - View user profile")
      io.println("  mp preferences profile --bodyweight 75 - Set body weight")
      io.println(
        "  mp preferences profile --activity moderate - Set activity level",
      )
      io.println("  mp preferences profile --goal maintain - Set goal")
      io.println("  mp preferences dietary                 - View dietary info")
      io.println(
        "  mp preferences meals                   - View meal settings",
      )
      io.println("  mp preferences meals --meals 4         - Set meals per day")
      Ok(Nil)
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

fn result_to_option(res: Result(a, b)) -> Option(a) {
  case res {
    Ok(val) -> Some(val)
    Error(_) -> None
  }
}

fn connect_db(config: Config) -> Result(pog.Connection, String) {
  let db_config =
    postgres.Config(
      host: config.database.host,
      port: config.database.port,
      database: config.database.name,
      user: config.database.user,
      password: case config.database.password {
        "" -> None
        pwd -> Some(pwd)
      },
      pool_size: config.database.pool_size,
    )

  postgres.connect(db_config)
  |> result.map_error(postgres.format_error)
}

fn storage_error_to_string(err: profile.StorageError) -> String {
  case err {
    profile.NotFound -> "Not found"
    profile.DatabaseError(msg) -> "Database error: " <> msg
    profile.InvalidInput(msg) -> "Invalid input: " <> msg
    profile.Unauthorized(msg) -> "Unauthorized: " <> msg
  }
}

// ============================================================================
// View All Preferences
// ============================================================================

fn view_all_preferences(config: Config) -> Result(String, String) {
  use conn <- result.try(connect_db(config))

  let header =
    string.repeat("=", 60)
    <> "\n"
    <> "                    USER PREFERENCES\n"
    <> string.repeat("=", 60)
    <> "\n"

  // Get user profile
  let profile_section = case profile.get_user_profile(conn) {
    Ok(p) -> format_profile_section(p)
    Error(_) -> "\nUser Profile: Not configured\n"
  }

  // Get nutrition goals
  let goals_section = case profile.get_goals(conn) {
    Ok(g) -> format_goals_section(g)
    Error(_) ->
      "\nNutrition Goals: Using defaults\n"
      <> format_goals_section(ncp.get_default_goals())
  }

  let footer = "\n" <> string.repeat("=", 60)

  Ok(header <> profile_section <> goals_section <> footer)
}

fn format_profile_section(p: UserProfile) -> String {
  let activity_str = case user_profile_activity_level(p) {
    Sedentary -> "Sedentary"
    Moderate -> "Moderate"
    Active -> "Active"
  }

  let goal_str = case user_profile_goal(p) {
    Gain -> "Muscle Gain"
    Maintain -> "Maintain Weight"
    Lose -> "Weight Loss"
  }

  "\nUSER PROFILE\n"
  <> string.repeat("-", 40)
  <> "\n"
  <> "  Body Weight:     "
  <> float_to_display(user_profile_bodyweight(p))
  <> " kg\n"
  <> "  Activity Level:  "
  <> activity_str
  <> "\n"
  <> "  Goal:            "
  <> goal_str
  <> "\n"
  <> "  Meals per Day:   "
  <> int.to_string(user_profile_meals_per_day(p))
  <> "\n"
}

fn format_goals_section(g: NutritionGoals) -> String {
  "\nNUTRITION GOALS\n"
  <> string.repeat("-", 40)
  <> "\n"
  <> "  Daily Calories:  "
  <> float_to_display(g.daily_calories)
  <> " kcal\n"
  <> "  Daily Protein:   "
  <> float_to_display(g.daily_protein)
  <> " g\n"
  <> "  Daily Carbs:     "
  <> float_to_display(g.daily_carbs)
  <> " g\n"
  <> "  Daily Fat:       "
  <> float_to_display(g.daily_fat)
  <> " g\n"
}

// ============================================================================
// Goals Management
// ============================================================================

fn display_goals(config: Config) -> Result(String, String) {
  use conn <- result.try(connect_db(config))

  case profile.get_goals(conn) {
    Ok(goals) -> {
      let output =
        "Daily Nutrition Goals\n"
        <> string.repeat("=", 40)
        <> "\n\n"
        <> build_goals_table(goals)
      Ok(output)
    }
    Error(err) -> Error(storage_error_to_string(err))
  }
}

fn update_goals(
  config: Config,
  calories calories_opt: Option(Int),
  protein protein_opt: Option(Int),
  carbs carbs_opt: Option(Int),
  fat fat_opt: Option(Int),
) -> Result(String, String) {
  use conn <- result.try(connect_db(config))

  // Get current goals or use defaults
  let current = case profile.get_goals(conn) {
    Ok(g) -> g
    Error(_) -> ncp.get_default_goals()
  }

  // Apply updates
  let updated =
    NutritionGoals(
      daily_calories: option.unwrap(
        option.map(calories_opt, int.to_float),
        current.daily_calories,
      ),
      daily_protein: option.unwrap(
        option.map(protein_opt, int.to_float),
        current.daily_protein,
      ),
      daily_carbs: option.unwrap(
        option.map(carbs_opt, int.to_float),
        current.daily_carbs,
      ),
      daily_fat: option.unwrap(
        option.map(fat_opt, int.to_float),
        current.daily_fat,
      ),
    )

  // Validate goals
  use _ <- result.try(
    ncp.nutrition_goals_validate(updated)
    |> result.map_error(fn(e) { "Validation error: " <> e }),
  )

  // Save to database
  case profile.save_goals(conn, updated) {
    Ok(_) -> {
      let output =
        "Nutrition goals updated successfully!\n\n"
        <> build_goals_table(updated)
      Ok(output)
    }
    Error(err) -> Error(storage_error_to_string(err))
  }
}

fn format_goals(goals: NutritionGoals) -> String {
  "Calories: "
  <> float_to_display(goals.daily_calories)
  <> " kcal | Protein: "
  <> float_to_display(goals.daily_protein)
  <> "g | Carbs: "
  <> float_to_display(goals.daily_carbs)
  <> "g | Fat: "
  <> float_to_display(goals.daily_fat)
  <> "g"
}

fn build_goals_table(goals: NutritionGoals) -> String {
  "┌─────────────┬──────────────┐\n"
  <> "│ Nutrient    │ Daily Goal   │\n"
  <> "├─────────────┼──────────────┤\n"
  <> "│ Calories    │ "
  <> pad_right(float_to_display(goals.daily_calories) <> " kcal", 12)
  <> " │\n"
  <> "│ Protein     │ "
  <> pad_right(float_to_display(goals.daily_protein) <> " g", 12)
  <> " │\n"
  <> "│ Carbs       │ "
  <> pad_right(float_to_display(goals.daily_carbs) <> " g", 12)
  <> " │\n"
  <> "│ Fat         │ "
  <> pad_right(float_to_display(goals.daily_fat) <> " g", 12)
  <> " │\n"
  <> "└─────────────┴──────────────┘"
}

// ============================================================================
// Profile Management
// ============================================================================

fn display_profile(config: Config) -> Result(String, String) {
  use conn <- result.try(connect_db(config))

  case profile.get_user_profile(conn) {
    Ok(p) -> {
      let output =
        "User Profile\n"
        <> string.repeat("=", 40)
        <> "\n"
        <> format_profile_section(p)
      Ok(output)
    }
    Error(err) -> Error(storage_error_to_string(err))
  }
}

fn update_profile(
  config: Config,
  bodyweight bodyweight_opt: Option(Float),
  activity activity_opt: Option(String),
  goal goal_opt: Option(String),
  meals meals_opt: Option(Int),
) -> Result(String, String) {
  use conn <- result.try(connect_db(config))

  // Get current profile or create default
  let current = case profile.get_user_profile(conn) {
    Ok(p) -> p
    Error(_) ->
      case
        new_user_profile(id.user_id("1"), 70.0, Moderate, Maintain, 3, None)
      {
        Ok(p) -> p
        Error(_) -> panic as "Default profile should always be valid"
      }
  }

  // Parse activity level
  use activity_level <- result.try(case activity_opt {
    Some("sedentary") -> Ok(Sedentary)
    Some("moderate") -> Ok(Moderate)
    Some("active") -> Ok(Active)
    Some(invalid) ->
      Error(
        "Invalid activity level: "
        <> invalid
        <> ". Use: sedentary, moderate, active",
      )
    None -> Ok(user_profile_activity_level(current))
  })

  // Parse goal
  use user_goal <- result.try(case goal_opt {
    Some("gain") -> Ok(Gain)
    Some("maintain") -> Ok(Maintain)
    Some("lose") -> Ok(Lose)
    Some(invalid) ->
      Error("Invalid goal: " <> invalid <> ". Use: gain, maintain, lose")
    None -> Ok(user_profile_goal(current))
  })

  // Validate meals
  use meals_per_day <- result.try(case meals_opt {
    Some(m) -> {
      case m >= 1 && m <= 10 {
        True -> Ok(m)
        False ->
          Error(
            "Invalid meals per day: "
            <> int.to_string(m)
            <> ". Must be between 1 and 10",
          )
      }
    }
    None -> Ok(user_profile_meals_per_day(current))
  })

  // Build updated profile
  let updated = case
    new_user_profile(
      user_profile_id(current),
      option.unwrap(bodyweight_opt, user_profile_bodyweight(current)),
      activity_level,
      user_goal,
      meals_per_day,
      user_profile_micronutrient_goals(current),
    )
  {
    Ok(profile) -> profile
    Error(err) -> {
      let _ = io.println("Error creating updated profile: " <> err)
      current
    }
  }

  // Save to database
  case profile.save_user_profile(conn, updated) {
    Ok(_) -> {
      let output =
        "Profile updated successfully!\n" <> format_profile_section(updated)
      Ok(output)
    }
    Error(err) -> Error(storage_error_to_string(err))
  }
}

// ============================================================================
// Meal Preferences
// ============================================================================

fn display_meal_preferences(config: Config) -> Result(String, String) {
  use conn <- result.try(connect_db(config))

  case profile.get_user_profile(conn) {
    Ok(p) -> {
      let output =
        "Meal Preferences\n"
        <> string.repeat("=", 40)
        <> "\n\n"
        <> "Meals per Day: "
        <> int.to_string(user_profile_meals_per_day(p))
        <> "\n\n"
        <> "Typical meal distribution:\n"
        <> format_meal_distribution(user_profile_meals_per_day(p))
      Ok(output)
    }
    Error(err) -> Error(storage_error_to_string(err))
  }
}

fn format_meal_distribution(meals_per_day: Int) -> String {
  case meals_per_day {
    1 -> "  1. Main meal (100%)\n"
    2 -> "  1. Lunch (50%)\n  2. Dinner (50%)\n"
    3 -> "  1. Breakfast (25%)\n  2. Lunch (35%)\n  3. Dinner (40%)\n"
    4 ->
      "  1. Breakfast (20%)\n  2. Lunch (30%)\n  3. Snack (15%)\n  4. Dinner (35%)\n"
    5 ->
      "  1. Breakfast (20%)\n  2. Morning Snack (10%)\n  3. Lunch (25%)\n  4. Afternoon Snack (10%)\n  5. Dinner (35%)\n"
    _ ->
      "  Custom distribution across "
      <> int.to_string(meals_per_day)
      <> " meals\n"
  }
}

fn update_meals_per_day(config: Config, meals: Int) -> Result(String, String) {
  // Validate
  case meals >= 1 && meals <= 10 {
    False ->
      Error(
        "Invalid meals per day: "
        <> int.to_string(meals)
        <> ". Must be between 1 and 10",
      )
    True -> {
      use conn <- result.try(connect_db(config))

      // Get current profile
      let current = case profile.get_user_profile(conn) {
        Ok(p) -> p
        Error(_) ->
          case
            new_user_profile(id.user_id("1"), 70.0, Moderate, Maintain, 3, None)
          {
            Ok(p) -> p
            Error(_) -> panic as "Default profile should always be valid"
          }
      }

      // Update meals per day
      let updated = case
        new_user_profile(
          user_profile_id(current),
          user_profile_bodyweight(current),
          user_profile_activity_level(current),
          user_profile_goal(current),
          meals,
          user_profile_micronutrient_goals(current),
        )
      {
        Ok(profile) -> profile
        Error(err) -> {
          let _ = io.println("Error creating updated profile: " <> err)
          current
        }
      }

      case profile.save_user_profile(conn, updated) {
        Ok(_) ->
          Ok(
            "Meals per day updated to "
            <> int.to_string(meals)
            <> "\n\n"
            <> format_meal_distribution(meals),
          )
        Error(err) -> Error(storage_error_to_string(err))
      }
    }
  }
}

// ============================================================================
// Formatting Helpers
// ============================================================================

fn float_to_display(f: Float) -> String {
  let str = float.to_string(f)
  case string.split(str, ".") {
    [whole, decimal] -> {
      let trimmed = string.slice(decimal, 0, 1)
      case trimmed {
        "0" -> whole
        d -> whole <> "." <> d
      }
    }
    _ -> str
  }
}

fn pad_right(s: String, width: Int) -> String {
  let len = string.length(s)
  case width > len {
    True -> s <> string.repeat(" ", width - len)
    False -> s
  }
}
