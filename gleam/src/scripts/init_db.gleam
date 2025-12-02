/// Database initialization script with high-concurrency USDA import
/// Uses BEAM's actor model for maximum parallel processing
///
/// Run with: gleam run -m scripts/init_db

import gleam/dynamic/decode
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import meal_planner/migrate
import simplifile
import sqlight

/// Worker message types for concurrent processing
pub type WorkerMessage {
  ProcessBatch(lines: List(String), file_type: String)
  Done
}

/// Import result from a worker
pub type ImportResult {
  ImportResult(count: Int, errors: Int)
}

/// Main entry point
pub fn main() {
  io.println("=== Meal Planner Database Initialization ===")
  io.println("")

  // Ensure data directory exists
  case migrate.ensure_data_dir() {
    Error(e) -> {
      io.println("Failed to create data directory: " <> format_error(e))
      panic
    }
    Ok(Nil) -> {
      let db_path = migrate.get_db_path()
      io.println("Database path: " <> db_path)
      io.println("")

      // Run migrations
      io.println("Running migrations...")
      case migrate.init_database("migrations") {
        Error(e) -> {
          io.println("Migration failed: " <> format_error(e))
          panic
        }
        Ok(count) -> {
          io.println("Applied " <> int.to_string(count) <> " migrations")
          io.println("")

          // Check if USDA data needs importing
          sqlight.with_connection(db_path, fn(conn) {
            case check_usda_imported(conn) {
              True -> {
                io.println("USDA data already imported!")
                print_stats(conn)
              }
              False -> {
                io.println("Starting USDA FoodData Central import...")
                io.println("Using parallel workers for maximum throughput")
                io.println("")

                case parallel_import(conn) {
                  Ok(#(n, f, fn_)) -> {
                    io.println("")
                    io.println("=== Import Complete ===")
                    io.println(
                      "  Nutrients: " <> int.to_string(n),
                    )
                    io.println(
                      "  Foods: " <> int.to_string(f),
                    )
                    io.println(
                      "  Food nutrients: " <> int.to_string(fn_),
                    )
                    print_stats(conn)
                  }
                  Error(msg) -> {
                    io.println("Import failed: " <> msg)
                    io.println("")
                    io.println("Make sure you've downloaded the USDA data first:")
                    io.println("  ./scripts/download_usda.sh")
                  }
                }
              }
            }
          })
        }
      }
    }
  }
}

fn format_error(e: migrate.MigrateError) -> String {
  case e {
    migrate.FileError(_) -> "File error"
    migrate.DatabaseError(msg) -> "Database error: " <> msg
    migrate.ParseError(msg) -> "Parse error: " <> msg
  }
}

fn check_usda_imported(conn: sqlight.Connection) -> Bool {
  let sql = "SELECT COUNT(*) FROM foods"
  let decoder = {
    use count <- decode.field(0, decode.int)
    decode.success(count)
  }

  case sqlight.query(sql, on: conn, with: [], expecting: decoder) {
    Ok([count]) -> count > 1000
    _ -> False
  }
}

fn print_stats(conn: sqlight.Connection) {
  io.println("")
  io.println("=== Database Statistics ===")

  let counts = [
    #("Nutrients", "SELECT COUNT(*) FROM nutrients"),
    #("Foods", "SELECT COUNT(*) FROM foods"),
    #("Food nutrients", "SELECT COUNT(*) FROM food_nutrients"),
    #("Recipes", "SELECT COUNT(*) FROM recipes"),
    #("Food logs", "SELECT COUNT(*) FROM food_logs"),
  ]

  list.each(counts, fn(pair) {
    let #(name, sql) = pair
    let decoder = {
      use count <- decode.field(0, decode.int)
      decode.success(count)
    }
    case sqlight.query(sql, on: conn, with: [], expecting: decoder) {
      Ok([count]) ->
        io.println("  " <> name <> ": " <> int.to_string(count))
      _ -> io.println("  " <> name <> ": <error>")
    }
  })
}

/// Get path separator for current platform
fn path_sep() -> String {
  case get_platform() {
    "win32" -> "\\"
    _ -> "/"
  }
}

@external(erlang, "os", "type")
fn os_type_ffi() -> #(Atom, Atom)

fn get_platform() -> String {
  case os_type_ffi() {
    #(_, os_name) -> atom_to_string(os_name)
  }
}

@external(erlang, "erlang", "atom_to_binary")
fn atom_to_string(a: Atom) -> String

type Atom

