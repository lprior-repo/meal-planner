/// High-concurrency PostgreSQL database initialization
/// Uses BEAM's process spawning for maximum parallel processing
///
/// Run with: gleam run -m scripts/init_pg
import envoy
import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import meal_planner/nutrition_constants
import pog
import simplifile

/// Main entry point
pub fn main() {
  io.println("=== Meal Planner PostgreSQL Database Initialization ===")
  io.println("Using maximum BEAM concurrency for fast imports")
  io.println("")

  // First create the database if it doesn't exist
  io.println("Ensuring database exists...")
  case create_database_if_needed() {
    Error(e) -> {
      io.println("Failed to create database: " <> e)
      io.println("")
      io.println(
        "Make sure PostgreSQL is running and you can connect as postgres user",
      )
      panic
    }
    Ok(_) -> {
      io.println("Database ready!")
      io.println("")
    }
  }

  // Create a named connection pool
  let pool_name = process.new_name(prefix: "meal_planner_pool")
  let config =
    pog.default_config(pool_name)
    |> pog.host("localhost")
    |> pog.port(5432)
    |> pog.database("meal_planner")
    |> pog.user("postgres")
    |> pog.password(Some("postgres"))
    |> pog.pool_size(nutrition_constants.pg_pool_size)

  // Start connection pool
  case pog.start(config) {
    Error(e) -> {
      io.println("Failed to start connection pool")
      io.println(format_start_error(e))
      panic
    }
    Ok(started) -> {
      let db = started.data

      // Check if tables exist (migrations already ran via psql)
      io.println("Checking schema...")
      case check_tables_exist(db) {
        False -> {
          io.println("Tables not found. Run migrations manually with psql:")
          io.println(
            "  psql -d meal_planner -f migrations_pg/001_schema_migrations.sql",
          )
          io.println(
            "  psql -d meal_planner -f migrations_pg/002_usda_tables.sql",
          )
          io.println(
            "  psql -d meal_planner -f migrations_pg/003_app_tables.sql",
          )
          panic
        }
        True -> {
          io.println("Schema OK!")
          io.println("")
        }
      }

      // Check if data already imported
      case check_data_imported(db) {
        True -> {
          io.println("USDA data already imported!")
          print_stats(db)
        }
        False -> {
          io.println("Starting parallel USDA import...")
          io.println(
            "Workers: "
            <> int.to_string(nutrition_constants.food_nutrient_import_workers)
            <> " concurrent connections",
          )
          io.println("")

          case parallel_import(db) {
            Ok(stats) -> {
              io.println("")
              io.println("=== Import Complete ===")
              io.println("  Nutrients: " <> int.to_string(stats.nutrients))
              io.println("  Foods: " <> int.to_string(stats.foods))
              io.println(
                "  Food nutrients: " <> int.to_string(stats.food_nutrients),
              )
              print_stats(db)
            }
            Error(e) -> {
              io.println("Import failed: " <> e)
            }
          }
        }
      }
    }
  }
}

type ImportStats {
  ImportStats(nutrients: Int, foods: Int, food_nutrients: Int)
}

fn format_start_error(e: actor.StartError) -> String {
  case e {
    actor.InitTimeout -> "Init timeout"
    actor.InitFailed(reason) -> "Init failed: " <> reason
    actor.InitExited(reason) -> "Init exited: " <> string.inspect(reason)
  }
}

fn create_database_if_needed() -> Result(Nil, String) {
  // Connect to default postgres database first
  let pool_name = process.new_name(prefix: "setup_pool")
  let config =
    pog.default_config(pool_name)
    |> pog.host("localhost")
    |> pog.port(5432)
    |> pog.database("postgres")
    |> pog.user("postgres")
    |> pog.password(Some("postgres"))
    |> pog.pool_size(1)

  case pog.start(config) {
    Error(_) -> Error("Cannot connect to PostgreSQL")
    Ok(started) -> {
      let db = started.data

      // Check if meal_planner database exists
      let check_query =
        pog.query("SELECT 1 FROM pg_database WHERE datname = 'meal_planner'")
        |> pog.returning(decode.at([0], decode.int))

      case pog.execute(check_query, db) {
        Ok(pog.Returned(0, _)) -> {
          // Database doesn't exist, create it
          io.println("Creating meal_planner database...")
          let create_query = pog.query("CREATE DATABASE meal_planner")
          case pog.execute(create_query, db) {
            Ok(_) -> Ok(Nil)
            Error(e) ->
              Error("Failed to create database: " <> format_pog_error(e))
          }
        }
        Ok(_) -> Ok(Nil)
        Error(e) -> Error("Failed to check database: " <> format_pog_error(e))
      }
    }
  }
}

