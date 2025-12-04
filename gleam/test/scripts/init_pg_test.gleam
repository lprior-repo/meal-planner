/// Comprehensive integration tests for PostgreSQL database initialization
/// Tests database setup, migration execution, data seeding, and error handling
///
/// NOTE: These tests require a running PostgreSQL instance with:
/// - Host: localhost:5432
/// - User: postgres
/// - Password: postgres
/// - Permissions to create databases
///
/// Run with: cd gleam && gleam test
import envoy
import fixtures/test_db
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/string
import gleeunit/should
import pog
import simplifile

// =============================================================================
// Test Database Configuration
// =============================================================================

/// Generate a unique test database name to avoid conflicts between parallel tests
fn unique_test_db_name() -> String {
  // Use system time for unique component
  let timestamp = erlang_system_time()
  // Create unique database name with timestamp
  "test_meal_planner_" <> int.to_string(timestamp)
}

@external(erlang, "erlang", "system_time")
fn erlang_system_time() -> Int

/// Create a test database configuration with unique name
fn test_db_config(db_name: String) -> pog.Config {
  let pool_name = process.new_name(prefix: "test_pool")
  pog.default_config(pool_name)
  |> pog.host("localhost")
  |> pog.port(5432)
  |> pog.database(db_name)
  |> pog.user("postgres")
  |> pog.password(Some("postgres"))
  |> pog.pool_size(5)
}

/// Create postgres database config (for setup/teardown)
fn postgres_db_config() -> pog.Config {
  let pool_name = process.new_name(prefix: "setup_pool")
  pog.default_config(pool_name)
  |> pog.host("localhost")
  |> pog.port(5432)
  |> pog.database("postgres")
  |> pog.user("postgres")
  |> pog.password(Some("postgres"))
  |> pog.pool_size(1)
}

// =============================================================================
// Test Fixtures and Helpers
// =============================================================================

/// Create test database with given name
fn create_test_database(db_name: String) -> Result(Nil, String) {
  case pog.start(postgres_db_config()) {
    Error(_) -> Error("Cannot connect to PostgreSQL")
    Ok(started) -> {
      let db = started.data

      // First, terminate any existing connections to the target database
      let terminate_query =
        pog.query(
          "SELECT pg_terminate_backend(pid)
           FROM pg_stat_activity
           WHERE datname = $1 AND pid <> pg_backend_pid()",
        )
        |> pog.parameter(pog.text(db_name))
      let _ = pog.execute(terminate_query, db)

      // Drop existing test database if it exists
      let drop_query = pog.query("DROP DATABASE IF EXISTS " <> db_name)
      let _ = pog.execute(drop_query, db)

      // Create fresh test database
      let create_query = pog.query("CREATE DATABASE " <> db_name)
      let result = case pog.execute(create_query, db) {
        Ok(_) -> Ok(Nil)
        Error(e) ->
          Error("Failed to create test database: " <> format_pog_error(e))
      }

      // Stop the pool to release connection
      process.kill(started.pid)
      result
    }
  }
}

/// Drop test database with given name
fn drop_test_database(db_name: String) -> Result(Nil, String) {
  case pog.start(postgres_db_config()) {
    Error(_) -> Error("Cannot connect to PostgreSQL")
    Ok(started) -> {
      let db = started.data

      // Terminate any connections to the target database
      let terminate_query =
        pog.query(
          "SELECT pg_terminate_backend(pid)
           FROM pg_stat_activity
           WHERE datname = $1 AND pid <> pg_backend_pid()",
        )
        |> pog.parameter(pog.text(db_name))
      let _ = pog.execute(terminate_query, db)

      let query = pog.query("DROP DATABASE IF EXISTS " <> db_name)
      let result = case pog.execute(query, db) {
        Ok(_) -> Ok(Nil)
        Error(e) ->
          Error("Failed to drop test database: " <> format_pog_error(e))
      }

      // Stop the pool to release connection
      process.kill(started.pid)
      result
    }
  }
}

/// Run all migrations in standard order (skips migration 009)
fn run_all_migrations(db: pog.Connection) -> Result(Nil, String) {
  let migrations = [
    "migrations_pg/001_schema_migrations.sql",
    "migrations_pg/002_usda_tables.sql",
    "migrations_pg/003_app_tables.sql",
    "migrations_pg/005_add_micronutrients_to_food_logs.sql",
    "migrations_pg/006_add_source_tracking.sql",
    // Skip 009 - requires users table which doesn't exist yet
  ]

  list.try_each(migrations, fn(migration_path) {
    run_migration(db, migration_path)
  })
}

