/// USDA FoodData Central CSV importer
/// Downloads and imports food/nutrient data to SQLite
import gleam/dynamic/decode
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/migrate
import simplifile
import sqlight

/// Import error types
pub type ImportError {
  FileNotFound(String)
  ParseError(String)
  DatabaseError(String)
  ZipError(String)
}

/// USDA Nutrient definition
pub type Nutrient {
  Nutrient(
    id: Int,
    name: String,
    unit_name: String,
    nutrient_nbr: Option(String),
    rank: Option(Int),
  )
}

/// USDA Food item
pub type Food {
  Food(
    fdc_id: Int,
    data_type: String,
    description: String,
    food_category: Option(String),
    publication_date: Option(String),
  )
}

/// USDA Food nutrient value
pub type FoodNutrient {
  FoodNutrient(id: Int, fdc_id: Int, nutrient_id: Int, amount: Option(Float))
}

/// Get the USDA cache directory
pub fn get_cache_dir() -> String {
  migrate.get_data_dir() <> "/usda-cache"
}

/// Check if USDA data is already imported
pub fn is_imported(conn: sqlight.Connection) -> Bool {
  let sql = "SELECT COUNT(*) FROM foods"
  let decoder = {
    use count <- decode.field(0, decode.int)
    decode.success(count)
  }

  case sqlight.query(sql, on: conn, with: [], expecting: decoder) {
    Ok([count]) -> count > 0
    _ -> False
  }
}

/// Parse a CSV line into fields (handles quoted fields)
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

/// Parse nutrient.csv line
fn parse_nutrient(fields: List(String)) -> Result(Nutrient, String) {
  case fields {
    [id_str, name, unit_name, nutrient_nbr, rank_str, ..] -> {
      case int.parse(id_str) {
        Error(_) -> Error("Invalid nutrient id: " <> id_str)
        Ok(id) -> {
          let nbr = case nutrient_nbr {
            "" -> None
            n -> Some(n)
          }
          let rank = case int.parse(rank_str) {
            Ok(r) -> Some(r)
            Error(_) -> None
          }
          Ok(Nutrient(
            id: id,
            name: name,
            unit_name: unit_name,
            nutrient_nbr: nbr,
            rank: rank,
          ))
        }
      }
    }
    _ -> Error("Invalid nutrient row")
  }
}

/// Parse food.csv line
fn parse_food(fields: List(String)) -> Result(Food, String) {
  case fields {
    [
      fdc_id_str,
      data_type,
      description,
      food_category_str,
      publication_date,
      ..
    ] -> {
      case int.parse(fdc_id_str) {
        Error(_) -> Error("Invalid fdc_id: " <> fdc_id_str)
        Ok(fdc_id) -> {
          let cat = case food_category_str {
            "" -> None
            c -> Some(c)
          }
          let pub_date = case publication_date {
            "" -> None
            d -> Some(d)
          }
          Ok(Food(
            fdc_id: fdc_id,
            data_type: data_type,
            description: description,
            food_category: cat,
            publication_date: pub_date,
          ))
        }
      }
    }
    _ -> Error("Invalid food row")
  }
}

/// Parse food_nutrient.csv line
fn parse_food_nutrient(fields: List(String)) -> Result(FoodNutrient, String) {
  case fields {
    [id_str, fdc_id_str, nutrient_id_str, amount_str, ..] -> {
      case
        int.parse(id_str),
        int.parse(fdc_id_str),
        int.parse(nutrient_id_str)
      {
        Ok(id), Ok(fdc_id), Ok(nutrient_id) -> {
          let amount = case parse_float(amount_str) {
            Ok(a) -> Some(a)
            Error(_) -> None
          }
          Ok(FoodNutrient(
            id: id,
            fdc_id: fdc_id,
            nutrient_id: nutrient_id,
            amount: amount,
          ))
        }
        _, _, _ -> Error("Invalid food_nutrient row")
      }
    }
    _ -> Error("Invalid food_nutrient row")
  }
}

fn parse_float(s: String) -> Result(Float, Nil) {
  case string.contains(s, ".") {
    True ->
      case float_parse_ffi(s) {
        f if f == 0.0 && s != "0.0" && s != "0" && s != ".0" && s != "0." ->
          Error(Nil)
        f -> Ok(f)
      }
    False ->
      case int.parse(s) {
        Ok(i) -> Ok(int.to_float(i))
        Error(_) -> Error(Nil)
      }
  }
}

@external(erlang, "erlang", "binary_to_float")
fn float_parse_ffi(s: String) -> Float

/// Insert a batch of nutrients
fn insert_nutrients(
  conn: sqlight.Connection,
  nutrients: List(Nutrient),
) -> Result(Int, ImportError) {
  let results =
    list.map(nutrients, fn(n) {
      let sql =
        "INSERT OR IGNORE INTO nutrients (id, name, unit_name, nutrient_nbr, rank) VALUES (?, ?, ?, ?, ?)"
      let args = [
        sqlight.int(n.id),
        sqlight.text(n.name),
        sqlight.text(n.unit_name),
        case n.nutrient_nbr {
          Some(nbr) -> sqlight.text(nbr)
          None -> sqlight.null()
        },
        case n.rank {
          Some(r) -> sqlight.int(r)
          None -> sqlight.null()
        },
      ]
      sqlight.query(sql, on: conn, with: args, expecting: decode.dynamic)
    })

  let successes = list.filter(results, result.is_ok)
  Ok(list.length(successes))
}