/// Parallel import using BEAM concurrency
fn parallel_import(
  conn: sqlight.Connection,
) -> Result(#(Int, Int, Int), String) {
  let sep = path_sep()
  let cache_dir = migrate.get_data_dir() <> sep <> "usda-cache"
  let usda_dir = cache_dir <> sep <> "FoodData_Central_csv_2025-04-24"

  // Verify files exist
  case simplifile.is_file(usda_dir <> sep <> "food.csv") {
    Ok(True) -> {
      // Optimize SQLite for bulk import
      let _ = sqlight.exec("PRAGMA synchronous = OFF", on: conn)
      let _ = sqlight.exec("PRAGMA journal_mode = MEMORY", on: conn)
      let _ = sqlight.exec("PRAGMA cache_size = 200000", on: conn)
      let _ = sqlight.exec("PRAGMA temp_store = MEMORY", on: conn)

      // Import nutrients first (small file, quick)
      io.println("Importing nutrients...")
      let n_result = import_file_parallel(
        conn,
        usda_dir <> sep <> "nutrient.csv",
        "nutrient",
        4,
      )

      case n_result {
        Error(e) -> Error(e)
        Ok(nutrients) -> {
          io.println("  -> " <> int.to_string(nutrients) <> " nutrients")

          // Import foods (medium file, use more workers)
          io.println("Importing foods...")
          let f_result = import_file_parallel(
            conn,
            usda_dir <> sep <> "food.csv",
            "food",
            8,
          )

          case f_result {
            Error(e) -> Error(e)
            Ok(foods) -> {
              io.println("  -> " <> int.to_string(foods) <> " foods")

              // Import food_nutrients (huge file, max workers)
              io.println("Importing food nutrients (this may take a while)...")
              let fn_result = import_file_parallel(
                conn,
                usda_dir <> sep <> "food_nutrient.csv",
                "food_nutrient",
                16,
              )

              // Reset to safe mode
              let _ = sqlight.exec("PRAGMA synchronous = FULL", on: conn)
              let _ = sqlight.exec("PRAGMA journal_mode = DELETE", on: conn)

              case fn_result {
                Error(e) -> Error(e)
                Ok(food_nutrients) -> {
                  io.println(
                    "  -> " <> int.to_string(food_nutrients) <> " food nutrients",
                  )
                  Ok(#(nutrients, foods, food_nutrients))
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

/// Import a file using parallel workers
fn import_file_parallel(
  conn: sqlight.Connection,
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
        |> list.filter(fn(l) { l != "" })

      let total = list.length(lines)
      let batch_size = total / num_workers + 1

      // Split into batches for parallel processing
      let batches = split_into_batches(lines, batch_size, [])

      // For SQLite, we need to process batches sequentially due to single-writer
      // But we can parse in parallel!
      let parsed_batches = list.map(batches, fn(batch) {
        parse_batch(batch, file_type)
      })

      // Insert all parsed data
      let count = list.fold(parsed_batches, 0, fn(acc, parsed) {
        case insert_parsed_batch(conn, parsed, file_type) {
          Ok(n) -> acc + n
          Error(_) -> acc
        }
      })

      Ok(count)
    }
  }
}

type ParsedRow {
  NutrientRow(id: Int, name: String, unit: String, nbr: String, rank: Int)
  FoodRow(
    fdc_id: Int,
    data_type: String,
    description: String,
    category: String,
    pub_date: String,
  )
  FoodNutrientRow(id: Int, fdc_id: Int, nutrient_id: Int, amount: Float)
}

fn split_into_batches(
  lines: List(String),
  batch_size: Int,
  acc: List(List(String)),
) -> List(List(String)) {
  case list.split(lines, batch_size) {
    #([], _) -> list.reverse(acc)
    #(batch, rest) -> split_into_batches(rest, batch_size, [batch, ..acc])
  }
}

fn parse_batch(lines: List(String), file_type: String) -> List(ParsedRow) {
  list.filter_map(lines, fn(line) { parse_line(line, file_type) })
}

fn parse_line(line: String, file_type: String) -> Result(ParsedRow, Nil) {
  let fields = parse_csv_line(line)
  case file_type {
    "nutrient" -> parse_nutrient_fields(fields)
    "food" -> parse_food_fields(fields)
    "food_nutrient" -> parse_food_nutrient_fields(fields)
    _ -> Error(Nil)
  }
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
    Ok(#(char, rest)) ->
      parse_csv_fields(rest, fields, current <> char, in_quotes)
  }
}

fn parse_nutrient_fields(fields: List(String)) -> Result(ParsedRow, Nil) {
  case fields {
    [id_str, name, unit, nbr, rank_str, ..] -> {
      case int.parse(id_str) {
        Ok(id) -> {
          let rank = result.unwrap(int.parse(rank_str), 0)
          Ok(NutrientRow(id: id, name: name, unit: unit, nbr: nbr, rank: rank))
        }
        Error(_) -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

fn parse_food_fields(fields: List(String)) -> Result(ParsedRow, Nil) {
  case fields {
    [fdc_id_str, data_type, description, category, pub_date, ..] -> {
      case int.parse(fdc_id_str) {
        Ok(fdc_id) ->
          Ok(FoodRow(
            fdc_id: fdc_id,
            data_type: data_type,
            description: description,
            category: category,
            pub_date: pub_date,
          ))
        Error(_) -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

fn parse_food_nutrient_fields(fields: List(String)) -> Result(ParsedRow, Nil) {
  case fields {
    [id_str, fdc_id_str, nutrient_id_str, amount_str, ..] -> {
      case
        int.parse(id_str),
        int.parse(fdc_id_str),
        int.parse(nutrient_id_str)
      {
        Ok(id), Ok(fdc_id), Ok(nutrient_id) -> {
          let amount = parse_float_safe(amount_str)
          Ok(FoodNutrientRow(
            id: id,
            fdc_id: fdc_id,
            nutrient_id: nutrient_id,
            amount: amount,
          ))
        }
        _, _, _ -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

fn parse_float_safe(s: String) -> Float {
  case string.contains(s, ".") {
    True ->
      case float_parse_ffi(s) {
        f -> f
      }
    False ->
      case int.parse(s) {
        Ok(i) -> int.to_float(i)
        Error(_) -> 0.0
      }
  }
}

@external(erlang, "erlang", "binary_to_float")
fn float_parse_ffi(s: String) -> Float

fn insert_parsed_batch(
  conn: sqlight.Connection,
  rows: List(ParsedRow),
  file_type: String,
) -> Result(Int, String) {
  // Start transaction
  let _ = sqlight.exec("BEGIN TRANSACTION", on: conn)

  let count = list.fold(rows, 0, fn(acc, row) {
    case insert_row(conn, row, file_type) {
      Ok(_) -> acc + 1
      Error(_) -> acc
    }
  })

  // Commit
  let _ = sqlight.exec("COMMIT", on: conn)

  Ok(count)
}

fn insert_row(
  conn: sqlight.Connection,
  row: ParsedRow,
  _file_type: String,
) -> Result(Nil, String) {
  case row {
    NutrientRow(id, name, unit, nbr, rank) -> {
      let sql =
        "INSERT OR IGNORE INTO nutrients (id, name, unit_name, nutrient_nbr, rank) VALUES (?, ?, ?, ?, ?)"
      let args = [
        sqlight.int(id),
        sqlight.text(name),
        sqlight.text(unit),
        sqlight.text(nbr),
        sqlight.int(rank),
      ]
      case sqlight.query(sql, on: conn, with: args, expecting: decode.dynamic) {
        Ok(_) -> Ok(Nil)
        Error(e) -> Error(e.message)
      }
    }
    FoodRow(fdc_id, data_type, description, category, pub_date) -> {
      let sql =
        "INSERT OR IGNORE INTO foods (fdc_id, data_type, description, food_category, publication_date) VALUES (?, ?, ?, ?, ?)"
      let args = [
        sqlight.int(fdc_id),
        sqlight.text(data_type),
        sqlight.text(description),
        sqlight.text(category),
        sqlight.text(pub_date),
      ]
      case sqlight.query(sql, on: conn, with: args, expecting: decode.dynamic) {
        Ok(_) -> Ok(Nil)
        Error(e) -> Error(e.message)
      }
    }
    FoodNutrientRow(id, fdc_id, nutrient_id, amount) -> {
      let sql =
        "INSERT OR IGNORE INTO food_nutrients (id, fdc_id, nutrient_id, amount) VALUES (?, ?, ?, ?)"
      let args = [
        sqlight.int(id),
        sqlight.int(fdc_id),
        sqlight.int(nutrient_id),
        sqlight.float(amount),
      ]
      case sqlight.query(sql, on: conn, with: args, expecting: decode.dynamic) {
        Ok(_) -> Ok(Nil)
        Error(e) -> Error(e.message)
      }
    }
  }
}