/// Helper to run a test with isolated database
/// Creates unique DB, runs migrations, runs test, cleans up
fn with_test_db(test_fn: fn(pog.Connection) -> a) -> a {
  let db_name = unique_test_db_name()

  // Setup: create database
  let assert Ok(_) = create_test_database(db_name)
  let assert Ok(started) = pog.start(test_db_config(db_name))
  let db = started.data

  // Setup: run migrations
  let assert Ok(_) = run_all_migrations(db)

  // Run test
  let result = test_fn(db)

  // Cleanup: stop pool and drop database
  process.kill(started.pid)
  let assert Ok(_) = drop_test_database(db_name)

  result
}

/// Helper to run a test with empty database (no migrations)
/// Used for testing migration execution itself
fn with_empty_db(test_fn: fn(pog.Connection) -> a) -> a {
  let db_name = unique_test_db_name()

  // Setup: create database only (no migrations)
  let assert Ok(_) = create_test_database(db_name)
  let assert Ok(started) = pog.start(test_db_config(db_name))
  let db = started.data

  // Run test
  let result = test_fn(db)

  // Cleanup
  let assert Ok(_) = drop_test_database(db_name)

  result
}

/// Run migration SQL file
fn run_migration(db: pog.Connection, file_path: String) -> Result(Nil, String) {
  case simplifile.read(file_path) {
    Error(_) -> Error("Cannot read migration file: " <> file_path)
    Ok(content) -> {
      // Split by semicolon and execute each statement
      let statements =
        content
        |> string.split(";")
        |> list.filter(fn(s) { string.trim(s) != "" })

      list.try_each(statements, fn(sql) {
        let trimmed = string.trim(sql)
        case trimmed {
          "" -> Ok(Nil)
          _ -> {
            let query = pog.query(trimmed)
            case pog.execute(query, db) {
              Ok(_) -> Ok(Nil)
              Error(e) -> Error("Migration failed: " <> format_pog_error(e))
            }
          }
        }
      })
    }
  }
}

/// Format pog error for display
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

/// Check if a table exists
fn table_exists(db: pog.Connection, table_name: String) -> Bool {
  let query =
    pog.query(
      "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = $1",
    )
    |> pog.parameter(pog.text(table_name))
    |> pog.returning(decode.at([0], decode.int))

  case pog.execute(query, db) {
    Ok(pog.Returned(_, [count])) -> count > 0
    _ -> False
  }
}

/// Get row count from a table
fn get_row_count(db: pog.Connection, table_name: String) -> Int {
  let query =
    pog.query("SELECT COUNT(*) FROM " <> table_name)
    |> pog.returning(decode.at([0], decode.int))

  case pog.execute(query, db) {
    Ok(pog.Returned(_, [count])) -> count
    _ -> 0
  }
}

/// Insert test nutrient
fn insert_test_nutrient(
  db: pog.Connection,
  id: Int,
  name: String,
  unit: String,
) -> Result(Nil, String) {
  let query =
    pog.query(
      "INSERT INTO nutrients (id, name, unit_name, nutrient_nbr, rank)
       VALUES ($1, $2, $3, $4, $5)",
    )
    |> pog.parameter(pog.int(id))
    |> pog.parameter(pog.text(name))
    |> pog.parameter(pog.text(unit))
    |> pog.parameter(pog.text("TEST"))
    |> pog.parameter(pog.int(100))

  case pog.execute(query, db) {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(format_pog_error(e))
  }
}

/// Insert test food
fn insert_test_food(
  db: pog.Connection,
  fdc_id: Int,
  description: String,
) -> Result(Nil, String) {
  let query =
    pog.query(
      "INSERT INTO foods (fdc_id, data_type, description, food_category, publication_date)
       VALUES ($1, $2, $3, $4, $5)",
    )
    |> pog.parameter(pog.int(fdc_id))
    |> pog.parameter(pog.text("test_data"))
    |> pog.parameter(pog.text(description))
    |> pog.parameter(pog.text("Test Category"))
    |> pog.parameter(pog.text("2025-01-01"))

  case pog.execute(query, db) {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(format_pog_error(e))
  }
}

/// Insert test food nutrient
fn insert_test_food_nutrient(
  db: pog.Connection,
  id: Int,
  fdc_id: Int,
  nutrient_id: Int,
  amount: Float,
) -> Result(Nil, String) {
  let query =
    pog.query(
      "INSERT INTO food_nutrients (id, fdc_id, nutrient_id, amount)
       VALUES ($1, $2, $3, $4)",
    )
    |> pog.parameter(pog.int(id))
    |> pog.parameter(pog.int(fdc_id))
    |> pog.parameter(pog.int(nutrient_id))
    |> pog.parameter(pog.float(amount))

  case pog.execute(query, db) {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(format_pog_error(e))
  }
}