/// Insert a batch of foods
fn insert_foods(
  conn: sqlight.Connection,
  foods: List(Food),
) -> Result(Int, ImportError) {
  let results =
    list.map(foods, fn(f) {
      let sql =
        "INSERT OR IGNORE INTO foods (fdc_id, data_type, description, food_category, publication_date) VALUES (?, ?, ?, ?, ?)"
      let args = [
        sqlight.int(f.fdc_id),
        sqlight.text(f.data_type),
        sqlight.text(f.description),
        case f.food_category {
          Some(cat) -> sqlight.text(cat)
          None -> sqlight.null()
        },
        case f.publication_date {
          Some(d) -> sqlight.text(d)
          None -> sqlight.null()
        },
      ]
      sqlight.query(sql, on: conn, with: args, expecting: decode.dynamic)
    })

  let successes = list.filter(results, result.is_ok)
  Ok(list.length(successes))
}

/// Insert a batch of food nutrients
fn insert_food_nutrients(
  conn: sqlight.Connection,
  food_nutrients: List(FoodNutrient),
) -> Result(Int, ImportError) {
  let results =
    list.map(food_nutrients, fn(fn_) {
      let sql =
        "INSERT OR IGNORE INTO food_nutrients (id, fdc_id, nutrient_id, amount) VALUES (?, ?, ?, ?)"
      let args = [
        sqlight.int(fn_.id),
        sqlight.int(fn_.fdc_id),
        sqlight.int(fn_.nutrient_id),
        case fn_.amount {
          Some(a) -> sqlight.float(a)
          None -> sqlight.null()
        },
      ]
      sqlight.query(sql, on: conn, with: args, expecting: decode.dynamic)
    })

  let successes = list.filter(results, result.is_ok)
  Ok(list.length(successes))
}

/// Import a CSV file in batches
pub fn import_csv_file(
  conn: sqlight.Connection,
  file_path: String,
  file_type: String,
  batch_size: Int,
) -> Result(Int, ImportError) {
  case simplifile.read(file_path) {
    Error(_) -> Error(FileNotFound(file_path))
    Ok(content) -> {
      let lines =
        content
        |> string.split("\n")
        |> list.drop(1)
        // Skip header
        |> list.filter(fn(l) { l != "" })

      let total = list.length(lines)
      io.println(
        "Importing " <> int.to_string(total) <> " rows from " <> file_type,
      )

      import_lines_in_batches(conn, lines, file_type, batch_size, 0)
    }
  }
}

fn import_lines_in_batches(
  conn: sqlight.Connection,
  lines: List(String),
  file_type: String,
  batch_size: Int,
  total_imported: Int,
) -> Result(Int, ImportError) {
  case list.split(lines, batch_size) {
    #([], _) -> Ok(total_imported)
    #(batch, rest) -> {
      let parsed =
        list.filter_map(batch, fn(line) {
          let fields = parse_csv_line(line)
          case file_type {
            "nutrient" -> parse_nutrient(fields) |> result.map(NutrientRow)
            "food" -> parse_food(fields) |> result.map(FoodRow)
            "food_nutrient" ->
              parse_food_nutrient(fields) |> result.map(FoodNutrientRow)
            _ -> Error("Unknown file type")
          }
        })

      let inserted = case file_type {
        "nutrient" -> {
          let nutrients =
            list.filter_map(parsed, fn(r) {
              case r {
                NutrientRow(n) -> Ok(n)
                _ -> Error(Nil)
              }
            })
          insert_nutrients(conn, nutrients)
        }
        "food" -> {
          let foods =
            list.filter_map(parsed, fn(r) {
              case r {
                FoodRow(f) -> Ok(f)
                _ -> Error(Nil)
              }
            })
          insert_foods(conn, foods)
        }
        "food_nutrient" -> {
          let fns =
            list.filter_map(parsed, fn(r) {
              case r {
                FoodNutrientRow(fn_) -> Ok(fn_)
                _ -> Error(Nil)
              }
            })
          insert_food_nutrients(conn, fns)
        }
        _ -> Error(DatabaseError("Unknown file type"))
      }

      case inserted {
        Error(e) -> Error(e)
        Ok(count) -> {
          let new_total = total_imported + count
          case new_total % 10_000 {
            0 ->
              io.println(
                "  Imported " <> int.to_string(new_total) <> " rows...",
              )
            _ -> Nil
          }
          import_lines_in_batches(conn, rest, file_type, batch_size, new_total)
        }
      }
    }
  }
}

/// Helper type for parsing
type ParsedRow {
  NutrientRow(Nutrient)
  FoodRow(Food)
  FoodNutrientRow(FoodNutrient)
}

/// Full import from extracted USDA directory
pub fn import_from_directory(
  conn: sqlight.Connection,
  usda_dir: String,
) -> Result(#(Int, Int, Int), ImportError) {
  io.println("Starting USDA FoodData Central import from " <> usda_dir)

  // Import nutrients first (referenced by food_nutrients)
  let nutrient_result =
    import_csv_file(conn, usda_dir <> "/nutrient.csv", "nutrient", 100)

  case nutrient_result {
    Error(e) -> Error(e)
    Ok(nutrients_count) -> {
      io.println("Imported " <> int.to_string(nutrients_count) <> " nutrients")

      // Import foods
      let food_result =
        import_csv_file(conn, usda_dir <> "/food.csv", "food", 1000)

      case food_result {
        Error(e) -> Error(e)
        Ok(foods_count) -> {
          io.println("Imported " <> int.to_string(foods_count) <> " foods")

          // Import food_nutrients (largest file)
          let fn_result =
            import_csv_file(
              conn,
              usda_dir <> "/food_nutrient.csv",
              "food_nutrient",
              5000,
            )

          case fn_result {
            Error(e) -> Error(e)
            Ok(fn_count) -> {
              io.println(
                "Imported "
                <> int.to_string(fn_count)
                <> " food nutrient values",
              )
              Ok(#(nutrients_count, foods_count, fn_count))
            }
          }
        }
      }
    }
  }
}