fn format_pog_error(e: pog.QueryError) -> String {
  case e {
    pog.ConstraintViolated(msg, _, _) -> "Constraint violated: " <> msg
    pog.PostgresqlError(code, _, msg) ->
      "PostgreSQL error " <> code <> ": " <> msg
    pog.UnexpectedArgumentCount(_, _) -> "Unexpected argument count"
    pog.UnexpectedArgumentType(_, _) -> "Unexpected argument type"
    pog.UnexpectedResultType(_) -> "Unexpected result type"
    pog.QueryTimeout -> "Query timeout"
    pog.ConnectionUnavailable -> "Connection unavailable"
  }
}

fn check_tables_exist(db: pog.Connection) -> Bool {
  let query =
    pog.query(
      "SELECT COUNT(*) FROM information_schema.tables WHERE table_name IN ('foods', 'nutrients', 'food_nutrients', 'recipes')",
    )
    |> pog.returning(decode.at([0], decode.int))

  case pog.execute(query, db) {
    Ok(pog.Returned(_, [count])) -> count >= 4
    _ -> False
  }
}

fn check_data_imported(db: pog.Connection) -> Bool {
  let query =
    pog.query("SELECT COUNT(*) FROM foods")
    |> pog.returning(decode.at([0], decode.int))

  case pog.execute(query, db) {
    Ok(pog.Returned(_, [count])) ->
      count > nutrition_constants.import_batch_size
    _ -> False
  }
}

fn print_stats(db: pog.Connection) {
  io.println("")
  io.println("=== Database Statistics ===")

  let tables = [
    #("Nutrients", "SELECT COUNT(*) FROM nutrients"),
    #("Foods", "SELECT COUNT(*) FROM foods"),
    #("Food nutrients", "SELECT COUNT(*) FROM food_nutrients"),
    #("Recipes", "SELECT COUNT(*) FROM recipes"),
    #("Food logs", "SELECT COUNT(*) FROM food_logs"),
  ]

  list.each(tables, fn(pair) {
    let #(name, sql) = pair
    let query =
      pog.query(sql)
      |> pog.returning(decode.at([0], decode.int))
    case pog.execute(query, db) {
      Ok(pog.Returned(_, [count])) ->
        io.println("  " <> name <> ": " <> int.to_string(count))
      _ -> io.println("  " <> name <> ": <error>")
    }
  })
}

/// Message type for worker communication
type WorkerResult {
  WorkerDone(worker_id: Int, count: Int)
}

fn parallel_import(db: pog.Connection) -> Result(ImportStats, String) {
  let cache_dir = get_usda_cache_dir()
  let usda_dir = cache_dir <> "\\FoodData_Central_csv_2025-04-24"

  // Verify files exist
  case simplifile.is_file(usda_dir <> "\\food.csv") {
    Ok(True) -> {
      // Import nutrients first (small, quick)
      io.println("Importing nutrients...")
      let n_result =
        import_file_parallel(
          db,
          usda_dir <> "\\nutrient.csv",
          "nutrient",
          nutrition_constants.nutrient_import_workers,
        )

      case n_result {
        Error(e) -> Error(e)
        Ok(nutrients) -> {
          io.println("  -> " <> int.to_string(nutrients) <> " nutrients")

          // Import foods in parallel
          io.println(
            "Importing foods with "
            <> int.to_string(nutrition_constants.food_import_workers)
            <> " workers...",
          )
          let f_result =
            import_file_parallel(
              db,
              usda_dir <> "\\food.csv",
              "food",
              nutrition_constants.food_import_workers,
            )

          case f_result {
            Error(e) -> Error(e)
            Ok(foods) -> {
              io.println("  -> " <> int.to_string(foods) <> " foods")

              // Import food_nutrients with maximum parallelism
              io.println(
                "Importing food nutrients with "
                <> int.to_string(
                  nutrition_constants.food_nutrient_import_workers,
                )
                <> " workers...",
              )
              let fn_result =
                import_file_parallel(
                  db,
                  usda_dir <> "\\food_nutrient.csv",
                  "food_nutrient",
                  nutrition_constants.food_nutrient_import_workers,
                )

              case fn_result {
                Error(e) -> Error(e)
                Ok(food_nutrients) -> {
                  io.println(
                    "  -> "
                    <> int.to_string(food_nutrients)
                    <> " food nutrients",
                  )
                  Ok(ImportStats(nutrients, foods, food_nutrients))
                }
              }
            }
          }
        }
      }
    }
    _ -> Error("USDA data not found at: " <> usda_dir)
  }
}

