/// Comprehensive tests for recipe_sources migration (009_auto_meal_planner.sql)
/// Validates migration integrity, table schema, constraints, indexes, and triggers
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/list
import gleam/option.{None, Some}
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
  let pool_name = process.new_name(prefix: "migration_test_pool")
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
    |> pog.returning(decode.at([0], decode.bool))

  case pog.execute(query, db) {
    Ok(pog.Returned(_, [True])) -> should.be_true(True)
    Ok(pog.Returned(_, [False])) -> should.fail()
    Ok(_) -> should.fail()
    Error(e) -> {
      let _ = format_pog_error(e)
      panic as "Query failed"
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
    |> pog.returning(decode.at([0], decode.bool))

  case pog.execute(query, db) {
    Ok(pog.Returned(_, [True])) -> should.be_true(True)
    Ok(pog.Returned(_, [False])) -> should.fail()
    Ok(_) -> should.fail()
    Error(e) -> {
      let _ = format_pog_error(e)
      panic as "Query failed"
    }
  }
}

// ============================================================================
// Schema Validation Tests
// ============================================================================

pub fn recipe_sources_has_correct_columns_test() {
  let db = get_test_db()

  let decoder = {
    use column_name <- decode.field(0, decode.string)
    use data_type <- decode.field(1, decode.string)
    use is_nullable <- decode.field(2, decode.string)
    decode.success(#(column_name, data_type, is_nullable))
  }

  let query =
    pog.query(
      "
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_name = 'recipe_sources'
    ORDER BY ordinal_position;
  ",
    )
    |> pog.returning(decoder)

  case pog.execute(query, db) {
    Ok(pog.Returned(_, columns)) -> {
      // Verify we have all expected columns
      list.length(columns) |> should.equal(7)

      // Verify specific columns exist with correct types
      should.be_true(
        list.any(columns, fn(c) {
          c.0 == "id" && c.1 == "integer" && c.2 == "NO"
        }),
      )

      should.be_true(
        list.any(columns, fn(c) {
          c.0 == "name" && c.1 == "text" && c.2 == "NO"
        }),
      )

      should.be_true(
        list.any(columns, fn(c) {
          c.0 == "type" && c.1 == "text" && c.2 == "NO"
        }),
      )

      should.be_true(
        list.any(columns, fn(c) {
          c.0 == "config" && c.2 == "YES"
        }),
      )

      should.be_true(
        list.any(columns, fn(c) {
          c.0 == "enabled" && c.1 == "boolean" && c.2 == "NO"
        }),
      )

      should.be_true(
        list.any(columns, fn(c) {
          c.0 == "created_at"
          && string.contains(c.1, "timestamp")
          && c.2 == "NO"
        }),
      )

      should.be_true(
        list.any(columns, fn(c) {
          c.0 == "updated_at"
          && string.contains(c.1, "timestamp")
          && c.2 == "NO"
        }),
      )
    }
    Error(e) -> {
      let _ = format_pog_error(e)
      panic as "Query failed"
    }
  }
}

pub fn recipe_sources_has_primary_key_test() {
  let db = get_test_db()

  let query =
    pog.query(
      "
    SELECT COUNT(*)
    FROM information_schema.table_constraints
    WHERE table_name = 'recipe_sources' AND constraint_type = 'PRIMARY KEY';
  ",
    )
    |> pog.returning(decode.at([0], decode.int))

  case pog.execute(query, db) {
    Ok(pog.Returned(_, [count])) -> count |> should.equal(1)
    Ok(_) -> should.fail()
    Error(e) -> {
      let _ = format_pog_error(e)
      panic as "Query failed"
    }
  }
}

pub fn recipe_sources_has_unique_name_constraint_test() {
  let db = get_test_db()

  let query =
    pog.query(
      "
    SELECT COUNT(*)
    FROM information_schema.table_constraints
    WHERE table_name = 'recipe_sources' AND constraint_type = 'UNIQUE';
  ",
    )
    |> pog.returning(decode.at([0], decode.int))

  case pog.execute(query, db) {
    Ok(pog.Returned(_, [count])) -> { count >= 1 } |> should.be_true()
    Ok(_) -> should.fail()
    Error(e) -> {
      let _ = format_pog_error(e)
      panic as "Query failed"
    }
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
    SELECT COUNT(*)
    FROM pg_indexes
    WHERE tablename = 'recipe_sources' AND indexname = 'idx_recipe_sources_type';
  ",
    )
    |> pog.returning(decode.at([0], decode.int))

  case pog.execute(query, db) {
    Ok(pog.Returned(_, [count])) -> count |> should.equal(1)
    Ok(_) -> should.fail()
    Error(e) -> {
      let _ = format_pog_error(e)
      panic as "Query failed"
    }
  }
}

pub fn recipe_sources_has_enabled_index_test() {
  let db = get_test_db()

  let query =
    pog.query(
      "
    SELECT COUNT(*)
    FROM pg_indexes
    WHERE tablename = 'recipe_sources' AND indexname = 'idx_recipe_sources_enabled';
  ",
    )
    |> pog.returning(decode.at([0], decode.int))

  case pog.execute(query, db) {
    Ok(pog.Returned(_, [count])) -> count |> should.equal(1)
    Ok(_) -> should.fail()
    Error(e) -> {
      let _ = format_pog_error(e)
      panic as "Query failed"
    }
  }
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
    RETURNING id;
  ",
    )
    |> pog.parameter(pog.text("test_api_source"))
    |> pog.parameter(pog.text("api"))
    |> pog.parameter(pog.nullable(pog.text, Some("{\"api_key\": \"test123\"}")))
    |> pog.parameter(pog.bool(True))
    |> pog.returning(decode.at([0], decode.int))

  case pog.execute(insert_query, db) {
    Ok(pog.Returned(_, [_id])) -> should.be_true(True)
    Ok(_) -> should.fail()
    Error(e) -> {
      let _ = format_pog_error(e)
      cleanup_recipe_sources(db)
      panic as "Insert failed"
    }
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
    |> pog.returning(decode.at([0], decode.int))

  case pog.execute(count_query, db) {
    Ok(pog.Returned(_, [count])) -> count |> should.equal(2)
    Ok(_) -> should.fail()
    Error(e) -> {
      let _ = format_pog_error(e)
      cleanup_recipe_sources(db)
      panic as "Count query failed"
    }
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
      Error(_e) -> panic as "Failed to insert valid type"
    }
  })

  cleanup_recipe_sources(db)
}