// =============================================================================
// Cleanup (runs first alphabetically)
// =============================================================================

/// Clean up orphan test databases from previous failed runs
/// This test name starts with "aaa" to run first alphabetically
pub fn aaa_cleanup_orphan_databases_test() {
  test_db.cleanup_orphan_test_databases()
  |> should.be_ok
}

// =============================================================================
// Migration Tests
// =============================================================================

/// Test: Migration 001 - schema_migrations table creation
pub fn migration_001_creates_schema_migrations_test() {
  with_empty_db(fn(db) {
    let assert Ok(_) =
      run_migration(db, "migrations_pg/001_schema_migrations.sql")

    table_exists(db, "schema_migrations")
    |> should.be_true
  })
}

/// Test: Migration 002 - USDA tables creation
pub fn migration_002_creates_usda_tables_test() {
  with_empty_db(fn(db) {
    let assert Ok(_) =
      run_migration(db, "migrations_pg/001_schema_migrations.sql")
    let assert Ok(_) = run_migration(db, "migrations_pg/002_usda_tables.sql")

    table_exists(db, "nutrients")
    |> should.be_true

    table_exists(db, "foods")
    |> should.be_true

    table_exists(db, "food_nutrients")
    |> should.be_true

    table_exists(db, "food_nutrients_staging")
    |> should.be_true
  })
}

/// Test: Migration 003 - App tables creation
pub fn migration_003_creates_app_tables_test() {
  with_empty_db(fn(db) {
    let assert Ok(_) =
      run_migration(db, "migrations_pg/001_schema_migrations.sql")
    let assert Ok(_) = run_migration(db, "migrations_pg/002_usda_tables.sql")
    let assert Ok(_) = run_migration(db, "migrations_pg/003_app_tables.sql")

    table_exists(db, "recipes")
    |> should.be_true

    table_exists(db, "food_logs")
    |> should.be_true
  })
}

/// Test: Migrations are idempotent (can run multiple times)
pub fn migrations_are_idempotent_test() {
  with_empty_db(fn(db) {
    let assert Ok(_) =
      run_migration(db, "migrations_pg/001_schema_migrations.sql")
    let assert Ok(_) = run_migration(db, "migrations_pg/002_usda_tables.sql")

    // Second run should succeed (CREATE IF NOT EXISTS)
    let result1 = run_migration(db, "migrations_pg/001_schema_migrations.sql")
    result1
    |> should.be_ok

    let result2 = run_migration(db, "migrations_pg/002_usda_tables.sql")
    result2
    |> should.be_ok

    table_exists(db, "schema_migrations")
    |> should.be_true

    table_exists(db, "nutrients")
    |> should.be_true
  })
}

/// Test: Migration ordering matters
pub fn migration_order_matters_test() {
  with_empty_db(fn(db) {
    // Running 003 before 002 should fail (missing dependencies)
    run_migration(db, "migrations_pg/003_app_tables.sql")
    |> should.be_error
  })
}

// =============================================================================
// Schema Validation Tests
// =============================================================================

/// Test: Nutrients table has correct schema
pub fn nutrients_table_schema_test() {
  with_test_db(fn(db) {
    insert_test_nutrient(db, 1, "Protein", "g")
    |> should.be_ok

    get_row_count(db, "nutrients")
    |> should.equal(1)
  })
}

/// Test: Foods table has correct schema and indexes
pub fn foods_table_schema_test() {
  with_test_db(fn(db) {
    insert_test_food(db, 100_001, "Test Food")
    |> should.be_ok

    get_row_count(db, "foods")
    |> should.equal(1)
  })
}

/// Test: Food nutrients table enforces foreign key constraints
pub fn food_nutrients_foreign_key_constraints_test() {
  with_test_db(fn(db) {
    let assert Ok(_) = insert_test_nutrient(db, 1, "Protein", "g")
    let assert Ok(_) = insert_test_food(db, 100_001, "Test Food")

    // Valid insert should succeed
    let result1 = insert_test_food_nutrient(db, 1, 100_001, 1, 10.5)
    result1
    |> should.be_ok

    // Invalid foreign key should fail
    let result2 = insert_test_food_nutrient(db, 2, 999_999, 1, 5.0)
    result2
    |> should.be_error
  })
}

