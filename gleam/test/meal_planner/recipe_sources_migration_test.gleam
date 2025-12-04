/// Comprehensive tests for recipe_sources migration (009_auto_meal_planner.sql)
/// Validates migration integrity, table schema, constraints, indexes, and triggers
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleeunit/should
import pog

// Test database imports
@external(erlang, "erlang", "sleep")
fn sleep(milliseconds: Int) -> Nil

// ============================================================================
// Helper Functions
// ============================================================================

/// Get a test database connection
fn get_test_db() -> pog.Connection {
  let pool_name = "migration_test_pool"
  case
    pog.default_config(pool_name)
    |> pog.host("localhost")
    |> pog.port(5432)
    |> pog.database("meal_planner_test")
    |> pog.user("postgres")
    |> pog.password(Some("postgres"))
    |> pog.pool_size(5)
    |> pog.start()
  {
    Ok(started) -> started.data
    Error(_) -> panic as "Failed to connect to test database"
  }
}

/// Clean up test data from recipe_sources table
fn cleanup_recipe_sources(db: pog.Connection) -> Nil {
  let _ =
    pog.query("DELETE FROM recipe_sources WHERE name LIKE 'test_%';")
    |> pog.execute(db)
  Nil
}

/// Format pog error for debugging
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

// ============================================================================
// Table Existence Tests
// ============================================================================

pub fn recipe_sources_table_exists_test() {
  let db = get_test_db()

  let query =
    pog.query(
      "
    SELECT EXISTS (
      SELECT FROM information_schema.tables
      WHERE table_schema = 'public'
      AND table_name = 'recipe_sources'
    );
  ",
    )

  case pog.execute(query, db) {
    Ok(result) -> {
      case decode.run(result.rows, decode.element(0, decode.bool)) {
        Ok([True]) -> should.be_true(True)
        Ok([False]) -> should.fail()
        _ -> should.fail()
      }
    }
    Error(e) -> {
      panic as "Query failed: " <> format_pog_error(e)
    }
  }
}

pub fn auto_meal_plans_table_exists_test() {
  let db = get_test_db()

  let query =
    pog.query(
      "
    SELECT EXISTS (
      SELECT FROM information_schema.tables
      WHERE table_schema = 'public'
      AND table_name = 'auto_meal_plans'
    );
  ",
    )

  case pog.execute(query, db) {
    Ok(result) -> {
      case decode.run(result.rows, decode.element(0, decode.bool)) {
        Ok([True]) -> should.be_true(True)
        Ok([False]) -> should.fail()
        _ -> should.fail()
      }
    }
    Error(e) -> {
      panic as "Query failed: " <> format_pog_error(e)
    }
  }
}

// ============================================================================
// Schema Validation Tests
// ============================================================================