// ============================================================================
// Default Value Tests
// ============================================================================

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
    |> pog.returning(decode.at([0], decode.bool))

  case pog.execute(query, db) {
    Ok(pog.Returned(_, [enabled])) -> enabled |> should.be_true()
    Ok(_) -> should.fail()
    Error(e) -> {
      let _ = format_pog_error(e)
      cleanup_recipe_sources(db)
      panic as "Default enabled test failed"
    }
  }

  cleanup_recipe_sources(db)
}

// ============================================================================
// Trigger Tests
// ============================================================================

pub fn updated_at_trigger_fires_on_update_test() {
  let db = get_test_db()
  cleanup_recipe_sources(db)

  let decoder = {
    use id <- decode.field(0, decode.int)
    use updated_at <- decode.field(1, decode.string)
    decode.success(#(id, updated_at))
  }

  // Insert a record
  let insert_query =
    pog.query(
      "
    INSERT INTO recipe_sources (name, type, enabled)
    VALUES ($1, $2, $3)
    RETURNING id, updated_at::text;
  ",
    )
    |> pog.parameter(pog.text("test_trigger"))
    |> pog.parameter(pog.text("api"))
    |> pog.parameter(pog.bool(True))
    |> pog.returning(decoder)

  let #(record_id, original_timestamp) = case pog.execute(insert_query, db) {
    Ok(pog.Returned(_, [data])) -> data
    Ok(_) -> panic as "Unexpected result format"
    Error(_e) -> panic as "Insert for trigger test failed"
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
    RETURNING updated_at::text;
  ",
    )
    |> pog.parameter(pog.bool(False))
    |> pog.parameter(pog.int(record_id))
    |> pog.returning(decode.at([0], decode.string))

  case pog.execute(update_query, db) {
    Ok(pog.Returned(_, [new_timestamp])) -> {
      // New timestamp should be different (later) than original
      { new_timestamp != original_timestamp } |> should.be_true()
    }
    Ok(_) -> should.fail()
    Error(_e) -> {
      cleanup_recipe_sources(db)
      panic as "Update for trigger test failed"
    }
  }

  cleanup_recipe_sources(db)
}

// ============================================================================
// Idempotency Tests
// ============================================================================

pub fn migration_is_idempotent_test() {
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
    Error(_e) -> panic as "Idempotency test failed"
  }
}