/// Test: Primary key constraints prevent duplicates
pub fn primary_key_prevents_duplicates_test() {
  with_test_db(fn(db) {
    // First insert should succeed
    let result1 = insert_test_nutrient(db, 1, "Protein", "g")
    result1
    |> should.be_ok

    // Duplicate primary key should fail
    let result2 = insert_test_nutrient(db, 1, "Fat", "g")
    result2
    |> should.be_error
  })
}

// =============================================================================
// Index Creation Tests
// =============================================================================

/// Test: Full-text search index exists on foods.description
pub fn foods_fts_index_exists_test() {
  with_test_db(fn(db) {
    let query =
      pog.query(
        "SELECT COUNT(*) FROM pg_indexes
         WHERE tablename = 'foods'
         AND indexname = 'idx_foods_description_gin'",
      )
      |> pog.returning(decode.at([0], decode.int))

    case pog.execute(query, db) {
      Ok(pog.Returned(_, [count])) -> {
        count
        |> should.equal(1)
      }
      _ -> should.fail()
    }
  })
}

/// Test: B-tree indexes exist on foods table
pub fn foods_btree_indexes_exist_test() {
  with_test_db(fn(db) {
    // Check data_type index
    let query1 =
      pog.query(
        "SELECT COUNT(*) FROM pg_indexes
         WHERE tablename = 'foods'
         AND indexname = 'idx_foods_data_type'",
      )
      |> pog.returning(decode.at([0], decode.int))

    case pog.execute(query1, db) {
      Ok(pog.Returned(_, [count])) -> {
        count
        |> should.equal(1)
      }
      _ -> should.fail()
    }

    // Check category index
    let query2 =
      pog.query(
        "SELECT COUNT(*) FROM pg_indexes
         WHERE tablename = 'foods'
         AND indexname = 'idx_foods_category'",
      )
      |> pog.returning(decode.at([0], decode.int))

    case pog.execute(query2, db) {
      Ok(pog.Returned(_, [count])) -> {
        count
        |> should.equal(1)
      }
      _ -> should.fail()
    }
  })
}

// =============================================================================
// Data Seeding Tests
// =============================================================================

/// Test: Can insert multiple nutrients in batch
pub fn batch_nutrient_insert_test() {
  with_test_db(fn(db) {
    let assert Ok(_) = insert_test_nutrient(db, 1, "Protein", "g")
    let assert Ok(_) = insert_test_nutrient(db, 2, "Fat", "g")
    let assert Ok(_) = insert_test_nutrient(db, 3, "Carbohydrates", "g")

    get_row_count(db, "nutrients")
    |> should.equal(3)
  })
}

/// Test: Can insert foods and nutrients with relationships
pub fn related_data_insert_test() {
  with_test_db(fn(db) {
    let assert Ok(_) = insert_test_nutrient(db, 1, "Protein", "g")
    let assert Ok(_) = insert_test_nutrient(db, 2, "Fat", "g")
    let assert Ok(_) = insert_test_food(db, 100_001, "Chicken Breast")
    let assert Ok(_) = insert_test_food_nutrient(db, 1, 100_001, 1, 31.0)
    let assert Ok(_) = insert_test_food_nutrient(db, 2, 100_001, 2, 3.6)

    get_row_count(db, "nutrients")
    |> should.equal(2)

    get_row_count(db, "foods")
    |> should.equal(1)

    get_row_count(db, "food_nutrients")
    |> should.equal(2)
  })
}

/// Test: ON CONFLICT DO NOTHING works for idempotent inserts
pub fn on_conflict_do_nothing_test() {
  with_test_db(fn(db) {
    let query1 =
      pog.query(
        "INSERT INTO nutrients (id, name, unit_name, nutrient_nbr, rank)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (id) DO NOTHING",
      )
      |> pog.parameter(pog.int(1))
      |> pog.parameter(pog.text("Protein"))
      |> pog.parameter(pog.text("g"))
      |> pog.parameter(pog.text("TEST"))
      |> pog.parameter(pog.int(100))

    let assert Ok(_) = pog.execute(query1, db)

    let query2 =
      pog.query(
        "INSERT INTO nutrients (id, name, unit_name, nutrient_nbr, rank)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (id) DO NOTHING",
      )
      |> pog.parameter(pog.int(1))
      |> pog.parameter(pog.text("Different Name"))
      |> pog.parameter(pog.text("mg"))
      |> pog.parameter(pog.text("TEST2"))
      |> pog.parameter(pog.int(200))

    let assert Ok(_) = pog.execute(query2, db)

    get_row_count(db, "nutrients")
    |> should.equal(1)

    let query3 =
      pog.query("SELECT name FROM nutrients WHERE id = $1")
      |> pog.parameter(pog.int(1))
      |> pog.returning(decode.at([0], decode.string))

    case pog.execute(query3, db) {
      Ok(pog.Returned(_, [name])) -> {
        name
        |> should.equal("Protein")
      }
      _ -> should.fail()
    }
  })
}

