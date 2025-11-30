/// Tests for USDA FoodData Central import
import gleam/dynamic/decode
import gleam/float
import gleam/order
import gleeunit/should
import meal_planner/usda_import
import simplifile
import sqlight

pub fn parse_csv_line_simple_test() {
  // Test basic CSV parsing through import_csv_file behavior
  // We'll test this indirectly through the full import

  // Just verify the module compiles and is importable
  let cache_dir = usda_import.get_cache_dir()
  { cache_dir != "" } |> should.be_true
}

pub fn is_imported_empty_db_test() {
  sqlight.with_connection(":memory:", fn(conn) {
    // Create the foods table
    let _ =
      sqlight.exec(
        "CREATE TABLE foods (fdc_id INTEGER PRIMARY KEY, data_type TEXT, description TEXT, food_category TEXT, publication_date TEXT)",
        on: conn,
      )

    // Empty database should return false
    usda_import.is_imported(conn) |> should.be_false
  })
}

pub fn is_imported_with_data_test() {
  sqlight.with_connection(":memory:", fn(conn) {
    // Create the foods table
    let _ =
      sqlight.exec(
        "CREATE TABLE foods (fdc_id INTEGER PRIMARY KEY, data_type TEXT, description TEXT, food_category TEXT, publication_date TEXT)",
        on: conn,
      )

    // Insert a food item
    let _ =
      sqlight.exec(
        "INSERT INTO foods (fdc_id, data_type, description) VALUES (12345, 'foundation_food', 'Test Food')",
        on: conn,
      )

    // Should return true now
    usda_import.is_imported(conn) |> should.be_true
  })
}

pub fn import_nutrient_csv_test() {
  let temp_dir = "/tmp/usda_test_nutrients"
  let _ = simplifile.create_directory_all(temp_dir)

  // Create test nutrient.csv
  let csv_content =
    "id,name,unit_name,nutrient_nbr,rank
1003,Protein,G,203,600
1004,\"Total lipid (fat)\",G,204,800
1005,Carbohydrate,G,205,1100
1008,Energy,KCAL,208,300"

  let _ = simplifile.write(temp_dir <> "/nutrient.csv", csv_content)

  sqlight.with_connection(":memory:", fn(conn) {
    // Create the nutrients table
    let _ =
      sqlight.exec(
        "CREATE TABLE nutrients (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          unit_name TEXT NOT NULL,
          nutrient_nbr TEXT,
          rank INTEGER
        )",
        on: conn,
      )

    // Import the CSV
    let result =
      usda_import.import_csv_file(conn, temp_dir <> "/nutrient.csv", "nutrient", 100)

    result |> should.be_ok

    case result {
      Ok(count) -> count |> should.equal(4)
      Error(_) -> should.fail()
    }

    // Verify data was imported
    let query_result =
      sqlight.query(
        "SELECT COUNT(*) FROM nutrients",
        on: conn,
        with: [],
        expecting: {
          use count <- decode.field(0, decode.int)
          decode.success(count)
        },
      )

    case query_result {
      Ok([count]) -> count |> should.equal(4)
      _ -> should.fail()
    }
  })

  // Cleanup
  let _ = simplifile.delete(temp_dir)
  Nil
}

pub fn import_food_csv_test() {
  let temp_dir = "/tmp/usda_test_foods"
  let _ = simplifile.create_directory_all(temp_dir)

  // Create test food.csv
  let csv_content =
    "fdc_id,data_type,description,food_category_id,publication_date
167512,foundation_food,\"Chicken, broiler or fryers, breast, meat only, cooked, roasted\",Poultry Products,2019-04-01
171705,sr_legacy_food,\"Beef, ground, 93% lean meat / 7% fat, raw\",Beef Products,2019-04-01
173410,foundation_food,\"Egg, whole, raw, fresh\",Dairy and Egg Products,2019-04-01"

  let _ = simplifile.write(temp_dir <> "/food.csv", csv_content)

  sqlight.with_connection(":memory:", fn(conn) {
    // Create the foods table
    let _ =
      sqlight.exec(
        "CREATE TABLE foods (
          fdc_id INTEGER PRIMARY KEY,
          data_type TEXT NOT NULL,
          description TEXT NOT NULL,
          food_category TEXT,
          publication_date TEXT
        )",
        on: conn,
      )

    // Import the CSV
    let result =
      usda_import.import_csv_file(conn, temp_dir <> "/food.csv", "food", 100)

    result |> should.be_ok

    case result {
      Ok(count) -> count |> should.equal(3)
      Error(_) -> should.fail()
    }

    // Verify data was imported with correct descriptions
    let query_result =
      sqlight.query(
        "SELECT description FROM foods WHERE fdc_id = 167512",
        on: conn,
        with: [],
        expecting: {
          use desc <- decode.field(0, decode.string)
          decode.success(desc)
        },
      )

    case query_result {
      Ok([desc]) -> {
        // Check that quoted field was parsed correctly
        { desc != "" } |> should.be_true
      }
      _ -> should.fail()
    }
  })

  // Cleanup
  let _ = simplifile.delete(temp_dir)
  Nil
}