pub fn recipe_sources_has_correct_columns_test() {
  let db = get_test_db()

  let query =
    pog.query(
      "
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_name = 'recipe_sources'
    ORDER BY ordinal_position;
  ",
    )

  case pog.execute(query, db) {
    Ok(result) -> {
      let decoder = {
        use column_name <- decode.field(0, decode.string)
        use data_type <- decode.field(1, decode.string)
        use is_nullable <- decode.field(2, decode.string)
        decode.success(#(column_name, data_type, is_nullable))
      }

      case decode.run(result.rows, decode.list(decoder)) {
        Ok(columns) -> {
          // Verify we have all expected columns
          list.length(columns) |> should.equal(7)

          // Verify specific columns exist with correct types
          let column_map = columns

          // ID column
          should.be_true(
            list.any(column_map, fn(c) {
              c.0 == "id" && c.1 == "integer" && c.2 == "NO"
            }),
          )

          // Name column (NOT NULL, UNIQUE tested separately)
          should.be_true(
            list.any(column_map, fn(c) {
              c.0 == "name" && c.1 == "text" && c.2 == "NO"
            }),
          )

          // Type column (NOT NULL with CHECK constraint)
          should.be_true(
            list.any(column_map, fn(c) {
              c.0 == "type" && c.1 == "text" && c.2 == "NO"
            }),
          )

          // Config column (nullable TEXT/JSONB)
          should.be_true(
            list.any(column_map, fn(c) {
              c.0 == "config" && c.2 == "YES"
            }),
          )

          // Enabled column (NOT NULL with default)
          should.be_true(
            list.any(column_map, fn(c) {
              c.0 == "enabled" && c.1 == "boolean" && c.2 == "NO"
            }),
          )

          // Timestamps
          should.be_true(
            list.any(column_map, fn(c) {
              c.0 == "created_at"
              && string.contains(c.1, "timestamp")
              && c.2 == "NO"
            }),
          )

          should.be_true(
            list.any(column_map, fn(c) {
              c.0 == "updated_at"
              && string.contains(c.1, "timestamp")
              && c.2 == "NO"
            }),
  )
        }
        Error(_) -> should.fail()
      }
    }
    Error(e) -> panic as "Query failed: " <> format_pog_error(e)
  }
}

pub fn recipe_sources_has_primary_key_test() {
  let db = get_test_db()

  let query =
    pog.query(
      "
    SELECT constraint_name, constraint_type
    FROM information_schema.table_constraints
    WHERE table_name = 'recipe_sources' AND constraint_type = 'PRIMARY KEY';
  ",
    )

  case pog.execute(query, db) {
    Ok(result) -> {
      // Should have exactly one primary key constraint
      result.rows
      |> list.length()
      |> should.equal(1)
    }
    Error(e) -> panic as "Query failed: " <> format_pog_error(e)
  }
}

pub fn recipe_sources_has_unique_name_constraint_test() {
  let db = get_test_db()

  let query =
    pog.query(
      "
    SELECT constraint_name
    FROM information_schema.table_constraints
    WHERE table_name = 'recipe_sources' AND constraint_type = 'UNIQUE';
  ",
    )

  case pog.execute(query, db) {
    Ok(result) -> {
      // Should have at least one unique constraint (on name)
      result.rows
      |> list.length()
      |> fn(len) { len >= 1 }
      |> should.be_true()
    }
    Error(e) -> panic as "Query failed: " <> format_pog_error(e)
  }
}

// ============================================================================
// Index Creation Tests
// ============================================================================

pub fn recipe_sources_has_type_index_test() {
  let db = get_test_db()

  let query =
    pog.query(
      "
    SELECT indexname
    FROM pg_indexes
    WHERE tablename = 'recipe_sources' AND indexname = 'idx_recipe_sources_type';
  ",
    )

  case pog.execute(query, db) {
    Ok(result) -> {
      result.rows
      |> list.length()
      |> should.equal(1)
    }
    Error(e) -> panic as "Query failed: " <> format_pog_error(e)
  }
}

pub fn recipe_sources_has_enabled_index_test() {
  let db = get_test_db()

  let query =
    pog.query(
      "
    SELECT indexname
    FROM pg_indexes
    WHERE tablename = 'recipe_sources' AND indexname = 'idx_recipe_sources_enabled';
  ",
    )

  case pog.execute(query, db) {
    Ok(result) -> {
      result.rows
      |> list.length()
      |> should.equal(1)
    }
    Error(e) -> panic as "Query failed: " <> format_pog_error(e)
  }
}

pub fn auto_meal_plans_has_required_indexes_test() {
  let db = get_test_db()

  let expected_indexes = [
    "idx_auto_meal_plans_user_id", "idx_auto_meal_plans_status",
    "idx_auto_meal_plans_generated_at",
  ]

  list.each(expected_indexes, fn(index_name) {
    let query =
      pog.query(
        "
      SELECT indexname
      FROM pg_indexes
      WHERE tablename = 'auto_meal_plans' AND indexname = $1;
    ",
      )
      |> pog.parameter(pog.text(index_name))

    case pog.execute(query, db) {
      Ok(result) -> {
        result.rows
        |> list.length()
        |> should.equal(1)
      }
      Error(e) -> panic as "Index check failed: " <> format_pog_error(e)
    }
  })
}

// ============================================================================
// Insert Operations Tests
// ============================================================================

pub fn can_insert_recipe_source_test() {
  let db = get_test_db()
  cleanup_recipe_sources(db)

  let insert_query =
    pog.query(
      "
    INSERT INTO recipe_sources (name, type, config, enabled)
    VALUES ($1, $2, $3, $4)
    RETURNING id, name, type, enabled;
  ",
    )
    |> pog.parameter(pog.text("test_api_source"))
    |> pog.parameter(pog.text("api"))
    |> pog.parameter(pog.nullable(pog.text, Some("{\"api_key\": \"test123\"}")))
    |> pog.parameter(pog.bool(True))

  case pog.execute(insert_query, db) {
    Ok(result) -> {
      result.rows
      |> list.length()
      |> should.equal(1)
    }
    Error(e) -> panic as "Insert failed: " <> format_pog_error(e)
  }

  cleanup_recipe_sources(db)
}

pub fn can_insert_multiple_recipe_sources_test() {
  let db = get_test_db()
  cleanup_recipe_sources(db)

  // Insert API source
  let _ =
    pog.query(
      "
    INSERT INTO recipe_sources (name, type, enabled)
    VALUES ($1, $2, $3);
  ",
    )
    |> pog.parameter(pog.text("test_api_multiple"))
    |> pog.parameter(pog.text("api"))
    |> pog.parameter(pog.bool(True))
    |> pog.execute(db)

  // Insert scraper source
  let _ =
    pog.query(
      "
    INSERT INTO recipe_sources (name, type, enabled)
    VALUES ($1, $2, $3);
  ",
    )
    |> pog.parameter(pog.text("test_scraper_multiple"))
    |> pog.parameter(pog.text("scraper"))
    |> pog.parameter(pog.bool(False))
    |> pog.execute(db)

  // Verify both inserted
  let count_query =
    pog.query("SELECT COUNT(*) FROM recipe_sources WHERE name LIKE 'test_%';")

  case pog.execute(count_query, db) {
    Ok(result) -> {
      case decode.run(result.rows, decode.element(0, decode.int)) {
        Ok([count]) -> count |> should.equal(2)
        _ -> should.fail()
      }
    }
    Error(e) -> panic as "Count query failed: " <> format_pog_error(e)
  }

  cleanup_recipe_sources(db)
}

// ============================================================================
// Constraint Tests
// ============================================================================

pub fn unique_name_constraint_enforced_test() {
  let db = get_test_db()
  cleanup_recipe_sources(db)

  // Insert first source
  let _ =
    pog.query(
      "
    INSERT INTO recipe_sources (name, type, enabled)
    VALUES ($1, $2, $3);
  ",
    )
    |> pog.parameter(pog.text("test_unique"))
    |> pog.parameter(pog.text("api"))
    |> pog.parameter(pog.bool(True))
    |> pog.execute(db)

  // Try to insert duplicate name
  let duplicate_query =
    pog.query(
      "
    INSERT INTO recipe_sources (name, type, enabled)
    VALUES ($1, $2, $3);
  ",
    )
    |> pog.parameter(pog.text("test_unique"))
    |> pog.parameter(pog.text("scraper"))
    |> pog.parameter(pog.bool(False))

  case pog.execute(duplicate_query, db) {
    Error(pog.ConstraintViolated(_, _, _)) -> should.be_true(True)
    Error(pog.PostgresqlError(code, _, _)) -> {
      // PostgreSQL unique violation error code is 23505
      code |> should.equal("23505")
    }
    Ok(_) -> should.fail()
    Error(_) -> should.fail()
  }

  cleanup_recipe_sources(db)
}

pub fn not_null_constraints_enforced_test() {
  let db = get_test_db()

  // Try to insert without name (should fail)
  let query =
    pog.query(
      "
    INSERT INTO recipe_sources (name, type, enabled)
    VALUES ($1, $2, $3);
  ",
    )
    |> pog.parameter(pog.nullable(pog.text, None))
    |> pog.parameter(pog.text("api"))
    |> pog.parameter(pog.bool(True))

  case pog.execute(query, db) {
    Error(pog.ConstraintViolated(_, _, _)) -> should.be_true(True)
    Error(pog.PostgresqlError(code, _, _)) -> {
      // NOT NULL violation error code is 23502
      code |> should.equal("23502")
    }
    Ok(_) -> should.fail()
    Error(_) -> should.fail()
  }
}

pub fn type_check_constraint_enforced_test() {
  let db = get_test_db()
  cleanup_recipe_sources(db)

  // Try to insert invalid type
  let query =
    pog.query(
      "
    INSERT INTO recipe_sources (name, type, enabled)
    VALUES ($1, $2, $3);
  ",
    )
    |> pog.parameter(pog.text("test_invalid_type"))
    |> pog.parameter(pog.text("invalid_type"))
    |> pog.parameter(pog.bool(True))

  case pog.execute(query, db) {
    Error(pog.ConstraintViolated(_, _, _)) -> should.be_true(True)
    Error(pog.PostgresqlError(code, _, _)) -> {
      // CHECK constraint violation error code is 23514
      code |> should.equal("23514")
    }
    Ok(_) -> should.fail()
    Error(_) -> should.fail()
  }

  cleanup_recipe_sources(db)
}

pub fn valid_types_accepted_test() {
  let db = get_test_db()
  cleanup_recipe_sources(db)

  let valid_types = ["api", "scraper", "manual"]

  list.each(valid_types, fn(recipe_type) {
    let query =
      pog.query(
        "
      INSERT INTO recipe_sources (name, type, enabled)
      VALUES ($1, $2, $3);
    ",
      )
      |> pog.parameter(pog.text("test_" <> recipe_type))
      |> pog.parameter(pog.text(recipe_type))
      |> pog.parameter(pog.bool(True))

    case pog.execute(query, db) {
      Ok(_) -> should.be_true(True)
      Error(e) ->
        panic as "Failed to insert valid type "
        <> recipe_type
        <> ": "
        <> format_pog_error(e)
    }
  })

  cleanup_recipe_sources(db)
}

// ============================================================================
// JSON Config Column Tests
// ============================================================================

pub fn config_accepts_valid_json_test() {
  let db = get_test_db()
  cleanup_recipe_sources(db)

  let json_config = "{\"api_key\": \"abc123\", \"endpoint\": \"https://api.example.com\"}"

  let query =
    pog.query(
      "
    INSERT INTO recipe_sources (name, type, config, enabled)
    VALUES ($1, $2, $3, $4)
    RETURNING config;
  ",
    )
    |> pog.parameter(pog.text("test_json"))
    |> pog.parameter(pog.text("api"))
    |> pog.parameter(pog.nullable(pog.text, Some(json_config)))
    |> pog.parameter(pog.bool(True))

  case pog.execute(query, db) {
    Ok(result) -> {
      result.rows
      |> list.length()
      |> should.equal(1)
    }
    Error(e) -> panic as "JSON insert failed: " <> format_pog_error(e)
  }

  cleanup_recipe_sources(db)
}

pub fn config_can_be_null_test() {
  let db = get_test_db()
  cleanup_recipe_sources(db)

  let query =
    pog.query(
      "
    INSERT INTO recipe_sources (name, type, config, enabled)
    VALUES ($1, $2, $3, $4)
    RETURNING id;
  ",
    )
    |> pog.parameter(pog.text("test_null_config"))
    |> pog.parameter(pog.text("manual"))
    |> pog.parameter(pog.nullable(pog.text, None))
    |> pog.parameter(pog.bool(True))

  case pog.execute(query, db) {
    Ok(result) -> {
      result.rows
      |> list.length()
      |> should.equal(1)
    }
    Error(e) -> panic as "Null config insert failed: " <> format_pog_error(e)
  }

  cleanup_recipe_sources(db)
}

// ============================================================================
// Timestamp Tests
// ============================================================================

pub fn timestamps_auto_populate_test() {
  let db = get_test_db()
  cleanup_recipe_sources(db)

  let query =
    pog.query(
      "
    INSERT INTO recipe_sources (name, type, enabled)
    VALUES ($1, $2, $3)
    RETURNING created_at, updated_at;
  ",
    )
    |> pog.parameter(pog.text("test_timestamps"))
    |> pog.parameter(pog.text("api"))
    |> pog.parameter(pog.bool(True))

  case pog.execute(query, db) {
    Ok(result) -> {
      let decoder = {
        use created_at <- decode.field(0, decode.string)
        use updated_at <- decode.field(1, decode.string)
        decode.success(#(created_at, updated_at))
      }

      case decode.run(result.rows, decode.list(decoder)) {
        Ok([#(created, updated)]) -> {
          // Timestamps should be non-empty
          string.length(created) |> fn(len) { len > 0 } |> should.be_true()
          string.length(updated) |> fn(len) { len > 0 } |> should.be_true()
        }
        _ -> should.fail()
      }
    }
    Error(e) -> panic as "Timestamp query failed: " <> format_pog_error(e)
  }

  cleanup_recipe_sources(db)
}

pub fn default_enabled_is_true_test() {
  let db = get_test_db()
  cleanup_recipe_sources(db)

  let query =
    pog.query(
      "
    INSERT INTO recipe_sources (name, type)
    VALUES ($1, $2)
    RETURNING enabled;
  ",
    )
    |> pog.parameter(pog.text("test_default_enabled"))
    |> pog.parameter(pog.text("api"))

  case pog.execute(query, db) {
    Ok(result) -> {
      case decode.run(result.rows, decode.element(0, decode.bool)) {
        Ok([enabled]) -> enabled |> should.be_true()
        _ -> should.fail()
      }
    }
    Error(e) -> panic as "Default enabled test failed: " <> format_pog_error(e)
  }

  cleanup_recipe_sources(db)
}

// ============================================================================
// Trigger Tests
// ============================================================================

pub fn updated_at_trigger_fires_on_update_test() {
  let db = get_test_db()
  cleanup_recipe_sources(db)

  // Insert a record
  let insert_query =
    pog.query(
      "
    INSERT INTO recipe_sources (name, type, enabled)
    VALUES ($1, $2, $3)
    RETURNING id, updated_at;
  ",
    )
    |> pog.parameter(pog.text("test_trigger"))
    |> pog.parameter(pog.text("api"))
    |> pog.parameter(pog.bool(True))

  let #(record_id, original_timestamp) = case pog.execute(insert_query, db) {
    Ok(result) -> {
      let decoder = {
        use id <- decode.field(0, decode.int)
        use updated_at <- decode.field(1, decode.string)
        decode.success(#(id, updated_at))
      }

      case decode.run(result.rows, decode.list(decoder)) {
        Ok([data]) -> data
        _ -> panic as "Failed to decode insert result"
      }
    }
    Error(e) -> panic as "Insert for trigger test failed: " <> format_pog_error(e)
  }

  // Sleep to ensure timestamp difference
  sleep(1100)

  // Update the record
  let update_query =
    pog.query(
      "
    UPDATE recipe_sources
    SET enabled = $1
    WHERE id = $2
    RETURNING updated_at;
  ",
    )
    |> pog.parameter(pog.bool(False))
    |> pog.parameter(pog.int(record_id))

  case pog.execute(update_query, db) {
    Ok(result) -> {
      case decode.run(result.rows, decode.element(0, decode.string)) {
        Ok([new_timestamp]) -> {
          // New timestamp should be different (later) than original
          { new_timestamp != original_timestamp } |> should.be_true()
        }
        _ -> should.fail()
      }
    }
    Error(e) -> panic as "Update for trigger test failed: " <> format_pog_error(e)
  }

  cleanup_recipe_sources(db)
}

// ============================================================================
// Idempotency Tests
// ============================================================================

pub fn migration_is_idempotent_test() {
  // This test verifies that CREATE TABLE IF NOT EXISTS allows re-running the migration
  // We can't actually re-run the migration here, but we can verify the IF NOT EXISTS clauses work
  let db = get_test_db()

  // Try to create the table again (should not error due to IF NOT EXISTS)
  let query =
    pog.query(
      "
    CREATE TABLE IF NOT EXISTS recipe_sources (
      id SERIAL PRIMARY KEY,
      name TEXT NOT NULL UNIQUE,
      type TEXT NOT NULL CHECK(type IN ('api', 'scraper', 'manual')),
      config TEXT,
      enabled BOOLEAN NOT NULL DEFAULT TRUE,
      created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
  ",
    )

  case pog.execute(query, db) {
    Ok(_) -> should.be_true(True)
    Error(e) -> panic as "Idempotency test failed: " <> format_pog_error(e)
  }
}

pub fn indexes_are_idempotent_test() {
  let db = get_test_db()

  // Try to create indexes again (should not error due to IF NOT EXISTS)
  let index_queries = [
    "CREATE INDEX IF NOT EXISTS idx_recipe_sources_type ON recipe_sources(type);",
    "CREATE INDEX IF NOT EXISTS idx_recipe_sources_enabled ON recipe_sources(enabled);",
  ]

  list.each(index_queries, fn(sql) {
    let query = pog.query(sql)
    case pog.execute(query, db) {
      Ok(_) -> should.be_true(True)
      Error(e) ->
        panic as "Index idempotency test failed: " <> format_pog_error(e)
    }
  })
}

// ============================================================================
// Foreign Key Tests (auto_meal_plans)
// ============================================================================

pub fn auto_meal_plans_has_user_id_foreign_key_test() {
  let db = get_test_db()

  let query =
    pog.query(
      "
    SELECT constraint_name, constraint_type
    FROM information_schema.table_constraints
    WHERE table_name = 'auto_meal_plans' AND constraint_type = 'FOREIGN KEY';
  ",
    )

  case pog.execute(query, db) {
    Ok(result) -> {
      // Should have at least one foreign key constraint
      result.rows
      |> list.length()
      |> fn(len) { len >= 1 }
      |> should.be_true()
    }
    Error(e) -> panic as "Foreign key check failed: " <> format_pog_error(e)
  }
}