fn get_usda_cache_dir() -> String {
  case envoy.get("LOCALAPPDATA") {
    Ok(local_app_data) -> local_app_data <> "\\meal-planner\\usda-cache"
    Error(_) -> {
      case envoy.get("HOME") {
        Ok(home) -> home <> "/.local/share/meal-planner/usda-cache"
        Error(_) -> "/tmp/meal-planner/usda-cache"
      }
    }
  }
}

/// Import a file using parallel workers with process.spawn
fn import_file_parallel(
  db: pog.Connection,
  file_path: String,
  file_type: String,
  num_workers: Int,
) -> Result(Int, String) {
  case simplifile.read(file_path) {
    Error(_) -> Error("Cannot read file: " <> file_path)
    Ok(content) -> {
      let lines =
        content
        |> string.split("\n")
        |> list.drop(1)
        // Skip header
        |> list.filter(fn(l) { l != "" && l != "\r" })

      let total = list.length(lines)
      io.println("    Processing " <> int.to_string(total) <> " rows...")

      // Split into chunks for parallel processing
      let chunk_size = total / num_workers + 1
      let chunks = split_into_chunks(lines, chunk_size, [])

      // Create a subject to receive results
      let result_subject: Subject(WorkerResult) = process.new_subject()

      // Spawn workers
      list.index_map(chunks, fn(chunk, idx) {
        let parent = result_subject
        process.spawn(fn() {
          let count = process_chunk(db, chunk, file_type, idx)
          process.send(parent, WorkerDone(idx, count))
        })
      })

      // Wait for all workers to complete
      let num_chunks = list.length(chunks)
      let total_inserted =
        collect_results(
          result_subject,
          num_chunks,
          0,
          nutrition_constants.worker_timeout_ms,
        )

      Ok(total_inserted)
    }
  }
}

fn collect_results(
  subject: Subject(WorkerResult),
  remaining: Int,
  acc: Int,
  timeout_ms: Int,
) -> Int {
  case remaining {
    0 -> acc
    _ -> {
      // Wait for a result with configured timeout
      case process.receive(subject, timeout_ms) {
        Ok(WorkerDone(_, count)) ->
          collect_results(subject, remaining - 1, acc + count, timeout_ms)
        Error(_) -> acc
      }
    }
  }
}

fn split_into_chunks(
  lines: List(String),
  chunk_size: Int,
  acc: List(List(String)),
) -> List(List(String)) {
  case list.split(lines, chunk_size) {
    #([], _) -> list.reverse(acc)
    #(chunk, rest) -> split_into_chunks(rest, chunk_size, [chunk, ..acc])
  }
}

fn process_chunk(
  db: pog.Connection,
  lines: List(String),
  file_type: String,
  worker_id: Int,
) -> Int {
  // Process in batches
  let batches =
    split_into_chunks(lines, nutrition_constants.import_batch_size, [])

  list.fold(batches, 0, fn(acc, batch) {
    let inserted = insert_batch(db, batch, file_type)
    let new_total = acc + inserted
    case new_total % nutrition_constants.progress_report_interval {
      0 ->
        io.println(
          "    Worker "
          <> int.to_string(worker_id)
          <> ": "
          <> int.to_string(new_total)
          <> " rows...",
        )
      _ -> Nil
    }
    new_total
  })
}

fn insert_batch(
  db: pog.Connection,
  lines: List(String),
  file_type: String,
) -> Int {
  case file_type {
    "nutrient" -> insert_nutrients_batch(db, lines)
    "food" -> insert_foods_batch(db, lines)
    "food_nutrient" -> insert_food_nutrients_batch(db, lines)
    _ -> 0
  }
}