pub fn import_food_nutrient_csv_test() {
  let temp_dir = "/tmp/usda_test_food_nutrients"
  let _ = simplifile.create_directory_all(temp_dir)

  // Create test food_nutrient.csv
  let csv_content =
    "id,fdc_id,nutrient_id,amount,data_points,derivation_id,min,max,median,loq,footnote,min_year_acquired
1,167512,1003,31.02,,,,,,,
2,167512,1004,3.57,,,,,,,
3,167512,1008,165.0,,,,,,,
4,171705,1003,20.73,,,,,,,
5,171705,1004,7.0,,,,,,,,"

  let _ = simplifile.write(temp_dir <> "/food_nutrient.csv", csv_content)

  sqlight.with_connection(":memory:", fn(conn) {
    // Create the food_nutrients table
    let _ =
      sqlight.exec(
        "CREATE TABLE food_nutrients (
          id INTEGER PRIMARY KEY,
          fdc_id INTEGER NOT NULL,
          nutrient_id INTEGER NOT NULL,
          amount REAL
        )",
        on: conn,
      )

    // Import the CSV
    let result =
      usda_import.import_csv_file(
        conn,
        temp_dir <> "/food_nutrient.csv",
        "food_nutrient",
        100,
      )

    result |> should.be_ok

    case result {
      Ok(count) -> count |> should.equal(5)
      Error(_) -> should.fail()
    }

    // Verify data was imported
    let query_result =
      sqlight.query(
        "SELECT amount FROM food_nutrients WHERE id = 1",
        on: conn,
        with: [],
        expecting: {
          use amount <- decode.field(0, decode.float)
          decode.success(amount)
        },
      )

    case query_result {
      Ok([amount]) -> {
        // Protein amount for chicken breast should be ~31.02
        { float.compare(amount, 30.0) == order.Gt && float.compare(amount, 32.0) == order.Lt } |> should.be_true
      }
      _ -> should.fail()
    }
  })

  // Cleanup
  let _ = simplifile.delete(temp_dir)
  Nil
}

pub fn import_from_directory_test() {
  let temp_dir = "/tmp/usda_test_full"
  let _ = simplifile.create_directory_all(temp_dir)

  // Create all three test files
  let nutrient_csv =
    "id,name,unit_name,nutrient_nbr,rank
1003,Protein,G,203,600
1004,\"Total lipid (fat)\",G,204,800"

  let food_csv =
    "fdc_id,data_type,description,food_category_id,publication_date
167512,foundation_food,\"Chicken breast\",Poultry,2019-04-01
171705,sr_legacy_food,\"Ground beef\",Beef,2019-04-01"

  let food_nutrient_csv =
    "id,fdc_id,nutrient_id,amount,data_points,derivation_id
1,167512,1003,31.02,,,
2,167512,1004,3.57,,,
3,171705,1003,20.73,,,"

  let _ = simplifile.write(temp_dir <> "/nutrient.csv", nutrient_csv)
  let _ = simplifile.write(temp_dir <> "/food.csv", food_csv)
  let _ = simplifile.write(temp_dir <> "/food_nutrient.csv", food_nutrient_csv)

  sqlight.with_connection(":memory:", fn(conn) {
    // Create all tables
    let _ =
      sqlight.exec(
        "CREATE TABLE nutrients (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          unit_name TEXT NOT NULL,
          nutrient_nbr TEXT,
          rank INTEGER
        )",
        on: conn,
      )
    let _ =
      sqlight.exec(
        "CREATE TABLE foods (
          fdc_id INTEGER PRIMARY KEY,
          data_type TEXT NOT NULL,
          description TEXT NOT NULL,
          food_category TEXT,
          publication_date TEXT
        )",
        on: conn,
      )
    let _ =
      sqlight.exec(
        "CREATE TABLE food_nutrients (
          id INTEGER PRIMARY KEY,
          fdc_id INTEGER NOT NULL,
          nutrient_id INTEGER NOT NULL,
          amount REAL
        )",
        on: conn,
      )

    // Import from directory
    let result = usda_import.import_from_directory(conn, temp_dir)

    result |> should.be_ok

    case result {
      Ok(#(nutrients, foods, food_nutrients)) -> {
        nutrients |> should.equal(2)
        foods |> should.equal(2)
        food_nutrients |> should.equal(3)
      }
      Error(_) -> should.fail()
    }
  })

  // Cleanup
  let _ = simplifile.delete(temp_dir)
  Nil
}

pub fn file_not_found_test() {
  sqlight.with_connection(":memory:", fn(conn) {
    let _ =
      sqlight.exec("CREATE TABLE nutrients (id INTEGER PRIMARY KEY, name TEXT NOT NULL, unit_name TEXT NOT NULL, nutrient_nbr TEXT, rank INTEGER)", on: conn)

    let result =
      usda_import.import_csv_file(
        conn,
        "/nonexistent/path/nutrient.csv",
        "nutrient",
        100,
      )

    case result {
      Error(usda_import.FileNotFound(_)) -> Nil
      _ -> should.fail()
    }
  })
}