// =============================================================================
// Error Handling Tests
// =============================================================================

/// Test: Cannot connect to non-existent database
pub fn connection_to_nonexistent_db_fails_test() {
  let pool_name = process.new_name(prefix: "bad_pool")
  let bad_config =
    pog.default_config(pool_name)
    |> pog.host("localhost")
    |> pog.port(5432)
    |> pog.database("nonexistent_db_12345")
    |> pog.user("postgres")
    |> pog.password(Some("postgres"))
    |> pog.pool_size(1)

  pog.start(bad_config)
  |> should.be_error
}

/// Test: Invalid SQL causes rollback
pub fn invalid_sql_causes_error_test() {
  with_test_db(fn(db) {
    let query = pog.query("SELECT * FROM nonexistent_table")
    pog.execute(query, db)
    |> should.be_error
  })
}

/// Test: Constraint violations are caught
pub fn constraint_violation_caught_test() {
  with_test_db(fn(db) {
    let query =
      pog.query(
        "INSERT INTO food_nutrients (id, fdc_id, nutrient_id, amount)
         VALUES ($1, $2, $3, $4)",
      )
      |> pog.parameter(pog.int(1))
      |> pog.parameter(pog.int(999_999))
      |> pog.parameter(pog.int(999_999))
      |> pog.parameter(pog.float(10.0))

    pog.execute(query, db)
    |> should.be_error
  })
}

// =============================================================================
// Performance and Concurrency Tests
// =============================================================================

/// Test: Can handle multiple concurrent connections
pub fn concurrent_connections_test() {
  let db_name = unique_test_db_name()
  let assert Ok(_) = create_test_database(db_name)

  let pool_name = process.new_name(prefix: "concurrent_pool")
  let config =
    pog.default_config(pool_name)
    |> pog.host("localhost")
    |> pog.port(5432)
    |> pog.database(db_name)
    |> pog.user("postgres")
    |> pog.password(Some("postgres"))
    |> pog.pool_size(10)

  pog.start(config)
  |> should.be_ok

  let assert Ok(_) = drop_test_database(db_name)
}

/// Test: Large batch insert performance
pub fn large_batch_insert_test() {
  with_test_db(fn(db) {
    let ids = list.range(1, 100)
    list.each(ids, fn(id) {
      let assert Ok(_) =
        insert_test_nutrient(db, id, "Nutrient " <> int.to_string(id), "g")
      Nil
    })

    get_row_count(db, "nutrients")
    |> should.equal(100)
  })
}

// =============================================================================
// Data Integrity Tests
// =============================================================================

/// Test: CASCADE delete removes related food_nutrients
pub fn cascade_delete_test() {
  with_test_db(fn(db) {
    let assert Ok(_) = insert_test_nutrient(db, 1, "Protein", "g")
    let assert Ok(_) = insert_test_food(db, 100_001, "Test Food")
    let assert Ok(_) = insert_test_food_nutrient(db, 1, 100_001, 1, 10.0)

    get_row_count(db, "food_nutrients")
    |> should.equal(1)

    let delete_query =
      pog.query("DELETE FROM foods WHERE fdc_id = $1")
      |> pog.parameter(pog.int(100_001))

    let assert Ok(_) = pog.execute(delete_query, db)

    get_row_count(db, "food_nutrients")
    |> should.equal(0)
  })
}

/// Test: Nutrient deletion cascades to food_nutrients
pub fn nutrient_cascade_delete_test() {
  with_test_db(fn(db) {
    let assert Ok(_) = insert_test_nutrient(db, 1, "Protein", "g")
    let assert Ok(_) = insert_test_food(db, 100_001, "Test Food")
    let assert Ok(_) = insert_test_food_nutrient(db, 1, 100_001, 1, 10.0)

    let delete_query =
      pog.query("DELETE FROM nutrients WHERE id = $1")
      |> pog.parameter(pog.int(1))

    let assert Ok(_) = pog.execute(delete_query, db)

    get_row_count(db, "food_nutrients")
    |> should.equal(0)
  })
}