fn insert_nutrients_batch(db: pog.Connection, lines: List(String)) -> Int {
  list.fold(lines, 0, fn(acc, line) {
    let fields = parse_csv_line(line)
    case fields {
      [id_str, name, unit, nbr, rank_str, ..] -> {
        case int.parse(id_str) {
          Ok(id) -> {
            let rank = result.unwrap(int.parse(rank_str), 0)
            let query =
              pog.query(
                "INSERT INTO nutrients (id, name, unit_name, nutrient_nbr, rank)
                 VALUES ($1, $2, $3, $4, $5)
                 ON CONFLICT (id) DO NOTHING",
              )
              |> pog.parameter(pog.int(id))
              |> pog.parameter(pog.text(name))
              |> pog.parameter(pog.text(unit))
              |> pog.parameter(pog.text(nbr))
              |> pog.parameter(pog.int(rank))

            case pog.execute(query, db) {
              Ok(_) -> acc + 1
              Error(_) -> acc
            }
          }
          Error(_) -> acc
        }
      }
      _ -> acc
    }
  })
}

fn insert_foods_batch(db: pog.Connection, lines: List(String)) -> Int {
  list.fold(lines, 0, fn(acc, line) {
    let fields = parse_csv_line(line)
    case fields {
      [fdc_id_str, data_type, description, category, pub_date, ..] -> {
        case int.parse(fdc_id_str) {
          Ok(fdc_id) -> {
            let query =
              pog.query(
                "INSERT INTO foods (fdc_id, data_type, description, food_category, publication_date)
                 VALUES ($1, $2, $3, $4, $5)
                 ON CONFLICT (fdc_id) DO NOTHING",
              )
              |> pog.parameter(pog.int(fdc_id))
              |> pog.parameter(pog.text(data_type))
              |> pog.parameter(pog.text(description))
              |> pog.parameter(pog.text(category))
              |> pog.parameter(pog.text(pub_date))

            case pog.execute(query, db) {
              Ok(_) -> acc + 1
              Error(_) -> acc
            }
          }
          Error(_) -> acc
        }
      }
      _ -> acc
    }
  })
}

fn insert_food_nutrients_batch(db: pog.Connection, lines: List(String)) -> Int {
  list.fold(lines, 0, fn(acc, line) {
    let fields = parse_csv_line(line)
    case fields {
      [id_str, fdc_id_str, nutrient_id_str, amount_str, ..] -> {
        case
          int.parse(id_str),
          int.parse(fdc_id_str),
          int.parse(nutrient_id_str)
        {
          Ok(id), Ok(fdc_id), Ok(nutrient_id) -> {
            let amount = parse_float_safe(amount_str)
            let query =
              pog.query(
                "INSERT INTO food_nutrients (id, fdc_id, nutrient_id, amount)
                 VALUES ($1, $2, $3, $4)
                 ON CONFLICT (id) DO NOTHING",
              )
              |> pog.parameter(pog.int(id))
              |> pog.parameter(pog.int(fdc_id))
              |> pog.parameter(pog.int(nutrient_id))
              |> pog.parameter(pog.float(amount))

            case pog.execute(query, db) {
              Ok(_) -> acc + 1
              Error(_) -> acc
            }
          }
          _, _, _ -> acc
        }
      }
      _ -> acc
    }
  })
}

fn parse_csv_line(line: String) -> List(String) {
  parse_csv_fields(line, [], "", False)
}

fn parse_csv_fields(
  remaining: String,
  fields: List(String),
  current: String,
  in_quotes: Bool,
) -> List(String) {
  case string.pop_grapheme(remaining) {
    Error(Nil) -> list.reverse([current, ..fields])
    Ok(#("\"", rest)) -> parse_csv_fields(rest, fields, current, !in_quotes)
    Ok(#(",", rest)) if !in_quotes ->
      parse_csv_fields(rest, [current, ..fields], "", False)
    Ok(#("\r", rest)) -> parse_csv_fields(rest, fields, current, in_quotes)
    Ok(#(char, rest)) ->
      parse_csv_fields(rest, fields, current <> char, in_quotes)
  }
}

fn parse_float_safe(s: String) -> Float {
  let cleaned = string.trim(s)
  case string.contains(cleaned, ".") {
    True ->
      case float_parse_ffi(cleaned) {
        f -> f
      }
    False ->
      case int.parse(cleaned) {
        Ok(i) -> int.to_float(i)
        Error(_) -> 0.0
      }
  }
}

@external(erlang, "erlang", "binary_to_float")
fn float_parse_ffi(s: String) -> Float
